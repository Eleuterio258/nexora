# Continuação da análise do backend — 15/10/2026

Esta revisão complementa `analise-profunda-backend-modulos-2026-10-14.md`. Aprofunda o processo de renovação comercial, incluindo o job que não tinha sido demonstrado na avaliação de M32. Não altera código funcional. Evidência estática confrontada com migrações versionadas; não foram feitas ligações ao banco configurado nem executados testes de integração.

## AP-21 — O job de renovação não seleciona subscrições válidas — alta

Em `backend/internal/background/jobs.go:688`, `processSubscriptionRenewals` filtra `s.status = 'activo'`. A constraint `subscriptions_status_check`, na baseline `20260724080001_baseline_schema.up.sql:421`, só permite `pendente`, `activa`, `suspensa`, `cancelada` e `expirada`. O endpoint de renovação também escreve `activa` (`assinaturas/handlers/assinaturas.go`, função `RenovarAssinatura`).

Consequência no esquema versionado: nenhuma subscrição válida satisfaz o filtro. O job pode terminar sem erro e sem gerar uma única factura. A existência do agendamento diário em `jobs.go:94` não demonstra renovação operacional. Não foi encontrada nas migrações ativas uma alteração que aceite `activo` nesta tabela.

Correção proposta: alinhar estados entre esquema, handlers e worker. Verificação: subscrição `activa`, com renovação automática e data vencida, gera exactamente uma factura e avança a data; suspensas e canceladas permanecem excluídas.

## AP-22 — A factura produzida pelo job viola o estado permitido — alta

Em `jobs.go:730`, o INSERT de `assinaturas.subscription_invoices` usa `status='pendente'`. A constraint da baseline, linha 355, aceita apenas `emitida`, `paga`, `cancelada` e `vencida`.

Este é um segundo bloqueio, atualmente ocultado por AP-21. Corrigir apenas o filtro permite chegar a um INSERT que falha; a transação faz rollback e a próxima execução volta a tentar. As colunas monetárias deste INSERT existem: o defeito confirmado aqui é o estado.

Correção proposta: definir o estado inicial de negócio e alinhar a escrita com o contrato aprovado. Verificação em PostgreSQL isolado: criação e avanço de data confirmam na mesma transação; falha no INSERT preserva a data anterior.

## AP-23 — O plano trimestral é renovado como mensal — média

A baseline permite `billing_period='trimestral'` (linha 377). O switch em `jobs.go:716` só distingue `anual`; todos os outros valores seguem o cálculo mensal.

Depois de remover AP-21/22, uma subscrição trimestral pode receber um período de um mês e avançar a próxima cobrança apenas um mês. O impacto monetário depende da interpretação comercial de `unit_price`; a periodicidade incorreta está diretamente visível.

Correção proposta: tratar explicitamente cada periodicidade aceite e rejeitar valores desconhecidos. Validar também datas de fim de mês: `time.AddDate` normaliza datas, pelo que a política de aniversário de cobrança deve ser definida antes de fixar os resultados esperados.

## AP-24 — O worker pode faturar uma subscrição cancelada após a seleção — alta

A seleção das subscrições acontece antes de abrir a transação por registo. O UPDATE posterior (`jobs.go:742`) usa apenas `WHERE id = $2`, sem revalidar estado, data ou `auto_renew`. O cancelamento do handler atualiza o estado separadamente.

Sequência possível, ainda não reproduzida: o worker seleciona uma subscrição; o endpoint confirma o cancelamento; o worker abre a transação, cria a factura a partir do resultado antigo e avança a data da subscrição cancelada. O UPDATE não reativa a subscrição, mas permite produzir uma nova cobrança após o cancelamento. AP-21/22 impedem atualmente este caminho no esquema versionado; a corrida deve ser tratada ao reparar o processo.

Correção proposta: reservar e revalidar a subscrição dentro da transação e coordenar o cancelamento pela mesma linha. A política deve definir o resultado quando a renovação já começou. A consulta `NOT EXISTS` fora da transação também não reserva o período. A unicidade existente `(tenant_id, numero)` ajuda a rejeitar números duplicados, mas não substitui uma regra explícita por subscrição/período.

## Atualização da avaliação de M32

Há geração automática implementada em background, além dos endpoints de consulta. Contudo, no esquema versionado, AP-21 e AP-22 bloqueiam o processo em duas etapas independentes. A avaliação de RF-M32-04 deve registar implementação presente com bloqueio técnico identificado, sem assumir recorrência operacional. AP-12 e os problemas de input/estado em `RenovarAssinatura` continuam aplicáveis.

## Verificação necessária

1. PostgreSQL descartável com as migrações ativas; massa fictícia e worker apontado explicitamente para essa base.
2. Renovação mensal, trimestral e anual, com datas normais e de fim de mês.
3. Reexecução do mesmo período e execução concorrente por dois workers.
4. Cancelamento ou suspensão entre seleção e escrita, com barreiras que tornem a sequência reproduzível.
5. Falha entre INSERT e UPDATE, provando rollback conjunto.

Esta continuação não repete os testes gerais já registados nas análises anteriores. A validação realizada foi leitura do fluxo completo e comparação de estados, periodicidades e constraints; comportamento em execução continua por demonstrar.
