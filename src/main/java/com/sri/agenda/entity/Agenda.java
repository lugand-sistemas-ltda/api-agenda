package com.sri.agenda.entity;

import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Agenda: unidade de agrupamento de itens de agenda (ADR-006 AG-001).
 * Cada usuário e cada grupo possuem sua própria agenda.
 */
@Entity
@Table(name = "agenda", schema = "agenda")
public class Agenda extends PanacheEntityBase {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    public UUID id;

    @Column(nullable = false)
    public String nome;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    public TipoAgenda tipo;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "proprietario_id")
    public Usuario proprietario;  // preenchido se tipo = pessoal

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "grupo_id")
    public Grupo grupo;  // preenchido se tipo = grupo | unidade

    @Column(nullable = false)
    public boolean ativa = true;

    @Column(name = "criado_em", nullable = false, updatable = false)
    public LocalDateTime criadoEm = LocalDateTime.now();

    @Column(name = "atualizado_em", nullable = false)
    public LocalDateTime atualizadoEm = LocalDateTime.now();

    @PreUpdate
    public void onUpdate() {
        atualizadoEm = LocalDateTime.now();
    }
}
