# Arquitetura de Comunicação — Assiduidade Nexora

> **Data:** 2026-07-27  
> **Escopo:** ERP Go, FaceClock Python, app Android, web admin e dispositivos físicos.

---

## 1. Princípio fundamental

O **Nexora ERP é o centro de gravidade**. O **FaceClock é stateless**: não persiste registos de ponto, funcionários, consentimentos LGPD, auditoria nem configurações. A única excepção são os **templates biométricos** (face e digitais), que ficam no FaceClock por isolamento de dados sensíveis e performance de matching local.

---

## 2. Topologia recomendada

```
┌─────────────────────────────────────────────────────────────┐
│                         CLIENTES                            │
│  Web (JWT)  │  Android (JWT)  │  iOS (JWT)  │  Kiosk (JWT) │
└────────────────────┬────────────────────────────────────────┘
                     │ HTTPS
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                      NEXORA ERP                             │
│  - Auth (OAuth2)                                            │
│  - RH / assiduidade / configuração / LGPD                   │
│  - Único ponto de entrada para clientes                     │
└────────────────────┬────────────────────────────────────────┘
                     │ service-to-service (mTLS + gateway secret)
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                      FACECLOCK                              │
│  - Apenas biometria (face/digital)                          │
│  - Não persiste ponto/auditoria/consentimento               │
└────────────────────┬────────────────────────────────────────┘
                     │ X-API-Key (hardware.devices)
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                   TERMINAIS FÍSICOS                         │
│  - Hikvision, ZKTeco, leitores NFC, etc.                    │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Regra de autenticação por tipo de actor

| Actor | Método de auth | Porquê |
|---|---|---|
| **Pessoa (web, Android, iOS, kiosk)** | `Authorization: Bearer <JWT>` | Já existe login humano; tenant e funcionário vêm do token. |
| **Serviço ERP → FaceClock** | mTLS + `X-Gateway-Secret` + Bearer reencaminhado | Comunicação interna confiável; o ERP actua como proxy seguro. |
| **FaceClock → ERP** | `X-API-Key` de `hardware.devices` | O FaceClock funciona como um "device" a enviar eventos. |
| **Terminal físico autónomo** | `X-API-Key` de `hardware.devices` | Não há login humano no momento do evento. |

> **Regra de ouro:** se o dispositivo é operado por uma pessoa autenticada, usa JWT. Se é uma máquina autónoma, usa API Key.

---

## 4. Problemas da arquitetura actual

### 4.1 Mobile usa `/api/hardware/*` com `X-API-Key`

A app Android Android chama endpoints como:

```bash
POST /api/hardware/events/generic
X-API-Key: <DEVICE_API_KEY>
```

Isso é conceptualmente errado porque:

- `/api/hardware/*` foi desenhado para **terminais físicos autónomos**.
- A app mobile já tem um utilizador autenticado (JWT).
- A chave está hardcoded em `local.properties` / `BuildConfig`, tornando-se extraiível do APK.
- Revogação exige novo build.

### 4.2 FaceClock ainda é acessível directamente pelo mobile

Fluxos antigos ainda fazem a app falar directamente com FaceClock. Isso quebra o princípio stateless e duplica lógica de negócio.

### 4.3 ERP → FaceClock sem mTLS documentado

O segredo partilhado `GATEWAY_SHARED_SECRET` existe, mas a comunicação entre serviços ainda depende de decisões de infraestrutura (rede Docker, DNS, mTLS).

---

## 5. Padrões de comunicação recomendados

### 5.1 Síncrono (REST/JSON)

Usar para operações imediatas:

- Login e refresh token
- Marcação de ponto
- Enrollment facial
- Consulta de histórico
- Aprovação de ausências

**Convenções:**

- Timeout de 30 segundos.
- Respostas padronizadas: `{"data": ..., "error": ...}`.
- Idempotência em operações críticas (ex.: `idempotency_key` na marcação de ponto).

### 5.2 Assíncrono (filas + background jobs)

Usar para operações que não precisam de resposta imediata:

- Cálculo diário de faltas (`process-daily-absences`)
- Reenvio de eventos falhados ao ERP
- Geração de relatórios pesados
- Sincronização de funcionários

**Convenções:**

- Fila persistente (PostgreSQL, RabbitMQ ou Redis Streams).
- Retry com backoff exponencial.
- Dead-letter queue após N tentativas.

### 5.3 Tempo real

Usar para:

- Chat interno (`/ws/chat` — já existe no ERP)
- Notificações push (Firebase Cloud Messaging)
- Alertas de atraso/falta

### 5.4 Batch

Usar para alto volume:

- Reenvio de eventos de presença em lote (`POST /api/hardware/events/batch`)
- Sync de funcionários

---

## 6. Fluxo ideal de marcação de ponto no mobile

### Antes (problemático)

```
App → /api/hardware/events/generic (X-API-Key)
```

### Depois (recomendado)

```
App → /api/self-service/assiduidade/ponto (JWT)
   ERP valida:
     - token
     - tenant
     - método ativo na configuração do tenant
     - geofence/unidade (se aplicável)
     - consentimento LGPD (se facial)
   ERP decide:
     - se facial → chama FaceClock /biometric/verify
     - se QR/NFC/PIN → valida localmente
     - registra evento em rh.eventos_assiduidade
```

**Vantagens:**

- Mobile nunca vê API Key de device.
- Mobile nunca fala directamente com FaceClock.
- Toda a lógica de negócio e auditoria fica no ERP.
- Fácil adicionar novos métodos sem alterar a app.

---

## 7. Segurança por camada

| Camada | Medida |
|---|---|
| Mobile ↔ ERP | HTTPS + OAuth2 PKCE |
| Web admin ↔ ERP | HTTPS + OAuth2 PKCE |
| ERP ↔ FaceClock | mTLS + `X-Gateway-Secret` |
| FaceClock ↔ ERP | `X-API-Key` de `hardware.devices` |
| ERP ↔ Base de dados | TLS + credenciais em secret manager |
| FaceClock armazenamento | Templates biométricos cifrados em repouso |

### Nunca fazer

- ❌ Hardcoded API Key no APK ou em ficheiros versionados.
- ❌ Expor FaceClock publicamente na internet.
- ❌ FaceClock confiar em headers `X-Auth-*` sem `X-Gateway-Secret`.
- ❌ Mobile chamar FaceClock directamente.

---

## 8. Configuração de métodos de assiduidade

Endpoint ERP:

```bash
PUT /api/system/configuracao/tenant/feature/rh.assiduidade
Authorization: Bearer <token>
```

Payload:

```json
{
  "activo": true,
  "configuracao": {
    "metodos": {
      "facial": { "ativo": true },
      "fingerprint": { "ativo": false },
      "qr_code": { "ativo": true },
      "nfc": { "ativo": true },
      "pin": { "ativo": true },
      "geolocation": { "ativo": true },
      "manual": { "ativo": true }
    }
  }
}
```

A app mobile deve consultar esta configuração via:

```bash
GET /api/hardware/assiduidade/config   # enquanto usar X-API-Key
GET /api/self-service/assiduidade/config  # futuro, JWT-only
```

---

## 9. Dispositivos físicos vs. mobile

### Dispositivos físicos autónomos

```
Terminal Hikvision/ZKTeco → FaceClock ou ERP
                          X-API-Key: <hardware.devices.api_key>
```

Manter inalterado. É o caso de uso correcto para API Key.

### Mobile operado por pessoa

```
App Android/iOS → ERP
                Authorization: Bearer <JWT>
```

Não usar `X-API-Key`.

---

## 10. Roadmap de migração sugerido

### Fase 1 — Criar endpoint JWT-only de ponto

- Criar `POST /api/self-service/assiduidade/ponto` no ERP.
- Suportar métodos: QR, NFC, PIN, manual.
- Migrar esses métodos no Android para o novo endpoint.

### Fase 2 — Métodos biométricos via ERP

- Mover `facial` e `fingerprint` para passar pelo ERP.
- ERP chama FaceClock internamente.
- Remover chamadas directas app ↔ FaceClock.

### Fase 3 — Remover API Key hardcoded do mobile

- Remover `DEVICE_API_KEY` de `build.gradle.kts` e `local.properties`.
- Todos os endpoints mobile passam a usar JWT.

### Fase 4 — Reforçar comunicação ERP ↔ FaceClock

- Ativar mTLS entre containers.
- Configurar `GATEWAY_SHARED_SECRET` em produção.
- Garantir que FaceClock não está exposto publicamente.

### Fase 5 — Filas e resiliência

- Implementar fila persistente para reenvio de eventos.
- Adicionar retry com backoff real.
- Monitorar métricas de sync.

---

## 11. Conclusão

A boa comunicação no ecossistema Nexora assenta em três pilares:

1. **ERP como API gateway central** para todos os clientes humanos.
2. **FaceClock isolado**, acessível apenas pelo ERP.
3. **Auth correcta por actor**: JWT para pessoas, API Key apenas para máquinas autónomas.

Seguir esta arquitetura elimina o acoplamento inseguro da API Key no mobile, simplifica a manutenção e reforça o isolamento cross-tenant.
