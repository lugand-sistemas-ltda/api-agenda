package com.sri.agenda.audit;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.persistence.EntityManager;
import jakarta.transaction.Transactional;

import java.util.UUID;

/**
 * Registra eventos SELECT cross-user em {@code audit.log_evento} em transação própria.
 *
 * <p>Separado do filtro para permitir {@code @Transactional} sem afetar a resposta HTTP.
 * O filtro chama este serviço após a resposta já ter sido preparada.
 */
@ApplicationScoped
public class AuditSelectService {

    @Inject
    EntityManager em;

    @Transactional(Transactional.TxType.REQUIRES_NEW)
    public void registrar(AuditContext ctx, UUID registroAlvoId, String path) {
        String tabela = path.contains("/compromissos") ? "agenda.item_agenda" : path;

        em.createNativeQuery(
            "INSERT INTO audit.log_evento " +
            "(operacao, tabela, registro_id, usuario_id, papel_momento, sessao_id, " +
            " delegado_por_id, ip_origem, aplicacao, transacao_id, " +
            " dados_antes, dados_depois, campos_alterados, status_operacao) " +
            "VALUES " +
            "('SELECT', :tabela, :alvoId, :uid, :papel, :sid, " +
            " :delegado, :ip, :aplicacao, txid_current(), " +
            " NULL, NULL, NULL, 'sucesso')"
        )
        .setParameter("tabela",    tabela)
        .setParameter("alvoId",    registroAlvoId)
        .setParameter("uid",       ctx.getUsuarioId())
        .setParameter("papel",     ctx.getPapel())
        .setParameter("sid",       ctx.getSessaoId())
        .setParameter("delegado",  ctx.getDelegadoPorId())
        .setParameter("ip",        ctx.getIpOrigem())
        .setParameter("aplicacao", ctx.getAplicacao() != null ? ctx.getAplicacao() : "api")
        .executeUpdate();
    }
}
