-- =============================================================================
-- V7 — Visibilidade "participante"
-- Referências: ADR-007 VIS-002; ADR-009 PM-004
-- Data: 2026-04-22
-- =============================================================================
-- Adiciona o valor 'participante' ao enum item_visibilidade.
-- Semântica: item visível apenas aos usuários registrados em item_participante.
-- Ou seja, "Responsáveis (apenas para responsáveis)" no front-end.
-- Diferente de 'privado' (somente o dono da agenda pessoal);
-- 'participante' funciona em qualquer tipo de agenda e é controlado
-- exclusivamente pela tabela item_participante.
-- =============================================================================

ALTER TYPE agenda.item_visibilidade
    ADD VALUE IF NOT EXISTS 'participante';
