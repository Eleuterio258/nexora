# Lacunas do Frontend vs. Backend PayCore

> Data: 2026-08-09  
> Frontend: `factPro/frontend` (PHP server-rendered)  
> Backend: `PayCore/backend` (Node.js/Express)

## Resumo executivo

Foram implementadas as fases 0 a 6 do plano de frontend. Durante a implementação constatou-se que o backend PayCore é mais simples do que o esperado inicialmente (que assumia backend Go/Nexora ERP). O frontend foi adaptado aos endpoints reais do PayCore, mas várias funcionalidades do plano original dependem de endpoints que ainda não existem no backend.

Este documento lista as lacunas identificadas, o impacto na UI e as recomendações.

---

## 1. Documentos fiscais

### O que o plano previa
- Orçamentos, encomendas, facturas, notas de crédito, recibos, guias de transporte.
- Emissão, assinatura, cancelamento, envio por email.

### Estado actual do PayCore
- Não existem endpoints de documentos fiscais.
- Apenas existe `/api/v1/transactions` (vendas POS).

### Implementação no frontend
- Criou-se `InvoicingService` sobre `/api/v1/transactions`.
- As transações são apresentadas como "Documentos de Venda".
- É possível cancelar/estornar transacoes (se o backend suportar).

### Lacuna
- Não há distinção entre facturas, orçamentos, notas de crédito, etc.
- Não há numeração fiscal, séries, AT (Autoridade Tributária), assinatura digital.
- O frontend mostra um aviso informativo.

### Recomendação
Criar no backend: `POST /api/v1/invoices`, `GET /api/v1/invoices`, `POST /api/v1/invoices/:id/cancel`, `POST /api/v1/quotes`, `POST /api/v1/credit-notes`, etc.

---

## 2. Clientes

### O que o plano previa
- CRUD de clientes, ficha de cliente, documentos, notas, descontos personalizados, histórico de compras.

### Estado actual do PayCore
- Não existe entidade `Customer`.
- As transações podem ter `customerEmail`, `customerName`, etc., mas não é um CRUD.

### Implementação no frontend
- `CustomerService` extrai clientes únicos das transações quando os campos existem.
- Ficha de cliente mostra histórico de transações desse email.

### Lacuna
- Não é possível criar/editar clientes independentemente.
- Não há endereços, NIF persistente, descontos por cliente, notas.

### Recomendação
Criar no backend: `/api/v1/customers` com CRUD completo e associar `customerId` às transações.

---

## 3. Pagamentos móveis (M-Pesa / E-Mola)

### O que o plano previa
- Integração real com gateways M-Pesa, eMola, etc.

### Estado actual do PayCore
- Não há gateway de pagamento móvel.
- O `paymentMethod` mais próximo é `WALLET`.

### Implementação no frontend
- Fluxo de pagamento móvel simulado: modal, referência, polling de 3 em 3 segundos.
- Cria transação `WALLET` e consulta estado por referência.

### Lacuna
- Não há comunicação real com a operadora.
- O estado da transação pode não mudar automaticamente.

### Recomendação
Implementar gateway de pagamento móvel no backend ou integrar com API de parceiro (M-Pesa API, eMola API).

---

## 4. Stock avançado

### O que o plano previa
- Armazéns, localizações, transferências entre armazéns, lotes, seriais.

### Estado actual do PayCore
- Apenas produtos com `stock` e `min_stock`.
- Existe `/api/v1/products/:id/stock/adjust` e `/api/v1/products/:id/stock/logs` (logs ainda vazios no controller).

### Implementação no frontend
- CRUD de produtos e categorias.
- Ajuste de stock manual.
- Alertas low-stock.

### Lacuna
- Sem gestão multi-armazém.
- Sem lotes, datas de validade, números de série.

### Recomendação
Expandir o modelo de stock no backend com warehouses, locations, batches, serials e transferências.

---

## 5. Contabilidade

### O que o plano previa
- Plano de contas, lançamentos contabilísticos, balancetes, ativos fixos, amortizações, impostos.

### Estado actual do PayCore
- Nenhum endpoint contabilístico.

### Implementação no frontend
- Páginas placeholder informativas.

### Recomendação
Criar módulo contabilístico no backend: `/api/v1/accounts`, `/api/v1/journal-entries`, `/api/v1/trial-balance`, etc.

