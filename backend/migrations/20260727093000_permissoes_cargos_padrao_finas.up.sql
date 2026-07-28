-- Corrige desalinhamento entre as permissões que o router.go realmente verifica
-- (ações finas como ver_funcionarios, gerir_movimentos, emitir_faturas) e as
-- ações genéricas (ver, criar, editar, apagar) que a migration anterior
-- 20260727000002_cargos_padrao_restore inseria nos cargos padrão.
--
-- Faz duas coisas idempotentes:
-- 1. Recria auth.criar_cargos_padrao() para que novos tenants recebam as
--    ações finas correctas.
-- 2. Faz backfill nos tenants existentes: converte ações genéricas em finas
--    e adiciona permissões de módulos recentes (tarefas, hardware,
--    assinatura-digital, notificacoes, perfil, etc.).

SET search_path TO auth, public;

-- ═════════════════════════════════════════════════════════════════════════════
-- 1. RECRIAR auth.criar_cargos_padrao() COM AÇÕES FINAS
-- ═════════════════════════════════════════════════════════════════════════════

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

    -- Administrador — todas as acções finas de todos os módulos
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Administrador',
            'Acesso total ao tenant. Gere utilizadores, cargos e configurações.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_id;

    -- Sistema / autorização / segurança
    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'auth', 'pin_admin'),
        (v_id, 'autorizacao', 'gerir_utilizadores'),
        (v_id, 'autorizacao', 'gerir_perfis'),
        (v_id, 'perfil', 'ver_perfil'),
        (v_id, 'perfil', 'editar_perfil'),
        (v_id, 'chat', 'ver_conversas'),
        (v_id, 'chat', 'enviar_mensagem'),
        (v_id, 'empresa', 'ver_empresa'),
        (v_id, 'empresa', 'editar_empresa'),
        (v_id, 'empresa', 'gerir_filiais'),
        (v_id, 'empresa', 'gerir_licencas'),
        (v_id, 'auditoria', 'ver_logs'),
        (v_id, 'auditoria', 'gerir_logs'),
        (v_id, 'sistema-configuracao', 'ver_configuracoes'),
        (v_id, 'sistema-configuracao', 'editar_configuracoes'),
        (v_id, 'sistema-configuracao', 'gerir_templates'),
        (v_id, 'seguranca', 'ver_seguranca'),
        (v_id, 'seguranca', 'gerir_politicas'),
        (v_id, 'seguranca', 'gerir_allowlist')
    ON CONFLICT DO NOTHING;

    -- Vendas / clientes / CRM / faturação / POS
    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'clientes', 'ver_clientes'),
        (v_id, 'clientes', 'gerir_clientes'),
        (v_id, 'clientes', 'eliminar_clientes'),
        (v_id, 'clientes', 'gerir_grupos'),
        (v_id, 'clientes', 'gerir_credito'),
        (v_id, 'vendas', 'ver'),
        (v_id, 'vendas', 'criar'),
        (v_id, 'vendas', 'editar'),
        (v_id, 'vendas', 'apagar'),
        (v_id, 'faturacao', 'ver_documentos'),
        (v_id, 'faturacao', 'configurar_series'),
        (v_id, 'faturacao', 'emitir_orcamentos'),
        (v_id, 'faturacao', 'emitir_encomendas'),
        (v_id, 'faturacao', 'emitir_faturas'),
        (v_id, 'faturacao', 'emitir_notas_credito'),
        (v_id, 'pos', 'operar_pos'),
        (v_id, 'pos', 'ver_vendas'),
        (v_id, 'pos', 'gerir_terminais'),
        (v_id, 'pos', 'gerir_catalogo'),
        (v_id, 'pos', 'gerir_descontos'),
        (v_id, 'crm', 'ver_leads'),
        (v_id, 'crm', 'gerir_leads'),
        (v_id, 'crm', 'mover_leads'),
        (v_id, 'crm', 'converter_leads'),
        (v_id, 'crm', 'eliminar_leads'),
        (v_id, 'crm', 'ver_oportunidades'),
        (v_id, 'crm', 'gerir_oportunidades'),
        (v_id, 'crm', 'gerir_atividades')
    ON CONFLICT DO NOTHING;

    -- Stock / compras / logística
    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'stock', 'ver_stock'),
        (v_id, 'stock', 'gerir_produtos'),
        (v_id, 'stock', 'gerir_categorias'),
        (v_id, 'stock', 'eliminar_produtos'),
        (v_id, 'stock', 'gerir_movimentos'),
        (v_id, 'compras', 'ver_compras'),
        (v_id, 'compras', 'criar_pedidos'),
        (v_id, 'compras', 'aprovar_pedidos'),
        (v_id, 'logistica', 'ver_logistica'),
        (v_id, 'logistica', 'gerir_entregas')
    ON CONFLICT DO NOTHING;

    -- Financeiro / contabilidade / tesouraria / impostos / centros de custo / multi-moeda
    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'financeiro', 'ver_financeiro'),
        (v_id, 'financeiro', 'gerir_categorias'),
        (v_id, 'financeiro', 'gerir_contas_receber'),
        (v_id, 'financeiro', 'gerir_contas_pagar'),
        (v_id, 'tesouraria', 'ver_tesouraria'),
        (v_id, 'tesouraria', 'gerir_movimentos'),
        (v_id, 'tesouraria', 'gerir_reconciliacao'),
        (v_id, 'contabilidade', 'ver_contabilidade'),
        (v_id, 'contabilidade', 'gerir_plano_contas'),
        (v_id, 'contabilidade', 'gerir_lancamentos'),
        (v_id, 'contabilidade', 'gerir_periodos'),
        (v_id, 'contabilidade', 'gerir_ativos_fixos'),
        (v_id, 'contabilidade', 'gerir_orcamentos'),
        (v_id, 'contabilidade', 'fechar_periodo'),
        (v_id, 'contabilidade', 'ver_relatorios'),
        (v_id, 'impostos', 'ver_impostos'),
        (v_id, 'impostos', 'gerir_impostos'),
        (v_id, 'centros-custo', 'ver_centros'),
        (v_id, 'centros-custo', 'gerir_centros'),
        (v_id, 'centros-custo', 'eliminar_centros'),
        (v_id, 'multi-moeda', 'ver_moedas'),
        (v_id, 'multi-moeda', 'gerir_moedas')
    ON CONFLICT DO NOTHING;

    -- RH / assiduidade / férias / recrutamento
    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'recursos-humanos', 'ver_funcionarios'),
        (v_id, 'recursos-humanos', 'gerir_funcionarios'),
        (v_id, 'recursos-humanos', 'gerir_contratos'),
        (v_id, 'recursos-humanos', 'aprovar_ausencias'),
        (v_id, 'recursos-humanos', 'processar_salarios'),
        (v_id, 'recursos-humanos', 'ver_salarios'),
        (v_id, 'recursos-humanos', 'ver_recibos'),
        (v_id, 'recursos-humanos', 'gerir_beneficios'),
        (v_id, 'recursos-humanos', 'ver_beneficios'),
        (v_id, 'recursos-humanos', 'gerir_formacoes'),
        (v_id, 'recursos-humanos', 'gerir_avaliacoes'),
        (v_id, 'recursos-humanos', 'gerir_horarios'),
        (v_id, 'recursos-humanos', 'ver_processos_disciplinares'),
        (v_id, 'recursos-humanos', 'ver_relatorios'),
        (v_id, 'assiduidade', 'ver_configuracao'),
        (v_id, 'assiduidade', 'gerir_configuracao'),
        (v_id, 'assiduidade', 'aprovar_correcao'),
        (v_id, 'pedido-ferias', 'ver_pedidos'),
        (v_id, 'pedido-ferias', 'submeter_pedido'),
        (v_id, 'pedido-ferias', 'aprovar'),
        (v_id, 'recrutamento', 'ver_vagas'),
        (v_id, 'recrutamento', 'gerir_vagas'),
        (v_id, 'recrutamento', 'ver_candidaturas'),
        (v_id, 'recrutamento', 'gerir_candidaturas'),
        (v_id, 'recrutamento', 'contratar'),
        (v_id, 'recrutamento', 'configurar_recrutamento')
    ON CONFLICT DO NOTHING;

    -- Escolar
    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'gestao-escolar', 'ver'),
        (v_id, 'gestao-escolar', 'relatorios'),
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
        (v_id, 'gestao-escolar', 'gerir_comunicacao'),
        (v_id, 'gestao-escolar', 'portal_aluno')
    ON CONFLICT DO NOTHING;

    -- Outros módulos recentes
    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'assinaturas', 'ver_assinaturas'),
        (v_id, 'assinaturas', 'gerir_assinaturas'),
        (v_id, 'assinatura-digital', 'ver_documentos'),
        (v_id, 'assinatura-digital', 'gerir_documentos'),
        (v_id, 'assinatura-digital', 'assinar_documentos'),
        (v_id, 'notificacoes', 'ver_notificacoes'),
        (v_id, 'notificacoes', 'gerir_notificacoes'),
        (v_id, 'hardware', 'ver_dispositivos'),
        (v_id, 'hardware', 'gerir_dispositivos'),
        (v_id, 'hardware', 'ver_eventos'),
        (v_id, 'tarefas', 'ver_quadros'),
        (v_id, 'tarefas', 'gerir_quadros'),
        (v_id, 'tarefas', 'gerir_listas'),
        (v_id, 'tarefas', 'gerir_cartoes'),
        (v_id, 'tarefas', 'mover_cartoes'),
        (v_id, 'tarefas', 'eliminar_cartoes')
    ON CONFLICT DO NOTHING;

    -- ───────────────────────────────────────────────────────────────────────

    -- Gestor de TI
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Gestor de TI',
            'Gestão técnica, integrações e segurança.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'auth', 'pin_admin'),
        (v_id, 'autorizacao', 'gerir_utilizadores'),
        (v_id, 'autorizacao', 'gerir_perfis'),
        (v_id, 'sistema-configuracao', 'ver_configuracoes'),
        (v_id, 'sistema-configuracao', 'editar_configuracoes'),
        (v_id, 'sistema-configuracao', 'gerir_templates'),
        (v_id, 'auditoria', 'ver_logs'),
        (v_id, 'auditoria', 'gerir_logs'),
        (v_id, 'seguranca', 'ver_seguranca'),
        (v_id, 'seguranca', 'gerir_politicas'),
        (v_id, 'seguranca', 'gerir_allowlist'),
        (v_id, 'notificacoes', 'ver_notificacoes'),
        (v_id, 'notificacoes', 'gerir_notificacoes'),
        (v_id, 'hardware', 'ver_dispositivos'),
        (v_id, 'hardware', 'gerir_dispositivos'),
        (v_id, 'hardware', 'ver_eventos')
    ON CONFLICT DO NOTHING;

    -- ───────────────────────────────────────────────────────────────────────

    -- Auditor Interno
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Auditor Interno',
            'Acesso de leitura para fins de auditoria.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'auditoria', 'ver_logs'),
        (v_id, 'auditoria', 'gerir_logs'),
        (v_id, 'financeiro', 'ver_financeiro'),
        (v_id, 'contabilidade', 'ver_contabilidade'),
        (v_id, 'tesouraria', 'ver_tesouraria'),
        (v_id, 'impostos', 'ver_impostos'),
        (v_id, 'compras', 'ver_compras'),
        (v_id, 'centros-custo', 'ver_centros')
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

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'recursos-humanos', 'ver_funcionarios'),
        (v_id, 'recursos-humanos', 'gerir_funcionarios'),
        (v_id, 'recursos-humanos', 'gerir_contratos'),
        (v_id, 'recursos-humanos', 'aprovar_ausencias'),
        (v_id, 'recursos-humanos', 'processar_salarios'),
        (v_id, 'recursos-humanos', 'ver_salarios'),
        (v_id, 'recursos-humanos', 'ver_recibos'),
        (v_id, 'recursos-humanos', 'gerir_beneficios'),
        (v_id, 'recursos-humanos', 'ver_beneficios'),
        (v_id, 'recursos-humanos', 'gerir_formacoes'),
        (v_id, 'recursos-humanos', 'gerir_avaliacoes'),
        (v_id, 'recursos-humanos', 'gerir_horarios'),
        (v_id, 'recursos-humanos', 'ver_processos_disciplinares'),
        (v_id, 'recursos-humanos', 'ver_relatorios'),
        (v_id, 'assiduidade', 'ver_configuracao'),
        (v_id, 'assiduidade', 'gerir_configuracao'),
        (v_id, 'assiduidade', 'aprovar_correcao'),
        (v_id, 'pedido-ferias', 'ver_pedidos'),
        (v_id, 'pedido-ferias', 'submeter_pedido'),
        (v_id, 'pedido-ferias', 'aprovar')
    ON CONFLICT DO NOTHING;

    -- ───────────────────────────────────────────────────────────────────────

    -- Gestor de RH
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Gestor de RH',
            'Admissão, transferências, avaliações.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'recursos-humanos', 'ver_funcionarios'),
        (v_id, 'recursos-humanos', 'gerir_funcionarios'),
        (v_id, 'recursos-humanos', 'gerir_contratos'),
        (v_id, 'recursos-humanos', 'aprovar_ausencias'),
        (v_id, 'recursos-humanos', 'gerir_formacoes'),
        (v_id, 'recursos-humanos', 'gerir_avaliacoes'),
        (v_id, 'recursos-humanos', 'gerir_horarios'),
        (v_id, 'recursos-humanos', 'ver_relatorios'),
        (v_id, 'assiduidade', 'ver_configuracao'),
        (v_id, 'assiduidade', 'gerir_configuracao'),
        (v_id, 'assiduidade', 'aprovar_correcao'),
        (v_id, 'pedido-ferias', 'ver_pedidos'),
        (v_id, 'pedido-ferias', 'submeter_pedido'),
        (v_id, 'pedido-ferias', 'aprovar')
    ON CONFLICT DO NOTHING;

    -- ───────────────────────────────────────────────────────────────────────

    -- Técnico de Processamento Salarial
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Técnico de Processamento Salarial',
            'Folha de salários, componentes salariais, benefícios.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'recursos-humanos', 'ver_funcionarios'),
        (v_id, 'recursos-humanos', 'ver_salarios'),
        (v_id, 'recursos-humanos', 'ver_recibos'),
        (v_id, 'recursos-humanos', 'processar_salarios'),
        (v_id, 'recursos-humanos', 'gerir_beneficios'),
        (v_id, 'recursos-humanos', 'ver_beneficios'),
        (v_id, 'contabilidade', 'ver_contabilidade')
    ON CONFLICT DO NOTHING;

    -- ───────────────────────────────────────────────────────────────────────

    -- Técnico de RH
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Técnico de RH',
            'Fichas de funcionários, formações, documentação.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'recursos-humanos', 'ver_funcionarios'),
        (v_id, 'recursos-humanos', 'gerir_funcionarios'),
        (v_id, 'recursos-humanos', 'gerir_formacoes'),
        (v_id, 'recursos-humanos', 'gerir_horarios'),
        (v_id, 'assiduidade', 'ver_configuracao'),
        (v_id, 'pedido-ferias', 'ver_pedidos'),
        (v_id, 'pedido-ferias', 'submeter_pedido')
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

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'recrutamento', 'ver_vagas'),
        (v_id, 'recrutamento', 'gerir_vagas'),
        (v_id, 'recrutamento', 'ver_candidaturas'),
        (v_id, 'recrutamento', 'gerir_candidaturas'),
        (v_id, 'recrutamento', 'contratar'),
        (v_id, 'recrutamento', 'configurar_recrutamento'),
        (v_id, 'recursos-humanos', 'ver_funcionarios')
    ON CONFLICT DO NOTHING;

    -- ───────────────────────────────────────────────────────────────────────

    -- Recrutador
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Recrutador',
            'Publica vagas, triagem e gestão de candidaturas.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'recrutamento', 'ver_vagas'),
        (v_id, 'recrutamento', 'gerir_vagas'),
        (v_id, 'recrutamento', 'ver_candidaturas'),
        (v_id, 'recrutamento', 'gerir_candidaturas')
    ON CONFLICT DO NOTHING;

    -- ───────────────────────────────────────────────────────────────────────

    -- Responsável de Entrevistas
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Responsável de Entrevistas',
            'Avalia candidatos e regista feedback de entrevistas.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'recrutamento', 'ver_vagas'),
        (v_id, 'recrutamento', 'ver_candidaturas')
    ON CONFLICT DO NOTHING;

    -- ═══════════════════════════════════════════════════════════════════════
    -- 4.4  GESTÃO DE CLIENTES / CRM
    -- ═══════════════════════════════════════════════════════════════════════

    -- Director Comercial
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Director Comercial',
            'Visão global, aprovação de descontos e contratos.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'clientes', 'ver_clientes'),
        (v_id, 'clientes', 'gerir_clientes'),
        (v_id, 'clientes', 'eliminar_clientes'),
        (v_id, 'clientes', 'gerir_grupos'),
        (v_id, 'clientes', 'gerir_credito'),
        (v_id, 'vendas', 'ver'),
        (v_id, 'vendas', 'criar'),
        (v_id, 'vendas', 'editar'),
        (v_id, 'vendas', 'apagar'),
        (v_id, 'crm', 'ver_leads'),
        (v_id, 'crm', 'gerir_leads'),
        (v_id, 'crm', 'mover_leads'),
        (v_id, 'crm', 'converter_leads'),
        (v_id, 'crm', 'eliminar_leads'),
        (v_id, 'crm', 'ver_oportunidades'),
        (v_id, 'crm', 'gerir_oportunidades'),
        (v_id, 'crm', 'gerir_atividades'),
        (v_id, 'faturacao', 'ver_documentos'),
        (v_id, 'faturacao', 'relatorios')
    ON CONFLICT DO NOTHING;

    -- ───────────────────────────────────────────────────────────────────────

    -- Gestor de Conta
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Gestor de Conta',
            'Carteira de clientes e oportunidades.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'clientes', 'ver_clientes'),
        (v_id, 'clientes', 'gerir_clientes'),
        (v_id, 'clientes', 'gerir_grupos'),
        (v_id, 'vendas', 'ver'),
        (v_id, 'vendas', 'criar'),
        (v_id, 'vendas', 'editar'),
        (v_id, 'crm', 'ver_leads'),
        (v_id, 'crm', 'gerir_leads'),
        (v_id, 'crm', 'mover_leads'),
        (v_id, 'crm', 'converter_leads'),
        (v_id, 'crm', 'eliminar_leads'),
        (v_id, 'crm', 'ver_oportunidades'),
        (v_id, 'crm', 'gerir_oportunidades'),
        (v_id, 'crm', 'gerir_atividades'),
        (v_id, 'faturacao', 'ver_documentos')
    ON CONFLICT DO NOTHING;

    -- ───────────────────────────────────────────────────────────────────────

    -- Técnico Comercial
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Técnico Comercial',
            'Orçamentos e seguimento de oportunidades.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'clientes', 'ver_clientes'),
        (v_id, 'vendas', 'ver'),
        (v_id, 'vendas', 'criar'),
        (v_id, 'crm', 'ver_leads'),
        (v_id, 'crm', 'gerir_leads'),
        (v_id, 'crm', 'ver_oportunidades'),
        (v_id, 'crm', 'gerir_oportunidades'),
        (v_id, 'crm', 'gerir_atividades'),
        (v_id, 'faturacao', 'ver_documentos')
    ON CONFLICT DO NOTHING;

    -- ───────────────────────────────────────────────────────────────────────

    -- Assistente Administrativo
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Assistente Administrativo',
            'Registo de clientes e consulta de faturas.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'clientes', 'ver_clientes'),
        (v_id, 'clientes', 'gerir_clientes'),
        (v_id, 'clientes', 'gerir_grupos'),
        (v_id, 'faturacao', 'ver_documentos')
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

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'financeiro', 'ver_financeiro'),
        (v_id, 'financeiro', 'gerir_categorias'),
        (v_id, 'financeiro', 'gerir_contas_receber'),
        (v_id, 'financeiro', 'gerir_contas_pagar'),
        (v_id, 'contabilidade', 'ver_contabilidade'),
        (v_id, 'contabilidade', 'gerir_plano_contas'),
        (v_id, 'contabilidade', 'gerir_lancamentos'),
        (v_id, 'contabilidade', 'gerir_periodos'),
        (v_id, 'contabilidade', 'gerir_ativos_fixos'),
        (v_id, 'contabilidade', 'gerir_orcamentos'),
        (v_id, 'contabilidade', 'fechar_periodo'),
        (v_id, 'contabilidade', 'ver_relatorios'),
        (v_id, 'tesouraria', 'ver_tesouraria'),
        (v_id, 'tesouraria', 'gerir_movimentos'),
        (v_id, 'tesouraria', 'gerir_reconciliacao'),
        (v_id, 'impostos', 'ver_impostos'),
        (v_id, 'impostos', 'gerir_impostos'),
        (v_id, 'faturacao', 'ver_documentos'),
        (v_id, 'faturacao', 'configurar_series'),
        (v_id, 'faturacao', 'emitir_orcamentos'),
        (v_id, 'faturacao', 'emitir_encomendas'),
        (v_id, 'faturacao', 'emitir_faturas'),
        (v_id, 'faturacao', 'emitir_notas_credito'),
        (v_id, 'centros-custo', 'ver_centros'),
        (v_id, 'centros-custo', 'gerir_centros'),
        (v_id, 'centros-custo', 'eliminar_centros'),
        (v_id, 'multi-moeda', 'ver_moedas'),
        (v_id, 'multi-moeda', 'gerir_moedas'),
        (v_id, 'auditoria', 'ver_logs')
    ON CONFLICT DO NOTHING;

    -- ───────────────────────────────────────────────────────────────────────

    -- Contabilista
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Contabilista',
            'Lançamentos contabilísticos, declarações fiscais.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'contabilidade', 'ver_contabilidade'),
        (v_id, 'contabilidade', 'gerir_plano_contas'),
        (v_id, 'contabilidade', 'gerir_lancamentos'),
        (v_id, 'contabilidade', 'gerir_periodos'),
        (v_id, 'contabilidade', 'gerir_ativos_fixos'),
        (v_id, 'contabilidade', 'gerir_orcamentos'),
        (v_id, 'contabilidade', 'fechar_periodo'),
        (v_id, 'contabilidade', 'ver_relatorios'),
        (v_id, 'impostos', 'ver_impostos'),
        (v_id, 'impostos', 'gerir_impostos'),
        (v_id, 'financeiro', 'ver_financeiro'),
        (v_id, 'centros-custo', 'ver_centros')
    ON CONFLICT DO NOTHING;

    -- ───────────────────────────────────────────────────────────────────────

    -- Tesoureiro
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Tesoureiro',
            'Caixa, bancos, conciliação.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'tesouraria', 'ver_tesouraria'),
        (v_id, 'tesouraria', 'gerir_movimentos'),
        (v_id, 'tesouraria', 'gerir_reconciliacao'),
        (v_id, 'financeiro', 'ver_financeiro'),
        (v_id, 'financeiro', 'gerir_contas_receber'),
        (v_id, 'financeiro', 'gerir_contas_pagar'),
        (v_id, 'contabilidade', 'ver_contabilidade')
    ON CONFLICT DO NOTHING;

    -- ───────────────────────────────────────────────────────────────────────

    -- Caixa
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Caixa',
            'Operações de ponto de venda.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'pos', 'operar_pos'),
        (v_id, 'pos', 'ver_vendas'),
        (v_id, 'tesouraria', 'ver_tesouraria')
    ON CONFLICT DO NOTHING;

    -- ───────────────────────────────────────────────────────────────────────

    -- Responsável de Faturação
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Responsável de Faturação',
            'Emissão e gestão de faturas.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'faturacao', 'ver_documentos'),
        (v_id, 'faturacao', 'configurar_series'),
        (v_id, 'faturacao', 'emitir_orcamentos'),
        (v_id, 'faturacao', 'emitir_encomendas'),
        (v_id, 'faturacao', 'emitir_faturas'),
        (v_id, 'faturacao', 'emitir_notas_credito'),
        (v_id, 'clientes', 'ver_clientes'),
        (v_id, 'clientes', 'gerir_clientes')
    ON CONFLICT DO NOTHING;

    -- ───────────────────────────────────────────────────────────────────────

    -- Analista Financeiro
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Analista Financeiro',
            'Análise financeira e reporting.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET nome = EXCLUDED.nome
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'financeiro', 'ver_financeiro'),
        (v_id, 'financeiro', 'gerir_categorias'),
        (v_id, 'contabilidade', 'ver_contabilidade'),
        (v_id, 'contabilidade', 'ver_relatorios'),
        (v_id, 'centros-custo', 'ver_centros'),
        (v_id, 'impostos', 'ver_impostos')
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

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'gestao-escolar', 'ver'),
        (v_id, 'gestao-escolar', 'relatorios'),
        (v_id, 'gestao-escolar', 'gerir_alunos'),
        (v_id, 'gestao-escolar', 'gerir_turmas'),
        (v_id, 'gestao-escolar', 'lancar_notas'),
        (v_id, 'gestao-escolar', 'gerir_presencas'),
        (v_id, 'gestao-escolar', 'gerir_horarios'),
        (v_id, 'gestao-escolar', 'gerir_calendario'),
        (v_id, 'gestao-escolar', 'gerir_biblioteca'),
        (v_id, 'gestao-escolar', 'gerir_propinas'),
        (v_id, 'gestao-escolar', 'gerir_ocorrencias'),
        (v_id, 'gestao-escolar', 'gerir_matriculas'),
        (v_id, 'gestao-escolar', 'gerir_comunicacao'),
        (v_id, 'gestao-escolar', 'portal_aluno')
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
        (v_id, 'faturacao', 'ver_documentos')
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
            'Acompanha pedagogicamente a turma, consulta relatórios e comunica com encarregados.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET descricao = EXCLUDED.descricao
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'gestao-escolar', 'ver'),
        (v_id, 'gestao-escolar', 'relatorios'),
        (v_id, 'gestao-escolar', 'lancar_notas'),
        (v_id, 'gestao-escolar', 'gerir_presencas'),
        (v_id, 'gestao-escolar', 'gerir_ocorrencias'),
        (v_id, 'gestao-escolar', 'gerir_comunicacao')
    ON CONFLICT DO NOTHING;

    -- ───────────────────────────────────────────────────────────────────────

    -- Chefe de Turma
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Chefe de Turma',
            'Apoia a comunicação e organização da turma.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET descricao = EXCLUDED.descricao
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'gestao-escolar', 'ver'),
        (v_id, 'gestao-escolar', 'gerir_comunicacao')
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

