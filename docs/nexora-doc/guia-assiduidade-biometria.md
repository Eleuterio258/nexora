# Guia — Assiduidade por Biometria

> Passo a passo para implementar marcação de ponto por biometria facial na arquitetura Nexora.

## 1. Tipos de biometria disponíveis

| Método | Onde funciona | Sistema que processa | Estado |
|--------|---------------|----------------------|--------|
| **Facial** | App Android | FaceClock (Python/FastAPI) | Funcional |
| **Impressão digital** | App Android / Terminal (simulada) | FaceClock (placeholder) | Não confiável em produção |
| **Digital real** | Leitor externo USB/OTG | SDK do fabricante + FaceClock | Necessita implementação |

A biometria **facial** é o método pronto para uso. A impressão digital ainda é placeholder e não deve ser usada em produção sem SDK real.

---

## 2. Arquitetura do fluxo

```text
Cadastro (enrollment):
  App/Gestor → ERP → FaceClock → template cifrado guardado

Marcação de ponto:
  App → selfie → ERP → FaceClock → comparação facial
  FaceClock → verification_token (JWT)
  App → ERP → consome token → cria rh.eventos_assiduidade
```

- **App Android**: captura imagem e envia para o ERP.
- **ERP (Go)**: orquestra, valida consentimento, faz proxy para o FaceClock, valida o comprovativo e regista o ponto.
- **FaceClock (Python)**: deteta rosto, gera embedding, compara, emite `verification_token`.
- **PostgreSQL**: guarda eventos, templates, consentimentos, resultados diários.

---

## 3. Cadastrar o rosto (enrollment)

### Quem pode fazer
- O próprio funcionário (`COLABORADOR`).
- Gestor RH (`GESTOR_RH`).
- Administrador (`ADMIN_SISTEMA`).

### Endpoint no ERP (multipart — recomendado)
```http
POST /api/rh/funcionarios/biometria/facial/enroll
Authorization: Bearer <access_token_erp>
Content-Type: multipart/form-data
```

### Campos do form
| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| `funcionario_id` | string/int | Sim | ID interno do funcionário no ERP. |
| `captures` | ficheiros | Sim | Mínimo de **3 fotos** do rosto (JPEG/PNG). Devem enviar-se com o mesmo nome de campo. |

**Requisitos do FaceClock:**
- Mínimo de **3 capturas**.
- Rosto detetado em cada foto.
- Qualidade suficiente (nitidez, iluminação, tamanho relativo).
- Liveness score acima do limiar (`BIOMETRIC_LIVENESS_THRESHOLD`, default 0.7).

### O que o ERP faz internamente
1. Valida consentimento LGPD ativo.
2. Faz upload de cada captura para **MinIO** sob `uploads/tenant-<id>/biometria/enroll/func-<id>/`.
3. Reenvia para o FaceClock com as URLs públicas:
   ```http
   POST /api/v1/biometric/enroll
   Authorization: Bearer <mesmo_token_erp>
   ```
4. O FaceClock faz download das imagens, gera um embedding 512-d, cifra com AES-256-GCM e guarda em `FaceTemplate`.

> **O template facial é armazenado cifrado no FaceClock.** As fotos permanecem no MinIO durante o tempo definido pela política de retenção LGPD (recomendado: 90 dias para auditoria, depois apagadas).

### Resposta de sucesso
```json
{
  "template_id": "550e8400-e29b-41d4-a716-446655440000",
  "user_id": "usr_123",
  "model_version": "facenet-vggface2-1.0",
  "status": "ACTIVE"
}
```

### cURL (multipart)
```bash
curl -X POST https://api.nexora.e258tech.tech/api/rh/funcionarios/biometria/facial/enroll \
  -H "Authorization: Bearer $ERP_ACCESS_TOKEN" \
  -F "funcionario_id=123" \
  -F "captures=@foto1.jpg" \
  -F "captures=@foto2.jpg" \
  -F "captures=@foto3.jpg"
```

### Modo legacy (JSON com base64)
Ainda é possível usar `Content-Type: application/json` com `captures[].image_base64`, mas é menos eficiente para grandes volumes e pode ser descontinuado.

---

## 4. Marcar ponto com reconhecimento facial

