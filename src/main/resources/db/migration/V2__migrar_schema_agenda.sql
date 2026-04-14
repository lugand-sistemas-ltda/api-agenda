-- =============================================================================
-- V2 — Migração das tabelas e tipos para o schema dedicado 'agenda'
-- Gerado em: 2026-04-14
-- Motivo: boas práticas — schema dedicado por domínio/aplicação
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS agenda;

-- -----------------------------------------------------------------------------
-- Tipos ENUM: mover de public → agenda
-- (referências por OID — sem impacto em dados existentes)
-- -----------------------------------------------------------------------------
ALTER TYPE public.compromisso_tipo   SET SCHEMA agenda;
ALTER TYPE public.compromisso_status SET SCHEMA agenda;

-- -----------------------------------------------------------------------------
-- Tabelas: mover de public → agenda
-- Ordem: dependências antes dos dependentes (FKs permanecem por OID)
-- -----------------------------------------------------------------------------
ALTER TABLE public.usuario                  SET SCHEMA agenda;
ALTER TABLE public.compromisso              SET SCHEMA agenda;
ALTER TABLE public.compromisso_responsavel  SET SCHEMA agenda;
