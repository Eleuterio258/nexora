# Endpoints de Assiduidade — Nexora

## Base URL

```
https://api.nexora.e258tech.tech
```

Em desenvolvimento pode ser sobrescrito pela variável de ambiente `ERP_BASE_URL`.

## Autenticação

Todos os endpoints exigem autenticação via JWT no header:

```http
Authorization: Bearer <TOKEN>
```

## Métodos de marcação suportados

### Colaborador (self-service)

| Método da app | Código no ERP | Origem guardada |
|---|---|---|
| `pin` | `pin` | `app` |
| `qr_code` | `qr` | `qr` |
| `nfc` | `nfc` | `nfc` |
| `selfie_gps` | `selfie` | `selfie` |
| `facial` | `reconhecimento_facial` | `reconhecimento_facial` |
| `fingerprint` | `impressao_digital` | `impressao_digital` |

> **Nota:** o método `manual` só pode ser usado por gestor/RH através de `POST /api/rh/assiduidade/ponto`. O colaborador não tem acesso a marcações manuais na app.

## Endpoints

---

### 1. Colaborador marca o próprio ponto

```http
POST /api/self-service/assiduidade/ponto
```

Permissão: `assiduidade:marcar_ponto`

O colaborador não precisa indicar se é entrada ou saída. O backend infere automaticamente pela paridade dos eventos do dia.

#### Payload

```json
{
  "metodo": "pin",
  "pin": "123456",
  "latitude": -25.95,
  "longitude": 32.58,
  "tipo_evento_codigo": "entrada"
}
```

Campos:

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `metodo` | string | sim | `pin`, `qr_code`, `nfc`, `selfie_gps`, `facial`, `fingerprint` |
| `pin` | string | apenas para `pin` | Código PIN do colaborador |
| `tipo_evento_codigo` | string | não | `entrada`, `saida`, `intervalo_inicio`, `intervalo_fim`. Se omitido, o backend infere. |
| `latitude` | number | não | Latitude GPS |
| `longitude` | number | não | Longitude GPS |
| `localidade_id` | number | não | ID da localidade para validação de geofence |
| `observacoes` | string | não | Observações livres |
| `dados` | object | não | Dados extra do método (ex.: `qr_code`, `nfc_tag_id`, `image_base64`) |

#### Resposta de sucesso — 201 Created

```json
{
  "id": 123,
  "tipo_evento_codigo": "entrada",
  "tipo_evento_nome": "Entrada",
  "metodo_codigo": "pin",
  "ocorrido_em": "2026-08-01T12:35:00Z",
  "estado": "valido"
}
```

#### Exemplos por método

**NFC:**

```json
{
  "metodo": "nfc",
  "dados": {
    "nfc_tag_id": "0E6A8A2584695F"
  }
}
```

**QR Code:**

```json
{
  "metodo": "qr_code",
  "dados": {
    "qr_code": "conteudo-do-qr"
  }
}
```

**Selfie + GPS:**

```json
{
  "metodo": "selfie_gps",
  "latitude": -25.95,
  "longitude": 32.58,
  "dados": {
    "image_base64": "/9j/4AAQ..."
  }
}
```

---

### 2. QR Code do Funcionário (Modo 1)

Neste modo, o funcionário apresenta um **QR Code pessoal** ao terminal NEXORA. O terminal lê o código, identifica o funcionário e regista o ponto.

#### 2.1 Funcionário gera o QR Code pessoal

```http
GET /api/self-service/assiduidade/qr/me
```

Permissão: `assiduidade:marcar_ponto`

Gera um QR Code temporário (60 segundos) vinculado ao funcionário autenticado. Pode ser apresentado na app NEXORA ou impresso no crachá.

#### Resposta de sucesso — 201 Created

```json
{
  "qr_code": "qr_a1b2c3d4...",
  "expires_at": "2026-08-01T12:36:00Z",
  "funcionario_id": 42
}
```

#### 2.2 Terminal lê o QR e regista o ponto

```http
POST /api/hardware/assiduidade/qr/registar
```

Autenticação: `X-API-Key` do dispositivo terminal.

O terminal envia o QR Code lido. O backend valida o token, identifica o funcionário e regista o ponto num único passo.

#### Payload

```json
{
  "qr_code": "qr_a1b2c3d4..."
}
```

#### Resposta de sucesso — 201 Created

```json
{
  "id": 200,
  "tipo_evento_codigo": "entrada",
  "metodo_codigo": "qr",
  "ocorrido_em": "2026-08-01T12:35:00Z",
  "estado": "valido"
}
```

---

### 3. QR Code Dinâmico do Terminal (Modo 2)

Neste modo, o **terminal NEXORA gera um QR Code temporário** (60 segundos). O funcionário usa a app NEXORA Mobile para fazer scan, e a app comunica com o servidor para registar o ponto.

#### 3.1 Terminal gera o QR Code dinâmico

```http
POST /api/hardware/assiduidade/qr/gerar-terminal
```

Autenticação: `X-API-Key` do dispositivo terminal.

Gera um QR Code de curta duração vinculado ao terminal e à localização. Não contém `funcionario_id`.

#### Resposta de sucesso — 201 Created

```json
{
  "qr_code": "qr_x9y8z7w6...",
  "expires_at": "2026-08-01T12:36:00Z"
}
```

#### 3.2 App NEXORA lê o QR e regista o ponto

```http
POST /api/self-service/assiduidade/ponto
```

Permissão: `assiduidade:marcar_ponto`

A app envia o QR Code lido. O backend valida o token do terminal e regista o ponto para o funcionário autenticado.

#### Payload

```json
{
  "metodo": "qr_code",
  "dados": {
    "qr_code": "qr_x9y8z7w6..."
  }
}
```

