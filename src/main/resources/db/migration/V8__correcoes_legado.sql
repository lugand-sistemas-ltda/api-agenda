-- =============================================================================
-- V8 — Correções de dados legados e enforcement de participação
-- Referências: ADR-007 (visibilidade), ADR-009 PM-003 (participação)
-- Data: 2026-04-23
-- =============================================================================
-- Correções:
--   1. ponto_facultativo em agenda 'sistema' → visibilidade 'global'
--      (Bug introduzido em V4: itens movidos para Calendário Nacional ficaram
--       com visibilidade 'unidade', mas a agenda sistema não tem grupo_id nem
--       proprietario_id — VIS-004 não conseguia resolver os membros destinatários)
--
--   2. Registrar item_participante retroativamente para itens legados
--      (Itens criados antes de V5/enforcement têm criado_por_id = NULL e nenhum
--       registro em item_participante → ficam invisíveis a todos, incluindo o
--       próprio responsável. Esta migration insere o registro 'responsavel' para
--       cada item que possui responsavel_id mas nenhum participante cadastrado.)
-- =============================================================================


-- =============================================================================
-- 1. Corrigir visibilidade de ponto_facultativo no Calendário Nacional
--
-- Semântica: "ponto_facultativo" na agenda de sistema (Calendário Nacional)
-- tem escopo nacional → deve ser 'global', não 'unidade'.
-- Pontos facultativos em agendas de unidade (grupo_id NOT NULL) permanecem
-- 'unidade' — estão corretamente escopados ao grupo.
-- =============================================================================

UPDATE agenda.item_agenda ia
SET    visibilidade = 'global'
FROM   agenda.agenda a
WHERE  ia.agenda_id = a.id
  AND  ia.tipo::text = 'ponto_facultativo'
  AND  a.tipo = 'sistema';


-- =============================================================================
-- 2. Registrar participante 'responsavel' para itens legados sem item_participante
--
-- Critério de seleção:
--   • criado_por_id IS NULL → item pré-V5 (sem enforcement de sessão)
--   • responsavel_id IS NOT NULL → existe um responsável identificado
--   • não existe ainda nenhum registro em item_participante para este item
--     (evita duplicação caso a migration seja re-executada acidentalmente)
-- =============================================================================

INSERT INTO agenda.item_participante (
    item_id,
    usuario_id,
    papel_no_item,
    visivel_na_agenda,
    aceito
)
SELECT
    ia.id          AS item_id,
    ia.responsavel_id AS usuario_id,
    'responsavel'  AS papel_no_item,
    true           AS visivel_na_agenda,
    true           AS aceito
FROM agenda.item_agenda ia
LEFT JOIN agenda.item_participante ip
       ON ip.item_id = ia.id
WHERE  ia.responsavel_id IS NOT NULL
  AND  ia.criado_por_id  IS NULL
  AND  ip.item_id        IS NULL;
