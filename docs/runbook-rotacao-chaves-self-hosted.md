# Runbook — Rotação de Chaves Biométricas (Self-Hosted)

**Data:** 2026-08-05  
**Sistema:** FaceClock (`assiduidade_system_backend/`)

---

## Quando usar

- Suspeita de comprometimento da chave de encriptação biométrica.
- Política interna de rotação periódica.
- Mudança de infraestrutura ou operador.

---

## Pré-requisitos

- Acesso administrativo ao FaceClock (credencial com `biometric:admin`).
- Nova chave já gerada (32 bytes aleatórios).
- Backup da base de dados recomendado.

---

## Passo 1 — Gerar nova chave

```bash
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

---

## Passo 2 — Adicionar nova chave ao keyring

O formato do keyring JSON é:

```json
{
  "v1": "<base64-da-chave-antiga>",
  "v2": "<base64-da-chave-nova>",
  "active": "v2"
}
```

Converter chaves para base64:

```bash
python -c "import base64; print(base64.b64encode(b'sua-chave-aqui').decode())"
```

Actualizar a variável de ambiente:

```env
BIOMETRIC_ENCRYPTION_KEYS={"v1":"base64-antiga","v2":"base64-nova","active":"v2"}
```

**Importante:** manter a chave antiga no keyring para poder ler templates existentes.

---

## Passo 3 — Reiniciar o FaceClock

```bash
# Com Docker Compose
docker-compose restart faceclock

# Ou manualmente
systemctl restart faceclock
```

---

## Passo 4 — Re-encriptar todos os templates

```bash
curl -X POST https://faceclock.seu-dominio.com/api/v1/admin/biometric/re-encrypt \
  -H "Content-Type: application/json" \
  -H "X-Nexora-Access-Key: <access-key>" \
  -H "X-Nexora-Timestamp: <timestamp>" \
  -H "X-Nexora-Nonce: <nonce>" \
  -H "X-Nexora-Content-SHA256: <body-hash>" \
  -H "X-Nexora-Signature: <signature>"
```

Resposta esperada:

```json
{
  "success": true,
  "re_encrypted": 150,
  "failed": 0,
  "active_key_id": "v2",
  "tenant_id": "tenant-1"
}
```

---

## Passo 5 — Verificar integridade

1. Testar um `verify` com um utilizador enrolado.
2. Confirmar que novos enrollments usam a chave activa.

```bash
curl -X POST https://faceclock.seu-dominio.com/api/v1/biometric/verify \
  -H "..." \
  -d '{"user_id":"123","device_id":"...","image_base64":"..."}'
```

---

## Passo 6 — Remover chave antiga (opcional)

**Só depois de confirmar que todos os templates foram re-encriptados com sucesso.**

Actualizar o keyring para conter apenas a nova chave:

```env
BIOMETRIC_ENCRYPTION_KEYS={"v2":"base64-nova","active":"v2"}
```

Reiniciar o FaceClock.

---

## Rotação de transformação cancelável

Se usares `CANCELABLE_TRANSFORM_SECRET`, a rotação é semelhante:

1. Gerar novo segredo.
2. Definir `CANCELABLE_TRANSFORM_VERSION=v2`.
3. Forçar re-enrolamento de todos os utilizadores (os templates antigos ficam incompatíveis).

```bash
curl -X POST https://faceclock.seu-dominio.com/api/v1/admin/biometric/force-re-enroll \
  -H "..."
```

---

## Troubleshooting

| Problema | Causa | Solução |
|---|---|---|
| `invalid_authentication_tag` | Chave antiga removida antes da re-encriptação | Restaurar backup ou re-enrolar |
| `re_encrypted=0, failed=N` | Templates corrompidos ou chave errada | Verificar keyring e logs |
| `transform_version_mismatch` | Segredo cancelável alterado | Force re-enroll |

---

## Checklist

- [ ] Nova chave gerada com 32 bytes aleatórios.
- [ ] Keyring actualizado com chave antiga + nova.
- [ ] FaceClock reiniciado.
- [ ] Endpoint `/admin/biometric/re-encrypt` chamado com sucesso.
- [ ] Verify/identify testados.
- [ ] Chave antiga removida (após validação).
- [ ] Backup da base de dados actualizado.
