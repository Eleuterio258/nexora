# Plano de Implementação do Frontend FactPro

> Estado: **Fases 0 a 6 concluídas** (preparação técnica, POS, stock, faturação/clientes, administração e finalização).
> Base de dados/backend: **PayCore (Node.js)** com endpoints `/api/v1/*`.

## 1. Contexto

O frontend FactPro (`factPro/frontend`) é uma aplicação PHP server-rendered que consome o backend PayCore. Durante a implementação verificou-se que o backend real é o PayCore (Node.js) e **não** o backend Go/Nexora ERP originalmente assumido no plano. Por isso, todos os endpoints, services e views foram adaptados para os paths reais do PayCore.

## 2. Arquitectura implementada

### 2.1 Proxy REST genérico

- `/nexora/api/v1/*` → encaminha para `/api/*` do backend PayCore com autenticação Bearer do admin em sessão.
- Proxy legado `/nexora/api/{acao}` mantido para compatibilidade.
- Endpoints POS específicos (`/nexora/api/v1/pos/pagamentos/*`, `/nexora/api/v1/pos/vendas`) implementados em `PosPaymentApiController` porque o backend não possui esses paths directamente.

### 2.2 Services PayCore

Todos os services estão em `src/Model/Service/PayCore/` e herdam de `NexoraService`:

| Service | Endpoint PayCore | Responsabilidade |
|---|---|---|
| `DashboardService` | `/api/v1/transactions/report`, `/api/v1/cash-drawers`, `/api/v1/products/low-stock`, `/api/v1/transactions` | KPIs do dashboard operacional |
| `PosCashDrawerService` | `/api/v1/cash-drawers` | Sessões de caixa, movimentos, fecho |
| `PosTransactionReportService` | `/api/v1/transactions/report` | Relatórios de transações |
| `PosPaymentService` | `/api/v1/transactions` | Vendas e pagamentos móveis (WALLET) |
| `PosDiscountService` | `/api/v1/discounts` | CRUD de descontos |
| `StockCategoryService` | `/api/v1/categories` | Categorias de produtos |
| `StockProductService` | `/api/v1/products` | Produtos, stock, low-stock |
| `StockAdjustmentService` | `/api/v1/products/:id/stock/*` | Ajustes e histórico de stock |
| `InvoicingService` | `/api/v1/transactions` | Documentos de venda (transações) |
| `CustomerService` | `/api/v1/transactions` | Clientes derivados das transações |
| `FileUploadService` | `/api/v1/files/upload/single` | Upload de imagens/ficheiros |
| `UserService` | `/api/v1/users` | Utilizadores do tenant |
| `TerminalAdminService` | `/api/v1/terminals/admin` | Terminais POS |

### 2.3 Componentes UI globais

- `loading-overlay.php` + CSS/JS
- `flash-messages.php` + integração com `ApiResponse`
- `license-modal.php` para erros 402
- `pagination.php` + `PaginationHelper`
- `api.js` — cliente JS global `e258tech.api.fetch()`

## 3. Resumo por fase

### Fase 0 — Preparação técnica ✅

- Proxy REST para paths compostos (`/nexora/api/v1/*`).
- Tratamento normalizado de erros (`ApiResponse`).
- Loading overlay, flash messages, license modal.
- Paginação reutilizável.
- Testes actualizados e a passar.

### Fase 1 — Dashboard e caixa POS ✅

- Dashboard operacional com vendas, transações, alertas de stock e gráfico de vendas (Chart.js).
- Listagem de sessões de caixa.
- Abertura, fecho e detalhe de sessão.
- Movimentações manuais (sangria/suprimento).
- Relatório de fecho de caixa.

### Fase 2 — Pagamentos móveis e descontos POS ✅

- Fluxo de pagamento M-Pesa/E-Mola simulado via `WALLET` do PayCore (modal + polling).
- CRUD completo de descontos (`/api/v1/discounts`).

### Fase 3 — Stock avançado ✅

- CRUD de categorias e produtos adaptado ao PayCore.
- Ajuste manual de stock com motivo e tipo.
- Alertas de stock baixo.
- Upload de imagem de produto.

### Fase 4 — Faturação, clientes e produtos avançados ✅

- Documentos de venda (transações POS) com listagem, detalhe, cancelamento.
- Clientes derivados dos dados das transações.
- Upload de imagens no formulário de produto.

### Fase 5 — Administração, segurança e sistema ✅

- CRUD de utilizadores do tenant.
- CRUD de terminais POS.
- Placeholders informativos para: segurança, auditoria, configuração do sistema, contabilidade e RH (módulos ainda não existentes no PayCore).

### Fase 6 — Testes e documentação ✅

- Smoke test `tests/PayCoreServicesTest.php` com 76 verificações.
- Todos os testes existentes actualizados e a passar.
- Documento de lacunas criado.

## 4. Testes

```bash
cd factPro/frontend
php tests/AdminServicesTest.php
php tests/CrmServicesTest.php
php tests/PresentationServicesTest.php
php tests/ArchitectureTest.php
php tests/PayCoreServicesTest.php
```

Todos passam.

## 5. Lacunas identificadas (backend PayCore)

Ver detalhes completos em `docs/frontend-gaps-paycore.md`.

Resumo:

1. **Documentos fiscais**: não há facturas, orçamentos, encomendas, notas de crédito. O frontend usa transações POS como "documentos de venda".
2. **Clientes**: não há CRUD de clientes. O frontend deriva clientes dos campos `customer_*` das transações.
3. **Pagamentos móveis**: não há integração directa M-Pesa/eMola. Usa-se `paymentMethod: WALLET` com polling simulado.
4. **Stock avançado**: não há armazéns, localizações, transferências, lotes, seriais.
5. **Contabilidade**: não existe plano de contas, lançamentos, balancetes.
6. **RH**: não existe módulo de funcionários, férias, assiduidade, recibos.
7. **Segurança/Auditoria**: não há logs de auditoria, roles granulares, gestão de sessões.
8. **Configuração do sistema**: não há endpoints para dados da empresa, moedas, impostos, licenciamento do tenant.
9. **Relatórios**: relatórios avançados são limitados ao `/api/v1/transactions/report`.

## 6. Próximos passos recomendados

1. Implementar backend CRUD de clientes.
2. Implementar backend de documentos fiscais (facturas/orçamentos/NC).
3. Integrar gateway de pagamento móvel real (M-Pesa/eMola).
4. Adicionar logs de auditoria e roles/permissoes granulares.
5. Criar endpoints de configuração do tenant.
6. Adicionar testes unitarios com mocks para os services PayCore.
