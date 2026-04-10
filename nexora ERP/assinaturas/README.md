# Modulo Assinaturas SaaS / Licencas

## Objetivo

Gerir planos SaaS, faturacao recorrente, gateways de pagamento, controlo de limites por empresa e ciclo completo de inadimplencia (aviso, suspensao, bloqueio e reactivacao).

## Entidades

| Tabela | Descricao |
| --- | --- |
| `payment_gateways` | Gateways configurados (M-Pesa, E-Mola, Stripe, PayPal, transferencia) |
| `subscription_plans` | Planos com preco, ciclo, trial e limites operacionais |
| `subscription_plan_features` | Funcionalidades descritivas por plano (para comparacao) |
| `subscriptions` | Assinatura activa de cada empresa ao plano escolhido |
| `subscription_billing_cycles` | Ciclos de faturacao gerados automaticamente |
| `subscription_payments` | Pagamentos efectuados por gateway |
| `subscription_usage` | Registo de consumo por metrica (planos baseados em uso) |
| `subscription_pauses` | Pausas manuais com periodo definido |
| `subscription_cancellations` | Cancelamentos com efectividade futura |
| `subscription_events` | Log de auditoria de todos os eventos da licenca |

## Estados da Assinatura

| Estado | Origem |
| --- | --- |
| `trial` | Nova subscricao com periodo de prova |
| `activa` | Pagamento confirmado ou trial sem cobranca |
| `pausada` | Pausa manual pelo cliente |
| `suspensa` | Suspensao automatica por inadimplencia |
| `cancelada` | Cancelamento pelo cliente ou sistema |
| `expirada` | Trial ou periodo pago esgotado sem renovacao |

## Limites por Plano

Os campos `max_utilizadores`, `max_filiais`, `max_produtos` e `max_documentos_mes` em `subscription_plans` definem os limites operacionais aplicados a cada tenant. O campo `modulos` (JSONB) lista os modulos incluidos.

## Dependencias

- Depende de: `gestao-clientes` (`customer_id` na assinatura)
- Alimenta: `modulo-faturacao` (`invoice_id` por ciclo faturado)
- Alimenta: `financeiro` (recebimentos recorrentes de assinatura)

## Ficheiros

| Ficheiro | Descricao |
| --- | --- |
| `database-assinaturas.sql` | Schema completo — 10 tabelas, constraints, indices |
| `api-assinaturas.md` | Endpoints REST agrupados por recurso |
| `requisitos.md` | RF + RNF do modulo |
| `uml.md` | ERD, state diagram, fluxos de faturacao e inadimplencia |