---

## 6. Recursos Humanos

### O que o plano previa
- Funcionários, férias, assiduidade, recibos de vencimento, folha de pagamento.

### Estado actual do PayCore
- Nenhum endpoint de RH.

### Implementação no frontend
- Páginas placeholder informativas.

### Recomendação
Criar módulo de RH no backend: `/api/v1/employees`, `/api/v1/leave-requests`, `/api/v1/attendance`, `/api/v1/payrolls`.

---

## 7. Segurança e auditoria

### O que o plano previa
- Roles e permissões granulares, logs de auditoria, gestão de sessões activas.

### Estado actual do PayCore
- Existem roles simples: `SUPER_ADMIN`, `ADMIN`, `OPERADOR`.
- Não há logs de auditoria acessíveis via API.
- Não há gestão de sessões.

### Implementação no frontend
- CRUD de utilizadores com roles existentes.
- Placeholders para segurança e auditoria.

### Recomendação
- Criar `/api/v1/audit-logs`.
- Expandir roles/permissions para granularidade por módulo.
- Criar `/api/v1/sessions` para gestão de sessões.

---

## 8. Configuração do sistema

### O que o plano previa
- Dados da empresa, moeda, impostos, taxas de câmbio, licenciamento.

### Estado actual do PayCore
- Não há endpoints para configuração do tenant (apenas superadmin pode gerir tenants/licenças).

### Implementação no frontend
- Página placeholder informativa.
- Terminais e utilizadores como atalhos.

### Recomendação
Criar `/api/v1/tenant/config` ou `/api/v1/company` para o tenant editar os seus dados.

---

## 9. Relatórios

### O que o plano previa
- Relatórios avançados de vendas, stock, financeiros, RH.

### Estado actual do PayCore
- Apenas `/api/v1/transactions/report`.

### Implementação no frontend
- Dashboard operacional com gráfico de vendas.
- Relatório de fecho de caixa.

### Lacuna
- Relatórios limitados a transações.
- Sem relatórios fiscais, de stock, de RH.

### Recomendação
Adicionar endpoints de relatórios específicos por módulo.

---

## Tabela resumida

| Módulo | Status frontend | Status backend | Nota |
|---|---|---|---|
| Dashboard operacional | ✅ Implementado | ✅ Dados disponíveis | Via transactions/report |
| Sessões de caixa | ✅ Implementado | ✅ Endpoints disponíveis | /api/v1/cash-drawers |
| Movimentações de caixa | ✅ Implementado | ✅ Endpoint disponível | /api/v1/cash-drawers/:id/movements |
| Pagamentos móveis | ⚠️ Simulado | ❌ Não existe gateway | Usa WALLET |
| Descontos POS | ✅ Implementado | ✅ CRUD disponível | /api/v1/discounts |
| Stock básico | ✅ Implementado | ✅ CRUD disponível | /api/v1/products |
| Stock avançado | ⚠️ Placeholder | ❌ Não existe | Sem warehouses, lotes, seriais |
| Documentos fiscais | ⚠️ Simulado | ❌ Não existe | Usa transactions |
| Clientes | ⚠️ Derivado | ❌ Não existe CRUD | Usa customerEmail das transações |
| Contabilidade | ⚠️ Placeholder | ❌ Não existe | Plano de contas, lançamentos |
| RH | ⚠️ Placeholder | ❌ Não existe | Funcionários, férias, recibos |
| Utilizadores | ✅ Implementado | ✅ CRUD disponível | /api/v1/users |
| Terminais POS | ✅ Implementado | ✅ CRUD disponível | /api/v1/terminals/admin |
| Segurança/Auditoria | ⚠️ Placeholder | ❌ Não existe | Logs, roles granulares |
| Configuração do sistema | ⚠️ Placeholder | ❌ Não existe | Dados empresa, moeda, impostos |

---

## Conclusão

O frontend cobre integralmente o que o backend PayCore oferece hoje e prepara a UI para módulos futuros. As principais dependências de backend são:

1. Documentos fiscais
2. Clientes (CRUD)
3. Gateway de pagamento móvel
4. Stock avançado
5. Contabilidade
6. RH
7. Auditoria e roles granulares
8. Configuração do tenant
