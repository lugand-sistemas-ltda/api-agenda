package com.sri.agenda.entity;

import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@SuppressWarnings("unchecked")

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

    /**
     * Retorna todos os itens visíveis para um usuário em um intervalo de datas.
     * Implementa VIS-004 (ADR-007): 7 cláusulas de visibilidade via UNION ALL.
     *
     * @param usuarioId ID do usuário consultante
     * @param inicio    início do intervalo (inclusive)
     * @param fim       fim do intervalo (inclusive)
     */
    public static List<Compromisso> findVisiveis(UUID usuarioId,
                                                  LocalDateTime inicio,
                                                  LocalDateTime fim) {
        String sql =
            // 1. Globais (feriados, calendário de sistema)
            "SELECT i.* FROM agenda.item_agenda i " +
            "WHERE i.visibilidade = 'global' " +
            "  AND i.data_inicio <= ?3 AND i.data_fim >= ?2 " +

            "UNION ALL " +

            // 2. Privados na própria agenda pessoal
            "SELECT i.* FROM agenda.item_agenda i " +
            "JOIN agenda.agenda a ON a.id = i.agenda_id " +
            "WHERE i.visibilidade = 'privado' " +
            "  AND a.tipo = 'pessoal' AND a.proprietario_id = ?1 " +
            "  AND i.data_inicio <= ?3 AND i.data_fim >= ?2 " +

            "UNION ALL " +

            // 3. Nível unidade via agenda de unidade/grupo (agenda tem grupo_id preenchido)
            "SELECT i.* FROM agenda.item_agenda i " +
            "JOIN agenda.agenda a ON a.id = i.agenda_id " +
            "JOIN agenda.grupo g ON g.id = a.grupo_id " +
            "JOIN agenda.grupo_membro gm ON gm.grupo_id = g.id " +
            "WHERE i.visibilidade = 'unidade' " +
            "  AND gm.usuario_id = ?1 AND gm.ativo = true " +
            "  AND i.data_inicio <= ?3 AND i.data_fim >= ?2 " +

            "UNION ALL " +

            // 3b. Nível unidade via agenda pessoal: item criado na agenda pessoal de um colega
            //     de grupo com visibilidade 'unidade'. Cobre o caso onde grupo_id é NULL na
            //     agenda — visível para todos os membros ativos do mesmo grupo do proprietário.
            "SELECT i.* FROM agenda.item_agenda i " +
            "JOIN agenda.agenda a ON a.id = i.agenda_id " +
            "JOIN agenda.grupo_membro gm_owner ON gm_owner.usuario_id = a.proprietario_id AND gm_owner.ativo = true " +
            "JOIN agenda.grupo_membro gm_view  ON gm_view.grupo_id = gm_owner.grupo_id " +
            "  AND gm_view.usuario_id = ?1 AND gm_view.ativo = true " +
            "WHERE i.visibilidade = 'unidade' " +
            "  AND a.grupo_id IS NULL " +
            "  AND i.data_inicio <= ?3 AND i.data_fim >= ?2 " +

            "UNION ALL " +

            // 4a. Grupo via agenda de unidade/grupo (agenda tem grupo_id preenchido)
            "SELECT i.* FROM agenda.item_agenda i " +
            "JOIN agenda.agenda a ON a.id = i.agenda_id " +
            "JOIN agenda.grupo_membro gm ON gm.grupo_id = a.grupo_id " +
            "WHERE i.visibilidade = 'grupo' " +
            "  AND a.grupo_id IS NOT NULL " +
            "  AND gm.usuario_id = ?1 AND gm.ativo = true " +
            "  AND i.data_inicio <= ?3 AND i.data_fim >= ?2 " +

            "UNION ALL " +

            // 4b. Grupo via responsável: itens em agendas pessoais (sem grupo_id) onde
            //     o responsável pertence ao mesmo grupo que o usuário consultante.
            //     Permite que itens 'grupo' criados em agendas pessoais sejam visíveis
            //     a todos os colegas do mesmo grupo.
            "SELECT i.* FROM agenda.item_agenda i " +
            "JOIN agenda.agenda a ON a.id = i.agenda_id " +
            "JOIN agenda.grupo_membro gm_resp ON gm_resp.usuario_id = i.responsavel_id AND gm_resp.ativo = true " +
            "JOIN agenda.grupo_membro gm_view ON gm_view.grupo_id = gm_resp.grupo_id " +
            "  AND gm_view.usuario_id = ?1 AND gm_view.ativo = true " +
            "WHERE i.visibilidade = 'grupo' " +
            "  AND a.grupo_id IS NULL " +
            "  AND i.data_inicio <= ?3 AND i.data_fim >= ?2 " +

            "UNION ALL " +

            // 5. Selecionado: grupos explicitamente listados em item_grupo_destino
            "SELECT i.* FROM agenda.item_agenda i " +
            "JOIN agenda.item_grupo_destino igd ON igd.item_id = i.id " +
            "JOIN agenda.grupo_membro gm ON gm.grupo_id = igd.grupo_id " +
            "WHERE i.visibilidade = 'selecionado' " +
            "  AND gm.usuario_id = ?1 AND gm.ativo = true " +
            "  AND i.data_inicio <= ?3 AND i.data_fim >= ?2 " +

            "UNION ALL " +

            // 6. [PM-004 / ADR-009] Privado em agenda alheia onde o usuário é participante.
            //    Mantido para backward-compat com itens 'privado' delegados via item_participante.
            "SELECT i.* FROM agenda.item_agenda i " +
            "JOIN agenda.agenda a ON a.id = i.agenda_id " +
            "WHERE i.visibilidade = 'privado' " +
            "  AND (a.proprietario_id IS NULL OR a.proprietario_id != ?1) " +
            "  AND EXISTS ( " +
            "    SELECT 1 FROM agenda.item_participante ip " +
            "    WHERE ip.item_id = i.id " +
            "      AND ip.usuario_id = ?1 " +
            "      AND ip.visivel_na_agenda = true " +
            "      AND (ip.aceito IS NULL OR ip.aceito = true) " +
            "  ) " +
            "  AND i.data_inicio <= ?3 AND i.data_fim >= ?2 " +

            "UNION ALL " +

            // 7. [VIS-007] Participante: visível apenas aos responsáveis listados em item_participante.
            //    Funciona em qualquer tipo de agenda — não depende de agenda ou grupo.
            "SELECT i.* FROM agenda.item_agenda i " +
            "WHERE i.visibilidade = 'participante' " +
            "  AND EXISTS ( " +
            "    SELECT 1 FROM agenda.item_participante ip " +
            "    WHERE ip.item_id = i.id " +
            "      AND ip.usuario_id = ?1 " +
            "      AND ip.visivel_na_agenda = true " +
            "      AND (ip.aceito IS NULL OR ip.aceito = true) " +
            "  ) " +
            "  AND i.data_inicio <= ?3 AND i.data_fim >= ?2 " +

            "UNION ALL " +

            // 8. [ADR-009 PM-002] visualizar.agenda_subordinado — Administrador e Gestor veem
            //    itens 'privado' em agendas compartilhadas (grupo_id NOT NULL) do seu grupo.
            //    Respeita a permissão 'compromisso.visualizar.agenda_subordinado' na tabela
            //    papel_permissao — garante que apenas papéis com essa concessão explícita
            //    enxergam o conteúdo privado de subordinados.
            //    Referência: comentário original do ENUM item_visibilidade em V4:
            //    'privado = apenas o dono da agenda de origem (+ gestores/admin por hierarquia)'
            "SELECT i.* FROM agenda.item_agenda i " +
            "JOIN agenda.agenda a ON a.id = i.agenda_id " +
            "JOIN agenda.grupo_membro gm ON gm.grupo_id = a.grupo_id " +
            "  AND gm.usuario_id = ?1 AND gm.ativo = true " +
            "WHERE i.visibilidade = 'privado' " +
            "  AND a.grupo_id IS NOT NULL " +
            "  AND EXISTS ( " +
            "    SELECT 1 FROM agenda.papel_permissao pp " +
            "    JOIN agenda.permissao p ON p.id = pp.permissao_id " +
            "    WHERE pp.papel::text = gm.papel::text " +
            "      AND p.codigo = 'compromisso.visualizar.agenda_subordinado' " +
            "  ) " +
            "  AND i.data_inicio <= ?3 AND i.data_fim >= ?2";

        return (List<Compromisso>) getEntityManager()
            .createNativeQuery(sql, Compromisso.class)
            .setParameter(1, usuarioId)
            .setParameter(2, inicio)
            .setParameter(3, fim)
            .getResultList();
    }
}

