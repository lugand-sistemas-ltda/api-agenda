-- =============================================================================
-- V1 — Schema inicial: usuários e compromissos
-- Gerado em: 2026-04-13
-- Referência: ADR-001 (regras de negócio), ADR-002 (arquitetura)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- ENUM: tipo de compromisso (extensível via nova migration)
-- -----------------------------------------------------------------------------
CREATE TYPE compromisso_tipo AS ENUM (
    'feriado',
    'ponto_facultativo',
    'oitiva',
    'operacao',
    'livre'
);

-- -----------------------------------------------------------------------------
-- ENUM: status do compromisso
-- -----------------------------------------------------------------------------
CREATE TYPE compromisso_status AS ENUM (
    'confirmado',
    'pendente',
    'cancelado'
);

-- -----------------------------------------------------------------------------
-- TABELA: usuario
-- Base mínima para PoC — sem autenticação por enquanto (ADR-001 RN-004 futuro)
-- -----------------------------------------------------------------------------
CREATE TABLE usuario (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome        VARCHAR(255) NOT NULL,
    email       VARCHAR(255) NOT NULL UNIQUE,
    criado_em   TIMESTAMP NOT NULL DEFAULT now(),
    atualizado_em TIMESTAMP NOT NULL DEFAULT now()
);

-- -----------------------------------------------------------------------------
-- TABELA: compromisso
-- -----------------------------------------------------------------------------
CREATE TABLE compromisso (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    titulo              VARCHAR(255) NOT NULL,
    descricao           TEXT,
    tipo                compromisso_tipo NOT NULL,
    status              compromisso_status NOT NULL DEFAULT 'pendente',
    data_inicio         TIMESTAMP NOT NULL,
    data_fim            TIMESTAMP NOT NULL,
    local               VARCHAR(255),
    observacoes         TEXT,
    responsavel_id      UUID NOT NULL REFERENCES usuario(id),
    criado_em           TIMESTAMP NOT NULL DEFAULT now(),
    atualizado_em       TIMESTAMP NOT NULL DEFAULT now(),

    CONSTRAINT chk_datas CHECK (data_fim > data_inicio)
);

-- -----------------------------------------------------------------------------
-- TABELA: compromisso_responsavel (outros responsáveis — lista opcional)
-- RN-007: responsáveis opcionais
-- -----------------------------------------------------------------------------
CREATE TABLE compromisso_responsavel (
    compromisso_id  UUID NOT NULL REFERENCES compromisso(id) ON DELETE CASCADE,
    usuario_id      UUID NOT NULL REFERENCES usuario(id),
    PRIMARY KEY (compromisso_id, usuario_id)
);

-- -----------------------------------------------------------------------------
-- ÍNDICES
-- -----------------------------------------------------------------------------
CREATE INDEX idx_compromisso_responsavel ON compromisso(responsavel_id);
CREATE INDEX idx_compromisso_data_inicio  ON compromisso(data_inicio);
CREATE INDEX idx_compromisso_tipo         ON compromisso(tipo);

-- -----------------------------------------------------------------------------
-- DADOS INICIAIS: usuário base para testes
-- -----------------------------------------------------------------------------
INSERT INTO usuario (id, nome, email) VALUES
    ('00000000-0000-0000-0000-000000000001', 'Administrador', 'admin@sri.local'),
    ('00000000-0000-0000-0000-000000000002', 'André Myszko',  'andre@sri.local'),
    ('00000000-0000-0000-0000-000000000003', 'Maria Silva',   'maria@sri.local');

-- -----------------------------------------------------------------------------
-- DADOS INICIAIS: feriados 2026 (RN-006)
-- -----------------------------------------------------------------------------
INSERT INTO compromisso (titulo, tipo, status, data_inicio, data_fim, responsavel_id) VALUES
    ('Tiradentes',           'feriado',          'confirmado', '2026-04-21 00:00:00', '2026-04-21 23:59:59', '00000000-0000-0000-0000-000000000001'),
    ('Véspera de Tiradentes','ponto_facultativo', 'confirmado', '2026-04-20 00:00:00', '2026-04-20 23:59:59', '00000000-0000-0000-0000-000000000001'),
    ('Dia do Trabalho',      'feriado',          'confirmado', '2026-05-01 00:00:00', '2026-05-01 23:59:59', '00000000-0000-0000-0000-000000000001'),
    ('Corpus Christi',       'feriado',          'confirmado', '2026-06-04 00:00:00', '2026-06-04 23:59:59', '00000000-0000-0000-0000-000000000001');
