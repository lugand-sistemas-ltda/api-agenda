-- =============================================================================
-- V6 — Permissões Granulares e Participação em Itens
-- Referências: ADR-009 (sistema de permissões, participação, hierarquia de agendas)
-- Data: 2026-04-21
-- =============================================================================
-- Alterações desta migration:
--   1. Tabela agenda.permissao         — catálogo de códigos de permissão atômicos
--   2. Tabela agenda.papel_permissao   — mapeamento papel → conjunto de permissões
--   3. Seed: 18 permissões + mapeamento para 5 papéis
--   4. ENUM agenda.papel_no_item       — papel de um usuário dentro de um item
--   5. Tabela agenda.item_participante — participação individual em itens
--   6. ALTER agenda.agenda             — coluna agenda_pai_id (hierarquia futura)
--
-- Comentado — Fase 5 (hierarquia municipal/estadual):
--   7. ALTER TYPE agenda.tipo_agenda   — valores 'municipal' e 'estadual'
--   8. ENUM agenda.status_compartilhamento
--   9. Tabela agenda.item_compartilhado
-- =============================================================================


-- =============================================================================
-- 1. TABELA: agenda.permissao
--    Catálogo de códigos de permissão atômicos (ADR-009 PM-001).
--    Cada linha representa uma operação protegida identificada por um código.
--    Formato do código: {recurso}.{acao}[.{escopo}]
-- =============================================================================

CREATE TABLE agenda.permissao (
    id        UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    codigo    VARCHAR(100) NOT NULL UNIQUE,
    descricao TEXT,
    categoria VARCHAR(50)  NOT NULL  -- 'compromisso', 'visibilidade', 'agenda', 'usuario'
);

COMMENT ON TABLE agenda.permissao IS
    'Catálogo de permissões atômicas do sistema. ADR-009 PM-001.';
COMMENT ON COLUMN agenda.permissao.codigo IS
    'Código no formato {recurso}.{acao}[.{escopo}]. Identificador único da operação protegida.';


-- =============================================================================
-- 2. TABELA: agenda.papel_permissao
--    Mapeamento papel → permissões (ADR-009 PM-002).
--    papel é VARCHAR para suportar extensão sem ALTER ENUM.
--    Deve conter apenas valores presentes em agenda.papel_grupo.
-- =============================================================================

CREATE TABLE agenda.papel_permissao (
    papel         VARCHAR(50) NOT NULL,
    permissao_id  UUID        NOT NULL REFERENCES agenda.permissao(id) ON DELETE CASCADE,
    PRIMARY KEY   (papel, permissao_id)
);

CREATE INDEX idx_papel_permissao_papel ON agenda.papel_permissao(papel);

COMMENT ON TABLE agenda.papel_permissao IS
    'Mapeamento papel → permissões. Modificar este mapeamento não exige deploy. ADR-009 PM-002.';
COMMENT ON COLUMN agenda.papel_permissao.papel IS
    'Valor deve corresponder a um membro de agenda.papel_grupo ENUM. VARCHAR para extensibilidade.';


-- =============================================================================
-- 3. SEED: catálogo de permissões (ADR-009 PM-001)
-- =============================================================================

