-- ============================================================
-- Seed: Criar empresa e258tech e funcionária OLÍMPIA CONSTANTINO CHITLHANGO
-- Salário líquido alvo: 10.000,00 MZN
-- Cálculo do salário base (sem proventos extra):
--   INSS = 3% do bruto
--   IRPS (escalão 10.000,01–20.000) = 15% - 850
--   Líquido = bruto - 0,03*bruto - (0,15*bruto - 850)
--           = 0,82*bruto + 850
--   bruto = (10.000 - 850) / 0,82 = 11.158,54 MZN
-- ============================================================

DO $$
DECLARE
    v_plano_id BIGINT;
    v_company_id BIGINT;
    v_tenant_id BIGINT;
    v_branch_id BIGINT;
    v_unit_id BIGINT;
    v_horario_id BIGINT;
    v_cargo_dir_geral BIGINT;
    v_cargo_designer BIGINT;
    v_funcionario_id BIGINT;
    v_salario_base NUMERIC(14,2) := 11158.54;
BEGIN
    -- Plano empresarial (padrão)
    SELECT id INTO v_plano_id FROM saas.plans WHERE codigo = 'empresarial' LIMIT 1;
    IF v_plano_id IS NULL THEN
        RAISE EXCEPTION 'Plano empresarial não encontrado em saas.plans';
    END IF;

    -- ============================================================
    -- 1. Empresa
    -- ============================================================
    SELECT id, tenant_id INTO v_company_id, v_tenant_id
    FROM empresas.companies
    WHERE codigo = 'E258TECH';

    IF v_company_id IS NULL THEN
        INSERT INTO empresas.companies (codigo, nome, nome_comercial, tipo, status, moeda_base, timezone)
        VALUES ('E258TECH', 'e258tech, Lda', 'e258tech', 'empresa', 'ativa', 'MZN', 'Africa/Maputo')
        RETURNING id INTO v_company_id;
    END IF;

    -- ============================================================
    -- 2. Tenant
    -- ============================================================
    IF v_tenant_id IS NULL THEN
        INSERT INTO saas.tenants (codigo, nome, company_id, status, dominio, plano_id, limite_utilizadores, limite_armazenamento_gb, validade_plano)
        VALUES ('e258tech', 'e258tech, Lda', v_company_id, 'ativo', 'e258tech.nexora.e258tech.tech', v_plano_id, 10, 5, CURRENT_DATE + INTERVAL '1 year')
        RETURNING id INTO v_tenant_id;

        UPDATE empresas.companies SET tenant_id = v_tenant_id WHERE id = v_company_id;
    END IF;

    -- Módulos ativos por defeito
    INSERT INTO saas.tenant_modules (tenant_id, modulo, ativo, config)
    SELECT v_tenant_id, m.modulo, TRUE, '{}'::jsonb
    FROM (VALUES
        ('clientes'), ('vendas'), ('faturacao'), ('stock'), ('compras'),
        ('financeiro'), ('tesouraria'), ('contabilidade'), ('impostos'),
        ('recursos-humanos'), ('crm'), ('pos'), ('logistica'), ('recrutamento'),
        ('gestao-escolar'), ('assinaturas'), ('notificacoes'), ('auditoria'),
        ('seguranca'), ('sistema-configuracao'), ('multi-moeda'), ('centros-custo')
    ) AS m(modulo)
    ON CONFLICT (tenant_id, modulo) DO NOTHING;

    -- Subscrição inicial
    INSERT INTO saas.tenant_subscriptions (tenant_id, plano_id, numero, starts_at, ends_at, next_billing_date, status, unit_price, moeda, auto_renew)
    VALUES (v_tenant_id, v_plano_id, 'SUB-' || v_tenant_id, CURRENT_DATE, CURRENT_DATE + INTERVAL '1 year', CURRENT_DATE + INTERVAL '1 month', 'activa', 0, 'MZN', TRUE)
    ON CONFLICT DO NOTHING;

    -- ============================================================
    -- 3. Filial principal (Sede)
    -- ============================================================
    SELECT id INTO v_branch_id
    FROM empresas.company_branches
    WHERE company_id = v_company_id AND codigo = 'SEDE';

    IF v_branch_id IS NULL THEN
        INSERT INTO empresas.company_branches (company_id, codigo, nome, status, principal)
        VALUES (v_company_id, 'SEDE', 'Sede', 'ativa', TRUE)
        RETURNING id INTO v_branch_id;
    END IF;

    -- Endereço da sede
    INSERT INTO empresas.company_addresses (company_id, branch_id, tipo, endereco, cidade, provincia, pais)
    VALUES (v_company_id, v_branch_id, 'principal', 'Kamubucuana, Luís Cabral', 'Maputo', 'Maputo Cidade', 'Mocambique')
    ON CONFLICT DO NOTHING;

    -- ============================================================
    -- 4. Unidade organizacional e horário
    -- ============================================================
    SELECT id INTO v_unit_id
    FROM rh.unidades_organizacionais
    WHERE tenant_id = v_tenant_id AND codigo = 'DIR-GERAL';

    IF v_unit_id IS NULL THEN
        INSERT INTO rh.unidades_organizacionais (tenant_id, codigo, nome, descricao, tipo, ativo)
        VALUES (v_tenant_id, 'DIR-GERAL', 'Direção Geral', 'Direção geral da e258tech', 'direccao', TRUE)
        RETURNING id INTO v_unit_id;
    END IF;

    SELECT id INTO v_horario_id
    FROM rh.horarios_trabalho
    WHERE tenant_id = v_tenant_id AND codigo = 'PADRAO-8H';

    IF v_horario_id IS NULL THEN
        INSERT INTO rh.horarios_trabalho (tenant_id, codigo, nome, descricao, hora_entrada, hora_saida, intervalo_inicio, intervalo_fim, dias_semana, carga_semanal_horas, ativo)
        VALUES (v_tenant_id, 'PADRAO-8H', 'Horário Padrão 8h', 'Horário normal de trabalho', '08:00', '17:00', '12:30', '13:30', '1,2,3,4,5', 40, TRUE)
        RETURNING id INTO v_horario_id;
    END IF;

    -- ============================================================
    -- 5. Cargos de RH
    -- ============================================================
    SELECT id INTO v_cargo_dir_geral
    FROM rh.cargos
    WHERE tenant_id = v_tenant_id AND codigo = 'DIR-GERAL';

    IF v_cargo_dir_geral IS NULL THEN
        INSERT INTO rh.cargos (tenant_id, codigo, nome, descricao, salario_min, salario_max, ativo)
        VALUES (v_tenant_id, 'DIR-GERAL', 'Directora Geral', 'Responsável máxima pela gestão e representação da empresa', 10000, 20000, TRUE)
        RETURNING id INTO v_cargo_dir_geral;
    END IF;

    SELECT id INTO v_cargo_designer
    FROM rh.cargos
    WHERE tenant_id = v_tenant_id AND codigo = 'DESIGNER';

    IF v_cargo_designer IS NULL THEN
        INSERT INTO rh.cargos (tenant_id, codigo, nome, descricao, salario_min, salario_max, ativo)
        VALUES (v_tenant_id, 'DESIGNER', 'Designer Gráfico', 'Criação de material visual e identidade corporativa', 10000, 20000, TRUE)
        RETURNING id INTO v_cargo_designer;
    END IF;

    -- ============================================================
    -- 6. Funcionária OLÍMPIA CONSTANTINO CHITLHANGO
    -- ============================================================
    SELECT id INTO v_funcionario_id
    FROM rh.funcionarios
    WHERE tenant_id = v_tenant_id AND nuit = '081208870999S';

    IF v_funcionario_id IS NULL THEN
        INSERT INTO rh.funcionarios (
            tenant_id, unit_id, numero_funcionario, nome_completo,
            data_nascimento, genero, nuit, telefone, email,
            endereco, cargo, data_admissao, tipo_contrato,
            salario_base, estado, cargo_id, horario_id,
            provincia, cidade, bairro
        ) VALUES (
            v_tenant_id, v_unit_id, 'E258-001',
            'OLÍMPIA CONSTANTINO CHITLHANGO',
            '2002-01-03', 'F', '081208870999S', NULL, 'olimpia.chitlhango@e258tech.mz',
            'Q.19 CASA 20, Luís Cabral, Kamubucuana', 'Directora Geral',
            CURRENT_DATE, 'indeterminado',
            v_salario_base, 'ativo', v_cargo_dir_geral, v_horario_id,
            'Maputo Cidade', 'Maputo', 'Luís Cabral'
        )
        RETURNING id INTO v_funcionario_id;

        -- Documento de identificação
        INSERT INTO rh.documentos_funcionario (tenant_id, funcionario_id, tipo, numero, data_emissao, data_validade)
        VALUES (v_tenant_id, v_funcionario_id, 'BI', '081208870999S', '2021-11-15', '2026-11-14');

        -- Contrato
        INSERT INTO rh.contratos (tenant_id, funcionario_id, tipo, funcao, data_inicio, salario, estado)
        VALUES (v_tenant_id, v_funcionario_id, 'indeterminado', 'Directora Geral', CURRENT_DATE, v_salario_base, 'ativo');

        -- Contacto de emergência (telefone obrigatório; omitido porque não foi fornecido)
        -- INSERT INTO rh.contactos_emergencia (tenant_id, funcionario_id, nome, parentesco, telefone)
        -- VALUES (v_tenant_id, v_funcionario_id, 'CONSTANTINO MÁRIO CHITLHANGO', 'pai', NULL);
    ELSE
        -- Actualiza salário/caso já exista
        UPDATE rh.funcionarios
        SET salario_base = v_salario_base,
            cargo_id = v_cargo_dir_geral,
            unit_id = v_unit_id,
            horario_id = v_horario_id,
            cargo = 'Directora Geral',
            estado = 'ativo'
        WHERE id = v_funcionario_id;
    END IF;

    -- Define a funcionária como responsável pela unidade organizacional
    UPDATE rh.unidades_organizacionais
    SET responsavel_id = v_funcionario_id
    WHERE id = v_unit_id AND responsavel_id IS NULL;

    RAISE NOTICE 'Empresa e258tech (tenant_id=%, company_id=%) criada/atualizada.', v_tenant_id, v_company_id;
    RAISE NOTICE 'Funcionária OLÍMPIA CONSTANTINO CHITLHANGO (id=%) registada com salário base %.', v_funcionario_id, v_salario_base;
    RAISE NOTICE 'Cargos criados: Directora Geral (id=%) e Designer Gráfico (id=%).', v_cargo_dir_geral, v_cargo_designer;

END $$;
