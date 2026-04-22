package com.sri.agenda.entity;

import java.io.Serializable;
import java.util.Objects;
import java.util.UUID;

/**
 * Chave primária composta para {@link ItemParticipante}.
 * Exigida por JPA quando a entidade usa {@code @IdClass}.
 */
public class ItemParticipanteId implements Serializable {

    public UUID itemId;
    public UUID usuarioId;

    public ItemParticipanteId() {}

    public ItemParticipanteId(UUID itemId, UUID usuarioId) {
        this.itemId    = itemId;
        this.usuarioId = usuarioId;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof ItemParticipanteId other)) return false;
        return Objects.equals(itemId, other.itemId)
            && Objects.equals(usuarioId, other.usuarioId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(itemId, usuarioId);
    }
}
