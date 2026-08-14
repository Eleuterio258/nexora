# Análise: POS Acoplado ao ERP — Gestão de Dependências entre Módulos

**Data:** 2026-08-12  
**Âmbito:** Módulo POS do Nexora ERP (`backend/internal/modules/pos`, `frontend/src/View/templates/pages/pos*.php`)
**Abordagem:** Manter o POS integrado no ERP, fortalecendo os contratos com os módulos dos quais depende.

---

## 1. Resumo executivo

O POS será mantido **acoplado ao ERP**, tal como está hoje. A separação física de projetos (igual à escola) **não é o objetivo** nesta fase. Em vez disso, o foco é:

1. **Mapear todas as dependências** do POS para outros módulos.
2. **Garantir que essas dependências sejam estáveis** e bem definidas.
3. **Reduzir o acoplamento direto a tabelas estrangeiras** sempre que possível, usando ports/adapters.
4. **Documentar os contratos** entre o POS e os módulos satélite.

Esta abordagem é válida porque:
- O POS precisa de dados em tempo real de stock, produtos, clientes, faturação, financeiro e tesouraria.
- O ERP já é um monolito modular coeso; separar o POS aumentaria a complexidade operacional sem ganho imediato.
- O backend POS (`backend/internal/modules/pos/`) já está bem localizado; o trabalho é reorganizar as dependências internas.

---

## 2. Arquitetura-alvo: POS dentro do ERP

```
┌─────────────────────────────────────────────────────────────────┐
│                         FRONTEND PHP                            │
│  frontend/src/View/templates/pages/pos*.php                     │
│  Rota: /nexora/pos                                              │
└────────────────────┬────────────────────────────────────────────┘
                     │ consome /api/pos/*
┌────────────────────▼────────────────────────────────────────────┐
│                     BACKEND GO (monolito)                       │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Módulo POS                                               │  │
│  │  backend/internal/modules/pos/handlers/*.go               │  │
│  └────────────────────┬──────────────────────────────────────┘  │
│                       │                                         │
│       ┌───────────────┼───────────────┐                         │
│       ▼               ▼               ▼                         │
│  ┌─────────┐    ┌──────────┐   ┌──────────┐                    │
│  │ Ports   │    │ Adapters │   │ Outros   │                    │
│  │ shared  │    │ shared   │   │ módulos  │                    │
│  │contracts│    │adapters  │   │diretos   │                    │
│  └─────────┘    └──────────┘   └──────────┘                    │
└─────────────────────────────────────────────────────────────────┘
```

### Princípios

- O POS vive dentro do mesmo deploy do ERP.
- O frontend POS continua em PHP dentro do `frontend/`.
- O backend POS continua em `backend/internal/modules/pos/`.
- As comunicações entre módulos devem preferir **Ports & Adapters** (`internal/shared/contracts` + `internal/shared/adapters`) em vez de queries diretas a tabelas estrangeiras.
- Quando a performance exigir queries diretas (ex: catálogo com stock), documentar o contrato implícito (schema esperado).

---

## 3. Dependências do POS mapeadas

### 3.1 Dependências via Ports & Adapters (bom padrão ✅)

| Módulo | Port | Adaptador | Uso no POS |
|---|---|---|---|
| Contabilidade | `contracts.AccountingPort` | `shared/adapters/accounting.go` | Lançamentos contabilísticos de receita por sessão |

### 3.2 Dependências diretas a tabelas de outros módulos (revisar ⚠️)

| Módulo alvo | Tabelas acessadas diretamente pelo POS | Ficheiro POS | Risco |
|---|---|---|---|
| **Faturação** | `invoice_series`, `faturacao.invoices`, `faturacao.invoice_items`, `faturacao.credit_notes`, `faturacao.credit_note_items` | `pos.go`, `faturacao.go`, `recibo.go`, `estorno_parcial.go`, `paycore_transactions.go` | Alto — schema fiscal pode mudar; numeração duplicada |
| **Gestão de Clientes** | `clientes.customers` | `faturacao.go` | Médio — criação de cliente anónimo |
| **Gestão de Produtos** | `produtos.products`, `produtos.product_categories`, `produtos.product_prices`, `produtos.product_barcodes`, `produtos.product_images` | `pos.go` (catálogo), `sync.go`, `relatorios.go` | Médio — catálogo POS depende do schema de produtos |
| **Gestão de Stock** | `stock_items`, `stock_movements` | `pos.go`, `estorno_parcial.go`, `paycore_transactions.go` | Alto — baixa/estorno de stock em SQL direto |
| **Auth/RBAC** | `auth.users`, `auth.cargos`, `auth.memberships`, `auth.permissoes_cargo` | `pos.go` | Médio — criação de conta de terminal |
| **Recursos Humanos** | `rh.funcionarios` (via `funcionario.Service`) | `pos.go` | Médio — resolução do funcionário do operador |
| **Empresas / SaaS** | `empresas.companies`, `empresas.company_licenses`, `empresas.company_tax_info`, `empresas.company_addresses`, `saas.tenants` | `recibo.go`, `licenca.go` | Baixo/Médio — dados de empresa para recibo e licenciamento |
| **Tesouraria** | *(nenhuma tabela direta visível; verificar)* | — | — |
| **Financeiro** | *(nenhuma tabela direta visível; verificar)* | — | — |

