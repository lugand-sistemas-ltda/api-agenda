package com.sri.agenda.resource;

import com.sri.agenda.dto.CompromissoDTO;
import com.sri.agenda.dto.UsuarioDTO;
import com.sri.agenda.entity.Compromisso;
import com.sri.agenda.entity.Usuario;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.openapi.annotations.Operation;
import org.eclipse.microprofile.openapi.annotations.tags.Tag;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Path("/api/compromissos")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Tag(name = "Compromissos")
public class CompromissoResource {

    // -------------------------------------------------------------------------
    // READ
    // -------------------------------------------------------------------------

    @GET
    @Operation(summary = "Listar compromissos. Filtros opcionais: ano, mes, dia")
    public List<CompromissoDTO> listar(
        @QueryParam("ano")  Integer ano,
        @QueryParam("mes")  Integer mes,
        @QueryParam("dia")  Integer dia
    ) {
        List<Compromisso> resultado;

        if (ano != null && mes != null && dia != null) {
            LocalDateTime inicioDia = LocalDate.of(ano, mes, dia).atStartOfDay();
            LocalDateTime fimDia    = LocalDate.of(ano, mes, dia).atTime(23, 59, 59);
            resultado = Compromisso.find(
                "dataInicio >= ?1 AND dataInicio <= ?2", inicioDia, fimDia
            ).list();
        } else if (ano != null && mes != null) {
            LocalDateTime inicio = YearMonth.of(ano, mes).atDay(1).atStartOfDay();
            LocalDateTime fim    = YearMonth.of(ano, mes).atEndOfMonth().atTime(23, 59, 59);
            resultado = Compromisso.find(
                "dataInicio >= ?1 AND dataInicio <= ?2", inicio, fim
            ).list();
        } else {
            resultado = Compromisso.listAll();
        }

        return resultado.stream().map(this::toDTO).collect(Collectors.toList());
    }

    @GET
    @Path("/{id}")
    @Operation(summary = "Buscar compromisso por ID")
    public Response buscar(@PathParam("id") UUID id) {
        Compromisso c = Compromisso.findById(id);
        if (c == null) return Response.status(Response.Status.NOT_FOUND).build();
        return Response.ok(toDTO(c)).build();
    }

    // -------------------------------------------------------------------------
    // CREATE
    // -------------------------------------------------------------------------

    @POST
    @Transactional
    @Operation(summary = "Criar compromisso")
    public Response criar(CompromissoDTO.Request req) {
        Usuario responsavel = Usuario.findById(req.responsavelId);
        if (responsavel == null) {
            return Response.status(Response.Status.BAD_REQUEST)
                .entity("{\"erro\":\"Responsável não encontrado\"}")
                .build();
        }

        Compromisso c = new Compromisso();
        c.titulo      = req.titulo;
        c.descricao   = req.descricao;
        c.tipo        = req.tipo;
        c.status      = req.status != null ? req.status : c.status;
        c.dataInicio  = req.dataInicio;
        c.dataFim     = req.dataFim;
        c.local       = req.local;
        c.observacoes = req.observacoes;
        c.responsavel = responsavel;

        if (req.outrosResponsaveisIds != null) {
            c.outrosResponsaveis = req.outrosResponsaveisIds.stream()
                .map(id -> (Usuario) Usuario.findById(id))
                .filter(u -> u != null)
                .collect(Collectors.toList());
        }

        c.persist();
        return Response.status(Response.Status.CREATED).entity(toDTO(c)).build();
    }

    // -------------------------------------------------------------------------
    // UPDATE
    // -------------------------------------------------------------------------

    @PUT
    @Path("/{id}")
    @Transactional
    @Operation(summary = "Atualizar compromisso")
    public Response atualizar(@PathParam("id") UUID id, CompromissoDTO.Request req) {
        Compromisso c = Compromisso.findById(id);
        if (c == null) return Response.status(Response.Status.NOT_FOUND).build();

        if (req.titulo      != null) c.titulo      = req.titulo;
        if (req.descricao   != null) c.descricao   = req.descricao;
        if (req.tipo        != null) c.tipo        = req.tipo;
        if (req.status      != null) c.status      = req.status;
        if (req.dataInicio  != null) c.dataInicio  = req.dataInicio;
        if (req.dataFim     != null) c.dataFim     = req.dataFim;
        if (req.local       != null) c.local       = req.local;
        if (req.observacoes != null) c.observacoes = req.observacoes;

        if (req.responsavelId != null) {
            Usuario responsavel = Usuario.findById(req.responsavelId);
            if (responsavel == null) {
                return Response.status(Response.Status.BAD_REQUEST)
                    .entity("{\"erro\":\"Responsável não encontrado\"}")
                    .build();
            }
            c.responsavel = responsavel;
        }

        if (req.outrosResponsaveisIds != null) {
            c.outrosResponsaveis = req.outrosResponsaveisIds.stream()
                .map(uid -> (Usuario) Usuario.findById(uid))
                .filter(u -> u != null)
                .collect(Collectors.toList());
        }

        return Response.ok(toDTO(c)).build();
    }

    // -------------------------------------------------------------------------
    // DELETE
    // -------------------------------------------------------------------------

    @DELETE
    @Path("/{id}")
    @Transactional
    @Operation(summary = "Remover compromisso")
    public Response remover(@PathParam("id") UUID id) {
        boolean deleted = Compromisso.deleteById(id);
        return deleted
            ? Response.noContent().build()
            : Response.status(Response.Status.NOT_FOUND).build();
    }

    // -------------------------------------------------------------------------
    // HELPER
    // -------------------------------------------------------------------------

    private CompromissoDTO toDTO(Compromisso c) {
        CompromissoDTO dto = new CompromissoDTO();
        dto.id          = c.id;
        dto.titulo      = c.titulo;
        dto.descricao   = c.descricao;
        dto.tipo        = c.tipo;
        dto.status      = c.status;
        dto.dataInicio  = c.dataInicio;
        dto.dataFim     = c.dataFim;
        dto.local       = c.local;
        dto.observacoes = c.observacoes;
        dto.criadoEm    = c.criadoEm;
        dto.atualizadoEm = c.atualizadoEm;

        UsuarioDTO resp = new UsuarioDTO();
        resp.id    = c.responsavel.id;
        resp.nome  = c.responsavel.nome;
        resp.email = c.responsavel.email;
        dto.responsavel = resp;

        dto.outrosResponsaveis = c.outrosResponsaveis.stream().map(u -> {
            UsuarioDTO ud = new UsuarioDTO();
            ud.id    = u.id;
            ud.nome  = u.nome;
            ud.email = u.email;
            return ud;
        }).collect(Collectors.toList());

        return dto;
    }
}
