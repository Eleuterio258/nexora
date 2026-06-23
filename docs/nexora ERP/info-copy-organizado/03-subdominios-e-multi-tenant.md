# Subdominios e Multi-Tenant

## Exemplo de subdominios

```text
erp.e258tech.tech
api.e258tech.tech
admin.e258tech.tech

tenant1.e258tech.tech
tenant2.e258tech.tech
tenant3.e258tech.tech
```

Cada tenant representa uma empresa cliente.

## Estrategias multi-tenant

### 1. Banco unico com `tenant_id`

```text
companies
customers
products
invoices
```

Todas as tabelas com `tenant_id`.

### 2. Banco por empresa

```text
erp_company1
erp_company2
erp_company3
```

### 3. Schema por empresa no PostgreSQL

```text
tenant1.customers
tenant2.customers
tenant3.customers
```
