-- V11: Triggers de auditoria nas 4 tabelas prioritárias
-- ADR-010: item_agenda, item_participante, usuario, grupo_membro
--
-- Decisão de escopo (tabelas SEM trigger — auditadas de outra forma):
--   agenda.sessao           → login/logout auditado na camada de aplicação (AuditSelectFilter)
--   agenda.permissao        → versionada via Flyway; DDL não dispara DML triggers
--   agenda.papel_permissao  → idem Flyway

-- =============================================================================
-- 1. agenda.item_agenda
-- =============================================================================

CREATE TRIGGER trg_audit_item_agenda
    AFTER INSERT OR UPDATE OR DELETE ON agenda.item_agenda
    FOR EACH ROW EXECUTE FUNCTION audit.registrar_evento();

COMMENT ON TRIGGER trg_audit_item_agenda ON agenda.item_agenda IS
    'Trilha de auditoria: toda escrita em item_agenda é registrada em audit.log_evento.';

-- =============================================================================
-- 2. agenda.item_participante  (PK composta: item_id + usuario_id)
-- =============================================================================

CREATE TRIGGER trg_audit_item_participante
    AFTER INSERT OR UPDATE OR DELETE ON agenda.item_participante
    FOR EACH ROW EXECUTE FUNCTION audit.registrar_evento();

COMMENT ON TRIGGER trg_audit_item_participante ON agenda.item_participante IS
    'Trilha de auditoria: registro_id ficará NULL (PK composta). '
    'Identifique o registro por dados_antes.item_id + dados_antes.usuario_id.';

-- =============================================================================
-- 3. agenda.usuario
-- =============================================================================

CREATE TRIGGER trg_audit_usuario
    AFTER INSERT OR UPDATE OR DELETE ON agenda.usuario
    FOR EACH ROW EXECUTE FUNCTION audit.registrar_evento();

COMMENT ON TRIGGER trg_audit_usuario ON agenda.usuario IS
    'Trilha de auditoria: senha_hash é mascarada como [REDACTED] antes da gravação.';

-- =============================================================================
-- 4. agenda.grupo_membro  (PK composta: grupo_id + usuario_id)
-- =============================================================================

CREATE TRIGGER trg_audit_grupo_membro
    AFTER INSERT OR UPDATE OR DELETE ON agenda.grupo_membro
    FOR EACH ROW EXECUTE FUNCTION audit.registrar_evento();

COMMENT ON TRIGGER trg_audit_grupo_membro ON agenda.grupo_membro IS
    'Trilha de auditoria: mudanças de grupo afetam visibilidade de todos os itens do grupo. '
    'registro_id ficará NULL (PK composta). Identifique por dados_antes.grupo_id + dados_antes.usuario_id.';
