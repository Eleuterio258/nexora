# Modulo Impostos Avancados

## Objetivo

Gerir isencoes de impostos, retencoes na fonte, declaracoes fiscais periodicas e certificados de contribuinte.

## Escopo

- Regimes fiscais por tenant
- Isencoes de IVA por cliente, fornecedor, produto ou categoria
- Retencoes na fonte (IRPS, IRPC) com calculo automatico
- Declaracoes fiscais periodicas (IVA, IRPS, Retencoes)
- Certificados de bom contribuinte e isencao

## Nota sobre contabilidade
As tabelas `taxes`, `tax_groups`, `tax_rules` e `tax_transactions` pertencem ao modulo `contabilidade`.
Este modulo complementa com isencoes, retencoes, declaracoes e certificados.

## Entidades

- `tax_regimes`
- `tax_exemptions`
- `withholding_taxes`
- `withholding_tax_transactions`
- `tax_returns`
- `tax_return_lines`
- `tax_certificates`

## Dependencias

- Depende de: `contabilidade` (taxes, fiscal_period_id)
- Depende de: `gestao-clientes` (customer isencoes)
- Depende de: `compras` (supplier isencoes, retencoes)
- Depende de: `recursos-humanos` (employee retencoes)
- Alimenta: `contabilidade` (lancamentos de imposto retido)

## Arquivos

- `database-impostos.sql`
- `api-impostos.md`
- `requisitos.md`
- `uml.md`
