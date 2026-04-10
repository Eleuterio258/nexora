# UML — Modulo Financeiro

## Diagrama de Entidades (ERD)

```mermaid
erDiagram
    payment_methods {
        bigint id PK
        bigint tenant_id
        varchar codigo UK
        varchar nome
        varchar tipo
        boolean ativo
    }

    financial_categories {
        bigint id PK
        bigint tenant_id
        bigint parent_id FK
        varchar codigo
        varchar nome
        varchar tipo
    }

    payments {
        bigint id PK
        bigint tenant_id
        varchar numero UK
        bigint payment_method_id FK
        bigint financial_category_id FK
        varchar tipo
        date data_pagamento
        numeric valor
        varchar referencia_tipo
        bigint referencia_id
        varchar status
    }

    payment_transactions {
        bigint id PK
        bigint payment_id FK
        bigint conta_bancaria_id
        bigint caixa_id
        numeric valor
    }

    accounts_receivable {
        bigint id PK
        bigint tenant_id
        varchar numero UK
        bigint customer_id
        bigint financial_category_id FK
        numeric valor_total
        numeric valor_pago
        numeric valor_pendente
        date data_vencimento
        varchar status
    }

    accounts_receivable_payments {
        bigint id PK
        bigint accounts_receivable_id FK
        bigint payment_id FK
        numeric valor_imputado
    }

    accounts_payable {
        bigint id PK
        bigint tenant_id
        varchar numero UK
        bigint supplier_id
        bigint financial_category_id FK
        numeric valor_total
        numeric valor_pago
        numeric valor_pendente
        date data_vencimento
        varchar status
    }

    accounts_payable_payments {
        bigint id PK
        bigint accounts_payable_id FK
        bigint payment_id FK
        numeric valor_imputado
    }

    financial_budgets {
        bigint id PK
        bigint tenant_id
        bigint financial_category_id FK
        integer ano
        integer mes
        numeric valor_orcamentado
    }

    cash_flow_entries {
        bigint id PK
        bigint tenant_id
        bigint financial_category_id FK
        varchar tipo
        varchar origem
        date data
        numeric valor
    }

    financial_reports {
        bigint id PK
        bigint tenant_id
        varchar tipo
        timestamptz gerado_em
        jsonb dados
    }

    payment_methods ||--o{ payments : "usado em"
    financial_categories ||--o{ payments : "classifica"
    financial_categories ||--o{ accounts_receivable : "classifica"
    financial_categories ||--o{ accounts_payable : "classifica"
    financial_categories ||--o{ financial_budgets : "orcada em"
    financial_categories ||--o{ cash_flow_entries : "classifica"
    financial_categories ||--o{ financial_categories : "hierarquia"
    payments ||--o{ payment_transactions : "distribuido em"
    accounts_receivable ||--o{ accounts_receivable_payments : "liquidada por"
    accounts_payable ||--o{ accounts_payable_payments : "liquidada por"
    payments ||--o{ accounts_receivable_payments : "imputado a"
    payments ||--o{ accounts_payable_payments : "imputado a"
```

## Fluxo de Registo de Recebimento (Fatura)

```mermaid
sequenceDiagram
    actor Utilizador
    participant Financeiro
    participant Tesouraria
    participant Contabilidade
    participant BD

    Utilizador->>Financeiro: POST /api/financeiro/payments (tipo=recebimento, invoice_id)
    Financeiro->>BD: INSERT payments
    Financeiro->>BD: INSERT payment_transactions (conta_bancaria_id / caixa_id)
    Financeiro->>Tesouraria: notificar movimentacao de saldo
    Tesouraria->>BD: INSERT movimentos_financeiros
    Financeiro->>BD: UPDATE accounts_receivable SET valor_pago, status
    Financeiro->>Contabilidade: lancar journal_entry (debito caixa/banco, credito receita)
    Financeiro-->>Utilizador: recebimento confirmado
```

## Fluxo de Imputacao de Pagamento a Conta a Receber

```mermaid
sequenceDiagram
    actor Utilizador
    participant Financeiro
    participant BD

    Utilizador->>Financeiro: POST /api/financeiro/receivables/{id}/imputar (payment_id, valor)
    Financeiro->>BD: SELECT accounts_receivable (valor_pendente)
    alt valor_imputado > valor_pendente
        Financeiro-->>Utilizador: erro — valor excede pendente
    else
        Financeiro->>BD: INSERT accounts_receivable_payments
        Financeiro->>BD: UPDATE accounts_receivable SET valor_pago += valor_imputado
        alt valor_pendente = 0
            Financeiro->>BD: UPDATE accounts_receivable SET status = liquidada
        else
            Financeiro->>BD: UPDATE accounts_receivable SET status = parcial
        end
        Financeiro-->>Utilizador: imputacao registada
    end
```

## Estados de Conta a Receber / Conta a Pagar

```mermaid
stateDiagram-v2
    [*] --> pendente : criacao
    pendente --> parcial : imputacao parcial
    parcial --> liquidada : imputacao total
    pendente --> liquidada : imputacao total directa
    pendente --> vencida : data_vencimento ultrapassada
    parcial --> vencida : data_vencimento ultrapassada
    pendente --> cancelada : cancelamento manual
    parcial --> cancelada : cancelamento manual
    vencida --> liquidada : imputacao apos vencimento
    liquidada --> [*]
    cancelada --> [*]
```

## Fluxo de Caixa — Realizados vs. Previstos

```mermaid
flowchart LR
    A([Pagamento\nconfirmado]) -->|realizado| C[cash_flow_entries\norigem=realizado]
    B([Conta a pagar\nprevista]) -->|previsto| D[cash_flow_entries\norigem=previsto]
    C --> E{Projecao\nde saldo}
    D --> E
    E --> F([Relatorio\nFluxo de Caixa])
```
