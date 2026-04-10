# Modulo de Auditoria

## Objetivo

Registar todas as accoes realizadas por utilizadores em qualquer modulo do ERP, garantindo rastreabilidade completa.

## Escopo

- Registo de criacao, alteracao e eliminacao de entidades
- Identificacao do utilizador, modulo, entidade e accao
- Armazenamento de detalhes da alteracao em JSONB
- Consulta por modulo, utilizador, entidade ou periodo

## Entidades

- `audit_logs`

## Dependencias

- Depende de: `empresas` (tenant_id)
- Recebe dados de: todos os modulos (cada modulo escreve os seus eventos de auditoria)
- Nao tem FK para autenticacao.users para garantir que logs nunca sao perdidos por cascata

## Arquivos

- `database-auditoria.sql`
- `api-auditoria.md`
