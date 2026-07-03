-- ============================================================
-- Seed complementar: dados completos da empresa e258tech e funcionária OLÍMPIA
-- Inclui: dados fiscais, contactos, banco, documentos, login, permissões,
-- formação, benefícios, componentes salariais, ausências, presença e folha.
--
-- Nota: para manter o salário LÍQUIDO em 10.000,00 MZN após adicionar
-- subsídios (alimentação 2.500 + transporte 1.500 = 4.000 proventos),
-- o salário base é ajustado para 7.158,54 MZN.
--   Bruto = 7.158,54 + 4.000 = 11.158,54
--   INSS 3% = 334,76
--   IRPS 15% − 850 = 823,78
--   Líquido = 11.158,54 − 334,76 − 823,78 = 10.000,00
-- ============================================================

DO $$
DECLARE
    v_tenant_id BIGINT;
    v_company_id BIGINT;
    v_branch_id BIGINT;
    v_funcionario_id BIGINT;
    v_user_id BIGINT;
    v_cargo_admin_id BIGINT;
    v_cargo_admin_ref BIGINT;
    v_formacao_id BIGINT;
    v_benef_saude BIGINT;
    v_benef_alim BIGINT;
    v_benef_transporte BIGINT;
    v_comp_subs_alim BIGINT;
    v_comp_subs_trans BIGINT;
    v_comp_inss BIGINT;
    v_comp_irps BIGINT;
    v_tipo_ferias BIGINT;
    v_tipo_doenca BIGINT;
    v_folha_id BIGINT;
    v_recibo_id BIGINT;

    v_salario_base NUMERIC(14,2) := 7158.54;
    v_subs_alim NUMERIC(14,2) := 2500.00;
    v_subs_trans NUMERIC(14,2) := 1500.00;
    v_bruto NUMERIC(14,2);
    v_inss NUMERIC(14,2);
    v_irps NUMERIC(14,2);
    v_proventos NUMERIC(14,2);
    v_descontos NUMERIC(14,2);
    v_liquido NUMERIC(14,2);