-- ═════════════════════════════════════════════════════════════════════════════
-- 2. BACKFILL IDEMPOTENTE NOS TENANTS EXISTENTES
-- ═════════════════════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────────────────────────────────────
-- 2.1 Converter acções genéricas em finas para módulos que ainda usam
--     o esquema antigo. Mantém acções já finas intactas.
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
DECLARE
    v_rec RECORD;
BEGIN
    FOR v_rec IN
        SELECT c.id AS cargo_id, c.tenant_id, c.nome
          FROM auth.cargos c
         WHERE c.nome IN (
             'Administrador','Gestor de TI','Auditor Interno',
             'Director de RH','Gestor de RH','Técnico de Processamento Salarial','Técnico de RH',
             'Gestor de Recrutamento','Recrutador','Responsável de Entrevistas',
             'Director Comercial','Gestor de Conta','Técnico Comercial','Assistente Administrativo',
             'Director Financeiro','Contabilista','Tesoureiro','Caixa','Responsável de Faturação','Analista Financeiro',
             'Director Escolar','Director Adjunto Pedagógico','Secretário Escolar','Bibliotecário','Professor',
             'Director de Turma','Chefe de Turma','Coordenador de Disciplina','Coordenador de Ciclo','Chefe de Oficina'
         )
    LOOP
        -- Administrador: garantir todas as acções finas (idempotente)
        IF v_rec.nome = 'Administrador' THEN
            INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
                (v_rec.cargo_id, 'auth', 'pin_admin'),
                (v_rec.cargo_id, 'autorizacao', 'gerir_utilizadores'),
                (v_rec.cargo_id, 'autorizacao', 'gerir_perfis'),
                (v_rec.cargo_id, 'perfil', 'ver_perfil'),
                (v_rec.cargo_id, 'perfil', 'editar_perfil'),
                (v_rec.cargo_id, 'chat', 'ver_conversas'),
                (v_rec.cargo_id, 'chat', 'enviar_mensagem'),
                (v_rec.cargo_id, 'empresa', 'ver_empresa'),
                (v_rec.cargo_id, 'empresa', 'editar_empresa'),
                (v_rec.cargo_id, 'empresa', 'gerir_filiais'),
                (v_rec.cargo_id, 'empresa', 'gerir_licencas'),
                (v_rec.cargo_id, 'auditoria', 'ver_logs'),
                (v_rec.cargo_id, 'auditoria', 'gerir_logs'),
                (v_rec.cargo_id, 'sistema-configuracao', 'ver_configuracoes'),
                (v_rec.cargo_id, 'sistema-configuracao', 'editar_configuracoes'),
                (v_rec.cargo_id, 'sistema-configuracao', 'gerir_templates'),
                (v_rec.cargo_id, 'seguranca', 'ver_seguranca'),
                (v_rec.cargo_id, 'seguranca', 'gerir_politicas'),
                (v_rec.cargo_id, 'seguranca', 'gerir_allowlist'),
                (v_rec.cargo_id, 'clientes', 'ver_clientes'),
                (v_rec.cargo_id, 'clientes', 'gerir_clientes'),
                (v_rec.cargo_id, 'clientes', 'eliminar_clientes'),
                (v_rec.cargo_id, 'clientes', 'gerir_grupos'),
                (v_rec.cargo_id, 'clientes', 'gerir_credito'),
                (v_rec.cargo_id, 'faturacao', 'ver_documentos'),
                (v_rec.cargo_id, 'faturacao', 'configurar_series'),
                (v_rec.cargo_id, 'faturacao', 'emitir_orcamentos'),
                (v_rec.cargo_id, 'faturacao', 'emitir_encomendas'),
                (v_rec.cargo_id, 'faturacao', 'emitir_faturas'),
                (v_rec.cargo_id, 'faturacao', 'emitir_notas_credito'),
                (v_rec.cargo_id, 'pos', 'operar_pos'),
                (v_rec.cargo_id, 'pos', 'ver_vendas'),
                (v_rec.cargo_id, 'pos', 'gerir_terminais'),
                (v_rec.cargo_id, 'pos', 'gerir_catalogo'),
                (v_rec.cargo_id, 'pos', 'gerir_descontos'),
                (v_rec.cargo_id, 'crm', 'ver_leads'),
                (v_rec.cargo_id, 'crm', 'gerir_leads'),
                (v_rec.cargo_id, 'crm', 'mover_leads'),
                (v_rec.cargo_id, 'crm', 'converter_leads'),
                (v_rec.cargo_id, 'crm', 'eliminar_leads'),
                (v_rec.cargo_id, 'crm', 'ver_oportunidades'),
                (v_rec.cargo_id, 'crm', 'gerir_oportunidades'),
                (v_rec.cargo_id, 'crm', 'gerir_atividades'),
                (v_rec.cargo_id, 'stock', 'ver_stock'),
                (v_rec.cargo_id, 'stock', 'gerir_produtos'),
                (v_rec.cargo_id, 'stock', 'gerir_categorias'),
                (v_rec.cargo_id, 'stock', 'eliminar_produtos'),
                (v_rec.cargo_id, 'stock', 'gerir_movimentos'),
                (v_rec.cargo_id, 'compras', 'ver_compras'),
                (v_rec.cargo_id, 'compras', 'criar_pedidos'),
                (v_rec.cargo_id, 'compras', 'aprovar_pedidos'),
                (v_rec.cargo_id, 'logistica', 'ver_logistica'),
                (v_rec.cargo_id, 'logistica', 'gerir_entregas'),
                (v_rec.cargo_id, 'financeiro', 'ver_financeiro'),
                (v_rec.cargo_id, 'financeiro', 'gerir_categorias'),
                (v_rec.cargo_id, 'financeiro', 'gerir_contas_receber'),
                (v_rec.cargo_id, 'financeiro', 'gerir_contas_pagar'),
                (v_rec.cargo_id, 'tesouraria', 'ver_tesouraria'),
                (v_rec.cargo_id, 'tesouraria', 'gerir_movimentos'),
                (v_rec.cargo_id, 'tesouraria', 'gerir_reconciliacao'),
                (v_rec.cargo_id, 'contabilidade', 'ver_contabilidade'),
                (v_rec.cargo_id, 'contabilidade', 'gerir_plano_contas'),
                (v_rec.cargo_id, 'contabilidade', 'gerir_lancamentos'),
                (v_rec.cargo_id, 'contabilidade', 'gerir_periodos'),
                (v_rec.cargo_id, 'contabilidade', 'gerir_ativos_fixos'),
                (v_rec.cargo_id, 'contabilidade', 'gerir_orcamentos'),
                (v_rec.cargo_id, 'contabilidade', 'fechar_periodo'),
                (v_rec.cargo_id, 'contabilidade', 'ver_relatorios'),
                (v_rec.cargo_id, 'impostos', 'ver_impostos'),
                (v_rec.cargo_id, 'impostos', 'gerir_impostos'),
                (v_rec.cargo_id, 'centros-custo', 'ver_centros'),
                (v_rec.cargo_id, 'centros-custo', 'gerir_centros'),
                (v_rec.cargo_id, 'centros-custo', 'eliminar_centros'),
                (v_rec.cargo_id, 'multi-moeda', 'ver_moedas'),
                (v_rec.cargo_id, 'multi-moeda', 'gerir_moedas'),
                (v_rec.cargo_id, 'recursos-humanos', 'ver_funcionarios'),
                (v_rec.cargo_id, 'recursos-humanos', 'gerir_funcionarios'),
                (v_rec.cargo_id, 'recursos-humanos', 'gerir_contratos'),
                (v_rec.cargo_id, 'recursos-humanos', 'aprovar_ausencias'),
                (v_rec.cargo_id, 'recursos-humanos', 'processar_salarios'),
                (v_rec.cargo_id, 'recursos-humanos', 'ver_salarios'),
                (v_rec.cargo_id, 'recursos-humanos', 'ver_recibos'),
                (v_rec.cargo_id, 'recursos-humanos', 'gerir_beneficios'),
                (v_rec.cargo_id, 'recursos-humanos', 'ver_beneficios'),
                (v_rec.cargo_id, 'recursos-humanos', 'gerir_formacoes'),
                (v_rec.cargo_id, 'recursos-humanos', 'gerir_avaliacoes'),
                (v_rec.cargo_id, 'recursos-humanos', 'gerir_horarios'),
                (v_rec.cargo_id, 'recursos-humanos', 'ver_processos_disciplinares'),
                (v_rec.cargo_id, 'recursos-humanos', 'ver_relatorios'),
                (v_rec.cargo_id, 'assiduidade', 'ver_configuracao'),
                (v_rec.cargo_id, 'assiduidade', 'gerir_configuracao'),
                (v_rec.cargo_id, 'assiduidade', 'aprovar_correcao'),
                (v_rec.cargo_id, 'pedido-ferias', 'ver_pedidos'),
                (v_rec.cargo_id, 'pedido-ferias', 'submeter_pedido'),
                (v_rec.cargo_id, 'pedido-ferias', 'aprovar'),
                (v_rec.cargo_id, 'recrutamento', 'ver_vagas'),
                (v_rec.cargo_id, 'recrutamento', 'gerir_vagas'),
                (v_rec.cargo_id, 'recrutamento', 'ver_candidaturas'),
                (v_rec.cargo_id, 'recrutamento', 'gerir_candidaturas'),
                (v_rec.cargo_id, 'recrutamento', 'contratar'),
                (v_rec.cargo_id, 'recrutamento', 'configurar_recrutamento'),
                (v_rec.cargo_id, 'gestao-escolar', 'ver'),
                (v_rec.cargo_id, 'gestao-escolar', 'relatorios'),
                (v_rec.cargo_id, 'gestao-escolar', 'gerir_alunos'),
                (v_rec.cargo_id, 'gestao-escolar', 'gerir_turmas'),
                (v_rec.cargo_id, 'gestao-escolar', 'lancar_notas'),
                (v_rec.cargo_id, 'gestao-escolar', 'gerir_presencas'),
                (v_rec.cargo_id, 'gestao-escolar', 'gerir_horarios'),
                (v_rec.cargo_id, 'gestao-escolar', 'gerir_calendario'),
                (v_rec.cargo_id, 'gestao-escolar', 'gerir_biblioteca'),
                (v_rec.cargo_id, 'gestao-escolar', 'gerir_propinas'),
                (v_rec.cargo_id, 'gestao-escolar', 'gerir_ocorrencias'),
                (v_rec.cargo_id, 'gestao-escolar', 'gerir_matriculas'),
                (v_rec.cargo_id, 'gestao-escolar', 'gerir_comunicacao'),
                (v_rec.cargo_id, 'gestao-escolar', 'portal_aluno'),
                (v_rec.cargo_id, 'assinaturas', 'ver_assinaturas'),
                (v_rec.cargo_id, 'assinaturas', 'gerir_assinaturas'),
                (v_rec.cargo_id, 'assinatura-digital', 'ver_documentos'),
                (v_rec.cargo_id, 'assinatura-digital', 'gerir_documentos'),
                (v_rec.cargo_id, 'assinatura-digital', 'assinar_documentos'),
                (v_rec.cargo_id, 'notificacoes', 'ver_notificacoes'),
                (v_rec.cargo_id, 'notificacoes', 'gerir_notificacoes'),
                (v_rec.cargo_id, 'hardware', 'ver_dispositivos'),
                (v_rec.cargo_id, 'hardware', 'gerir_dispositivos'),
                (v_rec.cargo_id, 'hardware', 'ver_eventos'),
                (v_rec.cargo_id, 'tarefas', 'ver_quadros'),
                (v_rec.cargo_id, 'tarefas', 'gerir_quadros'),
                (v_rec.cargo_id, 'tarefas', 'gerir_listas'),
                (v_rec.cargo_id, 'tarefas', 'gerir_cartoes'),
                (v_rec.cargo_id, 'tarefas', 'mover_cartoes'),
                (v_rec.cargo_id, 'tarefas', 'eliminar_cartoes')
            ON CONFLICT DO NOTHING;
        END IF;

        -- Mapeamento de conversão genérico -> fino por módulo (todos os cargos)
        -- Compras
        INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
        SELECT v_rec.cargo_id, 'compras', novo.acao
        FROM auth.permissoes_cargo pc
        CROSS JOIN LATERAL (
            SELECT CASE pc.acao
                WHEN 'ver'     THEN 'ver_compras'
                WHEN 'criar'   THEN 'criar_pedidos'
                WHEN 'aprovar' THEN 'aprovar_pedidos'
            END AS acao
        ) AS novo
        WHERE pc.cargo_id = v_rec.cargo_id
          AND pc.modulo = 'compras'
          AND pc.acao IN ('ver','criar','aprovar')
          AND novo.acao IS NOT NULL
        ON CONFLICT DO NOTHING;

        -- Financeiro
        INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
        SELECT v_rec.cargo_id, 'financeiro', novo.acao
        FROM auth.permissoes_cargo pc
        CROSS JOIN LATERAL (
            SELECT CASE pc.acao
                WHEN 'ver'     THEN 'ver_financeiro'
                WHEN 'criar'   THEN 'gerir_categorias'
                WHEN 'editar'  THEN 'gerir_contas_receber'
                WHEN 'apagar'  THEN 'gerir_contas_pagar'
            END AS acao
        ) AS novo
        WHERE pc.cargo_id = v_rec.cargo_id
          AND pc.modulo = 'financeiro'
          AND pc.acao IN ('ver','criar','editar','apagar')
          AND novo.acao IS NOT NULL
        ON CONFLICT DO NOTHING;

        -- Tesouraria
        INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
        SELECT v_rec.cargo_id, 'tesouraria', novo.acao
        FROM auth.permissoes_cargo pc
        CROSS JOIN LATERAL (
            SELECT CASE pc.acao
                WHEN 'ver'     THEN 'ver_tesouraria'
                WHEN 'criar'   THEN 'gerir_movimentos'
                WHEN 'editar'  THEN 'gerir_reconciliacao'
            END AS acao
        ) AS novo
        WHERE pc.cargo_id = v_rec.cargo_id
          AND pc.modulo = 'tesouraria'
          AND pc.acao IN ('ver','criar','editar')
          AND novo.acao IS NOT NULL
        ON CONFLICT DO NOTHING;

        -- Contabilidade
        INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
        SELECT v_rec.cargo_id, 'contabilidade', novo.acao
        FROM auth.permissoes_cargo pc
        CROSS JOIN LATERAL (
            SELECT CASE pc.acao
                WHEN 'ver'        THEN 'ver_contabilidade'
                WHEN 'criar'      THEN 'gerir_plano_contas'
                WHEN 'editar'     THEN 'gerir_lancamentos'
                WHEN 'apagar'     THEN 'gerir_periodos'
                WHEN 'aprovar'    THEN 'gerir_ativos_fixos'
                WHEN 'configurar' THEN 'gerir_orcamentos'
                WHEN 'relatorios' THEN 'ver_relatorios'
            END AS acao
        ) AS novo
        WHERE pc.cargo_id = v_rec.cargo_id
          AND pc.modulo = 'contabilidade'
          AND pc.acao IN ('ver','criar','editar','apagar','aprovar','configurar','relatorios')
          AND novo.acao IS NOT NULL
        ON CONFLICT DO NOTHING;

        -- Impostos
        INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
        SELECT v_rec.cargo_id, 'impostos', novo.acao
        FROM auth.permissoes_cargo pc
        CROSS JOIN LATERAL (
            SELECT CASE pc.acao
                WHEN 'ver'        THEN 'ver_impostos'
                WHEN 'criar'      THEN 'gerir_impostos'
                WHEN 'relatorios' THEN 'ver_impostos'
            END AS acao
        ) AS novo
        WHERE pc.cargo_id = v_rec.cargo_id
          AND pc.modulo = 'impostos'
          AND pc.acao IN ('ver','criar','relatorios')
          AND novo.acao IS NOT NULL
        ON CONFLICT DO NOTHING;

        -- Centros de custo
        INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
        SELECT v_rec.cargo_id, 'centros-custo', novo.acao
        FROM auth.permissoes_cargo pc
        CROSS JOIN LATERAL (
            SELECT CASE pc.acao
                WHEN 'ver'     THEN 'ver_centros'
                WHEN 'criar'   THEN 'gerir_centros'
                WHEN 'editar'  THEN 'gerir_centros'
                WHEN 'apagar'  THEN 'eliminar_centros'
            END AS acao
        ) AS novo
        WHERE pc.cargo_id = v_rec.cargo_id
          AND pc.modulo = 'centros-custo'
          AND pc.acao IN ('ver','criar','editar','apagar')
          AND novo.acao IS NOT NULL
        ON CONFLICT DO NOTHING;

        -- Multi-moeda
        INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
        SELECT v_rec.cargo_id, 'multi-moeda', novo.acao
        FROM auth.permissoes_cargo pc
        CROSS JOIN LATERAL (
            SELECT CASE pc.acao
                WHEN 'ver'        THEN 'ver_moedas'
                WHEN 'criar'      THEN 'gerir_moedas'
                WHEN 'editar'     THEN 'gerir_moedas'
                WHEN 'configurar' THEN 'gerir_moedas'
            END AS acao
        ) AS novo
        WHERE pc.cargo_id = v_rec.cargo_id
          AND pc.modulo = 'multi-moeda'
          AND pc.acao IN ('ver','criar','editar','configurar')
          AND novo.acao IS NOT NULL
        ON CONFLICT DO NOTHING;

        -- Logística
        INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
        SELECT v_rec.cargo_id, 'logistica', novo.acao
        FROM auth.permissoes_cargo pc
        CROSS JOIN LATERAL (
            SELECT CASE pc.acao
                WHEN 'ver'   THEN 'ver_logistica'
                WHEN 'criar' THEN 'gerir_entregas'
                WHEN 'editar' THEN 'gerir_entregas'
            END AS acao
        ) AS novo
        WHERE pc.cargo_id = v_rec.cargo_id
          AND pc.modulo = 'logistica'
          AND pc.acao IN ('ver','criar','editar')
          AND novo.acao IS NOT NULL
        ON CONFLICT DO NOTHING;

        -- Stock
        INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
        SELECT v_rec.cargo_id, 'stock', novo.acao
        FROM auth.permissoes_cargo pc
        CROSS JOIN LATERAL (
            SELECT CASE pc.acao
                WHEN 'ver'      THEN 'ver_stock'
                WHEN 'criar'    THEN 'gerir_produtos'
                WHEN 'editar'   THEN 'gerir_movimentos'
                WHEN 'apagar'   THEN 'eliminar_produtos'
                WHEN 'eliminar' THEN 'gerir_categorias'
            END AS acao
        ) AS novo
        WHERE pc.cargo_id = v_rec.cargo_id
          AND pc.modulo = 'stock'
          AND pc.acao IN ('ver','criar','editar','apagar','eliminar')
          AND novo.acao IS NOT NULL
        ON CONFLICT DO NOTHING;

        -- Recursos Humanos
        INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
        SELECT v_rec.cargo_id, 'recursos-humanos', novo.acao
        FROM auth.permissoes_cargo pc
        CROSS JOIN LATERAL (
            SELECT CASE pc.acao
                WHEN 'ver'        THEN 'ver_funcionarios'
                WHEN 'criar'      THEN 'gerir_funcionarios'
                WHEN 'editar'     THEN 'gerir_contratos'
                WHEN 'apagar'     THEN 'aprovar_ausencias'
                WHEN 'aprovar'    THEN 'processar_salarios'
                WHEN 'configurar' THEN 'gerir_horarios'
                WHEN 'relatorios' THEN 'ver_relatorios'
                WHEN 'exportar'   THEN 'ver_salarios'
            END AS acao
        ) AS novo
        WHERE pc.cargo_id = v_rec.cargo_id
          AND pc.modulo = 'recursos-humanos'
          AND pc.acao IN ('ver','criar','editar','apagar','aprovar','configurar','relatorios','exportar')
          AND novo.acao IS NOT NULL
        ON CONFLICT DO NOTHING;

        -- Assiduidade
        INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
        SELECT v_rec.cargo_id, 'assiduidade', novo.acao
        FROM auth.permissoes_cargo pc
        CROSS JOIN LATERAL (
            SELECT CASE pc.acao
                WHEN 'ver'     THEN 'ver_configuracao'
                WHEN 'editar'  THEN 'gerir_configuracao'
                WHEN 'aprovar' THEN 'aprovar_correcao'
            END AS acao
        ) AS novo
        WHERE pc.cargo_id = v_rec.cargo_id
          AND pc.modulo = 'assiduidade'
          AND pc.acao IN ('ver','editar','aprovar')
          AND novo.acao IS NOT NULL
        ON CONFLICT DO NOTHING;

        -- Pedido de férias
        INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
        SELECT v_rec.cargo_id, 'pedido-ferias', novo.acao
        FROM auth.permissoes_cargo pc
        CROSS JOIN LATERAL (
            SELECT CASE pc.acao
                WHEN 'ver'      THEN 'ver_pedidos'
                WHEN 'criar'    THEN 'submeter_pedido'
                WHEN 'aprovar'  THEN 'aprovar'
            END AS acao
        ) AS novo
        WHERE pc.cargo_id = v_rec.cargo_id
          AND pc.modulo = 'pedido-ferias'
          AND pc.acao IN ('ver','criar','aprovar')
          AND novo.acao IS NOT NULL
        ON CONFLICT DO NOTHING;

        -- Recrutamento
        INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
        SELECT v_rec.cargo_id, 'recrutamento', novo.acao
        FROM auth.permissoes_cargo pc
        CROSS JOIN LATERAL (
            SELECT CASE pc.acao
                WHEN 'ver'        THEN 'ver_vagas'
                WHEN 'criar'      THEN 'gerir_vagas'
                WHEN 'editar'     THEN 'gerir_candidaturas'
                WHEN 'apagar'     THEN 'gerir_candidaturas'
                WHEN 'aprovar'    THEN 'contratar'
                WHEN 'configurar' THEN 'configurar_recrutamento'
            END AS acao
        ) AS novo
        WHERE pc.cargo_id = v_rec.cargo_id
          AND pc.modulo = 'recrutamento'
          AND pc.acao IN ('ver','criar','editar','apagar','aprovar','configurar')
          AND novo.acao IS NOT NULL
        ON CONFLICT DO NOTHING;

        -- Empresa
        INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
        SELECT v_rec.cargo_id, 'empresa', novo.acao
        FROM auth.permissoes_cargo pc
        CROSS JOIN LATERAL (
            SELECT CASE pc.acao
                WHEN 'ver'        THEN 'ver_empresa'
                WHEN 'editar'     THEN 'editar_empresa'
                WHEN 'configurar' THEN 'gerir_filiais'
                WHEN 'aprovar'    THEN 'gerir_licencas'
            END AS acao
        ) AS novo
        WHERE pc.cargo_id = v_rec.cargo_id
          AND pc.modulo = 'empresa'
          AND pc.acao IN ('ver','editar','configurar','aprovar')
          AND novo.acao IS NOT NULL
        ON CONFLICT DO NOTHING;

        -- Auditoria
        INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
        SELECT v_rec.cargo_id, 'auditoria', novo.acao
        FROM auth.permissoes_cargo pc
        CROSS JOIN LATERAL (
            SELECT CASE pc.acao
                WHEN 'ver'        THEN 'ver_logs'
                WHEN 'relatorios' THEN 'ver_logs'
                WHEN 'exportar'   THEN 'gerir_logs'
            END AS acao
        ) AS novo
        WHERE pc.cargo_id = v_rec.cargo_id
          AND pc.modulo = 'auditoria'
          AND pc.acao IN ('ver','relatorios','exportar')
          AND novo.acao IS NOT NULL
        ON CONFLICT DO NOTHING;

        -- Sistema-configuracao
        INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
        SELECT v_rec.cargo_id, 'sistema-configuracao', novo.acao
        FROM auth.permissoes_cargo pc
        CROSS JOIN LATERAL (
            SELECT CASE pc.acao
                WHEN 'ver'        THEN 'ver_configuracoes'
                WHEN 'editar'     THEN 'editar_configuracoes'
                WHEN 'configurar' THEN 'gerir_templates'
                WHEN 'relatorios' THEN 'ver_configuracoes'
            END AS acao
        ) AS novo
        WHERE pc.cargo_id = v_rec.cargo_id
          AND pc.modulo = 'sistema-configuracao'
          AND pc.acao IN ('ver','editar','configurar','relatorios')
          AND novo.acao IS NOT NULL
        ON CONFLICT DO NOTHING;

        -- Seguranca
        INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
        SELECT v_rec.cargo_id, 'seguranca', novo.acao
        FROM auth.permissoes_cargo pc
        CROSS JOIN LATERAL (
            SELECT CASE pc.acao
                WHEN 'ver'        THEN 'ver_seguranca'
                WHEN 'editar'     THEN 'gerir_politicas'
                WHEN 'configurar' THEN 'gerir_allowlist'
                WHEN 'relatorios' THEN 'ver_seguranca'
            END AS acao
        ) AS novo
        WHERE pc.cargo_id = v_rec.cargo_id
          AND pc.modulo = 'seguranca'
          AND pc.acao IN ('ver','editar','configurar','relatorios')
          AND novo.acao IS NOT NULL
        ON CONFLICT DO NOTHING;

        -- Assinaturas
        INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
        SELECT v_rec.cargo_id, 'assinaturas', novo.acao
        FROM auth.permissoes_cargo pc
        CROSS JOIN LATERAL (
            SELECT CASE pc.acao
                WHEN 'ver'     THEN 'ver_assinaturas'
                WHEN 'criar'   THEN 'gerir_assinaturas'
                WHEN 'editar'  THEN 'gerir_assinaturas'
                WHEN 'apagar'  THEN 'gerir_assinaturas'
            END AS acao
        ) AS novo
        WHERE pc.cargo_id = v_rec.cargo_id
          AND pc.modulo = 'assinaturas'
          AND pc.acao IN ('ver','criar','editar','apagar')
          AND novo.acao IS NOT NULL
        ON CONFLICT DO NOTHING;

        -- Notificacoes
        INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
        SELECT v_rec.cargo_id, 'notificacoes', novo.acao
        FROM auth.permissoes_cargo pc
        CROSS JOIN LATERAL (
            SELECT CASE pc.acao
                WHEN 'ver'     THEN 'ver_notificacoes'
                WHEN 'criar'   THEN 'gerir_notificacoes'
                WHEN 'editar'  THEN 'gerir_notificacoes'
                WHEN 'apagar'  THEN 'gerir_notificacoes'
            END AS acao
        ) AS novo
        WHERE pc.cargo_id = v_rec.cargo_id
          AND pc.modulo = 'notificacoes'
          AND pc.acao IN ('ver','criar','editar','apagar')
          AND novo.acao IS NOT NULL
        ON CONFLICT DO NOTHING;

        -- Faturacao (ações genéricas antigas)
        INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
        SELECT v_rec.cargo_id, 'faturacao', novo.acao
        FROM auth.permissoes_cargo pc
        CROSS JOIN LATERAL (
            SELECT CASE pc.acao
                WHEN 'ver'        THEN 'ver_documentos'
                WHEN 'criar'      THEN 'emitir_orcamentos'
                WHEN 'editar'     THEN 'emitir_faturas'
                WHEN 'relatorios' THEN 'ver_documentos'
            END AS acao
        ) AS novo
        WHERE pc.cargo_id = v_rec.cargo_id
          AND pc.modulo = 'faturacao'
          AND pc.acao IN ('ver','criar','editar','relatorios')
          AND novo.acao IS NOT NULL
        ON CONFLICT DO NOTHING;

        -- POS (ações genéricas antigas)
        INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
        SELECT v_rec.cargo_id, 'pos', novo.acao
        FROM auth.permissoes_cargo pc
        CROSS JOIN LATERAL (
            SELECT CASE pc.acao
                WHEN 'ver'     THEN 'operar_pos'
                WHEN 'criar'   THEN 'operar_pos'
                WHEN 'editar'  THEN 'operar_pos'
                WHEN 'apagar'  THEN 'gerir_terminais'
            END AS acao
        ) AS novo
        WHERE pc.cargo_id = v_rec.cargo_id
          AND pc.modulo = 'pos'
          AND pc.acao IN ('ver','criar','editar','apagar')
          AND novo.acao IS NOT NULL
        ON CONFLICT DO NOTHING;

    END LOOP;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2.2 Remover acções genéricas obsoletas que já foram convertidas
