package com.sri.agenda.audit;

import jakarta.inject.Inject;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerResponseContext;
import org.jboss.resteasy.reactive.server.ServerResponseFilter;

import java.util.UUID;

/**
 * Audita acessos cross-user em {@code GET /api/compromissos?usuarioId=...}.
 *
 * <p>Regra: se o parâmetro {@code usuarioId} está presente E é diferente do usuário
 * autenticado, registra um evento SELECT em {@code audit.log_evento}. Leituras
 * da própria agenda não geram ruído na trilha.
 *
 * <p>Triggers PostgreSQL não capturam SELECTs, por isso este filtro é necessário
 * para cobrir o padrão de delegação (ex.: gestor vendo agenda do estagiário).
 *
 * <p>O INSERT é feito em transação separada para não interferir na resposta.
 */
public class AuditSelectFilter {

    @Inject
    AuditContext auditContext;

    @Inject
    AuditSelectService auditSelectService;

    @ServerResponseFilter
    public void filtrar(ContainerRequestContext reqCtx, ContainerResponseContext resCtx) {
        // Aplica apenas a GETs bem-sucedidos de compromissos com usuarioId externo
        String path = reqCtx.getUriInfo().getPath();
        if (!path.startsWith("/api/compromissos")) return;
        if (!"GET".equalsIgnoreCase(reqCtx.getMethod())) return;
        if (resCtx.getStatus() < 200 || resCtx.getStatus() >= 300) return;
        if (!auditContext.temUsuario()) return;

        String usuarioIdParam = reqCtx.getUriInfo().getQueryParameters().getFirst("usuarioId");
        if (usuarioIdParam == null || usuarioIdParam.isBlank()) return;

        UUID alvoId;
        try {
            alvoId = UUID.fromString(usuarioIdParam);
        } catch (IllegalArgumentException e) {
            return;
        }

        // Só audita se o alvo é diferente do usuário autenticado
        if (alvoId.equals(auditContext.getUsuarioId())) return;

        auditSelectService.registrar(auditContext, alvoId, path);
    }
}
