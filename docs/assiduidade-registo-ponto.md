# Registo de Ponto — Métodos e Fluxos

Documentação dos métodos de registo de ponto/assiduidade do Nexora ERP, incluindo os endpoints, identificadores e os dois cenários de uso: **próprio funcionário** e **gestor/RH**.

---

## Identificadores de funcionário

O backend suporta vários identificadores, mas todos resolvem para o identificador canónico interno `funcionario_id` (`rh.funcionarios.id`) através do `FuncionarioResolver`:

| Identificador | Campo na BD | Usado tipicamente em |
|---|---|---|
| `funcionario_id` | `rh.funcionarios.id` | Endpoints de RH/admin |
| `employee_no` | `rh.funcionarios.numero_funcionario` | Endpoints de hardware/dispositivos |
| `user_id` | `rh.funcionarios.user_id` (`auth.users.id`) | Autenticação, biometria |
| `email` | `rh.funcionarios.email` | Login por PIN |

---

## Cenários

### Cenário 1 — Próprio funcionário (self-service)

O funcionário regista o seu próprio ponto através da app Android ou portal.

Características:
- Autenticação por JWT ou API Key de dispositivo.
- Usa identificadores próprios do funcionário (`employee_no`, `email`, `tag_uid`, etc.).
- Validações de geofence, biometria, PIN, etc.

### Cenário 2 — Gestor/RH

O gestor ou RH regista o ponto em nome do funcionário ou gere as credenciais.

Características:
- Autenticação por JWT com permissões de gestão.
- Usa `funcionario_id` diretamente.
- Permite registo manual, cadastro de biometria, tags NFC, QR, etc.

---

## 1. Manual

| Cenário | Quem executa | Endpoint | Método HTTP | Identificador |
|---|---|---|---|---|
| Funcionário | Funcionário na app | `/api/hardware/events/generic` | POST | `employee_no` |
| Gestor/RH | Gestor na app | `/api/hardware/events/generic` | POST | `employee_no` |
| RH | RH no backoffice | `/api/rh/eventos` | POST | `funcionario_id` |

### Exemplo — registo manual via hardware

```json
POST /api/hardware/events/generic
Headers: X-API-Key: <api_key>

{
  "device_serial": "DISPOSITIVO_001",
  "employee_no": "FUNC001",
  "event_time": "2026-07-27T08:00:00Z",
  "event_type": "AUTO",
  "direction": "unknown",
  "credential_type": "manual"
}
```

### Exemplo — registo manual via RH

```json
POST /api/rh/eventos
Headers: Authorization: Bearer <jwt>

{
  "funcionario_id": 10,
  "tipo_evento_codigo": "ENTRADA",
  "metodo_codigo": "manual",
  "origem": "backoffice",
  "ocorrido_em": "2026-07-27T08:00:00Z",
  "data_referencia": "2026-07-27"
}
```

---

## 2. QR Code Pessoal

QR Code vinculado a um funcionário específico. Usado quando o gestor lê o QR pessoal do funcionário.

| Cenário | Quem executa | Endpoint | Método HTTP | Descrição |
|---|---|---|---|---|
| Funcionário | Funcionário gera QR pessoal | `/api/self-service/assiduidade/qr/me` | GET | QR vinculado ao funcionário autenticado |
| Gestor | Gestor lê QR pessoal | `/api/hardware/assiduidade/qr/validar` → `/api/hardware/events/generic` | POST + POST | QR já traz `funcionario_id` |

### Gerar QR pessoal

```http
GET /api/self-service/assiduidade/qr/me
Headers: Authorization: Bearer <jwt>
```

Resposta:

```json
{
  "qr_code": "qr_abc123",
  "expires_at": "2026-07-27T08:05:00Z",
  "funcionario_id": 10
}
```

### Validar QR pessoal

```json
POST /api/hardware/assiduidade/qr/validar
Headers: X-API-Key: <api_key>

{
  "qr_code": "qr_abc123"
}
```

Resposta:

```json
{
  "valid": true,
  "token_id": 1,
  "funcionario_id": 10,
  "employee_no": "FUNC001"
}
```

### Registar ponto

