# Análise de Viabilidade — Proposta de Integração FaceClock ↔ Nexora ERP

**Data:** 2026-07-11
**Escopo:** Verificação em código real (não apenas documentação) das assunções feitas em `proposta-arquitetura-assiduidade-erp.md`, contra o estado actual de:
- BD `nexora_erp` (Postgres, container `pg`)
- `backend/` (Nexora ERP, Go 1.25 + chi)
- `assiduidade_system_backend/` (FaceClock, FastAPI/Python)

**Método:** inspecção directa da BD via `docker exec pg psql`, leitura de código-fonte com citação `ficheiro:linha`, sem confiar cegamente noutros `.md` do repositório (vários estão desactualizados, ver secção 5).

---

## 1. Veredicto

**Sim, é viável — e mais fácil do que a proposta original sugere**, porque grande parte da infraestrutura assumida como "a construir" **já existe** no ERP (validação de gateway, feature flags, ingestão de eventos de dispositivos). O trabalho real é principalmente **adaptação de contratos** (nomes de headers, formato de payload) e **decisão de reaproveitamento** (usar o módulo `hardware` já existente em vez de criar um endpoint novo), não construção de infraestrutura de raiz.

O momento é bom: o FaceClock tem praticamente zero dados reais em produção (ver secção 4) — é o ponto de menor risco para fazer este refactor.

---

## 2. O que já existe e funciona como a proposta assume

| Assunção da proposta | Estado real | Evidência |
|---|---|---|
| Claims JWT do ERP (`sub`, `tid`, `tipo`, `escopo`, `jti`) | ✅ Confirmado exactamente | `backend/internal/modules/auth/handlers/auth.go:28-46` |
| Sistema de feature flags (`saas.feature_catalog` + `sistema_configuracao.tenant_feature_flags`) com JSONB de configuração | ✅ Existe e funciona | `backend/internal/middleware/auth.go:294-325` (`RequireFeature`); tabelas confirmadas na BD |
| `get_actor()` no FaceClock aceita headers de confiança | ✅ Existe, mas sem validar assinatura dos headers | `assiduidade_system_backend/app/deps.py:54-63` |
| FaceClock já é cliente HTTP genérico de um ERP externo (não é preciso reescrever `erp_client.py`) | ✅ Confirmado — "Omnisys" é só nome em comentários, a integração é 100% configurável via `ERP_BASE_URL` | `assiduidade_system_backend/app/erp_client.py` |
| FaceClock e Nexora ERP partilham rede Docker `e258techmozambique` | ✅ Confirmado nos dois `docker-compose.yml` | — |
| Ausência de qualquer referência a "FaceClock" no código Go | ✅ Confirmado (grep exaustivo, zero resultados) — é 100% trabalho novo do lado do ERP | — |

---

## 3. Onde a proposta precisa de ser corrigida antes de avançar

### 3.1 `GET /api/auth/gateway/validate` já existe, mas com contrato diferente

O endpoint existe (`router.go:160`, handler em `auth.go:821-841`), mas:
- Devolve **204 No Content com dados em headers**, não JSON.
- Os headers são `X-Auth-User-Id`, `X-Auth-Tenant-Id`, `X-Auth-Session-Id`, `X-Auth-User-Email`, `X-Auth-User-Name`, `X-Auth-User-Scope` — **não** `X-User-Id`/`X-User-Role`/`X-Tenant-Id` como a proposta assume.
- **Não existe `X-User-Role`** — só `escopo`, não `tipo`/cargo.

**Acção necessária:** ou (a) configurar o gateway/Traefik para mapear `X-Auth-*` → `X-User-*` no forward, ou (b) adicionar `X-Auth-User-Role` ao handler `GatewayValidate` e ajustar `get_actor()` no FaceClock para ler os nomes reais. A opção (b) é mais simples — evita lógica extra no gateway.

### 3.2 Não existe endpoint "estilo FaceClock" para listar funcionários

`GET /api/rh/funcionarios` existe (`rh.go:157`), mas os campos são em português e não coincidem com o que a proposta assume (`employee_code`, `full_name`, `email`, `role`, `is_active`, `tenant_id`):

