# Runbook — Deploy do FaceClock em Produção

**Data:** 2026-08-05  
**Sistema:** FaceClock (`assiduidade_system_backend/`)  
**Objectivo:** checklist e procedimentos para colocar o FaceClock em produção de forma segura.

---

## 1. Pré-requisitos

- [ ] PostgreSQL 14+ com extensão `pgvector` instalada.
- [ ] Redis 6+ (necessário se `LIVENESS_CHALLENGE_STORE=redis`).
- [ ] Docker e docker-compose disponíveis (recomendado).
- [ ] Acesso ao ERP Nexora configurado com credenciais HMAC.
- [ ] TLS terminado no reverse proxy (Traefik/Nginx).

---

## 2. Segredos obrigatórios

Configure as seguintes variáveis de ambiente **antes** de iniciar o serviço:

```env
# Ambiente
ENVIRONMENT=production

# Base de dados
DATABASE_URL=postgresql://user:pass@host:5432/faceclock

# Redis (opcional para single-instance, obrigatório para multi-réplica)
REDIS_URL=redis://redis:6379/0

# Chave de encriptacao biometrica (opcao 1: chave unica)
BIOMETRIC_ENCRYPTION_KEY=<32-bytes-hex-or-ascii>

# OU opcao 2: keyring para rotacao
BIOMETRIC_ENCRYPTION_KEYS={"v1":"base64...","active":"v1"}

# Provedor de chave (self-hosted)
BIOMETRIC_KEY_PROVIDER=environment

# Credenciais Nexora (HMAC servico-a-servico)
NEXORA_CREDENTIAL_ENCRYPTION_KEY=<chave-fernet-32-bytes>

# Segredo para tokens de verificacao facial
FACIAL_VERIFICATION_SECRET=<segredo-forte-min-32-bytes>

# Modelos
BIOMETRIC_MODEL=facenet
LIVENESS_MODEL=heuristic
LIVENESS_CHALLENGE_STORE=redis

# Assinatura de imagem (ativar quando dispositivos suportarem)
REQUIRE_IMAGE_SIGNATURE=false

# Deteccao de actividade suspeita (opcional, defaults razoaveis)
SUSPICIOUS_ACTIVITY_THRESHOLD=5
SUSPICIOUS_ACTIVITY_WINDOW_SECONDS=600

# Webhook de re-enrolamento automatico (opcional; sem isto so marca PENDING_REENROLL)
ERP_REENROLL_WEBHOOK_URL=
```

---

## 3. Verificacao pré-deploy

### 3.1 Validar segredos

```bash
cd assiduidade_system_backend
./venv/Scripts/python -c "from app.config import settings; settings.assert_production_secrets()"
```

Deve terminar sem erros.

### 3.2 Aplicar migrations

```bash
cd assiduidade_system_backend
DATABASE_URL=<url-de-producao> ./venv/Scripts/python -m alembic upgrade head
```

**Nunca assumir que o schema está actualizado só porque o serviço arranca sem erro** — `Base.metadata.create_all()` corre no arranque mas só cria tabelas que ainda não existem, nunca faz `ALTER` numa tabela já existente. Colunas/tabelas adicionadas ao modelo depois de a BD já ter sido criada (ex.: `face_templates.transform_version`, `face_templates.embedding_vector`, `device_public_keys` — todas descobertas em falta em produção em 2026-08-08) só entram com uma migration explícita. Confirmar sempre `alembic_version` contra a HEAD (`alembic heads`) antes de assumir que um deploy está completo.

### 3.3 Verificar extensao pgvector

```sql
CREATE EXTENSION IF NOT EXISTS vector;
SELECT extversion FROM pg_extension WHERE extname = 'vector';
```

**Isto falha se a extensão não estiver instalada a nível de sistema operativo no servidor Postgres** (não é só uma questão de permissões) — `CREATE EXTENSION` devolve `extension "vector" is not available` com um `DETAIL` a apontar para um ficheiro `.control` em falta. Corrigir isso requer instalar o pacote pgvector no SO onde o Postgres corre (ex.: `apt install postgresql-<versao>-pgvector` + restart), antes de tentar de novo — confirmado em produção em 2026-08-08.

### 3.4 Verificar modelos MediaPipe

Os ficheiros devem existir em `app/ml_models/`:

```
app/ml_models/blaze_face_short_range.tflite
app/ml_models/face_landmarker.task
```

### 3.5 Testar health check

```bash
curl -f http://localhost:8000/health
```

---

## 4. Deploy

### 4.1 Com Docker Compose

```bash
docker-compose up -d faceclock
```

### 4.2 Sem Docker

```bash
cd assiduidade_system_backend
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

---

## 5. Configuracao do ERP Nexora

1. Criar credencial FaceClock no ERP:

```bash
cd assiduidade_system_backend
./venv/Scripts/python scripts/create_erp_credential.py --tenant-id <tenant> --name "ERP Proxy"
```

2. Configurar no ERP Go:

```env
FACECLOCK_BASE_URL=https://faceclock.seu-dominio.com
FACECLOCK_ACCESS_KEY_ID=<access-key>
FACECLOCK_SECRET_ACCESS_KEY=<secret-key>
```

3. Testar proxy:

```bash
curl -X POST https://api.nexora.e258tech.tech/api/assiduidade/biometric/facial/enroll \
  -H "Authorization: Bearer <token>" \
  -d '{"user_id":"123","captures":[...]}'
