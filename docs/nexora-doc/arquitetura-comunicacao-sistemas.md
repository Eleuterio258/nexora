# Arquitetura de Comunicação — Nexora ERP, FaceClock, App Android e Terminal

> Análise técnica do código de `backend/`, `assiduidade_system_backend/`, `nexora_assiduidade/` e `terminal/`.

## 1. Componentes e responsabilidades

| Componente | Diretório | Tecnologia | Papel |
|------------|-----------|------------|-------|
| **Nexora ERP** | `backend/` | Go (chi) + PostgreSQL | Hub central: RH, assiduidade, permissões, storage, gateway para biometria |
| **FaceClock** | `assiduidade_system_backend/` | Python (FastAPI) + PyTorch | Serviço stateless de biometria facial/digital |
| **App Android** | `nexora_assiduidade/` | Kotlin + CameraX + MediaPipe | Marcação de ponto pelo colaborador/gestor |
| **Terminal** | `terminal/` | Java (Swing) + SQLite | Kiosk local: PIN, QR, NFC, digital simulada |

## 2. Regra geral de comunicação

- **App Android** e **Terminal** falam **diretamente com o ERP**.
- **FaceClock** só é acionado **indiretamente** pelo ERP para *enrollment* e verificação facial.
- Não há comunicação direta App Android ↔ Terminal.
- Não há comunicação Terminal ↔ FaceClock.

```
┌─────────────┐     ┌─────────────┐     ┌─────────────────────┐
│ App Android │────▶│  Nexora ERP │────▶│   FaceClock (Python)│
│  (Kotlin)   │     │    (Go)     │     │  biometria facial   │
└─────────────┘     │  PostgreSQL │     └─────────────────────┘
                    │   Storage   │
┌─────────────┐     │  JWKS / JWT │
│  Terminal   │────▶│  X-API-Key  │
│Java/Swing)  │     └─────────────┘
└─────────────┘
```

## 3. Comunicação ERP ↔ FaceClock

### Endpoints consumidos pelo ERP no FaceClock

`backend/internal/pkg/faceclock/client.go:33-62`

| Método | Endpoint | Finalidade |
|--------|----------|------------|
| `POST` | `/api/v1/biometric/enroll` | Cadastrar template facial |
| `POST` | `/api/v1/biometric/verify` | Verificar rosto e obter comprovativo |
| `POST` | `/api/v1/fingerprint/enroll` | Cadastrar template digital |

Base URL configurável: `FACE_CLOCK_BASE_URL` (`backend/config/config.go:121-126`).

### Autenticação

- O ERP reaproveita o **Bearer JWT** do utilizador autenticado e envia ao FaceClock.
- O FaceClock valida o JWT localmente via **JWKS** do ERP: `GET ${ERP_BASE_URL}/oauth/jwks` (`assiduidade_system_backend/app/oauth_jwks.py:27`).
- Para chamadas internas/gateway, o FaceClock aceita headers `X-Auth-*` + `X-Gateway-Secret` (`assiduidade_system_backend/app/deps.py:143-160`).

### Comprovativo facial (`verification_token`)

Após match bem-sucedido, o FaceClock emite um JWT HS256 (`assiduidade_system_backend/app/security/facial_verification.py:13`):

- `iss = faceclock`
- `aud = nexora-facial-attendance`
- TTL configurável (`FACIAL_VERIFICATION_TTL_SECONDS`, default 90s)
- O ERP valida o token localmente com `FacialVerificationSecret` e consome o `jti` para evitar replay (`backend/internal/modules/self-service/handlers/facial_verification.go:69-101`).

### FaceClock consulta o ERP

- `GET /api/hardware/assiduidade/config` — métodos activos.
- `GET /api/hardware/assiduidade/funcionarios` — lista de funcionários para integração.
- `GET /api/v1/audit/logs` — proxy de audit logs.

### Dados armazenados no FaceClock

Apenas templates biométricos cifrados:

- `FaceTemplate` — embedding 512-d cifrado com AES-256-GCM (`assiduidade_system_backend/app/models.py:15`).
- `FingerprintTemplate` — template digital cifrado (`assiduidade_system_backend/app/models.py:33`).

