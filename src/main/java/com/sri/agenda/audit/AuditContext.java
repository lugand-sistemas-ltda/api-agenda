package com.sri.agenda.audit;

import jakarta.enterprise.context.RequestScoped;
import java.util.UUID;

/**
 * Contexto de auditoria com escopo de requisição HTTP.
 *
 * <p>Preenchido pelo {@link AuditContextFilter} antes do processamento do recurso.
 * Consumido pelo {@link AuditContextInjector} para injetar os valores como
 * configurações transaction-local no PostgreSQL ({@code set_config(..., true)}),
 * tornando-os visíveis para a função trigger {@code audit.registrar_evento()}.
 */
@RequestScoped
public class AuditContext {

    private UUID   usuarioId;
    private UUID   sessaoId;
    private String papel;
    private UUID   delegadoPorId;
    private String ipOrigem;
    private String aplicacao = "api";

    public UUID getUsuarioId()          { return usuarioId; }
    public UUID getSessaoId()           { return sessaoId; }
    public String getPapel()            { return papel; }
    public UUID getDelegadoPorId()      { return delegadoPorId; }
    public String getIpOrigem()         { return ipOrigem; }
    public String getAplicacao()        { return aplicacao; }

    public void setUsuarioId(UUID v)    { this.usuarioId    = v; }
    public void setSessaoId(UUID v)     { this.sessaoId     = v; }
    public void setPapel(String v)      { this.papel        = v; }
    public void setDelegadoPorId(UUID v){ this.delegadoPorId = v; }
    public void setIpOrigem(String v)   { this.ipOrigem     = v; }
    public void setAplicacao(String v)  { this.aplicacao    = v; }

    public boolean temUsuario() {
        return usuarioId != null;
    }
}
