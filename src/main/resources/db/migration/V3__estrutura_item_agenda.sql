-- =============================================================================
-- V3 — Estrutura escalável de Item de Agenda
-- Referências: ADR-005 (hierarquia de item_agenda), ADR-006 (grupos e agendas)
-- Data: 2026-04-14
-- =============================================================================
-- Estratégia: evolução in-place
--   • Renomeia compromisso → item_agenda (+ colunas semânticas)
--   • Cria grupo (hierárquico), agenda (múltiplas), grupo_membro
--   • Migra dados existentes
--   • NÃO quebra o contrato atual da API (tabela renomeada, mesmos dados)
-- =============================================================================

-- =============================================================================
-- 1. NOVOS ENUMs
-- =============================================================================

-- Renderização visual do item no calendário (ADR-005 IA-002)
CREATE TYPE agenda.item_renderizacao AS ENUM (
    'evento',       -- cartão posicionado no horário
    'fundo_dia',    -- colore o fundo do dia inteiro
    'periodo'       -- barra multi-dia (futuro)
);

-- Papel do usuário dentro de um grupo / unidade (ADR-006 GR-003)
CREATE TYPE agenda.papel_grupo AS ENUM (
    'administrador',   -- acesso total à agenda da unidade
    'gestor',          -- acesso às agendas do seu sub-grupo
    'operador',        -- cria/edita compromissos próprios e para subordinados
    'secretaria',      -- cria compromissos para gestores/operadores do mesmo grupo
    'estagiario'       -- cria apenas compromissos próprios
);

-- Categoria estrutural da agenda (ADR-006 AG-001)
CREATE TYPE agenda.tipo_agenda AS ENUM (
    'pessoal',   -- pertence a um único usuário
    'grupo',     -- pertence a um grupo
    'unidade',   -- agenda raiz da unidade (visível a todos)
    'sistema'    -- agenda gerenciada pelo sistema (feriados nacionais, etc.)
);

-- Natureza da participação em um item (ADR-005 IA-003 / ADR-006)
CREATE TYPE agenda.tipo_participacao AS ENUM (
    'responsavel_extra',  -- responsável adicional além do principal
    'convidado',          -- presença esperada mas não verificada para conflito
    'testemunha',         -- papel jurídico — vinculado ao BO/procedimento
    'investigado'         -- papel jurídico — vinculado ao BO/procedimento
);

-- =============================================================================
-- 2. RENOMEAR ENUMs existentes para nomenclatura unificada
-- =============================================================================

ALTER TYPE agenda.compromisso_tipo   RENAME TO item_tipo;
ALTER TYPE agenda.compromisso_status RENAME TO item_status;

-- Adicionar novos valores ao item_tipo (extensível via migration futura)
-- Mantemos 'feriado','ponto_facultativo','oitiva','operacao','livre'
-- Adicionamos 'periodo' e 'reuniao' como base escalável
ALTER TYPE agenda.item_tipo ADD VALUE IF NOT EXISTS 'reuniao';
ALTER TYPE agenda.item_tipo ADD VALUE IF NOT EXISTS 'periodo';
ALTER TYPE agenda.item_tipo ADD VALUE IF NOT EXISTS 'recesso';

-- =============================================================================
-- 3. TABELA: grupo (hierárquica, auto-referenciada)
-- ADR-006 GR-001: grupos podem conter sub-grupos (grupo_pai_id)
-- =============================================================================

