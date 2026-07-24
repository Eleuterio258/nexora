-- Migration 121: Permissao auth.pin_admin para gestao de PINs
SET search_path TO auth, public;

-- Superadmin herda a permissao por tipo
INSERT INTO auth.permissoes_tipo (tipo, modulo, acao) VALUES
    ('superadmin', 'auth', 'pin_admin')
ON CONFLICT DO NOTHING;

-- Aplicar a cargos ja existentes
DO $$
DECLARE
    v_cargo_id BIGINT;
BEGIN
    SELECT id INTO v_cargo_id FROM auth.cargos WHERE nome = 'Administrador' LIMIT 1;
    IF FOUND THEN
        INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
            (v_cargo_id, 'auth', 'pin_admin')
        ON CONFLICT DO NOTHING;
    END IF;

    SELECT id INTO v_cargo_id FROM auth.cargos WHERE nome = 'Gestor de TI' LIMIT 1;
    IF FOUND THEN
        INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
            (v_cargo_id, 'auth', 'pin_admin')
        ON CONFLICT DO NOTHING;
    END IF;
END $$;

-- Atualizar funcao de criacao de cargos padrao
-- Migration 081: Função de provisionamento de cargos-padrão por tenant
-- Cria auth.criar_cargos_padrao(tenant_id) que inicializa os cargos documentados
-- em CARGOS.md para uma organização recém-criada.
-- Chamada automaticamente em CriarTenant (superadmin).

SET search_path TO auth, public;

-- Garantir UNIQUE(tenant_id, nome) em auth.cargos
ALTER TABLE auth.cargos DROP CONSTRAINT IF EXISTS cargos_tenant_id_nome_key;
ALTER TABLE auth.cargos ADD CONSTRAINT cargos_tenant_id_nome_key UNIQUE (tenant_id, nome);

-- ─────────────────────────────────────────────────────────────────────────────
-- Função principal
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION auth.criar_cargos_padrao(p_tenant_id BIGINT)
RETURNS void
LANGUAGE plpgsql AS
$$
DECLARE
    v_id BIGINT;
