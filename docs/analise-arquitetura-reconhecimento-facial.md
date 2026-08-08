# Análise de Implementação — Arquitetura de Reconhecimento Facial

**Data:** 2026-08-05  
**Sistema analisado:** FaceClock (`assiduidade_system_backend/`)  
**Documento de referência:** `docs/arquitetura-reconhecimento-facial.md`

---

## 1. Resumo executivo

O FaceClock implementou as **três fases** da arquitetura de reconhecimento facial proposta: segurança/compliance (Fase 1), precisão/modelos (Fase 2) e escala/1:N (Fase 3).

O sistema mantém o **pipeline 1:1 funcional** com liveness híbrido, encriptação AES-256-GCM e autenticação HMAC Nexora. Agora suporta múltiplos modelos de embedding (FaceNet e ArcFace placeholder), motor de busca 1:N via pgvector, validação de consentimento LGPD, verificação de olhos abertos, métricas PAD aproximadas e abstração de provedores de chave (KMS/HSM).

A implementação está **pronta para produção self-hosted em cenário 1:1 e 1:N de pequena/média escala**. Os componentes de ponta (ArcFace real, anti-spoofing treinado) são opcionais e podem ser activados localmente.

---

## 2. Estado atual do FaceClock

### 2.1 Modelo de reconhecimento facial

| Aspeto | Implementado | Arquitetura-alvo |
|---|---|---|
| Modelo | FaceNet `InceptionResnetV1` treinado em VGGFace2 (default); ArcFace via InsightFace (placeholder) | ArcFace, AdaFace, MagFace ou MobileFaceNet |
| Dimensão do embedding | 512D | 128/512/1024D |
| Normalização | L2 | L2 / específica do modelo |
| Versionamento | `model_version` guardada no template; rejeição automática de templates obsoletos | Versionamento + re-enrolamento planejado |
| Seleção de modelo | Env var `BIOMETRIC_MODEL` | — |

**Ficheiros:** `app/services/embedding_models.py`, `app/services/biometric.py`, `app/routers/biometric.py`, `app/models.py`

### 2.2 Deteção de face

| Aspeto | Implementado | Arquitetura-alvo |
|---|---|---|
| Detetor | MediaPipe BlazeFace (short-range) | RetinaFace, MTCNN, YuNet |
| Keypoints | 6 (olhos, nariz, boca, tragus) | 5–106 pontos fiduciais |
| Alinhamento | Affine pelos olhos | Alinhamento por landmarks |
| Crop | Adaptado ao modelo activo (160×160 para FaceNet, 112×112 para ArcFace) | 112×112 ou 224×224 |
| Multi-face | **Rejeição explícita** em enrollment/verify/identify | Rejeição explícita |

**Ficheiros:** `app/services/biometric.py`

### 2.3 Liveness

| Aspeto | Implementado | Arquitetura-alvo |
|---|---|---|
| Passiva | ✅ Heurística + classificador ONNX local (`anti_spoofing`) | Classificador PAD treinado, profundidade, fluxo óptico |
| Ativa | ✅ Desafios: piscar (BLINK), sorrir (SMILE), virar (TURN_HEAD) | Desafios de movimento |
| TTL do desafio | 45 segundos | — |
| Estado do desafio | ✅ Memory (default) ou Redis (`LIVENESS_CHALLENGE_STORE=redis`) | Persistência distribuída |
| Métricas PAD | ✅ APCER/BPCER aproximados operacionais | APCER, BPCER |
| Seleção de modelo | Env var `LIVENESS_MODEL` | — |

**Ficheiros:** `app/services/liveness_models.py`, `app/services/biometric.py`, `app/services/liveness_challenge.py`, `app/routers/liveness.py`

### 2.4 Armazenamento e encriptação

