# Modulo Centros de Custo

## Objetivo

Rastrear receitas e despesas por centro de custo, permitindo analise de rentabilidade por departamento, projecto ou area de negocio.

## Escopo

- Hierarquia de centros de custo (pai/filho)
- Orcamento por centro de custo e periodo fiscal
- Alocacao de lancamentos contabilisticos a centros de custo
- Movimentos e relatorio orcado vs realizado

## Entidades

- `cost_centers`
- `cost_center_budgets`
- `cost_center_allocations`
- `cost_center_movements`

## Dependencias

- Depende de: `empresas` (tenant_id)
- Depende de: `contabilidade` (fiscal_period_id, journal_entry_line_id)
- Alimentado por: `modulo-faturacao`, `compras`, `recursos-humanos`

## Arquivos

- `database-centros-custo.sql`
- `api-centros-custo.md`
- `requisitos.md`
- `uml.md`
