# Requisitos — Modulo Assinaturas SaaS / Licencas

## Requisitos Funcionais

### RF01 — Planos com Limites

O sistema deve permitir criar planos com preco, ciclo de renovacao, periodo de trial e limites operacionais (max_utilizadores, max_filiais, max_produtos, max_documentos_mes, modulos incluidos).

### RF02 — Funcionalidades Descritivas por Plano

Cada plano deve listar funcionalidades descritivas (incluidas ou nao) para exibicao na pagina de comparacao de planos.

### RF03 — Gateways de Pagamento

O sistema deve suportar multiplos gateways: M-Pesa, E-Mola, Stripe, PayPal e transferencia bancaria, configurados por tenant.

### RF04 — Subscricao de Empresa

O sistema deve registar a subscricao de um tenant a um plano, iniciando o periodo de trial ou activando imediatamente conforme o plano.

### RF05 — Faturacao Automatica por Ciclo

O sistema deve gerar automaticamente ciclos de faturacao e as respectivas faturas nos dias de renovacao de cada assinatura activa.

### RF06 — Pagamento via Gateway

O sistema deve registar pagamentos com referencia do gateway externo e confirmar automaticamente a assinatura apos confirmacao do pagamento.

### RF07 — Periodo de Trial

O sistema deve suportar periodos de trial sem cobranca com transicao automatica para o estado activo ou expirado no fim do periodo.

### RF08 — Pausa Manual

O sistema deve permitir pausar uma assinatura por periodo definido, suspendendo a faturacao automatica durante a pausa.

### RF09 — Suspensao por Inadimplencia

Apos falha de pagamento, o sistema deve: (1) aguardar N dias de tolerancia, (2) enviar aviso, (3) suspender automaticamente o acesso, (4) reactivar quando o pagamento for confirmado.

### RF10 — Cancelamento com Efectividade Futura

O cancelamento deve poder ser agendado para o fim do periodo ja pago, mantendo acesso ate la.

### RF11 — Upgrade e Downgrade de Plano

O sistema deve suportar mudanca de plano com ajuste pro-rata na fatura do ciclo corrente para upgrade e efectividade no proximo ciclo para downgrade.

### RF12 — Registo de Uso por Metrica

Para planos baseados em consumo, o sistema deve registar o uso por metrica (ex: numero de documentos, GB, transaccoes) e calcular a fatura correspondente.

### RF13 — Controlo de Limites em Tempo Real

O sistema deve verificar os limites do plano activo do tenant antes de permitir operacoes (criar utilizador, criar filial, emitir documento).

### RF14 — Auditoria de Eventos

Todos os eventos relevantes da assinatura (criacao, upgrade, downgrade, renovacao, falha, suspensao, reactivacao, cancelamento) devem ser registados em `subscription_events`.

### RF15 — Metricas SaaS

O sistema deve calcular MRR, ARR e taxa de churn por periodo.

---

## Requisitos Nao Funcionais

### RNF01 — Faturacao Automatica via Cron

O job de faturacao deve correr diariamente, processando assinaturas com `proxima_fatura_em <= hoje` e status `activa`.

### RNF02 — Idempotencia do Job

O job de faturacao deve ser idempotente: correr multiplas vezes no mesmo dia nao deve gerar ciclos ou faturas duplicadas.

### RNF03 — Notificacoes Antecipadas

O sistema deve notificar o cliente 7 dias antes do fim do trial, 7 dias antes da renovacao e imediatamente apos falha de pagamento.

### RNF04 — Tolerancia a Falha de Pagamento

O sistema deve permitir configurar N dias de tolerancia antes de suspender automaticamente uma assinatura inadimplente.

### RNF05 — Isolamento de Limites por Tenant

A verificacao de limites deve ser feita no contexto do tenant da assinatura activa, nunca entre tenants distintos.

### RNF06 — Auditoria Completa

Todos os eventos devem ser imutaveis — sem UPDATE ou DELETE em `subscription_events`.
