-- Fase 3 — Permissões granulares adicionais
-- Adiciona novas ações finas que o router passa a verificar e faz backfill
-- idempotente nos cargos padrão de todos os tenants existentes.

SET search_path TO auth, public;

BEGIN;

-- ═════════════════════════════════════════════════════════════════════════════
-- 1. NOVAS PERMISSÕES NOS CARGOS PADRÃO EXISTENTES
-- ═════════════════════════════════════════════════════════════════════════════

-- CRM: ver atividades (separar do ver_leads)
INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
SELECT c.id, 'crm', 'ver_atividades'
  FROM auth.cargos c
 WHERE c.nome IN (
     'Administrador', 'Director Comercial', 'Gestor de Conta', 'Técnico Comercial'
 )
ON CONFLICT DO NOTHING;

-- CRM: eliminar oportunidades (separar do eliminar_leads)
INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
SELECT c.id, 'crm', 'eliminar_oportunidades'
  FROM auth.cargos c
 WHERE c.nome IN (
     'Administrador', 'Director Comercial'
 )
ON CONFLICT DO NOTHING;

-- Faturação: cancelar documentos
INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
SELECT c.id, 'faturacao', 'cancelar_documentos'
  FROM auth.cargos c
 WHERE c.nome IN (
     'Administrador', 'Director Financeiro', 'Responsável de Faturação'
 )
ON CONFLICT DO NOTHING;

-- Compras: receber mercadoria, gerir devoluções, faturar compras, gerir pagamentos
INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
SELECT c.id, 'compras', 'receber_mercadoria'
  FROM auth.cargos c
 WHERE c.nome IN (
     'Administrador'
 )
ON CONFLICT DO NOTHING;

INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
SELECT c.id, 'compras', 'gerir_devolucoes'
  FROM auth.cargos c
 WHERE c.nome IN (
     'Administrador'
 )
ON CONFLICT DO NOTHING;

INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
SELECT c.id, 'compras', 'faturar_compras'
  FROM auth.cargos c
 WHERE c.nome IN (
     'Administrador', 'Director Financeiro'
 )
ON CONFLICT DO NOTHING;

INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
SELECT c.id, 'compras', 'gerir_pagamentos'
  FROM auth.cargos c
 WHERE c.nome IN (
     'Administrador', 'Director Financeiro'
 )
ON CONFLICT DO NOTHING;

-- Contabilidade: estornar lançamentos, reabrir período, fechar ano fiscal
INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
SELECT c.id, 'contabilidade', 'estornar_lancamentos'
  FROM auth.cargos c
 WHERE c.nome IN (
     'Administrador', 'Director Financeiro', 'Contabilista'
 )
ON CONFLICT DO NOTHING;

INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
SELECT c.id, 'contabilidade', 'reabrir_periodo'
  FROM auth.cargos c
 WHERE c.nome IN (
     'Administrador', 'Director Financeiro'
 )
ON CONFLICT DO NOTHING;

INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
SELECT c.id, 'contabilidade', 'fechar_ano_fiscal'
  FROM auth.cargos c
 WHERE c.nome IN (
     'Administrador', 'Director Financeiro'
 )
ON CONFLICT DO NOTHING;

-- Tesouraria: gerir contas (contas bancárias e caixas)
INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
SELECT c.id, 'tesouraria', 'gerir_contas'
  FROM auth.cargos c
 WHERE c.nome IN (
     'Administrador', 'Director Financeiro', 'Tesoureiro'
 )
ON CONFLICT DO NOTHING;

-- Recursos Humanos: desligar funcionários
INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
SELECT c.id, 'recursos-humanos', 'desligar_funcionarios'
  FROM auth.cargos c
 WHERE c.nome IN (
     'Administrador', 'Director de RH', 'Gestor de RH'
 )
ON CONFLICT DO NOTHING;

-- ═════════════════════════════════════════════════════════════════════════════
-- 2. SINCRONIZAR auth.criar_cargos_padrao() PARA FUTUROS TENANTS
-- ═════════════════════════════════════════════════════════════════════════════
-- Em vez de recriar a função completa (1400+ linhas), acrescentamos as novas
-- permissões logo após a chamada à função nos tenants criados futuramente.
-- Criamos uma função auxiliar que a função principal pode invocar.

