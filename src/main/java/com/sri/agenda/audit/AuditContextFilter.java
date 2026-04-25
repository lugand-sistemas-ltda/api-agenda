package com.sri.agenda.audit;

import com.sri.agenda.entity.GrupoMembro;
import com.sri.agenda.entity.Sessao;
import jakarta.inject.Inject;
import jakarta.ws.rs.container.ContainerRequestContext;
import org.jboss.resteasy.reactive.server.ServerRequestFilter;

import java.util.UUID;

/**
 * Filtro de requisição que resolve a sessão HTTP e popula o {@link AuditContext}.
 *
 * <p>Executa antes de qualquer método de recurso. Não bloqueia requisições sem
 * sessão — endpoints públicos (ex.: login) simplesmente terão {@code usuarioId = null}
 * na trilha de auditoria.
 *
 * <p>O IP de origem é lido de {@code X-Forwarded-For} (proxy reverso) ou
 * {@code X-Real-IP}, ambos opcionais.
 */
public class AuditContextFilter {

    @Inject
    AuditContext auditContext;

    @ServerRequestFilter
    public void popular(ContainerRequestContext ctx) {
        // IP de origem (best-effort; pode ser null se não houver proxy reverso)
        String ip = ctx.getHeaderString("X-Forwarded-For");
        if (ip == null || ip.isBlank()) {
            ip = ctx.getHeaderString("X-Real-IP");
        }
        auditContext.setIpOrigem(ip);
        auditContext.setAplicacao("api");

        // Sessão HTTP
        String sessionHeader = ctx.getHeaderString("X-Session-Id");
        if (sessionHeader == null || sessionHeader.isBlank()) {
            return;
        }

        UUID sessaoUUID;
        try {
            sessaoUUID = UUID.fromString(sessionHeader);
        } catch (IllegalArgumentException e) {
            return;
        }

        Sessao.findValid(sessaoUUID).ifPresent(sessao -> {
            auditContext.setSessaoId(sessao.id);
            auditContext.setUsuarioId(sessao.usuario.id);

            // Papel ativo do usuário (primeiro grupo ativo encontrado)
            GrupoMembro.<GrupoMembro>find("usuario.id = ?1 and ativo = true", sessao.usuario.id)
                    .firstResultOptional()
                    .ifPresent(gm -> auditContext.setPapel(gm.papel.name()));
        });
    }
}