**O FaceClock é stateless de negócio.** Não guarda funcionários, unidades, dispositivos, registos de ponto, etc. Tudo o resto fica no ERP.

## 4. Fluxo da foto de reconhecimento facial

### 4.1 Enrollment (cadastro)

1. App Android (`EnrollFacialFragment.kt:57-504`) captura 3 fotos com CameraX.
2. Converte cada foto para JPEG 85% e base64 (`EnrollFacialRequest.kt:7-10`).
3. Envia para o ERP: `POST /api/rh/funcionarios/biometria/facial/enroll`.
4. ERP valida consentimento LGPD e faz proxy para FaceClock: `POST /api/v1/biometric/enroll`.
5. FaceClock (`app/services/biometric.py:447-472`):
   - Deteta rosto com MediaPipe BlazeFace.
   - Alinha pela posição dos olhos (warp affine).
   - Gera embedding 512-d com FaceNet/InceptionResnetV1 (treinado VGGFace2).
   - Cifra e persiste.

### 4.2 Verificação no momento do ponto

1. App Android (`FacialAttendanceFragment.kt:60-414`) inicia preview com CameraX.
2. MediaPipe on-device guia o enquadramento; **não decide identidade**.
3. Auto-captura quando rosto está centrado (15-55% da imagem, 15 frames bons).
4. Imagem → JPEG 85% + base64 (`bitmapToBase64()`, linhas 395-400).
5. Envia para o ERP: `POST /api/self-service/assiduidade/biometria/facial/verificar`.
6. ERP reenvia para o FaceClock: `POST /api/v1/biometric/verify`.
7. FaceClock compara com embedding armazenado usando **cosine similarity** (limiar default 0.85, `BIOMETRIC_MATCH_THRESHOLD`).
8. Se houver match, devolve `verification_token` JWT.
9. ERP valida o token e marca o ponto.
10. App regista o ponto: `POST /api/self-service/assiduidade/ponto` com `metodo="facial"` e `verification_token`.
11. ERP cria evento em `rh.eventos_assiduidade`.

> **A foto do rosto em si nunca é armazenada** — apenas o embedding cifrado.

## 5. Comunicação Terminal ↔ ERP

O terminal Java/Swing fala apenas com o ERP, usando header `X-API-Key`.

| Ação | Endpoint | Método | Ficheiro |
|------|----------|--------|----------|
| Sincronizar funcionários | `/api/hardware/assiduidade/funcionarios` | `GET` | `ErpApiClient.java:46-57` |
| Enviar marcação | `/api/hardware/events/generic` | `POST` | `ErpApiClient.java:60-75` |
| Gerar QR dinâmico | `/api/hardware/assiduidade/qr/gerar-terminal` | `POST` | `ErpApiClient.java:84-109` |

### Fluxo de marcação

1. Terminal autentica localmente (PIN, QR, NFC, digital simulada).
2. Grava registo em SQLite local (`registo_ponto`).
3. Envia assincronamente para o ERP (`ErpSyncService.java:59-74`).
4. Reenvia falhas a cada 5 min com até 3 retries.

### Modo QR dinâmico

- Terminal pede QR anónimo de 60s ao ERP.
- Mostra no ecrã.
- App Android lê o QR e envia a marcação diretamente para o ERP.
- O terminal não sabe quem marcou nesse modo.

## 6. Comunicação App Android ↔ ERP

### Autenticação

- **OAuth2**: `POST /oauth/token` (password/refresh grant). Tokens em `EncryptedSharedPreferences`.
- **X-API-Key**: para endpoints `/api/hardware/*`. Chave embarcada no build via `local.properties`.

### Endpoints principais

