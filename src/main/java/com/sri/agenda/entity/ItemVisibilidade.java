package com.sri.agenda.entity;

/**
 * Nível de visibilidade de um item de agenda (ADR-007 VIS-002).
 * Determina quem pode ver o item — orthogonal a tipo e renderizacao.
 *
 * privado     → apenas o dono da agenda pessoal de origem
 * grupo       → membros do grupo do responsável pelo item
 * unidade     → todos os membros da unidade (ponto_facultativo, recesso, etc.)
 * global      → todos (feriados nacionais, calendário de sistema)
 * selecionado → grupos específicos listados em item_grupo_destino (ADR-007 VIS-003)
 * participante→ apenas os responsáveis registrados em item_participante (ADR-007 VIS-007)
 */
public enum ItemVisibilidade {
    privado,
    grupo,
    unidade,
    global,
    selecionado,
    participante
}
