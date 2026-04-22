package com.sri.agenda.security;

/**
 * Códigos de permissão atômicos do sistema (ADR-009 PM-001).
 *
 * Cada constante corresponde a uma linha em {@code agenda.permissao.codigo}.
 * O mapeamento papel → permissões reside em {@code agenda.papel_permissao}.
 *
 * Uso nos recursos REST:
 * <pre>
 *   // verificação de papel a partir da sessão ativa
 *   if (!permissaoService.papelTem(papel, PermissaoCodigo.COMPROMISSO_CRIAR_PARA_SUPERIOR)) {
 *       return Response.status(Response.Status.FORBIDDEN).build();
 *   }
 * </pre>
 *
 * Formato dos códigos: {recurso}.{acao}[.{escopo}]
 *
 * Fase 1 (atual): verificação via lookup em memória carregado na inicialização.
 * Fase 3: verificação consulta {@code agenda.papel_permissao} em runtime.
 */
public final class PermissaoCodigo {

    private PermissaoCodigo() {
        // utilitário — sem instância
    }

    // -------------------------------------------------------------------------
    // Compromisso — criação
    // -------------------------------------------------------------------------

    /** Criar compromisso na própria agenda pessoal. */
    public static final String COMPROMISSO_CRIAR_PROPRIO = "compromisso.criar.proprio";

    /** Criar compromisso com outro usuário como responsável (superior hierárquico). */
    public static final String COMPROMISSO_CRIAR_PARA_SUPERIOR = "compromisso.criar.para_superior";

    /** Criar compromisso para subordinado direto. */
    public static final String COMPROMISSO_CRIAR_PARA_SUBORDINADO = "compromisso.criar.para_subordinado";

    // -------------------------------------------------------------------------
    // Compromisso — visualização
    // -------------------------------------------------------------------------

    /** Ver itens da própria agenda pessoal. */
    public static final String COMPROMISSO_VISUALIZAR_PROPRIO = "compromisso.visualizar.proprio";

    /**
     * Ver itens em qualquer agenda onde o usuário é participante.
     * (criador, delegado, responsável — via {@code agenda.item_participante})
     */
    public static final String COMPROMISSO_VISUALIZAR_PARTICIPANTE = "compromisso.visualizar.participante";

    /** Ver toda a agenda pessoal de um subordinado direto. */
    public static final String COMPROMISSO_VISUALIZAR_AGENDA_SUBORDINADO = "compromisso.visualizar.agenda_subordinado";

    // -------------------------------------------------------------------------
    // Compromisso — edição / exclusão
    // -------------------------------------------------------------------------

    /** Editar itens criados por si na própria agenda. */
    public static final String COMPROMISSO_EDITAR_PROPRIO = "compromisso.editar.proprio";

    /** Editar itens onde o usuário possui papel {@code criador} ou {@code delegado} em item_participante. */
    public static final String COMPROMISSO_EDITAR_PARTICIPANTE = "compromisso.editar.participante";

    /** Excluir itens da própria agenda. */
    public static final String COMPROMISSO_EXCLUIR_PROPRIO = "compromisso.excluir.proprio";

    // -------------------------------------------------------------------------
    // Visibilidade
    // -------------------------------------------------------------------------

    /** Publicar itens com visibilidade {@code privado}. */
    public static final String VISIBILIDADE_DEFINIR_PRIVADO = "visibilidade.definir.privado";

    /** Publicar itens com visibilidade {@code grupo}. */
    public static final String VISIBILIDADE_DEFINIR_GRUPO = "visibilidade.definir.grupo";

    /** Publicar itens com visibilidade {@code unidade}. */
    public static final String VISIBILIDADE_DEFINIR_UNIDADE = "visibilidade.definir.unidade";

    /** Publicar itens com visibilidade {@code global} (feriados nacionais — apenas administrador). */
    public static final String VISIBILIDADE_DEFINIR_GLOBAL = "visibilidade.definir.global";

    /** Publicar itens com visibilidade {@code selecionado} + lista de grupos destino. */
    public static final String VISIBILIDADE_DEFINIR_SELECIONADO = "visibilidade.definir.selecionado";

    // -------------------------------------------------------------------------
    // Agenda — compartilhamento hierárquico (Fase 5)
    // -------------------------------------------------------------------------

    /** Compartilhar itens desta agenda com agendas de nível hierárquico inferior. */
    public static final String AGENDA_COMPARTILHAR_PARA_INFERIOR = "agenda.compartilhar.para_inferior";

    /** Aceitar ou rejeitar itens recebidos de agendas de nível superior. */
    public static final String AGENDA_COMPARTILHAR_ACEITAR = "agenda.compartilhar.aceitar";

    /** Redistribuir itens aceitos para agendas ainda mais inferiores. */
    public static final String AGENDA_COMPARTILHAR_REDISTRIBUIR = "agenda.compartilhar.redistribuir";

    // -------------------------------------------------------------------------
    // Usuário — administração
    // -------------------------------------------------------------------------

    /** Adicionar e remover membros de um grupo. */
    public static final String USUARIO_GERENCIAR_GRUPO = "usuario.gerenciar.grupo";
}
