package com.sri.agenda.resource;

import com.sri.agenda.dto.CompromissoDTO;
import com.sri.agenda.dto.UsuarioDTO;
import com.sri.agenda.entity.Agenda;
import com.sri.agenda.entity.Compromisso;
import com.sri.agenda.entity.ItemRenderizacao;
import com.sri.agenda.entity.Usuario;
import jakarta.transaction.Transactional;
import jakarta.validation.Valid;
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
    @Operation(summary = "Listar itens de agenda. Filtros opcionais: ano, mes, dia, agendaId")
    public List<CompromissoDTO> listar(
        @QueryParam("ano")      Integer ano,
        @QueryParam("mes")      Integer mes,
        @QueryParam("dia")      Integer dia,
        @QueryParam("agendaId") UUID agendaId
    ) {
        List<Compromisso> resultado;

        if (ano != null && mes != null && dia != null) {
            LocalDateTime inicioDia = LocalDate.of(ano, mes, dia).atStartOfDay();
            LocalDateTime fimDia    = LocalDate.of(ano, mes, dia).atTime(23, 59, 59);
            if (agendaId != null) {
                resultado = Compromisso.find(
                    "dataInicio >= ?1 AND dataInicio <= ?2 AND agenda.id = ?3",
                    inicioDia, fimDia, agendaId
                ).list();
            } else {
                resultado = Compromisso.find(
                    "dataInicio >= ?1 AND dataInicio <= ?2", inicioDia, fimDia
                ).list();
            }
        } else if (ano != null && mes != null) {
            LocalDateTime inicio = YearMonth.of(ano, mes).atDay(1).atStartOfDay();
            LocalDateTime fim    = YearMonth.of(ano, mes).atEndOfMonth().atTime(23, 59, 59);
            if (agendaId != null) {
                resultado = Compromisso.find(
                    "dataInicio >= ?1 AND dataInicio <= ?2 AND agenda.id = ?3",
                    inicio, fim, agendaId
                ).list();
            } else {
                resultado = Compromisso.find(
                    "dataInicio >= ?1 AND dataInicio <= ?2", inicio, fim
                ).list();
            }
        } else {
            resultado = agendaId != null
                ? Compromisso.find("agenda.id = ?1", agendaId).list()
                : Compromisso.listAll();
        }

        return resultado.stream().map(this::toDTO).collect(Collectors.toList());
    }

    @GET
    @Path("/{id}")
    @Operation(summary = "Buscar item de agenda por ID")
    public Response buscar(@PathParam("id") UUID id) {
        Compromisso c = Compromisso.findById(id);
        if (c == null) return Response.status(Response.Status.NOT_FOUND).build();
        return Response.ok(toDTO(c)).build();
    }

    // -------------------------------------------------------------------------
    // CONFLITO (ADR-005 IA-006 / CONFLITO-B / RN-008)
    // -------------------------------------------------------------------------

    @GET
    @Path("/conflito")
    @Operation(summary = "Verificar conflitos de agenda para um responsável no intervalo informado. " +
                         "Aplica-se apenas a itens com exige_presenca = true (CONFLITO-B).")
    public List<CompromissoDTO> verificarConflito(
        @QueryParam("responsavelId") @jakarta.validation.constraints.NotNull UUID responsavelId,
        @QueryParam("inicio")        @jakarta.validation.constraints.NotNull LocalDateTime inicio,
        @QueryParam("fim")           @jakarta.validation.constraints.NotNull LocalDateTime fim,
        @QueryParam("excluirId")     UUID excluirId
    ) {
        return Compromisso.findConflitos(responsavelId, inicio, fim, excluirId)
            .stream().map(this::toDTO).collect(Collectors.toList());
    }

    // -------------------------------------------------------------------------
    // CREATE
    // -------------------------------------------------------------------------

    @POST
    @Transactional
    @Operation(summary = "Criar item de agenda")
    public Response criar(@Valid CompromissoDTO.Request req) {
        Compromisso c = new Compromisso();
        c.titulo      = req.titulo;
        c.descricao   = req.descricao;
        c.tipo        = req.tipo;
        c.status      = req.status != null ? req.status : c.status;
        c.dataInicio  = req.dataInicio;
        c.dataFim     = req.dataFim;
        c.local       = req.local;
        c.observacoes = req.observacoes;

        // Defaults de renderizacao e exigePresenca por tipo (ADR-005 IA-003)
        c.renderizacao = req.renderizacao != null
            ? req.renderizacao
            : defaultRenderizacao(req.tipo.name());
        c.exigePresenca = req.exigePresenca != null
            ? req.exigePresenca
            : defaultExigePresenca(req.tipo.name());

        // Responsável: obrigatório para eventos
        if (c.renderizacao == ItemRenderizacao.evento) {
            if (req.responsavelId == null) {
                return Response.status(Response.Status.BAD_REQUEST)
                    .entity("{\"erro\":\"Responsável é obrigatório para itens do tipo evento\"}")
                    .build();
            }
            Usuario responsavel = Usuario.findById(req.responsavelId);
            if (responsavel == null) {
                return Response.status(Response.Status.BAD_REQUEST)
                    .entity("{\"erro\":\"Responsável não encontrado\"}")
                    .build();
            }
            c.responsavel = responsavel;
        }

        // Agenda de destino
        UUID agendaAlvo = req.agendaId != null
            ? req.agendaId
            : UUID.fromString("00000000-0000-0000-0000-000000000020"); // padrão: unidade
        Agenda agenda = Agenda.findById(agendaAlvo);
        if (agenda == null) {
            return Response.status(Response.Status.BAD_REQUEST)
                .entity("{\"erro\":\"Agenda não encontrada\"}")
                .build();
        }
        c.agenda = agenda;

        // Item pai (containment)
        if (req.itemPaiId != null) {
            Compromisso pai = Compromisso.findById(req.itemPaiId);
            if (pai == null) {
                return Response.status(Response.Status.BAD_REQUEST)
                    .entity("{\"erro\":\"Item pai não encontrado\"}")
                    .build();
            }
            c.itemPai = pai;
        }

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
    @Operation(summary = "Atualizar item de agenda")
    public Response atualizar(@PathParam("id") UUID id, @Valid CompromissoDTO.Request req) {
        Compromisso c = Compromisso.findById(id);
        if (c == null) return Response.status(Response.Status.NOT_FOUND).build();

        if (req.titulo        != null) c.titulo        = req.titulo;
        if (req.descricao     != null) c.descricao     = req.descricao;
        if (req.tipo          != null) c.tipo          = req.tipo;
        if (req.status        != null) c.status        = req.status;
        if (req.renderizacao  != null) c.renderizacao  = req.renderizacao;
        if (req.exigePresenca != null) c.exigePresenca = req.exigePresenca;
        if (req.dataInicio    != null) c.dataInicio    = req.dataInicio;
        if (req.dataFim       != null) c.dataFim       = req.dataFim;
        if (req.local         != null) c.local         = req.local;
        if (req.observacoes   != null) c.observacoes   = req.observacoes;

        if (req.responsavelId != null) {
            Usuario responsavel = Usuario.findById(req.responsavelId);
            if (responsavel == null) {
                return Response.status(Response.Status.BAD_REQUEST)
                    .entity("{\"erro\":\"Responsável não encontrado\"}")
                    .build();
            }
            c.responsavel = responsavel;
        }

        if (req.agendaId != null) {
            Agenda agenda = Agenda.findById(req.agendaId);
            if (agenda == null) {
                return Response.status(Response.Status.BAD_REQUEST)
                    .entity("{\"erro\":\"Agenda não encontrada\"}")
                    .build();
            }
            c.agenda = agenda;
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
    @Operation(summary = "Remover item de agenda")
    public Response remover(@PathParam("id") UUID id) {
        boolean deleted = Compromisso.deleteById(id);
        return deleted
            ? Response.noContent().build()
            : Response.status(Response.Status.NOT_FOUND).build();
    }

    // -------------------------------------------------------------------------
    // HELPERS
    // -------------------------------------------------------------------------

    private CompromissoDTO toDTO(Compromisso c) {
        CompromissoDTO dto = new CompromissoDTO();
        dto.id             = c.id;
        dto.titulo         = c.titulo;
        dto.descricao      = c.descricao;
        dto.tipo           = c.tipo;
        dto.status         = c.status;
        dto.renderizacao   = c.renderizacao;
        dto.exigePresenca  = c.exigePresenca;
        dto.dataInicio     = c.dataInicio;
        dto.dataFim        = c.dataFim;
        dto.local          = c.local;
        dto.observacoes    = c.observacoes;
        dto.agendaId       = c.agenda != null ? c.agenda.id : null;
        dto.itemPaiId      = c.itemPai != null ? c.itemPai.id : null;
        dto.criadoEm       = c.criadoEm;
        dto.atualizadoEm   = c.atualizadoEm;

        if (c.responsavel != null) {
            UsuarioDTO resp = new UsuarioDTO();
            resp.id    = c.responsavel.id;
            resp.nome  = c.responsavel.nome;
            resp.email = c.responsavel.email;
            dto.responsavel = resp;
        }

        dto.outrosResponsaveis = c.outrosResponsaveis.stream().map(u -> {
            UsuarioDTO ud = new UsuarioDTO();
            ud.id    = u.id;
            ud.nome  = u.nome;
            ud.email = u.email;
            return ud;
        }).collect(Collectors.toList());

        return dto;
    }

    /** Valor padrão de renderizacao baseado no tipo (ADR-005 IA-003). */
    private ItemRenderizacao defaultRenderizacao(String tipo) {
        return switch (tipo) {
            case "feriado", "ponto_facultativo", "recesso" -> ItemRenderizacao.fundo_dia;
            case "periodo" -> ItemRenderizacao.periodo;
            default -> ItemRenderizacao.evento;
        };
    }

    /** Valor padrão de exige_presenca baseado no tipo (ADR-005 IA-003). */
    private boolean defaultExigePresenca(String tipo) {
        return switch (tipo) {
            case "oitiva", "operacao" -> true;
            default -> false;
        };
    }
}
