package com.sri.agenda.resource;

import com.sri.agenda.dto.AgendaDTO;
import com.sri.agenda.entity.Agenda;
import com.sri.agenda.entity.GrupoMembro;
import com.sri.agenda.entity.TipoAgenda;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import org.eclipse.microprofile.openapi.annotations.Operation;
import org.eclipse.microprofile.openapi.annotations.tags.Tag;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Path("/api/agendas")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Tag(name = "Agendas")
public class AgendaResource {

    // -------------------------------------------------------------------------
    // Listar todas as agendas ativas
    // -------------------------------------------------------------------------

    @GET
    @Operation(summary = "Listar todas as agendas ativas")
    public List<AgendaDTO> listar() {
        return Agenda.<Agenda>find("ativa = true")
            .stream()
            .map(AgendaDTO::from)
            .toList();
    }

    // -------------------------------------------------------------------------
    // Agenda consolidada de um usuário (ADR-006 AG-003 / RN-002)
    //
    // Retorna:
    //   1. Agenda pessoal do usuário
    //   2. Agendas de unidade dos grupos dos quais o usuário é membro ativo
    //
    // O campo `papel` é preenchido com o papel do usuário no grupo (ou
    // "proprietario" para a agenda pessoal).
    // -------------------------------------------------------------------------

    @GET
    @Path("/consolidada")
    @Operation(summary = "Agendas consolidadas de um usuário: pessoal + unidade dos grupos em que é membro ativo")
    public List<AgendaDTO> consolidada(@QueryParam("usuarioId") UUID usuarioId) {
        if (usuarioId == null) {
            throw new BadRequestException("usuarioId é obrigatório");
        }

        List<AgendaDTO> resultado = new ArrayList<>();

        // 1. Agenda pessoal
        Agenda pessoal = Agenda
            .find("proprietario.id = ?1 AND tipo = ?2 AND ativa = true",
                  usuarioId, TipoAgenda.pessoal)
            .<Agenda>firstResultOptional()
            .orElse(null);

        if (pessoal != null) {
            AgendaDTO dto = AgendaDTO.from(pessoal);
            dto.papel = "proprietario";
            resultado.add(dto);
        }

        // 2. Agendas de unidade dos grupos em que o usuário é membro ativo
        List<GrupoMembro> memberships = GrupoMembro
            .find("usuario.id = ?1 AND ativo = true", usuarioId)
            .<GrupoMembro>list();

        for (GrupoMembro m : memberships) {
            Agenda unidade = Agenda
                .find("grupo.id = ?1 AND tipo = ?2 AND ativa = true",
                      m.grupo.id, TipoAgenda.unidade)
                .<Agenda>firstResultOptional()
                .orElse(null);

            if (unidade != null) {
                AgendaDTO dto = AgendaDTO.from(unidade);
                dto.papel = m.papel.name();
                resultado.add(dto);
            }
        }

        return resultado;
    }
}
