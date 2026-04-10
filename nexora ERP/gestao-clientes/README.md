# Modulo de Gestao de Clientes

## Objetivo

Este modulo concentra a informacao completa de clientes para o ERP, cobrindo cadastro, credito, saldo, pagamentos, documentos e historico comercial.

## Funcionalidades

- cadastro completo de clientes
- grupos de clientes
- contactos do cliente
- enderecos do cliente
- documentos anexos do cliente
- controlo de limite de credito
- controlo de saldos
- registo de pagamentos do cliente
- notas internas do cliente
- historico do cliente
- etiquetas do cliente
- descontos comerciais por cliente

## Arquivos

- `database-clientes.sql`: estrutura PostgreSQL do modulo
- `views-clientes.sql`: views de consulta de negocio
- `funcoes-clientes.sql`: funcoes auxiliares para saldo e credito
- `api-clientes.md`: endpoints do modulo

## Entidades principais

- customers
- customer_groups
- customer_contacts
- customer_addresses
- customer_documents
- customer_credit_limits
- customer_balances
- customer_payments
- customer_notes
- customer_history
- customer_tags
- customer_discounts

## Indicadores principais por cliente

- total comprado
- total pago
- valor em aberto
- limite de credito
- credito disponivel
- ultimo pagamento
- ultima compra
- grupo comercial
- desconto aplicado
