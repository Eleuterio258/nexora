# Próximas Implementações — FaceClock Self-Hosted

**Data:** 2026-08-05 (última actualização: 2026-08-08)
**Sistema:** FaceClock (`assiduidade_system_backend/`)

---

## Resumo

O FaceClock está **100% self-hosted** e funcional para 1:1, 1:N, liveness híbrida, encriptação com rotação de chaves, cancelable biometrics, device registry, matching de impressão digital via ORB, detecção de actividade suspeita, audit log local, dashboard de métricas, export/backup de templates, batch enrollment e anti-spoofing com modelo treinado real.

Este documento analisa o que pode ser implementado **sem depender de serviços cloud**, priorizado por impacto/esforço, e regista o estado real de cada item.

---

## Legenda

| Prioridade | Significado |
| --- | --- |
| 🔴 Alta | Impacto imediato na segurança, precisão ou operação |
| 🟡 Média | Melhoria significativa, mas não bloqueante |
| 🟢 Baixa | Nice-to-have ou otimização futura |

| Estado | Significado |
| --- | --- |
| ✅ Feito | Implementado e testado |
| 🟨 Parcial | Parte do escopo feita, resto adiado/fora de alcance |
| ⏸️ Adiado | Decisão consciente de não avançar agora, com razão registada |
| ❌ Por fazer | Ainda não iniciado |

---

## 1. Segurança

### 1.1 Anti-spoofing treinado real (substituir dummy ONNX) 🔴 ✅ Feito

