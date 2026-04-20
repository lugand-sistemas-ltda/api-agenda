package com.sri.agenda.entity;

import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Item de agenda base (ADR-005).
 * Tabela renomeada compromisso → item_agenda na V3.
 * Classe mantém nome Compromisso para compatibilidade com o Resource existente;
 * será renomeada para ItemAgenda na Iteração 2 quando JPA inheritance for adotado (ADR-005 IA-008).
 */
@Entity
@Table(name = "item_agenda", schema = "agenda")
public class Compromisso extends PanacheEntityBase {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    public UUID id;

    @Column(nullable = false)
    public String titulo;

    public String descricao;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    public ItemTipo tipo;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    public ItemStatus status = ItemStatus.pendente;

    /**
     * Driver visual no calendário (ADR-005 IA-002, ADR-002 PA-011).
     * Use este campo — não 'tipo' — para decidir como renderizar no front-end.
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    public ItemRenderizacao renderizacao = ItemRenderizacao.evento;

    /**
     * Indica presença física obrigatória do responsável (ADR-005 IA-003).
     * Quando true, o item participa da verificação de conflito CONFLITO-B (RN-008).
     */
    @Column(name = "exige_presenca", nullable = false)
    public boolean exigePresenca = false;

    @Column(name = "data_inicio", nullable = false)
    public LocalDateTime dataInicio;

    @Column(name = "data_fim", nullable = false)
    public LocalDateTime dataFim;

    public String local;

    public String observacoes;

    /** Nullable: itens fundo_dia (feriados, etc.) não têm responsável. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "responsavel_id")
    public Usuario responsavel;

    /**
     * Agenda a que este item pertence (ADR-006 AG-001).
     * Determina em qual calendário o item aparece.
     */
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "agenda_id", nullable = false)
    public Agenda agenda;

    /**
     * Visibilidade do item (ADR-007 VIS-002).
     * Determina quem pode visualizar este item — orthogonal a tipo e renderizacao.
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    public ItemVisibilidade visibilidade = ItemVisibilidade.privado;

    /**
     * Usuário que criou o item (ADR-007 VIS-006).
     * Nullable na PoC; obrigatório após autenticação JWT (Iteração 3).
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "criado_por_id")
    public Usuario criadoPor;

    /**
     * Item pai: usado para containment de eventos dentro de períodos (ADR-005 IA-007).
     * Null para itens de nível raiz.
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "item_pai_id")
    public Compromisso itemPai;

    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(
        name = "item_responsavel",
        schema = "agenda",
        joinColumns = @JoinColumn(name = "item_id"),
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

    /**
     * Retorna itens que conflitam com o intervalo para um dado responsável.
     * Aplica-se apenas a itens com exigePresenca = true (CONFLITO-B, ADR-005 IA-006).
     */
    public static List<Compromisso> findConflitos(UUID responsavelId,
                                                   LocalDateTime inicio,
                                                   LocalDateTime fim,
                                                   UUID excluirId) {
        String q = "exigePresenca = true " +
                   "AND responsavel.id = ?1 " +
                   "AND dataInicio < ?3 " +
                   "AND dataFim > ?2";
        if (excluirId != null) {
            return find(q + " AND id != ?4", responsavelId, inicio, fim, excluirId).list();
        }
        return find(q, responsavelId, inicio, fim).list();
    }
}

