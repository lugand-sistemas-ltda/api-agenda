package com.sri.agenda.entity;

import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "compromisso")
public class Compromisso extends PanacheEntityBase {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    public UUID id;

    @Column(nullable = false)
    public String titulo;

    public String descricao;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    public CompromissoTipo tipo;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    public CompromissoStatus status = CompromissoStatus.pendente;

    @Column(name = "data_inicio", nullable = false)
    public LocalDateTime dataInicio;

    @Column(name = "data_fim", nullable = false)
    public LocalDateTime dataFim;

    public String local;

    public String observacoes;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "responsavel_id", nullable = false)
    public Usuario responsavel;

    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(
        name = "compromisso_responsavel",
        joinColumns = @JoinColumn(name = "compromisso_id"),
        inverseJoinColumns = @JoinColumn(name = "usuario_id")
    )
    public List<Usuario> outrosResponsaveis = new ArrayList<>();

    @Column(name = "criado_em", nullable = false, updatable = false)
    public LocalDateTime criadoEm = LocalDateTime.now();

    @Column(name = "atualizado_em", nullable = false)
    public LocalDateTime atualizadoEm = LocalDateTime.now();

    @PreUpdate
    public void onUpdate() {
        atualizadoEm = LocalDateTime.now();
    }

    // -------------------------------------------------------------------------
    // Queries estáticas (Panache)
    // -------------------------------------------------------------------------

    public static List<Compromisso> findByAnoMes(int ano, int mes) {
        LocalDateTime inicio = java.time.YearMonth.of(ano, mes).atDay(1).atStartOfDay();
        LocalDateTime fim    = java.time.YearMonth.of(ano, mes).atEndOfMonth().atTime(23, 59, 59);
        return find("dataInicio >= ?1 AND dataInicio <= ?2", inicio, fim).list();
    }

    public static List<Compromisso> findByResponsavelNoIntervalo(UUID responsavelId,
                                                                  LocalDateTime inicio,
                                                                  LocalDateTime fim) {
        return find(
            "(responsavel.id = ?1 OR ?1 IN (SELECT r.id FROM outrosResponsaveis r)) " +
            "AND dataInicio < ?3 AND dataFim > ?2",
            responsavelId, inicio, fim
        ).list();
    }
}
