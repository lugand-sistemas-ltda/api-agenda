package com.sri.agenda.entity;

/**
 * Papel do usuário dentro de um grupo (ADR-006 GR-003).
 * O papel é contextual por grupo — o mesmo usuário pode ter papéis distintos
 * em grupos diferentes.
 */
public enum PapelGrupo {
    administrador,  // acesso total; cria/edita para qualquer membro
    gestor,         // acesso aos subordinados do seu sub-grupo
    operador,       // cria/edita próprios compromissos
    secretaria,     // cria para gestores e operadores do mesmo grupo
    estagiario      // cria apenas compromissos próprios
}
