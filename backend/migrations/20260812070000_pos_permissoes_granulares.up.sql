-- Granulariza as permissões do módulo POS e adiciona cargos-padrão específicos.
--
-- As ações antigas (ver/criar/editar/relatorios) são convertidas para as novas
-- ações finas que o router Go realmente verifica. Cargos já configurados com
-- permissões POS específicas (operar_pos, supervisionar_pos, gerir_terminais,
-- etc.) não são alterados — a migração apenas garante que nenhum cargo fique
-- sem as novas ações equivalentes às antigas.

SET search_path TO auth, public;

-- ═══════════════════════════════════════════════════════════════════════════════
-- 1. Conversão de permissões POS antigas → novas ações finas
-- ═══════════════════════════════════════════════════════════════════════════════

-- ver → ver (consulta de sessões/vendas próprias e relatórios básicos)
INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
SELECT DISTINCT pc.cargo_id, 'pos', 'ver'
  FROM auth.permissoes_cargo pc
 WHERE pc.modulo = 'pos' AND pc.acao = 'ver'
   AND NOT EXISTS (
       SELECT 1 FROM auth.permissoes_cargo ex
        WHERE ex.cargo_id = pc.cargo_id AND ex.modulo = 'pos' AND ex.acao = 'ver'
   )
ON CONFLICT DO NOTHING;

-- criar → operar o terminal de venda (abrir sessão, registar venda, etc.)
INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
SELECT DISTINCT pc.cargo_id, 'pos', a.acao
  FROM auth.permissoes_cargo pc
 CROSS JOIN (VALUES
     ('operar_pos'),
     ('abrir_sessao'),
     ('fechar_sessao'),
     ('registar_venda'),
     ('processar_devolucao'),
     ('movimentar_caixa'),
     ('aplicar_desconto')
 ) AS a(acao)
 WHERE pc.modulo = 'pos' AND pc.acao = 'criar'
ON CONFLICT DO NOTHING;

-- editar → cancelar venda (ação de correção dentro do próprio turno)
INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
SELECT DISTINCT pc.cargo_id, 'pos', 'cancelar_venda'
  FROM auth.permissoes_cargo pc
 WHERE pc.modulo = 'pos' AND pc.acao = 'editar'
   AND NOT EXISTS (
       SELECT 1 FROM auth.permissoes_cargo ex
        WHERE ex.cargo_id = pc.cargo_id AND ex.modulo = 'pos' AND ex.acao = 'cancelar_venda'
   )
ON CONFLICT DO NOTHING;

-- relatorios → relatórios, supervisionar e fechar sessão de outro (supervisor)
INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
SELECT DISTINCT pc.cargo_id, 'pos', a.acao
  FROM auth.permissoes_cargo pc
 CROSS JOIN (VALUES
     ('relatorios'),
     ('supervisionar'),
     ('fechar_outra_sessao')
 ) AS a(acao)
 WHERE pc.modulo = 'pos' AND pc.acao = 'relatorios'
ON CONFLICT DO NOTHING;

-- Remove as ações antigas do módulo pos (não são mais usadas pelo router).
DELETE FROM auth.permissoes_cargo
 WHERE modulo = 'pos' AND acao IN ('criar', 'editar', 'apagar');

-- Mantém 'ver' porque ainda é uma ação válida no novo modelo.

-- ═══════════════════════════════════════════════════════════════════════════════
-- 2. Criação de cargos-padrão POS para tenants existentes
-- ═══════════════════════════════════════════════════════════════════════════════

DO $$
DECLARE
    v_tenant_id BIGINT;
    v_cargo_id  BIGINT;
BEGIN
    FOR v_tenant_id IN
        SELECT t.id FROM saas.tenants t
         WHERE EXISTS (
             SELECT 1 FROM auth.cargos c WHERE c.tenant_id = t.id
         )
    LOOP
        -- Operador de Caixa
        INSERT INTO auth.cargos (tenant_id, nome, descricao)
        VALUES (v_tenant_id, 'Operador de Caixa', 'Opera o terminal de venda, abre e fecha a própria sessão.')
        ON CONFLICT (tenant_id, nome) DO UPDATE SET descricao = EXCLUDED.descricao
        RETURNING id INTO v_cargo_id;

        INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
            (v_cargo_id, 'pos', 'operar_pos'),
            (v_cargo_id, 'pos', 'abrir_sessao'),
            (v_cargo_id, 'pos', 'fechar_sessao'),
            (v_cargo_id, 'pos', 'registar_venda'),
            (v_cargo_id, 'pos', 'processar_devolucao'),
            (v_cargo_id, 'pos', 'movimentar_caixa'),
            (v_cargo_id, 'pos', 'aplicar_desconto')
        ON CONFLICT DO NOTHING;

        -- Caixa Sénior
        INSERT INTO auth.cargos (tenant_id, nome, descricao)
        VALUES (v_tenant_id, 'Caixa Sénior', 'Opera o terminal e pode cancelar vendas.')
        ON CONFLICT (tenant_id, nome) DO UPDATE SET descricao = EXCLUDED.descricao
        RETURNING id INTO v_cargo_id;

        INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
            (v_cargo_id, 'pos', 'operar_pos'),
            (v_cargo_id, 'pos', 'abrir_sessao'),
            (v_cargo_id, 'pos', 'fechar_sessao'),
            (v_cargo_id, 'pos', 'registar_venda'),
            (v_cargo_id, 'pos', 'cancelar_venda'),
            (v_cargo_id, 'pos', 'processar_devolucao'),
            (v_cargo_id, 'pos', 'movimentar_caixa'),
            (v_cargo_id, 'pos', 'aplicar_desconto')
        ON CONFLICT DO NOTHING;

        -- Supervisor POS
        INSERT INTO auth.cargos (tenant_id, nome, descricao)
        VALUES (v_tenant_id, 'Supervisor POS', 'Supervisiona caixas, gera relatórios e pode fechar sessões de outros.')
        ON CONFLICT (tenant_id, nome) DO UPDATE SET descricao = EXCLUDED.descricao
        RETURNING id INTO v_cargo_id;

        INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
            (v_cargo_id, 'pos', 'ver'),
            (v_cargo_id, 'pos', 'relatorios'),
            (v_cargo_id, 'pos', 'supervisionar'),
            (v_cargo_id, 'pos', 'fechar_outra_sessao')
        ON CONFLICT DO NOTHING;

        -- Administrador POS
        INSERT INTO auth.cargos (tenant_id, nome, descricao)
        VALUES (v_tenant_id, 'Administrador POS', 'Configura terminais, catálogo e descontos do POS.')
        ON CONFLICT (tenant_id, nome) DO UPDATE SET descricao = EXCLUDED.descricao
        RETURNING id INTO v_cargo_id;

        INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
            (v_cargo_id, 'pos', 'gerir_terminais'),
            (v_cargo_id, 'pos', 'gerir_catalogo'),
            (v_cargo_id, 'pos', 'gerir_descontos'),
            (v_cargo_id, 'pos', 'configurar')
        ON CONFLICT DO NOTHING;
    END LOOP;
END $$;

