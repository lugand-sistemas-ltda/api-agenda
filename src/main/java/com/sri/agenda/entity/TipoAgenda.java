package com.sri.agenda.entity;

/**
 * Categoria estrutural da agenda (ADR-006 AG-001).
 */
public enum TipoAgenda {
    pessoal,   // pertence a um único usuário
    grupo,     // pertence a um grupo
    unidade,   // agenda raiz da unidade (visível a todos os membros)
    sistema    // gerenciada pelo sistema (feriados nacionais, etc.)
}