#### Resposta de sucesso — 201 Created

```json
{
  "id": 201,
  "tipo_evento_codigo": "entrada",
  "metodo_codigo": "qr",
  "ocorrido_em": "2026-08-01T12:35:00Z",
  "estado": "valido"
}
```

> **Validações do QR:**
> - Token deve existir e pertencer ao tenant.
> - Token não pode estar expirado.
> - Token só pode ser usado uma vez.
> - No Modo 2, o QR não pode ser pessoal (`funcionario_id` deve ser nulo).

---

### 4. Gestor/RH marca ponto para um funcionário

```http
POST /api/rh/assiduidade/ponto
```

Permissão: `recursos-humanos:gerir_funcionarios`

O gestor não precisa indicar o tipo de evento. O backend infere pela paridade dos eventos do dia do funcionário indicado. O gestor pode selecionar o dia e, opcionalmente, a hora.

#### Payload

```json
{
  "funcionario_id": 42,
  "data": "2026-08-01",
  "hora": "17:30",
  "observacoes": "Marcação manual pelo gestor"
}
```

Campos:

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `funcionario_id` | number | sim | ID do funcionário alvo |
| `data` | string | sim | Dia do evento (formato `YYYY-MM-DD`) |
| `hora` | string | não | Hora do evento (formato `HH:MM`). Se omitido, usa a hora actual. |
| `tipo_evento_codigo` | string | não | `entrada`, `saida`, `intervalo_inicio`, `intervalo_fim`. Se omitido, o backend infere. |
| `latitude` | number | não | Latitude GPS |
| `longitude` | number | não | Longitude GPS |
| `localidade_id` | number | não | ID da localidade |
| `observacoes` | string | não | Observações livres |

#### Resposta de sucesso — 201 Created

```json
{
  "id": 124,
  "funcionario_id": 42,
  "tipo_evento_codigo": "saida",
  "metodo_codigo": "manual",
  "ocorrido_em": "2026-08-01T17:30:00Z",
  "estado": "valido"
}
```

---

### 5. Verificação facial

```http
POST /api/self-service/assiduidade/biometria/facial/verificar
```

Permissão: `assiduidade:marcar_ponto`

Verifica se o rosto na imagem corresponde ao colaborador autenticado. Não grava evento de ponto — é apenas uma prova biométrica.

#### Payload

```json
{
  "device_id": "abc-123",
  "image_base64": "/9j/4AAQ...",
  "geo_lat": -25.95,
  "geo_lng": 32.58
}
```

#### Resposta de sucesso — 200 OK

```json
{
  "match": true,
  "reason": "Rosto reconhecido com sucesso"
}
```

---

### 6. Histórico / resumo de assiduidade (colaborador)

```http
GET /api/self-service/assiduidade/
```

Permissão: `assiduidade:ver_assiduidade`

Devolve o histórico e resumo do colaborador autenticado.

#### Resposta de sucesso — 200 OK

```json
{
  "eventos": [
    {
      "id": 123,
      "tipo_evento_codigo": "entrada",
      "metodo_codigo": "pin",
      "ocorrido_em": "2026-08-01T08:30:00Z",
      "estado": "valido"
    }
  ]
}
```

---

### 7. Métodos de marcação ativos

```http
GET /api/self-service/assiduidade/metodos
```

Permissão: `assiduidade:marcar_ponto`

Devolve os métodos de marcação activos para o tenant do colaborador.

#### Resposta de sucesso — 200 OK

```json
{
  "metodos": {
    "pin": { "ativo": true },
    "nfc": { "ativo": true },
    "qr_code": { "ativo": false },
    "selfie": { "ativo": true },
    "facial": { "ativo": true },
    "fingerprint": { "ativo": true }
  }
}
```

---

### 8. RH cria evento manual (tipo obrigatório)

```http
POST /api/rh/eventos
```

Permissão: `recursos-humanos:gerir_funcionarios`

Endpoint genérico para RH criar qualquer evento de assiduidade. Aqui o `tipo_evento_codigo` é obrigatório.

#### Payload

```json
{
  "funcionario_id": 42,
  "tipo_evento_codigo": "entrada",
  "origem": "manual",
  "metodo_codigo": "manual",
  "ocorrido_em": "2026-08-01T08:30:00Z",
  "data_referencia": "2026-08-01",
  "observacoes": "Correção manual"
}
```

#### Resposta de sucesso — 201 Created

```json
{
  "id": 125,
  "tipo_evento_codigo": "entrada",
  "metodo_codigo": "manual",
  "ocorrido_em": "2026-08-01T08:30:00Z",
  "estado": "valido"
}
```

---

## Inferência automática de entrada/saída

Quando `tipo_evento_codigo` não é enviado, o backend conta quantos eventos `entrada`/`saida` já existem no dia do funcionário:

- número par (0, 2, 4...) → próximo evento é `entrada`
- número ímpar (1, 3, 5...) → próximo evento é `saida`

Isto permite um único botão "Marcar ponto" na app.

## Códigos de erro comuns

| HTTP | Mensagem | Causa |
|---|---|---|
| 400 | Método de marcação não suportado | `metodo` inválido |
| 400 | tipo_evento_codigo não permitido | Tipo fora de `entrada`, `saida`, `intervalo_inicio`, `intervalo_fim` |
| 400 | pin é obrigatório | Método `pin` sem PIN |
| 403 | PIN incorrecto | PIN errado |
| 403 | Marcação por 'X' desactivada | Método desactivado para o tenant |
| 403 | Sem permissão para registar eventos deste funcionário | Gestor sem permissão sobre o funcionário |
| 412 | PIN não configurado | Colaborador sem PIN activo |
| 404 | Funcionário não encontrado | `funcionario_id` inválido/inexistente |
