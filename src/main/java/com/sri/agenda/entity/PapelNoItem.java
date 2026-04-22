package com.sri.agenda.entity;

/**
 * Papel de um usuário dentro de um item específico de agenda (ADR-009 PM-003).
 * É contextual ao item — independente do {@link PapelGrupo} do usuário no grupo.
 */
public enum PapelNoItem {
    /** Quem registrou o compromisso no sistema. */
    criador,
    /** Quem conduzirá / executará o compromisso. */
    responsavel,
    /** Criou o item para outro (secretaria/estagiario criando para superior). */
    delegado,
    /** Convidado explicitamente para o item. */
    participante,
    /** Pode ver mas não editar; não foi diretamente convidado. */
    observador
}
