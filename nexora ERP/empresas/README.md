# Modulo de Empresas e Multi-Tenant

## Objetivo

Este modulo controla a estrutura multiempresa do ERP e serve como base de segregacao de dados por tenant.

## Escopo

- cadastro de empresas
- configuracoes da empresa
- filiais
- enderecos
- contactos
- documentos da empresa
- informacao fiscal
- contas bancarias da empresa
- licencas
- associacao entre empresas e utilizadores

## Entidades principais

- companies
- company_settings
- company_branches
- company_addresses
- company_contacts
- company_documents
- company_tax_info
- company_banks
- company_licenses
- company_users

## Regra principal

Todos os modulos do ERP devem referenciar `company_id` ou `tenant_id` para isolamento de dados.

## Arquivos

- `database-empresas.sql`
- `api-empresas.md`
- `views-empresas.sql`
- `dependencias-empresas.md`
