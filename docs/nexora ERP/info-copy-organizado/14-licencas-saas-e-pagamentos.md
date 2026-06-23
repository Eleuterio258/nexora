# Sistema de Licencas SaaS e Pagamentos

## Objetivo

Gerir planos SaaS, cobranca, renovacao, bloqueio por inadimplencia e controlo de limites por empresa.

## Componentes principais

- planos
- licencas
- assinaturas
- faturas de assinatura
- pagamentos de assinatura
- limites por plano
- estado da empresa

## Entidades sugeridas

- plans
- plan_features
- subscriptions
- subscription_items
- billing_invoices
- billing_invoice_items
- billing_payments
- payment_gateways
- license_events

## Regras do sistema

- cada empresa tem um plano ativo
- o plano define limites de usuarios, filiais e funcionalidades
- pagamentos renovam a assinatura
- atraso pode causar aviso, suspensao ou bloqueio
- upgrade e downgrade devem ser controlados

## Fluxo basico

1. Empresa escolhe plano
2. Sistema cria assinatura
3. Sistema gera fatura SaaS
4. Cliente paga via gateway
5. Sistema confirma pagamento
6. Sistema ativa ou renova licenca
7. Sistema atualiza limites do tenant

## Gateways possiveis

- Stripe
- PayPal
- M-Pesa
- E-Mola
- transferencia bancaria

## Estados comuns da assinatura

- trial
- ativa
- vencida
- suspensa
- cancelada

## Eventos importantes

- criacao de plano
- upgrade de plano
- downgrade de plano
- renovacao
- falha de pagamento
- suspensao automatica
- reativacao
