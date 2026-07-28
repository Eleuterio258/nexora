# API Key + Controlo de Tenant e Funcionário

## Pergunta central

> Quando um dispositivo usa API Key, como o sistema sabe qual é o tenant certo e como garante que o funcionário pertence a esse tenant?

A resposta curta: **a API Key identifica o dispositivo, e o dispositivo já está registado no tenant certo.** A partir daí, todos os dados são filtrados por esse tenant.

---

## 1. Dispositivo é registado num tenant específico

Quando crias um dispositivo:

```bash
POST /api/hardware/dispositivos
Authorization: Bearer <token_gestor>
{
  "nome": "Relógio Entrada",
  "serial_number": "ZK123456",
  "tipo": "relogio_ponto"
}
```

O ERP guarda na tabela `hardware.devices`:

```sql
INSERT INTO hardware.devices (
  tenant_id, branch_id, nome, serial_number, tipo, api_key_hash, api_key_prefix, ativo
) VALUES (
  7,                      -- tenant do gestor que criou
  21,                     -- branch/unidade (opcional)
  'Relógio Entrada',
  'ZK123456',
  'relogio_ponto',
  'sha256_da_chave',
  'nk_dev_abcd',
  true
);
```

Resposta ao gestor:

```json
{
  "id": 1,
  "api_key": "nk_dev_abcdefghijklmnopqrstuvwxyz123456",
  "api_key_prefix": "nk_dev_abcd"
}
```

> A chave só aparece uma vez. O ERP guarda o **hash** e o **tenant_id**.

---

## 2. Dispositivo envia evento com API Key

O relógio de ponto captura o rosto do funcionário e envia:

```bash
POST /api/hardware/assiduidade/eventos
X-API-Key: nk_dev_abcdefghijklmnopqrstuvwxyz123456
Content-Type: application/json

{
  "funcionario_id": 82,
  "timestamp": "2026-07-26T09:00:00Z",
  "metodo": "facial",
  "source": "relogio_ponto"
}
```

---

## 3. ERP descobre o tenant pela API Key

O middleware `RequireDeviceAuth` faz:

```go
apiKey := r.Header.Get("X-API-Key")

err := pool.QueryRow(r.Context(), `
    SELECT id, tenant_id, branch_id, nome, modelo, ativo
      FROM hardware.devices
     WHERE api_key_hash = $1`,
    HashToken(apiKey),
).Scan(&deviceID, &tenantID, &branchID, &nome, &modelo, &ativo)
```

Resultado para a chave `nk_dev_...`:

| deviceID | tenantID | branchID | ativo |
|----------|----------|----------|-------|
| 1 | 7 | 21 | true |

> O tenant (7) é descoberto pela API Key. Não vem no body do pedido.

---

## 4. ERP verifica se o funcionário pertence ao tenant

Antes de gravar o evento, o handler `assiduidade_integracao.go` faz:

```sql
SELECT id, tenant_id, nome_completo, estado
FROM rh.funcionarios
WHERE id = 82
  AND tenant_id = 7;
```

Se o funcionário 82 existir e estiver ativo no tenant 7:

✅ **Evento gravado.**

Se não existir:

❌ **Erro 404:** "Funcionário não encontrado neste tenant."

---

## 5. Se o funcionário for de outro tenant?

Imagina:

- Dispositivo do tenant 7 recebe um rosto
- Mas o funcionário identificado tem ID 95 no tenant 8
- O dispositivo envia `funcionario_id: 95`

O ERP faz:

```sql
SELECT * FROM rh.funcionarios
WHERE id = 95 AND tenant_id = 7;
```

❌ **Não encontra.** O evento é rejeitado.

---

## 6. FaceClock também isola por tenant

Quando o ERP precisa verificar uma face no FaceClock:

```bash
POST https://asseduidade.e258tech.tech/api/v1/biometric/verify
X-API-Key: segredo-erp-faceclock
Authorization: Bearer <token_funcionario_ou_gestor>

{
  "user_id": "82",
  "image_base64": "..."
}
```

O FaceClock:

1. Valida a `X-API-Key` (sabe que é o ERP).
2. Lê o `tenant_id` do JWT (`tid` no token) ou do header `X-Auth-Tenant-Id`.
3. Procura o template:

```sql
SELECT * FROM face_templates
WHERE tenant_id = '7'
  AND erp_user_id = '82'
  AND status = 'ACTIVE';
```

> Templates do tenant 8 com `erp_user_id = '82'` **nunca** são considerados.

---

## 7. Fluxo completo com controlo de tenant

