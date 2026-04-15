package com.sri.agenda.entity;

import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.persistence.*;
import java.io.Serializable;
import java.time.LocalDateTime;
import java.util.Objects;
import java.util.UUID;

/**
 * Membro de um grupo com papel (ADR-006 GR-003).
 * Chave primária composta: (grupo_id, usuario_id).
 */
@Entity
@Table(name = "grupo_membro", schema = "agenda")
public class GrupoMembro extends PanacheEntityBase {

    @EmbeddedId
    public GrupoMembroId id = new GrupoMembroId();

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("grupoId")
    @JoinColumn(name = "grupo_id")
    public Grupo grupo;

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("usuarioId")
    @JoinColumn(name = "usuario_id")
    public Usuario usuario;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    public PapelGrupo papel;

    @Column(nullable = false)
    public boolean ativo = true;

    @Column(nullable = false, updatable = false)
    public LocalDateTime desde = LocalDateTime.now();

    // -------------------------------------------------------------------------
    // Chave composta embarcada
    // -------------------------------------------------------------------------

    @Embeddable
    public static class GrupoMembroId implements Serializable {
        public UUID grupoId;
        public UUID usuarioId;

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (!(o instanceof GrupoMembroId)) return false;
            GrupoMembroId that = (GrupoMembroId) o;
            return Objects.equals(grupoId, that.grupoId) &&
                   Objects.equals(usuarioId, that.usuarioId);
        }

        @Override
        public int hashCode() {
            return Objects.hash(grupoId, usuarioId);
        }
    }
}