--     (apenas para módulos onde o router só aceita acções finas).
--     Módulos com acções finas E genéricas ainda válidas (ex.: vendas,
--     gestao-escolar) não são afectados.
-- ─────────────────────────────────────────────────────────────────────────────
DELETE FROM auth.permissoes_cargo
 WHERE modulo IN (
     'compras','financeiro','tesouraria','contabilidade','impostos',
     'centros-custo','multi-moeda','logistica','stock','recursos-humanos',
     'assiduidade','pedido-ferias','recrutamento','empresa','auditoria',
     'sistema-configuracao','seguranca','assinaturas','notificacoes',
     'faturacao','pos','clientes'
 )
   AND acao IN ('ver','criar','editar','apagar','exportar','aprovar','configurar','relatorios','eliminar');

-- ═════════════════════════════════════════════════════════════════════════════
-- 3. PERMISSÕES POR TIPO DE UTILIZADOR
-- ═════════════════════════════════════════════════════════════════════════════

-- Self-service: funcionários precisam de perfil, chat, assiduidade e pedidos
INSERT INTO auth.permissoes_tipo (tipo, modulo, acao) VALUES
    ('funcionario', 'perfil', 'ver_perfil'),
    ('funcionario', 'perfil', 'editar_perfil'),
    ('funcionario', 'chat', 'ver_conversas'),
    ('funcionario', 'chat', 'enviar_mensagem'),
    ('funcionario', 'assiduidade', 'ver_assiduidade'),
    ('funcionario', 'assiduidade', 'justificar'),
    ('funcionario', 'assiduidade', 'corrigir_ponto'),
    ('funcionario', 'pedido-ferias', 'ver_pedidos'),
    ('funcionario', 'pedido-ferias', 'submeter_pedido')
ON CONFLICT DO NOTHING;

-- ═════════════════════════════════════════════════════════════════════════════
-- 4. REAPLICAR A FUNÇÃO AOS TENANTS SEM CARGO ADMINISTRADOR
-- ═════════════════════════════════════════════════════════════════════════════

SELECT auth.criar_cargos_padrao(t.id)
  FROM saas.tenants t
 WHERE NOT EXISTS (
     SELECT 1 FROM auth.cargos c
      WHERE c.tenant_id = t.id AND c.nome = 'Administrador'
 );