```json
POST /api/hardware/events/generic
Headers: X-API-Key: <api_key>

{
  "device_serial": "DISPOSITIVO_001",
  "employee_no": "FUNC001",
  "event_time": "2026-07-27T08:00:00Z",
  "credential_type": "qr",
  "qr_token_id": 1
}
```

---

## 3. QR Code Fixo (Cartão) — Novo método

QR Code impresso num cartão físico ou fixado num local (ex.: parede, recepção, posto de trabalho). Não tem funcionário vinculado — qualquer funcionário pode lê-lo para registar o seu ponto.

Ideal para substituir cartões NFC/biometria em locais onde os funcionários não têm credenciais físicas pessoais.

| Cenário | Quem executa | Endpoint | Método HTTP | Descrição |
|---|---|---|---|---|
| Gestor | Gestor gera QR fixo | `/api/rh/assiduidade/qr/gerar` | POST | QR sem funcionário vinculado; válido para qualquer funcionário |
| Funcionário | Funcionário lê QR fixo | `/api/hardware/assiduidade/qr/validar` → `/api/hardware/events/generic` | POST + POST | Valida QR e regista ponto do funcionário autenticado |

### Gerar QR fixo

```json
POST /api/rh/assiduidade/qr/gerar
Headers: Authorization: Bearer <jwt>

{
  "location_id": "1",
  "duracao_segundos": 300,
  "funcionario_id": null
}
```

Resposta:

```json
{
  "qr_code": "qr_xyz789",
  "expires_at": "2026-07-27T08:05:00Z"
}
```

### Validar QR fixo

```json
POST /api/hardware/assiduidade/qr/validar
Headers: X-API-Key: <api_key>

{
  "qr_code": "qr_xyz789"
}
```

Resposta (sem `funcionario_id` porque o QR é fixo):

```json
{
  "valid": true,
  "token_id": 2,
  "location_id": "1",
  "funcionario_id": null,
  "employee_no": null
}
```

### Registar ponto

A app do funcionário envia o próprio `employee_no` após validar o QR fixo:

```json
POST /api/hardware/events/generic
Headers: X-API-Key: <api_key>

{
  "device_serial": "DISPOSITIVO_001",
  "employee_no": "FUNC001",
  "event_time": "2026-07-27T08:00:00Z",
  "credential_type": "qr",
  "qr_token_id": 2
}
```

**Nota:** o `credential_type` no ERP é `qr` tanto para QR pessoal como QR fixo. A distinção é feita pelo facto de o QR fixo não ter `funcionario_id` no token.

---

## 4. Reconhecimento Facial

| Cenário | Quem executa | Endpoint | Método HTTP | Descrição |
|---|---|---|---|---|
| Funcionário | Funcionário na app | `POST /biometric/verify` → `POST /api/hardware/events/generic` | POST + POST | Verifica face e regista ponto |
| Gestor/RH | Gestor cadastra face | `/api/rh/funcionarios/{id}/biometria/facial/enroll` | POST | Cadastra face do funcionário |

### Verificar face (FaceClock)

```json
POST https://faceclock.exemplo.com/biometric/verify

{
  "user_id": "FUNC001",
  "device_id": "DISPOSITIVO_001",
  "image_base64": "/9j/4AAQ..."
}
```

### Registar ponto

```json
POST /api/hardware/events/generic
Headers: X-API-Key: <api_key>

{
  "device_serial": "DISPOSITIVO_001",
  "employee_no": "FUNC001",
  "event_time": "2026-07-27T08:00:00Z",
  "credential_type": "face",
  "confidence_score": 0.97,
  "liveness_score": 0.95
}
```

### Enroll facial

```json
POST /api/rh/funcionarios/10/biometria/facial/enroll
Headers: Authorization: Bearer <jwt>

{
  "captures": [
    { "image_base64": "/9j/4AAQ..." },
    { "image_base64": "/9j/4AAQ..." },
    { "image_base64": "/9j/4AAQ..." }
  ]
}
```

---

## 5. Selfie + GPS

