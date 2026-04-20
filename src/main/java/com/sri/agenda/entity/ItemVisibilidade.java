package com.sri.agenda.entity;

/**
 * Nível de visibilidade de um item de agenda (ADR-007 VIS-002).
 * Determina quem pode ver o item — orthogonal a tipo e renderizacao.
 *
 * privado    → apenas o criador (agenda pessoal)
 * grupo      → membros do grupo ao qual a agenda pertence
 * unidade    → todos da unidade (ponto_facultativo, recesso, etc.)
 * global     → todos (feriados nacionais, calendário de sistema)
 * selecionado→ grupos específicos listados em item_grupo_destino (ADR-007 VIS-003)
 */
public enum ItemVisibilidade {
    privado,
    grupo,
    unidade,
    global,
    selecionado
}