| Funcionalidade | Endpoint | Auth |
|----------------|----------|------|
| Login | `POST /oauth/token` | OAuth2 |
| Home | `GET /api/self-service/home` | Bearer |
| Métodos ativos | `GET /api/self-service/assiduidade/metodos` | Bearer |
| Marcar ponto | `POST /api/self-service/assiduidade/ponto` | Bearer |
| Verificar rosto | `POST /api/self-service/assiduidade/biometria/facial/verificar` | Bearer |
| Enrollment facial | `POST /api/rh/funcionarios/biometria/facial/enroll` | Bearer |
| Evento genérico (fallback) | `POST /api/hardware/events/generic` | X-API-Key |
| Validar NFC | `GET /api/hardware/assiduidade/nfc/validar` | X-API-Key |
| Validar QR | `POST /api/hardware/assiduidade/qr/validar` | X-API-Key |
| Geofence | `GET /api/hardware/assiduidade/geofence/validar` | X-API-Key |

### Fila offline

- `AttendanceRepository.kt:43-87` tenta envio imediato.
- Se falhar, guarda em Room encriptado (`OfflineEventCrypto`).
- `SyncAttendanceWorker.kt:35-112` reenvia a cada 15 min.

## 7. Modelo de dados central no ERP

Tabelas principais (`backend/migrations/20260724080001_baseline_schema.up.sql`):

- `rh.funcionarios` — funcionários.
- `rh.eventos_assiduidade` — cada marcação de ponto.
- `rh.resultados_diarios` — resumo calculado por dia.
- `rh.metodos_marcacao` — métodos disponíveis (PIN, QR, NFC, selfie, facial, digital).
- `rh.facial_verification_uses` — controle anti-replay do token facial.
- `rh.qr_tokens`, `rh.nfc_tags` — credenciais.
- `rh.auditoria_assiduidade` — logs de auditoria.

Fotos de ponto são guardadas em **object storage** (MinIO/local); a tabela guarda apenas `foto_url` (`backend/internal/modules/self-service/handlers/ponto.go:386-394`).

## 8. Pontos de atenção

1. **Terminal não participa do fluxo facial.** A biometria facial é exclusiva da app Android + FaceClock.
2. **FaceClock é stateless.** Depende totalmente do ERP para identidade, tenant e configuração.
3. **Dois modelos de assiduidade coexistem:** `rh.presencas` (legado) e `rh.eventos_assiduidade` + `rh.resultados_diarios` (novo).
4. **Liveness em memória.** Desafios de prova de vida usam cache local, o que não escala para múltiplas réplicas.
5. **Fingerprint é placeholder.** A comparação digital no FaceClock não usa algoritmo de minúcias (`app/routers/fingerprint.py:147-149`).
6. **X-API-Key embarcada no APK.** A chave de device está no build do Android, o que facilita extração.
7. **Tenant ID duplo.** `hardware.devices.tenant_id` usa `empresas.companies.id`, convertido para `saas.tenants.id` nas queries RH.
8. **Segredos defaults inseguros.** O FaceClock falha em produção se `assert_production_secrets()` detectar valores default.

## 9. Avaliação crítica da comunicação

### ✅ O que está correcto

| Aspecto | Avaliação |
|---|---|
| **ERP como hub** | Mantém o ERP como única fonte de verdade para identidade, permissões, tenant e registos de ponto. |
| **FaceClock stateless** | Isolar apenas templates biométricos cifrados reduz a superfície de ataque e simplifica LGPD. |
| **Separação de responsabilidades** | Cada componente tem um papel claro: app/terminal = captura, ERP = orquestração, FaceClock = matching biométrico. |
| **JWT anti-replay** | O `verification_token` com `jti` consumido no ERP impede reutilização do comprovativo facial. |
| **Offline-first parcial** | A app Android e o terminal já filam eventos quando perdem rede. |
| **JWKS local** | O FaceClock valida tokens OAuth2 sem round-trip, o que é eficiente. |
| **Cifra de templates** | Embeddings faciais/digitais cifrados em repouso com AES-256-GCM. |

### ⚠️ Problemas e riscos identificados

1. **Latência duplicada na verificação facial**  
   Cada marcação facial faz `app → ERP → FaceClock → ERP → app`, aumentando tempo de resposta e carga no ERP.

2. **ERP como ponto único de falha (SPOF)**  
   Se o ERP cair, app e terminal ficam inoperacionais. O FaceClock sozinho não consegue autenticar nem validar.

