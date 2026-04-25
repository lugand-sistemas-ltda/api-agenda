-- V10: Infraestrutura de auditoria — schema, tabela particionada e função trigger
-- ADR-010: Auditoria por trilha de eventos (trigger PostgreSQL + JSONB)
-- Decisão: Hibernate Envers rejeitado. Triggers capturam SQL direto, Flyway e app.
-- Imutabilidade: trigger BEFORE UPDATE/DELETE bloqueia modificações.
-- Contexto HTTP: injetado via set_config() transaction-local antes de cada escrita.

-- =============================================================================
-- 1. SCHEMA
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS audit;

-- =============================================================================
-- 2. TABELA PRINCIPAL (particionada por trimestre)
-- =============================================================================

CREATE TABLE audit.log_evento (
    -- Identidade
    id              BIGSERIAL       NOT NULL,

    -- O quê
    operacao        TEXT            NOT NULL,   -- INSERT | UPDATE | DELETE | SELECT
    tabela          TEXT            NOT NULL,   -- 'agenda.item_agenda'
    registro_id     UUID,                       -- PK do registro; NULL para tabelas com PK composta

    -- Quem
    usuario_id      UUID,                       -- set_config('app.usuario_id', ..., true)
    papel_momento   TEXT,                       -- set_config('app.papel', ..., true)
    sessao_id       UUID,                       -- set_config('app.sessao_id', ..., true)
    delegado_por_id UUID,                       -- set_config('app.delegado_por_id', ..., true)

    -- De onde / como
    ip_origem       TEXT,                       -- set_config('app.ip_origem', ..., true)
    aplicacao       TEXT            NOT NULL DEFAULT 'desconhecido',  -- 'api' | 'migration' | 'admin'
    transacao_id    BIGINT,                     -- txid_current()

    -- Dados
    dados_antes     JSONB,                      -- NULL em INSERT / SELECT
    dados_depois    JSONB,                      -- NULL em DELETE
    campos_alterados TEXT[],                    -- preenchido apenas em UPDATE

    -- Resultado
    status_operacao TEXT            NOT NULL DEFAULT 'sucesso',  -- sucesso | negado | erro

    -- Quando (chave de partição — IMUTÁVEL)
    criado_em       TIMESTAMPTZ     NOT NULL DEFAULT now(),

    PRIMARY KEY (id, criado_em)
) PARTITION BY RANGE (criado_em);

COMMENT ON TABLE  audit.log_evento                IS 'Trilha imutável de eventos de dados. ADR-010.';
COMMENT ON COLUMN audit.log_evento.operacao       IS 'INSERT | UPDATE | DELETE | SELECT';
COMMENT ON COLUMN audit.log_evento.registro_id    IS 'PK UUID do registro afetado. NULL para PKs compostas.';
COMMENT ON COLUMN audit.log_evento.delegado_por_id IS 'Preenchido quando uma ação é feita por delegação (ex.: estagiário criando para gestor).';
COMMENT ON COLUMN audit.log_evento.aplicacao      IS 'Origem da operação: api | migration | admin | desconhecido.';
COMMENT ON COLUMN audit.log_evento.campos_alterados IS 'Nomes das colunas cujos valores mudaram. Apenas em UPDATE.';

-- =============================================================================
-- 3. ÍNDICES
-- =============================================================================

CREATE INDEX idx_audit_usuario_id  ON audit.log_evento (usuario_id)  WHERE usuario_id  IS NOT NULL;
CREATE INDEX idx_audit_registro_id ON audit.log_evento (registro_id) WHERE registro_id IS NOT NULL;
CREATE INDEX idx_audit_tabela_op   ON audit.log_evento (tabela, operacao);
CREATE INDEX idx_audit_sessao_id   ON audit.log_evento (sessao_id)   WHERE sessao_id   IS NOT NULL;

-- =============================================================================
-- 4. FUNÇÃO TRIGGER — registrar_evento()
-- =============================================================================

CREATE OR REPLACE FUNCTION audit.registrar_evento()
RETURNS TRIGGER AS $$
DECLARE
    v_usuario_id      UUID;
    v_sessao_id       UUID;
    v_papel           TEXT;
    v_delegado_por    UUID;
    v_ip              TEXT;
    v_aplicacao       TEXT;
    v_registro_id     UUID;
    v_dados_antes     JSONB;
    v_dados_depois    JSONB;
    v_campos_alt      TEXT[];
    v_id_raw          TEXT;