CREATE TABLE agenda.grupo (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome            VARCHAR(255) NOT NULL,
    descricao       TEXT,
    grupo_pai_id    UUID REFERENCES agenda.grupo(id),  -- NULL = grupo raiz
    ativo           BOOLEAN NOT NULL DEFAULT true,
    criado_em       TIMESTAMP NOT NULL DEFAULT now(),
    atualizado_em   TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX idx_grupo_pai
    ON agenda.grupo(grupo_pai_id)
    WHERE grupo_pai_id IS NOT NULL;

-- =============================================================================
-- 4. TABELA: agenda (múltiplas agendas por usuário/grupo)
-- ADR-006 AG-001: cada usuário e cada grupo possuem sua própria agenda
-- =============================================================================

CREATE TABLE agenda.agenda (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome            VARCHAR(255) NOT NULL,
    tipo            agenda.tipo_agenda NOT NULL,
    proprietario_id UUID REFERENCES agenda.usuario(id),  -- preenchido se tipo = 'pessoal'
    grupo_id        UUID REFERENCES agenda.grupo(id),    -- preenchido se tipo IN ('grupo','unidade')
    ativa           BOOLEAN NOT NULL DEFAULT true,
    criado_em       TIMESTAMP NOT NULL DEFAULT now(),
    atualizado_em   TIMESTAMP NOT NULL DEFAULT now(),

    -- Garante que agendas pessoais têm proprietário e agendas de grupo têm grupo
    CONSTRAINT chk_agenda_vinculo CHECK (
        (tipo = 'pessoal'  AND proprietario_id IS NOT NULL AND grupo_id IS NULL) OR
        (tipo = 'grupo'    AND grupo_id IS NOT NULL) OR
        (tipo = 'unidade'  AND grupo_id IS NOT NULL) OR
        (tipo = 'sistema')
    )
);

CREATE INDEX idx_agenda_proprietario ON agenda.agenda(proprietario_id) WHERE proprietario_id IS NOT NULL;
CREATE INDEX idx_agenda_grupo        ON agenda.agenda(grupo_id)        WHERE grupo_id IS NOT NULL;

-- =============================================================================
-- 5. TABELA: grupo_membro (usuário × grupo × papel)
-- ADR-006 GR-003: um usuário pode pertencer a múltiplos grupos com papéis distintos
-- =============================================================================

CREATE TABLE agenda.grupo_membro (
    grupo_id    UUID NOT NULL REFERENCES agenda.grupo(id)   ON DELETE CASCADE,
    usuario_id  UUID NOT NULL REFERENCES agenda.usuario(id) ON DELETE CASCADE,
    papel       agenda.papel_grupo NOT NULL,
    ativo       BOOLEAN NOT NULL DEFAULT true,
    desde       TIMESTAMP NOT NULL DEFAULT now(),
    PRIMARY KEY (grupo_id, usuario_id)
);

CREATE INDEX idx_grupo_membro_usuario ON agenda.grupo_membro(usuario_id);

-- =============================================================================
-- 6. EVOLUIR compromisso → item_agenda (renomear + novas colunas)
-- ADR-005: item_agenda é a abstração base de todo elemento agendável
-- =============================================================================

-- 6a. Renomear tabelas
ALTER TABLE agenda.compromisso           RENAME TO item_agenda;
ALTER TABLE agenda.compromisso_responsavel RENAME TO item_responsavel;

-- 6b. Renomear índices existentes para nomenclatura consistente
ALTER INDEX agenda.idx_compromisso_responsavel RENAME TO idx_item_responsavel_principal;
ALTER INDEX agenda.idx_compromisso_data_inicio  RENAME TO idx_item_data_inicio;
ALTER INDEX agenda.idx_compromisso_tipo         RENAME TO idx_item_tipo;

-- 6c. Adicionar colunas semânticas
ALTER TABLE agenda.item_agenda
    ADD COLUMN renderizacao   agenda.item_renderizacao NOT NULL DEFAULT 'evento',
    ADD COLUMN exige_presenca BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN item_pai_id    UUID REFERENCES agenda.item_agenda(id),  -- containment futuro
    ADD COLUMN agenda_id      UUID;  -- preenchido via UPDATE antes de adicionar FK

-- 6d. responsavel_id torna-se opcional (fundo_dia não tem responsável)
ALTER TABLE agenda.item_agenda
    ALTER COLUMN responsavel_id DROP NOT NULL;

-- 6e. Renomear coluna de chave estrangeira em item_responsavel
ALTER TABLE agenda.item_responsavel
    RENAME COLUMN compromisso_id TO item_id;

-- 6f. Adicionar tipo de participação em item_responsavel
ALTER TABLE agenda.item_responsavel
    ADD COLUMN tipo_participacao agenda.tipo_participacao NOT NULL DEFAULT 'responsavel_extra';

-- =============================================================================
-- 7. DADOS DE SETUP: grupo raiz, agendas iniciais, membros
-- =============================================================================

-- Grupo raiz da unidade
INSERT INTO agenda.grupo (id, nome, descricao) VALUES
    ('00000000-0000-0000-0000-000000000010',
     'SRI',
     'Serviço de Repressão e Inteligência — grupo raiz da unidade');

-- Agenda da unidade (sistema)
INSERT INTO agenda.agenda (id, nome, tipo, grupo_id) VALUES
    ('00000000-0000-0000-0000-000000000020',
     'Agenda da Unidade SRI',
     'unidade',
     '00000000-0000-0000-0000-000000000010');

-- Agendas pessoais dos usuários seed
INSERT INTO agenda.agenda (id, nome, tipo, proprietario_id) VALUES
    ('00000000-0000-0000-0000-000000000021',
     'Agenda Pessoal — Administrador', 'pessoal',
     '00000000-0000-0000-0000-000000000001'),
    ('00000000-0000-0000-0000-000000000022',
     'Agenda Pessoal — André Myszko', 'pessoal',
     '00000000-0000-0000-0000-000000000002'),
    ('00000000-0000-0000-0000-000000000023',
     'Agenda Pessoal — Maria Silva', 'pessoal',
     '00000000-0000-0000-0000-000000000003');

-- Membros do grupo SRI (seed)
INSERT INTO agenda.grupo_membro (grupo_id, usuario_id, papel) VALUES
    ('00000000-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000000000001', 'administrador'),
    ('00000000-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000000000002', 'operador'),
    ('00000000-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000000000003', 'secretaria');

-- =============================================================================
-- 8. MIGRAR dados existentes de compromisso → semântica nova
-- =============================================================================

-- 8a. Associar todos os itens existentes à agenda da unidade
UPDATE agenda.item_agenda
SET agenda_id = '00000000-0000-0000-0000-000000000020';

-- 8b. Agora que estão preenchidos, adicionar FK e NOT NULL
ALTER TABLE agenda.item_agenda
    ALTER COLUMN agenda_id SET NOT NULL,
    ADD CONSTRAINT fk_item_agenda FOREIGN KEY (agenda_id) REFERENCES agenda.agenda(id);

-- 8c. Feriados e pontos facultativos → fundo_dia, sem responsável
-- NOTA: cast ::text necessário porque 'recesso' é novo valor adicionado via ADD VALUE
-- e não pode ser usado como literal enum na mesma transação (PostgreSQL restriction).
UPDATE agenda.item_agenda
SET renderizacao   = 'fundo_dia',
    responsavel_id = NULL,
    exige_presenca = false
WHERE tipo::text IN ('feriado', 'ponto_facultativo', 'recesso');

-- 8d. Tipos que exigem presença física do responsável
UPDATE agenda.item_agenda
SET exige_presenca = true
WHERE tipo IN ('oitiva', 'operacao');

-- =============================================================================
-- 9. NOVOS ÍNDICES
-- =============================================================================

-- Consulta de conflito CONFLITO-B (ADR-005 IA-006):
-- responsavel + exige_presenca + intervalo temporal
CREATE INDEX idx_item_conflito
    ON agenda.item_agenda(responsavel_id, data_inicio, data_fim)
    WHERE exige_presenca = true;

-- Filtro por agenda (selecionar qual agenda visualizar)
CREATE INDEX idx_item_agenda_data
    ON agenda.item_agenda(agenda_id, data_inicio);

-- Containment: itens filhos de um período
CREATE INDEX idx_item_pai
    ON agenda.item_agenda(item_pai_id)
    WHERE item_pai_id IS NOT NULL;

-- Filtro rápido por renderização (frontend)
CREATE INDEX idx_item_renderizacao
    ON agenda.item_agenda(agenda_id, renderizacao, data_inicio);