| Cenário | Quem executa | Endpoint | Método HTTP | Descrição |
|---|---|---|---|---|
| Funcionário | Funcionário na app | `/api/hardware/assiduidade/geofence/validar` (opcional) → `/api/hardware/events/generic` | GET + POST | Tira selfie e envia coordenadas |
| Gestor/RH | — | — | — | Não há fluxo direto; usa registo manual |

### Validar geofence

```http
GET /api/hardware/assiduidade/geofence/validar?unidade_id=1&latitude=-25.9702&longitude=32.5732
Headers: X-API-Key: <api_key>
```

### Registar ponto

```json
POST /api/hardware/events/generic
Headers: X-API-Key: <api_key>

{
  "device_serial": "DISPOSITIVO_001",
  "employee_no": "FUNC001",
  "event_time": "2026-07-27T08:00:00Z",
  "credential_type": "geolocation",
  "latitude": -25.9702,
  "longitude": 32.5732,
  "foto_url": "data:image/jpeg;base64,/9j/4AAQ..."
}
```

---

## 6. PIN

| Cenário | Quem executa | Endpoint | Método HTTP | Identificador |
|---|---|---|---|---|
| Funcionário (recomendado) | Funcionário na app, já autenticado | `/api/self-service/assiduidade/ponto` | POST | JWT + `pin` |
| Funcionário (legado) | Funcionário na app | `/api/authcode/pin/validate` → `/api/hardware/events/generic` | POST + POST | `email` + `pin` |
| Gestor/RH | Gestor define PIN | `/api/authcode/admin/set-pin` | POST | `user_id` |

### Marcar ponto por PIN (self-service, JWT)

Caminho preferido: verifica o PIN e grava o evento no mesmo pedido, com a
identidade de quem marca (JWT), sem a API Key de dispositivo. Exige a permissão
`assiduidade:marcar_ponto`.

```json
POST /api/self-service/assiduidade/ponto
Headers: Authorization: Bearer <jwt>

{
  "metodo": "pin",
  "pin": "123456"
}
```

Campos opcionais: `tipo_evento_codigo` (`entrada`, `saida`, `intervalo_inicio`,
`intervalo_fim` — sem ele alterna entrada/saída pela paridade dos eventos do
dia), `latitude`, `longitude`, `localidade_id`, `observacoes`.

Resposta `201` com o evento gravado (`origem: "app"`, método `pin`). Respostas
de recusa: `403` PIN incorrecto ou marcação por PIN desactivada no tenant,
`412` PIN não configurado.

Não há limite ao número de marcações por dia — cada uma fica gravada como
evento e o emparelhamento entrada→saída (incluindo saídas e regressos a meio
do dia) é feito por `assiduidade.RecalcularDia` no cálculo do resultado
diário.

### Validar PIN (login por PIN, legado)

```json
POST /api/authcode/pin/validate
Headers: X-API-Key: <api_key>

{
  "email": "funcionario@nexora.test",
  "pin": "123456"
}
```

Resposta:

```json
{
  "access_token": "...",
  "token_type": "Bearer",
  "user": {
    "id": 99,
    "nome": "Ana Silva",
    "email": "funcionario@nexora.test",
    "funcionario_id": 10
  }
}
```

### Registar ponto

```json
POST /api/hardware/events/generic
Headers: X-API-Key: <api_key>

{
  "device_serial": "DISPOSITIVO_001",
  "employee_no": "FUNC001",
  "event_time": "2026-07-27T08:00:00Z",
  "credential_type": "pin"
}
```

### Definir PIN (admin)

```json
POST /api/authcode/admin/set-pin
Headers: Authorization: Bearer <jwt>

{
  "user_id": 99,
  "pin": "123456"
}
```

---

## 7. NFC

| Cenário | Quem executa | Endpoint | Método HTTP | Descrição |
|---|---|---|---|---|
| Funcionário | Funcionário aproxima cartão | `/api/hardware/assiduidade/nfc/validar` → `/api/hardware/events/generic` | GET + POST | Valida tag e regista ponto |
| Gestor/RH | Gestor cadastra tag | `/api/rh/funcionarios/{id}/nfc-tags` | POST | Vincula tag NFC ao funcionário |

### Validar tag

