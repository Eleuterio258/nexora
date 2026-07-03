-- Preenche campos nulos em rh.funcionarios do tenant 2
DO $$
DECLARE
  v_tenant_id BIGINT := 2;
  v_centro_custo_id BIGINT;
  v_cargo_outros BIGINT;
  v_func RECORD;
  v_bairros TEXT[] := ARRAY['Polana', 'Sommerschield', 'Coop', 'Malhangalene', 'Alto Mae', 'Bagamoyo', 'Mafalala', 'Inhagoia', 'Jardim', 'Zimpeto', 'Central', 'Fomento', 'Bairro 3'];
BEGIN
  -- Criar centro de custo padrao para empresa demo
  INSERT INTO centros_custo.cost_centers (tenant_id, codigo, nome, tipo, activo)
  VALUES (v_tenant_id, 'EMPRESA-DEMO', 'Empresa Demo - Sede', 'departamento', true)
  ON CONFLICT DO NOTHING RETURNING id INTO v_centro_custo_id;
  IF v_centro_custo_id IS NULL THEN
    SELECT id INTO v_centro_custo_id FROM centros_custo.cost_centers WHERE tenant_id = v_tenant_id AND codigo = 'EMPRESA-DEMO';
  END IF;

  -- Cargo generico para o funcionario sem cargo
  SELECT id INTO v_cargo_outros FROM rh.cargos WHERE tenant_id = v_tenant_id ORDER BY id LIMIT 1;

  FOR v_func IN
    SELECT id, endereco
    FROM rh.funcionarios
    WHERE tenant_id = v_tenant_id
  LOOP
    UPDATE rh.funcionarios SET
      cargo = COALESCE(cargo, 'Colaborador'),
      provincia = COALESCE(provincia, 'Maputo'),
      cidade = COALESCE(cidade, 'Maputo'),
      bairro = COALESCE(bairro, v_bairros[1 + (v_func.id % 13)]),
      centro_custo_id = COALESCE(centro_custo_id, v_centro_custo_id)
    WHERE id = v_func.id;
  END LOOP;
END $$;
