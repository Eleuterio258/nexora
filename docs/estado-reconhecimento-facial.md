# Estado do Reconhecimento Facial — FaceClock

**Data:** 2026-08-05  
**Sistema:** FaceClock (`assiduidade_system_backend/`)  
**Última fase implementada:** Fase 4 (items 4.1 a 4.6)

---

## Resumo

O FaceClock possui um pipeline de reconhecimento facial **enterprise-ready** para os cenários 1:1 e 1:N, com múltiplos modelos de embedding, liveness híbrida, encriptação com rotação de chaves, autenticação HMAC serviço-a-serviço e assinatura opcional de imagem.

A funcionalidade de **impressão digital** ainda usa comparação exacta de base64 e não está pronta para produção biométrica real.

---

## Funcionalidades implementadas

| Área | Implementação |
|---|---|
| **Modelos de embedding** | FaceNet (default), ArcFace placeholder, seleção via `BIOMETRIC_MODEL` |
| **Deteção de face** | MediaPipe BlazeFace + rejeição de múltiplas faces |
| **Alinhamento** | Affine pelos olhos, crop adaptativo ao modelo |
| **Qualidade da captura** | Resolução, nitidez, iluminação, tamanho do rosto, olhos abertos, pose/oclusão |
| **Liveness passiva** | Heurística plugável + classificador ONNX placeholder |
| **Liveness activa** | Desafios BLINK / SMILE / TURN_HEAD com TTL de 45s |
| **1:1 verify** | `POST /api/v1/biometric/verify` |
| **1:N identify** | `POST /api/v1/biometric/identify` via pgvector |
| **Enrollment** | `POST /api/v1/biometric/enroll` com validação LGPD |
| **Encriptação em repouso** | AES-256-GCM, formatos `enc:v1` e `enc:v2` |
| **Rotação de chaves** | Keyring JSON + endpoint `/admin/biometric/re-encrypt` |
| **Provedores de chave** | Environment (self-hosted) |
| **Assinatura de imagem** | Ed25519 opcional/obrigatória via `REQUIRE_IMAGE_SIGNATURE` |
| **RBAC** | Permissões por operação (`biometric:enroll`, `biometric:verify`, etc.) |
| **Métricas** | Tentativas, match rate, EER aproximado, APCER/BPCER operacionais |
| **Liveness challenge store** | Memória (default) ou Redis (`LIVENESS_CHALLENGE_STORE=redis`) |
| **Matching de impressão digital** | ORB features via OpenCV (self-hosted) |
| **Device registry** | Tabela `device_public_keys` para chaves Ed25519 |
| **Cancelable biometrics** | Transformação ortogonal por segredo/version |

---

## Endpoints biométricos expostos

```http
POST /api/v1/biometric/enroll
POST /api/v1/biometric/verify
POST /api/v1/biometric/identify
POST /api/v1/liveness/challenge
POST /api/v1/liveness/verify

POST /api/v1/admin/biometric/force-re-enroll
POST /api/v1/admin/biometric/calibrate-threshold
POST /api/v1/admin/biometric/re-encrypt
```

---

## O que ainda falta

### 1. Matching de minúcias ISO de impressões digitais
- **Estado:** matching baseado em ORB features (OpenCV), funcional mas nao ISO.
- **Solução:** integrar SourceAFIS, NBIS ou similar para matching de minúcias ISO/IEC 19794-2.
- **Ficheiro:** `app/services/fingerprint_matching.py`

### 2. Detector de face mais robusto
- **Estado:** BlazeFace.
- **Solução:** avaliar RetinaFace, YuNet ou MTCNN para cenários de baixa qualidade.
- **Ficheiro:** `app/services/biometric.py`

### 3. mTLS entre ERP e FaceClock
- **Estado:** autenticação HMAC Nexora.
- **Solução:** configurar certificados cliente/servidor na comunicação interna.

### 4. Testes de integração com dados reais
- **Estado:** testes unitários com mocks e imagens sintéticas.
- **Solução:** adicionar fixtures de imagens reais e benchmark de FAR/FRR/EER.
- **Ficheiro:** `tests/`

