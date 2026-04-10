# Modulo de Autorizacao

## Objetivo

Gerir o controlo de acesso baseado em roles (RBAC): definicao de roles, permissoes e atribuicao aos utilizadores.

## Escopo

- Definicao de roles por tenant
- Definicao de permissoes por recurso/accao
- Atribuicao de permissoes a roles
- Atribuicao de roles a utilizadores

## Entidades

- `roles`
- `permissions`
- `role_permissions`
- `user_roles`

## Dependencias

- Depende de: `empresas` (tenant_id)
- Depende de: `autenticacao` (user_id em user_roles)
- Consumido por: todos os modulos (verificam permissoes antes de cada operacao)

## Arquivos

- `database-autorizacao.sql`
- `api-autorizacao.md`
