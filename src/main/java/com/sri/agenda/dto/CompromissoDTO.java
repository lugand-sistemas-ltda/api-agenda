package com.sri.agenda.dto;

import com.sri.agenda.entity.CompromissoStatus;
import com.sri.agenda.entity.CompromissoTipo;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public class CompromissoDTO {

    public UUID id;
    public String titulo;
    public String descricao;
    public CompromissoTipo tipo;
    public CompromissoStatus status;
    public LocalDateTime dataInicio;
    public LocalDateTime dataFim;
    public String local;
    public String observacoes;
    public UsuarioDTO responsavel;
    public List<UsuarioDTO> outrosResponsaveis;
    public LocalDateTime criadoEm;
    public LocalDateTime atualizadoEm;

    // -------------------------------------------------------------------------
    // Request payload (criação e edição)
    // -------------------------------------------------------------------------
    public static class Request {
        @NotBlank(message = "Título é obrigatório")
        public String titulo;

        public String descricao;

        @NotNull(message = "Tipo é obrigatório")
        public CompromissoTipo tipo;

        public CompromissoStatus status;

        @NotNull(message = "Data de início é obrigatória")
        public LocalDateTime dataInicio;

        @NotNull(message = "Data de término é obrigatória")
        public LocalDateTime dataFim;

        public String local;
        public String observacoes;

        @NotNull(message = "Responsável é obrigatório")
        public UUID responsavelId;

        public List<UUID> outrosResponsaveisIds;
    }
}
