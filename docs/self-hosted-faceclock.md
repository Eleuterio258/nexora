# Guia Self-Hosted — FaceClock sem Serviços Externos

**Data:** 2026-08-05  
**Sistema:** FaceClock (`assiduidade_system_backend/`)

---

## Objectivo

Este documento descreve como correr o FaceClock **100% self-hosted**, sem depender de serviços cloud externos (AWS, Azure, HashiCorp Vault, etc.).

Todas as funcionalidades core (1:1, 1:N, liveness, encriptação, assinatura) funcionam em modo local. Funcionalidades opcionais que requerem cloud estão desactivadas por omissão.

---

## Stack mínima self-hosted

| Componente | Requisito | Nota |
| --- | --- | --- |
| PostgreSQL | 14+ | Com extensão `pgvector` |
| Redis | 6+ | Opcional; `memory` é o default para challenges |
| FaceClock | Python 3.11+ | Ver `requirements.txt` |
| Reverse proxy | Traefik/Nginx | Para TLS |

---

## Instalação

### 1. Instalar dependências principais

```bash
cd assiduidade_system_backend
python -m venv venv
./venv/Scripts/pip install -r requirements.txt
```

**NÃO instalar `requirements-extras.txt`** — esse ficheiro contém apenas dependências opcionais avançadas (ex.: anti-spoofing ONNX).

### 2. Configurar PostgreSQL

```sql
CREATE DATABASE faceclock;
CREATE EXTENSION IF NOT EXISTS vector;
```

### 3. Configurar variáveis de ambiente

Criar `.env`:

```env
ENVIRONMENT=production
DATABASE_URL=postgresql://user:pass@localhost:5432/faceclock

# Chave biométrica (32 bytes) — gerada localmente
BIOMETRIC_ENCRYPTION_KEY=<segredo-local-32-bytes>

# OU usar keyring JSON para rotacao (tudo local)
# BIOMETRIC_ENCRYPTION_KEYS={"v1":"base64...","active":"v1"}

# Provedor de chave local
BIOMETRIC_KEY_PROVIDER=environment

# Liveness (heuristico ou ONNX local)
LIVENESS_MODEL=heuristic                # ou anti_spoofing
LIVENESS_CHALLENGE_STORE=memory

# Assinatura de imagem opcional (geracao de chaves Ed25519 no dispositivo)
REQUIRE_IMAGE_SIGNATURE=false

# Fingerprint (self-hosted via OpenCV)
FINGERPRINT_MATCH_THRESHOLD=0.25

# Cancelable biometrics (opcional, self-hosted)
CANCELABLE_TRANSFORM_SECRET=<segredo-forte-32-bytes>
CANCELABLE_TRANSFORM_VERSION=v1

# Anti-spoofing ONNX (opcional, self-hosted)
# Ver docs/anti-spoofing-onnx.md para modelo real

# Credenciais internas
NEXORA_CREDENTIAL_ENCRYPTION_KEY=<segredo-fernet-32-bytes>
FACIAL_VERIFICATION_SECRET=<segredo-forte-32-bytes>
```

### 4. Gerar chave local forte

```bash
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

### 5. Iniciar

```bash
./venv/Scripts/uvicorn app.main:app --host 0.0.0.0 --port 8000
```

---

## Funcionalidades disponíveis em self-hosted

| Funcionalidade | Estado |
| --- | --- |
| Enrollment facial | ✅ |
| Verify 1:1 | ✅ |
| Identify 1:N (pgvector, com índice HNSW) | ✅ |
| Liveness heurística | ✅ |
| Liveness challenge | ✅ (memory store) |
| Encriptação AES-256-GCM | ✅ |
| Rotação de chaves | ✅ (keyring JSON) |
| Assinatura de imagem | ✅ (Ed25519 + device registry) |
| Cancelable biometrics | ✅ (transformação local) |
| Matching de impressão digital | ✅ (ORB/OpenCV self-hosted) |
| Anti-spoofing ONNX | ✅ (modelo treinado real incluído desde 2026-08-08, MiniFASNetV2 — ver secção abaixo) |
| Detecção de actividade suspeita | ✅ (contador de janela deslizante, memory/redis) |
| Audit log local | ✅ (`/admin/biometric/audit-logs`) |
| Dashboard de métricas | ✅ (`/admin/biometric/metrics-dashboard`) |
| Export/backup de templates | ✅ (`/admin/biometric/export-templates`) |
| Batch enrollment | ✅ (`/admin/biometric/batch-enroll`, até 20 por pedido) |
| Métricas | ✅ |

## Funcionalidades que requerem extras

| Funcionalidade | O que é preciso |
| --- | --- |
| Anti-spoofing ONNX (activar) | Já incluído; definir `LIVENESS_MODEL=anti_spoofing` (default continua `heuristic`) — ver secção abaixo |
| Redis challenge store / actividade suspeita partilhada | Redis local; `LIVENESS_CHALLENGE_STORE=redis` (a mesma variável controla os dois) |

---

## Vantagens desta abordagem

- **Sem vendor lock-in**
- **Menor superfície de ataque** (menos credenciais e endpoints externos)
- **Funciona em rede fechada / air-gapped**
- **Menor custo operacional**

## Limitações

- Liveness heurística é menos robusta contra ataques sofisticados do que um classificador PAD treinado.
- Chave local comprometida expõe todos os templates (mitigado por rotacao periódica).
- Memory challenge store não suporta múltiplas réplicas do FaceClock.

---

## Activar anti-spoofing treinado

Desde 2026-08-08, `app/ml_models/anti_spoofing.onnx` já é um modelo treinado real (MiniFASNetV2 80×80 do [Silent-Face-Anti-Spoofing](https://github.com/minivision-ai/Silent-Face-Anti-Spoofing), convertido para ONNX). Para o activar:

```bash
pip install -r requirements-extras.txt   # onnxruntime
```

```env
LIVENESS_MODEL=anti_spoofing
```

Depois calibrar `BIOMETRIC_LIVENESS_THRESHOLD` com capturas reais — ver `docs/runbook-deploy-producao-faceclock.md` secção 7.3 para o procedimento completo. Se quiseres trocar por outro modelo `.onnx` no futuro, o código lê o tamanho de input directamente do ficheiro (não assume 128×128), mas a interpretação do output de 3 classes assume especificamente a convenção do MiniFASNet — rever `AntiSpoofingONNXModel` em `app/services/liveness_models.py` se usares uma arquitectura diferente.

---

## Referências

- `docs/runbook-deploy-producao-faceclock.md` — deploy em produção
- `docs/hardening-faceclock.md` — hardening operacional (segredos, rede, mTLS)
- `docs/proximas-implementacoes-self-hosted.md` — backlog e estado das funcionalidades
- `docs/estado-reconhecimento-facial.md` — estado actual do sistema
