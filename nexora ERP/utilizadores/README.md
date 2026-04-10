# Modulo de Utilizadores

## Objetivo

Este modulo controla os dados de perfil, preferencias e atividade dos utilizadores do ERP.

## Escopo

- perfis
- preferencias do utilizador
- notificacoes
- dispositivos
- atividade
- tokens
- logs de seguranca do utilizador
- avatar
- configuracoes pessoais

## Entidades principais

- profiles
- user_preferences
- user_notifications
- user_devices
- user_activity
- user_tokens
- user_security_logs
- user_avatar
- user_settings

## Regra principal

O modulo `utilizadores` complementa o modulo `seguranca`.
`seguranca` e dono de autenticacao e RBAC.
`utilizadores` e dono dos dados pessoais e operacionais do utilizador.

## Arquivos

- `database-utilizadores.sql`
- `api-utilizadores.md`
- `views-utilizadores.sql`
- `dependencias-utilizadores.md`
