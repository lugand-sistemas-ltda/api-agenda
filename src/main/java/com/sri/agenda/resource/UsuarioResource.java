package com.sri.agenda.resource;

import com.sri.agenda.dto.UsuarioDTO;
import com.sri.agenda.entity.GrupoMembro;
import com.sri.agenda.entity.Usuario;
import jakarta.transaction.Transactional;
import jakarta.validation.Valid;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.openapi.annotations.Operation;
import org.eclipse.microprofile.openapi.annotations.tags.Tag;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Path("/api/usuarios")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Tag(name = "Usuários")
public class UsuarioResource {

    @GET
    @Operation(summary = "Listar usuários. Filtro opcional: grupoId (retorna apenas membros ativos do grupo)")
    public List<UsuarioDTO> listar(@QueryParam("grupoId") UUID grupoId) {
        if (grupoId != null) {
            // Retorna apenas membros ativos do grupo indicado
            return GrupoMembro.<GrupoMembro>find("grupo.id = ?1 AND ativo = true", grupoId)
                .stream()
                .map(m -> toDTO(m.usuario))
                .collect(Collectors.toList());
        }
        return Usuario.<Usuario>listAll()
            .stream()
            .map(this::toDTO)
            .collect(Collectors.toList());
    }

    @GET
    @Path("/{id}")
    @Operation(summary = "Buscar usuário por ID")
    public Response buscar(@PathParam("id") UUID id) {
        Usuario u = Usuario.findById(id);
        if (u == null) return Response.status(Response.Status.NOT_FOUND).build();
        return Response.ok(toDTO(u)).build();
    }

    @POST
    @Transactional
    @Operation(summary = "Criar usuário")
    public Response criar(@Valid UsuarioDTO.Request req) {
        Usuario u = new Usuario();
        u.nome  = req.nome;
        u.email = req.email;
        u.persist();
        return Response.status(Response.Status.CREATED).entity(toDTO(u)).build();
    }

    @PUT
    @Path("/{id}")
    @Transactional
    @Operation(summary = "Atualizar usuário")
    public Response atualizar(@PathParam("id") UUID id, @Valid UsuarioDTO.Request req) {
        Usuario u = Usuario.findById(id);
        if (u == null) return Response.status(Response.Status.NOT_FOUND).build();
        u.nome  = req.nome;
        u.email = req.email;
        return Response.ok(toDTO(u)).build();
    }

    @DELETE
    @Path("/{id}")
    @Transactional
    @Operation(summary = "Remover usuário")
    public Response remover(@PathParam("id") UUID id) {
        boolean deleted = Usuario.deleteById(id);
        return deleted
            ? Response.noContent().build()
            : Response.status(Response.Status.NOT_FOUND).build();
    }

    // -------------------------------------------------------------------------
    private UsuarioDTO toDTO(Usuario u) {
        UsuarioDTO dto = new UsuarioDTO();
        dto.id        = u.id;
        dto.nome      = u.nome;
        dto.email     = u.email;
        dto.matricula = u.matricula;
        return dto;
    }
}
