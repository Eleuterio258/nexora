# Modulo Multi-Moeda

## Objetivo

Gerir conversoes de moeda entre a moeda do documento e a moeda base da empresa, com politicas de taxa configuradas e historico de conversoes.

## Escopo

- Politicas de taxa de cambio (taxa do dia, taxa fixa, taxa media mensal)
- Registo de conversoes por documento
- Historico de taxas aplicadas
- Regras de arredondamento por moeda
- Suporte a documentos em moeda estrangeira com valor equivalente em MZN

## Nota sobre sistema-configuracao
As tabelas `currencies` e `exchange_rates` (tabela mestra de taxas diarias) pertencem ao modulo `sistema-configuracao`.
Este modulo complementa com as politicas de aplicacao e historico de conversoes por documento.

## Entidades

- `exchange_rate_policies`
- `currency_conversions`
- `document_currencies`
- `currency_rounding_rules`

## Dependencias

- Depende de: `sistema-configuracao` (currencies, exchange_rates)
- Consumido por: `modulo-faturacao`, `compras`, `financeiro`, `contabilidade`

## Arquivos

- `database-multi-moeda.sql`
- `api-multi-moeda.md`
- `requisitos.md`
- `uml.md`
