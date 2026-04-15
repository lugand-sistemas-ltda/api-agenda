package com.sri.agenda.entity;

/**
 * Tipo do item de agenda.
 * Extensível via nova migration: ALTER TYPE agenda.item_tipo ADD VALUE '...';
 * Ao adicionar novo valor: incluir aqui + par de CSS vars no tema front-end (PA-006).
 */
public enum ItemTipo {
    feriado,
    ponto_facultativo,
    recesso,
    oitiva,
    operacao,
    reuniao,
    periodo,
    livre
}
