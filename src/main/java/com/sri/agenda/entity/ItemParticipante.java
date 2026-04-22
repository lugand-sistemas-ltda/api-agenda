package com.sri.agenda.entity;

import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.persistence.*;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

/**
 * Participação individual de um usuário em um item de agenda (ADR-009 PM-003).
 *
 * <p>Representa o papel que um usuário tem dentro de um item específico —
 * independente de qual agenda contém o item e independente do papel do usuário no grupo.
 *
 * <p>Caso de uso central: um estagiário cria um compromisso para o gestor.
 * O item fica na agenda pessoal do gestor ({@code visibilidade='privado'}),
 * mas o estagiário possui um registro aqui com {@code papelNoItem=delegado}.
 * A query VIS-004 estendida (cláusula PM-004) retorna o item para o estagiário
 * sem expor o restante da agenda privada do gestor.
 *
 * <p>Chave primária composta: {@code (item_id, usuario_id)}.
 */
@Entity
@Table(name = "item_participante", schema = "agenda")
@IdClass(ItemParticipanteId.class)
public class ItemParticipante extends PanacheEntityBase {

    @Id
    @Column(name = "item_id")
    public UUID itemId;

    @Id
    @Column(name = "usuario_id")
    public UUID usuarioId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "item_id", insertable = false, updatable = false)
    public Compromisso item;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "usuario_id", insertable = false, updatable = false)
    public Usuario usuario;

    @Enumerated(EnumType.STRING)
    @Column(name = "papel_no_item", nullable = false)
    public PapelNoItem papelNoItem;

    /**
     * Se {@code false}, o participante existe mas optou por ocultar o item
     * do próprio calendário (não remove a participação).
     */
    @Column(name = "visivel_na_agenda", nullable = false)
    public boolean visivelNaAgenda = true;

    /**
     * {@code null} = pendente (item criado para o usuário, aguardando confirmação);
     * {@code true} = aceito;
     * {@code false} = rejeitado.
     */
    @Column(name = "aceito")
    public Boolean aceito;

    @Column(name = "aceito_em")
    public OffsetDateTime aceitoEm;

    // -------------------------------------------------------------------------
    // Queries estáticas (Panache)
    // -------------------------------------------------------------------------

    /**
     * Retorna os participantes visíveis de um item.
     * Usado no modal de detalhes do compromisso para listar envolvidos.
     */
    public static List<ItemParticipante> findVisivelPorItem(UUID itemId) {
        return list("itemId = ?1 AND visivelNaAgenda = true", itemId);
    }

    /**
     * Verifica se um usuário é participante ativo de um item.
     * Usado pela cláusula PM-004 da query VIS-004 (visibilidade por participação).
     */
    public static boolean isParticipante(UUID itemId, UUID usuarioId) {
        return count(
            "itemId = ?1 AND usuarioId = ?2 AND visivelNaAgenda = true AND (aceito IS NULL OR aceito = true)",
            itemId, usuarioId
        ) > 0;
    }

    /**
     * Cria os registros de participação ao criar um compromisso.
     *
     * @param itemId       UUID do item recém-criado
     * @param criadorId    usuário que está criando
     * @param responsavelId usuário que será responsável (pode ser igual ao criador)
     */
    public static void registrarCriacao(UUID itemId, UUID criadorId, UUID responsavelId) {
        if (criadorId.equals(responsavelId)) {
            // Caso simples: usuário cria para si mesmo
            ItemParticipante p = new ItemParticipante();
            p.itemId        = itemId;
            p.usuarioId     = criadorId;
            p.papelNoItem   = PapelNoItem.criador;
            p.visivelNaAgenda = true;
            p.aceito        = true;
            p.persist();
        } else {
            // Caso delegado: criador (delegado) + responsável separados
            ItemParticipante delegado = new ItemParticipante();
            delegado.itemId        = itemId;
            delegado.usuarioId     = criadorId;
            delegado.papelNoItem   = PapelNoItem.delegado;
            delegado.visivelNaAgenda = true;
            delegado.aceito        = true;    // criador sempre aceita o que criou
            delegado.persist();

            ItemParticipante responsavel = new ItemParticipante();
            responsavel.itemId        = itemId;
            responsavel.usuarioId     = responsavelId;
            responsavel.papelNoItem   = PapelNoItem.responsavel;
            responsavel.visivelNaAgenda = true;
            responsavel.aceito        = null; // pendente — aguarda confirmação do responsável
            responsavel.persist();
        }
    }
}
