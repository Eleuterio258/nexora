-- 107_currencies_unification.up.sql
-- Resolve a duplicação de schemas de moedas:
--   sistema_configuracao.currencies  → lista global, sem tenant, sem decimals
--   multi_moeda.currencies           → lista multi-tenant, com decimals, fonte canónica
--
-- Convenção estabelecida:
--   multi_moeda.currencies é a fonte autoritária para operações financeiras.
--   sistema_configuracao.currencies mantém-se para configuração de plataforma (2 moedas base).
--
-- Acção: garantir que todas as moedas de sistema_configuracao existem em multi_moeda,
--        e criar uma view de consulta unificada.

-- 1. Sincronizar moedas ausentes de sistema_configuracao para multi_moeda (tenant_id=NULL = global)
INSERT INTO multi_moeda.currencies (code, name, symbol, decimals, active)
SELECT sc.codigo, sc.nome, sc.simbolo, 2, sc.ativa
  FROM sistema_configuracao.currencies sc
 WHERE NOT EXISTS (
     SELECT 1 FROM multi_moeda.currencies mc WHERE mc.code = sc.codigo
 );

-- 2. View unificada — consultas podem usar esta view sem preocupações com schema
CREATE OR REPLACE VIEW sistema_configuracao.v_currencies AS
SELECT
    mc.id,
    mc.code                        AS codigo,
    mc.name                        AS nome,
    mc.symbol                      AS simbolo,
    mc.decimals,
    mc.active                      AS ativa,
    CASE WHEN sc.id IS NOT NULL
         THEN TRUE ELSE FALSE END  AS is_sistema_config
  FROM multi_moeda.currencies mc
  LEFT JOIN sistema_configuracao.currencies sc ON sc.codigo = mc.code;

COMMENT ON VIEW sistema_configuracao.v_currencies IS
    'Vista unificada de moedas. Fonte canónica: multi_moeda.currencies. '
    'is_sistema_config=true indica moedas também presentes na configuração global de plataforma.';

-- 3. Documentar convenção nas tabelas originais
COMMENT ON TABLE sistema_configuracao.currencies IS
    'Moedas de referência global da plataforma (MZN, USD). '
    'Para operações financeiras multi-tenant usar multi_moeda.currencies ou v_currencies.';

COMMENT ON TABLE multi_moeda.currencies IS
    'Fonte canónica de moedas para operações financeiras multi-tenant. '
    'Inclui decimais e suporte a múltiplos tenants.';
