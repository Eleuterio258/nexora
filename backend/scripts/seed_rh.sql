-- Seed de dados de RH para o tenant 5 (Enigma School) - Professores PFA
-- Popula configuracoes, completa funcionarios e gera movimentacao de RH.

DO $$
DECLARE
  v_tenant_id BIGINT := 5;
  v_cargo_prof BIGINT;
  v_cargo_dir BIGINT;
  v_cargo_coord BIGINT;
  v_unit_docente BIGINT;
  v_unit_dir BIGINT;
  v_horario BIGINT;
  v_comp_inss BIGINT;
  v_comp_irps BIGINT;
  v_comp_subs_alim BIGINT;
  v_comp_subs_trans BIGINT;
  v_comp_bonus BIGINT;
  v_comp_horas_extra BIGINT;
  v_comp_faltas BIGINT;
  v_benef_saude BIGINT;
  v_benef_gym BIGINT;
  v_formacao_id BIGINT;
  v_tipo_ferias BIGINT;
  v_tipo_doenca BIGINT;
  v_folha_id BIGINT;
  v_recibo_id BIGINT;
  v_func RECORD;
  v_salario NUMERIC(18,2);
  v_data DATE;
  v_dia INT;
  v_tipo_presenca TEXT;
  v_total_proventos NUMERIC(18,2);
  v_total_descontos NUMERIC(18,2);
  v_liquido NUMERIC(18,2);
  v_adiantamento NUMERIC(18,2);
  v_prestacao NUMERIC(18,2);
  v_doc_id BIGINT;
