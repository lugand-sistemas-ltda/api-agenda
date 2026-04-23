-- =============================================================================
-- V9 — Seed de desenvolvimento: fixtures para testes manuais e onboarding
-- Data: 2026-04-23
-- Referências: ADR-005, ADR-006, ADR-007, ADR-009
-- =============================================================================
-- Propósito:
--   Gerar um conjunto rico de dados de teste cobrindo todos os casos de uso
--   da aplicação: visibilidades (global/unidade/grupo/privado/participante/
--   selecionado), itens simultâneos, criação delegada (estagiário→gestor),
--   itens de período com filhos, conflitos de horário, etc.
--
--   Período coberto: 2026-04-23 a 2026-08-31
--
-- Estrutura preservada (não é truncada):
--   usuario, grupo, grupo_membro, agenda, permissao, papel_permissao
--   (todos definidos em V1–V6 com UUIDs fixos)
--
-- Estrutura truncada e re-semeada:
--   item_agenda, item_participante, item_grupo_destino
-- =============================================================================
-- REFERÊNCIA RÁPIDA DE UUIDs
--
-- USUÁRIOS:
--   001 = Administrador       (SRI / administrador)
--   002 = André Myszko        (SRI / operador)
--   003 = Maria Silva         (SRI / secretaria)
--   004 = João Pereira        (SRI / gestor)
--   005 = Lucas Gomes         (SRI / estagiário)
--   006 = Patrícia Alves      (DECA / administrador)
--   007 = Roberto Costa       (DECA / gestor)
--   008 = Juliana Ferreira    (DECA / operador)
--   009 = Diego Martins       (DECA / secretaria)
--   013 = Camila Santos       (DEIC / administrador)
--   014 = Henrique Oliveira   (DEIC / gestor)
--   015 = Beatriz Correia     (DEIC / operador)
--   016 = Rafael Melo         (DEIC / estagiário)
--
-- GRUPOS:
--   010 = SRI
--   011 = DECA
--   012 = DEIC
--
-- AGENDAS:
--   020 = Unidade SRI         (unidade,  grupo_id=010)
--   021 = Pessoal Administrador
--   022 = Pessoal André Myszko
--   023 = Pessoal Maria Silva
--   024 = Unidade DECA        (unidade,  grupo_id=011)
--   025 = Unidade DEIC        (unidade,  grupo_id=012)
--   026 = Pessoal João Pereira
--   027 = Pessoal Lucas Gomes
--   031 = Pessoal Patrícia Alves
--   032 = Pessoal Roberto Costa
--   033 = Pessoal Juliana Ferreira
--   034 = Pessoal Diego Martins
--   035 = Pessoal Camila Santos
--   036 = Pessoal Henrique Oliveira
--   037 = Pessoal Beatriz Correia
--   038 = Pessoal Rafael Melo
--   030 = Calendário Nacional  (sistema)
-- =============================================================================


-- =============================================================================
-- 0. LIMPAR dados de conteúdo (mantém estrutura: usuários, grupos, agendas)
-- =============================================================================

TRUNCATE agenda.item_participante  CASCADE;
TRUNCATE agenda.item_grupo_destino CASCADE;
TRUNCATE agenda.item_agenda        CASCADE;


-- =============================================================================
-- 1. FERIADOS E PONTOS FACULTATIVOS NACIONAIS (visibilidade = 'global')
--    Residem na Agenda do Calendário Nacional (030) — tipo = 'sistema'
--    Período: maio–agosto 2026
-- =============================================================================

INSERT INTO agenda.item_agenda (id, titulo, descricao, tipo, renderizacao, visibilidade,
    data_inicio, data_fim, exige_presenca, agenda_id, criado_por_id) VALUES

    -- Maio
    ('00000000-0000-0000-0000-000000000101',
     'Dia do Trabalho', 'Feriado Nacional — 1° de Maio',
     'feriado', 'fundo_dia', 'global',
     '2026-05-01 00:00:00', '2026-05-01 23:59:59', false,
     '00000000-0000-0000-0000-000000000030', '00000000-0000-0000-0000-000000000001'),

    -- Junho
    ('00000000-0000-0000-0000-000000000102',
     'Corpus Christi', 'Feriado Nacional — Corpus Christi',
     'feriado', 'fundo_dia', 'global',
     '2026-06-04 00:00:00', '2026-06-04 23:59:59', false,
     '00000000-0000-0000-0000-000000000030', '00000000-0000-0000-0000-000000000001'),

    ('00000000-0000-0000-0000-000000000103',
     'Ponto Facultativo — véspera de Corpus Christi', 'Ponto facultativo — 03/06',
     'ponto_facultativo', 'fundo_dia', 'global',
     '2026-06-03 00:00:00', '2026-06-03 23:59:59', false,
     '00000000-0000-0000-0000-000000000030', '00000000-0000-0000-0000-000000000001'),

    -- Julho
    ('00000000-0000-0000-0000-000000000104',
     'Recesso de Julho', 'Recesso administrativo — semana de 13 a 17/07',
     'recesso', 'fundo_dia', 'global',
     '2026-07-13 00:00:00', '2026-07-17 23:59:59', false,
     '00000000-0000-0000-0000-000000000030', '00000000-0000-0000-0000-000000000001'),

    -- Agosto
    ('00000000-0000-0000-0000-000000000105',
     'Ponto Facultativo — 07/08', 'Ponto facultativo próximo ao Dia do Soldado',
     'ponto_facultativo', 'fundo_dia', 'global',
     '2026-08-07 00:00:00', '2026-08-07 23:59:59', false,
     '00000000-0000-0000-0000-000000000030', '00000000-0000-0000-0000-000000000001');


-- =============================================================================
-- 2. ITENS DA UNIDADE SRI (visibilidade = 'unidade', agenda 020)
--    Visíveis para todos os 5 membros da SRI (001–005)
-- =============================================================================

INSERT INTO agenda.item_agenda (id, titulo, descricao, tipo, renderizacao, visibilidade,
    data_inicio, data_fim, local, exige_presenca, agenda_id, criado_por_id, responsavel_id) VALUES

    -- Reuniões mensais de planejamento
    ('00000000-0000-0000-0000-000000000201',
     'Reunião de Planejamento — Maio', 'Revisão de metas e distribuição de tarefas da SRI para maio.',
     'reuniao', 'evento', 'unidade',
     '2026-05-05 09:00:00', '2026-05-05 11:00:00', 'Sala de Reuniões A', true,
     '00000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000004',
     '00000000-0000-0000-0000-000000000004'),

    ('00000000-0000-0000-0000-000000000202',
     'Reunião de Planejamento — Junho', 'Revisão de metas e distribuição de tarefas da SRI para junho.',
     'reuniao', 'evento', 'unidade',
     '2026-06-02 09:00:00', '2026-06-02 11:00:00', 'Sala de Reuniões A', true,
     '00000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000004',
     '00000000-0000-0000-0000-000000000004'),

    ('00000000-0000-0000-0000-000000000203',
     'Reunião de Planejamento — Julho', 'Revisão de metas e distribuição de tarefas da SRI para julho.',
     'reuniao', 'evento', 'unidade',
     '2026-07-07 09:00:00', '2026-07-07 11:00:00', 'Sala de Reuniões A', true,
     '00000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000004',
     '00000000-0000-0000-0000-000000000004'),

    ('00000000-0000-0000-0000-000000000204',
     'Reunião de Planejamento — Agosto', 'Revisão de metas e distribuição de tarefas da SRI para agosto.',
     'reuniao', 'evento', 'unidade',
     '2026-08-04 09:00:00', '2026-08-04 11:00:00', 'Sala de Reuniões A', true,
     '00000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000004',
     '00000000-0000-0000-0000-000000000004'),

    -- Operação de longa duração (período) — multi-dia, visível para toda unidade
    ('00000000-0000-0000-0000-000000000205',
     'Operação Verão 2026', 'Período de operações especializadas da SRI. Todos os agentes em alerta.',
     'periodo', 'periodo', 'unidade',
     '2026-07-20 00:00:00', '2026-07-31 23:59:59', null, false,
     '00000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000001',
     '00000000-0000-0000-0000-000000000001'),

    -- Treinamentos e capacitações
    ('00000000-0000-0000-0000-000000000206',
     'Capacitação: Atualização Normativa', 'Treinamento obrigatório para toda a SRI sobre novas normativas internas.',
     'reuniao', 'evento', 'unidade',
     '2026-05-19 14:00:00', '2026-05-19 17:00:00', 'Auditório Principal', true,
     '00000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000001',
     '00000000-0000-0000-0000-000000000001'),

    ('00000000-0000-0000-0000-000000000207',
     'Capacitação: Uso do Sistema de Agenda', 'Demonstração do novo sistema de agenda para todos os membros da SRI.',
     'reuniao', 'evento', 'unidade',
     '2026-05-26 10:00:00', '2026-05-26 12:00:00', 'Sala de Reuniões B', false,
     '00000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000002',
     '00000000-0000-0000-0000-000000000002'),

    -- Avaliações periódicas
    ('00000000-0000-0000-0000-000000000208',
     'Avaliação de Desempenho — 1° Semestre', 'Reunião de feedback e avaliação de desempenho da equipe SRI.',
     'reuniao', 'evento', 'unidade',
     '2026-06-25 14:00:00', '2026-06-25 17:00:00', 'Sala de Reuniões A', true,
     '00000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000004',
     '00000000-0000-0000-0000-000000000004'),

    -- Vários itens no mesmo dia — para testar visão diária congestionada
    ('00000000-0000-0000-0000-000000000209',
     'Stand-up diário — 28/04', 'Alinhamento rápido de 15 minutos da equipe SRI.',
     'reuniao', 'evento', 'unidade',
     '2026-04-28 08:30:00', '2026-04-28 08:45:00', 'Online', false,
     '00000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000004',
     '00000000-0000-0000-0000-000000000004'),

    ('00000000-0000-0000-0000-000000000210',
     'Briefing Operacional — 28/04', 'Briefing de segurança pré-operação.',
     'reuniao', 'evento', 'unidade',
     '2026-04-28 09:00:00', '2026-04-28 10:00:00', 'Sala Segura', true,
     '00000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000001',
     '00000000-0000-0000-0000-000000000001'),

    ('00000000-0000-0000-0000-000000000211',
     'Revisão de Procedimentos — 28/04', 'Revisão mensal de procedimentos operacionais padrão.',
     'reuniao', 'evento', 'unidade',
     '2026-04-28 10:30:00', '2026-04-28 12:00:00', 'Sala de Reuniões A', true,
     '00000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000001',
     '00000000-0000-0000-0000-000000000001'),

    ('00000000-0000-0000-0000-000000000212',
     'Almoço de Equipe — 28/04', 'Confraternização mensal da equipe SRI.',
     'livre', 'evento', 'unidade',
     '2026-04-28 12:00:00', '2026-04-28 13:30:00', 'Restaurante Sede', false,
     '00000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000003',
     null),

    ('00000000-0000-0000-0000-000000000213',
     'Reunião de Alinhamento — 28/04', 'Segunda reunião do dia da SRI.',
     'reuniao', 'evento', 'unidade',
     '2026-04-28 14:00:00', '2026-04-28 15:30:00', 'Sala de Reuniões B', true,
     '00000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000004',
     '00000000-0000-0000-0000-000000000004');


