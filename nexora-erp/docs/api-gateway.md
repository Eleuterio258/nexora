# API Gateway

O `Traefik` e o gateway HTTP oficial do `nexora-erp`.

## Objetivos

- Centralizar roteamento HTTP dos microservicos.
- Aplicar politicas comuns de seguranca, CORS, compressao e rate limit.
- Validar sessoes no edge para rotas protegidas.
- Propagar contexto autenticado para observabilidade e integracoes futuras.

## Componentes

- Entrada HTTP/HTTPS: `traefik`
- Configuracao dinamica: `infra/traefik/dynamic.yml`
- Validacao central: `GET /api/auth/gateway/validate` no `auth-service`

## Cadeias de middleware

- `gateway-public@file`
- `gateway-protected@file`

`gateway-protected@file` usa `forwardAuth` contra o `auth-service`. Os servicos continuam a validar o JWT localmente; o gateway acrescenta uma validacao no edge e propaga headers de contexto autenticado.

## Headers propagados

- `X-Auth-User-Id`
- `X-Auth-Tenant-Id`
- `X-Auth-Session-Id`
- `X-Auth-User-Email`
- `X-Auth-User-Name`

## Convencao de rotas

Rotas publicas:

- `POST /api/auth/login`
- `POST /api/auth/refresh`
- `POST /api/auth/forgot-password`
- `POST /api/auth/reset-password`
- `POST /api/auth/verify-email`

Rotas protegidas:

- restantes rotas `/api/auth`
- todos os outros modulos `/api/*`

## Dashboard

- URL: `http://localhost/dashboard/`
- utilizador inicial: `admin`
- password inicial: `test`

Essa credencial deve ser trocada antes de producao.
