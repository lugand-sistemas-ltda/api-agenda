-- =============================================================================
-- V5 — Autenticação por Matrícula + Senha + Sessão Opaca
-- Referências: ADR-002 PA-016 (autenticação de tela); Iteração 2
-- Data: 2026-04-21
-- =============================================================================
-- Alterações:
--   1. Habilitar pgcrypto (bcrypt para hash de senhas)
--   2. Colunas matricula + senha_hash em agenda.usuario
--   3. Tabela agenda.sessao (sessão opaca com expiração)
--   4. Atualizar os 3 usuários seed existentes (matricula + senha)
--   5. Adicionar 10 novos usuários: SRI +2, DECA ×4, DEIC ×4
--   6. Criar grupos DECA e DEIC com agendas de unidade + pessoais
--   7. Índices de performance para sessão
-- =============================================================================

-- Senha padrão para todos os usuários seed: SRI@2026
-- bcrypt gerado via pgcrypto (gen_salt('bf', 12) — custo 12)
-- Compatível com verificação em Java via at.favre.lib:bcrypt


-- =============================================================================
-- 1. PGCRYPTO — necessário para gen_salt / crypt (bcrypt)
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;


-- =============================================================================
-- 2. COLUNAS: matricula e senha_hash em agenda.usuario
--    Adicionadas como nullable → UPDATE existentes → NOT NULL + UNIQUE
-- =============================================================================

ALTER TABLE agenda.usuario
    ADD COLUMN matricula  VARCHAR(20),
    ADD COLUMN senha_hash VARCHAR(60);


-- =============================================================================
-- 3. TABELA: agenda.sessao
--    Sessão opaca — criada no login, invalidada no logout ou ao expirar (8h).
-- =============================================================================

CREATE TABLE agenda.sessao (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id  UUID NOT NULL REFERENCES agenda.usuario(id) ON DELETE CASCADE,
    criado_em   TIMESTAMP NOT NULL DEFAULT now(),
    expira_em   TIMESTAMP NOT NULL DEFAULT (now() + INTERVAL '8 hours')
);

CREATE INDEX idx_sessao_usuario ON agenda.sessao(usuario_id);
CREATE INDEX idx_sessao_expira  ON agenda.sessao(expira_em);


-- =============================================================================
-- 4. ATUALIZAR usuários seed existentes — matricula + senha
-- =============================================================================

UPDATE agenda.usuario SET
    matricula  = '1000001',
    senha_hash = crypt('SRI@2026', gen_salt('bf', 12))
WHERE id = '00000000-0000-0000-0000-000000000001'; -- Administrador

UPDATE agenda.usuario SET
    matricula  = '1000002',
    senha_hash = crypt('SRI@2026', gen_salt('bf', 12))
WHERE id = '00000000-0000-0000-0000-000000000002'; -- André Myszko

UPDATE agenda.usuario SET
    matricula  = '1000003',
    senha_hash = crypt('SRI@2026', gen_salt('bf', 12))
WHERE id = '00000000-0000-0000-0000-000000000003'; -- Maria Silva


-- =============================================================================
-- 5. APLICAR NOT NULL + UNIQUE após preenchimento dos existentes
-- =============================================================================

ALTER TABLE agenda.usuario
    ALTER COLUMN matricula  SET NOT NULL,
    ALTER COLUMN senha_hash SET NOT NULL;

ALTER TABLE agenda.usuario
    ADD CONSTRAINT uq_usuario_matricula UNIQUE (matricula);


-- =============================================================================
-- 6. NOVOS USUÁRIOS — SRI (gestor + estagiário)
-- =============================================================================

INSERT INTO agenda.usuario (id, nome, email, matricula, senha_hash) VALUES
    (
        '00000000-0000-0000-0000-000000000004',
        'João Pereira',
        'joao.pereira@sri.local',
        '1000004',
        crypt('SRI@2026', gen_salt('bf', 12))
    ),
    (
        '00000000-0000-0000-0000-000000000005',
        'Lucas Gomes',
        'lucas.gomes@sri.local',
        '1000005',
        crypt('SRI@2026', gen_salt('bf', 12))
    );

-- Agendas pessoais
INSERT INTO agenda.agenda (id, nome, tipo, proprietario_id) VALUES
    ('00000000-0000-0000-0000-000000000026', 'Agenda Pessoal — João Pereira',  'pessoal', '00000000-0000-0000-0000-000000000004'),
    ('00000000-0000-0000-0000-000000000027', 'Agenda Pessoal — Lucas Gomes',   'pessoal', '00000000-0000-0000-0000-000000000005');

-- Membros do grupo SRI
INSERT INTO agenda.grupo_membro (grupo_id, usuario_id, papel) VALUES
    ('00000000-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000000000004', 'gestor'),
    ('00000000-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000000000005', 'estagiario');


-- =============================================================================
-- 7. UNIDADE: DECA — Delegacia Especializada em Crimes Ambientais
-- =============================================================================

INSERT INTO agenda.grupo (id, nome, descricao) VALUES
    (
        '00000000-0000-0000-0000-000000000011',
        'DECA',
        'Delegacia Especializada em Crimes Ambientais'
    );

