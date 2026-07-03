-- Preenche campos nulos em rh.funcionarios do tenant 5
-- e cria um centro de custo padrao para a escola.

DO $$
DECLARE
  v_tenant_id BIGINT := 5;
  v_centro_custo_id BIGINT;
  v_func RECORD;
  v_generos TEXT[] := ARRAY['M', 'F'];
  v_bairros TEXT[] := ARRAY['Polana', 'Sommerschield', 'Coop', 'Malhangalene', 'Alto Mae', 'Bagamoyo', 'Mafalala', 'Inhagoia', 'Jardim', 'Zimpeto'];
  v_idx INT := 0;
  v_idade INT;
  v_data_nasc DATE;
BEGIN
  -- Criar centro de custo padrao
  INSERT INTO centros_custo.cost_centers (tenant_id, codigo, nome, tipo, activo)
  VALUES (v_tenant_id, 'ESCOLA-PFA', 'Escola PFA - Corpo Docente', 'departamento', true)
  ON CONFLICT DO NOTHING RETURNING id INTO v_centro_custo_id;
  IF v_centro_custo_id IS NULL THEN
    SELECT id INTO v_centro_custo_id FROM centros_custo.cost_centers WHERE tenant_id = v_tenant_id AND codigo = 'ESCOLA-PFA';
  END IF;

  FOR v_func IN
    SELECT id, nome_completo, numero_funcionario
    FROM rh.funcionarios
    WHERE tenant_id = v_tenant_id
    ORDER BY id
  LOOP
    v_idx := v_idx + 1;
    v_idade := 25 + (v_func.id % 30); -- idade entre 25 e 54 anos
    v_data_nasc := DATE '2026-01-01' - ((v_idade * 365) + ((v_func.id * 17) % 365))::int;

    UPDATE rh.funcionarios SET
      data_nascimento = v_data_nasc,
      endereco = 'Avenida ' || v_bairros[1 + (v_func.id % 10)] || ', nr ' || (100 + v_func.id),
      provincia = 'Maputo',
      cidade = 'Maputo',
      bairro = v_bairros[1 + (v_func.id % 10)],
      centro_custo_id = v_centro_custo_id
    WHERE id = v_func.id;
  END LOOP;

  -- Corrigir genero com base em nomes tipicamente masculinos
  UPDATE rh.funcionarios
  SET genero = 'M'
  WHERE tenant_id = v_tenant_id
    AND nome_completo ~* '(^| )(Antonio|Carlos|Domingos|João|António|Hélder|Paulo|Francisco|Benedito|Estêvão|Simão|Augusto|Horácio|Salomão|Tomás|Abílio|Machel|Mondlane|Cuambe|Cumbe|Chissano|Chivambo|Nhacolo|Cossa|Nhabanga|Sitole|Mutemba|Nhantumbo)( |$)';

  -- Os restantes ficam com genero F
  UPDATE rh.funcionarios
  SET genero = 'F'
  WHERE tenant_id = v_tenant_id AND genero IS NULL;
END $$;