INSERT INTO agenda.permissao (codigo, categoria, descricao) VALUES
    -- Compromisso — criação
    ('compromisso.criar.proprio',          'compromisso', 'Criar compromisso na própria agenda pessoal'),
    ('compromisso.criar.para_superior',    'compromisso', 'Criar compromisso com outro usuário como responsável (superior hierárquico)'),
    ('compromisso.criar.para_subordinado', 'compromisso', 'Criar compromisso para subordinado'),
    -- Compromisso — visualização
    ('compromisso.visualizar.proprio',             'compromisso', 'Ver itens da própria agenda pessoal'),
    ('compromisso.visualizar.participante',         'compromisso', 'Ver itens em qualquer agenda onde o usuário é participante (criador, delegado, responsável)'),
    ('compromisso.visualizar.agenda_subordinado',   'compromisso', 'Ver toda a agenda pessoal de um subordinado direto'),
    -- Compromisso — edição / exclusão
    ('compromisso.editar.proprio',       'compromisso', 'Editar itens criados por si na própria agenda'),
    ('compromisso.editar.participante',  'compromisso', 'Editar itens onde o usuário possui papel criador ou delegado'),
    ('compromisso.excluir.proprio',      'compromisso', 'Excluir itens da própria agenda'),
    -- Visibilidade
    ('visibilidade.definir.privado',    'visibilidade', 'Publicar itens com visibilidade privado'),
    ('visibilidade.definir.grupo',      'visibilidade', 'Publicar itens com visibilidade grupo'),
    ('visibilidade.definir.unidade',    'visibilidade', 'Publicar itens com visibilidade unidade'),
    ('visibilidade.definir.global',     'visibilidade', 'Publicar itens com visibilidade global (feriados nacionais)'),
    ('visibilidade.definir.selecionado','visibilidade', 'Publicar itens com visibilidade selecionado e lista de grupos destino'),
    -- Agenda — compartilhamento hierárquico (Fase 5)
    ('agenda.compartilhar.para_inferior', 'agenda', 'Compartilhar itens desta agenda com agendas de nível hierárquico inferior'),
    ('agenda.compartilhar.aceitar',       'agenda', 'Aceitar ou rejeitar itens recebidos de agendas de nível superior'),
    ('agenda.compartilhar.redistribuir',  'agenda', 'Redistribuir itens aceitos para agendas ainda mais inferiores'),
    -- Usuário — administração
    ('usuario.gerenciar.grupo', 'usuario', 'Adicionar e remover membros de um grupo');


-- =============================================================================
-- 4. SEED: mapeamento papel → permissões (ADR-009 PM-002)
-- =============================================================================

INSERT INTO agenda.papel_permissao (papel, permissao_id)
SELECT p.papel, pm.id
FROM (VALUES
    -- administrador: acesso total
    ('administrador', 'compromisso.criar.proprio'),
    ('administrador', 'compromisso.criar.para_superior'),
    ('administrador', 'compromisso.criar.para_subordinado'),
    ('administrador', 'compromisso.visualizar.proprio'),
    ('administrador', 'compromisso.visualizar.participante'),
    ('administrador', 'compromisso.visualizar.agenda_subordinado'),
    ('administrador', 'compromisso.editar.proprio'),
    ('administrador', 'compromisso.editar.participante'),
    ('administrador', 'compromisso.excluir.proprio'),
    ('administrador', 'visibilidade.definir.privado'),
    ('administrador', 'visibilidade.definir.grupo'),
    ('administrador', 'visibilidade.definir.unidade'),
    ('administrador', 'visibilidade.definir.global'),
    ('administrador', 'visibilidade.definir.selecionado'),
    ('administrador', 'agenda.compartilhar.para_inferior'),
    ('administrador', 'agenda.compartilhar.aceitar'),
    ('administrador', 'agenda.compartilhar.redistribuir'),
    ('administrador', 'usuario.gerenciar.grupo'),

    -- gestor: acesso hierárquico (subordinados e compartilhamento)
    ('gestor', 'compromisso.criar.proprio'),
    ('gestor', 'compromisso.criar.para_superior'),
    ('gestor', 'compromisso.criar.para_subordinado'),
    ('gestor', 'compromisso.visualizar.proprio'),
    ('gestor', 'compromisso.visualizar.participante'),
    ('gestor', 'compromisso.visualizar.agenda_subordinado'),
    ('gestor', 'compromisso.editar.proprio'),
    ('gestor', 'compromisso.editar.participante'),
    ('gestor', 'compromisso.excluir.proprio'),
    ('gestor', 'visibilidade.definir.privado'),
    ('gestor', 'visibilidade.definir.grupo'),
    ('gestor', 'visibilidade.definir.unidade'),
    ('gestor', 'visibilidade.definir.selecionado'),
    ('gestor', 'agenda.compartilhar.para_inferior'),
    ('gestor', 'agenda.compartilhar.aceitar'),

    -- operador: acesso individual (própria agenda)
    ('operador', 'compromisso.criar.proprio'),
    ('operador', 'compromisso.visualizar.proprio'),
    ('operador', 'compromisso.visualizar.participante'),
    ('operador', 'compromisso.editar.proprio'),
    ('operador', 'compromisso.excluir.proprio'),
    ('operador', 'visibilidade.definir.privado'),
    ('operador', 'visibilidade.definir.grupo'),

    -- secretaria: cria para outros, não vê agenda alheia completa
    ('secretaria', 'compromisso.criar.proprio'),
    ('secretaria', 'compromisso.criar.para_superior'),
    ('secretaria', 'compromisso.visualizar.proprio'),
    ('secretaria', 'compromisso.visualizar.participante'),
    ('secretaria', 'compromisso.editar.proprio'),
    ('secretaria', 'compromisso.editar.participante'),
    ('secretaria', 'compromisso.excluir.proprio'),
    ('secretaria', 'visibilidade.definir.privado'),
    ('secretaria', 'visibilidade.definir.grupo'),

    -- estagiario: cria apenas para superiores, vê o que criou (via participante)
    ('estagiario', 'compromisso.criar.proprio'),
    ('estagiario', 'compromisso.criar.para_superior'),
    ('estagiario', 'compromisso.visualizar.proprio'),
    ('estagiario', 'compromisso.visualizar.participante'),
    ('estagiario', 'compromisso.editar.proprio'),
    ('estagiario', 'compromisso.excluir.proprio'),
    ('estagiario', 'visibilidade.definir.privado')

) AS p(papel, codigo)
JOIN agenda.permissao pm ON pm.codigo = p.codigo;


