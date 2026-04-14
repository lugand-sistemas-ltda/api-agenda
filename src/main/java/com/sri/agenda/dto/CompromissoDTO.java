package com.sri.agenda.dto;

import com.sri.agenda.entity.CompromissoStatus;
import com.sri.agenda.entity.CompromissoTipo;

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
        public String titulo;
        public String descricao;
        public CompromissoTipo tipo;
        public CompromissoStatus status;
        public LocalDateTime dataInicio;
        public LocalDateTime dataFim;
        public String local;
        public String observacoes;
        public UUID responsavelId;
        public List<UUID> outrosResponsaveisIds;
    }
}