- **Descrição:** O suporte ONNX ja existe e inclui um modelo dummy. Substituir por um classificador PAD treinado (ex.: Silent-Face-Anti-Spoofing).
- **Estado (2026-08-08):** Integrado o **MiniFASNetV2 80×80** do [Silent-Face-Anti-Spoofing](https://github.com/minivision-ai/Silent-Face-Anti-Spoofing) (conversão ONNX via [QingHeYang/Silent-Face-Anti-Spoofing-onnx](https://github.com/QingHeYang/Silent-Face-Anti-Spoofing-onnx)) em `app/ml_models/anti_spoofing.onnx`. Durante a integração corrigiram-se 2 bugs no código (`app/services/liveness_models.py`): tamanho de input fixo em 128×128 (o modelo real é 80×80, agora lido dinamicamente do próprio ONNX) e índice de classe "live" errado no output de 3 classes (usava o último logit em vez de softmax + índice 1, confirmado contra o `test.py` oficial do minivision-ai — sem a correcção seria um bug de segurança silencioso, não um crash).
- **Falta:** `LIVENESS_MODEL` continua `heuristic` por omissão — activar `anti_spoofing` e calibrar `BIOMETRIC_LIVENESS_THRESHOLD` com capturas reais é uma decisão deliberada a tomar separadamente, não foi activado automaticamente.
- **Ficheiros:** `app/ml_models/anti_spoofing.onnx`, `app/services/liveness_models.py`

### 1.2 mTLS entre ERP e FaceClock 🟡 🟨 Parcial

- **Descrição:** Adicionar certificados cliente/servidor à comunicação interna, complementando o HMAC Nexora.
- **Estado (2026-08-08):** Documentado em `docs/hardening-faceclock.md` (secção 4), incluindo exemplo de configuração Traefik. **Não aplicado à infraestrutura real** — configurar Traefik/Nginx de produção está fora do alcance de um agente sem acesso a essa infra; decisão consciente de só documentar.
- **Ficheiros:** `docs/hardening-faceclock.md`

### 1.3 Detecção de tentativas suspeitas 🔴 ✅ Feito

- **Descrição:** Alertar quando houver múltiplas falhas de liveness/verify seguidas, tentativas de replay de challenge, ou dispositivos desconhecidos.
- **Estado (2026-08-08):** Novo `app/services/suspicious_activity.py` (contador de janela deslizante, backend memory/redis pluggável, mesma configuração de `LIVENESS_CHALLENGE_STORE`), ligado a `verify_biometric`/`verify_liveness_challenge`. Endpoint `GET /admin/biometric/suspicious-activity`.
- **Ficheiros:** `app/services/suspicious_activity.py`, `app/routers/admin.py`, `app/routers/biometric.py`, `app/routers/liveness.py`

### 1.4 Audit logs locais 🟡 ✅ Feito

- **Descrição:** Guardar logs de auditoria biométrica localmente (além de delegar ao ERP).
- **Estado (2026-08-08):** Nova tabela `BiometricAuditLog`, serviço `app/services/audit_log.py`, ligado a enroll/verify/identify/liveness (sucesso e cada motivo de rejeição). Endpoint `GET /admin/biometric/audit-logs`. Cobre só eventos biométricos, não acções de admin (decisão consciente, escopo desta ronda).
- **Ficheiros:** `app/models.py`, `app/services/audit_log.py`, `app/routers/admin.py`

---

## 2. Precisão e robustez

### 2.1 Detector de face alternativo (RetinaFace/YuNet) 🔴 ✅ Feito

- **Descrição:** Suportar múltiplos detectores de face. RetinaFace/YuNet são mais robustos a oclusão e pose do que BlazeFace.
- **Estado:** Já implementado antes desta ronda de trabalho — `app/services/face_detectors.py` com `BlazeFaceDetector` e `YuNetDetector`. Nesta ronda foi adicionada cache de instância (ver 5.1).
- **Ficheiros:** `app/services/biometric.py`, `app/services/face_detectors.py`

### 2.2 Benchmark interno de FAR/FRR/EER 🔴 ✅ Feito

- **Descrição:** Endpoint admin que, dado um dataset etiquetado de pares genuínos/impostores, calcula FAR/FRR/EER e sugere threshold óptimo.
- **Estado:** Já implementado antes desta ronda — `POST /admin/biometric/calibrate-threshold`.
- **Ficheiros:** `app/routers/admin.py`, `app/services/biometric.py`

### 2.3 Matching de minúcias ISO para fingerprint 🟡 ⏸️ Adiado

- **Descrição:** O matching actual é baseado em ORB features. Para produção biométrica rigorosa, usar matching de minúcias ISO/IEC 19794-2.
- **Estado (2026-08-08):** Pesquisado em detalhe — SourceAFIS (referência da indústria) só tem implementações oficiais em Java/.NET, sem porte Python maduro. Alternativas PyPI (`fingerprints-matching`, `fingerprint-feature-extractor`, `pyfing`) são pacotes nicho, pouco vetados — risco de supply-chain não aceitável num pipeline biométrico de segurança sem avaliação mais profunda. Decisão: manter ORB, adiar.
- **Ficheiros:** `app/services/fingerprint_matching.py`

### 2.4 Indexação HNSW no pgvector 🟢 ✅ Feito

- **Descrição:** Criar índice HNSW na coluna `embedding_vector` para acelerar busca 1:N.
- **Estado (2026-08-08):** Migration `76692ef15c1a` — índice `ix_face_templates_embedding_vector_hnsw` (`vector_cosine_ops`, m=16, ef_construction=64), aplicado em produção.
- **Ficheiros:** `alembic/versions/76692ef15c1a_add_hnsw_index_embedding_vector.py`

---

## 3. Administração e operação

### 3.1 Dashboard de métricas 🟡 ✅ Feito

- **Descrição:** Endpoint com estatísticas visuais (taxas de match, liveness, tentativas por hora, etc.).
- **Estado (2026-08-08):** `GET /admin/biometric/metrics-dashboard` — agrega `biometric_metrics` (processo-wide), actividade suspeita e resumo de audit log das últimas 24h (estes dois por tenant). Nota de design explícita sobre a assimetria de scope no próprio endpoint.
- **Ficheiros:** `app/routers/admin.py`

### 3.2 Export/backup encriptado de templates 🟡 ✅ Feito

- **Descrição:** Endpoint admin para exportar todos os templates de um tenant encriptados (ex.: para backup/migração).
- **Estado (2026-08-08):** `GET /admin/biometric/export-templates` — devolve o ciphertext tal como guardado (AES-GCM) + metadados; só decifrável num ambiente com a mesma chave/keyring (decisão consciente, mais simples que re-cifrar com passphrase).
- **Ficheiros:** `app/routers/admin.py`

### 3.3 Re-enrolamento automático por mudança de modelo 🟡 🟨 Parcial

- **Descrição:** Quando `model_version` muda, notificar o ERP para re-enrolar automaticamente em vez de apenas marcar como `PENDING_REENROLL`.
- **Estado (2026-08-08):** Lado FaceClock feito — `erp_client.notify_reenroll_required()`, best-effort (nunca bloqueia o verify), disparado só na 1ª transição para `PENDING_REENROLL`, via `ERP_REENROLL_WEBHOOK_URL` (opcional). **O endpoint Go correspondente no ERP para receber esta notificação não foi construído** — decisão consciente de escopo desta ronda.
- **Ficheiros:** `app/erp_client.py`, `app/routers/biometric.py`, `app/config.py`

### 3.4 Documentação de hardening 🟢 ✅ Feito

- **Descrição:** Guia de hardening: permissões de ficheiros, isolamento de rede, política de segredos, etc.
- **Estado (2026-08-08):** `docs/hardening-faceclock.md` — segredos, permissões de ficheiros, isolamento de rede, mTLS (ver 1.2), superfície de ataque, auditoria/monitorização.
- **Ficheiros:** `docs/hardening-faceclock.md`

---

## 4. Testes e qualidade

### 4.1 Testes E2E com imagens reais 🔴 🟨 Parcial

- **Descrição:** Adicionar fixtures de imagens reais (com consentimento) e testes de ponta-a-ponta para verify/identify.
- **Estado (2026-08-08):** Decisão consciente de não avançar com o spike de gerar uma face sintética para testar contra os detectores reais (BlazeFace/YuNet) — incerteza real sobre se passaria na detecção, e sem imagens reais com consentimento disponíveis. Continuam a ser usados mocks (`monkeypatch`) para os testes de rota completos. Ver 4.3 para o que foi feito em alternativa.
- **Ficheiros:** `tests/`

### 4.2 Testes de stress para 1:N 🟡 ❌ Por fazer

- **Descrição:** Testar performance do pgvector com 10k/100k/1M templates sintéticos.
- **Estado:** Não iniciado.
- **Ficheiros:** `tests/`

### 4.3 Testes de segurança (spoofing) 🟡 ✅ Feito (parcial)

- **Descrição:** Criar testes com ataques simples (foto, ecrã) para validar liveness.
- **Estado (2026-08-08):** `TestSpoofingSimulations` em `tests/test_liveness_models.py` — comparação relativa de scores (imagem lisa/moiré vs. texturada) chamando os modelos de liveness directamente, contornando a necessidade de detecção real de face. Não substitui testes com ataques reais (foto impressa, replay de ecrã) contra o pipeline completo — ver 4.1.
- **Ficheiros:** `tests/test_liveness_models.py`

---

## 5. Optimizações

### 5.1 Cache de modelos em memória 🟢 ✅ Feito

- **Descrição:** Garantir que detector, landmarker e modelo de embedding são carregados uma única vez.
- **Estado (2026-08-08):** `face_detectors.get_face_detector()` e `liveness_models.get_liveness_model()` agora fazem cache por nome (antes recriavam a instância — e para YuNet/anti-spoofing, recarregavam o ONNX — a cada pedido). `warmup_biometric_models()` pré-carrega ambos no arranque.
- **Ficheiros:** `app/services/face_detectors.py`, `app/services/liveness_models.py`, `app/services/biometric.py`

### 5.2 Compressão de embeddings 🟢 ⏸️ Adiado

- **Descrição:** Usar PCA ou quantização para reduzir o tamanho dos embeddings (ex.: 512D → 256D) com perda mínima.
- **Estado (2026-08-08):** Adiado por decisão consciente — precisa de dataset real para treinar o PCA por modelo e um plano de migração dos templates já guardados (mudar a dimensão fixa da coluna `embedding_vector` afecta todos os templates existentes).
- **Ficheiros:** `app/services/embedding_models.py`

### 5.3 Batch processing para enrollment em massa 🟢 ✅ Feito

- **Descrição:** Endpoint para fazer enrollment de múltiplos utilizadores em batch.
- **Estado (2026-08-08):** `POST /admin/biometric/batch-enroll` (até 20 utilizadores por pedido), reaproveita a mesma lógica de `/biometric/enroll` via `_perform_enrollment`; cada item processado e comitado independentemente — uma falha não bloqueia nem desfaz os restantes.
- **Ficheiros:** `app/routers/admin.py`, `app/routers/biometric.py`, `app/schemas/requests.py`

---

## 6. Gaps de schema descobertos durante esta ronda (fora do backlog original)

Ao investigar o índice HNSW (2.4), descobriu-se que a base de dados de produção (`nexora_erp`) estava significativamente atrasada face ao modelo SQLAlchemy actual — `face_templates.transform_version`, `face_templates.embedding_vector` e a tabela `device_public_keys` existiam no código mas nunca tiveram migration própria (dependiam de `Base.metadata.create_all`, que só cria tabelas novas, nunca faz `ALTER` em tabelas já existentes). Sem isto, qualquer deploy do código actual teria partido `/biometric/enroll` e `/biometric/verify` imediatamente.

Corrigido com 3 migrations (`527f1cebd109`, `a8f7d3ba8531`, `ac34e8883d12`), aplicadas em produção após confirmação explícita, incluindo instalação da extensão `pgvector` no servidor Postgres (que também estava em falta a nível de sistema operativo).

---

## Recomendação de ordem (histórico — já executada)

1. ~~Anti-spoofing ONNX~~ — ✅ feito
2. ~~Detector de face alternativo~~ — ✅ já estava feito
3. ~~Benchmark FAR/FRR/EER~~ — ✅ já estava feito
4. ~~Audit logs locais~~ — ✅ feito
5. ~~Indexação HNSW~~ — ✅ feito
6. Testes E2E com imagens reais — 🟨 parcial, adiado o pipeline completo
7. ~~mTLS~~ — 🟨 só documentado
8. ~~Dashboard de métricas~~ — ✅ feito
9. ~~Export encriptado de templates~~ — ✅ feito
10. Matching de minúcias ISO — ⏸️ adiado, sem boa opção Python

---

## O que resta em aberto

| Item | Estado | Razão |
| --- | --- | --- |
| `LIVENESS_MODEL=anti_spoofing` activado em produção | Não activado | Decisão deliberada — precisa calibração de threshold primeiro |
| mTLS aplicado à infra real | Só documentado | Fora do alcance de um agente sem acesso à infra de produção |
| Endpoint Go no ERP para webhook de re-enroll | Não construído | Escopo desta ronda foi só o lado FaceClock |
| Testes E2E com detecção facial real (sem mocks) | Adiado | Falta imagens reais com consentimento ou gerador de faces sintéticas validado |
| Compressão PCA de embeddings | Adiado | Precisa dataset real + plano de migração |
| Matching de minúcias ISO | Adiado | Sem biblioteca Python madura e confiável |
| Testes de stress 1:N | Por fazer | Não iniciado |

---

## Nota final

Todas as sugestões acima são **self-hosted** e não requerem serviços cloud. A única excepção seria se se quisesse usar modelos pré-treinados de terceiros, mas esses podem ser descarregados e corridos localmente.
