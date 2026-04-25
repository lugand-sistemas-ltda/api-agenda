package com.sri.agenda.audit;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.persistence.EntityManager;

/**
 * Injeta o contexto de auditoria como configurações transaction-local no PostgreSQL.
 *
 * <p>Deve ser chamado explicitamente no início de cada método {@code @Transactional}
 * que escreve em tabelas auditadas. O {@code set_config(key, value, true)} torna o
 * valor visível apenas dentro da transação corrente — o trigger {@code audit.registrar_evento()}
 * lê esses valores via {@code current_setting(key, true)}.
 *
 * <p>Exemplo de uso em um resource:
 * <pre>{@code
 *   @Inject AuditContextInjector auditInjector;
 *
 *   @POST
 *   @Transactional
 *   public Response criar(...) {
 *       auditInjector.injetar();
 *       // ... lógica de negócio
 *   }
 * }</pre>
 *
 * <p>Se o contexto não tiver usuário (ex.: migration, admin SQL), os valores ficam
 * vazios e o trigger os trata como NULL, registrando {@code aplicacao='desconhecido'}.
 */
@ApplicationScoped
public class AuditContextInjector {

    @Inject
    AuditContext auditContext;

    /**
     * Injeta os valores do {@link AuditContext} como configurações transaction-local.
     *
     * @param em EntityManager da transação corrente (obtido do resource que chama este método)
     */
    public void injetar(EntityManager em) {
        String usuarioId    = auditContext.getUsuarioId()     != null ? auditContext.getUsuarioId().toString()     : "";
        String sessaoId     = auditContext.getSessaoId()      != null ? auditContext.getSessaoId().toString()      : "";
        String papel        = auditContext.getPapel()         != null ? auditContext.getPapel()                    : "";
        String delegadoPor  = auditContext.getDelegadoPorId() != null ? auditContext.getDelegadoPorId().toString() : "";
        String ip           = auditContext.getIpOrigem()      != null ? auditContext.getIpOrigem()                 : "";
        String aplicacao    = auditContext.getAplicacao()     != null ? auditContext.getAplicacao()                : "api";

        em.createNativeQuery(
            "SELECT " +
            "  set_config('app.usuario_id',      :uid,        true), " +
            "  set_config('app.sessao_id',        :sid,        true), " +
            "  set_config('app.papel',            :papel,      true), " +
            "  set_config('app.delegado_por_id',  :delegado,   true), " +
            "  set_config('app.ip_origem',        :ip,         true), " +
            "  set_config('app.aplicacao',        :aplicacao,  true)"
        )
        .setParameter("uid",       usuarioId)
        .setParameter("sid",       sessaoId)
        .setParameter("papel",     papel)
        .setParameter("delegado",  delegadoPor)
        .setParameter("ip",        ip)
        .setParameter("aplicacao", aplicacao)
        .getSingleResult();
    }
}
