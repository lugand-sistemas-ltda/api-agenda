package com.sri.agenda.entity;

import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Grupo organizacional / equipe (ADR-006 GR-001).
 * Hierárquico: grupos podem conter sub-grupos via grupo_pai_id.
 */
@Entity
@Table(name = "grupo", schema = "agenda")
public class Grupo extends PanacheEntityBase {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    public UUID id;

    @Column(nullable = false)
    public String nome;

    public String descricao;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "grupo_pai_id")
    public Grupo grupoPai;

    @Column(nullable = false)
    public boolean ativo = true;

    @Column(name = "criado_em", nullable = false, updatable = false)
    public LocalDateTime criadoEm = LocalDateTime.now();

    @Column(name = "atualizado_em", nullable = false)
    public LocalDateTime atualizadoEm = LocalDateTime.now();

    @PreUpdate
    public void onUpdate() {
        atualizadoEm = LocalDateTime.now();
    }
}