### 3.3 Dependências lógicas (conforme `docs/nexora ERP/pos/README.md`)

| Módulo | Dado/Função necessária |
|---|---|
| `gestao-produtos` | `product_id`, `product_variant_id`, código de barras, preço de venda |
| `gestao-stock` | Baixa de stock no `warehouse_id` do terminal |
| `modulo-faturacao` | Emissão de fatura fiscal (série "FT") e notas de crédito |
| `financeiro` | Registo de recebimentos por método de pagamento |
| `tesouraria` | `caixa_id` associado ao terminal; reconciliação no fecho |
| `contabilidade` | Lançamentos contabilísticos automáticos |

---

## 4. Problemas de acoplamento identificados

### 4.1 Numeração de série fiscal duplicada

**Ficheiro:** `pos.go` linha 26

```go
// proximoNumeroSerie obtem (com lock) a serie ativa do tipo indicado,
// incrementa a sua sequencia e devolve o numero de documento gerado e o
// id da serie, para serem gravados no documento dentro da mesma transacao.
// Réplica local de modulo-faturacao/handlers/faturacao.go (helper duplicado por convenção).
```

**Problema:** O POS tem uma cópia local da lógica de numeração de séries da faturação. Se a faturação mudar a regra, o POS fica inconsistente.

**Recomendação:** Criar um `InvoicingPort` em `internal/shared/contracts` e um adaptador em `internal/shared/adapters/invoicing.go` para:
- Obter o próximo número de série
- Criar fatura/invoice
- Criar nota de crédito

O POS passa a chamar o port, não a replicar a lógica nem a aceder diretamente a `invoice_series`.

### 4.2 Criação de cliente anónimo diretamente na tabela `clientes.customers`

**Ficheiro:** `faturacao.go` linha 48

```go
INSERT INTO clientes.customers (tenant_id, codigo, nome, estado) ...
```

**Problema:** O POS conhece o schema da gestão de clientes.

**Recomendação:** Usar `contracts.ClientPort` / `shared/adapters/client.go` para criar/obter cliente anónimo. O port já existe (`GetClientID`, `CreateClient`).

### 4.3 Baixa de stock em SQL direto

**Ficheiros:** `pos.go`, `estorno_parcial.go`, `paycore_transactions.go`

```go
SELECT id FROM stock_items ...
UPDATE stock_items SET quantity=quantity+? ...
INSERT INTO stock_movements ...
```

**Problema:** Regras de stock (reservas, lotes, validades, custo médio) podem ser violadas se o POS atualizar stock diretamente.

**Recomendação:** Criar um `StockPort` em `internal/shared/contracts` e adaptador em `internal/shared/adapters/stock.go` com operações:
- `Reserve(ctx, warehouseID, productID, variantID, quantity) error`
- `Release(ctx, warehouseID, productID, variantID, quantity) error`
- `Move(ctx, StockMovement) error`

O POS só chama o port; o módulo de stock controla as regras.

### 4.4 Criação de funcionário/conta de terminal diretamente nas tabelas auth

**Ficheiro:** `pos.go` linha 92-117 e 125-199

```go
ensureCargoTerminalPOS(...) // cria cargo e permissão diretamente
INSERT INTO auth.users ...
INSERT INTO auth.memberships ...
INSERT INTO pos_terminals ...
```

**Problema:** O POS manipula RBAC diretamente.

**Recomendação:** Criar um `AuthPort` ou reutilizar um serviço de auth para:
- Criar conta de sistema/terminal
- Atribuir cargo/permissões
- Gerar hash de password

### 4.5 Acesso direto a produtos para catálogo e sync

**Ficheiros:** `pos.go`, `sync.go`, `relatorios.go`

```go
FROM produtos.products p
LEFT JOIN produtos.product_categories pc ...
LEFT JOIN LATERAL (SELECT valor FROM produtos.product_prices ...) ...
```

**Problema:** O POS depende do schema completo de produtos.

**Recomendação:** Manter uma **view materializada ou tabela de catálogo POS** (`pos_catalog_items`) que é preenchida/atualizada pelo módulo de produtos. O POS lê apenas do seu catálogo; a sincronização é responsabilidade do módulo de produtos ou de um processo batch.

---

## 5. Proposta de reestruturação das dependências

### 5.1 Criar/adotar Ports para todos os módulos satélite

Adicionar ao `internal/shared/contracts/erp_ports.go` (ou ficheiros dedicados):

```go
// InvoicingPort — emissão de documentos fiscais
type InvoicingPort interface {
    NextDocumentNumber(ctx context.Context, tenantID int64, docType string) (string, int64, error)
    CreateInvoice(ctx context.Context, req InvoiceRequest) (int64, error)
    CreateCreditNote(ctx context.Context, req CreditNoteRequest) (int64, error)
}

// StockPort — movimentação de stock
type StockPort interface {
    Decrease(ctx context.Context, req StockChangeRequest) error
    Increase(ctx context.Context, req StockChangeRequest) error
    GetAvailable(ctx context.Context, tenantID, warehouseID, productID int64, variantID *int64) (float64, error)
}

// TreasuryPort — já existe, confirmar uso no POS
type TreasuryPort interface {
    RecordReceipt(ctx context.Context, p TreasuryReceipt) error
}

// FinancialPort — já existe, confirmar uso no POS
type FinancialPort interface {
    RecordReceivable(ctx context.Context, p FinancialReceivable) error
}
```

