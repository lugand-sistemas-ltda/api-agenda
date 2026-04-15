package com.sri.agenda.entity;

/**
 * Comportamento visual do item no calendário (ADR-005 IA-002).
 * É o único driver de renderização nos componentes Vue — não usar 'tipo' para isso.
 */
public enum ItemRenderizacao {
    evento,     // cartão posicionado no horário
    fundo_dia,  // colore o fundo do dia inteiro; outros itens ficam sobre ele
    periodo     // barra multi-dia (futuro: containment via item_pai_id)
}