```http
GET /api/hardware/assiduidade/nfc/validar?tag_uid=A1:B2:C3:D4
Headers: X-API-Key: <api_key>
```

Resposta:

```json
{
  "valid": true,
  "funcionario_id": 10,
  "employee_no": "FUNC001",
  "erp_user_id": 99,
  "funcionario": "Ana Silva"
}
```

### Registar ponto

```json
POST /api/hardware/events/generic
Headers: X-API-Key: <api_key>

{
  "device_serial": "DISPOSITIVO_001",
  "employee_no": "FUNC001",
  "event_time": "2026-07-27T08:00:00Z",
  "credential_type": "nfc"
}
```

### Criar tag NFC

```json
POST /api/rh/funcionarios/10/nfc-tags
Headers: Authorization: Bearer <jwt>

{
  "tag_uid": "A1:B2:C3:D4"
}
```

---

## 8. Impressão Digital

| Cenário | Quem executa | Endpoint | Método HTTP | Descrição |
|---|---|---|---|---|
| Funcionário | Funcionário na app | `BiometricPrompt` local → `/api/hardware/events/generic` | POST | Verificação local + evento |
| Gestor/RH | Cadastro no hardware | `/api/v1/fingerprint/enroll` | POST | Cadastra template |
| Gestor/RH | Remoção | `DELETE /api/v1/fingerprint/enroll/{user_id}` | DELETE | Remove template |

### Registar ponto (app)

```json
POST /api/hardware/events/generic
Headers: X-API-Key: <api_key>

{
  "device_serial": "DISPOSITIVO_001",
  "employee_no": "FUNC001",
  "event_time": "2026-07-27T08:00:00Z",
  "credential_type": "fingerprint",
  "confidence_score": 1.0
}
```

### Enroll (hardware)

```json
POST /api/v1/fingerprint/enroll
Headers: X-API-Key: <api_key>

{
  "funcionario_id": 10,
  "finger_type": "right_thumb",
  "template_base64": "..."
}
```

### Identify (hardware)

```json
POST /api/v1/fingerprint/identify
Headers: X-API-Key: <api_key>

{
  "template_base64": "..."
}
```

Resposta:

```json
{
  "success": true,
  "user_id": "99",
  "funcionario_id": 10,
  "employee_no": "FUNC001"
}
```

---

## Resumo comparativo

| Método | Funcionário (self-service) | Gestor/RH | Identificador canónico |
|---|---|---|---|
| Manual | `/api/hardware/events/generic` | `/api/rh/eventos` | `funcionario_id` |
| QR Code Pessoal | Gera QR pessoal (`/api/self-service/assiduidade/qr/me`) | Lê QR pessoal | `funcionario_id` |
| QR Code Fixo (Cartão) | Lê QR fixo | Gera QR fixo (`/api/rh/assiduidade/qr/gerar`) | `funcionario_id` |
| Facial | `/biometric/verify` | `/api/rh/funcionarios/{id}/biometria/facial/enroll` | `funcionario_id` |
| Selfie + GPS | `/api/hardware/events/generic` | Registo manual | `funcionario_id` |
| PIN | `/api/authcode/pin/validate` | `/api/authcode/admin/set-pin` | `funcionario_id` |
| NFC | Aproxima tag NFC | `/api/rh/funcionarios/{id}/nfc-tags` | `funcionario_id` |
| Impressão Digital | `BiometricPrompt` local | `/api/v1/fingerprint/enroll` | `funcionario_id` |

---

## Endpoint genérico central

Quase todos os métodos de registo de ponto enviam o evento final para:

```http
POST /api/hardware/events/generic
```

Campos principais:

| Campo | Descrição |
|---|---|
| `device_serial` | Identificador do dispositivo |
| `employee_no` | Número do funcionário |
| `event_time` | Data/hora do evento (RFC3339) |
| `event_type` | Tipo de evento (ex.: `AUTO`) |
| `direction` | `entry`, `exit` ou `unknown` |
| `credential_type` | `manual`, `qr`, `nfc`, `pin`, `face`, `fingerprint`, `geolocation` |

O ERP infere automaticamente se uma marcação é entrada ou saída pela paridade dos eventos do dia quando `direction = unknown`.
