# Banco, Cache e Kubernetes

## Banco de dados para 1M empresas

A estrategia recomendada e banco unico com `tenant_id`.

```text
companies
users
customers
products
invoices
```

## Cluster distribuido

```text
                DB Router
                   |
        .----------+----------.
        |                     |
    DB Cluster A          DB Cluster B
   (500k tenants)        (500k tenants)
```

Cada cluster pode ter:

```text
Primary DB
  |
  |-- Read Replica 1
  |-- Read Replica 2
  `-- Read Replica 3
```

Tecnologias comuns:

- MySQL Cluster
- PostgreSQL + Citus
- Vitess

## Redis Cluster

Uso principal:

- sessoes
- cache de queries
- rate limiting
- filas

## Kubernetes

```text
Kubernetes Cluster
|
|-- API Pods
|-- Worker Pods
|-- Queue Pods
|-- Cron Jobs
`-- Monitoring
```