### 4.1 App captura selfie e envia para o ERP (multipart — recomendado)
```http
POST /api/self-service/assiduidade/biometria/facial/verificar
Authorization: Bearer <access_token_erp>
Content-Type: multipart/form-data
```

### Campos do form
| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| `image` | ficheiro | Sim | Selfie JPEG/PNG. |
| `device_id` | string | Sim | ID do dispositivo Android. |
| `geo_lat` | float | Não | Latitude do funcionário. |
| `geo_lng` | float | Não | Longitude do funcionário. |

O `user_id` não é enviado pela app; o ERP obtém-o a partir do token de autenticação, impedindo que um colaborador se faça passar por outro.

### 4.2 ERP faz upload para MinIO e reenvia para o FaceClock
1. O ERP guarda a selfie em MinIO sob `uploads/tenant-<id>/biometria/verify/user-<id>/`.
2. Envia a URL pública da imagem ao FaceClock:
   ```http
   POST /api/v1/biometric/verify
   Authorization: Bearer <mesmo_token_erp>
   ```
3. O FaceClock faz download da imagem, executa a verificação e devolve o resultado.

### 4.3 FaceClock responde
**Match positivo:**
```json
{
  "match": true,
  "user_id": "usr_123",
  "confidence_score": 0.94,
  "liveness_score": 0.89,
  "timestamp": "2026-08-03T09:30:00Z",
  "reason": null,
  "verification_token": "eyJhbGciOiJIUzI1NiIs..."
}
```

**Match negativo:**
```json
{
  "match": false,
  "user_id": "usr_123",
  "confidence_score": 0.62,
  "liveness_score": 0.91,
  "timestamp": "2026-08-03T09:30:00Z",
  "reason": "match_below_threshold",
  "verification_token": null
}
```

Possíveis valores de `reason`:
- `invalid_image` — imagem não reconhecida ou corrompida.
- `invalid_image_url` — URL da imagem inacessível ou não permitida.
- `low_quality_capture`
- `liveness_failed`
- `user_not_enrolled`
- `match_below_threshold`

### 4.4 App envia o comprovativo para registar o ponto
```http
POST /api/self-service/assiduidade/ponto
Authorization: Bearer <access_token_erp>
Content-Type: application/json
```

```json
{
  "metodo": "facial",
  "dados": {
    "verification_token": "eyJhbGciOiJIUzI1NiIs...",
    "foto_url": "https://minio.e258tech.tech/nexoraerp/uploads/tenant-7/..."
  }
}
```

> O campo `foto_url` é devolvido pelo ERP no passo 4.1 (verificação) para que o registo de ponto possa guardar a selfie que foi auditada.

### 4.5 ERP valida e cria o evento
1. Verifica assinatura do `verification_token` com `FACIAL_VERIFICATION_SECRET`.
2. Verifica se o `jti` já foi consumido (tabela `rh.facial_verification_uses`).
3. Cria o registo em `rh.eventos_assiduidade`.
4. Recalcula resultados diários em background.

### cURL completo — verificação (multipart)
```bash
curl -X POST https://api.nexora.e258tech.tech/api/self-service/assiduidade/biometria/facial/verificar \
  -H "Authorization: Bearer $ERP_ACCESS_TOKEN" \
  -F "device_id=550e8400-e29b-41d4-a716-446655440000" \
  -F "geo_lat=-8.8368" \
  -F "geo_lng=13.2343" \
  -F "image=@selfie.jpg"
```

### Modo legacy — verificação (JSON com base64)
Ainda é possível usar `Content-Type: application/json` com `image_base64`, mas é menos eficiente e pode ser descontinuado.

### cURL — registo do ponto
```bash
curl -X POST https://api.nexora.e258tech.tech/api/self-service/assiduidade/ponto \
  -H "Authorization: Bearer $ERP_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "metodo": "facial",
    "dados": {
      "verification_token": "eyJhbGciOiJIUzI1NiIs..."
    }
  }'
```

---

## 5. Configuração necessária