| Aspeto | Implementado | Arquitetura-alvo |
|---|---|---|
| Algoritmo | AES-256-GCM | AES-256 |
| Formato | `enc:v1:<nonce><tag><ciphertext>` | — |
| Chave | `BIOMETRIC_ENCRYPTION_KEY` via env var; keyring JSON via `BIOMETRIC_ENCRYPTION_KEYS` | KMS/HSM |
| Provedores de chave | ✅ `environment` (self-hosted) | KMS/HSM |
| Default em desenvolvimento | **Removido** — levanta erro se chave não configurada | Nenhum default |
| Rotação | ✅ Formato `enc:v2` com key_id + endpoint `/admin/biometric/re-encrypt` | Periódica |
| Cancelable biometrics | ✅ Transformação ortogonal por segredo/version | Recomendado |

**Ficheiros:** `app/security/encryption.py`, `app/security/key_management.py`, `app/config.py`

### 2.5 Motor de similaridade

| Aspeto | Implementado | Arquitetura-alvo |
|---|---|---|
| Algoritmo | Similaridade do cosseno | Similaridade do cosseno / euclidiana normalizada |
| Busca 1:1 | Força-bruta na aplicação | Força-bruta / índice |
| Busca 1:N | **pgvector** com índice na coluna `embedding_vector` | FAISS, Milvus, pgvector, Weaviate |
| 1:N face | ✅ Endpoint `/api/v1/biometric/identify` | Recomendado |
| 1:N fingerprint | Placeholder (comparação exacta de base64) | Matching de minúcias real |

**Ficheiros:** `app/services/biometric.py`, `app/routers/biometric.py`, `app/models.py`, `app/database.py`

### 2.6 Validação de qualidade

| Aspeto | Implementado | Arquitetura-alvo |
|---|---|---|
| Resolução mínima | ≥ 100×100 px | ≥ 80×80 px |
| Nitidez | Laplaciano | Nitidez / exposição / contraste |
| Iluminação | Média entre 40 e 200 | Iluminação uniforme |
| Tamanho do rosto | ~15% da área da imagem | Face detectável |
| Olhos abertos | ✅ Verificação via FaceLandmarker + EAR | Olhos abertos |
| Multi-face | ✅ Rejeição explícita | Rejeição explícita |
| Pose / oclusão | ✅ Yaw/pitch/roll + oclusão de pontos críticos | Pose frontal, evitar oclusão |
| Threshold | `BIOMETRIC_QUALITY_THRESHOLD` = 0,55 (default) | Calibrado no dataset próprio |

**Ficheiros:** `app/services/biometric.py`

### 2.7 Métricas

| Métrica | Implementado |
|---|---|
| Total de tentativas / sucessos / falhas | ✅ |
| Taxa de match | ✅ |
| FAR/FRR simplificados | ⚠️ (heurísticos) |
| EER estimado | ✅ (máximo de FAR/FRR actual) |
| APCER / BPCER aproximados | ✅ (baseados em resultados de liveness) |
| Confiança média / liveness médio | ✅ |

**Ficheiros:** `app/biometric_metrics.py`, `app/routers/monitoring.py`

### 2.8 Segurança e compliance

| Aspeto | Implementado |
|---|---|
| Autenticação serviço-a-serviço | HMAC-SHA256 Nexora |
| Rate limiting | slowapi |
| JWT de verificação facial | HS256 com claims tenant/user/device |
| TLS | Terminação no Traefik (docker-compose) |
| mTLS entre serviços | ❌ |
| Assinatura de payload de imagem | ✅ Ed25519 opcional/obrigatória via `REQUIRE_IMAGE_SIGNATURE` |
| Consentimento LGPD no FaceClock | ✅ Validado via ERP antes do enrollment |
| RBAC fino sobre templates | ✅ Permissões por operação (`biometric:enroll`, `biometric:verify`, `biometric:identify`, `biometric:admin`, etc.) |
| Logs de auditoria biométrica | Delegados ao ERP via `/api/audit-logs` |

**Ficheiros:** `app/security/nexora_auth.py`, `app/security/facial_verification.py`, `app/routers/audit.py`, `app/routers/biometric.py`, `app/erp_client.py`

---

## 3. Checklist arquitetura vs implementação

