package com.sri.agenda.dto;

import com.sri.agenda.entity.ItemRenderizacao;
import com.sri.agenda.entity.ItemStatus;
import com.sri.agenda.entity.ItemTipo;
import com.sri.agenda.entity.ItemVisibilidade;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public class CompromissoDTO {

    public UUID id;
    public String titulo;
    public String descricao;
    public ItemTipo tipo;
    public ItemStatus status;
    public ItemRenderizacao renderizacao;
    public boolean exigePresenca;
    public LocalDateTime dataInicio;
    public LocalDateTime dataFim;
    public String local;
    public String observacoes;
    public UsuarioDTO responsavel;
    public List<UsuarioDTO> outrosResponsaveis;
    public UUID agendaId;
    public UUID itemPaiId;
    public ItemVisibilidade visibilidade;
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
        public ItemTipo tipo;

        public ItemStatus status;

        /** Se não informado, herdado do tipo via defaults (ADR-005 IA-003). */
        public ItemRenderizacao renderizacao;

        /** Se não informado, herdado do tipo via defaults (ADR-005 IA-003). */
        public Boolean exigePresenca;

        @NotNull(message = "Data de início é obrigatória")
        public LocalDateTime dataInicio;

        @NotNull(message = "Data de término é obrigatória")
        public LocalDateTime dataFim;

        public String local;
        public String observacoes;

        /**
         * Obrigatório para renderizacao = evento.
         * Opcional / ignorado para renderizacao = fundo_dia.
         */
        public UUID responsavelId;

        public List<UUID> outrosResponsaveisIds;

        /** Agenda de destino. Se null, usa agenda da unidade padrão. */
        public UUID agendaId;

        /** Para containment: ID do período pai (ADR-005 IA-007). */
        public UUID itemPaiId;

        /** Visibilidade do item (ADR-007 VIS-002). Se null, usa 'privado'. */
        public ItemVisibilidade visibilidade;
    }
}