```

---

## 6. Checklist de seguranca

- [ ] `BIOMETRIC_ENCRYPTION_KEY` gerada com 32 bytes aleatórios.
- [ ] `FACIAL_VERIFICATION_SECRET` diferente do default.
- [ ] `NEXORA_CREDENTIAL_ENCRYPTION_KEY` diferente do default.
- [ ] TLS activo e redireccionamento de HTTP para HTTPS.
- [ ] Rate limiting configurado (`NEXORA_RATE_LIMIT_PER_KEY`).
- [ ] Logs centralizados (ELK, Loki, etc.).
- [ ] Backups da base de dados configurados.
- [ ] Monitoramento do `/health` e `/metrics`.

---

## 7. Ativacao gradual de funcionalidades

### 7.1 Liveness activa

Começar com desafios simples (BLINK) antes de SMILE/TURN_HEAD.

### 7.2 Assinatura de imagem

1. Desenvolver geração de chaves Ed25519 na app Android.
2. Testar com `REQUIRE_IMAGE_SIGNATURE=false`.
3. Activar `REQUIRE_IMAGE_SIGNATURE=true` em producao.

### 7.3 Anti-spoofing treinado

Desde 2026-08-08, `app/ml_models/anti_spoofing.onnx` já contém um modelo treinado real (MiniFASNetV2 80×80, [Silent-Face-Anti-Spoofing](https://github.com/minivision-ai/Silent-Face-Anti-Spoofing)), não o dummy anterior. O código lê o tamanho de input directamente do ONNX (não assume 128×128) e trata correctamente o output de 3 classes desse modelo (índice 1 = rosto real). Para activar:

1. Confirmar que `app/ml_models/anti_spoofing.onnx` é um modelo treinado, não o dummy (`scripts/create_dummy_antispoofing_model.py` gera um ficheiro ~1MB de pesos aleatórios; o modelo real tem uma proveniência rastreável, ex.: via `git log` do ficheiro).
2. Definir `LIVENESS_MODEL=anti_spoofing` (o default continua `heuristic`).
3. Calibrar `BIOMETRIC_LIVENESS_THRESHOLD` de acordo com APCER/BPCER observados — usar `/admin/biometric/metrics-dashboard` para acompanhar `apcer`/`bpcer` depois de activar, e ajustar antes de confiar cegamente no default.

Se trocar de modelo `.onnx` no futuro (arquitectura diferente, output com número de classes diferente do MiniFASNet), rever `AntiSpoofingONNXModel.score()` em `app/services/liveness_models.py` — a leitura de 3 classes assume especificamente a convenção MiniFASNet (índice 1 = real), que não é universal.

---

## 8. Novos endpoints administrativos (desde 2026-08-08)

Todos exigem `require_nexora_signature` com a permissão indicada, e a maioria é tenant-scoped via `apply_tenant`:

| Endpoint | Permissão | Descrição |
| --- | --- | --- |
| `GET /admin/biometric/suspicious-activity` | `biometric:admin` | Utilizadores/dispositivos com falhas consecutivas acima do threshold |
| `GET /admin/biometric/audit-logs` | `audit:read` | Audit log local de eventos biométricos (complementa `GET /audit/logs`, que delega ao ERP) |
| `GET /admin/biometric/metrics-dashboard` | `biometric:admin` | Métricas de processo + actividade suspeita + resumo de auditoria 24h |
| `GET /admin/biometric/export-templates` | `biometric:admin` | Export de templates cifrados (ciphertext tal como guardado) para backup/migração |
| `POST /admin/biometric/batch-enroll` | `biometric:admin` | Enrolamento em massa (até 20 utilizadores por pedido) |

Ver `docs/proximas-implementacoes-self-hosted.md` para o detalhe de cada um.

---

## 9. Rollback

Se necessário, fazer rollback para a versão anterior:

```bash
docker-compose down
docker-compose up -d faceclock:<versao-anterior>
```

Nota: se a nova versão alterou o formato de encriptação, garantir compatibilidade de leitura dos templates antigos. Se a nova versão adicionou migrations (colunas/tabelas novas), um rollback de código sem rollback de schema é normalmente seguro (colunas novas nullable não quebram código antigo que as ignora) — mas confirmar caso a caso.

---

## 10. Troubleshooting comum

| Sintoma | Causa provável | Solucao |
| --- | --- | --- |
| `mediapipe nao disponivel` | Modelos em falta | Verificar `app/ml_models/` |
| `pgvector nao esta instalado` | Extensao nao activa a nivel de SO, nao so de permissoes | Instalar o pacote pgvector no servidor Postgres, depois `CREATE EXTENSION vector;` |
| `column ... does not exist` (enroll/verify) | Migration em falta | `alembic upgrade head` — ver secção 3.2 |
| `Credenciais invalidas` | HMAC errado | Verificar clocks e chaves |
| `liveness_failed` | Threshold agressivo | Ajustar `BIOMETRIC_LIVENESS_THRESHOLD` |
| `invalid_pose` | Pose strict demais | Ajustar `BIOMETRIC_MAX_*` |

---

## 11. Contactos e referencias

- Documentacao arquitetural: `docs/arquitetura-reconhecimento-facial.md`
- Estado actual: `docs/estado-reconhecimento-facial.md`
- Fase 4: `docs/fase-4-reconhecimento-facial.md`
- Self-hosted: `docs/self-hosted-faceclock.md`
- Rotacao de chaves: `docs/runbook-rotacao-chaves-self-hosted.md`
- Hardening: `docs/hardening-faceclock.md`
- Backlog e estado das funcionalidades: `docs/proximas-implementacoes-self-hosted.md`

---

*Runbook criado para facilitar deploys seguros e reprodutíveis do FaceClock.*
