# API — Modulo Autenticacao

## Autenticacao

| Metodo | Rota | Descricao |
| --- | --- | --- |
| POST | /api/auth/login | Autenticar com email e password; devolve access_token e refresh_token |
| POST | /api/auth/logout | Encerrar sessao actual (revoga o token) |
| POST | /api/auth/refresh | Renovar access_token com refresh_token valido |
| GET | /api/auth/me | Obter dados do utilizador autenticado |
| POST | /api/auth/change-password | Alterar password (requer password actual) |
| POST | /api/auth/forgot-password | Solicitar link de recuperacao de password |
| POST | /api/auth/reset-password | Redefinir password com token de recuperacao |
| POST | /api/auth/verify-email | Verificar email com token enviado por email |

---

## Utilizadores

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/auth/utilizadores | Listar utilizadores do tenant (filtros: estado, search) |
| POST | /api/auth/utilizadores | Criar utilizador |
| GET | /api/auth/utilizadores/{id} | Obter utilizador |
| PUT | /api/auth/utilizadores/{id} | Actualizar utilizador (nome, telefone) |
| POST | /api/auth/utilizadores/{id}/activar | Activar utilizador |
| POST | /api/auth/utilizadores/{id}/bloquear | Bloquear utilizador (com motivo) |
| POST | /api/auth/utilizadores/{id}/desactivar | Desactivar utilizador |

---

## Sessoes

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/auth/sessoes | Listar sessoes activas do utilizador autenticado |
| POST | /api/auth/sessoes/{id}/revogar | Revogar sessao especifica |
| POST | /api/auth/sessoes/revogar-todas | Revogar todas as sessoes excepto a actual |

---

## Historico de Login

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/auth/historico-login | Historico de tentativas de login (filtros: user_id, sucesso, data) |

---

## Chaves de API

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/auth/api-keys | Listar chaves de API do tenant |
| POST | /api/auth/api-keys | Criar chave de API (devolve o valor em claro apenas uma vez) |
| GET | /api/auth/api-keys/{id} | Obter metadados da chave (nunca o valor em claro) |
| PUT | /api/auth/api-keys/{id} | Actualizar nome ou expiracao |
| POST | /api/auth/api-keys/{id}/revogar | Revogar chave de API |
