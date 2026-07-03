-- Corrige e completa os dados da empresa Enigma School (tenant 5) no schema empresas

DO $$
DECLARE
  v_tenant_id BIGINT := 5;
  v_company_id BIGINT;
  v_branch_id BIGINT;
  v_admin_user_id BIGINT;
BEGIN
  -- 1. Garantir que a company 7 esta ligada ao tenant 5
  SELECT id INTO v_company_id FROM empresas.companies WHERE codigo = 'ENIGMA-SCH';
  IF v_company_id IS NULL THEN
    INSERT INTO empresas.companies (codigo, nome, nome_comercial, tipo, status, moeda_base, timezone, tenant_id)
    VALUES ('ENIGMA-SCH', 'Instituto Politecnico de Ciencias da Terra e Ambiente', 'Enigma School', 'organizacao', 'ativa', 'MZN', 'Africa/Maputo', v_tenant_id)
    RETURNING id INTO v_company_id;
  ELSE
    UPDATE empresas.companies
    SET tenant_id = v_tenant_id,
        nome = 'Instituto Politecnico de Ciencias da Terra e Ambiente'
    WHERE id = v_company_id;
  END IF;

  -- 2. Remover registos orfaos (company_id = 1 nao existe mais)
  DELETE FROM empresas.company_branches WHERE company_id NOT IN (SELECT id FROM empresas.companies);
  DELETE FROM empresas.company_tax_info WHERE company_id NOT IN (SELECT id FROM empresas.companies);
  DELETE FROM empresas.company_licenses WHERE company_id NOT IN (SELECT id FROM empresas.companies);
  DELETE FROM empresas.company_addresses WHERE company_id NOT IN (SELECT id FROM empresas.companies);
  DELETE FROM empresas.company_banks WHERE company_id NOT IN (SELECT id FROM empresas.companies);
  DELETE FROM empresas.company_contacts WHERE company_id NOT IN (SELECT id FROM empresas.companies);
  DELETE FROM empresas.company_documents WHERE company_id NOT IN (SELECT id FROM empresas.companies);
  DELETE FROM empresas.company_settings WHERE company_id NOT IN (SELECT id FROM empresas.companies);
  DELETE FROM empresas.company_users WHERE company_id NOT IN (SELECT id FROM empresas.companies);

  -- 3. Criar filial principal
  INSERT INTO empresas.company_branches (company_id, codigo, nome, status, principal)
  VALUES (v_company_id, 'SEDE', 'Sede Enigma School', 'ativa', true)
  ON CONFLICT (company_id, codigo) DO NOTHING RETURNING id INTO v_branch_id;
  IF v_branch_id IS NULL THEN
    SELECT id INTO v_branch_id FROM empresas.company_branches WHERE company_id = v_company_id AND codigo = 'SEDE';
  END IF;

  -- 4. Informacao fiscal
  INSERT INTO empresas.company_tax_info (company_id, nuit, regime_iva, taxa_iva_padrao, inicio_atividade, reparticao_fiscal)
  VALUES (v_company_id, '400123456', 'geral', 17.00, '2020-01-15', 'Maputo')
  ON CONFLICT (company_id) DO UPDATE SET
    nuit = EXCLUDED.nuit,
    regime_iva = EXCLUDED.regime_iva,
    taxa_iva_padrao = EXCLUDED.taxa_iva_padrao,
    inicio_atividade = EXCLUDED.inicio_atividade,
    reparticao_fiscal = EXCLUDED.reparticao_fiscal;

  -- 5. Licenca
  INSERT INTO empresas.company_licenses (company_id, plano, licenca_chave, limite_usuarios, limite_filiais, inicia_em, expira_em, status)
  VALUES (v_company_id, 'educacional', 'ENIGMA-EDU-2026-UNLIMITED', 1000, 10, '2026-01-01', '2026-12-31', 'ativa')
  ON CONFLICT DO NOTHING;

  -- 6. Endereco
  INSERT INTO empresas.company_addresses (company_id, branch_id, tipo, endereco, cidade, provincia, pais, codigo_postal)
  VALUES (v_company_id, v_branch_id, 'principal', 'Avenida 24 de Julho, nr 1234', 'Maputo', 'Maputo', 'Mocambique', '1100')
  ON CONFLICT DO NOTHING;

  -- 7. Banco
  INSERT INTO empresas.company_banks (company_id, banco, numero_conta, iban, moeda, principal)
  VALUES (v_company_id, 'BIM', '1234567890', 'MZ59123456789012345678901', 'MZN', true)
  ON CONFLICT DO NOTHING;

  -- 8. Contacto
  INSERT INTO empresas.company_contacts (company_id, branch_id, tipo, nome, email, telefone, principal)
  VALUES (v_company_id, v_branch_id, 'geral', 'Secretaria Enigma School', 'info@enigmaschool.mz', '+258 21 123 4567', true)
  ON CONFLICT DO NOTHING;

  -- 9. Configuracoes
  INSERT INTO empresas.company_settings (company_id, chave, valor)
  VALUES
    (v_company_id, 'ano_lectivo_atual', '2026'),
    (v_company_id, 'moeda_padrao', 'MZN'),
    (v_company_id, 'idioma_padrao', 'pt'),
    (v_company_id, 'timezone', 'Africa/Maputo')
  ON CONFLICT DO NOTHING;

  -- 10. Vincular admin do tenant 5 a empresa
  SELECT u.id INTO v_admin_user_id
  FROM auth.users u
  JOIN auth.memberships m ON m.user_id = u.id
  WHERE m.tenant_id = v_tenant_id AND u.email = 'admin@enigmaschool.mz'
  LIMIT 1;

  IF v_admin_user_id IS NOT NULL THEN
    INSERT INTO empresas.company_users (company_id, branch_id, user_id, perfil_empresa, ativo)
    VALUES (v_company_id, v_branch_id, v_admin_user_id, 'administrador', true)
    ON CONFLICT (company_id, user_id) DO UPDATE SET
      branch_id = EXCLUDED.branch_id,
      perfil_empresa = EXCLUDED.perfil_empresa,
      ativo = EXCLUDED.ativo;
  END IF;

  -- Atualizar saas.tenants.company_id se necessario
  UPDATE saas.tenants SET company_id = v_company_id WHERE id = v_tenant_id AND (company_id IS NULL OR company_id != v_company_id);

END $$;
