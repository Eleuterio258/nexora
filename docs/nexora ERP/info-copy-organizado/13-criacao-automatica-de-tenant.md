# Criacao Automatica de Tenant por Subdominio

## Objetivo

Permitir que uma nova empresa seja criada automaticamente no ERP e fique acessivel por subdominio proprio.

## Exemplo

```text
empresa1.e258tech.tech
empresa2.e258tech.tech
empresa3.e258tech.tech
```

## Fluxo recomendado

1. Cliente faz registo da empresa
2. Sistema valida disponibilidade do subdominio
3. Sistema cria o tenant na base de dados
4. Sistema gera configuracoes iniciais da empresa
5. Sistema cria utilizador admin inicial
6. Sistema associa plano/licenca
7. Sistema publica o subdominio no proxy
8. Sistema envia email de confirmacao

## Tabelas envolvidas

- companies
- company_settings
- company_licenses
- users
- company_users
- domains ou tenant_domains

## Passos tecnicos

### 1. Registo do tenant

```text
POST /api/public/signup-company
```

### 2. Validacao do subdominio

Regras:

- unico
- sem caracteres invalidos
- sem palavras reservadas

### 3. Provisionamento automatico

Criar:

- empresa
- configuracoes iniciais
- plano padrao
- utilizador admin
- dados padrao do sistema

### 4. Resolucao no proxy

Traefik ou Nginx identifica o host e envia para a aplicacao.
A aplicacao resolve o tenant pelo subdominio.

## Resolucao de tenant

```text
tenant1.e258tech.tech -> tenant_code = tenant1
```

Depois:

```text
SELECT * FROM companies WHERE codigo = 'tenant1'
```

## Requisitos importantes

- idempotencia no provisionamento
- auditoria da criacao
- rollback em caso de falha
- limite por plano
- validacao anti-abuso
