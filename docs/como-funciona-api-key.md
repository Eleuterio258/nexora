# Como Funciona a API Key no Nexora

## O que é uma API Key?

Uma **API Key** é uma "senha secreta" usada para identificar **máquinas, dispositivos ou sistemas** quando falam com uma API. Diferente do JWT (que identifica uma pessoa), a API Key identifica uma **aplicação ou dispositivo**.

No Nexora existem **dois tipos** de API Key:

1. **API Key de dispositivo** — para máquinas físicas (relógios de ponto, terminais POS)
2. **API Key de integração** — para comunicação entre sistemas (ERP ↔ FaceClock)

---

## 1. API Key de Dispositivo (ERP Go)

### Para que serve?

Permite que **dispositivos físicos** (relógios de ponto, leitores de cartão, terminais POS) enviem dados para o ERP sem precisarem de login com email/senha.

### Como é criada?

Quando um gestor regista um dispositivo:

```bash
POST /api/hardware/dispositivos
Authorization: Bearer <token_gestor>
Content-Type: application/json

{
  "nome": "Relógio Ponto Entrada",
  "serial_number": "ZK123456",
  "modelo": "ZKTECO K40",
  "tipo": "relogio_ponto"
}
```

O ERP gera automaticamente uma chave:

```json
{
  "id": 1,
  "api_key": "nk_dev_abcdefghijklmnopqrstuvwxyz123456",
  "api_key_prefix": "nk_dev_abcd",
  "message": "Guarda esta chave, só aparece uma vez."
}
```

> ⚠️ A chave completa **só aparece uma vez**. Se perderes, tens de gerar outra.

### Onde é guardada?

Na base de dados, tabela `hardware.devices`:

```sql
SELECT id, nome, api_key_prefix, api_key_hash, ativo
FROM hardware.devices;
```

| id | nome | api_key_prefix | api_key_hash | ativo |
|---|------|----------------|--------------|-------|
| 1 | Relógio Ponto Entrada | nk_dev_abcd | sha256(...) | true |

> O ERP **nunca** guarda a chave completa. Guarda apenas o **hash** e o **prefixo**.

### Como é validada?

Quando o dispositivo faz um pedido:

```bash
POST /api/hardware/assiduidade/eventos
X-API-Key: nk_dev_abcdefghijklmnopqrstuvwxyz123456
Content-Type: application/json

{
  "funcionario_id": 82,
  "timestamp": "2026-07-26T09:00:00Z",
  "metodo": "facial"
}
```

O ERP executa os seguintes passos (`backend/internal/middleware/device_auth.go`):

```go
apiKey := r.Header.Get("X-API-Key")
if apiKey == "" {
    // Erro 401: API Key em falta
}

err := pool.QueryRow(r.Context(), `
    SELECT id, tenant_id, branch_id, nome, modelo, driver, serial_number, ativo, ip_permitido
      FROM hardware.devices
     WHERE api_key_hash = $1`,
    HashToken(apiKey),
).Scan(...)

if err != nil || !ativo {
    // Erro 401: Dispositivo não autorizado
}

// Verifica IP de origem (opcional)
if ip_permitido != "" && !ipMatches(r, ip_permitido) {
    // Erro 403: IP não autorizado
}
```

Se tudo estiver correto, o ERP injecta o dispositivo no contexto e executa o handler.

### Quem pode criar dispositivos?

Geralmente gestores com permissão `hardware:gerir_dispositivos`.

---

## 2. API Key de Integração (ERP ↔ FaceClock)

### Para que serve?

Permite que o **ERP Go** comunique com o **FaceClock (Python/FastAPI)** de forma segura.

### Configuração

No FaceClock (`.env`):

```bash
ERP_API_KEY=segredo-compartilhado-erp-faceclock
GATEWAY_SHARED_SECRET=outro-segredo-gateway
```

No ERP Go (`.env`):

```bash
FACECLOCK_API_KEY=segredo-compartilhado-erp-faceclock
FACECLOCK_BASE_URL=https://asseduidade.e258tech.tech
```

### Como é usada?

Quando um gestor cadastra um rosto, o ERP chama o FaceClock:

