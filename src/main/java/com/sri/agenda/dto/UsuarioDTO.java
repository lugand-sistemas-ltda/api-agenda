package com.sri.agenda.dto;

import java.util.UUID;

public class UsuarioDTO {
    public UUID id;
    public String nome;
    public String email;

    public static class Request {
        public String nome;
        public String email;
    }
}
