package com.sri.agenda.entity;

/**
 * Natureza da participação de um usuário num item de agenda (ADR-005 / ADR-006).
 * Usado em agenda.item_responsavel para qualificar a relação.
 */
public enum TipoParticipacao {
    responsavel_extra,  // responsável adicional além do principal
    convidado,          // presença esperada, não gera conflito
    testemunha,         // papel jurídico — vinculado a BO/procedimento
    investigado         // papel jurídico — vinculado a BO/procedimento
}