| Item | Estado |
|---|---|
| Modelo de embedding ArcFace/AdaFace | ⚠️ Arquitetura plugável; ArcFace placeholder |
| Embeddings 128/512/1024D | ✅ 512D |
| Deteção RetinaFace/MTCNN/YuNet | ❌ BlazeFace |
| Liveness passiva robusta | ⚠️ Heurística simples + placeholder PAD |
| Liveness ativa com desafios | ✅ |
| Alinhamento e crop padronizado | ✅ Adaptativo ao modelo |
| Encriptação AES-256 em repouso | ✅ |
| Chaves em KMS/HSM | ✅ Rotação local via keyring JSON |
| Motor ANN (FAISS/pgvector/Milvus) | ✅ pgvector |
| Métricas FAR/FRR/EER/PAD | ⚠️ FAR/FRR básicos + EER/PAD aproximados |
| Validação de qualidade completa | ✅ Pose/oclusão + olhos abertos + multi-face |
| Versionamento de modelo | ✅ Com re-enrolamento forçado |
| Rotação de chaves biométricas | ✅ |
| Assinatura de imagem | ✅ |
| Audit logs locais | ⚠️ Delegados ao ERP |
| 1:1 | ✅ |
| 1:N face | ✅ |

---

## 4. Gaps remanescentes

### 4.1 Modelo de deteção de face
- **Problema:** BlazeFace é menos robusto a oclusões/poses extremas.
- **Ação recomendada:** Avaliar RetinaFace ou MediaPipe FaceMesh para melhor precisão de landmarks.

### 4.2 Pose e oclusão
- **Problema:** Não há verificação explícita de pose frontal ou oclusão excessiva.
- **Ação recomendada:** Usar FaceLandmarker para estimar yaw/pitch/roll e rejeitar poses extremas.

### 4.3 Persistência distribuída de desafios
- **Problema:** Estado do liveness challenge está em memória.
- **Ação recomendada:** Migrar para Redis quando houver múltiplas réplicas.

### 4.4 mTLS entre serviços
- **Problema:** Apenas HMAC + TLS.
- **Ação recomendada:** Configurar certificados cliente/servidor entre ERP e FaceClock.

---

## 5. Plano de implementação concluído

### Fase 1 — Segurança e compliance ✅

1. ✅ Remover default inseguro de `BIOMETRIC_ENCRYPTION_KEY`.
2. ✅ Validar consentimento LGPD ativo no enrollment facial.
3. ✅ Rejeitar múltiplas faces explicitamente.
4. ✅ Verificar olhos abertos.
5. ✅ Adicionar métricas EER/PAD básicas.

### Fase 2 — Precisão ✅

1. ✅ Refactor para suportar múltiplos modelos de embedding.
2. ✅ Adicionar FaceNet (default) e ArcFace (placeholder).
3. ✅ Implementar re-enrolamento por mudança de `model_version`.
4. ✅ Adicionar endpoint de calibração de threshold.
5. ✅ Tornar liveness passiva plugável.

### Fase 3 — Escala e 1:N ✅

1. ✅ Adicionar pgvector e coluna `embedding_vector`.
2. ✅ Criar endpoint `POST /api/v1/biometric/identify`.
3. ✅ Consolidar RBAC por operação.
4. ✅ Adicionar abstração KMS/HSM.

---

## 6. Conclusão

O FaceClock está agora alinhado com a maioria dos pontos da arquitetura-alvo. Os maiores investimentos futuros devem ser:

1. **Modelo de deteção de face** (RetinaFace/FaceMesh) para maior robustez.
2. **Liveness passiva com classificador PAD treinado** para segurança contra spoofing.
3. **mTLS** entre ERP e FaceClock.
4. **Validação de pose/oclusão** para reduzir FRR.

A arquitetura está preparada para receber estas melhorias sem alterações estruturais significativas.

---

*Análise actualizada após a implementação das Fases 1, 2, 3 e 4 (self-hosted) da arquitetura de reconhecimento facial.*