```go
// rh.go:190-203 — campos reais
ID, NumeroFuncionario, NomeCompleto, UnitID, UnidadeNome, Cargo, CargoID,
HorarioID, DataAdmissao, TipoContrato, Estado, UserID
// sem email no payload, sem tenant_id no corpo (vem do JWT), sem is_active booleano
```

**Acção necessária:** criar um endpoint/DTO novo (ex. `GET /api/integracoes/faceclock/funcionarios` ou adaptar `sync.py` do FaceClock para mapear os campos PT→EN), não é uma reutilização directa como a secção 6.1.2 da proposta sugere.

### 3.3 `rh.presencas.tipo` já existe na BD real — mas falta migration de catch-up

Confirmado directamente na BD (`\d rh.presencas`): a coluna `tipo` existe, com `CHECK` e dados reais (577 `presente`, 64 `atraso`, 32 `falta`). O handler `self-service/handlers/assiduidade.go` já filtra por ela correctamente.

**Problema:** nenhuma migration versionada em `backend/migrations/` cria essa coluna. Quem reconstruir a BD do zero a partir de `migrate up` **não terá `tipo`, `latitude`, `longitude`, `observacao`, nem o `CHECK` constraint** — só existem no dump de produção (`backup_nexora_erp_20260628_044410.sql`). Isto é uma lacuna de dívida técnica **independente** desta proposta, mas deve ser corrigida antes de qualquer integração nova sobre esta tabela, para não perpetuar o desalinhamento.

**Acção necessária:** gerar uma migration "catch-up" que documente o estado real de `rh.presencas` (mesmo que seja `ALTER TABLE ... ADD COLUMN IF NOT EXISTS`).

### 3.4 Já existe um módulo de ingestão de eventos de dispositivos — não recriar

A proposta assume que `POST /api/rh/attendance/events` "provavelmente não existe ainda". **Existe algo melhor**: um módulo `hardware` completo e operacional:

- `POST /api/hardware/events`, `/events/generic`, `/events/zkteco`, `/events/batch` (`router.go:2414-2431`)
- Autenticação por API Key de dispositivo: `RequireDeviceAuth` (`middleware/device_auth.go:34-37`)
- Processor que já grava em `rh.presencas` via upsert: `hardware/service/processor.go:118-139`
- Suporta múltiplos adaptadores (ZKTeco, Hikvision, REST genérico, MQTT)
- Mapeamento device→pessoa via `hardware.device_users`

**Recomendação forte:** registar o FaceClock como um **"device" com API Key** neste módulo `hardware`, em vez de construir um endpoint `/api/rh/attendance/events` novo e duplicado. Isto reaproveita autenticação, idempotência e consolidação já testadas.

**Nota:** o `registarPresenca` actual (processor.go:118-139) não define `tipo` no insert — usa sempre o `DEFAULT 'presente'`. Se o FaceClock passar a alimentar `rh.presencas` via este caminho, será preciso estender o processor para também decidir `atraso`/`falta` (hoje só o handler self-service calcula isso via outra via).

### 3.5 Feature `rh.assiduidade` ainda não existe — mas o mecanismo está pronto

Confirmado na BD: `saas.feature_catalog` só tem `rh.ferias`, `rh.avaliacoes`, `rh.formacoes`, `rh.folha_pagamento`, `rh.disciplinar`. `rh.assiduidade` está por criar — mas o middleware `RequireFeature` (usado hoje só uma vez, em `compras.aprovacoes`) já suporta exactamente o padrão JSONB que a proposta desenha na secção 9.3. A secção 9 da proposta está tecnicamente correcta e pronta a implementar sem alterações de infraestrutura.

---

## 4. Estado real do FaceClock (risco de migração)

Dados na BD Postgres `faceclock` (mesma instância `pg`, base separada — não é `nexora_erp`):

| Tabela | Linhas |
|---|---|
| `users` | 3 |
| `devices` | 1 |
| `clock_records` | 0 |
| `face_templates` | 0 |