CREATE OR REPLACE FUNCTION auth.adicionar_permissoes_granulares_fase3(p_tenant_id BIGINT)
RETURNS void
LANGUAGE plpgsql AS
$$
BEGIN
    -- CRM
    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
    SELECT c.id, 'crm', 'ver_atividades'
      FROM auth.cargos c
     WHERE c.tenant_id = p_tenant_id
       AND c.nome IN ('Administrador', 'Director Comercial', 'Gestor de Conta', 'Técnico Comercial')
    ON CONFLICT DO NOTHING;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
    SELECT c.id, 'crm', 'eliminar_oportunidades'
      FROM auth.cargos c
     WHERE c.tenant_id = p_tenant_id
       AND c.nome IN ('Administrador', 'Director Comercial')
    ON CONFLICT DO NOTHING;

    -- Faturação
    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
    SELECT c.id, 'faturacao', 'cancelar_documentos'
      FROM auth.cargos c
     WHERE c.tenant_id = p_tenant_id
       AND c.nome IN ('Administrador', 'Director Financeiro', 'Responsável de Faturação')
    ON CONFLICT DO NOTHING;

    -- Compras
    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
    SELECT c.id, 'compras', novo.acao
      FROM auth.cargos c
     CROSS JOIN LATERAL (VALUES
         ('receber_mercadoria'),
         ('gerir_devolucoes')
     ) AS novo(acao)
     WHERE c.tenant_id = p_tenant_id
       AND c.nome = 'Administrador'
    ON CONFLICT DO NOTHING;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
    SELECT c.id, 'compras', novo.acao
      FROM auth.cargos c
     CROSS JOIN LATERAL (VALUES
         ('faturar_compras'),
         ('gerir_pagamentos')
     ) AS novo(acao)
     WHERE c.tenant_id = p_tenant_id
       AND c.nome IN ('Administrador', 'Director Financeiro')
    ON CONFLICT DO NOTHING;

    -- Contabilidade
    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
    SELECT c.id, 'contabilidade', 'estornar_lancamentos'
      FROM auth.cargos c
     WHERE c.tenant_id = p_tenant_id
       AND c.nome IN ('Administrador', 'Director Financeiro', 'Contabilista')
    ON CONFLICT DO NOTHING;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
    SELECT c.id, 'contabilidade', novo.acao
      FROM auth.cargos c
     CROSS JOIN LATERAL (VALUES
         ('reabrir_periodo'),
         ('fechar_ano_fiscal')
     ) AS novo(acao)
     WHERE c.tenant_id = p_tenant_id
       AND c.nome IN ('Administrador', 'Director Financeiro')
    ON CONFLICT DO NOTHING;

    -- Tesouraria
    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
    SELECT c.id, 'tesouraria', 'gerir_contas'
      FROM auth.cargos c
     WHERE c.tenant_id = p_tenant_id
       AND c.nome IN ('Administrador', 'Director Financeiro', 'Tesoureiro')
    ON CONFLICT DO NOTHING;

    -- RH
    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
    SELECT c.id, 'recursos-humanos', 'desligar_funcionarios'
      FROM auth.cargos c
     WHERE c.tenant_id = p_tenant_id
       AND c.nome IN ('Administrador', 'Director de RH', 'Gestor de RH')
    ON CONFLICT DO NOTHING;
END;
$$;

-- ═════════════════════════════════════════════════════════════════════════════
-- 3. APLICAR A TODOS OS TENANTS EXISTENTES (garantia extra de idempotência)
-- ═════════════════════════════════════════════════════════════════════════════

DO $$
DECLARE
    v_tenant_id BIGINT;
BEGIN
    FOR v_tenant_id IN
        SELECT id FROM saas.tenants
    LOOP
        PERFORM auth.adicionar_permissoes_granulares_fase3(v_tenant_id);
    END LOOP;
END;
$$;

COMMIT;