BEGIN
  -- ============================================================
  -- 1. Configuracoes base
  -- ============================================================

  -- Cargos
  INSERT INTO rh.cargos (tenant_id, codigo, nome, descricao, salario_min, salario_max, ativo)
  VALUES (v_tenant_id, 'PROF', 'Professor', 'Docente do ensino regular', 25000, 80000, true)
  ON CONFLICT DO NOTHING RETURNING id INTO v_cargo_prof;
  IF v_cargo_prof IS NULL THEN SELECT id INTO v_cargo_prof FROM rh.cargos WHERE tenant_id = v_tenant_id AND codigo = 'PROF'; END IF;

  INSERT INTO rh.cargos (tenant_id, codigo, nome, descricao, salario_min, salario_max, ativo)
  VALUES (v_tenant_id, 'DIR-PED', 'Director Pedagogico', 'Responsavel pela direccao pedagogica', 60000, 120000, true)
  ON CONFLICT DO NOTHING RETURNING id INTO v_cargo_dir;
  IF v_cargo_dir IS NULL THEN SELECT id INTO v_cargo_dir FROM rh.cargos WHERE tenant_id = v_tenant_id AND codigo = 'DIR-PED'; END IF;

  INSERT INTO rh.cargos (tenant_id, codigo, nome, descricao, salario_min, salario_max, ativo)
  VALUES (v_tenant_id, 'COORD', 'Coordenador de Curso', 'Coordenacao de curso/disciplina', 45000, 90000, true)
  ON CONFLICT DO NOTHING RETURNING id INTO v_cargo_coord;
  IF v_cargo_coord IS NULL THEN SELECT id INTO v_cargo_coord FROM rh.cargos WHERE tenant_id = v_tenant_id AND codigo = 'COORD'; END IF;

  -- Unidades organizacionais
  INSERT INTO rh.unidades_organizacionais (tenant_id, codigo, nome, descricao, tipo, ativo)
  VALUES (v_tenant_id, 'DIR-PED', 'Direccao Pedagogica', 'Gestao pedagogica da escola', 'direccao', true)
  ON CONFLICT DO NOTHING RETURNING id INTO v_unit_dir;
  IF v_unit_dir IS NULL THEN SELECT id INTO v_unit_dir FROM rh.unidades_organizacionais WHERE tenant_id = v_tenant_id AND codigo = 'DIR-PED'; END IF;

  INSERT INTO rh.unidades_organizacionais (tenant_id, codigo, nome, descricao, tipo, parent_id, ativo)
  VALUES (v_tenant_id, 'CORPO-DOC-PFA', 'Corpo Docente PFA', 'Professores do curso PFA', 'departamento', v_unit_dir, true)
  ON CONFLICT DO NOTHING RETURNING id INTO v_unit_docente;
  IF v_unit_docente IS NULL THEN SELECT id INTO v_unit_docente FROM rh.unidades_organizacionais WHERE tenant_id = v_tenant_id AND codigo = 'CORPO-DOC-PFA'; END IF;

  -- Horario de trabalho
  INSERT INTO rh.horarios_trabalho (tenant_id, codigo, nome, descricao, hora_entrada, hora_saida, intervalo_inicio, intervalo_fim, dias_semana, carga_semanal_horas, ativo)
  VALUES (v_tenant_id, 'ESCOLA-8H', 'Horario Escolar 7h30-15h30', 'Horario normal do corpo docente', '07:30', '15:30', '12:00', '13:00', '1,2,3,4,5', 40, true)
  ON CONFLICT DO NOTHING RETURNING id INTO v_horario;
  IF v_horario IS NULL THEN SELECT id INTO v_horario FROM rh.horarios_trabalho WHERE tenant_id = v_tenant_id AND codigo = 'ESCOLA-8H'; END IF;

  -- Componentes salariais
  INSERT INTO rh.componentes_salariais (tenant_id, codigo, nome, tipo, forma_calculo, valor_padrao, ativo)
  VALUES (v_tenant_id, 'INSS', 'INSS Trabalhador', 'desconto', 'percentual', 3, true)
  ON CONFLICT DO NOTHING RETURNING id INTO v_comp_inss;
  IF v_comp_inss IS NULL THEN SELECT id INTO v_comp_inss FROM rh.componentes_salariais WHERE tenant_id = v_tenant_id AND codigo = 'INSS'; END IF;

  INSERT INTO rh.componentes_salariais (tenant_id, codigo, nome, tipo, forma_calculo, valor_padrao, ativo)
  VALUES (v_tenant_id, 'IRPS', 'IRPS', 'desconto', 'percentual', 10, true)
  ON CONFLICT DO NOTHING RETURNING id INTO v_comp_irps;
  IF v_comp_irps IS NULL THEN SELECT id INTO v_comp_irps FROM rh.componentes_salariais WHERE tenant_id = v_tenant_id AND codigo = 'IRPS'; END IF;

  INSERT INTO rh.componentes_salariais (tenant_id, codigo, nome, tipo, forma_calculo, valor_padrao, ativo)
  VALUES (v_tenant_id, 'SUBS-ALIM', 'Subsidio de Alimentacao', 'provento', 'fixo', 2500, true)
  ON CONFLICT DO NOTHING RETURNING id INTO v_comp_subs_alim;
  IF v_comp_subs_alim IS NULL THEN SELECT id INTO v_comp_subs_alim FROM rh.componentes_salariais WHERE tenant_id = v_tenant_id AND codigo = 'SUBS-ALIM'; END IF;

  INSERT INTO rh.componentes_salariais (tenant_id, codigo, nome, tipo, forma_calculo, valor_padrao, ativo)
  VALUES (v_tenant_id, 'SUBS-TRANS', 'Subsidio de Transporte', 'provento', 'fixo', 1800, true)
  ON CONFLICT DO NOTHING RETURNING id INTO v_comp_subs_trans;
  IF v_comp_subs_trans IS NULL THEN SELECT id INTO v_comp_subs_trans FROM rh.componentes_salariais WHERE tenant_id = v_tenant_id AND codigo = 'SUBS-TRANS'; END IF;

  INSERT INTO rh.componentes_salariais (tenant_id, codigo, nome, tipo, forma_calculo, valor_padrao, ativo)
  VALUES (v_tenant_id, 'BONUS', 'Bonus Mensal', 'provento', 'fixo', 3000, true)
  ON CONFLICT DO NOTHING RETURNING id INTO v_comp_bonus;
  IF v_comp_bonus IS NULL THEN SELECT id INTO v_comp_bonus FROM rh.componentes_salariais WHERE tenant_id = v_tenant_id AND codigo = 'BONUS'; END IF;

  INSERT INTO rh.componentes_salariais (tenant_id, codigo, nome, tipo, forma_calculo, valor_padrao, ativo)
  VALUES (v_tenant_id, 'HX-50', 'Horas Extras 50%', 'provento', 'fixo', 0, true)
  ON CONFLICT DO NOTHING RETURNING id INTO v_comp_horas_extra;
  IF v_comp_horas_extra IS NULL THEN SELECT id INTO v_comp_horas_extra FROM rh.componentes_salariais WHERE tenant_id = v_tenant_id AND codigo = 'HX-50'; END IF;

  INSERT INTO rh.componentes_salariais (tenant_id, codigo, nome, tipo, forma_calculo, valor_padrao, ativo)
  VALUES (v_tenant_id, 'DESC-FALTA', 'Desconto por Faltas', 'desconto', 'fixo', 0, true)
  ON CONFLICT DO NOTHING RETURNING id INTO v_comp_faltas;
  IF v_comp_faltas IS NULL THEN SELECT id INTO v_comp_faltas FROM rh.componentes_salariais WHERE tenant_id = v_tenant_id AND codigo = 'DESC-FALTA'; END IF;

  -- Beneficios
  INSERT INTO rh.beneficios (tenant_id, codigo, nome, descricao, ativo)
  VALUES (v_tenant_id, 'SAUDE', 'Plano de Saude', 'Cobertura medica para funcionarios', true)
  ON CONFLICT DO NOTHING RETURNING id INTO v_benef_saude;
  IF v_benef_saude IS NULL THEN SELECT id INTO v_benef_saude FROM rh.beneficios WHERE tenant_id = v_tenant_id AND codigo = 'SAUDE'; END IF;

  INSERT INTO rh.beneficios (tenant_id, codigo, nome, descricao, ativo)
  VALUES (v_tenant_id, 'GYM', 'Ginasio', 'Acesso a ginasio parceiro', true)
  ON CONFLICT DO NOTHING RETURNING id INTO v_benef_gym;
  IF v_benef_gym IS NULL THEN SELECT id INTO v_benef_gym FROM rh.beneficios WHERE tenant_id = v_tenant_id AND codigo = 'GYM'; END IF;

  -- Formacao
  INSERT INTO rh.formacoes (tenant_id, codigo, nome, descricao, categoria, duracao_horas, entidade_formadora, ativo)
  VALUES (v_tenant_id, 'FORM-PFA', 'Formacao Inicial PFA', 'Formacao pedagogica para o curso PFA', 'obrigatoria', 24, 'Instituto Pedagogico', true)
  ON CONFLICT DO NOTHING RETURNING id INTO v_formacao_id;
  IF v_formacao_id IS NULL THEN SELECT id INTO v_formacao_id FROM rh.formacoes WHERE tenant_id = v_tenant_id AND codigo = 'FORM-PFA'; END IF;

  -- Tipos de ausencia
  INSERT INTO rh.tipos_ausencia (tenant_id, codigo, nome, dias_anuais, remunerada, afeta_saldo, ativo)
  VALUES (v_tenant_id, 'FERIAS', 'Ferias Anuais', 22, true, true, true)
  ON CONFLICT DO NOTHING RETURNING id INTO v_tipo_ferias;
  IF v_tipo_ferias IS NULL THEN SELECT id INTO v_tipo_ferias FROM rh.tipos_ausencia WHERE tenant_id = v_tenant_id AND codigo = 'FERIAS'; END IF;

  INSERT INTO rh.tipos_ausencia (tenant_id, codigo, nome, dias_anuais, remunerada, afeta_saldo, ativo)
  VALUES (v_tenant_id, 'DOENCA', 'Licenca por Doenca', 30, true, false, true)
  ON CONFLICT DO NOTHING RETURNING id INTO v_tipo_doenca;
  IF v_tipo_doenca IS NULL THEN SELECT id INTO v_tipo_doenca FROM rh.tipos_ausencia WHERE tenant_id = v_tenant_id AND codigo = 'DOENCA'; END IF;

  -- Folha de pagamento de Junho/2026
  INSERT INTO rh.folhas_pagamento (tenant_id, ano, mes, estado, num_funcionarios, total_proventos, total_descontos, total_liquido)
  VALUES (v_tenant_id, 2026, 6, 'paga', 0, 0, 0, 0)
  ON CONFLICT DO NOTHING RETURNING id INTO v_folha_id;
  IF v_folha_id IS NULL THEN SELECT id INTO v_folha_id FROM rh.folhas_pagamento WHERE tenant_id = v_tenant_id AND ano = 2026 AND mes = 6; END IF;

  -- ============================================================
  -- 2. Atualizar funcionarios e criar dados dependentes
  -- ============================================================
  FOR v_func IN
    SELECT id, numero_funcionario, nome_completo, data_admissao
    FROM rh.funcionarios
    WHERE tenant_id = v_tenant_id
    ORDER BY id
  LOOP
    -- Salario base variavel entre 30000 e 55000
    v_salario := 30000 + ((v_func.id % 25) * 1000);

    -- Atribuir cargo, unidade, horario e salario
    UPDATE rh.funcionarios SET
      cargo_id = CASE
        WHEN v_func.numero_funcionario IN ('PROF-01','PROF-02') THEN v_cargo_dir
        WHEN v_func.numero_funcionario IN ('PROF-03','PROF-04','PROF-05') THEN v_cargo_coord
        ELSE v_cargo_prof
      END,
      unit_id = v_unit_docente,
      horario_id = v_horario,
      salario_base = v_salario,
      tipo_contrato = 'efetivo',
      estado = 'ativo'
    WHERE id = v_func.id;

    -- Contrato
    INSERT INTO rh.contratos (tenant_id, funcionario_id, tipo, funcao, data_inicio, salario, estado)
    VALUES (v_tenant_id, v_func.id, 'efetivo', 'Professor', v_func.data_admissao, v_salario, 'ativo')
    ON CONFLICT DO NOTHING;

    -- Contacto de emergencia
    INSERT INTO rh.contactos_emergencia (tenant_id, funcionario_id, nome, parentesco, telefone, email)
    VALUES (v_tenant_id, v_func.id, 'Familiar ' || v_func.numero_funcionario, 'conjuge', '84' || LPAD((v_func.id % 1000000)::TEXT, 7, '0'), 'emergencia.' || v_func.id || '@nexora.test')
    ON CONFLICT DO NOTHING;

    -- Documento
    INSERT INTO rh.documentos_funcionario (tenant_id, funcionario_id, tipo, numero, data_emissao, data_validade)
    VALUES (v_tenant_id, v_func.id, 'BI', 'BI-' || v_func.numero_funcionario, '2015-01-01', '2030-01-01')
    ON CONFLICT DO NOTHING RETURNING id INTO v_doc_id;

    -- Componentes salariais do funcionario
    INSERT INTO rh.funcionario_componentes_salariais (tenant_id, funcionario_id, componente_id, valor)
    VALUES
      (v_tenant_id, v_func.id, v_comp_subs_alim, 2500),
      (v_tenant_id, v_func.id, v_comp_subs_trans, 1800),
      (v_tenant_id, v_func.id, v_comp_bonus, CASE WHEN v_func.id % 3 = 0 THEN 5000 ELSE 3000 END),
      (v_tenant_id, v_func.id, v_comp_horas_extra, 0)
    ON CONFLICT DO NOTHING;

    -- Saldos de ausencia
    INSERT INTO rh.saldos_ausencia (tenant_id, funcionario_id, tipo_ausencia_id, ano, dias_atribuidos, dias_usados)
    VALUES
      (v_tenant_id, v_func.id, v_tipo_ferias, 2026, 22, 2),
      (v_tenant_id, v_func.id, v_tipo_doenca, 2026, 30, 0)
    ON CONFLICT DO NOTHING;

    -- Presencas dos ultimos 30 dias uteis
    FOR v_dia IN 1..30 LOOP
      v_data := CURRENT_DATE - v_dia;
      -- Apenas dias uteis (1=domingo, 7=sabado)
      IF EXTRACT(DOW FROM v_data) NOT IN (0, 6) THEN
        v_tipo_presenca := CASE
          WHEN v_dia IN (3, 7, 15) THEN 'atraso'
          WHEN v_dia IN (10, 20) THEN 'falta'
          ELSE 'presente'
        END;
        INSERT INTO rh.presencas (tenant_id, funcionario_id, data, hora_entrada, hora_saida, tipo, observacoes)
        VALUES (v_tenant_id, v_func.id, v_data,
          CASE v_tipo_presenca WHEN 'atraso' THEN '08:15' ELSE '07:30' END,
          CASE v_tipo_presenca WHEN 'saida_antecipada' THEN '14:30' ELSE '15:30' END,
          v_tipo_presenca,
          CASE v_tipo_presenca WHEN 'falta' THEN 'Falta nao justificada' WHEN 'atraso' THEN 'Transito' ELSE NULL END)
        ON CONFLICT DO NOTHING;
      END IF;
    END LOOP;

    -- Ausencia de 2 dias de ferias
    INSERT INTO rh.ausencias (tenant_id, funcionario_id, tipo, tipo_id, data_inicio, data_fim, dias, motivo, estado)
    VALUES (v_tenant_id, v_func.id, 'ferias', v_tipo_ferias, '2026-04-10', '2026-04-11', 2, 'Ferias de Pascoa', 'gozada')
    ON CONFLICT DO NOTHING;

    -- Adiantamento para alguns funcionarios
    IF v_func.id % 4 = 0 THEN
      v_adiantamento := ROUND(v_salario * 0.3, 2);
      INSERT INTO rh.adiantamentos (tenant_id, funcionario_id, valor_total, num_prestacoes, prestacao_valor, descricao)
      VALUES (v_tenant_id, v_func.id, v_adiantamento, 1, v_adiantamento, 'Adiantamento salarial')
      ON CONFLICT DO NOTHING;
    END IF;

    -- Emprestimo para alguns funcionarios
    IF v_func.id % 7 = 0 THEN
      v_prestacao := 2500;
      INSERT INTO rh.emprestimos (tenant_id, funcionario_id, valor_total, num_prestacoes, prestacao_valor, taxa_juros, descricao)
      VALUES (v_tenant_id, v_func.id, 25000, 10, v_prestacao, 5, 'Emprestimo habitacao')
      ON CONFLICT DO NOTHING;
    END IF;

    -- Historico salarial
    INSERT INTO rh.historico_salarial (tenant_id, funcionario_id, salario_anterior, salario_novo, data_efectiva, motivo)
    VALUES (v_tenant_id, v_func.id, v_salario - 2000, v_salario, '2026-01-01', 'Revisao anual')
    ON CONFLICT DO NOTHING;

    -- Formacao
    INSERT INTO rh.funcionario_formacoes (tenant_id, funcionario_id, formacao_id, data_inicio, data_fim, estado, nota, observacoes)
    VALUES (v_tenant_id, v_func.id, v_formacao_id, '2026-01-15', '2026-01-17', 'concluida', 16, 'Formacao inicial PFA')
    ON CONFLICT DO NOTHING;

    -- Beneficios
    INSERT INTO rh.funcionario_beneficios (tenant_id, funcionario_id, beneficio_id, valor, data_inicio, observacoes)
    VALUES
      (v_tenant_id, v_func.id, v_benef_saude, 1500, '2026-01-01', 'Plano de saude familiar'),
      (v_tenant_id, v_func.id, v_benef_gym, 500, '2026-01-01', 'Ginasio')
    ON CONFLICT DO NOTHING;

    -- Avaliacao
    INSERT INTO rh.avaliacoes (tenant_id, funcionario_id, periodo, pontuacao, comentarios, estado)
    VALUES (v_tenant_id, v_func.id, '2026-1o Semestre', 15 + (v_func.id % 6), 'Bom desempenho pedagogico', 'aprovada')
    ON CONFLICT DO NOTHING;

    -- Recibo de vencimento
    v_total_proventos := v_salario + 2500 + 1800 + CASE WHEN v_func.id % 3 = 0 THEN 5000 ELSE 3000 END;
    v_total_descontos := ROUND(v_salario * 0.13, 2); -- INSS 3% + IRPS 10%
    v_liquido := v_total_proventos - v_total_descontos;

    INSERT INTO rh.recibos_vencimento (tenant_id, folha_id, funcionario_id, salario_base, total_proventos, total_descontos, salario_liquido, estado)
    VALUES (v_tenant_id, v_folha_id, v_func.id, v_salario, v_total_proventos, v_total_descontos, v_liquido, 'pago')
    ON CONFLICT DO NOTHING RETURNING id INTO v_recibo_id;

    IF v_recibo_id IS NOT NULL THEN
      INSERT INTO rh.recibo_vencimento_itens (recibo_id, componente_id, nome, tipo, valor)
      VALUES
        (v_recibo_id, NULL, 'Salario Base', 'provento', v_salario),
        (v_recibo_id, v_comp_subs_alim, 'Subsidio de Alimentacao', 'provento', 2500),
        (v_recibo_id, v_comp_subs_trans, 'Subsidio de Transporte', 'provento', 1800),
        (v_recibo_id, v_comp_bonus, 'Bonus Mensal', 'provento', CASE WHEN v_func.id % 3 = 0 THEN 5000 ELSE 3000 END),
        (v_recibo_id, v_comp_inss, 'INSS', 'desconto', ROUND(v_salario * 0.03, 2)),
        (v_recibo_id, v_comp_irps, 'IRPS', 'desconto', ROUND(v_salario * 0.10, 2))
      ON CONFLICT DO NOTHING;
    END IF;
  END LOOP;

  -- Actualizar totais da folha
  UPDATE rh.folhas_pagamento SET
    num_funcionarios = (SELECT COUNT(*) FROM rh.recibos_vencimento WHERE folha_id = v_folha_id),
    total_proventos = (SELECT COALESCE(SUM(total_proventos), 0) FROM rh.recibos_vencimento WHERE folha_id = v_folha_id),
    total_descontos = (SELECT COALESCE(SUM(total_descontos), 0) FROM rh.recibos_vencimento WHERE folha_id = v_folha_id),
    total_liquido = (SELECT COALESCE(SUM(salario_liquido), 0) FROM rh.recibos_vencimento WHERE folha_id = v_folha_id)
  WHERE id = v_folha_id;

END $$;
