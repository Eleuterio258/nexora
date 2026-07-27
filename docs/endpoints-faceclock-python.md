# Endpoints do FaceClock (Python/FastAPI)

> Base URL de produção: `https://asseduidade.e258tech.tech`
> Todos os endpoints (exceto health/metrics) requerem a header `X-API-Key`.
> O FaceClock não verifica permissões de utilizador — só valida a API Key.

---

## 1. Health & Monitoring

| Método | Endpoint | Auth | Descrição |
|--------|----------|------|-----------|
| GET | `/health` | - | Status da aplicação |
| GET | `/ready` | - | Readiness probe (verifica base de dados) |
| GET | `/metrics` | - | Métricas Prometheus |

---

## 2. Biometria Facial

Prefixo: `/api/v1`

| Método | Endpoint | Auth | Descrição | Rate Limit |
|--------|----------|------|-----------|------------|
| POST | `/api/v1/biometric/enroll` | `X-API-Key` | Cadastrar rosto (3+ capturas base64) | 20/hora |
| POST | `/api/v1/biometric/verify` | `X-API-Key` | Verificar rosto contra template | 30/minuto |

### Body de `/biometric/enroll`

```json
{
  "user_id": "123",
  "captures": [
    { "image_base64": "..." },
    { "image_base64": "..." },
    { "image_base64": "..." }
  ]
}
```

### Body de `/biometric/verify`

```json
{
  "user_id": "123",
  "image_base64": "..."
}
```

---

## 3. Impressão Digital

Prefixo: `/api/v1`

| Método | Endpoint | Auth | Descrição | Rate Limit |
|--------|----------|------|-----------|------------|
| POST | `/api/v1/fingerprint/enroll` | `X-API-Key` | Cadastrar template digital | 20/hora |
| POST | `/api/v1/fingerprint/identify` | `X-API-Key` | Identificar utilizador por digital | 30/minuto |
| DELETE | `/api/v1/fingerprint/enroll/{user_id}` | `X-API-Key` | Remover enrolamento digital | 20/hora |

### Body de `/fingerprint/enroll`

```json
{
  "user_id": "123",
  "erp_funcionario_id": "82",
  "finger_type": "right_thumb",
  "template_base64": "..."
}
```

### Body de `/fingerprint/identify`

```json
{
  "template_base64": "..."
}
```

> Nota: A identificação 1:N real requer leitor de impressão digital externo. A app Android usa BiometricPrompt apenas como prova de presença.

---

## 4. Liveness (Selfie com Prova de Vida)

Prefixo: `/api/v1`

| Método | Endpoint | Auth | Descrição | Rate Limit |
|--------|----------|------|-----------|------------|
| POST | `/api/v1/liveness/challenge` | `X-API-Key` | Gerar desafio (piscar/sorrir/virar) | - |
| POST | `/api/v1/liveness/verify` | `X-API-Key` | Verificar desafio + fazer match facial | 20/minuto |

### Body de `/liveness/challenge`

```json
{
  "user_id": "123"
}
```

Resposta:

```json
{
  "challenge_id": "...",
  "action": "BLINK",
  "prompt": "Pisque os olhos",
  "expires_in_seconds": 45
}
```

### Body de `/liveness/verify`

```json
{
  "user_id": "123",
  "challenge_id": "...",
  "frames_base64": ["...", "...", "..."]
}
```

---

## 5. Auditoria

Prefixo: `/api/v1`

| Método | Endpoint | Auth | Descrição |
|--------|----------|------|-----------|
| GET | `/api/v1/audit/logs` | `Authorization: Bearer <token>` | Logs de auditoria (proxy para ERP) |

> Este endpoint é um **proxy** para o ERP. Quem pode ver logs é decidido pelo ERP (`auditoria:ver_logs`).

Parâmetros de query opcionais:
- `modulo`
- `user_id`
- `entidade`
- `entidade_id`
- `acao`
- `page`
- `limit`

---

## Resumo por categoria

| Categoria | Endpoints |
|-----------|-----------|
| Health | `GET /health`, `GET /ready`, `GET /metrics` |
| Facial | `POST /api/v1/biometric/enroll`, `POST /api/v1/biometric/verify` |
| Digital | `POST /api/v1/fingerprint/enroll`, `POST /api/v1/fingerprint/identify`, `DELETE /api/v1/fingerprint/enroll/{user_id}` |
| Liveness | `POST /api/v1/liveness/challenge`, `POST /api/v1/liveness/verify` |
| Auditoria | `GET /api/v1/audit/logs` |

---

## Autenticação

O FaceClock usa apenas `X-API-Key` para os endpoints biométricos:

```bash
curl -X POST https://asseduidade.e258tech.tech/api/v1/biometric/enroll \
  -H "X-API-Key: <segredo>" \
  -H "Content-Type: application/json" \
  -d '{"user_id":"123","captures":[{"image_base64":"..."},...]}'
```

A `X-API-Key` é configurada no ERP (`FACECLOCK_API_KEY`) e nunca é exposta aos utilizadores finais.

---

## Referências

- [Permissões de Assiduidade: ERP vs FaceClock](./permissoes-assiduidade-erp-faceclock.md)
- [Permissões por Módulo](./permissoes-por-modulo.md)