-- =============================================================================
-- 5. ENUM: agenda.papel_no_item
--    Papel que um usuário possui dentro de um item específico (ADR-009 PM-003).
--    Independente do papel_grupo — é contextual ao item, não ao grupo.
-- =============================================================================

CREATE TYPE agenda.papel_no_item AS ENUM (
    'criador',        -- quem registrou o compromisso no sistema
    'responsavel',    -- quem conduzirá / executará o compromisso
    'delegado',       -- criou o item para outro (secretaria/estagiario para superior)
    'participante',   -- convidado explicitamente para o item
    'observador'      -- pode ver mas não editar; não convidado diretamente
);

COMMENT ON TYPE agenda.papel_no_item IS
    'Papel de um usuário dentro de um item de agenda. Independente do papel_grupo. ADR-009 PM-003.';


-- =============================================================================
-- 6. TABELA: agenda.item_participante
--    Registra a participação individual de um usuário em um item (ADR-009 PM-003).
--    É a fonte de verdade para visibilidade individual de itens privados.
--
--    Regras de preenchimento automático ao criar um compromisso:
--      - Usuário cria para si:
--          INSERT (item, usuario, papel='criador') — acumula papel de responsavel
--      - Secretaria/estagiario cria para superior:
--          INSERT (item, secretaria, papel='delegado')
--          INSERT (item, superior, papel='responsavel')
--      - Gestor cria para subordinado:
--          INSERT (item, gestor, papel='delegado')
--          INSERT (item, subordinado, papel='responsavel')
-- =============================================================================

CREATE TABLE agenda.item_participante (
    item_id             UUID                    NOT NULL REFERENCES agenda.item_agenda(id) ON DELETE CASCADE,
    usuario_id          UUID                    NOT NULL REFERENCES agenda.usuario(id),
    papel_no_item       agenda.papel_no_item    NOT NULL,
    visivel_na_agenda   BOOLEAN                 NOT NULL DEFAULT true,
    aceito              BOOLEAN                 DEFAULT NULL,  -- NULL=pendente, true=aceito, false=rejeitado
    aceito_em           TIMESTAMPTZ,
    PRIMARY KEY (item_id, usuario_id)
);

