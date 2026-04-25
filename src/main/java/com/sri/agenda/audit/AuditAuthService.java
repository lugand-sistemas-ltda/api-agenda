package com.sri.agenda.audit;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.persistence.EntityManager;
import jakarta.transaction.Transactional;

import java.util.UUID;

/**
 * Registra eventos de autenticação ({@code LOGIN}, {@code LOGOUT}, {@code LOGIN_FALHOU})
 * diretamente em {@code audit.log_evento}.
 *
 * <p>Usa {@code REQUIRES_NEW} para que cada evento de autenticação seja persistido
 * de forma independente da transação principal — garante que o registro de uma
 * tentativa de login com falha seja gravado mesmo que não haja commit externo.
 *
 * <p>Não utiliza {@code set_config} nem triggers — os dados de contexto (ip, sessão,
 * papel) são resolvidos na camada Java e inseridos diretamente, pois em login não
 * existe sessão ativa antes da autenticação ser concluída.
 */
@ApplicationScoped
public class AuditAuthService {

    @Inject
    EntityManager em;

    /**
     * Login bem-sucedido — sessão criada, usuário identificado.
     *
     * @param usuarioId UUID do usuário autenticado
     * @param sessaoId  UUID da sessão recém-criada
     * @param papel     papel ativo do usuário no momento do login (pode ser null)
     * @param ip        IP de origem da requisição (best-effort)
     */
    @Transactional(Transactional.TxType.REQUIRES_NEW)
    public void registrarLogin(UUID usuarioId, UUID sessaoId, String papel, String ip) {
        inserir("LOGIN", sessaoId, usuarioId, papel, sessaoId, ip, "sucesso");
    }

    /**
     * Tentativa de login com credenciais inválidas.
     *
     * <p>{@code usuarioId} pode ser {@code null} quando a matrícula não foi encontrada
     * — preservando a mesma resposta HTTP neutra do endpoint (sem revelar existência do usuário).
     *
     * @param usuarioId UUID do usuário tentado (null se matrícula inexistente)
     * @param ip        IP de origem
     */
    @Transactional(Transactional.TxType.REQUIRES_NEW)
    public void registrarLoginFalhou(UUID usuarioId, String ip) {
        inserir("LOGIN_FALHOU", null, usuarioId, null, null, ip, "negado");
    }

    /**
     * Logout — sessão invalidada pelo próprio usuário.
     *
     * @param usuarioId UUID do usuário autenticado
     * @param sessaoId  UUID da sessão encerrada
     * @param papel     papel ativo no momento do logout
     * @param ip        IP de origem
     */
    @Transactional(Transactional.TxType.REQUIRES_NEW)
    public void registrarLogout(UUID usuarioId, UUID sessaoId, String papel, String ip) {
        inserir("LOGOUT", sessaoId, usuarioId, papel, sessaoId, ip, "sucesso");
    }

    // -------------------------------------------------------------------------

    private void inserir(String operacao, UUID registroId, UUID usuarioId,
                         String papel, UUID sessaoId, String ip, String status) {
        em.createNativeQuery(
            "INSERT INTO audit.log_evento " +
            "(operacao, tabela, registro_id, usuario_id, papel_momento, sessao_id, " +
            " ip_origem, aplicacao, transacao_id, " +
            " dados_antes, dados_depois, campos_alterados, status_operacao) " +
            "VALUES " +
            "(:op, 'agenda.sessao', :regId, :uid, :papel, :sid, " +
            " :ip, 'api', txid_current(), " +
            " NULL, NULL, NULL, :status)"
        )
        .setParameter("op",     operacao)
        .setParameter("regId",  registroId)
        .setParameter("uid",    usuarioId)
        .setParameter("papel",  papel)
        .setParameter("sid",    sessaoId)
        .setParameter("ip",     ip)
        .setParameter("status", status)
        .executeUpdate();
    }
}
