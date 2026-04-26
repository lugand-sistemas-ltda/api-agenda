package com.sri.agenda.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

import java.util.UUID;

public class UsuarioDTO {
    public UUID id;
    public String nome;
    public String email;
    public String matricula;

    public static class Request {
        @NotBlank(message = "Nome é obrigatório")
        public String nome;

        @NotBlank(message = "E-mail é obrigatório")
        @Email(message = "E-mail inválido")
        public String email;

        @NotBlank(message = "Matrícula é obrigatória")
        public String matricula;

        public String senha;
    }
}