```
┌─────────────────┐
│  Relógio de     │  1. Captura rosto do funcionário
│  Ponto          │
│  tenant_id = 7  │
└────────┬────────┘
         │
         │ 2. Envia evento
         │    X-API-Key: nk_dev_...
         │    { funcionario_id: 82 }
         ▼
┌─────────────────┐
│     ERP Go      │  3. Valida API Key
│                 │  4. Descobre tenant_id = 7
│                 │  5. Verifica funcionário 82 no tenant 7
│                 │  6. Se OK, identifica rosto no FaceClock
└────────┬────────┘
         │
         │ 7. Chama FaceClock com X-API-Key + tenant_id
         ▼
┌─────────────────┐
│   FaceClock     │  8. Valida API Key
│                 │  9. Filtra templates por tenant_id = 7
│                 │ 10. Compara rosto
└─────────────────┘
```

---

## 8. Onde cada coisa é controlada

| Controlo | Onde acontece | Como |
|----------|---------------|------|
| Descobrir tenant do dispositivo | ERP middleware `RequireDeviceAuth` | API Key → `hardware.devices.api_key_hash` → `tenant_id` |
| Verificar funcionário no tenant | ERP handler | `SELECT ... FROM rh.funcionarios WHERE id = ? AND tenant_id = ?` |
| Isolar templates faciais | FaceClock | `face_templates.tenant_id` + `apply_tenant()` |
| Isolar eventos de assiduidade | ERP | `rh.eventos_assiduidade.tenant_id` |

---

## 9. Exemplo prático de segurança

### Cenário

- Dispositivo 1: tenant 7 (E258 Tech), API Key = `nk_dev_AAA...`
- Dispositivo 2: tenant 8 (Outra Empresa), API Key = `nk_dev_BBB...`

### Tentativa 1: dispositivo do tenant 7 envia funcionário válido

```bash
POST /api/hardware/assiduidade/eventos
X-API-Key: nk_dev_AAA...
{ "funcionario_id": 82 }
```

ERP:

```sql
-- API Key AAA pertence a tenant_id = 7
SELECT tenant_id FROM hardware.devices WHERE api_key_hash = Hash('nk_dev_AAA...');
-- Resultado: 7

-- Verifica funcionário
SELECT * FROM rh.funcionarios WHERE id = 82 AND tenant_id = 7;
-- Resultado: Eleutério ✅
```

✅ **Evento gravado.**

### Tentativa 2: dispositivo do tenant 8 tenta usar funcionário do tenant 7

```bash
POST /api/hardware/assiduidade/eventos
X-API-Key: nk_dev_BBB...
{ "funcionario_id": 82 }
```

ERP:

```sql
-- API Key BBB pertence a tenant_id = 8
SELECT tenant_id FROM hardware.devices WHERE api_key_hash = Hash('nk_dev_BBB...');
-- Resultado: 8

-- Verifica funcionário
SELECT * FROM rh.funcionarios WHERE id = 82 AND tenant_id = 8;
-- Resultado: vazio ❌
```

❌ **Erro 404.** O dispositivo do tenant 8 não pode gravar eventos para funcionários do tenant 7.

### Tentativa 3: dispositivo roubado do tenant 7 tenta usar em outro IP

Se o dispositivo tiver `ip_permitido` configurado:

```sql
SELECT ip_permitido FROM hardware.devices WHERE id = 1;
-- Resultado: '192.168.1.0/24'
```

E o pedido vem de `10.0.0.5`:

❌ **Erro 403:** "IP não autorizado."

---

## 10. Queries úteis para verificar

### Listar dispositivos e tenants

```sql
SELECT d.id, d.nome, d.tenant_id, t.nome as tenant_nome, d.ativo, d.api_key_prefix
FROM hardware.devices d
JOIN tenants t ON t.id = d.tenant_id;
```

### Ver eventos de assiduidade por tenant

```sql
SELECT id, tenant_id, funcionario_id, metodo, timestamp
FROM rh.eventos_assiduidade
WHERE tenant_id = 7
ORDER BY timestamp DESC
LIMIT 10;
```

### Ver templates faciais por tenant

```sql
SELECT id, tenant_id, erp_user_id, status, created_at
FROM face_templates
WHERE tenant_id = '7'
ORDER BY created_at DESC
LIMIT 10;
```

### Verificar se funcionário pertence a um tenant

```sql
SELECT id, nome_completo, tenant_id
FROM rh.funcionarios
WHERE id = 82 AND tenant_id = 7;
```

---

## Conclusão

A API Key não identifica o funcionário nem o tenant diretamente. Ela identifica o **dispositivo**. E como cada dispositivo está registado num tenant específico, o sistema:

1. Descobre o tenant pela API Key.
2. Verifica se o funcionário existe nesse tenant.
3. Filtra todos os dados (ERP e FaceClock) por esse tenant.

Isto garante que **dispositivos nunca confundem tenants nem funcionários**.

---

## Referências

- [Como Funciona a API Key](./como-funciona-api-key.md)
- [Controlo de Tenant e Funcionário](./controlo-tenant-funcionario.md)
- `backend/internal/middleware/device_auth.go`
- `backend/internal/modules/hardware/handlers/devices.go`
- `backend/internal/modules/recursos-humanos/handlers/assiduidade_integracao.go`
- `assiduidade_system_backend/app/deps.py`