BEGIN
    -- ============================================================
    -- 0. Localizar IDs base
    -- ============================================================
    SELECT c.id, c.tenant_id INTO v_company_id, v_tenant_id
    FROM empresas.companies c
    WHERE c.codigo = 'E258TECH';

    IF v_company_id IS NULL THEN
        RAISE EXCEPTION 'Empresa E258TECH não encontrada. Executar seed_e258tech.sql primeiro.';
    END IF;

    SELECT id INTO v_branch_id
    FROM empresas.company_branches
    WHERE company_id = v_company_id AND codigo = 'SEDE';

    SELECT id INTO v_funcionario_id
    FROM rh.funcionarios
    WHERE tenant_id = v_tenant_id AND numero_funcionario = 'E258-001';

    IF v_funcionario_id IS NULL THEN
        RAISE EXCEPTION 'Funcionária E258-001 não encontrada.';
    END IF;

    -- ============================================================
    -- 1. Dados fiscais e comerciais da empresa
    -- ============================================================
    INSERT INTO empresas.company_tax_info (company_id, nuit, regime_iva, taxa_iva_padrao, inicio_atividade, reparticao_fiscal)
    VALUES (v_company_id, '402134951', 'simplificado', 17.00, '2021-01-01', 'Repartição de Impostos de Maputo')
    ON CONFLICT (company_id) DO NOTHING;

    -- Contactos
    INSERT INTO empresas.company_contacts (company_id, branch_id, tipo, nome, telefone, email, principal)
    VALUES
        (v_company_id, v_branch_id, 'geral', 'Geral', '842345678', 'geral@e258tech.mz', TRUE),
        (v_company_id, v_branch_id, 'financeiro', 'Financeiro', '842345679', 'financeiro@e258tech.mz', FALSE),
        (v_company_id, v_branch_id, 'rh', 'Recursos Humanos', '842345680', 'rh@e258tech.mz', FALSE)
    ON CONFLICT DO NOTHING;

    -- Dados bancários
    INSERT INTO empresas.company_banks (company_id, banco, numero_conta, nib, iban, swift, moeda, principal)
    VALUES (v_company_id, 'BCI', '0001234567890', '0008000012345678901', 'MZ590008000012345678901', 'BCIMMZMXXXX', 'MZN', TRUE)
    ON CONFLICT DO NOTHING;

    -- Documentos
    INSERT INTO empresas.company_documents (company_id, tipo, numero, emitido_em, expira_em)
    VALUES
        (v_company_id, 'alvara', 'ALV-258-2021', '2021-01-15', '2026-01-15'),
        (v_company_id, 'certidao', 'CERT-258-2021', '2021-01-20', NULL),
        (v_company_id, 'contrato_social', 'CS-258-2021', '2021-01-10', NULL),
        (v_company_id, 'licenca', 'LIC-258-2021', '2021-02-01', '2026-02-01')
    ON CONFLICT DO NOTHING;

    -- Licença de uso da plataforma
    INSERT INTO empresas.company_licenses (company_id, plano, licenca_chave, limite_usuarios, limite_filiais, inicia_em, expira_em, status)
    VALUES (v_company_id, 'empresarial', 'E258TECH-EMP-2026', 10, 1, CURRENT_DATE, CURRENT_DATE + INTERVAL '1 year', 'ativa')
    ON CONFLICT DO NOTHING;

    -- ============================================================
    -- 2. Utilizador / login para a OLÍMPIA
    -- ============================================================
    INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
    VALUES (
        'OLÍMPIA CONSTANTINO CHITLHANGO',
        'olimpia.chitlhango@e258tech.mz',
        crypt('E258tech@2026', gen_salt('bf')),
        '841234567',
        'ativo',
        TRUE,
        'funcionario'
    )
    ON CONFLICT (email) DO NOTHING;

    SELECT id INTO v_user_id FROM auth.users WHERE email = 'olimpia.chitlhango@e258tech.mz';

    -- Cargo Administrador no tenant e258tech (copiar permissões do cargo Administrador do tenant 5)
    INSERT INTO auth.cargos (tenant_id, nome, descricao, ativo)
    VALUES (v_tenant_id, 'Administrador', 'Acesso total ao ERP da e258tech', TRUE)
    ON CONFLICT (tenant_id, nome) DO NOTHING;

    SELECT id INTO v_cargo_admin_id FROM auth.cargos WHERE tenant_id = v_tenant_id AND nome = 'Administrador';

    SELECT id INTO v_cargo_admin_ref
    FROM auth.cargos
    WHERE tenant_id = 5 AND nome = 'Administrador'
    LIMIT 1;

    IF v_cargo_admin_ref IS NOT NULL THEN
        INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
        SELECT v_cargo_admin_id, modulo, acao
        FROM auth.permissoes_cargo
        WHERE cargo_id = v_cargo_admin_ref
        ON CONFLICT (cargo_id, modulo, acao) DO NOTHING;
    END IF;

    -- Garantir permissões específicas de RH usadas pelo backend Nexora
    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
    SELECT v_cargo_admin_id, p.modulo, p.acao
    FROM (VALUES
        ('recursos-humanos', 'ver_funcionarios'),
        ('recursos-humanos', 'gerir_funcionarios'),
        ('recursos-humanos', 'ver_recibos'),
        ('recursos-humanos', 'ver_salarios'),
        ('recursos-humanos', 'processar_salarios'),
        ('recursos-humanos', 'ver_beneficios'),
        ('recursos-humanos', 'gerir_beneficios'),
        ('recursos-humanos', 'ver_processos_disciplinares'),
        ('recursos-humanos', 'gerir_formacoes'),
        ('recursos-humanos', 'gerir_contratos'),
        ('recursos-humanos', 'aprovar_ausencias'),
        ('recursos-humanos', 'gerir_avaliacoes'),
        ('recursos-humanos', 'gerir_horarios'),
        ('centros-custo', 'ver_centros'),
        ('centros-custo', 'gerir_centros'),
        ('centros-custo', 'eliminar_centros')
    ) AS p(modulo, acao)
    ON CONFLICT (cargo_id, modulo, acao) DO NOTHING;

    -- Membership
    INSERT INTO auth.memberships (user_id, tenant_id, cargo_id, ativo, escopo)
    VALUES (v_user_id, v_tenant_id, v_cargo_admin_id, TRUE, 'erp')
    ON CONFLICT (user_id) DO NOTHING;

    -- Associar funcionária ao utilizador e à empresa
    UPDATE rh.funcionarios SET user_id = v_user_id, telefone = '841234567' WHERE id = v_funcionario_id;

    INSERT INTO empresas.company_users (company_id, user_id, branch_id, perfil_empresa, ativo)
    VALUES (v_company_id, v_user_id, v_branch_id, 'administrador', TRUE)
    ON CONFLICT (company_id, user_id) DO NOTHING;

    -- ============================================================
    -- 3. Contacto de emergência (telefone placeholder — substituir depois)
    -- ============================================================
    INSERT INTO rh.contactos_emergencia (tenant_id, funcionario_id, nome, parentesco, telefone)
    VALUES (v_tenant_id, v_funcionario_id, 'CONSTANTINO MÁRIO CHITLHANGO', 'pai', '840000000')
    ON CONFLICT DO NOTHING;

    -- ============================================================
    -- 4. Formação
    -- ============================================================
    INSERT INTO rh.formacoes (tenant_id, codigo, nome, descricao, categoria, duracao_horas, entidade_formadora, ativo)
    VALUES (v_tenant_id, 'GEST-EMP', 'Gestão Empresarial', 'Gestão estratégica e operacional de empresas', 'tecnica', 40, 'Instituto Superior de Gestão', TRUE)
    ON CONFLICT (tenant_id, codigo) DO NOTHING RETURNING id INTO v_formacao_id;

    IF v_formacao_id IS NULL THEN
        SELECT id INTO v_formacao_id FROM rh.formacoes WHERE tenant_id = v_tenant_id AND codigo = 'GEST-EMP';
    END IF;

    INSERT INTO rh.funcionario_formacoes (tenant_id, funcionario_id, formacao_id, data_inicio, data_fim, estado, nota)
    VALUES (v_tenant_id, v_funcionario_id, v_formacao_id, '2020-06-01', '2020-08-31', 'concluida', 16.00)
    ON CONFLICT DO NOTHING;

    -- ============================================================
    -- 5. Benefícios
    -- ============================================================
    INSERT INTO rh.beneficios (tenant_id, codigo, nome, descricao, valor_padrao, ativo)
    VALUES (v_tenant_id, 'SAUDE', 'Plano de Saúde', 'Cobertura médica ambulatório e internamento', 0, TRUE)
    ON CONFLICT (tenant_id, codigo) DO NOTHING RETURNING id INTO v_benef_saude;
    IF v_benef_saude IS NULL THEN SELECT id INTO v_benef_saude FROM rh.beneficios WHERE tenant_id = v_tenant_id AND codigo = 'SAUDE'; END IF;

    INSERT INTO rh.beneficios (tenant_id, codigo, nome, descricao, valor_padrao, ativo)
    VALUES (v_tenant_id, 'ALIM', 'Subsídio de Alimentação', 'Subsídio diário de alimentação', 2500, TRUE)
    ON CONFLICT (tenant_id, codigo) DO NOTHING RETURNING id INTO v_benef_alim;
    IF v_benef_alim IS NULL THEN SELECT id INTO v_benef_alim FROM rh.beneficios WHERE tenant_id = v_tenant_id AND codigo = 'ALIM'; END IF;

    INSERT INTO rh.beneficios (tenant_id, codigo, nome, descricao, valor_padrao, ativo)
    VALUES (v_tenant_id, 'TRANS', 'Subsídio de Transporte', 'Subsídio mensal de transporte', 1500, TRUE)
    ON CONFLICT (tenant_id, codigo) DO NOTHING RETURNING id INTO v_benef_transporte;
    IF v_benef_transporte IS NULL THEN SELECT id INTO v_benef_transporte FROM rh.beneficios WHERE tenant_id = v_tenant_id AND codigo = 'TRANS'; END IF;

    INSERT INTO rh.funcionario_beneficios (tenant_id, funcionario_id, beneficio_id, valor, data_inicio, observacoes)
    VALUES
        (v_tenant_id, v_funcionario_id, v_benef_saude, 0, CURRENT_DATE, 'Cobertura familiar incluída'),
        (v_tenant_id, v_funcionario_id, v_benef_alim, 2500, CURRENT_DATE, NULL),
        (v_tenant_id, v_funcionario_id, v_benef_transporte, 1500, CURRENT_DATE, NULL)
    ON CONFLICT DO NOTHING;

    -- ============================================================
    -- 6. Componentes salariais
    -- ============================================================
    INSERT INTO rh.componentes_salariais (tenant_id, codigo, nome, tipo, forma_calculo, valor_padrao, ativo)
    VALUES (v_tenant_id, 'SUBS-ALIM', 'Subsídio de Alimentação', 'provento', 'fixo', 2500, TRUE)
    ON CONFLICT (tenant_id, codigo) DO NOTHING RETURNING id INTO v_comp_subs_alim;
    IF v_comp_subs_alim IS NULL THEN SELECT id INTO v_comp_subs_alim FROM rh.componentes_salariais WHERE tenant_id = v_tenant_id AND codigo = 'SUBS-ALIM'; END IF;

    INSERT INTO rh.componentes_salariais (tenant_id, codigo, nome, tipo, forma_calculo, valor_padrao, ativo)
    VALUES (v_tenant_id, 'SUBS-TRANS', 'Subsídio de Transporte', 'provento', 'fixo', 1500, TRUE)
    ON CONFLICT (tenant_id, codigo) DO NOTHING RETURNING id INTO v_comp_subs_trans;
    IF v_comp_subs_trans IS NULL THEN SELECT id INTO v_comp_subs_trans FROM rh.componentes_salariais WHERE tenant_id = v_tenant_id AND codigo = 'SUBS-TRANS'; END IF;

    INSERT INTO rh.componentes_salariais (tenant_id, codigo, nome, tipo, forma_calculo, valor_padrao, ativo)
    VALUES (v_tenant_id, 'INSS', 'INSS Trabalhador', 'desconto', 'percentual', 3, TRUE)
    ON CONFLICT (tenant_id, codigo) DO NOTHING RETURNING id INTO v_comp_inss;
    IF v_comp_inss IS NULL THEN SELECT id INTO v_comp_inss FROM rh.componentes_salariais WHERE tenant_id = v_tenant_id AND codigo = 'INSS'; END IF;

    INSERT INTO rh.componentes_salariais (tenant_id, codigo, nome, tipo, forma_calculo, valor_padrao, ativo)
    VALUES (v_tenant_id, 'IRPS', 'IRPS', 'desconto', 'percentual', 15, TRUE)
    ON CONFLICT (tenant_id, codigo) DO NOTHING RETURNING id INTO v_comp_irps;
    IF v_comp_irps IS NULL THEN SELECT id INTO v_comp_irps FROM rh.componentes_salariais WHERE tenant_id = v_tenant_id AND codigo = 'IRPS'; END IF;

    INSERT INTO rh.funcionario_componentes_salariais (tenant_id, funcionario_id, componente_id, valor)
    VALUES
        (v_tenant_id, v_funcionario_id, v_comp_subs_alim, v_subs_alim),
        (v_tenant_id, v_funcionario_id, v_comp_subs_trans, v_subs_trans)
    ON CONFLICT DO NOTHING;

    -- Reajustar salário base para manter 10.000 MZN líquido
    UPDATE rh.funcionarios SET salario_base = v_salario_base WHERE id = v_funcionario_id;
    UPDATE rh.contratos SET salario = v_salario_base WHERE funcionario_id = v_funcionario_id AND estado = 'ativo';

    -- ============================================================
    -- 7. Tipos de ausência e saldos
    -- ============================================================
    INSERT INTO rh.tipos_ausencia (tenant_id, codigo, nome, dias_anuais, remunerada, afeta_saldo, ativo)
    VALUES (v_tenant_id, 'FERIAS', 'Férias Anuais', 22, TRUE, TRUE, TRUE)
    ON CONFLICT (tenant_id, codigo) DO NOTHING RETURNING id INTO v_tipo_ferias;
    IF v_tipo_ferias IS NULL THEN SELECT id INTO v_tipo_ferias FROM rh.tipos_ausencia WHERE tenant_id = v_tenant_id AND codigo = 'FERIAS'; END IF;

    INSERT INTO rh.tipos_ausencia (tenant_id, codigo, nome, dias_anuais, remunerada, afeta_saldo, ativo)
    VALUES (v_tenant_id, 'DOENCA', 'Licença por Doença', 30, TRUE, FALSE, TRUE)
    ON CONFLICT (tenant_id, codigo) DO NOTHING RETURNING id INTO v_tipo_doenca;
    IF v_tipo_doenca IS NULL THEN SELECT id INTO v_tipo_doenca FROM rh.tipos_ausencia WHERE tenant_id = v_tenant_id AND codigo = 'DOENCA'; END IF;

    INSERT INTO rh.saldos_ausencia (tenant_id, funcionario_id, tipo_ausencia_id, ano, dias_atribuidos, dias_usados)
    VALUES
        (v_tenant_id, v_funcionario_id, v_tipo_ferias, 2026, 22, 0),
        (v_tenant_id, v_funcionario_id, v_tipo_doenca, 2026, 30, 0)
    ON CONFLICT DO NOTHING;

    -- ============================================================
    -- 8. Presença do dia corrente
    -- ============================================================
    INSERT INTO rh.presencas (tenant_id, funcionario_id, data, hora_entrada, hora_saida, tipo, horas_extra)
    VALUES (v_tenant_id, v_funcionario_id, CURRENT_DATE, '08:00', '17:00', 'presente', 0)
    ON CONFLICT DO NOTHING;

    -- ============================================================
    -- 9. Folha de pagamento e recibo (Julho/2026)
    -- ============================================================
    v_proventos := v_subs_alim + v_subs_trans;
    v_bruto := v_salario_base + v_proventos;
    v_inss := ROUND(v_bruto * 0.03, 2);
    v_irps := ROUND(v_bruto * 0.15 - 850, 2);
    v_descontos := v_inss + v_irps;
    v_liquido := v_bruto - v_descontos;

    INSERT INTO rh.folhas_pagamento (tenant_id, ano, mes, estado, num_funcionarios, total_proventos, total_descontos, total_liquido, processada_em, paga_em)
    VALUES (v_tenant_id, 2026, 7, 'paga', 1, v_proventos, v_descontos, v_liquido, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
    ON CONFLICT (tenant_id, ano, mes) DO NOTHING RETURNING id INTO v_folha_id;

    IF v_folha_id IS NULL THEN
        SELECT id INTO v_folha_id FROM rh.folhas_pagamento WHERE tenant_id = v_tenant_id AND ano = 2026 AND mes = 7;
        UPDATE rh.folhas_pagamento
        SET estado = 'paga',
            num_funcionarios = 1,
            total_proventos = v_proventos,
            total_descontos = v_descontos,
            total_liquido = v_liquido,
            processada_em = CURRENT_TIMESTAMP,
            paga_em = CURRENT_TIMESTAMP
        WHERE id = v_folha_id;
    END IF;

    INSERT INTO rh.recibos_vencimento (tenant_id, folha_id, funcionario_id, salario_base, total_proventos, total_descontos, salario_liquido, estado)
    VALUES (v_tenant_id, v_folha_id, v_funcionario_id, v_salario_base, v_proventos, v_descontos, v_liquido, 'pago')
    ON CONFLICT (folha_id, funcionario_id) DO NOTHING RETURNING id INTO v_recibo_id;

    IF v_recibo_id IS NULL THEN
        SELECT id INTO v_recibo_id FROM rh.recibos_vencimento WHERE folha_id = v_folha_id AND funcionario_id = v_funcionario_id;
        UPDATE rh.recibos_vencimento
        SET salario_base = v_salario_base,
            total_proventos = v_proventos,
            total_descontos = v_descontos,
            salario_liquido = v_liquido,
            estado = 'pago'
        WHERE id = v_recibo_id;
    END IF;

    -- Itens do recibo
    DELETE FROM rh.recibo_vencimento_itens WHERE recibo_id = v_recibo_id;

    INSERT INTO rh.recibo_vencimento_itens (recibo_id, componente_id, nome, tipo, valor)
    VALUES
        (v_recibo_id, NULL, 'Salário Base', 'provento', v_salario_base),
        (v_recibo_id, v_comp_subs_alim, 'Subsídio de Alimentação', 'provento', v_subs_alim),
        (v_recibo_id, v_comp_subs_trans, 'Subsídio de Transporte', 'provento', v_subs_trans),
        (v_recibo_id, v_comp_inss, 'INSS Trabalhador', 'desconto', v_inss),
        (v_recibo_id, v_comp_irps, 'IRPS', 'desconto', v_irps);

    RAISE NOTICE 'Dados completos criados para e258tech (tenant_id=%, company_id=%).', v_tenant_id, v_company_id;
    RAISE NOTICE 'Login: olimpia.chitlhango@e258tech.mz / E258tech@2026';
    RAISE NOTICE 'Salário base ajustado para % MZN, líquido % MZN.', v_salario_base, v_liquido;
END $$;
