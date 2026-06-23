# Dependencias do Modulo de Empresas

## Papel no ERP

O modulo `empresas` e a base do modelo multi-tenant.

## Dependencias funcionais

- `seguranca` depende de `companies` para associar utilizadores por empresa
- `modulo-faturacao`, `compras`, `tesouraria`, `contabilidade`, `recursos-humanos`, `gestao-clientes`, `gestao-produtos` e `gestao-stock` devem guardar `company_id` ou `tenant_id`
- `company_users` referencia utilizadores do modulo `seguranca`
- `company_branches` pode ser referenciado por stock, tesouraria, rh e faturacao

## Regra recomendada

- `companies` e o owner do tenant
- nenhum outro modulo deve recriar tabela de empresa
- toda query de negocio deve ser filtrada por `company_id`