BEGIN

    -- ═══════════════════════════════════════════════════════════════════════
    -- 4.1  SISTEMA E ADMINISTRAÇÃO
    -- ═══════════════════════════════════════════════════════════════════════

    -- Administrador — todos os módulos, todas as acções
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Administrador',
            'Acesso total ao tenant. Gere utilizadores, cargos e configurações.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
    SELECT v_id, m.modulo, a.acao
    FROM (VALUES
        ('auth'), ('autorizacao'), ('empresa'), ('sistema-configuracao'),
        ('auditoria'), ('seguranca'), ('clientes'), ('crm'), ('vendas'),
        ('assinaturas'), ('faturacao'), ('pos'), ('financeiro'), ('tesouraria'),
        ('contabilidade'), ('impostos'), ('multi-moeda'), ('centros-custo'),
        ('stock'), ('compras'), ('logistica'), ('recursos-humanos'),
        ('pedido-ferias'), ('gestao-escolar'), ('notificacoes')
    ) AS m(modulo)
    CROSS JOIN (VALUES
        ('ver'), ('criar'), ('editar'), ('apagar'), ('exportar'),
        ('aprovar'), ('configurar'), ('relatorios')
    ) AS a(acao)
    ON CONFLICT DO NOTHING;
    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'auth', 'pin_admin')
    ON CONFLICT DO NOTHING;


    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'gestao-escolar', 'gerir_alunos'),
        (v_id, 'gestao-escolar', 'gerir_turmas'),
        (v_id, 'gestao-escolar', 'lancar_notas'),
        (v_id, 'gestao-escolar', 'gerir_presencas'),
        (v_id, 'gestao-escolar', 'gerir_horarios'),
        (v_id, 'gestao-escolar', 'gerir_biblioteca'),
        (v_id, 'gestao-escolar', 'gerir_propinas'),
        (v_id, 'gestao-escolar', 'gerir_ocorrencias'),
        (v_id, 'gestao-escolar', 'gerir_matriculas'),
        (v_id, 'gestao-escolar', 'gerir_calendario'),
        (v_id, 'gestao-escolar', 'portal_aluno')
    ON CONFLICT DO NOTHING;

    -- ───────────────────────────────────────────────────────────────────────

    -- Gestor de TI
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Gestor de TI',
            'Gestão técnica, integrações e segurança.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'auth',                'ver'),        (v_id, 'auth',                'criar'),
        (v_id, 'auth',                'editar'),     (v_id, 'auth',                'apagar'),
        (v_id, 'auth',                'configurar'), (v_id, 'auth',                'relatorios'),
        (v_id, 'autorizacao',         'ver'),        (v_id, 'autorizacao',         'criar'),
        (v_id, 'autorizacao',         'editar'),     (v_id, 'autorizacao',         'apagar'),
        (v_id, 'autorizacao',         'configurar'), (v_id, 'autorizacao',         'relatorios'),
        (v_id, 'sistema-configuracao','ver'),        (v_id, 'sistema-configuracao','editar'),
        (v_id, 'sistema-configuracao','configurar'), (v_id, 'sistema-configuracao','relatorios'),
        (v_id, 'auditoria',           'ver'),        (v_id, 'auditoria',           'relatorios'),
        (v_id, 'seguranca',           'ver'),        (v_id, 'seguranca',           'editar'),
        (v_id, 'seguranca',           'configurar'), (v_id, 'seguranca',           'relatorios')
    ON CONFLICT DO NOTHING;
    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'auth', 'pin_admin')
    ON CONFLICT DO NOTHING;


    -- ───────────────────────────────────────────────────────────────────────

    -- Auditor Interno
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Auditor Interno',
            'Acesso de leitura para fins de auditoria.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'auditoria',    'ver'), (v_id, 'auditoria',    'relatorios'), (v_id, 'auditoria',    'exportar'),
        (v_id, 'financeiro',   'ver'), (v_id, 'financeiro',   'relatorios'),
        (v_id, 'contabilidade','ver'), (v_id, 'contabilidade','relatorios')
    ON CONFLICT DO NOTHING;

    -- ═══════════════════════════════════════════════════════════════════════
    -- 4.2  RECURSOS HUMANOS
    -- ═══════════════════════════════════════════════════════════════════════

    -- Director de RH
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Director de RH',
            'Gestão estratégica de RH, aprovação de políticas.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
    SELECT v_id, 'recursos-humanos', a.acao
    FROM (VALUES
        ('ver'),('criar'),('editar'),('apagar'),('exportar'),('aprovar'),('configurar'),('relatorios')
    ) AS a(acao)
    ON CONFLICT DO NOTHING;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'pedido-ferias', 'ver'), (v_id, 'pedido-ferias', 'aprovar'),
        (v_id, 'pedido-ferias', 'relatorios'), (v_id, 'pedido-ferias', 'exportar')
    ON CONFLICT DO NOTHING;

    -- ───────────────────────────────────────────────────────────────────────

    -- Gestor de RH
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Gestor de RH',
            'Admissão, transferências, avaliações.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'recursos-humanos', 'ver'),       (v_id, 'recursos-humanos', 'criar'),
        (v_id, 'recursos-humanos', 'editar'),    (v_id, 'recursos-humanos', 'relatorios'),
        (v_id, 'recursos-humanos', 'exportar'),
        (v_id, 'pedido-ferias',    'ver'),       (v_id, 'pedido-ferias',    'aprovar')
    ON CONFLICT DO NOTHING;

    -- ───────────────────────────────────────────────────────────────────────

    -- Técnico de Processamento Salarial
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Técnico de Processamento Salarial',
            'Folha de salários, componentes salariais, benefícios.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'recursos-humanos', 'ver'), (v_id, 'recursos-humanos', 'editar'),
        (v_id, 'contabilidade',    'ver')
    ON CONFLICT DO NOTHING;

    -- ───────────────────────────────────────────────────────────────────────

    -- Técnico de RH
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Técnico de RH',
            'Fichas de funcionários, formações, documentação.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'recursos-humanos', 'ver'), (v_id, 'recursos-humanos', 'criar'),
        (v_id, 'recursos-humanos', 'editar'),
        (v_id, 'pedido-ferias',    'ver')
    ON CONFLICT DO NOTHING;

    -- ═══════════════════════════════════════════════════════════════════════
    -- 4.3  RECRUTAMENTO
    -- ═══════════════════════════════════════════════════════════════════════

    -- Gestor de Recrutamento
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Gestor de Recrutamento',
            'Aprova vagas, gere o processo end-to-end, integra com RH.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
    SELECT v_id, 'recrutamento', a.acao
    FROM (VALUES
        ('ver'),('criar'),('editar'),('apagar'),('aprovar'),('configurar'),('relatorios'),('exportar')
    ) AS a(acao)
    ON CONFLICT DO NOTHING;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'recursos-humanos', 'ver')
    ON CONFLICT DO NOTHING;

    -- ───────────────────────────────────────────────────────────────────────

    -- Recrutador
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Recrutador',
            'Publica vagas, triagem e gestão de candidaturas.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'recrutamento', 'ver'), (v_id, 'recrutamento', 'criar'),
        (v_id, 'recrutamento', 'editar')
    ON CONFLICT DO NOTHING;

    -- ───────────────────────────────────────────────────────────────────────

    -- Responsável de Entrevistas
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Responsável de Entrevistas',
            'Avalia candidatos e regista feedback de entrevistas.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'recrutamento', 'ver')
    ON CONFLICT DO NOTHING;

    -- ═══════════════════════════════════════════════════════════════════════
    -- 4.4  GESTÃO DE CLIENTES
    -- ═══════════════════════════════════════════════════════════════════════

    -- Director Comercial
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Director Comercial',
            'Visão global, aprovação de descontos e contratos.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
    SELECT v_id, m.modulo, a.acao
    FROM (VALUES ('clientes'), ('vendas'), ('crm')) AS m(modulo)
    CROSS JOIN (VALUES
        ('ver'),('criar'),('editar'),('apagar'),('exportar'),('aprovar'),('configurar'),('relatorios')
    ) AS a(acao)
    ON CONFLICT DO NOTHING;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'faturacao', 'ver'), (v_id, 'faturacao', 'relatorios')
    ON CONFLICT DO NOTHING;

    -- ───────────────────────────────────────────────────────────────────────

    -- Gestor de Conta
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Gestor de Conta',
            'Carteira de clientes e oportunidades.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'clientes', 'ver'), (v_id, 'clientes', 'editar'),
        (v_id, 'vendas',   'ver'), (v_id, 'vendas',   'criar'), (v_id, 'vendas',   'editar'),
        (v_id, 'crm',      'ver'), (v_id, 'crm',      'criar'), (v_id, 'crm',      'editar'),
        (v_id, 'crm',      'apagar')
    ON CONFLICT DO NOTHING;

    -- ───────────────────────────────────────────────────────────────────────

    -- Técnico Comercial
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Técnico Comercial',
            'Orçamentos e seguimento de oportunidades.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'clientes', 'ver'),
        (v_id, 'vendas',   'ver'), (v_id, 'vendas', 'criar'),
        (v_id, 'crm',      'ver'), (v_id, 'crm',    'editar')
    ON CONFLICT DO NOTHING;

    -- ───────────────────────────────────────────────────────────────────────

    -- Assistente Administrativo
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Assistente Administrativo',
            'Registo de clientes e consulta de faturas.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'clientes',  'ver'), (v_id, 'clientes', 'criar'),
        (v_id, 'faturacao', 'ver')
    ON CONFLICT DO NOTHING;

    -- ═══════════════════════════════════════════════════════════════════════
    -- 4.5  FINANCEIRO E CONTABILIDADE
    -- ═══════════════════════════════════════════════════════════════════════

    -- Director Financeiro
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Director Financeiro',
            'Supervisão total da área financeira.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
    SELECT v_id, m.modulo, a.acao
    FROM (VALUES ('financeiro'), ('contabilidade'), ('tesouraria'), ('impostos'), ('faturacao')) AS m(modulo)
    CROSS JOIN (VALUES
        ('ver'),('criar'),('editar'),('apagar'),('exportar'),('aprovar'),('configurar'),('relatorios')
    ) AS a(acao)
    ON CONFLICT DO NOTHING;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'centros-custo', 'ver'),       (v_id, 'centros-custo', 'criar'),
        (v_id, 'centros-custo', 'editar'),    (v_id, 'centros-custo', 'relatorios'),
        (v_id, 'multi-moeda',   'ver'),       (v_id, 'multi-moeda',   'criar'),
        (v_id, 'multi-moeda',   'editar'),    (v_id, 'multi-moeda',   'configurar'),
        (v_id, 'auditoria',     'ver'),       (v_id, 'auditoria',     'relatorios')
    ON CONFLICT DO NOTHING;

    -- ───────────────────────────────────────────────────────────────────────

    -- Contabilista
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Contabilista',
            'Lançamentos contabilísticos, declarações fiscais.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'contabilidade', 'ver'),       (v_id, 'contabilidade', 'criar'),
        (v_id, 'contabilidade', 'editar'),    (v_id, 'contabilidade', 'relatorios'),
        (v_id, 'contabilidade', 'exportar'),
        (v_id, 'impostos',      'ver'),       (v_id, 'impostos',      'criar'),
        (v_id, 'impostos',      'relatorios'),
        (v_id, 'financeiro',    'ver'),       (v_id, 'financeiro',    'relatorios')
    ON CONFLICT DO NOTHING;

    -- ───────────────────────────────────────────────────────────────────────

    -- Tesoureiro
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Tesoureiro',
            'Caixa, bancos, conciliação.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'tesouraria', 'ver'),      (v_id, 'tesouraria', 'criar'),
        (v_id, 'tesouraria', 'editar'),   (v_id, 'tesouraria', 'apagar'),
        (v_id, 'tesouraria', 'exportar'), (v_id, 'tesouraria', 'relatorios'),
        (v_id, 'financeiro', 'ver'),      (v_id, 'financeiro', 'editar')
    ON CONFLICT DO NOTHING;

    -- ───────────────────────────────────────────────────────────────────────

    -- Caixa
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Caixa',
            'Operações de ponto de venda.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'pos',       'ver'), (v_id, 'pos',       'criar'),
        (v_id, 'pos',       'editar'), (v_id, 'pos',    'relatorios'),
        (v_id, 'tesouraria','ver')
    ON CONFLICT DO NOTHING;

    -- ───────────────────────────────────────────────────────────────────────

    -- Responsável de Faturação
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Responsável de Faturação',
            'Emissão e gestão de faturas.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'faturacao', 'ver'),      (v_id, 'faturacao', 'criar'),
        (v_id, 'faturacao', 'editar'),   (v_id, 'faturacao', 'relatorios'),
        (v_id, 'faturacao', 'exportar'),
        (v_id, 'clientes',  'ver')
    ON CONFLICT DO NOTHING;

    -- ───────────────────────────────────────────────────────────────────────

    -- Analista Financeiro
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Analista Financeiro',
            'Análise financeira e reporting.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'financeiro',    'ver'), (v_id, 'financeiro',    'relatorios'),
        (v_id, 'financeiro',    'exportar'),
        (v_id, 'contabilidade', 'ver'), (v_id, 'contabilidade', 'relatorios'),
        (v_id, 'centros-custo', 'ver'), (v_id, 'centros-custo', 'relatorios')
    ON CONFLICT DO NOTHING;

    -- ═══════════════════════════════════════════════════════════════════════
    -- 4.6  GESTÃO ESCOLAR
    -- ═══════════════════════════════════════════════════════════════════════

    -- Director Escolar
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Director Escolar',
            'Acesso total ao módulo escolar. Homologa pautas, gere configurações.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
    SELECT v_id, 'gestao-escolar', a.acao
    FROM (VALUES
        ('ver'),('criar'),('editar'),('apagar'),('exportar'),('aprovar'),('configurar'),('relatorios'),
        ('gerir_alunos'),('gerir_turmas'),('lancar_notas'),('gerir_presencas'),
        ('gerir_horarios'),('gerir_calendario'),('gerir_biblioteca'),('gerir_propinas'),
        ('gerir_ocorrencias'),('gerir_matriculas'),('gerir_comunicacao'),('portal_aluno')
    ) AS a(acao)
    ON CONFLICT DO NOTHING;

    -- ───────────────────────────────────────────────────────────────────────

    -- Director Adjunto Pedagógico
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Director Adjunto Pedagógico',
            'Supervisão pedagógica e aprovação de planos lectivos.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'gestao-escolar', 'ver'),
        (v_id, 'gestao-escolar', 'gerir_turmas'),
        (v_id, 'gestao-escolar', 'gerir_horarios'),
        (v_id, 'gestao-escolar', 'gerir_calendario'),
        (v_id, 'gestao-escolar', 'gerir_presencas'),
        (v_id, 'gestao-escolar', 'gerir_ocorrencias'),
        (v_id, 'gestao-escolar', 'gerir_comunicacao'),
        (v_id, 'gestao-escolar', 'relatorios')
    ON CONFLICT DO NOTHING;

    -- ───────────────────────────────────────────────────────────────────────

    -- Secretário Escolar
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Secretário Escolar',
            'Matrículas, propinas, documentação.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'gestao-escolar', 'ver'),
        (v_id, 'gestao-escolar', 'gerir_alunos'),
        (v_id, 'gestao-escolar', 'gerir_matriculas'),
        (v_id, 'gestao-escolar', 'gerir_propinas'),
        (v_id, 'gestao-escolar', 'relatorios'),
        (v_id, 'faturacao',      'ver')
    ON CONFLICT DO NOTHING;

    -- ───────────────────────────────────────────────────────────────────────

    -- Bibliotecário
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Bibliotecário',
            'Gestão de acervo e empréstimos.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'gestao-escolar', 'ver'),
        (v_id, 'gestao-escolar', 'gerir_biblioteca')
    ON CONFLICT DO NOTHING;

    -- ───────────────────────────────────────────────────────────────────────

    -- Professor
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Professor',
            'Notas e presenças das suas disciplinas/turmas.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'gestao-escolar', 'ver'),
        (v_id, 'gestao-escolar', 'lancar_notas'),
        (v_id, 'gestao-escolar', 'gerir_presencas')
    ON CONFLICT DO NOTHING;

    -- ───────────────────────────────────────────────────────────────────────

    -- Director de Turma
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Director de Turma',
            'Notas e presenças + brigada de turma e comunicação com EE.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'gestao-escolar', 'ver'),
        (v_id, 'gestao-escolar', 'lancar_notas'),
        (v_id, 'gestao-escolar', 'gerir_presencas'),
        (v_id, 'gestao-escolar', 'gerir_ocorrencias')
    ON CONFLICT DO NOTHING;

    -- ───────────────────────────────────────────────────────────────────────

    -- Coordenador de Disciplina
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Coordenador de Disciplina',
            'Coordena o grupo de professores da disciplina.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'gestao-escolar', 'ver'),
        (v_id, 'gestao-escolar', 'lancar_notas'),
        (v_id, 'gestao-escolar', 'gerir_presencas'),
        (v_id, 'gestao-escolar', 'relatorios')
    ON CONFLICT DO NOTHING;

    -- ───────────────────────────────────────────────────────────────────────

    -- Coordenador de Ciclo
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Coordenador de Ciclo',
            'Supervisiona um ciclo (EP1, ESG1, etc.).')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'gestao-escolar', 'ver'),
        (v_id, 'gestao-escolar', 'relatorios'),
        (v_id, 'gestao-escolar', 'gerir_ocorrencias')
    ON CONFLICT DO NOTHING;

    -- ───────────────────────────────────────────────────────────────────────

    -- Chefe de Oficina / Laboratório
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Chefe de Oficina',
            'Componente prática do ensino técnico-profissional (ETP).')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'gestao-escolar', 'ver'),
        (v_id, 'gestao-escolar', 'lancar_notas'),
        (v_id, 'gestao-escolar', 'gerir_presencas')
    ON CONFLICT DO NOTHING;

END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- Aplicar cargos ao tenant existente (tenant_id = 1) se ainda não tiver
-- ─────────────────────────────────────────────────────────────────────────────
SELECT auth.criar_cargos_padrao(t.id)
  FROM saas.tenants t
 WHERE NOT EXISTS (
     SELECT 1 FROM auth.cargos c
      WHERE c.tenant_id = t.id AND c.nome = 'Administrador'
 );