BEGIN
    -- -------------------------------------------------------------------------
    -- Lê contexto HTTP injetado via set_config() transaction-local
    -- current_setting(key, missing_ok) retorna '' se não definido (não lança exceção)
    -- -------------------------------------------------------------------------
    BEGIN
        v_usuario_id   := NULLIF(current_setting('app.usuario_id',      true), '')::UUID;
    EXCEPTION WHEN invalid_text_representation THEN v_usuario_id   := NULL; END;
    BEGIN
        v_sessao_id    := NULLIF(current_setting('app.sessao_id',        true), '')::UUID;
    EXCEPTION WHEN invalid_text_representation THEN v_sessao_id    := NULL; END;
    BEGIN
        v_delegado_por := NULLIF(current_setting('app.delegado_por_id',  true), '')::UUID;
    EXCEPTION WHEN invalid_text_representation THEN v_delegado_por := NULL; END;

    v_papel      := NULLIF(current_setting('app.papel',      true), '');
    v_ip         := NULLIF(current_setting('app.ip_origem',  true), '');
    v_aplicacao  := COALESCE(NULLIF(current_setting('app.aplicacao', true), ''), 'desconhecido');

    -- -------------------------------------------------------------------------
    -- Captura o id UUID do registro (pode não existir em tabelas com PK composta)
    -- -------------------------------------------------------------------------
    v_id_raw := CASE TG_OP
        WHEN 'DELETE' THEN to_jsonb(OLD) ->> 'id'
        ELSE               to_jsonb(NEW) ->> 'id'
    END;
    BEGIN
        v_registro_id := v_id_raw::UUID;
    EXCEPTION WHEN OTHERS THEN
        v_registro_id := NULL;
    END;

    -- -------------------------------------------------------------------------
    -- Monta dados_antes / dados_depois
    -- -------------------------------------------------------------------------
    IF TG_OP = 'INSERT' THEN
        v_dados_antes  := NULL;
        v_dados_depois := to_jsonb(NEW);
    ELSIF TG_OP = 'DELETE' THEN
        v_dados_antes  := to_jsonb(OLD);
        v_dados_depois := NULL;
    ELSE -- UPDATE
        v_dados_antes  := to_jsonb(OLD);
        v_dados_depois := to_jsonb(NEW);

        -- Campos que efetivamente mudaram
        SELECT array_agg(o.key ORDER BY o.key)
        INTO   v_campos_alt
        FROM   jsonb_each_text(to_jsonb(OLD)) o
        FULL OUTER JOIN jsonb_each_text(to_jsonb(NEW)) n USING (key)
        WHERE  o.value IS DISTINCT FROM n.value;
    END IF;

    -- -------------------------------------------------------------------------
    -- Mascara senha_hash em qualquer tabela que contenha essa coluna
    -- -------------------------------------------------------------------------
    IF v_dados_antes  IS NOT NULL AND v_dados_antes  ? 'senha_hash' THEN
        v_dados_antes  := jsonb_set(v_dados_antes,  '{senha_hash}', '"[REDACTED]"');
    END IF;
    IF v_dados_depois IS NOT NULL AND v_dados_depois ? 'senha_hash' THEN
        v_dados_depois := jsonb_set(v_dados_depois, '{senha_hash}', '"[REDACTED]"');
    END IF;

    -- -------------------------------------------------------------------------
    -- Grava na trilha
    -- -------------------------------------------------------------------------
    INSERT INTO audit.log_evento (
        operacao, tabela, registro_id,
        usuario_id, papel_momento, sessao_id, delegado_por_id,
        ip_origem, aplicacao, transacao_id,
        dados_antes, dados_depois, campos_alterados,
        status_operacao
    ) VALUES (
        TG_OP,
        TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME,
        v_registro_id,
        v_usuario_id, v_papel, v_sessao_id, v_delegado_por,
        v_ip, v_aplicacao, txid_current(),
        v_dados_antes, v_dados_depois, v_campos_alt,
        'sucesso'
    );

    RETURN NULL; -- AFTER trigger; valor de retorno ignorado
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = audit, pg_catalog;

COMMENT ON FUNCTION audit.registrar_evento() IS
    'Trigger AFTER INSERT/UPDATE/DELETE. Grava evento em audit.log_evento. '
    'SECURITY DEFINER para garantir INSERT mesmo que o papel da app não tenha acesso direto. '
    'Contexto HTTP (usuario_id, sessao_id, papel, ip) é passado via set_config(..., true).';

-- =============================================================================
-- 5. FUNÇÃO BLOQUEIO — imutabilidade das trilhas
-- =============================================================================

CREATE OR REPLACE FUNCTION audit.bloquear_modificacao()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION
        'Trilha de auditoria é imutável — operação % bloqueada na tabela %.%',
        TG_OP, TG_TABLE_SCHEMA, TG_TABLE_NAME;
END;
$$ LANGUAGE plpgsql
   SET search_path = audit, pg_catalog;

COMMENT ON FUNCTION audit.bloquear_modificacao() IS
    'Garante imutabilidade: qualquer UPDATE ou DELETE em audit.log_evento lança exceção.';

CREATE TRIGGER trg_audit_imutavel
    BEFORE UPDATE OR DELETE ON audit.log_evento
    FOR EACH ROW EXECUTE FUNCTION audit.bloquear_modificacao();

-- =============================================================================
-- NOTA DE SEGURANÇA
-- =============================================================================
-- Em produção, execute como superusuário após identificar o role da aplicação:
--   REVOKE UPDATE, DELETE, TRUNCATE ON audit.log_evento FROM <app_role>;
--   GRANT  INSERT, SELECT          ON audit.log_evento TO   <app_role>;
--   GRANT  SELECT                  ON audit.log_evento TO   <audit_reader_role>;
-- O trigger bloqueia UPDATE/DELETE no nível de linha como camada adicional.