-- Índice parcial para a cláusula PM-004 (VIS-004 estendida):
-- EXISTS em item_participante WHERE usuario_id = ? AND visivel_na_agenda = true
CREATE INDEX idx_item_participante_usuario
    ON agenda.item_participante(usuario_id)
    WHERE visivel_na_agenda = true;

-- Índice para listar participantes de um item (ex.: modal de detalhes)
CREATE INDEX idx_item_participante_item
    ON agenda.item_participante(item_id);

COMMENT ON TABLE agenda.item_participante IS
    'Participação individual em itens. Permite visibilidade granular: '
    'um estagiário vê o item privado que criou para o gestor sem ver toda a agenda do gestor. ADR-009 PM-003.';
COMMENT ON COLUMN agenda.item_participante.aceito IS
    'NULL = pendente (notificação enviada); true = aceito; false = rejeitado.';
COMMENT ON COLUMN agenda.item_participante.visivel_na_agenda IS
    'false = participante existe mas optou por ocultar o item do calendário.';


-- =============================================================================
-- 7. Coluna agenda_pai_id em agenda.agenda (ADR-009 PM-005)
--    Habilita a hierarquia de agendas (pessoal < grupo < unidade < municipal < estadual < sistema).
--    Adicionada agora; usada ativamente na Fase 5 com tipos 'municipal' e 'estadual'.
-- =============================================================================

ALTER TABLE agenda.agenda
    ADD COLUMN agenda_pai_id UUID REFERENCES agenda.agenda(id);

CREATE INDEX idx_agenda_pai ON agenda.agenda(agenda_pai_id)
    WHERE agenda_pai_id IS NOT NULL;

COMMENT ON COLUMN agenda.agenda.agenda_pai_id IS
    'Agenda hierarquicamente superior. NULL para agendas de topo (sistema, unidade raiz). ADR-009 PM-005.';


-- =============================================================================
-- FASE 5 — comentado, não ativo — hierarquia municipal/estadual
--
-- Ativar quando casos de uso municipais/estaduais forem definidos (ADR-009 PM-005 e PM-006).
-- Antes de ativar, criar migration V7 com:
--   1. ALTER TYPE agenda.tipo_agenda ADD VALUE 'municipal' AFTER 'unidade';
--   2. ALTER TYPE agenda.tipo_agenda ADD VALUE 'estadual'  AFTER 'municipal';
--   3. As tabelas abaixo.
-- =============================================================================
--
-- CREATE TYPE agenda.status_compartilhamento AS ENUM (
--     'pendente',    -- aguardando decisão do gestor receptor
--     'aceito',      -- aceito; visibilidade controlada por item_compartilhado.visivel
--     'rejeitado'    -- rejeitado; não aparece na agenda receptora
-- );
--
-- CREATE TABLE agenda.item_compartilhado (
--     id                UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
--     item_id           UUID    NOT NULL REFERENCES agenda.item_agenda(id) ON DELETE CASCADE,
--     agenda_origem_id  UUID    NOT NULL REFERENCES agenda.agenda(id),
--     agenda_destino_id UUID    NOT NULL REFERENCES agenda.agenda(id),
--     status            agenda.status_compartilhamento NOT NULL DEFAULT 'pendente',
--     visivel           BOOLEAN NOT NULL DEFAULT true,
--     compartilhado_por UUID    NOT NULL REFERENCES agenda.usuario(id),
--     compartilhado_em  TIMESTAMPTZ NOT NULL DEFAULT now(),
--     decidido_por      UUID    REFERENCES agenda.usuario(id),
--     decidido_em       TIMESTAMPTZ,
--     UNIQUE (item_id, agenda_destino_id)
-- );
--
-- CREATE INDEX idx_item_compartilhado_destino_status
--     ON agenda.item_compartilhado(agenda_destino_id, status);
-- =============================================================================
