# Próximas Implementações — FaceClock Self-Hosted

**Data:** 2026-08-05 (última actualização: 2026-08-08)  
**Sistema:** FaceClock (`assiduidade_system_backend/`)  
**Versão do documento:** 2.0  
**Autor:** Equipa de Engenharia Nexora  

---

## Resumo Executivo

O FaceClock é o subsistema de biometria facial e de impressão digital do Nexora ERP. Está concebido para funcionar **100% self-hosted**, sem dependências de serviços cloud para inferência, armazenamento de templates ou matching. O objectivo é garantir soberania total dos dados biométricos, reduzir a superfície de ataque e manter a operação mesmo com conectividade limitada.

### Estado actual (2026-08-08)

| Dimensão | Estado |
| --- | --- |
| Funcionalidade core (1:1, 1:N, enrollment) | ✅ Estável em produção |
| Anti-spoofing | ✅ Modelo real integrado (MiniFASNetV2); ainda não activado por omissão |
| Criptografia em repouso | ✅ AES-GCM com keyring/rotação |
| Cancelable biometrics | ✅ Transformação opcicional por segredo |
| Detecção de actividade suspeita | ✅ Memória ou Redis |
| Audit logs locais | ✅ Tabela `biometric_audit_logs` |
| Device registry (Ed25519) | ✅ Tabela `device_public_keys` |
| Indexação 1:N | ✅ HNSW pgvector |
| Dashboard e métricas | ✅ Endpoint admin |
| Backup encriptado de templates | ✅ Endpoint admin |
| Re-enrolamento automático | ✅ Notificação best-effort ao ERP |
| mTLS | 🟨 Apenas documentado |
| Testes E2E reais | 🟨 Parcial (sem imagens reais consentidas) |
| Testes de stress 1:N | ❌ Não iniciados |
| Matching ISO de impressão digital | ⏸️ Adiado (sem biblioteca madura) |

### Decisões-chave tomadas

1. **LIVENESS_MODEL continua `heuristic` por omissão** mesmo com o modelo ONNX disponível, porque a calibração de `BIOMETRIC_LIVENESS_THRESHOLD` com capturas reais ainda não foi feita. Activar sem calibração seria um risco de segurança silencioso.
2. **A coluna `face_templates.embedding_vector` só é populada quando existe transformação cancelável activa.** Sem transformação, o vector ficaria legível em claro na base de dados; isso violaria o princípio de encriptação em repouso dos templates.
3. **O matching de impressão digital mantém ORB** em vez de minúcias ISO/IEC 19794-2, porque não existe porte Python maduro e auditado do SourceAFIS, e alternativas PyPI têm risco de supply-chain inaceitável num pipeline de segurança.
4. **mTLS fica documentado mas não aplicado** porque a configuração do Traefik/Nginx de produção está fora do alcance de um agente sem acesso à infraestrutura real.

---

## Legenda

### Prioridade

| Prioridade | Significado | Critério |
| --- | --- | --- |
| 🔴 Alta | Impacto imediato na segurança, precisão ou operação | Deve ser tratado na próxima sprint se recursos existirem |
| 🟡 Média | Melhoria significativa, mas não bloqueante | Planejado para a ronda seguinte |
| 🟢 Baixa | Nice-to-have ou otimização futura | Sem compromisso temporal |

### Estado

| Estado | Significado |
| --- | --- |
| ✅ Feito | Implementado, testado e (quando aplicável) aplicado em produção |
| 🟨 Parcial | Parte do escopo feita; restante adiado ou fora de alcance |
| ⏸️ Adiado | Decisão consciente de não avançar agora, com razão registada |
| ❌ Por fazer | Ainda não iniciado |
| 🔄 Em validação | Implementado, mas ainda não exercido em ambiente real |

---

## 1. Segurança

### 1.1 Anti-spoofing treinado real (substituir dummy ONNX) 🔴 ✅ Feito

#### Descrição
Substituir o classificador de liveness heurístico (baseado em textura/FFT/cor) por um modelo de Presentation Attack Detection (PAD) treinado, capaz de distinguir rostos vivos de fotos, ecrãs e máscaras com taxas de erro medidas.

