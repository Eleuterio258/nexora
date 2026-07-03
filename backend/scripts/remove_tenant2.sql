-- Remove todos os dados do tenant 2 (Nexora Demo Lda)
-- AVISO: Operacao destrutiva. Fazer backup antes de executar.

DO $$
DECLARE
  v_tenant_id BIGINT := 2;
  r RECORD;
  v_sql TEXT;
  v_count INT;
BEGIN
  -- Desabilitar triggers em todas as tabelas de negocio
  FOR r IN
    SELECT table_schema, table_name
    FROM information_schema.tables
    WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
      AND table_type = 'BASE TABLE'
      AND table_schema NOT LIKE 'pg_%'
  LOOP
    v_sql := format('ALTER TABLE %I.%I DISABLE TRIGGER ALL', r.table_schema, r.table_name);
    EXECUTE v_sql;
  END LOOP;

  -- Apagar registos do tenant 2 em todas as tabelas com coluna tenant_id
  FOR r IN
    SELECT c.table_schema, c.table_name
    FROM information_schema.columns c
    JOIN information_schema.tables t
      ON t.table_schema = c.table_schema AND t.table_name = c.table_name
    WHERE c.column_name = 'tenant_id'
      AND t.table_type = 'BASE TABLE'
      AND c.table_schema NOT IN ('pg_catalog', 'information_schema')
    ORDER BY c.table_schema, c.table_name
  LOOP
    v_sql := format('DELETE FROM %I.%I WHERE tenant_id = %s', r.table_schema, r.table_name, v_tenant_id);
    EXECUTE v_sql;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    IF v_count > 0 THEN
      RAISE NOTICE 'Apagados % registos de %.%', v_count, r.table_schema, r.table_name;
    END IF;
  END LOOP;

  -- Apagar o tenant
  DELETE FROM saas.tenants WHERE id = v_tenant_id;

  -- Reabilitar triggers
  FOR r IN
    SELECT table_schema, table_name
    FROM information_schema.tables
    WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
      AND table_type = 'BASE TABLE'
      AND table_schema NOT LIKE 'pg_%'
  LOOP
    v_sql := format('ALTER TABLE %I.%I ENABLE TRIGGER ALL', r.table_schema, r.table_name);
    EXECUTE v_sql;
  END LOOP;

  RAISE NOTICE 'Tenant % removido com sucesso.', v_tenant_id;
END $$;