INSERT INTO agenda.agenda (id, nome, tipo, grupo_id) VALUES
    ('00000000-0000-0000-0000-000000000024', 'Agenda da Unidade DECA', 'unidade', '00000000-0000-0000-0000-000000000011');

-- Usuários DECA
INSERT INTO agenda.usuario (id, nome, email, matricula, senha_hash) VALUES
    ('00000000-0000-0000-0000-000000000006', 'Patrícia Alves',   'patricia.alves@deca.local',   '2000001', crypt('SRI@2026', gen_salt('bf', 12))),
    ('00000000-0000-0000-0000-000000000007', 'Roberto Costa',    'roberto.costa@deca.local',    '2000002', crypt('SRI@2026', gen_salt('bf', 12))),
    ('00000000-0000-0000-0000-000000000008', 'Juliana Ferreira', 'juliana.ferreira@deca.local', '2000003', crypt('SRI@2026', gen_salt('bf', 12))),
    ('00000000-0000-0000-0000-000000000009', 'Diego Martins',    'diego.martins@deca.local',    '2000004', crypt('SRI@2026', gen_salt('bf', 12)));

INSERT INTO agenda.agenda (id, nome, tipo, proprietario_id) VALUES
    ('00000000-0000-0000-0000-000000000031', 'Agenda Pessoal — Patrícia Alves',   'pessoal', '00000000-0000-0000-0000-000000000006'),
    ('00000000-0000-0000-0000-000000000032', 'Agenda Pessoal — Roberto Costa',    'pessoal', '00000000-0000-0000-0000-000000000007'),
    ('00000000-0000-0000-0000-000000000033', 'Agenda Pessoal — Juliana Ferreira', 'pessoal', '00000000-0000-0000-0000-000000000008'),
    ('00000000-0000-0000-0000-000000000034', 'Agenda Pessoal — Diego Martins',    'pessoal', '00000000-0000-0000-0000-000000000009');

INSERT INTO agenda.grupo_membro (grupo_id, usuario_id, papel) VALUES
    ('00000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000006', 'administrador'),
    ('00000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000007', 'gestor'),
    ('00000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000008', 'operador'),
    ('00000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000009', 'secretaria');


-- =============================================================================
-- 8. UNIDADE: DEIC — Departamento Estadual de Investigações Criminais
-- =============================================================================

INSERT INTO agenda.grupo (id, nome, descricao) VALUES
    (
        '00000000-0000-0000-0000-000000000012',
        'DEIC',
        'Departamento Estadual de Investigações Criminais'
    );

INSERT INTO agenda.agenda (id, nome, tipo, grupo_id) VALUES
    ('00000000-0000-0000-0000-000000000025', 'Agenda da Unidade DEIC', 'unidade', '00000000-0000-0000-0000-000000000012');

-- Usuários DEIC
INSERT INTO agenda.usuario (id, nome, email, matricula, senha_hash) VALUES
    ('00000000-0000-0000-0000-000000000013', 'Camila Santos',     'camila.santos@deic.local',     '3000001', crypt('SRI@2026', gen_salt('bf', 12))),
    ('00000000-0000-0000-0000-000000000014', 'Henrique Oliveira', 'henrique.oliveira@deic.local', '3000002', crypt('SRI@2026', gen_salt('bf', 12))),
    ('00000000-0000-0000-0000-000000000015', 'Beatriz Correia',   'beatriz.correia@deic.local',   '3000003', crypt('SRI@2026', gen_salt('bf', 12))),
    ('00000000-0000-0000-0000-000000000016', 'Rafael Melo',       'rafael.melo@deic.local',       '3000004', crypt('SRI@2026', gen_salt('bf', 12)));

INSERT INTO agenda.agenda (id, nome, tipo, proprietario_id) VALUES
    ('00000000-0000-0000-0000-000000000035', 'Agenda Pessoal — Camila Santos',     'pessoal', '00000000-0000-0000-0000-000000000013'),
    ('00000000-0000-0000-0000-000000000036', 'Agenda Pessoal — Henrique Oliveira', 'pessoal', '00000000-0000-0000-0000-000000000014'),
    ('00000000-0000-0000-0000-000000000037', 'Agenda Pessoal — Beatriz Correia',   'pessoal', '00000000-0000-0000-0000-000000000015'),
    ('00000000-0000-0000-0000-000000000038', 'Agenda Pessoal — Rafael Melo',       'pessoal', '00000000-0000-0000-0000-000000000016');

INSERT INTO agenda.grupo_membro (grupo_id, usuario_id, papel) VALUES
    ('00000000-0000-0000-0000-000000000012', '00000000-0000-0000-0000-000000000013', 'administrador'),
    ('00000000-0000-0000-0000-000000000012', '00000000-0000-0000-0000-000000000014', 'gestor'),
    ('00000000-0000-0000-0000-000000000012', '00000000-0000-0000-0000-000000000015', 'operador'),
    ('00000000-0000-0000-0000-000000000012', '00000000-0000-0000-0000-000000000016', 'estagiario');
