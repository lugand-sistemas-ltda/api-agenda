-- V12: Partições trimestrais de audit.log_evento
-- Cobrem Q2 2026 → Q1 2027 (janela de operação do sistema + 1 trimestre de folga)
--
-- Estratégia de retenção: 5 anos = 20 partições. Criar a partição do trimestre seguinte
-- uma sprint antes de entrar no período (ex.: criar Q2_2027 antes de 2027-04-01).
--
-- Partition key: criado_em TIMESTAMPTZ (RANGE, criado_em inclusive lower, exclusive upper)

-- Q2 2026: 2026-04-01 → 2026-06-30 23:59:59.999…
CREATE TABLE audit.log_evento_2026_q2
    PARTITION OF audit.log_evento
    FOR VALUES FROM ('2026-04-01 00:00:00+00') TO ('2026-07-01 00:00:00+00');

COMMENT ON TABLE audit.log_evento_2026_q2 IS 'Partição Q2/2026 (abr–jun).';

-- Q3 2026: 2026-07-01 → 2026-09-30 23:59:59.999…
CREATE TABLE audit.log_evento_2026_q3
    PARTITION OF audit.log_evento
    FOR VALUES FROM ('2026-07-01 00:00:00+00') TO ('2026-10-01 00:00:00+00');

COMMENT ON TABLE audit.log_evento_2026_q3 IS 'Partição Q3/2026 (jul–set).';

-- Q4 2026: 2026-10-01 → 2026-12-31 23:59:59.999…
CREATE TABLE audit.log_evento_2026_q4
    PARTITION OF audit.log_evento
    FOR VALUES FROM ('2026-10-01 00:00:00+00') TO ('2027-01-01 00:00:00+00');

COMMENT ON TABLE audit.log_evento_2026_q4 IS 'Partição Q4/2026 (out–dez).';

-- Q1 2027: 2027-01-01 → 2027-03-31 23:59:59.999…
CREATE TABLE audit.log_evento_2027_q1
    PARTITION OF audit.log_evento
    FOR VALUES FROM ('2027-01-01 00:00:00+00') TO ('2027-04-01 00:00:00+00');

COMMENT ON TABLE audit.log_evento_2027_q1 IS 'Partição Q1/2027 (jan–mar).';

-- =============================================================================
-- LEMBRETE OPERACIONAL
-- =============================================================================
-- Antes de 2027-04-01, execute:
--   CREATE TABLE audit.log_evento_2027_q2
--       PARTITION OF audit.log_evento
--       FOR VALUES FROM ('2027-04-01 00:00:00+00') TO ('2027-07-01 00:00:00+00');
-- Retenção de 5 anos: partições com mais de 20 trimestres podem ser arquivadas/removidas.
-- Arquive antes de DROP: pg_dump -t audit.log_evento_YYYY_qN > arquivo_antes_de_remover.sql
