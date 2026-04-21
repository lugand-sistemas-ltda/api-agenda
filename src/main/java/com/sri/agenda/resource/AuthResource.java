package com.sri.agenda.resource;

import at.favre.lib.crypto.bcrypt.BCrypt;
import com.sri.agenda.dto.AuthDTO;
import com.sri.agenda.entity.Sessao;
import com.sri.agenda.entity.Usuario;
import jakarta.transaction.Transactional;
import jakarta.validation.Valid;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.openapi.annotations.Operation;
import org.eclipse.microprofile.openapi.annotations.tags.Tag;

import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@Path("/api/auth")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Tag(name = "Autenticação")
public class AuthResource {

    private Response unauthorized() {
        return Response.status(Response.Status.UNAUTHORIZED)
                .entity(Map.of("erro", "Credenciais inválidas"))
                .build();
    }

    // =========================================================================
    // POST /api/auth/login
    // =========================================================================

    @POST
    @Path("/login")
    @Transactional
    @Operation(summary = "Login por matrícula e senha — retorna ID de sessão opaco")
    public Response login(@Valid AuthDTO.LoginRequest body) {
        // Busca usuário pela matrícula
        Optional<Usuario> opt = Usuario.find("matricula", body.matricula).firstResultOptional();
        if (opt.isEmpty()) {
            return unauthorized();
        }
        Usuario usuario = opt.get();

        // Verifica senha com bcrypt (hash gerado via pgcrypto em formato $2a$)
        BCrypt.Result resultado = BCrypt.verifyer()
                .verify(body.senha.toCharArray(), usuario.senhaHash);
        if (!resultado.verified) {
            return unauthorized();
        }

        // Cria sessão (expira em 8h, vide Sessao.expiraEm)
        Sessao sessao = new Sessao();
        sessao.usuario = usuario;
        sessao.persist();

        return Response.ok(toResponse(sessao)).build();
    }

    // =========================================================================
    // GET /api/auth/me
    // =========================================================================

    @GET
    @Path("/me")
    @Operation(summary = "Valida sessão e retorna dados do usuário autenticado")
    public Response me(@HeaderParam("X-Session-Id") String sessionId) {
        Sessao sessao = resolveSession(sessionId);
        if (sessao == null) {
            return Response.status(Response.Status.UNAUTHORIZED)
                    .entity(Map.of("erro", "Sessão inválida ou expirada"))
                    .build();
        }
        return Response.ok(toResponse(sessao)).build();
    }

    // =========================================================================
    // POST /api/auth/logout
    // =========================================================================

    @POST
    @Path("/logout")
    @Transactional
    @Operation(summary = "Invalida a sessão atual")
    public Response logout(@HeaderParam("X-Session-Id") String sessionId) {
        if (sessionId != null && !sessionId.isBlank()) {
            try {
                Sessao.deleteById(UUID.fromString(sessionId));
            } catch (IllegalArgumentException ignored) {
                // UUID malformado — ignorar silenciosamente
            }
        }
        return Response.noContent().build();
    }

    // =========================================================================
    // Utilitários privados
    // =========================================================================

    private Sessao resolveSession(String sessionId) {
        if (sessionId == null || sessionId.isBlank()) return null;
        try {
            return Sessao.findValid(UUID.fromString(sessionId)).orElse(null);
        } catch (IllegalArgumentException e) {
            return null;
        }
    }

    private AuthDTO.LoginResponse toResponse(Sessao s) {
        return new AuthDTO.LoginResponse(
                s.id.toString(),
                s.usuario.id.toString(),
                s.usuario.nome,
                s.usuario.email,
                s.usuario.matricula
        );
    }
}