#### Modelo integrado
- **Arquitectura:** MiniFASNetV2 80×80 do [Silent-Face-Anti-Spoofing](https://github.com/minivision-ai/Silent-Face-Anti-Spoofing).
- **Conversão ONNX:** [QingHeYang/Silent-Face-Anti-Spoofing-onnx](https://github.com/QingHeYang/Silent-Face-Anti-Spoofing-onnx).
- **Ficheiro:** `app/ml_models/anti_spoofing.onnx`.
- **Formato de input:** dinâmico (lido do próprio ONNX); fallback 128×128 se dimensão simbólica.
- **Formato de output:** suporta 1, 2 ou 3 classes. Para 3 classes (oficial MiniFASNet), índice 1 = `real face`.

#### Bugs corrigidos durante a integração
1. **Tamanho de input fixo em 128×128** — o modelo real é 80×80. O código agora lê `(H, W)` do `input_shape` do ONNX.
2. **Índice de classe "live" errado** — para output de 3 classes, o código inicialmente usava o último logit (`probs[-1]`). A convenção oficial é `argmax` com índice 1. Sem esta correcção, o classificador inverteria as probabilidades de ataque/vivo — um bug de segurança silencioso.

#### Configuração
```bash
# Modelo de liveness: heuristic | anti_spoofing | silent_face_anti_spoofing
LIVENESS_MODEL=heuristic

# Threshold de liveness (0.0–1.0). Calibrar antes de activar anti_spoofing.
BIOMETRIC_LIVENESS_THRESHOLD=0.60
```

#### Porque não está activado por omissão
- O threshold 0.60 foi calibrado para o modelo heurístico.
- O MiniFASNetV2 produz scores numa escala diferente; o mesmo threshold poderia rejeitar rostos vivos ou aceitar ataques.
- Recomenda-se usar o endpoint `POST /admin/biometric/calibrate-threshold` com capturas reais de ataque e vivo antes da activação.

#### Ficheiros
- `app/ml_models/anti_spoofing.onnx`
- `app/services/liveness_models.py`
- `tests/test_liveness_models.py`

#### Próximos passos
1. Recolher dataset interno de ~100 capturas reais (vivo/foto/ecrã) por categoria de luz.
2. Correr `POST /admin/biometric/calibrate-threshold` para determinar `BIOMETRIC_LIVENESS_THRESHOLD` óptimo.
3. Activar `LIVENESS_MODEL=anti_spoofing` num ambiente de staging.
4. Monitorar APCER/BPCER no dashboard por 1–2 semanas antes de produção.

---

### 1.2 mTLS entre ERP e FaceClock 🟡 🟨 Parcial

#### Descrição
Adicionar autenticação mútua baseada em certificados X.509 (mTLS) à comunicação interna FaceClock ↔ Nexora ERP, complementando o HMAC Nexora já existente. O HMAC garante autenticidade e integridade da mensagem; o mTLS adiciona uma camada de transporte que autentica os hosts e dificulta ataques de rede interna.

#### Estado (2026-08-08)
- Documentado em `docs/hardening-faceclock.md` (secção 4).
- Incluído exemplo de configuração Traefik com `tls.options.clientAuth`.
- **Não aplicado à infraestrutura real:** configurar o edge proxy de produção (Traefik/Nginx) está fora do alcance de um agente sem acesso a essa infra.

#### O que falta
1. Gerar/renovar CA interna e certificados cliente/servidor.
2. Distribuir certificados via secret manager (ex.: HashiCorp Vault, AWS Secrets Manager, ou ficheiros cifrados no host).
3. Configurar Traefik/Nginx de produção para exigir client certificate.
4. Testar fail-close: pedidos sem certificado válido devem ser rejeitados ao nível do TLS handshake.

#### Ficheiros
- `docs/hardening-faceclock.md`
- `backend/` (configuração do ERP Go para usar certificado cliente)

#### Decisão registada
> Fica documentado como recomendação de hardening. A implementação prática depende da equipa de infraestrutura e da CA interna da empresa.

---

### 1.3 Detecção de tentativas suspeitas 🔴 ✅ Feito

#### Descrição
Detectar e alertar quando um utilizador ou dispositivo acumula múltiplas falhas de verify/liveness numa janela temporal, indicando potencial ataque de força bruta, replay ou dispositivo comprometido.

#### Implementação
- **Backend:** `MemorySuspiciousActivityStore` (single-instance) ou `RedisSuspiciousActivityStore` (multi-replica).
- **Reutilização de configuração:** usa a mesma env var `LIVENESS_CHALLENGE_STORE` do challenge store (memory/redis), porque a decisão operacional single vs. multi-replica é a mesma.
- **Contadores:** por `(tenant_id, kind, identifier)`, onde `kind ∈ {user, device}`.
- **Janela deslizante:** `SUSPICIOUS_ACTIVITY_WINDOW_SECONDS` (default 600s).
- **Threshold:** `SUSPICIOUS_ACTIVITY_THRESHOLD` (default 5 falhas).
- **Reset:** uma verificação bem-sucedida limpa o contador.

#### Integração
- Chamado em `/biometric/verify` e `/liveness/verify` (ver `app/routers/biometric.py`).
- Endpoint de consulta: `GET /admin/biometric/suspicious-activity`.
- Log de aviso `log.warning` quando o threshold é cruzado.

#### Configuração
```bash
LIVENESS_CHALLENGE_STORE=memory   # ou redis
SUSPICIOUS_ACTIVITY_THRESHOLD=5
SUSPICIOUS_ACTIVITY_WINDOW_SECONDS=600
```

#### Limitações
- O store em memória perde estado em reinício ou em setup multi-replica sem sticky sessions.
- Ainda não existe notificação proactiva para o ERP (ex.: webhook de bloqueio temporário). Pode ser adicionado futuramente sem alterar o schema.

#### Ficheiros
- `app/services/suspicious_activity.py`
- `app/routers/admin.py` (`GET /admin/biometric/suspicious-activity`)
- `app/routers/biometric.py`
- `app/routers/liveness.py`

---

### 1.4 Audit logs locais 🟡 ✅ Feito

#### Descrição
Manter um registo de auditoria local de todos os eventos biométricos (enroll, verify, identify, liveness), independentemente do ERP. Isto garante trilha de auditoria mesmo quando o ERP está indisponível.

#### Implementação
- Tabela `biometric_audit_logs` com colunas: `event_type`, `erp_user_id`, `device_id`, `reason`, `confidence_score`, `liveness_score`, `created_at`.
- Índices em `tenant_id`, `event_type`, `erp_user_id`, `device_id`, `created_at`.
- Serviço `record_audit_event()` cria a entrada dentro da mesma transacção da operação biométrica.
- Endpoint: `GET /admin/biometric/audit-logs` com filtros e paginação.

#### Eventos registados
| Evento | Quando |
| --- | --- |
| `enroll_success` | Enrollment bem-sucedido |
| `enroll_failure` | Enrollment rejeitado (qualidade/liveness/ERP) |
| `verify_match` | 1:1 com score ≥ threshold |
| `verify_rejection` | 1:1 rejeitado (qualidade/liveness/match/modelo) |
| `identify_match` | 1:N encontrou candidato |
| `identify_no_match` | 1:N não encontrou candidato |

#### Escopo consciente
- Apenas eventos biométricos; acções administrativas (registo/revogação de chaves, re-encriptação) ficam para uma fase futura.
- O log local complementa, não substitui, o audit log central do ERP.

#### Configuração
Nenhuma variável específica; requer apenas migration aplicada.

#### Ficheiros
- `app/models.py` (`BiometricAuditLog`)
- `app/services/audit_log.py`
- `app/routers/admin.py` (`GET /admin/biometric/audit-logs`)

---

## 2. Precisão e robustez

### 2.1 Detector de face alternativo (RetinaFace/YuNet) 🔴 ✅ Feito

#### Descrição
Suportar múltiplos detectores de face, permitindo escolher entre velocidade (BlazeFace) e robustez a pose/oclusão (YuNet).

#### Detectores disponíveis
| Nome | Motor | Requisitos | Caso de uso |
| --- | --- | --- | --- |
| `blaze_face` | MediaPipe BlazeFace (short-range) | `mediapipe` instalado | Default, rápido, boa para selfies frontais |
| `yunet` | OpenCV YuNet ONNX | `app/ml_models/face_detection_yunet.onnx` | Pose/oclusão ligeira |

#### Configuração
```bash
BIOMETRIC_FACE_DETECTOR=blaze_face   # ou yunet
```

#### Cache de instância
- `get_face_detector()` e `get_liveness_model()` cacheiam instâncias por nome.
- Antes da cache, YuNet e anti-spoofing recarregavam o ONNX a cada pedido, causando latência e consumo de CPU/descrição.
- `warmup_biometric_models()` pré-carrega os modelos no arranque.

#### Ficheiros
- `app/services/face_detectors.py`
- `app/services/biometric.py`
- `app/ml_models/face_detection_yunet.onnx`

#### Nota sobre RetinaFace
RetinaFace não foi integrado porque YuNet cobre a necessidade de robustez com dependência apenas de OpenCV. Se no futuro YuNet mostrar limitações em pose extrema, RetinaFace pode ser adicionado seguindo o mesmo padrão `FaceDetector`.

---

### 2.2 Benchmark interno de FAR/FRR/EER 🔴 ✅ Feito

#### Descrição
Endpoint admin que, dado um dataset etiquetado de pares genuínos/impostores, calcula:
- **FAR** (False Acceptance Rate)
- **FRR** (False Rejection Rate)
- **EER** (Equal Error Rate)
- Threshold óptimo
- Threshold para um FAR alvo opcional

#### Endpoint
```http
POST /admin/biometric/calibrate-threshold
```

#### Corpo
```json
{
  "pairs": [
    {"embedding_a": [...], "embedding_b": [...], "genuine": true},
    {"embedding_a": [...], "embedding_b": [...], "genuine": false}
  ],
  "target_far": 0.001
}
```

#### Ficheiros
- `app/routers/admin.py`
- `app/services/biometric.py` (`cosine_similarity`)

#### Como usar na prática
1. Recolher embeddings de ~50 utilizadores, 2 capturas por utilizador (pares genuínos) + 1 captura cruzada entre cada par (pares impostores).
2. Enviar para `POST /admin/biometric/calibrate-threshold`.
3. Aplicar o `eer_threshold` ou `target_far_threshold` resultante em `BIOMETRIC_MATCH_THRESHOLD`.

---

### 2.3 Matching de minúcias ISO para fingerprint 🟡 ⏸️ Adiado

#### Descrição
O matching actual de impressão digital é baseado em características ORB (features locais de imagem). Para produção biométrica rigorosa, o ideal seria usar matching de minúcias conforme ISO/IEC 19794-2.

#### Pesquisa realizada
- **SourceAFIS:** referência da indústria, mas apenas implementações oficiais em Java/.NET.
- **PyPI alternativas:** `fingerprints-matching`, `fingerprint-feature-extractor`, `pyfing`.
  - Pacotes nicho, pouco vetados.
  - Risco de supply-chain elevado num pipeline de segurança.
  - Sem garantia de interoperabilidade ISO/IEC 19794-2.

#### Decisão
Manter ORB; adiar matching ISO até haver biblioteca Python madura e auditada, ou até se decidir correr SourceAFIS via JVM/.NET bridge controlada.

#### Ficheiros
- `app/services/fingerprint_matching.py`

#### Próximos passos (não prioritário)
1. Avaliar SourceAFIS Java via `pyjnius` ou serviço separado.
2. Se se optar por bridge, isolar em container com comunicação local segura.
3. Actualizar documentação de conformidade.

---

### 2.4 Indexação HNSW no pgvector 🟢 ✅ Feito

#### Descrição
Criar um índice aproximado de vizinhos mais próximos (HNSW) na coluna `embedding_vector` para acelerar a busca 1:N (`/biometric/identify`).

#### Migration aplicada
- Ficheiro: `alembic/versions/76692ef15c1a_add_hnsw_index_embedding_vector.py`
- Índice: `ix_face_templates_embedding_vector_hnsw`
- Parâmetros: `vector_cosine_ops`, `m=16`, `ef_construction=64`

#### Gaps de schema corrigidos
Ao investigar a indexação, descobriu-se que a base de dados de produção estava atrasada face ao modelo SQLAlchemy:
- `face_templates.transform_version`
- `face_templates.embedding_vector`
- Tabela `device_public_keys`

Estas colunas/tabelas existiam no código mas nunca tiveram migration própria (dependiam de `Base.metadata.create_all`, que cria tabelas novas mas não faz `ALTER`). Foram criadas 3 migrations adicionais:
- `527f1cebd109` — adiciona `transform_version` a `face_templates`
- `a8f7d3ba8531` — adiciona `embedding_vector` a `face_templates`
- `ac34e8883d12` — adiciona tabela `device_public_keys`

A extensão `pgvector` também tinha de ser instalada a nível de sistema operativo no servidor Postgres.

#### Configuração afinável
```sql
-- Ajustar ef_search por sessão (default 40; perde ~25% de identificações a 100k templates)
SET hnsw.ef_search = 100;
```

#### Ficheiros
- `alembic/versions/76692ef15c1a_add_hnsw_index_embedding_vector.py`
- `alembic/versions/527f1cebd109_add_transform_version_to_face_templates.py`
- `alembic/versions/a8f7d3ba8531_add_embedding_vector_to_face_templates.py`
- `alembic/versions/ac34e8883d12_add_device_public_keys.py`

#### Próximos passos
- Afinar `hnsw.ef_search` após testes de stress (ver 4.2).
- Reconstruir o índice após grandes inserções batch (`REINDEX INDEX ...`).

---

## 3. Administração e operação

### 3.1 Dashboard de métricas 🟡 ✅ Feito

#### Descrição
Endpoint unificado de operação biométrica que agrega três fontes de dados:
1. Métricas de processo (`biometric_metrics`)
2. Actividade suspeita
3. Resumo de audit log das últimas 24h

#### Endpoint
```http
GET /admin/biometric/metrics-dashboard
```

#### Estrutura da resposta
```json
{
  "biometric_metrics": { "far_rate": ..., "frr_rate": ..., "match_rate": ..., "scope": "process-wide" },
  "suspicious_activity": { "threshold": 5, "window_seconds": 600, "flagged_count": 0, "flagged": [] },
  "audit_summary_24h": { "verify_match": 120, "verify_rejection": 3 }
}
```

#### Nota de design
`biometric_metrics` é um singleton global do processo (sem `tenant_id`), tal como o endpoint `/metrics` Prometheus. As secções `suspicious_activity` e `audit_summary_24h` são filtradas por tenant. Esta assimetria é intencional.

#### Ficheiros
- `app/routers/admin.py`
- `app/biometric_metrics.py`

---

### 3.2 Export/backup encriptado de templates 🟡 ✅ Feito

#### Descrição
Endpoint admin para exportar todos os templates faciais de um tenant, mantendo a encriptação original (AES-GCM), para backup ou migração.

#### Endpoint
```http
GET /admin/biometric/export-templates?erp_user_id=opcional
```

#### Características
- Devolve o ciphertext tal como está guardado (`enc:v2:...`).
- Inclui metadados: `tenant_id`, `erp_user_id`, `model_version`, `transform_version`, `quality_score`, `status`, `created_at`, `revoked_at`.
- **Não inclui** `embedding_vector` (dados derivados, reconstruíveis a partir do embedding decifrado).
- Só é decifrável num ambiente com a mesma chave/keyring.

#### Casos de uso
- Backup offline periódico.
- Migração entre instâncias FaceClock.
- DR (disaster recovery) sem expor embeddings em claro.

#### Ficheiros
- `app/routers/admin.py`

---

### 3.3 Re-enrolamento automático por mudança de modelo 🟡 ✅ Feito

#### Descrição
Quando `model_version` do modelo de embedding muda, os templates antigos tornam-se incompatíveis. O sistema:
1. Marca o template como `PENDING_REENROLL`.
2. Notifica o ERP (best-effort) para que o colaborador seja avisado e possa re-enrolar.

#### Lado FaceClock
- Função: `erp_client.notify_reenroll_required()`
- Chamada apenas na 1ª transição para `PENDING_REENROLL` (idempotência por estado).
- Nunca bloqueia o verify: se a notificação falhar, o template continua marcado como pendente.
- URL configurável: `ERP_REENROLL_WEBHOOK_URL`.

#### Lado ERP (Go)
- Endpoint: `POST /api/hardware/assiduidade/biometria/reenroll-required`
- Autenticação: `RequireDeviceAuth` (X-API-Key), como os restantes endpoints `/api/hardware/assiduidade/*`.
- Resolve `erp_user_id` (= `auth.users.id`) para `rh.funcionarios.id`.
- Escreve em `auditoria.audit_logs` (`acao='reenroll_required'`).
- Cria aviso em `notif_colaborador`, idempotente por `WHERE NOT EXISTS`.
- O `tenant_id` do corpo é informativo; o isolamento vem do device autenticado.

#### Configuração
```bash
ERP_REENROLL_WEBHOOK_URL=https://api.exemplo.com/api/hardware/assiduidade/biometria/reenroll-required
ERP_API_KEY=...
```

#### Estado de validação
- O endpoint compila e a rota está registada.
- **Não foi exercido contra uma base de dados real**, porque não há ambiente de teste do ERP Go com o schema aplicado.

#### Ficheiros
- FaceClock: `app/erp_client.py`, `app/routers/biometric.py`, `app/config.py`, `.env.example`
- ERP Go: `backend/internal/modules/recursos-humanos/handlers/biometria_reenroll.go`, `backend/internal/router/router.go`

---

### 3.4 Documentação de hardening 🟢 ✅ Feito

#### Descrição
Guia operacional de hardening do FaceClock.

#### Temas cobertos
- Gestão de segredos (`BIOMETRIC_ENCRYPTION_KEY`, `NEXORA_CREDENTIAL_ENCRYPTION_KEY`, `FACIAL_VERIFICATION_SECRET`).
- Permissões de ficheiros (modelos ONNX, chaves, logs).
- Isolamento de rede (VLAN, ACLs, exposição mínima).
- mTLS (ver 1.2).
- Superfície de ataque (desactivar docs em produção, limitar CORS).
- Auditoria e monitorização (logs, métricas, alertas).

#### Ficheiros
- `docs/hardening-faceclock.md`

---

## 4. Testes e qualidade

### 4.1 Testes E2E com imagens reais 🔴 🟨 Parcial

#### Descrição
Adicionar fixtures de imagens reais (com consentimento) e testes de ponta-a-ponta para `/biometric/verify` e `/biometric/identify` sem recorrer a mocks.

#### Estado (2026-08-08)
- Decisão consciente de **não avançar** com o spike de gerar uma face sintética para testar contra detectores reais.
- Razão: incerteza real sobre se uma face sintética passaria na detecção real (BlazeFace/YuNet), e ausência de imagens reais com consentimento.
- Continuam a ser usados mocks (`monkeypatch`) para os testes de rota completos.

#### Alternativa implementada (ver 4.3)
Testes relativos nos modelos de liveness directamente, contornando a detecção facial.

#### Ficheiros
- `tests/`

#### Próximos passos
1. Obter conjunto de imagens reais com consentimento explícito para testes:
   - 5–10 indivíduos.
   - 3 capturas por indivíduo (genuínas).
   - 1 foto impressa + 1 replay de ecrã por indivíduo (ataques).
2. Criar fixtures e testes parametrizados.
3. Verificar se gerador sintético (ex.: StyleGAN) é viável e validado contra detectores; se sim, integrar em pipeline de CI separado.

---

### 4.2 Testes de stress para 1:N 🟡 ❌ Por fazer

#### Descrição
Avaliar a performance do pgvector HNSW com volumes crescentes de templates sintéticos: 10k, 100k, 1M.

#### Estado
Não iniciado.

#### O que medir
| Métrica | Objectivo |
| --- | --- |
| Latência p95 identify | < 500 ms |
| Latência p99 identify | < 1 s |
| Recall @ top-1 | > 99% vs. busca exacta |
| Tempo de construção do índice | Aceitável para a janela de manutenção |
| Uso de CPU/memória durante busca | Não exceder limites do container |

#### Configuração do benchmark
```bash
STRESS_TEMPLATE_COUNTS=10000,100000,1000000
```

#### Resultado parcial conhecido
- A 100k templates, a construção do índice HNSW já levou ~8,5 minutos num ambiente de teste.
- Valor por omissão de `hnsw.ef_search` perde ~25% das identificações a 100k templates.

#### Ficheiros
- `tests/` (a criar)

#### Próximos passos
1. Criar script de stress que gera embeddings sintéticos e corre identify.
2. Testar diferentes valores de `hnsw.ef_search` (40, 100, 200).
3. Documentar latência/recall por volume.
4. Aplicar `hnsw.ef_search` recomendado em produção.

---

### 4.3 Testes de segurança (spoofing) 🟡 ✅ Feito (parcial)

#### Descrição
Criar testes com ataques simples (foto, ecrã) para validar liveness.

#### Implementação
- Classe `TestSpoofingSimulations` em `tests/test_liveness_models.py`.
- Compara scores relativos (não thresholds absolutos) entre:
  - Imagem lisa (simula foto impressa).
  - Padrão de moiré (simula replay de ecrã).
  - Imagem texturizada com ruído gaussiano (simula pele viva).
- Chama os modelos de liveness directamente, contornando a necessidade de detecção real de face.

#### Limitações
- Não substitui testes com ataques reais (foto impressa, replay de ecrã) contra o pipeline completo.
- Não mede APCER/BPCER absolutos.

#### Ficheiros
- `tests/test_liveness_models.py`

---

## 5. Optimizações

### 5.1 Cache de modelos em memória 🟢 ✅ Feito

#### Descrição
Garantir que detector de face, landmarker e modelo de embedding são carregados uma única vez por processo.

#### Implementação
- `face_detectors.get_face_detector()` — cache por nome (`_detector_cache`).
- `liveness_models.get_liveness_model()` — cache por nome (`_model_cache`).
- `warmup_biometric_models()` — pré-carrega no arranque para evitar latência no primeiro pedido.

#### Impacto
- Antes da cache, YuNet e anti-spoofing recarregavam o ONNX a cada pedido.
- Latência de primeiro pedido reduzida de segundos para milissegundos após warmup.
- Menor pressão de I/O e memória (evita múltiplas cópias do modelo em RAM).

#### Ficheiros
- `app/services/face_detectors.py`
- `app/services/liveness_models.py`
- `app/services/biometric.py`

---

### 5.2 Compressão de embeddings 🟢 ⏸️ Adiado

#### Descrição
Usar PCA ou quantização para reduzir a dimensão dos embeddings (ex.: 512D → 256D) com perda mínima, reduzindo uso de disco e memória e acelerando a busca 1:N.

#### Porque foi adiado
1. Precisa de dataset real para treinar o PCA por modelo (FaceNet, ArcFace, etc.).
2. Mudar a dimensão da coluna `embedding_vector` afecta todos os templates existentes.
3. Requer plano de migração: re-gerar `embedding_vector` para todos os templates, possivelmente numa janela de manutenção.

#### Ficheiros
- `app/services/embedding_models.py`

#### Próximos passos (futuro)
1. Recolher dataset representativo.
2. Treinar PCA por `model_version`.
3. Criar migration que adiciona coluna `embedding_vector_compressed`.
4. Avaliar recall loss vs. ganho de performance.

---

### 5.3 Batch processing para enrollment em massa 🟢 ✅ Feito

#### Descrição
Endpoint para fazer enrollment de múltiplos utilizadores num único pedido (útil para migrações ou onboarding em lote).

#### Endpoint
```http
POST /admin/biometric/batch-enroll
```

#### Características
- Limite: 20 utilizadores por pedido.
- Reaproveita `_perform_enrollment`, a mesma lógica de `/biometric/enroll`.
- Cada item é processado e comitado independentemente: uma falha não bloqueia nem desfaz os restantes.
- Resposta detalhada por item (`success`, `template_id` ou `error`).

#### Ficheiros
- `app/routers/admin.py`
- `app/routers/biometric.py`
- `app/schemas/requests.py` (`BatchEnrollRequest`)

---

## 6. Gaps de schema descobertos durante esta ronda

A base de dados de produção (`nexora_erp`) estava significativamente atrasada face ao modelo SQLAlchemy actual. Foram descobertos e corrigidos os seguintes gaps:

| Coluna/Tabela | Problema | Migration |
| --- | --- | --- |
| `face_templates.transform_version` | Existia no modelo, não existia na BD | `527f1cebd109` |
| `face_templates.embedding_vector` | Existia no modelo, não existia na BD | `a8f7d3ba8531` |
| `device_public_keys` | Tabela existia no modelo, não existia na BD | `ac34e8883d12` |
| Extensão `pgvector` | Não instalada a nível de SO | Instalação manual no Postgres |

Sem estas correcções, qualquer deploy do código actual teria partido `/biometric/enroll` e `/biometric/verify` imediatamente, porque o código assumia a existência destas colunas/tabelas.

#### Lição aprendida
`Base.metadata.create_all()` cria tabelas novas mas não faz `ALTER` em tabelas existentes. Alterações de schema em produção devem sempre passar por Alembic, mesmo em ambientes que inicialmente usaram `create_all`.

---

## 7. Roadmap e recomendação de ordem

### Fase 1 — Segurança e estabilidade (já executada)
1. ✅ Anti-spoofing ONNX integrado.
2. ✅ Audit logs locais.
3. ✅ Indexação HNSW + migrations de schema.
4. ✅ Detecção de actividade suspeita.

### Fase 2 — Activar funcionalidades pendentes
1. Calibrar e activar `LIVENESS_MODEL=anti_spoofing` em staging.
2. Afinar `hnsw.ef_search` após testes de stress.
3. Validar webhook de re-enroll contra BD real do ERP.

### Fase 3 — Hardening e conformidade
1. Implementar mTLS em produção (infraestrutura).
2. Revisar permissões de ficheiros e segredos conforme `docs/hardening-faceclock.md`.
3. Adicionar testes E2E com imagens reais consentidas.

### Fase 4 — Otimizações futuras
1. Testes de stress 1:N a 1M templates.
2. Compressão PCA de embeddings (se justificado).
3. Avaliar matching ISO de impressão digital via SourceAFIS bridge.

---

## 8. Métricas e KPIs recomendados

| Métrica | Alvo | Onde ver |
| --- | --- | --- |
| FAR | < 0.1% | `POST /admin/biometric/calibrate-threshold` |
| FRR | < 5% | `POST /admin/biometric/calibrate-threshold` |
| APCER (ataque aceite) | < 1% com anti-spoofing activado | Dashboard + testes de spoofing |
| BPCER (vivo rejeitado) | < 5% com anti-spoofing activado | Dashboard + testes de spoofing |
| Latência p95 verify | < 1 s | Métricas Prometheus |
| Latência p95 identify | < 500 ms (até 100k templates) | Testes de stress |
| Disponibilidade | 99.9% | Monitorização de infraestrutura |
| Templates por tenant | Crescimento semanal | Dashboard admin |

---

## 9. Runbooks operacionais

### Activar anti-spoofing em produção
1. Recolher dataset de calibração (vivo vs. ataque).
2. Correr `POST /admin/biometric/calibrate-threshold` com scores de liveness.
3. Definir `BIOMETRIC_LIVENESS_THRESHOLD` com base nos resultados.
4. Alterar `LIVENESS_MODEL=anti_spoofing`.
5. Reiniciar o serviço.
6. Monitorar APCER/BPCER no dashboard durante 48h.

### Rotação de chaves de encriptação
1. Gerar nova chave e adicionar ao keyring JSON (`BIOMETRIC_ENCRYPTION_KEYS`).
2. Definir `"active"` para a nova chave.
3. Reiniciar o serviço.
4. Chamar `POST /admin/biometric/re-encrypt` para re-cifrar todos os templates.
5. Remover chave antiga do keyring após validação.

### Recuperação de desastre (DR)
1. Restaurar base de dados a partir de backup.
2. Copiar ficheiros de modelo ONNX (`app/ml_models/`).
3. Garantir que `BIOMETRIC_ENCRYPTION_KEYS` está configurado com as mesmas chaves.
4. Importar templates via lógica inversa do export (a criar se necessário).

---

## 10. Decisões e riscos

| ID | Decisão | Razão | Risco residual |
| --- | --- | --- | --- |
| D1 | Manter `LIVENESS_MODEL=heuristic` por omissão | Threshold não calibrado para MiniFASNetV2 | Ataques de spoofing podem passar até activação |
| D2 | Não popular `embedding_vector` sem transformação cancelável | Evitar vector em claro na BD | Busca 1:N só funciona com transformação activa |
| D3 | Manter ORB para fingerprints | Sem biblioteca ISO Python madura | Menor precisão vs. minúcias ISO |
| D4 | mTLS apenas documentado | Sem acesso à infra de produção | Tráfego interno protegido apenas por HMAC |
| D5 | Notificação de re-enroll best-effort | Não bloquear verify se ERP falhar | Colaborador pode não ser avisado imediatamente |

---

## 11. O que resta em aberto

| Item | Estado | Razão | Owner sugerido |
| --- | --- | --- | --- |
| `hnsw.ef_search` afinado para o volume real | **Por aplicar** | Achado novo dos testes de stress: o valor por omissão perde ~25% das identificações a 100k templates | Backend/DBA |
| `LIVENESS_MODEL=anti_spoofing` activado em produção | Não activado | Decisão deliberada — precisa calibração de threshold primeiro | ML/Produto |
| mTLS aplicado à infra real | Só documentado | Fora do alcance de um agente sem acesso à infra de produção | Infra/DevOps |
| Webhook de re-enroll validado contra BD real | Só compilado | Não há ambiente de teste do ERP Go com o schema aplicado | Backend ERP |
| Testes E2E com detecção facial real (sem mocks) | Adiado | Falta imagens reais com consentimento ou gerador de faces sintéticas validado | QA/Legal |
| Compressão PCA de embeddings | Adiado | Precisa dataset real + plano de migração | ML/Backend |
| Matching de minúcias ISO | Adiado | Sem biblioteca Python madura e confiável | Arquitectura |
| Testes de stress 1:N a 1M templates | Não corrido | O benchmark suporta-o; a 100k a construção do índice já leva 8,5 min | QA/Backend |
| Testes E2E de anti-spoofing contra pipeline completo | Não iniciado | Dependente de imagens reais de ataque | QA/Segurança |
| Documentação de DR e importação de templates | Não iniciado | Export existe; import ainda não | DevOps/Backend |

---

## 12. Changelog

| Data | Versão | Alterações |
| --- | --- | --- |
| 2026-08-05 | 1.0 | Documento inicial com backlog priorizado. |
| 2026-08-08 | 2.0 | Reescrita completa: adicionados resumo executivo, roadmaps, runbooks, KPIs, decisões, riscos, changelog e detalhamento técnico de cada item. Actualizado com estado real pós-ronda de implementação. |

---

## Nota final

Todas as sugestões acima são **self-hosted** e não requerem serviços cloud. A única excepção seria se se quisesse usar modelos pré-treinados de terceiros, mas esses podem ser descarregados e corridos localmente. A soberania dos dados biométricos continua a ser o princípio orientador do FaceClock.
