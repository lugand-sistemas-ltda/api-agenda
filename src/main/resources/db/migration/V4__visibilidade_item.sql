-- =============================================================================
-- V4 — Visibilidade de Itens de Agenda
-- Referências: ADR-007 (visibilidade); resolve contradição ADR-006 AG-004
-- Data: 2026-04-20
-- =============================================================================
-- Alterações:
--   1. Novo ENUM item_visibilidade
--   2. Coluna visibilidade em item_agenda (default 'privado')
--   3. Coluna criado_por_id em item_agenda (nullable — obrigatório em Iteração 3)
--   4. Agenda de sistema — Calendário Nacional (ID fixo para seed reproduzível)
--   5. Migrar feriados/ponto_facultativo/recesso para agenda de sistema
--   6. Atualizar visibilidade dos itens existentes com base no tipo
--   7. Tabela item_grupo_destino (para visibilidade = 'selecionado')
--   8. Índices de performance para query VIS-004
-- =============================================================================


-- =============================================================================
-- 1. ENUM item_visibilidade (ADR-007 VIS-002)
-- =============================================================================

CREATE TYPE agenda.item_visibilidade AS ENUM (
    'privado',     -- apenas o dono da agenda de origem (+ gestores/admin por hierarquia)
    'grupo',       -- membros do grupo vinculado à agenda de origem
    'unidade',     -- todos os membros da unidade (grupo raiz)
    'global',      -- todos os usuários do sistema (feriados nacionais)
    'selecionado'  -- grupos específicos listados em item_grupo_destino
);


-- =============================================================================
-- 2. Coluna visibilidade em item_agenda (ADR-007 VIS-002)
-- =============================================================================

ALTER TABLE agenda.item_agenda
    ADD COLUMN visibilidade agenda.item_visibilidade NOT NULL DEFAULT 'privado';


-- =============================================================================
-- 3. Coluna criado_por_id em item_agenda (ADR-007 VIS-006 / fecha ADR-006 Q3)
--    Nullable na PoC; será NOT NULL após autenticação JWT (Iteração 3).
-- =============================================================================

ALTER TABLE agenda.item_agenda
    ADD COLUMN criado_por_id UUID REFERENCES agenda.usuario(id);


-- =============================================================================
-- 4. Agenda de sistema — Calendário Nacional (ADR-007 VIS-005 / ADR-006 AG-004)
--    Sem proprietario_id e sem grupo_id — agenda global do módulo.
-- =============================================================================

INSERT INTO agenda.agenda (id, nome, tipo)
VALUES (
    '00000000-0000-0000-0000-000000000030',
    'Calendário Nacional',
    'sistema'
);


-- =============================================================================
-- 5. Migrar feriados, pontos facultativos e recessos para agenda de sistema
--    RESOLVE contradição da V3: esses itens estavam na agenda da unidade SRI
--    ('00000000-0000-0000-0000-000000000020'), mas ADR-006 AG-004 define que
--    devem residir na agenda de tipo = 'sistema'.
-- =============================================================================

UPDATE agenda.item_agenda
SET agenda_id = '00000000-0000-0000-0000-000000000030'
WHERE tipo::text IN ('feriado', 'ponto_facultativo', 'recesso');


-- =============================================================================
-- 6. Atualizar visibilidade dos itens existentes com base no tipo (ADR-007 VIS-002)
-- =============================================================================

-- Feriados: globais por definição
UPDATE agenda.item_agenda
SET visibilidade = 'global'
WHERE tipo::text = 'feriado';

-- Pontos facultativos e recessos: escopo de unidade
UPDATE agenda.item_agenda
SET visibilidade = 'unidade'
WHERE tipo::text IN ('ponto_facultativo', 'recesso');

-- Operações e reuniões: escopo de grupo
UPDATE agenda.item_agenda
SET visibilidade = 'grupo'
WHERE tipo::text IN ('operacao', 'reuniao');

-- Períodos: escopo de grupo (gestor pode ampliar para 'unidade' ou 'selecionado')
UPDATE agenda.item_agenda
SET visibilidade = 'grupo'
WHERE tipo::text = 'periodo';

-- Oitivas e itens livres: privado (responsável + hierarquia)
-- (já são 'privado' pelo DEFAULT — UPDATE explícito por clareza)
UPDATE agenda.item_agenda
SET visibilidade = 'privado'
WHERE tipo::text IN ('oitiva', 'livre');


-- =============================================================================
-- 7. Tabela item_grupo_destino (ADR-007 VIS-003)
--    Usada quando visibilidade = 'selecionado'.
--    N:M entre item_agenda e grupo.
-- =============================================================================

CREATE TABLE agenda.item_grupo_destino (
    item_id   UUID NOT NULL REFERENCES agenda.item_agenda(id) ON DELETE CASCADE,
    grupo_id  UUID NOT NULL REFERENCES agenda.grupo(id)       ON DELETE CASCADE,
    PRIMARY KEY (item_id, grupo_id)
);

CREATE INDEX idx_item_grupo_destino_grupo
    ON agenda.item_grupo_destino(grupo_id);


-- =============================================================================
-- 8. Índices de performance para query VIS-004 (ADR-007 VIS-004)
-- =============================================================================

-- Filtro rápido por visibilidade + intervalo
CREATE INDEX idx_item_visibilidade_data
    ON agenda.item_agenda(visibilidade, data_inicio);

-- Filtro por criador (futura auditoria / RN-010)
CREATE INDEX idx_item_criado_por
    ON agenda.item_agenda(criado_por_id)
    WHERE criado_por_id IS NOT NULL;