-- =============================================================================
-- 3. item_participante para itens da unidade SRI (todos os membros da SRI)
--    Criados por: João Pereira (004) e André Myszko (002)
-- =============================================================================

INSERT INTO agenda.item_participante (item_id, usuario_id, papel_no_item, visivel_na_agenda, aceito) VALUES
    -- item 201–204 (planejamentos mensais) — criador = João (004), acumula responsavel
    ('00000000-0000-0000-0000-000000000201', '00000000-0000-0000-0000-000000000004', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000202', '00000000-0000-0000-0000-000000000004', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000203', '00000000-0000-0000-0000-000000000004', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000204', '00000000-0000-0000-0000-000000000004', 'criador', true, true),

    -- item 205–206 — criador = Administrador (001)
    ('00000000-0000-0000-0000-000000000205', '00000000-0000-0000-0000-000000000001', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000206', '00000000-0000-0000-0000-000000000001', 'criador', true, true),

    -- item 207 — criador = André (002)
    ('00000000-0000-0000-0000-000000000207', '00000000-0000-0000-0000-000000000002', 'criador', true, true),

    -- item 208 — criador = João (004)
    ('00000000-0000-0000-0000-000000000208', '00000000-0000-0000-0000-000000000004', 'criador', true, true),

    -- items 28/04 — criadores variados
    ('00000000-0000-0000-0000-000000000209', '00000000-0000-0000-0000-000000000004', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000210', '00000000-0000-0000-0000-000000000001', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000211', '00000000-0000-0000-0000-000000000001', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000212', '00000000-0000-0000-0000-000000000003', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000213', '00000000-0000-0000-0000-000000000004', 'criador', true, true);


-- =============================================================================
-- 4. ITENS DE GRUPO SRI (visibilidade = 'grupo', agenda 020)
--    Visíveis apenas para membros do grupo SRI (010)
-- =============================================================================

INSERT INTO agenda.item_agenda (id, titulo, descricao, tipo, renderizacao, visibilidade,
    data_inicio, data_fim, local, exige_presenca, agenda_id, criado_por_id, responsavel_id) VALUES

    ('00000000-0000-0000-0000-000000000301',
     'Operação Noturna — Maio', 'Detalhes restritos. Briefing com gestores e operadores da SRI.',
     'operacao', 'evento', 'grupo',
     '2026-05-13 22:00:00', '2026-05-14 02:00:00', 'Ponto de Encontro Operacional', true,
     '00000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000001',
     '00000000-0000-0000-0000-000000000004'),

    ('00000000-0000-0000-0000-000000000302',
     'Operação Escudo — Junho', 'Operação de monitoramento preventivo.',
     'operacao', 'evento', 'grupo',
     '2026-06-10 08:00:00', '2026-06-10 18:00:00', 'Campo Externo', true,
     '00000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000001',
     '00000000-0000-0000-0000-000000000002'),

    ('00000000-0000-0000-0000-000000000303',
     'Operação Horizonte — Julho', 'Operação de longa duração em campo.',
     'operacao', 'evento', 'grupo',
     '2026-07-22 06:00:00', '2026-07-22 20:00:00', 'Campo Externo Norte', true,
     '00000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000001',
     '00000000-0000-0000-0000-000000000004'),

    ('00000000-0000-0000-0000-000000000304',
     'Debriefing Operação Escudo', 'Reunião de análise pós-operação.',
     'reuniao', 'evento', 'grupo',
     '2026-06-15 14:00:00', '2026-06-15 16:00:00', 'Sala Segura', true,
     '00000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000001',
     '00000000-0000-0000-0000-000000000001'),

    ('00000000-0000-0000-0000-000000000305',
     'Reunião de Inteligência — Semanal', 'Reunião restrita ao grupo SRI para troca de informações operacionais.',
     'reuniao', 'evento', 'grupo',
     '2026-05-06 15:00:00', '2026-05-06 16:30:00', 'Sala Segura', true,
     '00000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000004',
     '00000000-0000-0000-0000-000000000004'),

    ('00000000-0000-0000-0000-000000000306',
     'Reunião de Inteligência — Semanal', 'Reunião restrita ao grupo SRI.',
     'reuniao', 'evento', 'grupo',
     '2026-05-13 15:00:00', '2026-05-13 16:30:00', 'Sala Segura', true,
     '00000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000004',
     '00000000-0000-0000-0000-000000000004'),

    ('00000000-0000-0000-0000-000000000307',
     'Reunião de Inteligência — Semanal', 'Reunião restrita ao grupo SRI.',
     'reuniao', 'evento', 'grupo',
     '2026-05-20 15:00:00', '2026-05-20 16:30:00', 'Sala Segura', true,
     '00000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000004',
     '00000000-0000-0000-0000-000000000004'),

    ('00000000-0000-0000-0000-000000000308',
     'Reunião de Inteligência — Semanal', 'Reunião restrita ao grupo SRI.',
     'reuniao', 'evento', 'grupo',
     '2026-05-27 15:00:00', '2026-05-27 16:30:00', 'Sala Segura', true,
     '00000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000004',
     '00000000-0000-0000-0000-000000000004');

-- item_participante para itens de grupo SRI
-- 301-303: criador (001) ≠ responsavel → duas linhas; 304-308: criador = responsavel → uma linha
INSERT INTO agenda.item_participante (item_id, usuario_id, papel_no_item, visivel_na_agenda, aceito) VALUES
    ('00000000-0000-0000-0000-000000000301', '00000000-0000-0000-0000-000000000001', 'criador',    true, true),
    ('00000000-0000-0000-0000-000000000301', '00000000-0000-0000-0000-000000000004', 'responsavel', true, true),
    ('00000000-0000-0000-0000-000000000302', '00000000-0000-0000-0000-000000000001', 'criador',    true, true),
    ('00000000-0000-0000-0000-000000000302', '00000000-0000-0000-0000-000000000002', 'responsavel', true, true),
    ('00000000-0000-0000-0000-000000000303', '00000000-0000-0000-0000-000000000001', 'criador',    true, true),
    ('00000000-0000-0000-0000-000000000303', '00000000-0000-0000-0000-000000000004', 'responsavel', true, true),
    ('00000000-0000-0000-0000-000000000304', '00000000-0000-0000-0000-000000000001', 'criador',    true, true),
    ('00000000-0000-0000-0000-000000000305', '00000000-0000-0000-0000-000000000004', 'criador',    true, true),
    ('00000000-0000-0000-0000-000000000306', '00000000-0000-0000-0000-000000000004', 'criador',    true, true),
    ('00000000-0000-0000-0000-000000000307', '00000000-0000-0000-0000-000000000004', 'criador',    true, true),
    ('00000000-0000-0000-0000-000000000308', '00000000-0000-0000-0000-000000000004', 'criador',    true, true);


-- =============================================================================
-- 5. ITENS PRIVADOS — Agendas pessoais SRI
--    (visibilidade = 'privado') — cada usuário vê apenas os seus
-- =============================================================================

INSERT INTO agenda.item_agenda (id, titulo, descricao, tipo, renderizacao, visibilidade,
    data_inicio, data_fim, local, exige_presenca, agenda_id, criado_por_id, responsavel_id) VALUES

    -- André Myszko (002) — agenda 022
    ('00000000-0000-0000-0000-000000000401',
     'Consulta Médica', 'Consulta de rotina — não precisa de substituto.',
     'livre', 'evento', 'privado',
     '2026-05-08 14:00:00', '2026-05-08 15:00:00', 'Clínica Saúde Total', false,
     '00000000-0000-0000-0000-000000000022', '00000000-0000-0000-0000-000000000002',
     '00000000-0000-0000-0000-000000000002'),

    ('00000000-0000-0000-0000-000000000402',
     'Estudo de Caso Operacional', 'Análise individual de dossiê sigiloso.',
     'livre', 'evento', 'privado',
     '2026-05-12 08:00:00', '2026-05-12 10:00:00', 'Mesa Própria', false,
     '00000000-0000-0000-0000-000000000022', '00000000-0000-0000-0000-000000000002',
     '00000000-0000-0000-0000-000000000002'),

    ('00000000-0000-0000-0000-000000000403',
     'Revisão de Relatório Mensal', 'Preparação do relatório mensal individual.',
     'livre', 'evento', 'privado',
     '2026-05-28 09:00:00', '2026-05-28 11:00:00', 'Sala Individual', false,
     '00000000-0000-0000-0000-000000000022', '00000000-0000-0000-0000-000000000002',
     '00000000-0000-0000-0000-000000000002'),

    ('00000000-0000-0000-0000-000000000404',
     'Férias — André', 'Período de férias programadas.',
     'recesso', 'fundo_dia', 'privado',
     '2026-08-10 00:00:00', '2026-08-21 23:59:59', null, false,
     '00000000-0000-0000-0000-000000000022', '00000000-0000-0000-0000-000000000002',
     '00000000-0000-0000-0000-000000000002'),

    -- João Pereira (004) — agenda 026
    ('00000000-0000-0000-0000-000000000411',
     'Atendimento Individual — Lucas', 'Reunião 1:1 de acompanhamento do estagiário.',
     'reuniao', 'evento', 'privado',
     '2026-05-07 16:00:00', '2026-05-07 17:00:00', 'Sala do Gestor', true,
     '00000000-0000-0000-0000-000000000026', '00000000-0000-0000-0000-000000000004',
     '00000000-0000-0000-0000-000000000004'),

    ('00000000-0000-0000-0000-000000000412',
     'Atendimento Individual — Lucas', 'Reunião 1:1 semanal.',
     'reuniao', 'evento', 'privado',
     '2026-05-14 16:00:00', '2026-05-14 17:00:00', 'Sala do Gestor', true,
     '00000000-0000-0000-0000-000000000026', '00000000-0000-0000-0000-000000000004',
     '00000000-0000-0000-0000-000000000004'),

    ('00000000-0000-0000-0000-000000000413',
     'Atendimento Individual — Lucas', 'Reunião 1:1 semanal.',
     'reuniao', 'evento', 'privado',
     '2026-05-21 16:00:00', '2026-05-21 17:00:00', 'Sala do Gestor', true,
     '00000000-0000-0000-0000-000000000026', '00000000-0000-0000-0000-000000000004',
     '00000000-0000-0000-0000-000000000004'),

    ('00000000-0000-0000-0000-000000000414',
     'Análise de Inteligência Sigilosa', 'Análise de relatório de IC com classificação reservado.',
     'livre', 'evento', 'privado',
     '2026-06-08 10:00:00', '2026-06-08 12:00:00', 'Sala Segura', true,
     '00000000-0000-0000-0000-000000000026', '00000000-0000-0000-0000-000000000004',
     '00000000-0000-0000-0000-000000000004'),

    ('00000000-0000-0000-0000-000000000415',
     'Revisão do Plano Operacional 2° Semestre', 'Revisão do plano operacional antes da apresentação à diretoria.',
     'livre', 'evento', 'privado',
     '2026-06-30 14:00:00', '2026-06-30 16:00:00', 'Sala do Gestor', false,
     '00000000-0000-0000-0000-000000000026', '00000000-0000-0000-0000-000000000004',
     '00000000-0000-0000-0000-000000000004'),

    -- Maria Silva (003) — agenda 023
    ('00000000-0000-0000-0000-000000000421',
     'Organização de Protocolo', 'Protocolo de correspondências recebidas.',
     'livre', 'evento', 'privado',
     '2026-05-04 08:00:00', '2026-05-04 09:00:00', 'Mesa de Trabalho', false,
     '00000000-0000-0000-0000-000000000023', '00000000-0000-0000-0000-000000000003',
     '00000000-0000-0000-0000-000000000003'),

    ('00000000-0000-0000-0000-000000000422',
     'Organização de Protocolo', 'Protocolo semanal.',
     'livre', 'evento', 'privado',
     '2026-05-11 08:00:00', '2026-05-11 09:00:00', 'Mesa de Trabalho', false,
     '00000000-0000-0000-0000-000000000023', '00000000-0000-0000-0000-000000000003',
     '00000000-0000-0000-0000-000000000003'),

    -- Lucas Gomes (005) — agenda 027
    ('00000000-0000-0000-0000-000000000431',
     'Entrega de Relatório de Estágio', 'Relatório quinzenal de atividades do estágio.',
     'livre', 'evento', 'privado',
     '2026-05-15 17:00:00', '2026-05-15 17:30:00', 'E-mail / Portal RH', false,
     '00000000-0000-0000-0000-000000000027', '00000000-0000-0000-0000-000000000005',
     '00000000-0000-0000-0000-000000000005'),

    ('00000000-0000-0000-0000-000000000432',
     'Entrega de Relatório de Estágio', 'Relatório quinzenal.',
     'livre', 'evento', 'privado',
     '2026-05-29 17:00:00', '2026-05-29 17:30:00', 'E-mail / Portal RH', false,
     '00000000-0000-0000-0000-000000000027', '00000000-0000-0000-0000-000000000005',
     '00000000-0000-0000-0000-000000000005'),

    ('00000000-0000-0000-0000-000000000433',
     'Leitura de Procedimentos SRI', 'Estudo autônomo de manuais e procedimentos.',
     'livre', 'evento', 'privado',
     '2026-05-06 09:00:00', '2026-05-06 11:00:00', 'Sala de Estagiários', false,
     '00000000-0000-0000-0000-000000000027', '00000000-0000-0000-0000-000000000005',
     '00000000-0000-0000-0000-000000000005'),

    -- Administrador (001) — agenda pessoal 021
    ('00000000-0000-0000-0000-000000000441',
     'Despacho Reservado com Assessoria', 'Reunião reservada com assessoria jurídica sobre processo administrativo em curso.',
     'reuniao', 'evento', 'privado',
     '2026-05-06 10:00:00', '2026-05-06 11:00:00', 'Sala da Direção', true,
     '00000000-0000-0000-0000-000000000021', '00000000-0000-0000-0000-000000000001',
     '00000000-0000-0000-0000-000000000001'),

    ('00000000-0000-0000-0000-000000000442',
     'Revisão de Dossiê — IC Mensal', 'Leitura e análise individual do dossiê de inteligência classificado.',
     'livre', 'evento', 'privado',
     '2026-05-20 09:00:00', '2026-05-20 11:00:00', 'Sala Segura', true,
     '00000000-0000-0000-0000-000000000021', '00000000-0000-0000-0000-000000000001',
     '00000000-0000-0000-0000-000000000001'),

    ('00000000-0000-0000-0000-000000000443',
     'Preparação de Briefing para Diretoria', 'Organização dos pontos de pauta para apresentação mensal à diretoria.',
     'livre', 'evento', 'privado',
     '2026-06-03 14:00:00', '2026-06-03 16:00:00', 'Mesa de Trabalho', false,
     '00000000-0000-0000-0000-000000000021', '00000000-0000-0000-0000-000000000001',
     '00000000-0000-0000-0000-000000000001'),

    ('00000000-0000-0000-0000-000000000444',
     'Consulta ao Serviço Médico', 'Consulta de saúde ocupacional — rotina anual.',
     'livre', 'evento', 'privado',
     '2026-06-18 11:00:00', '2026-06-18 12:00:00', 'Clínica Ocupacional', false,
     '00000000-0000-0000-0000-000000000021', '00000000-0000-0000-0000-000000000001',
     '00000000-0000-0000-0000-000000000001'),

    ('00000000-0000-0000-0000-000000000445',
     'Férias — Administrador', 'Período de férias programadas do Administrador da SRI.',
     'recesso', 'fundo_dia', 'privado',
     '2026-07-14 00:00:00', '2026-07-25 23:59:59', null, false,
     '00000000-0000-0000-0000-000000000021', '00000000-0000-0000-0000-000000000001',
     '00000000-0000-0000-0000-000000000001');

-- item_participante para itens privados (criador = responsável = o próprio usuário)
INSERT INTO agenda.item_participante (item_id, usuario_id, papel_no_item, visivel_na_agenda, aceito) VALUES
    ('00000000-0000-0000-0000-000000000401', '00000000-0000-0000-0000-000000000002', 'criador',    true, true),
    ('00000000-0000-0000-0000-000000000402', '00000000-0000-0000-0000-000000000002', 'criador',    true, true),
    ('00000000-0000-0000-0000-000000000403', '00000000-0000-0000-0000-000000000002', 'criador',    true, true),
    ('00000000-0000-0000-0000-000000000404', '00000000-0000-0000-0000-000000000002', 'criador',    true, true),
    ('00000000-0000-0000-0000-000000000411', '00000000-0000-0000-0000-000000000004', 'criador',    true, true),
    ('00000000-0000-0000-0000-000000000412', '00000000-0000-0000-0000-000000000004', 'criador',    true, true),
    ('00000000-0000-0000-0000-000000000413', '00000000-0000-0000-0000-000000000004', 'criador',    true, true),
    ('00000000-0000-0000-0000-000000000414', '00000000-0000-0000-0000-000000000004', 'criador',    true, true),
    ('00000000-0000-0000-0000-000000000415', '00000000-0000-0000-0000-000000000004', 'criador',    true, true),
    ('00000000-0000-0000-0000-000000000421', '00000000-0000-0000-0000-000000000003', 'criador',    true, true),
    ('00000000-0000-0000-0000-000000000422', '00000000-0000-0000-0000-000000000003', 'criador',    true, true),
    ('00000000-0000-0000-0000-000000000431', '00000000-0000-0000-0000-000000000005', 'criador',    true, true),
    ('00000000-0000-0000-0000-000000000432', '00000000-0000-0000-0000-000000000005', 'criador',    true, true),
    ('00000000-0000-0000-0000-000000000433', '00000000-0000-0000-0000-000000000005', 'criador',    true, true),
    ('00000000-0000-0000-0000-000000000441', '00000000-0000-0000-0000-000000000001', 'criador',    true, true),
    ('00000000-0000-0000-0000-000000000442', '00000000-0000-0000-0000-000000000001', 'criador',    true, true),
    ('00000000-0000-0000-0000-000000000443', '00000000-0000-0000-0000-000000000001', 'criador',    true, true),
    ('00000000-0000-0000-0000-000000000444', '00000000-0000-0000-0000-000000000001', 'criador',    true, true),
    ('00000000-0000-0000-0000-000000000445', '00000000-0000-0000-0000-000000000001', 'criador',    true, true);


-- =============================================================================
-- 6. CENÁRIO DELEGADO — Estagiário cria item na agenda do Gestor (PM-004)
--    Lucas Gomes (005 / estagiário) cria oitiva para João Pereira (004 / gestor).
--    Item fica na agenda PESSOAL de João (026) como 'privado'.
--    Lucas vê o item via cláusula 6 do VIS-004 (participante em agenda alheia).
--    João vê porque é proprietário da agenda (cláusula 2).
-- =============================================================================

INSERT INTO agenda.item_agenda (id, titulo, descricao, tipo, renderizacao, visibilidade,
    data_inicio, data_fim, local, exige_presenca, agenda_id, criado_por_id, responsavel_id) VALUES

    ('00000000-0000-0000-0000-000000000501',
     'Oitiva — Testemunha Caso 2026-051', 'Oitiva de testemunha referente ao caso ambiental. Agendada pelo estagiário Lucas.',
     'oitiva', 'evento', 'privado',
     '2026-05-09 10:00:00', '2026-05-09 12:00:00', 'Sala de Oitivas 1', true,
     '00000000-0000-0000-0000-000000000026', '00000000-0000-0000-0000-000000000005',
     '00000000-0000-0000-0000-000000000004'),

    ('00000000-0000-0000-0000-000000000502',
     'Oitiva — Investigado Caso 2026-051', 'Segunda oitiva do mesmo caso. Delegada por Lucas ao gestor João.',
     'oitiva', 'evento', 'privado',
     '2026-05-16 14:00:00', '2026-05-16 16:00:00', 'Sala de Oitivas 2', true,
     '00000000-0000-0000-0000-000000000026', '00000000-0000-0000-0000-000000000005',
     '00000000-0000-0000-0000-000000000004'),

    ('00000000-0000-0000-0000-000000000503',
     'Oitiva — Perito Caso 2026-072', 'Depoimento de perito técnico.',
     'oitiva', 'evento', 'privado',
     '2026-06-11 09:00:00', '2026-06-11 11:00:00', 'Sala de Oitivas 1', true,
     '00000000-0000-0000-0000-000000000026', '00000000-0000-0000-0000-000000000005',
     '00000000-0000-0000-0000-000000000004');

-- item_participante: Lucas como 'delegado', João como 'responsavel'
INSERT INTO agenda.item_participante (item_id, usuario_id, papel_no_item, visivel_na_agenda, aceito) VALUES
    ('00000000-0000-0000-0000-000000000501', '00000000-0000-0000-0000-000000000005', 'delegado',   true, true),
    ('00000000-0000-0000-0000-000000000501', '00000000-0000-0000-0000-000000000004', 'responsavel', true, true),
    ('00000000-0000-0000-0000-000000000502', '00000000-0000-0000-0000-000000000005', 'delegado',   true, true),
    ('00000000-0000-0000-0000-000000000502', '00000000-0000-0000-0000-000000000004', 'responsavel', true, true),
    ('00000000-0000-0000-0000-000000000503', '00000000-0000-0000-0000-000000000005', 'delegado',   true, true),
    ('00000000-0000-0000-0000-000000000503', '00000000-0000-0000-0000-000000000004', 'responsavel', true, true);


-- =============================================================================
-- 7. CENÁRIO DELEGADO — Secretaria cria itens para gestor (PM-004)
--    Maria Silva (003 / secretaria) cria reuniões para João Pereira (004 / gestor).
--    Item fica na agenda pessoal de João (026) como 'privado'.
-- =============================================================================

INSERT INTO agenda.item_agenda (id, titulo, descricao, tipo, renderizacao, visibilidade,
    data_inicio, data_fim, local, exige_presenca, agenda_id, criado_por_id, responsavel_id) VALUES

    ('00000000-0000-0000-0000-000000000511',
     'Reunião com Diretoria — Maio', 'Reunião mensal de prestação de contas agendada pela secretaria.',
     'reuniao', 'evento', 'privado',
     '2026-05-28 10:00:00', '2026-05-28 12:00:00', 'Sala da Diretoria', true,
     '00000000-0000-0000-0000-000000000026', '00000000-0000-0000-0000-000000000003',
     '00000000-0000-0000-0000-000000000004'),

    ('00000000-0000-0000-0000-000000000512',
     'Reunião com Diretoria — Junho', 'Reunião mensal de prestação de contas.',
     'reuniao', 'evento', 'privado',
     '2026-06-25 10:00:00', '2026-06-25 12:00:00', 'Sala da Diretoria', true,
     '00000000-0000-0000-0000-000000000026', '00000000-0000-0000-0000-000000000003',
     '00000000-0000-0000-0000-000000000004'),

    ('00000000-0000-0000-0000-000000000513',
     'Compromisso Externo — Audiência', 'Audiência judicial representando a unidade.',
     'oitiva', 'evento', 'privado',
     '2026-07-03 14:00:00', '2026-07-03 17:00:00', 'Fórum Central', true,
     '00000000-0000-0000-0000-000000000026', '00000000-0000-0000-0000-000000000003',
     '00000000-0000-0000-0000-000000000004');

INSERT INTO agenda.item_participante (item_id, usuario_id, papel_no_item, visivel_na_agenda, aceito) VALUES
    ('00000000-0000-0000-0000-000000000511', '00000000-0000-0000-0000-000000000003', 'delegado',   true, true),
    ('00000000-0000-0000-0000-000000000511', '00000000-0000-0000-0000-000000000004', 'responsavel', true, true),
    ('00000000-0000-0000-0000-000000000512', '00000000-0000-0000-0000-000000000003', 'delegado',   true, true),
    ('00000000-0000-0000-0000-000000000512', '00000000-0000-0000-0000-000000000004', 'responsavel', true, true),
    ('00000000-0000-0000-0000-000000000513', '00000000-0000-0000-0000-000000000003', 'delegado',   true, true),
    ('00000000-0000-0000-0000-000000000513', '00000000-0000-0000-0000-000000000004', 'responsavel', true, true);


-- =============================================================================
-- 8. CENÁRIO PARTICIPANTE — visibilidade = 'participante' (VIS-007)
--    Oitiva interinstitucional: envolve membros de SRI, DECA e DEIC.
--    Apenas os participantes listados veem o item.
-- =============================================================================

INSERT INTO agenda.item_agenda (id, titulo, descricao, tipo, renderizacao, visibilidade,
    data_inicio, data_fim, local, exige_presenca, agenda_id, criado_por_id, responsavel_id) VALUES

    ('00000000-0000-0000-0000-000000000601',
     'Oitiva Interinstitucional — Caso Verde', 'Oitiva sigilosa com participação de SRI, DECA e DEIC. Apenas convidados.',
     'oitiva', 'evento', 'participante',
     '2026-05-22 09:00:00', '2026-05-22 12:00:00', 'Sala Segura Interinstitucional', true,
     '00000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000001',
     '00000000-0000-0000-0000-000000000001'),

    ('00000000-0000-0000-0000-000000000602',
     'Reunião de Coordenação Operacional', 'Alinhamento entre lideranças das três unidades. Restrito a participantes.',
     'reuniao', 'evento', 'participante',
     '2026-06-17 14:00:00', '2026-06-17 16:00:00', 'Sala de Comando', true,
     '00000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000001',
     '00000000-0000-0000-0000-000000000001'),

    ('00000000-0000-0000-0000-000000000603',
     'Apresentação de Resultados — Operação Verão', 'Briefing final com representantes das três unidades.',
     'reuniao', 'evento', 'participante',
     '2026-08-05 10:00:00', '2026-08-05 12:00:00', 'Sala de Conferências', true,
     '00000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000001',
     '00000000-0000-0000-0000-000000000001');

-- Participantes: subconjunto de cada unidade
INSERT INTO agenda.item_participante (item_id, usuario_id, papel_no_item, visivel_na_agenda, aceito) VALUES
    -- item 601: criador (001) acumula responsavel; participantes de outras unidades
    ('00000000-0000-0000-0000-000000000601', '00000000-0000-0000-0000-000000000001', 'criador',     true, true),
    ('00000000-0000-0000-0000-000000000601', '00000000-0000-0000-0000-000000000004', 'participante', true, true),
    ('00000000-0000-0000-0000-000000000601', '00000000-0000-0000-0000-000000000006', 'participante', true, true),
    ('00000000-0000-0000-0000-000000000601', '00000000-0000-0000-0000-000000000007', 'participante', true, true),
    ('00000000-0000-0000-0000-000000000601', '00000000-0000-0000-0000-000000000013', 'participante', true, true),

    -- item 602: criador (001) acumula responsavel
    ('00000000-0000-0000-0000-000000000602', '00000000-0000-0000-0000-000000000001', 'criador',     true, true),
    ('00000000-0000-0000-0000-000000000602', '00000000-0000-0000-0000-000000000004', 'participante', true, true),
    ('00000000-0000-0000-0000-000000000602', '00000000-0000-0000-0000-000000000006', 'participante', true, true),
    ('00000000-0000-0000-0000-000000000602', '00000000-0000-0000-0000-000000000007', 'participante', true, true),
    ('00000000-0000-0000-0000-000000000602', '00000000-0000-0000-0000-000000000013', 'participante', true, true),
    ('00000000-0000-0000-0000-000000000602', '00000000-0000-0000-0000-000000000014', 'participante', true, true),

    -- item 603: criador (001) acumula responsavel; André como observador
    ('00000000-0000-0000-0000-000000000603', '00000000-0000-0000-0000-000000000001', 'criador',     true, true),
    ('00000000-0000-0000-0000-000000000603', '00000000-0000-0000-0000-000000000004', 'participante', true, true),
    ('00000000-0000-0000-0000-000000000603', '00000000-0000-0000-0000-000000000006', 'participante', true, true),
    ('00000000-0000-0000-0000-000000000603', '00000000-0000-0000-0000-000000000013', 'participante', true, true),
    ('00000000-0000-0000-0000-000000000603', '00000000-0000-0000-0000-000000000002', 'observador',   true, true);


-- =============================================================================
-- 9. ITENS SELECIONADOS — visibilidade = 'selecionado' (VIS-003)
--    Compartilhado entre unidades específicas via item_grupo_destino
-- =============================================================================

INSERT INTO agenda.item_agenda (id, titulo, descricao, tipo, renderizacao, visibilidade,
    data_inicio, data_fim, local, exige_presenca, agenda_id, criado_por_id, responsavel_id) VALUES

    ('00000000-0000-0000-0000-000000000701',
     'Alerta Operacional — Região Norte', 'Alerta compartilhado com DECA e DEIC sobre movimentação suspeita.',
     'livre', 'evento', 'selecionado',
     '2026-05-15 08:00:00', '2026-05-15 18:00:00', null, false,
     '00000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000001',
     '00000000-0000-0000-0000-000000000001'),

    ('00000000-0000-0000-0000-000000000702',
     'Protocolo Conjunto SRI–DECA', 'Procedimento operacional compartilhado com a DECA.',
     'livre', 'periodo', 'selecionado',
     '2026-06-01 00:00:00', '2026-06-30 23:59:59', null, false,
     '00000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000001',
     '00000000-0000-0000-0000-000000000001'),

    ('00000000-0000-0000-0000-000000000703',
     'Operação Conjunta SRI–DEIC — Agosto', 'Operação de campo com participação das duas unidades.',
     'operacao', 'evento', 'selecionado',
     '2026-08-18 06:00:00', '2026-08-18 22:00:00', 'Campo Externo', true,
     '00000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000001',
     '00000000-0000-0000-0000-000000000001');

-- item_grupo_destino (quais grupos recebem cada item selecionado)
INSERT INTO agenda.item_grupo_destino (item_id, grupo_id) VALUES
    ('00000000-0000-0000-0000-000000000701', '00000000-0000-0000-0000-000000000011'), -- DECA
    ('00000000-0000-0000-0000-000000000701', '00000000-0000-0000-0000-000000000012'), -- DEIC
    ('00000000-0000-0000-0000-000000000702', '00000000-0000-0000-0000-000000000011'), -- DECA
    ('00000000-0000-0000-0000-000000000703', '00000000-0000-0000-0000-000000000012'); -- DEIC

-- item_participante para itens selecionados (criador = responsavel → uma linha)
INSERT INTO agenda.item_participante (item_id, usuario_id, papel_no_item, visivel_na_agenda, aceito) VALUES
    ('00000000-0000-0000-0000-000000000701', '00000000-0000-0000-0000-000000000001', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000702', '00000000-0000-0000-0000-000000000001', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000703', '00000000-0000-0000-0000-000000000001', 'criador', true, true);


-- =============================================================================
-- 10. ITENS DA UNIDADE DECA (visibilidade = 'unidade', agenda 024)
--     Visíveis para Patrícia (006), Roberto (007), Juliana (008), Diego (009)
-- =============================================================================

INSERT INTO agenda.item_agenda (id, titulo, descricao, tipo, renderizacao, visibilidade,
    data_inicio, data_fim, local, exige_presenca, agenda_id, criado_por_id, responsavel_id) VALUES

    ('00000000-0000-0000-0000-000000000801',
     'Reunião da Unidade DECA — Maio', 'Reunião mensal de planejamento da DECA.',
     'reuniao', 'evento', 'unidade',
     '2026-05-04 09:00:00', '2026-05-04 11:00:00', 'Sala DECA', true,
     '00000000-0000-0000-0000-000000000024', '00000000-0000-0000-0000-000000000006',
     '00000000-0000-0000-0000-000000000006'),

    ('00000000-0000-0000-0000-000000000802',
     'Reunião da Unidade DECA — Junho', 'Reunião mensal de planejamento da DECA.',
     'reuniao', 'evento', 'unidade',
     '2026-06-01 09:00:00', '2026-06-01 11:00:00', 'Sala DECA', true,
     '00000000-0000-0000-0000-000000000024', '00000000-0000-0000-0000-000000000006',
     '00000000-0000-0000-0000-000000000006'),

    ('00000000-0000-0000-0000-000000000803',
     'Reunião da Unidade DECA — Julho', 'Reunião mensal de planejamento da DECA.',
     'reuniao', 'evento', 'unidade',
     '2026-07-06 09:00:00', '2026-07-06 11:00:00', 'Sala DECA', true,
     '00000000-0000-0000-0000-000000000024', '00000000-0000-0000-0000-000000000006',
     '00000000-0000-0000-0000-000000000006'),

    ('00000000-0000-0000-0000-000000000804',
     'Reunião da Unidade DECA — Agosto', 'Reunião mensal de planejamento da DECA.',
     'reuniao', 'evento', 'unidade',
     '2026-08-03 09:00:00', '2026-08-03 11:00:00', 'Sala DECA', true,
     '00000000-0000-0000-0000-000000000024', '00000000-0000-0000-0000-000000000006',
     '00000000-0000-0000-0000-000000000006'),

    ('00000000-0000-0000-0000-000000000805',
     'Vistoria Ambiental — Zona Norte', 'Operação de campo DECA para vistoria ambiental.',
     'operacao', 'evento', 'unidade',
     '2026-05-20 07:00:00', '2026-05-20 17:00:00', 'Zona Norte', true,
     '00000000-0000-0000-0000-000000000024', '00000000-0000-0000-0000-000000000007',
     '00000000-0000-0000-0000-000000000007'),

    ('00000000-0000-0000-0000-000000000806',
     'Vistoria Ambiental — Zona Sul', 'Operação de campo DECA para vistoria ambiental.',
     'operacao', 'evento', 'unidade',
     '2026-06-24 07:00:00', '2026-06-24 17:00:00', 'Zona Sul', true,
     '00000000-0000-0000-0000-000000000024', '00000000-0000-0000-0000-000000000007',
     '00000000-0000-0000-0000-000000000007'),

    ('00000000-0000-0000-0000-000000000807',
     'Capacitação: Legislação Ambiental 2026', 'Atualização obrigatória sobre novas normas ambientais.',
     'reuniao', 'evento', 'unidade',
     '2026-07-14 14:00:00', '2026-07-14 17:00:00', 'Sala DECA', false,
     '00000000-0000-0000-0000-000000000024', '00000000-0000-0000-0000-000000000006',
     '00000000-0000-0000-0000-000000000006'),

    -- Dia lotado na DECA — múltiplos itens no mesmo dia
    ('00000000-0000-0000-0000-000000000808',
     'Protocolo de Laudos — Manhã', 'Protocolo de laudos periciais recebidos.',
     'livre', 'evento', 'unidade',
     '2026-05-27 08:00:00', '2026-05-27 09:30:00', 'Mesa DECA', false,
     '00000000-0000-0000-0000-000000000024', '00000000-0000-0000-0000-000000000009',
     null),

    ('00000000-0000-0000-0000-000000000809',
     'Reunião de Acompanhamento de Casos', 'Status de casos em andamento na DECA.',
     'reuniao', 'evento', 'unidade',
     '2026-05-27 10:00:00', '2026-05-27 11:30:00', 'Sala DECA', true,
     '00000000-0000-0000-0000-000000000024', '00000000-0000-0000-0000-000000000006',
     '00000000-0000-0000-0000-000000000007'),

    ('00000000-0000-0000-0000-000000000810',
     'Oitiva — Infrator Ambiental', 'Oitiva de infrator em caso de desmatamento.',
     'oitiva', 'evento', 'unidade',
     '2026-05-27 14:00:00', '2026-05-27 15:30:00', 'Sala de Oitivas DECA', true,
     '00000000-0000-0000-0000-000000000024', '00000000-0000-0000-0000-000000000007',
     '00000000-0000-0000-0000-000000000007'),

    ('00000000-0000-0000-0000-000000000811',
     'Despacho com Ministério Público', 'Alinhamento com promotoria sobre caso de grande repercussão.',
     'reuniao', 'evento', 'unidade',
     '2026-05-27 16:00:00', '2026-05-27 17:30:00', 'Sala de Videoconferência', true,
     '00000000-0000-0000-0000-000000000024', '00000000-0000-0000-0000-000000000006',
     '00000000-0000-0000-0000-000000000006');

-- item_participante para itens de unidade DECA
-- 809: criador (006) ≠ responsavel (007) → duas linhas; demais: criador = responsavel → uma linha
INSERT INTO agenda.item_participante (item_id, usuario_id, papel_no_item, visivel_na_agenda, aceito) VALUES
    ('00000000-0000-0000-0000-000000000801', '00000000-0000-0000-0000-000000000006', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000802', '00000000-0000-0000-0000-000000000006', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000803', '00000000-0000-0000-0000-000000000006', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000804', '00000000-0000-0000-0000-000000000006', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000805', '00000000-0000-0000-0000-000000000007', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000806', '00000000-0000-0000-0000-000000000007', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000807', '00000000-0000-0000-0000-000000000006', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000808', '00000000-0000-0000-0000-000000000009', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000809', '00000000-0000-0000-0000-000000000006', 'criador',    true, true),
    ('00000000-0000-0000-0000-000000000809', '00000000-0000-0000-0000-000000000007', 'responsavel', true, true),
    ('00000000-0000-0000-0000-000000000810', '00000000-0000-0000-0000-000000000007', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000811', '00000000-0000-0000-0000-000000000006', 'criador', true, true);


-- =============================================================================
-- 11. ITENS PRIVADOS — Agendas pessoais DECA
-- =============================================================================

INSERT INTO agenda.item_agenda (id, titulo, descricao, tipo, renderizacao, visibilidade,
    data_inicio, data_fim, local, exige_presenca, agenda_id, criado_por_id, responsavel_id) VALUES

    -- Patrícia Alves (006) — agenda 031
    ('00000000-0000-0000-0000-000000000901',
     'Elaboração de Relatório Trimestral', 'Redação do relatório de gestão ambiental para o trimestre.',
     'livre', 'evento', 'privado',
     '2026-05-06 09:00:00', '2026-05-06 12:00:00', 'Mesa Pessoal', false,
     '00000000-0000-0000-0000-000000000031', '00000000-0000-0000-0000-000000000006',
     '00000000-0000-0000-0000-000000000006'),

    ('00000000-0000-0000-0000-000000000902',
     'Reunião com Perito — Laudo Técnico', 'Discussão de laudo técnico com perito externo.',
     'reuniao', 'evento', 'privado',
     '2026-06-09 14:00:00', '2026-06-09 15:30:00', 'Sala Reservada', true,
     '00000000-0000-0000-0000-000000000031', '00000000-0000-0000-0000-000000000006',
     '00000000-0000-0000-0000-000000000006'),

    ('00000000-0000-0000-0000-000000000903',
     'Férias — Patrícia', 'Período de férias programadas.',
     'recesso', 'fundo_dia', 'privado',
     '2026-07-27 00:00:00', '2026-08-07 23:59:59', null, false,
     '00000000-0000-0000-0000-000000000031', '00000000-0000-0000-0000-000000000006',
     '00000000-0000-0000-0000-000000000006'),

    -- Roberto Costa (007) — agenda 032
    ('00000000-0000-0000-0000-000000000911',
     'Saída de Campo Particular', 'Vistoria particular em área de denúncia não formalizada.',
     'operacao', 'evento', 'privado',
     '2026-05-12 08:00:00', '2026-05-12 14:00:00', 'Zona Leste', true,
     '00000000-0000-0000-0000-000000000032', '00000000-0000-0000-0000-000000000007',
     '00000000-0000-0000-0000-000000000007'),

    ('00000000-0000-0000-0000-000000000912',
     'Preparação de Auto de Infração', 'Redação e revisão de auto de infração ambiental.',
     'livre', 'evento', 'privado',
     '2026-06-03 10:00:00', '2026-06-03 12:00:00', 'Mesa Pessoal', false,
     '00000000-0000-0000-0000-000000000032', '00000000-0000-0000-0000-000000000007',
     '00000000-0000-0000-0000-000000000007'),

    -- Juliana Ferreira (008) — agenda 033
    ('00000000-0000-0000-0000-000000000921',
     'Análise de Denúncia — Ref. 2026-0312', 'Triagem e análise de denúncia ambiental recebida.',
     'livre', 'evento', 'privado',
     '2026-05-08 09:00:00', '2026-05-08 11:00:00', 'Mesa Pessoal', false,
     '00000000-0000-0000-0000-000000000033', '00000000-0000-0000-0000-000000000008',
     '00000000-0000-0000-0000-000000000008'),

    ('00000000-0000-0000-0000-000000000922',
     'Análise de Denúncia — Ref. 2026-0415', 'Triagem de nova denúncia.',
     'livre', 'evento', 'privado',
     '2026-06-15 09:00:00', '2026-06-15 11:00:00', 'Mesa Pessoal', false,
     '00000000-0000-0000-0000-000000000033', '00000000-0000-0000-0000-000000000008',
     '00000000-0000-0000-0000-000000000008'),

    -- Diego Martins (009) — agenda 034
    ('00000000-0000-0000-0000-000000000931',
     'Protocolo Diário de Entrada', 'Protocolo e distribuição de documentação recebida.',
     'livre', 'evento', 'privado',
     '2026-05-04 08:00:00', '2026-05-04 08:30:00', 'Recepção DECA', false,
     '00000000-0000-0000-0000-000000000034', '00000000-0000-0000-0000-000000000009',
     '00000000-0000-0000-0000-000000000009'),

    ('00000000-0000-0000-0000-000000000932',
     'Protocolo Diário de Entrada', 'Protocolo semanal.',
     'livre', 'evento', 'privado',
     '2026-05-11 08:00:00', '2026-05-11 08:30:00', 'Recepção DECA', false,
     '00000000-0000-0000-0000-000000000034', '00000000-0000-0000-0000-000000000009',
     '00000000-0000-0000-0000-000000000009');

INSERT INTO agenda.item_participante (item_id, usuario_id, papel_no_item, visivel_na_agenda, aceito) VALUES
    ('00000000-0000-0000-0000-000000000901', '00000000-0000-0000-0000-000000000006', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000902', '00000000-0000-0000-0000-000000000006', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000903', '00000000-0000-0000-0000-000000000006', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000911', '00000000-0000-0000-0000-000000000007', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000912', '00000000-0000-0000-0000-000000000007', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000921', '00000000-0000-0000-0000-000000000008', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000922', '00000000-0000-0000-0000-000000000008', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000931', '00000000-0000-0000-0000-000000000009', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000932', '00000000-0000-0000-0000-000000000009', 'criador', true, true);


-- =============================================================================
-- 12. ITENS DA UNIDADE DEIC (visibilidade = 'unidade', agenda 025)
--     Visíveis para Camila (013), Henrique (014), Beatriz (015), Rafael (016)
-- =============================================================================

INSERT INTO agenda.item_agenda (id, titulo, descricao, tipo, renderizacao, visibilidade,
    data_inicio, data_fim, local, exige_presenca, agenda_id, criado_por_id, responsavel_id) VALUES

    ('00000000-0000-0000-0000-000000000A01',
     'Reunião da Unidade DEIC — Maio', 'Planejamento mensal DEIC.',
     'reuniao', 'evento', 'unidade',
     '2026-05-05 14:00:00', '2026-05-05 16:00:00', 'Sala DEIC', true,
     '00000000-0000-0000-0000-000000000025', '00000000-0000-0000-0000-000000000013',
     '00000000-0000-0000-0000-000000000013'),

    ('00000000-0000-0000-0000-000000000A02',
     'Reunião da Unidade DEIC — Junho', 'Planejamento mensal DEIC.',
     'reuniao', 'evento', 'unidade',
     '2026-06-02 14:00:00', '2026-06-02 16:00:00', 'Sala DEIC', true,
     '00000000-0000-0000-0000-000000000025', '00000000-0000-0000-0000-000000000013',
     '00000000-0000-0000-0000-000000000013'),

    ('00000000-0000-0000-0000-000000000A03',
     'Reunião da Unidade DEIC — Julho', 'Planejamento mensal DEIC.',
     'reuniao', 'evento', 'unidade',
     '2026-07-07 14:00:00', '2026-07-07 16:00:00', 'Sala DEIC', true,
     '00000000-0000-0000-0000-000000000025', '00000000-0000-0000-0000-000000000013',
     '00000000-0000-0000-0000-000000000013'),

    ('00000000-0000-0000-0000-000000000A04',
     'Reunião da Unidade DEIC — Agosto', 'Planejamento mensal DEIC.',
     'reuniao', 'evento', 'unidade',
     '2026-08-04 14:00:00', '2026-08-04 16:00:00', 'Sala DEIC', true,
     '00000000-0000-0000-0000-000000000025', '00000000-0000-0000-0000-000000000013',
     '00000000-0000-0000-0000-000000000013'),

    ('00000000-0000-0000-0000-000000000A05',
     'Investigação Criminal — Fase 1', 'Período de investigação sigilosa. Todos os agentes da DEIC em alerta.',
     'periodo', 'periodo', 'unidade',
     '2026-05-25 00:00:00', '2026-06-05 23:59:59', null, false,
     '00000000-0000-0000-0000-000000000025', '00000000-0000-0000-0000-000000000013',
     '00000000-0000-0000-0000-000000000013'),

    ('00000000-0000-0000-0000-000000000A06',
     'Operação Trilha — Monitoramento', 'Monitoramento de suspeitos em operação longa.',
     'operacao', 'evento', 'unidade',
     '2026-06-08 06:00:00', '2026-06-08 22:00:00', 'Posto de Monitoramento', true,
     '00000000-0000-0000-0000-000000000025', '00000000-0000-0000-0000-000000000014',
     '00000000-0000-0000-0000-000000000014'),

    ('00000000-0000-0000-0000-000000000A07',
     'Operação Trilha — Encerramento', 'Encerramento da operação e coleta de evidências.',
     'operacao', 'evento', 'unidade',
     '2026-06-22 06:00:00', '2026-06-22 20:00:00', 'Campo Externo', true,
     '00000000-0000-0000-0000-000000000025', '00000000-0000-0000-0000-000000000014',
     '00000000-0000-0000-0000-000000000014'),

    -- Dia lotado DEIC
    ('00000000-0000-0000-0000-000000000A08',
     'Briefing Matinal — 10/06', 'Alinhamento rápido antes da operação.',
     'reuniao', 'evento', 'unidade',
     '2026-06-10 07:30:00', '2026-06-10 08:00:00', 'Sala DEIC', true,
     '00000000-0000-0000-0000-000000000025', '00000000-0000-0000-0000-000000000013',
     '00000000-0000-0000-0000-000000000013'),

    ('00000000-0000-0000-0000-000000000A09',
     'Operação Trilha — Dia 2', 'Segunda fase da operação de campo.',
     'operacao', 'evento', 'unidade',
     '2026-06-10 08:00:00', '2026-06-10 18:00:00', 'Campo', true,
     '00000000-0000-0000-0000-000000000025', '00000000-0000-0000-0000-000000000014',
     '00000000-0000-0000-0000-000000000014'),

    ('00000000-0000-0000-0000-000000000A10',
     'Oitiva — Suspeito Principal', 'Oitiva emergencial durante operação.',
     'oitiva', 'evento', 'unidade',
     '2026-06-10 15:00:00', '2026-06-10 17:00:00', 'Sala de Oitivas DEIC', true,
     '00000000-0000-0000-0000-000000000025', '00000000-0000-0000-0000-000000000014',
     '00000000-0000-0000-0000-000000000014'),

    ('00000000-0000-0000-0000-000000000A11',
     'Debriefing — Fim de Operação', 'Reunião de encerramento do dia operacional.',
     'reuniao', 'evento', 'unidade',
     '2026-06-10 18:30:00', '2026-06-10 20:00:00', 'Sala DEIC', true,
     '00000000-0000-0000-0000-000000000025', '00000000-0000-0000-0000-000000000013',
     '00000000-0000-0000-0000-000000000013'),

    ('00000000-0000-0000-0000-000000000A12',
     'Capacitação: Técnicas de Investigação', 'Treinamento para a equipe DEIC.',
     'reuniao', 'evento', 'unidade',
     '2026-07-21 09:00:00', '2026-07-21 17:00:00', 'Sala de Treinamento', false,
     '00000000-0000-0000-0000-000000000025', '00000000-0000-0000-0000-000000000013',
     '00000000-0000-0000-0000-000000000013');

INSERT INTO agenda.item_participante (item_id, usuario_id, papel_no_item, visivel_na_agenda, aceito) VALUES
    -- criador = responsavel em todos os itens DEIC → uma linha por item
    ('00000000-0000-0000-0000-000000000A01', '00000000-0000-0000-0000-000000000013', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000A02', '00000000-0000-0000-0000-000000000013', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000A03', '00000000-0000-0000-0000-000000000013', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000A04', '00000000-0000-0000-0000-000000000013', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000A05', '00000000-0000-0000-0000-000000000013', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000A06', '00000000-0000-0000-0000-000000000014', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000A07', '00000000-0000-0000-0000-000000000014', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000A08', '00000000-0000-0000-0000-000000000013', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000A09', '00000000-0000-0000-0000-000000000014', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000A10', '00000000-0000-0000-0000-000000000014', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000A11', '00000000-0000-0000-0000-000000000013', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000A12', '00000000-0000-0000-0000-000000000013', 'criador', true, true);


-- =============================================================================
-- 13. ITENS PRIVADOS — Agendas pessoais DEIC
-- =============================================================================

INSERT INTO agenda.item_agenda (id, titulo, descricao, tipo, renderizacao, visibilidade,
    data_inicio, data_fim, local, exige_presenca, agenda_id, criado_por_id, responsavel_id) VALUES

    -- Camila Santos (013) — agenda 035
    ('00000000-0000-0000-0000-000000000B01',
     'Análise de Dossiê Sigiloso', 'Leitura e análise de relatório sigiloso de inteligência.',
     'livre', 'evento', 'privado',
     '2026-05-06 09:00:00', '2026-05-06 11:00:00', 'Sala Segura', true,
     '00000000-0000-0000-0000-000000000035', '00000000-0000-0000-0000-000000000013',
     '00000000-0000-0000-0000-000000000013'),

    ('00000000-0000-0000-0000-000000000B02',
     'Reunião com Delegado-Geral', 'Reunião reservada com a chefia máxima.',
     'reuniao', 'evento', 'privado',
     '2026-06-16 10:00:00', '2026-06-16 12:00:00', 'Gabinete da Diretoria', true,
     '00000000-0000-0000-0000-000000000035', '00000000-0000-0000-0000-000000000013',
     '00000000-0000-0000-0000-000000000013'),

    ('00000000-0000-0000-0000-000000000B03',
     'Férias — Camila', 'Período de férias.',
     'recesso', 'fundo_dia', 'privado',
     '2026-08-17 00:00:00', '2026-08-28 23:59:59', null, false,
     '00000000-0000-0000-0000-000000000035', '00000000-0000-0000-0000-000000000013',
     '00000000-0000-0000-0000-000000000013'),

    -- Henrique Oliveira (014) — agenda 036
    ('00000000-0000-0000-0000-000000000B11',
     'Elaboração de Plano de Operação', 'Planejamento detalhado da Operação Trilha.',
     'livre', 'evento', 'privado',
     '2026-05-19 09:00:00', '2026-05-19 12:00:00', 'Mesa Pessoal', false,
     '00000000-0000-0000-0000-000000000036', '00000000-0000-0000-0000-000000000014',
     '00000000-0000-0000-0000-000000000014'),

    ('00000000-0000-0000-0000-000000000B12',
     'Reunião de Inteligência — Mensal', 'Reunião mensal de atualização de inteligência.',
     'reuniao', 'evento', 'privado',
     '2026-07-14 16:00:00', '2026-07-14 17:30:00', 'Sala Segura', true,
     '00000000-0000-0000-0000-000000000036', '00000000-0000-0000-0000-000000000014',
     '00000000-0000-0000-0000-000000000014'),

    -- Beatriz Correia (015) — agenda 037
    ('00000000-0000-0000-0000-000000000B21',
     'Análise de Interceptação Telefônica', 'Análise de material sigiloso. Acesso restrito.',
     'livre', 'evento', 'privado',
     '2026-05-13 09:00:00', '2026-05-13 13:00:00', 'Sala Segura', true,
     '00000000-0000-0000-0000-000000000037', '00000000-0000-0000-0000-000000000015',
     '00000000-0000-0000-0000-000000000015'),

    ('00000000-0000-0000-0000-000000000B22',
     'Redação de Relatório de IC', 'Relatório de inteligência criminal a ser encaminhado.',
     'livre', 'evento', 'privado',
     '2026-06-23 10:00:00', '2026-06-23 12:00:00', 'Mesa Pessoal', false,
     '00000000-0000-0000-0000-000000000037', '00000000-0000-0000-0000-000000000015',
     '00000000-0000-0000-0000-000000000015'),

    -- Rafael Melo (016) — agenda 038
    ('00000000-0000-0000-0000-000000000B31',
     'Relatório de Estágio DEIC — Quinzenal', 'Entrega de relatório quinzenal de atividades.',
     'livre', 'evento', 'privado',
     '2026-05-15 17:00:00', '2026-05-15 17:30:00', 'E-mail / Portal RH', false,
     '00000000-0000-0000-0000-000000000038', '00000000-0000-0000-0000-000000000016',
     '00000000-0000-0000-0000-000000000016'),

    ('00000000-0000-0000-0000-000000000B32',
     'Relatório de Estágio DEIC — Quinzenal', 'Entrega de relatório quinzenal.',
     'livre', 'evento', 'privado',
     '2026-05-29 17:00:00', '2026-05-29 17:30:00', 'E-mail / Portal RH', false,
     '00000000-0000-0000-0000-000000000038', '00000000-0000-0000-0000-000000000016',
     '00000000-0000-0000-0000-000000000016');

INSERT INTO agenda.item_participante (item_id, usuario_id, papel_no_item, visivel_na_agenda, aceito) VALUES
    ('00000000-0000-0000-0000-000000000B01', '00000000-0000-0000-0000-000000000013', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000B02', '00000000-0000-0000-0000-000000000013', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000B03', '00000000-0000-0000-0000-000000000013', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000B11', '00000000-0000-0000-0000-000000000014', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000B12', '00000000-0000-0000-0000-000000000014', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000B21', '00000000-0000-0000-0000-000000000015', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000B22', '00000000-0000-0000-0000-000000000015', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000B31', '00000000-0000-0000-0000-000000000016', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000B32', '00000000-0000-0000-0000-000000000016', 'criador', true, true);


-- =============================================================================
-- 14. CENÁRIO DELEGADO — Diego (secretaria DECA) cria para Roberto (gestor)
-- =============================================================================

INSERT INTO agenda.item_agenda (id, titulo, descricao, tipo, renderizacao, visibilidade,
    data_inicio, data_fim, local, exige_presenca, agenda_id, criado_por_id, responsavel_id) VALUES

    ('00000000-0000-0000-0000-000000000C01',
     'Audiência Pública — Licenciamento Ambiental', 'Representação da DECA em audiência pública.',
     'reuniao', 'evento', 'privado',
     '2026-06-04 09:00:00', '2026-06-04 13:00:00', 'Câmara Municipal', true,
     '00000000-0000-0000-0000-000000000032', '00000000-0000-0000-0000-000000000009',
     '00000000-0000-0000-0000-000000000007'),

    ('00000000-0000-0000-0000-000000000C02',
     'Despacho com Assessoria Jurídica', 'Acompanhamento de processo administrativo.',
     'reuniao', 'evento', 'privado',
     '2026-07-08 15:00:00', '2026-07-08 16:30:00', 'Sala da Assessoria', true,
     '00000000-0000-0000-0000-000000000032', '00000000-0000-0000-0000-000000000009',
     '00000000-0000-0000-0000-000000000007');

INSERT INTO agenda.item_participante (item_id, usuario_id, papel_no_item, visivel_na_agenda, aceito) VALUES
    ('00000000-0000-0000-0000-000000000C01', '00000000-0000-0000-0000-000000000009', 'delegado',   true, true),
    ('00000000-0000-0000-0000-000000000C01', '00000000-0000-0000-0000-000000000007', 'responsavel', true, true),
    ('00000000-0000-0000-0000-000000000C02', '00000000-0000-0000-0000-000000000009', 'delegado',   true, true),
    ('00000000-0000-0000-0000-000000000C02', '00000000-0000-0000-0000-000000000007', 'responsavel', true, true);


-- =============================================================================
-- 15. CENÁRIO DELEGADO — Rafael (estagiário DEIC) cria para Henrique (gestor)
-- =============================================================================

INSERT INTO agenda.item_agenda (id, titulo, descricao, tipo, renderizacao, visibilidade,
    data_inicio, data_fim, local, exige_presenca, agenda_id, criado_por_id, responsavel_id) VALUES

    ('00000000-0000-0000-0000-000000000C11',
     'Oitiva — Caso Trilha 2026-089', 'Oitiva de suspeito agendada pelo estagiário Rafael.',
     'oitiva', 'evento', 'privado',
     '2026-06-12 10:00:00', '2026-06-12 12:00:00', 'Sala de Oitivas DEIC', true,
     '00000000-0000-0000-0000-000000000036', '00000000-0000-0000-0000-000000000016',
     '00000000-0000-0000-0000-000000000014'),

    ('00000000-0000-0000-0000-000000000C12',
     'Oitiva — Testemunha Caso Trilha', 'Depoimento de testemunha-chave.',
     'oitiva', 'evento', 'privado',
     '2026-06-19 14:00:00', '2026-06-19 16:00:00', 'Sala de Oitivas DEIC', true,
     '00000000-0000-0000-0000-000000000036', '00000000-0000-0000-0000-000000000016',
     '00000000-0000-0000-0000-000000000014');

INSERT INTO agenda.item_participante (item_id, usuario_id, papel_no_item, visivel_na_agenda, aceito) VALUES
    ('00000000-0000-0000-0000-000000000C11', '00000000-0000-0000-0000-000000000016', 'delegado',   true, true),
    ('00000000-0000-0000-0000-000000000C11', '00000000-0000-0000-0000-000000000014', 'responsavel', true, true),
    ('00000000-0000-0000-0000-000000000C12', '00000000-0000-0000-0000-000000000016', 'delegado',   true, true),
    ('00000000-0000-0000-0000-000000000C12', '00000000-0000-0000-0000-000000000014', 'responsavel', true, true);


-- =============================================================================
-- 16. ITENS DE UNIDADE DECA via agenda pessoal (visibilidade = 'unidade', cláusula 3b)
--     Criados por Patrícia (006) na agenda PESSOAL dela — com visibilidade 'unidade'
--     Visíveis para membros do mesmo grupo (DECA) via cláusula 3b do VIS-004
-- =============================================================================

INSERT INTO agenda.item_agenda (id, titulo, descricao, tipo, renderizacao, visibilidade,
    data_inicio, data_fim, local, exige_presenca, agenda_id, criado_por_id, responsavel_id) VALUES

    ('00000000-0000-0000-0000-000000000D01',
     'Aviso: Relatório Trimestral DECA', 'Prazo de entrega de relatórios individuais à coordenação.',
     'livre', 'fundo_dia', 'unidade',
     '2026-06-30 00:00:00', '2026-06-30 23:59:59', null, false,
     '00000000-0000-0000-0000-000000000031', '00000000-0000-0000-0000-000000000006',
     null),

    ('00000000-0000-0000-0000-000000000D02',
     'Aviso: Escala de Plantão — Julho', 'Comunicado sobre escala de plantão para o mês de julho.',
     'livre', 'fundo_dia', 'unidade',
     '2026-06-25 00:00:00', '2026-06-25 23:59:59', null, false,
     '00000000-0000-0000-0000-000000000031', '00000000-0000-0000-0000-000000000006',
     null);

INSERT INTO agenda.item_participante (item_id, usuario_id, papel_no_item, visivel_na_agenda, aceito) VALUES
    ('00000000-0000-0000-0000-000000000D01', '00000000-0000-0000-0000-000000000006', 'criador', true, true),
    ('00000000-0000-0000-0000-000000000D02', '00000000-0000-0000-0000-000000000006', 'criador', true, true);


-- =============================================================================
-- FIM DA MIGRATION V9
-- =============================================================================
-- Resumo dos fixtures inseridos:
--   Seção  1: 5  feriados/pontos facultativos nacionais (global)
--   Seção  2: 13 itens da unidade SRI (unidade)
--   Seção  3: item_participante para seção 2
--   Seção  4: 8  itens de grupo SRI (grupo)
--   Seção  5: 14 itens privados — agendas pessoais SRI
--   Seção  6: 3  oitivas delegadas (Lucas → João Pereira)
--   Seção  7: 3  reuniões delegadas (Maria Silva → João Pereira)
--   Seção  8: 3  itens interinstitucionais (participante)
--   Seção  9: 3  itens compartilhados entre unidades (selecionado)
--   Seção 10: 11 itens da unidade DECA (unidade)
--   Seção 11: item_participante para seção 10
--   Seção 12: 9  itens privados — agendas pessoais DECA
--   Seção 13: 12 itens da unidade DEIC (unidade)
--   Seção 14: item_participante para seção 13
--   Seção 15: 9  itens privados — agendas pessoais DEIC
--   Seção 16: 2  delegados (Diego → Roberto / DECA)
--   Seção 17: 2  delegados (Rafael → Henrique / DEIC)
--   Seção 18: 2  itens unidade via agenda pessoal (cláusula 3b — DECA)
--
--   TOTAL: ~100 itens de agenda cobrindo todas as visibilidades e cenários
-- =============================================================================