### FaceClock
```bash
ENVIRONMENT=production
DATABASE_URL=postgresql+psycopg://user:pass@host:5432/faceclock
BIOMETRIC_ENCRYPTION_KEY=<segredo_aleatorio_32_bytes>
FACIAL_VERIFICATION_SECRET=<segredo_aleatorio_32_bytes>
GATEWAY_SHARED_SECRET=<segredo_aleatorio_32_bytes>
ERP_BASE_URL=https://api.nexora.e258tech.tech
ERP_TOKEN_AUDIENCE=nexora-api
CORS_ORIGINS=https://app.nexora.e258tech.tech
```

### ERP
```bash
FACE_CLOCK_BASE_URL=https://asseduidade.e258tech.tech
FACIAL_VERIFICATION_SECRET=<mesmo_segredo_do_faceclock>

# Object storage — MinIO
STORAGE_PROVIDER=minio
MINIO_ENDPOINT=minio:9000
MINIO_ACCESS_KEY=<access_key>
MINIO_SECRET_KEY=<secret_key>
MINIO_BUCKET=nexoraerp
MINIO_USE_SSL=false
MINIO_REGION=us-east-1
```

### FaceClock (download de imagens)
```bash
IMAGE_DOWNLOAD_TIMEOUT_SECONDS=10
IMAGE_DOWNLOAD_MAX_BYTES=10485760
```

### App Android
Definir no `local.properties` ou `BuildConfig`:
```bash
ERP_BASE_URL=https://api.nexora.e258tech.tech
```

Use `MultipartBody` para enviar as fotos nos endpoints de biometria facial.

---

## 6. Segurança e compliance

| Requisito | Implementação |
|-----------|---------------|
| Fotos temporárias | Upload para MinIO; retenção limitada por política LGPD |
| Template facial | Apenas embedding cifrado no FaceClock (AES-256-GCM) |
| Anti-replay | `jti` consumido em `rh.facial_verification_uses` |
| Consentimento LGPD | Validado no ERP antes do enrollment |
| TLS | Obrigatório em produção |
| Liveness | Heurístico + desafio opcional por piscar/sorrir/virar |
| Autorização | `require_self_or_manager` — colaborador só opera sobre si próprio |
| Input | Multipart/form-data para imagens; JSON legacy mantido em transição |

---

## 7. Problemas conhecidos e melhorias pendentes

| Problema | Localização | Solução recomendada |
|----------|-------------|---------------------|
| Liveness heurístico é fraco | `app/services/biometric.py:391` | Usar `/liveness/challenge` + `/liveness/verify` |
| Cache de liveness em memória | `app/services/liveness_challenge.py:110` | Redis para multi-réplica |
| Fingerprint é placeholder | `app/routers/fingerprint.py:150` | SDK real de leitor digital |
| CORS permissivo em dev | `app/main.py:74` | Restringir origens em produção |
| Rate limit em memória | `app/limiter.py` | Redis para multi-réplica |
| Retenção de fotos no MinIO | `funcionarios_biometria.go`, `biometria.go` | Definir lifecycle policy (ex.: 90 dias) e apagar após auditoria |
| Acesso do FaceClock ao MinIO | `app/services/biometric.py` | Confirmar `STORAGE_PUBLIC_URL` acessível ou usar presigned URLs |

---

## 8. Terminal e biometria

O **terminal Java/Swing** não realiza reconhecimento facial. Suporta:

- PIN
- QR Code
- NFC
- Impressão digital simulada

Para assiduidade por biometria facial, o funcionário deve usar a **app Android** (`nexora_assiduidade`).

---

## 9. Resumo visual

```text
Cadastro:
  App → multipart POST /api/rh/funcionarios/biometria/facial/enroll → ERP
  ERP → upload MinIO → image_url
  ERP → POST /api/v1/biometric/enroll (image_url) → FaceClock
  FaceClock → download → embedding → guarda template cifrado em PostgreSQL

Ponto:
  App → multipart POST /api/self-service/assiduidade/biometria/facial/verificar → ERP
  ERP → upload MinIO → image_url
  ERP → POST /api/v1/biometric/verify (image_url) → FaceClock
  FaceClock → download → verificação → devolve verification_token
  ERP → resposta com foto_url
  App → POST /api/self-service/assiduidade/ponto (verification_token + foto_url) → ERP
  ERP → valida token → cria rh.eventos_assiduidade → recalcula resultados diários
```

---

*Actualizado em: 2026-08-03 — fluxo multipart + MinIO*