---

## Testes

```bash
cd assiduidade_system_backend
./venv/Scripts/python -m pytest -q
```

**Resultado actual:** `80 passed, 8 warnings`

---

## Variáveis de ambiente principais

```env
# Modelo e qualidade
BIOMETRIC_MODEL=facenet                    # ou arcface
BIOMETRIC_QUALITY_THRESHOLD=0.55
BIOMETRIC_MAX_YAW=25.0
BIOMETRIC_MAX_PITCH=20.0
BIOMETRIC_MAX_ROLL=15.0

# Liveness
LIVENESS_MODEL=heuristic                   # ou anti_spoofing
LIVENESS_CHALLENGE_STORE=memory            # ou redis
REDIS_URL=redis://localhost:6379/0

# Chaves biométricas (self-hosted)
BIOMETRIC_KEY_PROVIDER=environment
BIOMETRIC_ENCRYPTION_KEY=...               # 32 bytes
BIOMETRIC_ENCRYPTION_KEYS={"v1":"base64...","v2":"base64...","active":"v2"}

# Cancelable biometrics (opcional)
CANCELABLE_TRANSFORM_SECRET=...
CANCELABLE_TRANSFORM_VERSION=v1

# Fingerprint
FINGERPRINT_MATCH_THRESHOLD=0.25

# Assinatura de imagem
REQUIRE_IMAGE_SIGNATURE=false
```

---

## Documentação relacionada

- `docs/arquitetura-reconhecimento-facial.md` — visão arquitetural original
- `docs/analise-arquitetura-reconhecimento-facial.md` — análise do estado vs. arquitetura
- `docs/fase-4-reconhecimento-facial.md` — plano e estado da Fase 4
- `docs/self-hosted-faceclock.md` — guia de deploy self-hosted
- `docs/runbook-rotacao-chaves-self-hosted.md` — rotação de chaves
- `docs/anti-spoofing-onnx.md` — anti-spoofing ONNX
- `docs/proximas-implementacoes-self-hosted.md` — próximas funcionalidades
- `docs/self-hosted-faceclock.md` — guia de deploy self-hosted
- `docs/runbook-rotacao-chaves-self-hosted.md` — rotação de chaves

---

## Pipeline de captura a decisão

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Imagem base64  │────▶│  Qualidade +     │────▶│  Deteção de     │
│  ou image_url   │     │  pose/oclusão    │     │  múltiplas faces│
└─────────────────┘     └──────────────────┘     └─────────────────┘
                                                          │
                          ┌──────────────────┐           │
                          │  Liveness        │◀──────────┘
                          │  (heurística/    │
                          │   PAD + desafio) │
                          └──────────────────┘
                                   │
                          ┌──────────────────┐
                          │  Alinhamento +   │
                          │  embedding       │
                          └──────────────────┘
                                   │
                    ┌──────────────┼──────────────┐
                    ▼              ▼              ▼
              ┌─────────┐   ┌──────────┐   ┌──────────┐
              │ 1:1     │   │ 1:N      │   │ Storage  │
              │ verify  │   │ identify │   │ enc:v2   │
              └─────────┘   └──────────┘   └──────────┘
