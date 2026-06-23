# UML — Modulo Assinaturas SaaS / Licencas

## Diagrama de Entidades (ERD)

```mermaid
erDiagram
    payment_gateways {
        bigint id PK
        bigint tenant_id
        varchar codigo UK
        varchar nome
        varchar tipo
        jsonb configuracao
        boolean ativo
    }

    subscription_plans {
        bigint id PK
        bigint tenant_id
        varchar codigo UK
        varchar nome
        numeric preco
        varchar moeda
        varchar ciclo
        integer trial_dias
        integer max_utilizadores
        integer max_filiais
        integer max_produtos
        integer max_documentos_mes
        jsonb modulos
        boolean ativo
    }

    subscription_plan_features {
        bigint id PK
        bigint plan_id FK
        varchar codigo
        varchar descricao
        boolean incluido
    }

    subscriptions {
        bigint id PK
        bigint tenant_id
        bigint customer_id
        bigint plan_id FK
        varchar status
        timestamptz inicio_em
        timestamptz trial_fim_em
        timestamptz proxima_fatura_em
        integer dias_tolerancia
    }

    subscription_billing_cycles {
        bigint id PK
        bigint subscription_id FK
        timestamptz periodo_inicio
        timestamptz periodo_fim
        numeric valor
        varchar status
        bigint invoice_id
    }

    subscription_payments {
        bigint id PK
        bigint subscription_id FK
        bigint billing_cycle_id FK
        bigint payment_gateway_id FK
        numeric valor
        varchar referencia_gateway
        varchar status
        timestamptz pago_em
    }

    subscription_usage {
        bigint id PK
        bigint subscription_id FK
        varchar metrica
        numeric quantidade
        timestamptz periodo_inicio
        timestamptz periodo_fim
    }

    subscription_pauses {
        bigint id PK
        bigint subscription_id FK
        timestamptz pausado_em
        timestamptz retoma_em
        varchar motivo
    }

    subscription_cancellations {
        bigint id PK
        bigint subscription_id FK
        varchar motivo
        timestamptz cancelado_em
        timestamptz efectivo_em
    }

    subscription_events {
        bigint id PK
        bigint tenant_id
        bigint subscription_id FK
        varchar tipo
        text descricao
        jsonb dados
        timestamptz registado_em
    }

    subscription_plans ||--o{ subscription_plan_features : "tem"
    subscription_plans ||--o{ subscriptions : "usada em"
    subscriptions ||--o{ subscription_billing_cycles : "gera"
    subscriptions ||--o{ subscription_payments : "recebe"
    subscriptions ||--o{ subscription_usage : "regista"
    subscriptions ||--o| subscription_cancellations : "pode ter"
    subscriptions ||--o{ subscription_pauses : "pode ter"
    subscriptions ||--o{ subscription_events : "regista"
    subscription_billing_cycles ||--o{ subscription_payments : "pago por"
    payment_gateways ||--o{ subscription_payments : "processa"
```

## Ciclo de Vida da Assinatura

```mermaid
stateDiagram-v2
    [*] --> trial : nova subscricao com trial
    [*] --> activa : nova subscricao sem trial
    trial --> activa : trial expirado + pagamento confirmado
    trial --> expirada : trial expirado sem pagamento
    trial --> cancelada : cancelamento
    activa --> pausada : pausa manual
    pausada --> activa : retoma
    activa --> suspensa : falha pagamento apos tolerancia
    suspensa --> activa : pagamento confirmado (reactivacao)
    activa --> cancelada : cancelamento
    activa --> expirada : nao renovada
    cancelada --> [*]
    expirada --> [*]
```

## Fluxo de Faturacao Automatica

```mermaid
sequenceDiagram
    participant Cron
    participant Assinaturas
    participant Faturacao
    participant Utilizadores
    participant BD

    Cron->>Assinaturas: executar job diario
    Assinaturas->>BD: SELECT subscriptions WHERE proxima_fatura_em <= now() AND status=activa
    loop por cada assinatura
        Assinaturas->>Faturacao: criar fatura (customer_id, valor, periodo)
        Faturacao-->>Assinaturas: invoice_id
        Assinaturas->>BD: INSERT subscription_billing_cycles (status=faturado)
        Assinaturas->>BD: INSERT subscription_payments (status=pendente)
        Assinaturas->>BD: UPDATE subscriptions.proxima_fatura_em += ciclo
        Assinaturas->>BD: INSERT subscription_events (tipo=renovacao)
        Assinaturas->>Utilizadores: notificar cliente (fatura emitida)
    end
```

## Fluxo de Inadimplencia

```mermaid
sequenceDiagram
    participant Cron
    participant Assinaturas
    participant Utilizadores
    participant BD

    Cron->>Assinaturas: verificar pagamentos em atraso
    Assinaturas->>BD: SELECT pagamentos pendentes com vencimento < hoje
    loop por cada assinatura em atraso
        alt dentro do periodo de tolerancia
            Assinaturas->>Utilizadores: aviso de pagamento pendente
        else tolerancia esgotada
            Assinaturas->>BD: UPDATE subscriptions SET status=suspensa
            Assinaturas->>BD: INSERT subscription_events (tipo=suspensao_automatica)
            Assinaturas->>Utilizadores: notificar suspensao de acesso
        end
    end

    note over Utilizadores,BD: Apos pagamento confirmado
    Utilizadores->>Assinaturas: POST /pagamentos/{id}/confirmar
    Assinaturas->>BD: UPDATE subscription_payments SET status=confirmado
    Assinaturas->>BD: UPDATE subscriptions SET status=activa
    Assinaturas->>BD: INSERT subscription_events (tipo=reativacao)
    Assinaturas->>Utilizadores: acesso restaurado
```

## Fluxo de Upgrade de Plano

```mermaid
sequenceDiagram
    actor Cliente
    participant Assinaturas
    participant Faturacao
    participant BD

    Cliente->>Assinaturas: POST /assinaturas/{id}/upgrade (novo_plan_id)
    Assinaturas->>BD: calcular valor pro-rata do ciclo corrente
    Assinaturas->>Faturacao: criar fatura de ajuste (diferenca pro-rata)
    Faturacao-->>Assinaturas: invoice_id
    Assinaturas->>BD: UPDATE subscriptions SET plan_id = novo_plan_id
    Assinaturas->>BD: INSERT subscription_events (tipo=upgrade, dados={plano_anterior, plano_novo})
    Assinaturas-->>Cliente: confirmacao com novos limites activos
```