**Conclusão:** não há dados de produção reais para migrar ou perder. Sem `Traefik` labels configuradas para o `controle-api` (só porta directa 8000) — ou seja, hoje o FaceClock **não está exposto publicamente via gateway**, o que é bom (postura fail-closed), mas também confirma que a "Fase 0" da proposta (isolar rede/gateway) ainda está por fazer, não só por confirmar.

---

## 5. Bugs e riscos de segurança encontrados (independentes da decisão de integração)

Estes devem ser corrigidos **de qualquer forma**, quer a integração avance ou não:

| Risco | Evidência | Severidade |
|---|---|---|
| `build_embedding()` degrada silenciosamente para embedding simulado e **determinístico pelo comprimento do payload** quando `facenet-pytorch` não carrega — sem erro visível ao chamador | `app/services/biometric.py:424-449` | Alto — verificação facial pode aceitar/rejeitar sem qualquer alarme |
| `JWT_SECRET_KEY` com default hardcoded `"change-me-in-production"`, apenas "esticado" para 32 bytes por repetição se não configurado | `app/config.py:40-46` | Crítico se chegar a produção sem override |
| `erp_fallback_local_login=true` por omissão — login local do FaceClock continua activo mesmo com ERP configurado | `app/config.py:36-38` | Médio — contraria o objectivo de centralizar auth no ERP |
| `sync_employees()` gera password inicial previsível = o próprio `employee_code` | `app/routers/sync.py:140` | Médio |
| `get_actor()` confia em headers `X-User-*` sem validar assinatura/origem — qualquer chamador com acesso de rede ao serviço pode forjar-se como admin de qualquer tenant | `app/deps.py:54-63` | Alto se a rede Docker não estiver isolada do exterior |
| Zero testes automatizados para `auth.py`, `sync.py`, `erp_client.py` — exactamente as três áreas que esta integração vai alterar | `tests/test_api.py` (grep sem resultados nessas áreas) | Alto risco de regressão sem rede de segurança |

### Discrepância de documentação encontrada (não é bug de código)

O `stakeholders-and-constraints.md` descreve um bug de `verify_pin()`/`pwd_context` inexistente em `app/security.py`. **Não existe no código actual** — a validação de PIN está correctamente implementada em `app/routers/authcode.py:74` usando `verify_password()` (bcrypt), numa rota `POST /api/v1/authcode/pin/validate` (não `/auth/login/pin` como o documento diz). Recomenda-se corrigir/remover essa entrada da tabela de riscos do documento de stakeholders, para não gastar esforço a "corrigir" um bug que já não existe.

---

## 6. Plano de acção recomendado (revisão do plano de fases original)

A estrutura de fases da proposta (0→5) mantém-se válida; ajustes concretos:

1. **Fase 0/1 (gateway):** decidir entre normalizar headers no `GatewayValidate` (adicionar `X-Auth-User-Role`) **ou** mapear no Traefik. Adicionar labels Traefik ao `controle-api` no `docker-compose.yml` do FaceClock (hoje inexistentes).
2. **Fase 2 (dados mestres):** criar endpoint novo de funcionários (não reaproveitar `ListarFuncionarios` tal como está); gerar a migration catch-up de `rh.presencas` primeiro.
3. **Fase 2 (config por tenant):** implementar `rh.assiduidade` no `feature_catalog` — sem bloqueios técnicos, mecanismo pronto.
4. **Fase 4 (eventos):** **não construir** `/api/rh/attendance/events`; integrar via `/api/hardware/events*` existente, estendendo o `processor.go` para decidir `tipo` (atraso/falta) em vez de só `DEFAULT 'presente'`.
5. **Antes de qualquer fase:** corrigir os riscos de segurança da secção 5 (especialmente o embedding simulado silencioso e o `JWT_SECRET_KEY` default), independentemente do calendário de integração — são riscos que existem hoje, com ou sem ERP.

---

## 7. Nota de segurança pendente (não resolvida)

O ficheiro `assiduidade_system_backend/stakeholders-and-constraints.md` tem, no working tree (alteração **não commitada**, não presente em `origin/main`), uma AWS Access Key + Secret colada no final do documento. Continua por remover — está apenas a aguardar confirmação do utilizador para não mexer sem autorização.
