# UML — Modulo Contabilidade

## Diagrama de Entidades (ERD)

```mermaid
erDiagram
    account_types {
        bigint id PK
        bigint tenant_id
        varchar codigo UK
        varchar nome
        varchar natureza
    }

    chart_of_accounts {
        bigint id PK
        bigint tenant_id
        bigint account_type_id FK
        varchar codigo UK
        varchar nome
        boolean aceita_lancamento
    }

    fiscal_years {
        bigint id PK
        bigint tenant_id
        integer ano UK
        date data_inicio
        date data_fim
        varchar status
    }

    fiscal_periods {
        bigint id PK
        bigint fiscal_year_id FK
        varchar codigo UK
        date data_inicio
        date data_fim
        varchar status
    }

    journal_entries {
        bigint id PK
        bigint tenant_id
        bigint fiscal_period_id FK
        varchar numero UK
        timestamptz entry_date
        varchar origem_tipo
        bigint origem_id
    }

    journal_entry_lines {
        bigint id PK
        bigint journal_entry_id FK
        bigint chart_account_id FK
        numeric debito
        numeric credito
    }

    taxes {
        bigint id PK
        bigint tenant_id
        bigint tax_group_id FK
        varchar codigo
        varchar nome
        numeric taxa
        boolean ativo
    }

    tax_groups {
        bigint id PK
        bigint tenant_id
        varchar nome
    }

    tax_transactions {
        bigint id PK
        bigint tenant_id
        bigint tax_id FK
        varchar referencia_tipo
        bigint referencia_id
        numeric base_imponivel
        numeric tax_amount
    }

    fixed_assets {
        bigint id PK
        bigint tenant_id
        varchar codigo UK
        varchar nome
        bigint chart_account_id FK
        date data_aquisicao
        numeric valor_aquisicao
        numeric valor_residual
        integer vida_util_meses
        varchar metodo_amortizacao
        varchar estado
    }

    depreciation_schedules {
        bigint id PK
        bigint fixed_asset_id FK
        bigint fiscal_period_id FK
        numeric valor_amortizacao
        numeric valor_acumulado
        numeric valor_contabilistico
        bigint journal_entry_id FK
        varchar status
    }

    budget_accounts {
        bigint id PK
        bigint tenant_id
        bigint fiscal_year_id FK
        bigint chart_account_id FK
        numeric valor_orcamentado
    }

    period_closings {
        bigint id PK
        bigint tenant_id
        bigint fiscal_period_id FK
        varchar status
        boolean verificacoes_ok
        timestamptz encerrado_em
        bigint encerrado_por
    }

    closing_checks {
        bigint id PK
        bigint period_closing_id FK
        varchar verificacao
        varchar status
        text detalhe
    }

    account_types ||--o{ chart_of_accounts : "classifica"
    fiscal_years ||--o{ fiscal_periods : "tem"
    fiscal_periods ||--o{ journal_entries : "contem"
    journal_entries ||--o{ journal_entry_lines : "tem"
    chart_of_accounts ||--o{ journal_entry_lines : "usada em"
    chart_of_accounts ||--o{ fixed_assets : "registada em"
    chart_of_accounts ||--o{ budget_accounts : "orcada"
    tax_groups ||--o{ taxes : "agrupa"
    taxes ||--o{ tax_transactions : "aplicada em"
    fixed_assets ||--o{ depreciation_schedules : "amortizada em"
    fiscal_periods ||--o{ depreciation_schedules : "processa"
    journal_entries ||--o{ depreciation_schedules : "origina"
    fiscal_years ||--o{ budget_accounts : "orcada em"
    fiscal_periods ||--o{ period_closings : "encerrada por"
    period_closings ||--o{ closing_checks : "verificada em"
```

## Fluxo de Lancamento Contabilistico

```mermaid
sequenceDiagram
    participant Origem
    participant Contabilidade
    participant BD

    Origem->>Contabilidade: lancar(origem_tipo, origem_id, linhas[])
    Contabilidade->>BD: SELECT fiscal_period WHERE status = aberto
    alt periodo fechado
        Contabilidade-->>Origem: erro — periodo fiscal fechado
    else
        Contabilidade->>Contabilidade: validar debito = credito
        alt desequilibrio
            Contabilidade-->>Origem: erro — debito != credito
        else
            Contabilidade->>BD: INSERT journal_entries
            Contabilidade->>BD: INSERT journal_entry_lines (N linhas)
            Contabilidade-->>Origem: lancamento registado
        end
    end
```

## Fluxo de Processamento de Amortizacoes

```mermaid
sequenceDiagram
    actor Contabilista
    participant Contabilidade
    participant BD

    Contabilista->>Contabilidade: POST /depreciation/processar (fiscal_period_id)
    Contabilidade->>BD: SELECT fixed_assets WHERE estado = activo
    loop para cada activo
        Contabilidade->>BD: SELECT depreciation_schedules (calcular valor do periodo)
        Contabilidade->>BD: INSERT journal_entries (origem_tipo=depreciation)
        Contabilidade->>BD: INSERT journal_entry_lines (debito: gastos, credito: amort acumulada)
        Contabilidade->>BD: UPDATE depreciation_schedules SET status=lancado, journal_entry_id
    end
    Contabilidade-->>Contabilista: N amortizacoes processadas
```

## Fluxo de Encerramento de Periodo

```mermaid
sequenceDiagram
    actor Contabilista
    participant Contabilidade
    participant BD

    Contabilista->>Contabilidade: POST /period-closings (fiscal_period_id)
    Contabilidade->>BD: INSERT period_closings (status=em_fecho)
    Contabilidade->>BD: INSERT closing_checks (pendente x N verificacoes)

    Contabilista->>Contabilidade: POST /period-closings/{id}/verificar
    loop para cada verificacao
        Contabilidade->>BD: executar verificacao
        alt verificacao ok
            Contabilidade->>BD: UPDATE closing_checks SET status=ok
        else erro encontrado
            Contabilidade->>BD: UPDATE closing_checks SET status=erro, detalhe
        end
    end

    alt todas ok
        Contabilidade->>BD: UPDATE period_closings SET verificacoes_ok=true
        Contabilista->>Contabilidade: POST /period-closings/{id}/encerrar
        Contabilidade->>BD: UPDATE period_closings SET status=fechado
        Contabilidade->>BD: UPDATE fiscal_periods SET status=fechado
        Contabilidade-->>Contabilista: periodo encerrado
    else erros pendentes
        Contabilidade-->>Contabilista: erro — verificacoes com falhas
    end
```

## Estado do Activo Fixo

```mermaid
stateDiagram-v2
    [*] --> activo : registo do activo
    activo --> totalmente_amortizado : vida_util esgotada
    activo --> alienado : alienacao registada
    totalmente_amortizado --> alienado : alienacao registada
    alienado --> [*]
```

## Estrutura do Plano de Contas

```mermaid
flowchart TD
    A[Plano de Contas] --> B[Activo\nnatureza=debito]
    A --> C[Passivo\nnatureza=credito]
    A --> D[Capital\nnatureza=credito]
    A --> E[Receita\nnatureza=credito]
    A --> F[Despesa\nnatureza=debito]
    B --> G[Activos Fixos\nfixed_assets]
    B --> H[Caixa e Banco\ntesouraria]
    E --> I[Vendas\nfaturacao]
    F --> J[Gastos\ncompras RH]
```
