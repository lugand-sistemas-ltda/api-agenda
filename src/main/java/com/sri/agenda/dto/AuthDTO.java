package com.sri.agenda.dto;

import jakarta.validation.constraints.NotBlank;

/**
 * DTOs de autenticação — login / sessão / me.
 */
public class AuthDTO {

    /** Corpo do POST /api/auth/login */
    public static class LoginRequest {
        @NotBlank(message = "Matrícula é obrigatória")
        public String matricula;

        @NotBlank(message = "Senha é obrigatória")
        public String senha;
    }

    /** Corpo da resposta de login bem-sucedido e de GET /api/auth/me */
    public static class LoginResponse {
        public String sessionId;
        public String usuarioId;
        public String nome;
        public String email;
        public String matricula;
        /** Papel do usuário na unidade (ex.: "gestor", "estagiario"). Null se não encontrado. */
        public String papel;

        public LoginResponse(String sessionId, String usuarioId, String nome, String email, String matricula, String papel) {
            this.sessionId  = sessionId;
            this.usuarioId  = usuarioId;
            this.nome       = nome;
            this.email      = email;
            this.matricula  = matricula;
            this.papel      = papel;
        }
    }
}