3. **Segurança: `X-API-Key` embarcada no APK**  
   A chave de device pode ser extraída por decompilação, permitindo spoofing de dispositivo.

4. **FaceClock depende 100% do ERP**  
   JWKS, configuração e lista de funcionários vêm do ERP. Isso frustra a independência do serviço biométrico.

5. **Liveness em memória**  
   O desafio de prova de vida usa cache local e não escala para múltiplas réplicas.

6. **Dois modelos de assiduidade**  
   `rh.presencas` (legado) e `rh.eventos_assiduidade` + `rh.resultados_diarios` (novo) coexistem, gerando duplicação lógica.

7. **Fingerprint é placeholder**  
   A identificação digital não usa algoritmo de minúcias e não é confiável.

8. **Falta de circuit breakers**  
   Se o FaceClock falhar, o ERP provavelmente propaga o erro diretamente para a app.

## 10. Possibilidades de melhoria

### A. Reduzir latência da verificação facial
Fazer a app chamar o FaceClock **directamente** para `verify`, depois enviar o `verification_token` para o ERP marcar o ponto:

```
app → FaceClock → app → ERP
```

**Prós:** menos uma parada, menor carga no ERP.  
**Contras:** a app precisa de credenciais válidas para o FaceClock; exige CORS, rate-limit e segurança direta.

### B. Autenticação serviço-a-serviço com mTLS
- Usar mTLS entre ERP e FaceClock.
- Ou service token rotativo de curta duração.
- Substituir `X-API-Key` no APK por OAuth2 Bearer ou device attestation (SafetyNet / Play Integrity).

### C. Tornar o FaceClock mais autónomo
- Cache TTL de JWKS e configuração.
- Cache de lista de funcionários por tenant.
- Modo degraded se o ERP estiver indisponível.

### D. Mensageria assíncrona para enrollment
Para cadastro de rosto (não tempo-real), usar RabbitMQ / NATS / Kafka / SQS:

```
app → ERP → fila → FaceClock → confirmação
```

### E. Consolidar modelos de assiduidade
Migrar self-service e relatórios para `rh.eventos_assiduidade` + `rh.resultados_diarios` e remover `rh.presencas`.

### F. Consolidar endpoints de ponto
Convergir todos os métodos (hardware, self-service, RH) para um único pipeline de eventos normalizados.

### G. Liveness stateless
Mover estado do desafio para Redis ou para um token assinado no cliente, permitindo múltiplas réplicas do FaceClock.

### H. Melhorar matching de digital
Substituir placeholder por biblioteca real de minúcias (SourceAFIS, Neurotechnology) ou remover a funcionalidade.

### I. Observabilidade e resiliência
- Timeout/retry configurável entre ERP e FaceClock.
- Circuit breaker (gobreaker, resilience4j).
- Tracing distribuído (OpenTelemetry) para rastrear app → ERP → FaceClock.

## 11. Recomendação prática

Priorização sugerida:

1. **Curto prazo:**
   - Remover `X-API-Key` hardcoded do APK (usar Bearer ou device attestation).
   - Cache de JWKS e configuração no FaceClock.
   - Consolidar os dois modelos de assiduidade.

2. **Médio prazo:**
   - App chamar FaceClock diretamente para `verify`, mantendo ERP apenas para marcar ponto.
   - mTLS / service token entre ERP e FaceClock.
   - Liveness stateless.

3. **Longo prazo:**
   - Mensageria para enrollment.
   - Event sourcing centralizado para assiduidade.
   - Matching real de fingerprint ou remoção da funcionalidade.

## 12. Conclusão

A comunicação atual está **aceitável para um MVP**, mas **não está pronta para produção em grande escala**. O problema maior não é a topologia hub-and-spoke em si, mas os detalhes de implementação: latência desnecessária, dependência total do ERP, chaves embarcadas e dualidade de modelos. As melhorias mais valiosas são reduzir o caminho da verificação facial, proteger as chaves de device e consolidar o modelo de dados de assiduidade.

---

*Gerado em: 2026-08-03*
