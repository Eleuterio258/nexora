# Modulo de Autenticacao

## Objetivo

Gerir contas de utilizador, sessoes activas, historico de login, recuperacao de password e chaves de API.

## Escopo

- Contas de utilizador (criacao, estado, bloqueio, desactivacao)
- Autenticacao por email/password com access_token + refresh_token
- Autenticacao por API Key para integracoes externas
- Gestao de sessoes activas com revogacao por dispositivo
- Historico de tentativas de login (sucesso e falha)
- Recuperacao e redefinicao de password por token

## Entidades

| Tabela | Descricao |
| --- | --- |
| `users` | Contas de utilizador com estado (ativo, bloqueado, pendente, inativo) |
| `sessions` | Sessoes activas com token_hash, IP e expiracao |
| `login_history` | Registo imutavel de todas as tentativas de login |
| `password_resets` | Tokens de recuperacao de password com expiracao |
| `api_keys` | Chaves de API para integracoes externas |

## Dependencias

- Depende de: `empresas` (tenant_id)
- Consumido por: todos os modulos (referenciam `user_id`)
- Modulo irmao: `autorizacao` (atribui roles e permissoes aos users)

## Ficheiros

| Ficheiro | Descricao |
| --- | --- |
| `database-autenticacao.sql` | Schema completo — 5 tabelas, constraints, indices |
| `api-autenticacao.md` | Endpoints REST agrupados por recurso |
| `requisitos.md` | 10 RF + 7 RNF |
| `uml.md` | ERD + fluxo de login + fluxo de recuperacao de password |