### 5.2 Criar adaptadores correspondentes

```
backend/internal/shared/adapters/
├── accounting.go        # já existe ✅
├── invoicing.go         # novo
├── stock.go             # novo
├── client.go            # já existe ✅
├── financial.go         # já existe
├── treasury.go          # já existe
├── hr.go                # já existe
└── auth.go              # novo (opcional)
```

### 5.3 Refatorar handlers POS

Injetar os ports no `Handler`:

```go
type Handler struct {
    db         *pgxpool.Pool
    cfg        *config.Config
    wsHub      *ws.Hub
    push       *push.Service
    accounting contracts.AccountingPort
    invoicing  contracts.InvoicingPort
    stock      contracts.StockPort
    treasury   contracts.TreasuryPort
    financial  contracts.FinancialPort
    client     contracts.ClientPort
}
```

Eliminar queries diretas a tabelas de outros módulos, exceto onde haja justificativa de performance documentada.

### 5.4 Manter o frontend PHP acoplado

Como a decisão é manter acoplado:
- Manter `frontend/src/View/templates/pages/pos*.php`.
- Garantir que as chamadas ao backend passem pelo `NexoraGateway` do frontend.
- Criar um `PosService.php` bem definido em `frontend/src/Model/Service/Pos/` para centralizar as chamadas a `/api/pos/*`.
- Isolar as rotas POS em `frontend/src/Routing/Pages/ComercialPageRoutes.php` ou criar `PosPageRoutes.php`.

---

## 6. Roadmap de implementação

### Fase 1 — Inventário e estabilização
- [ ] Listar todos os acessos diretos a tabelas de outros módulos no POS
- [ ] Documentar contratos implícitos (tabelas, colunas, schemas esperados)
- [ ] Criar testes de integração para os fluxos críticos de venda, devolução e fecho

### Fase 2 — Ports & Adapters prioritários
- [ ] Criar `InvoicingPort` + `invoicing.go` adapter
- [ ] Criar `StockPort` + `stock.go` adapter
- [ ] Refatorar `pos.go` e `faturacao.go` para usar os ports
- [ ] Eliminar `proximoNumeroSerie` duplicado do POS

### Fase 3 — Auth e RH
- [ ] Criar `AuthPort` para criação de contas de terminal (ou reutilizar serviço existente)
- [ ] Usar `HRPort` para resolução de `funcionario_id`
- [ ] Usar `ClientPort` para cliente anónimo

### Fase 4 — Financeiro e Tesouraria
- [ ] Confirmar uso de `TreasuryPort` e `FinancialPort` no POS
- [ ] Implementar adaptações se ainda não estiverem integradas

### Fase 5 — Catálogo POS
- [ ] Definir se o catálogo POS continua a ler diretamente de `produtos.*` ou se passa a usar `pos_catalog_items`
- [ ] Se manter leitura direta, documentar schema esperado
- [ ] Considerar cache/materialização para performance em catálogos grandes

### Fase 6 — Frontend PHP
- [ ] Criar `frontend/src/Model/Service/Pos/PosService.php` como camada de serviço única
- [ ] Agrupar rotas POS em ficheiro dedicado
- [ ] Manter layout POS isolado (`pos_top.php`, `pos_bottom.php`)

---

## 7. Riscos e mitigações

| Risco | Impacto | Mitigação |
|---|---|---|
| Refatoração de ports quebra fluxos existentes | Alto | Testes de integração antes e depois; fasear por port |
| Performance piora ao usar adapters | Médio | Manter leituras de catálogo/cache diretas; medir antes/depois |
| Outros módulos mudam schema | Alto | Documentar contratos; usar ports para isolar impacto |
| POS continua dependendo de módulos imaturos (financeiro, tesouraria) | Médio | Priorizar maturidade desses módulos ou simplificar integração |
| Frontend PHP monolítico dificulta evolução | Médio | Isolar service layer e rotas; considerar PWA no futuro |

---

## 8. Conclusão

Manter o POS **acoplado ao ERP é uma decisão válida** e pragmaticamente correta para o estágio atual. O trabalho não é separar, mas **organizar o acoplamento**:

1. O backend POS continua em `backend/internal/modules/pos/`.
2. O frontend POS continua em `frontend/src/View/templates/pages/pos*.php`.
3. As dependências para outros módulos devem passar por **Ports & Adapters** (`internal/shared/contracts` + `internal/shared/adapters`).
4. Eliminar lógica duplicada (ex: numeração de séries fiscais) e acessos diretos a tabelas estrangeiras sempre que possível.

A separação total (igual à escola) pode ser reconsiderada no futuro, mas só depois de os contratos entre módulos estarem estáveis e bem testados.
