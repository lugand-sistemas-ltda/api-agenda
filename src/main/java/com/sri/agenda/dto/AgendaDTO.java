package com.sri.agenda.dto;

import com.sri.agenda.entity.Agenda;
import com.sri.agenda.entity.TipoAgenda;

import java.util.UUID;

/**
 * DTO de Agenda para serialização REST.
 *
 * Expõe apenas os campos necessários para o front-end:
 * - seleção de agenda no seletor de usuário
 * - exibição de tipo e nome no AppHeader
 */
public class AgendaDTO {

    public UUID       id;
    public String     nome;
    public TipoAgenda tipo;
    /** ID do proprietário — preenchido apenas se tipo = pessoal */
    public UUID       proprietarioId;
    /** ID do grupo — preenchido apenas se tipo = grupo | unidade */
    public UUID       grupoId;
    public boolean    ativa;

    /** Papel do usuário solicitante nesta agenda (preenchido apenas em /consolidada) */
    public String papel;

    public static AgendaDTO from(Agenda a) {
        AgendaDTO dto = new AgendaDTO();
        dto.id             = a.id;
        dto.nome           = a.nome;
        dto.tipo           = a.tipo;
        dto.proprietarioId = a.proprietario != null ? a.proprietario.id : null;
        dto.grupoId        = a.grupo        != null ? a.grupo.id        : null;
        dto.ativa          = a.ativa;
        return dto;
    }
}