```bash
POST https://asseduidade.e258tech.tech/api/v1/biometric/enroll
X-API-Key: segredo-compartilhado-erp-faceclock
Content-Type: application/json

{
  "user_id": "82",
  "captures": [
    { "image_base64": "..." },
    { "image_base64": "..." },
    { "image_base64": "..." }
  ]
}
```

O FaceClock valida a `X-API-Key` e processa as imagens.

### Identidade do utilizador no FaceClock

O FaceClock não sabe quem é o gestor. O ERP pode enviar headers de confiança:

```bash
X-Auth-User-Id: 82
X-Auth-User-Role: COLABORADOR
X-Auth-Tenant-Id: 7
X-Gateway-Secret: outro-segredo-gateway
```

O `X-Gateway-Secret` impede que alguém que descubra a `X-API-Key` se faça passar por outro utilizador.

---

## 3. Diferença entre JWT e API Key

| Característica | JWT | API Key |
|----------------|-----|---------|
| **Identifica** | Uma pessoa | Uma máquina / aplicação |
| **Obtém-se por** | Login com email/senha | Gerada pelo administrador/sistema |
| **Tempo de vida** | Curto (minutos/horas) | Longo ou indefinido |
| **Transporte** | `Authorization: Bearer ...` | `X-API-Key: ...` |
| **Exemplo** | Gestor a usar a app | Relógio de ponto a enviar marcação |

---

## 4. Fluxo completo: relógio de ponto → ERP → FaceClock

```
┌─────────────────┐      ┌──────────────┐      ┌─────────────┐
│  Relógio de     │      │   ERP Go     │      │  FaceClock  │
│  Ponto (device) │      │  (backend)   │      │  (Python)   │
└────────┬────────┘      └──────┬───────┘      └──────┬──────┘
         │                      │                     │
         │ 1. Envia marcação    │                     │
         │    X-API-Key: chave  │                     │
         │    do relógio        │                     │
         │─────────────────────>│                     │
         │                      │                     │
         │                      │ 2. Valida API Key   │
         │                      │    em hardware.     │
         │                      │    devices          │
         │                      │                     │
         │                      │ 3. Identifica rosto │
         │                      │    X-API-Key: chave │
         │                      │    ERP-FaceClock    │
         │                      │────────────────────>│
         │                      │                     │
         │                      │ 4. Devolve user_id  │
         │                      │<────────────────────│
         │                      │                     │
         │ 5. Responde OK       │                     │
         │<─────────────────────│                     │
         │                      │                     │
```

---

## 5. Segurança

### Boas práticas

1. **Nunca exponhas a API Key no frontend** (app/web). Ela só deve estar em servidores ou dispositivos controlados.
2. **Roda a chave periodicamente** — se suspeitares de vazamento, gera uma nova.
3. **Restringe por IP** — configura `ip_permitido` nos dispositivos quando possível.
4. **Desactiva dispositivos perdidos** — altera `ativo = false` na tabela.
5. **Usa HTTPS sempre** — API Keys não devem transitar em HTTP puro.

### O que acontece se alguém descobrir a API Key?

- **Dispositivo**: pode enviar marcações falsas. Por isso é importante IP allowlist e desactivar rapidamente.
- **Integração ERP-FaceClock**: pode fazer pedidos biométricos. Por isso existe o `GATEWAY_SHARED_SECRET` como camada extra.

---

## 6. Ver dispositivos e chaves no banco de dados

```sql
-- Listar dispositivos
SELECT id, nome, serial_number, modelo, tipo, api_key_prefix, ativo, ultimo_uso_em
FROM hardware.devices;

-- Verificar se uma chave existe (substituir pela chave real)
SELECT id, nome
FROM hardware.devices
WHERE api_key_hash = encode(digest('sua-chave-aqui', 'sha256'), 'hex');
```

> Nota: a função `digest()` requer a extensão `pgcrypto` no PostgreSQL.

---

## 7. Referências

- [Endpoints FaceClock Python](./endpoints-faceclock-python.md)
- [Permissões de Assiduidade: ERP vs FaceClock](./permissoes-assiduidade-erp-faceclock.md)
- `backend/internal/middleware/device_auth.go`
- `backend/internal/modules/hardware/handlers/devices.go`
- `assiduidade_system_backend/app/deps.py`
- `assiduidade_system_backend/app/config.py`