```

---

## Decisões arquiteturais (ADRs)

### ADR 1 — FaceNet como modelo default
- **Decisão:** usar FaceNet `InceptionResnetV1` treinado em VGGFace2 como default.
- **Razão:** bom equilíbrio entre precisão e tempo de inferência em CPU; já integrado via `facenet-pytorch`.
- **Alternativa:** ArcFace/AdaFace oferecem melhor precisão em benchmarks, mas requerem dependências adicionais.

### ADR 2 — pgvector para 1:N
- **Decisão:** usar PostgreSQL + pgvector para busca por similaridade 1:N.
- **Razão:** evita adicionar outro serviço à stack; a base de dados já é PostgreSQL.
- **Limitação:** para milhões de templates, pode ser necessário FAISS/Milvus dedicado.

### ADR 3 — Encriptação simétrica em repouso
- **Decisão:** AES-256-GCM com chave por tenant/global.
- **Razão:** simplicidade e performance.
- **Risco:** chave comprometida expõe todos os templates. Mitigado por rotação e KMS.

### ADR 4 — Liveness híbrida
- **Decisão:** combinar liveness passiva (heurística/ONNX) com desafio activo.
- **Razão:** nenhuma técnica isolada é suficiente contra todos os ataques.
- **Futuro:** substituir heurística por classificador PAD treinado.

### ADR 5 — Autenticação HMAC Nexora
- **Decisão:** autenticar ERP → FaceClock via HMAC-SHA256 com timestamp/nonce.
- **Razão:** stateless, simples de implementar e auditar.
- **Melhoria futura:** adicionar mTLS como segunda camada.

---

## Matriz de riscos e mitigações

| Risco | Probabilidade | Impacto | Mitigação actual | Mitigação futura |
|---|---|---|---|---|
| Spoofing com foto/vídeo | Média | Alto | Liveness híbrida | Modelo PAD treinado |
| Chave de encriptação comprometida | Baixa | Crítico | KMS + rotação | Cancelable biometrics ✅ |
| Falso match em 1:N | Baixa | Alto | Threshold calibrável | FAISS + re-rank |
| Pose/oclusão degradam precisão | Baixa | Médio | Validação de pose ✅ | Detector RetinaFace |
| Replay de challenge | Baixa | Médio | TTL + consume | Redis + nonce único |
| Man-in-the-middle ERP→FaceClock | Baixa | Crítico | HMAC + TLS | mTLS |
| Templates antigos em modelo obsoleto | Média | Médio | `model_version` + force re-enroll | Migração automática |
| Dispositivo spoofing assinatura | Baixa | Alto | Assinatura Ed25519 + device registry ✅ | mTLS |

---

## Plano de migração sugerido

### Para produção (curto prazo)
1. Configurar `BIOMETRIC_ENCRYPTION_KEY` localmente ou via KMS.
2. Registar chaves publicas dos dispositivos em `/admin/devices/register-key`.
3. Activar `REQUIRE_IMAGE_SIGNATURE=true` quando todos os dispositivos suportarem.
4. Configurar `CANCELABLE_TRANSFORM_SECRET` para activar transformacao cancelavel.

### Médio prazo
1. Substituição do BlazeFace por RetinaFace/YuNet.
2. Calibrar thresholds num dataset interno.
3. Colocar modelo ONNX anti-spoofing em `app/ml_models/anti_spoofing.onnx`.
4. Implementar matching de minucias ISO para impressoes digitais.

### Longo prazo
1. mTLS entre serviços.
2. Device registry com chaves públicas por `device_id`.
3. Avaliação contínua de modelos (ArcFace, AdaFace).

---

## Referências rápidas

| Ficheiro | Responsabilidade |
|---|---|
| `app/routers/biometric.py` | Endpoints enroll/verify/identify |
| `app/services/biometric.py` | Deteção, alinhamento, qualidade, pose |
| `app/services/embedding_models.py` | FaceNet/ArcFace |
| `app/services/liveness_models.py` | Heurística / anti-spoofing ONNX |
| `app/services/liveness_challenge.py` | Desafios activos |
| `app/services/challenge_store.py` | Persistência de challenges |
| `app/security/encryption.py` | AES-GCM v1/v2 + keyring |
| `app/security/key_management.py` | Provedor de chave local |
| `app/security/image_signature.py` | Validação Ed25519 |
| `app/security/cancelable_transform.py` | Transformação cancelavel |
| `app/services/fingerprint_matching.py` | Matching de impressao digital |
| `app/services/device_registry.py` | Registo de chaves publicas |
| `app/models.py` | `FaceTemplate` com `embedding_vector` |
| `app/biometric_metrics.py` | Métricas operacionais |

---

*Documento gerado automaticamente a partir do estado actual do código e dos testes.*
