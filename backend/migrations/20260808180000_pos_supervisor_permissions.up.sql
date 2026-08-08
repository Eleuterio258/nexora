-- Introduz permissão pos:supervisionar_pos para acções sensíveis do POS
-- (cancelar vendas, estornos parciais, movimentos de caixa) e cria os cargos
-- padrão "Supervisor POS" e "Gerente de Loja".
--
-- Em vez de redefinir auth.criar_cargos_padrao() por completo, usamos uma
-- trigger em auth.cargos: sempre que um cargo "Administrador" é criado num
-- tenant, o sistema garante os cargos POS de supervisão para esse tenant.

SET search_path TO auth, public;

-- ═════════════════════════════════════════════════════════════════════════════
-- 1. FUNÇÃO AUXILIAR: garante cargos POS de supervisão num tenant
-- ═════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION auth.garantir_cargos_pos_padrao(p_tenant_id BIGINT)
RETURNS void
LANGUAGE plpgsql AS
$$
DECLARE
    v_admin_id      BIGINT;
    v_supervisor_id BIGINT;
    v_gerente_id    BIGINT;
BEGIN
    -- Localiza o cargo Administrador do tenant para adicionar supervisionar_pos
    SELECT id INTO v_admin_id
      FROM auth.cargos
     WHERE tenant_id = p_tenant_id AND nome = 'Administrador'
     LIMIT 1;

    IF v_admin_id IS NOT NULL THEN
        INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
            (v_admin_id, 'pos', 'supervisionar_pos')
        ON CONFLICT DO NOTHING;
    END IF;

    -- Cargo Supervisor POS
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Supervisor POS',
            'Supervisiona operações de caixa: cancelamentos, estornos e movimentos de caixa.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET descricao = EXCLUDED.descricao
    RETURNING id INTO v_supervisor_id;

    IF v_supervisor_id IS NOT NULL THEN
        INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
            (v_supervisor_id, 'pos', 'operar_pos'),
            (v_supervisor_id, 'pos', 'ver_vendas'),
            (v_supervisor_id, 'pos', 'supervisionar_pos')
        ON CONFLICT DO NOTHING;
    END IF;

    -- Cargo Gerente de Loja
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Gerente de Loja',
            'Gestão completa do ponto de venda, incluindo supervisão, terminais, catálogo, descontos e relatórios.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET descricao = EXCLUDED.descricao
    RETURNING id INTO v_gerente_id;

    IF v_gerente_id IS NOT NULL THEN
        INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
            (v_gerente_id, 'pos', 'operar_pos'),
            (v_gerente_id, 'pos', 'ver_vendas'),
            (v_gerente_id, 'pos', 'supervisionar_pos'),
            (v_gerente_id, 'pos', 'gerir_terminais'),
            (v_gerente_id, 'pos', 'gerir_catalogo'),
            (v_gerente_id, 'pos', 'gerir_descontos'),
            (v_gerente_id, 'pos', 'relatorios')
        ON CONFLICT DO NOTHING;
    END IF;
END;
$$;

-- ═════════════════════════════════════════════════════════════════════════════
-- 2. TRIGGER: quando nasce um Administrador, garante cargos POS de supervisão
-- ═════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION auth.trigger_garantir_cargos_pos_padrao()
RETURNS trigger
LANGUAGE plpgsql AS
$$
BEGIN
    IF NEW.nome = 'Administrador' THEN
        PERFORM auth.garantir_cargos_pos_padrao(NEW.tenant_id);
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_garantir_cargos_pos_padrao ON auth.cargos;

CREATE TRIGGER trg_garantir_cargos_pos_padrao
    AFTER INSERT ON auth.cargos
    FOR EACH ROW
    WHEN (NEW.nome = 'Administrador')
    EXECUTE FUNCTION auth.trigger_garantir_cargos_pos_padrao();

-- ═════════════════════════════════════════════════════════════════════════════
-- 3. BACKFILL: aplica a helper a todos os tenants existentes
-- ═════════════════════════════════════════════════════════════════════════════

DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN SELECT id FROM saas.tenants LOOP
        PERFORM auth.garantir_cargos_pos_padrao(r.id);
    END LOOP;
END $$;
