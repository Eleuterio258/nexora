# Proposta de Arquitetura: FaceClock como Gateway de Assiduidade (Stateless)

## Contexto

Este documento define a arquitetura do `assiduidade_system_backend` (FaceClock) como um **gateway stateless de captura e validação biométrica de assiduidade**. O objetivo é que **nenhum dado fique no FaceClock**; toda a persistência é delegada ao ERP principal (`factPro/backend`, Nexora ERP).

> **Decisão arquitetural vigente (2026-07-12):** A única excepção ao princípio stateless são os **templates biométricos** (face e digitais), que permanecem no FaceClock (Python) por isolamento de dados sensíveis e performance de matching local. Todo o resto — auth, funcionários, unidades, dispositivos, registos de ponto, consentimentos LGPD, auditoria, configurações e relatórios — vive no Nexora ERP.

> **Nota sobre o nome da base de dados:** o banco referido como `nexoro_erp` é, na realidade, o **`nexora_erp`** — PostgreSQL usado pelo Nexora ERP.

> **Revisão de viabilidade (2026-07-11):** este documento foi confrontado com o código real de `backend/` e `assiduidade_system_backend/`, e com o estado real da BD `nexora_erp`. Veredicto: **viável, e mais barato do que aqui assumido** — várias peças dadas como "a construir" já existem (endpoint de gateway, módulo de ingestão de eventos de hardware, coluna `tipo` em `rh.presencas`, feature flags). As secções abaixo foram corrigidas em conformidade; ver detalhe completo com `ficheiro:linha` em [`analise-viabilidade-proposta-2026-07-11.md`](./analise-viabilidade-proposta-2026-07-11.md).

---

## 1. Resumo da arquitetura de auth dos dois sistemas

| Aspecto | Nexora ERP (`factPro/backend`) | FaceClock (`assiduidade_system_backend`) |
|---|---|---|
| Linguagem/Framework | Go 1.25 + chi | Python + FastAPI |
| Auth | Própria, standalone | Própria, standalone, com integração opcional a ERP |
| Banco de dados | PostgreSQL `nexora_erp`, schema `auth.*` | PostgreSQL `faceclock` (próprio) ou SQLite |
| Tabela de users | `auth.users` | `users` |
| JWT | HS256, segredos `JWT_SECRET` / `JWT_REFRESH_SECRET` | HS256, segredo `JWT_SECRET_KEY` |
| Claims principais | `sub`, `tid`, `tipo`, `escopo`, `jti` | `sub`, `type`, `role`, `tenant_id` |
| Login request | `POST /api/auth/login` com `{email, password}` | `POST /api/v1/auth/login` com `{username, password}` |
| Login response | `access_token`, `refresh_token`, `user`, `modulos`, `features`, `tipo`, `escopo` | `access_token`, `refresh_token`, `user` |

---

## 2. O que significa "FaceClock stateless"

Face à decisão arquitetural de não persistir dados no FaceClock, a tabela `users` local (e todas as outras não biométricas) deve ser eliminada. O FaceClock:

1. **Não valida credenciais localmente** — auth (login, refresh, PIN, TOTP) delega no Nexora ERP.
2. **Não guarda dados mestres** — funcionários, tenants, unidades e dispositivos vêm do ERP sob demanda ou cache em memória.
3. **Não persiste registos de ponto** — cada evento é enviado imediatamente ao ERP.
4. **Não persiste consentimentos, auditoria ou configurações** — delega tudo ao ERP.
5. **Mantém apenas templates biométricos** — face e digitais, cifrados, ligados por `erp_funcionario_id`.

A grande reformulação referida na proposta original é agora o objectivo: remover as dependências de `users.id` local e substituí-las por referências ao ERP (`erp_user_id` / `erp_funcionario_id`).

---

## 3. Arquitetura proposta

```
┌─────────────────┐      ┌─────────────────────────┐      ┌─────────────────────────────┐
│   App / Totem   │─────▶│   Gateway / Traefik     │─────▶│   Nexora ERP                │
│                 │      │  (valida JWT no ERP)    │      │  auth.users                 │
│                 │◀─────│  passa X-Auth-*         │◀─────│  rh.funcionarios            │
└─────────────────┘      └─────────────────────────┘      │  rh.presencas               │
         │                                                │  rh.unidades_organizacionais│
         │                                                │  hardware.devices           │
         │                                                │  lgpd.consents              │
         │                                                │  auditoria.audit_logs       │
         │                                                └─────────────────────────────┘
         │                                                           ▲
         │                                                           │
         └──────────────────▶   FaceClock   ─────────────────────────┘
                                  (apenas: biometria face/digital
                                   + proxy de registo de ponto)
```

### 3.1 O que fica no FaceClock (única excepção stateless)

| Funcionalidade | Razão de ficar no FaceClock |
|---|---|
| `biometric/verify` e `biometric/enroll` | Reconhecimento facial, processamento de embeddings, liveness. |
| `fingerprint/enroll`, `fingerprint/identify` | Impressão digital e identificação 1:N. |
| `face_templates`, `fingerprint_templates` | Dados biométricos sensíveis; isolamento e controles específicos no Python. |

> **Nota:** Os templates biométricos são a **única** persistência autorizada no FaceClock. Todo o resto é proxy/cache em memória ou delegação imediata ao ERP.

### 3.2 O que vai para o ERP (Nexora)

| Funcionalidade actual no FaceClock | Equivalente no Nexora ERP |
|---|---|
| Auth/login/JWT | `auth.users`, `/api/auth/login`, sessões, RBAC. |
| PIN/TOTP delegado | `/api/authcode/*` (já implementado). |
| Tenants | `saas.tenants` / `empresas.companies`. |
| Unidades | `rh.unidades_organizacionais`. |
| CRUD de funcionários | `rh.funcionarios` (ligado a `auth.users` via `user_id`). |
| Dispositivos/totems | `hardware.devices` (API Key de device). |
| Registo de ponto (eventos brutos) | `hardware.device_events` → `rh.presencas`. |
| Histórico/consolidação de presenças | `rh.presencas` (data, hora_entrada, hora_saida, horas_extra, tipo). |
| Pedidos de correção de ponto | Novo módulo/endpoint no ERP (a criar). |
| Consentimentos LGPD | Nova tabela `lgpd.consents` (a criar) ou reaproveitar auditoria. |
| Auditoria | `auditoria.audit_logs`. |
| Configuração de métodos | `sistema_configuracao.tenant_feature_flags` (`rh.assiduidade`). |
| Relatórios/exportação | Módulos de RH/relatórios do ERP. |
| Roles/permissoes | `auth.cargos`, `auth.permissoes_cargo`, `auth.permissoes_diretas`. |

### 3.3 Fluxo de um registo de ponto

1. Utilizador autentica-se no **Nexora ERP** e recebe token ERP.
2. App/Totem chama gateway com token ERP.
3. Gateway valida token no ERP (`GET /api/auth/gateway/validate`) e adiciona headers `X-Auth-*` + `X-Gateway-Secret`.
4. FaceClock valida o segredo do gateway e extrai o actor via `get_actor`.
5. FaceClock valida biometria localmente (se for o método escolhido) e/ou NFC / QR / geolocalização / PIN / TOTP.
6. FaceClock **não grava** o registo localmente; envia o evento imediatamente para o ERP via `POST /api/hardware/events/generic` (ou variante batch).
7. ERP persiste em `hardware.device_events` e consolida em `rh.presencas`.
8. FaceClock devolve ao App/Totem o resultado devolvido pelo ERP.

> **Modo offline:** se configurado no ERP (`rh.assiduidade.configuracao.offline.ativo`), o FaceClock pode aceitar registos sem conectividade, mantendo-os apenas em **memória ou fila temporária** até o ERP voltar a estar disponível. Em modo stateless estrito, registos offline não são persistidos em disco.

---

## 4. Dados que o FaceClock ainda precisa manter

Face à decisão arquitetural de não persistir dados no FaceClock, a única excepção são os **templates biométricos**. Todas as outras entidades (`users`, `tenants`, `units`, `devices`, `clock_records`, `consents`, `audit_logs`) devem ser **eliminadas ou transformadas em cache em memória**.

### 4.1 Templates biométricos (permanecem no FaceClock)

| Entidade | Finalidade |
|---|---|
| `face_templates` | Embeddings faciais para verificação/enrolamento. |
| `fingerprint_templates` | Templates de impressão digital para identificação 1:N. |

**Requisitos:**
- Criptografia em repouso (AES-256 ou equivalente).
- Ligação ao funcionário apenas por `erp_funcionario_id` (não há tabela `users` local).
- Remoção imediata quando o consentimento é revogado ou o funcionário é desactivado no ERP.
- Sem replicação para o ERP — o Nexora ERP **não armazena** templates biométricos.

### 4.2 Cache em memória (não persistido)

O FaceClock pode manter em memória, com TTL curto:

- Configuração de métodos de assiduidade (`rh.assiduidade`).
- Lista de funcionários do tenant (para lookup durante o matching).
- Tokens JWT de curta duração.

**Não pode haver tabelas espelho persistentes.** Quando o serviço reinicia, o cache é reconstruído a partir do ERP.

```python
# Exemplo de referência a um funcionário (apenas em memória/cache)
class EmployeeRef:
    erp_user_id: int
    erp_funcionario_id: int
    employee_code: str
    full_name: str
    email: str
    role: str
    status: str
    tenant_id: int
    unit_id: int | None
```

---

## 5. Opções técnicas para delegar o auth ao Nexora ERP

### Opção A — Gateway valida token no ERP e passa headers de confiança

O FaceClock já suporta identidade via headers de confiança (`app/deps.py:54-63`, confirmado):

```python
def get_actor(
    authorization: str | None = Header(default=None, alias="Authorization"),
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    x_user_role: str | None = Header(default=None, alias="X-User-Role"),
    x_tenant_id: str | None = Header(default=None, alias="X-Tenant-Id"),
) -> ActorContext:
    jwt_actor = _get_actor_from_jwt(authorization)
    if jwt_actor:
        return jwt_actor
    return ActorContext(id=x_user_id, role=x_user_role or "SYSTEM", tenant_id=x_tenant_id)
```

**Correcção face ao ERP real:** o endpoint `GET /api/auth/gateway/validate` (`auth.go:821`) não devolve `X-User-Id`/`X-User-Role`/`X-Tenant-Id` — devolve `X-Auth-User-Id`, `X-Auth-Tenant-Id`, `X-Auth-Session-Id`, `X-Auth-User-Email`, `X-Auth-User-Name`, `X-Auth-User-Scope`, sem role/tipo. Duas opções: (a) mapear os nomes no Traefik/gateway ao reencaminhar o pedido, ou (b) estender `GatewayValidate` para também devolver `X-Auth-User-Role` (mais simples, sem lógica extra no gateway).

**Prós:** elimina login próprio do FaceClock; centraliza sessões e permissões no ERP.

**Contras:** necessita garantir que o FaceClock só seja acessível via gateway, para evitar injeção de headers — hoje `get_actor()` confia nos headers `X-User-*` sem validar a sua origem (`app/deps.py:54-63`), e o `controle-api` não tem nenhuma label Traefik configurada, logo não está isolado atrás de gateway algum neste momento (só porta directa 8000).

### Opção B — Reaproveitar `ERP_BASE_URL` apontando para o Nexora ERP

Hoje o FaceClock já pode autenticar via ERP (`app/routers/auth.py`). Para apontar ao Nexora ERP, é necessário:

1. Adaptar `erp_client.authenticate_user()` para enviar `{email: username, password: password}`.
2. Mapear a resposta do Nexora ERP para os campos que o FaceClock espera:

| FaceClock espera | Nexora ERP retorna |
|---|---|
| `user_id` / `id` | `user.id` |
| `tenant_id` | `user.tenant_id` |
| `role` | Deve ser mapeado a partir de `tipo` + `escopo` + cargo. |
| `full_name` | `user.nome` |
| `email` | `user.email` |

**Prós:** reaproveita mecanismo existente.

**Contras:** o refresh continua passando pelo FaceClock e os tokens emitidos ao cliente continuam sendo do FaceClock.

### Opção C — Compartilhar o mesmo segredo JWT

**Não recomendado.** Os claims são incompatíveis e criaria acoplamento frágil.

### Opção D — Implementar OAuth2/OpenID Connect no Nexora ERP

Padrão aberto e escalável, mas exige desenvolvimento significativo. Indicado para médio/longo prazo se houver mais sistemas para integrar.

---

## 6. Mudanças necessárias

### 6.1 No Nexora ERP (`factPro/backend`)

1. **Endpoint para receber eventos de ponto do FaceClock**
   - **Correcção (2026-07-11):** não é preciso construir de raiz. Já existe um módulo `hardware` completo e operacional (`backend/internal/modules/hardware/`) com `POST /api/hardware/events`, `/events/generic`, `/events/zkteco`, `/events/batch`, autenticação por API Key (`RequireDeviceAuth`, `middleware/device_auth.go:34`) e um processor que já grava em `rh.presencas` via upsert (`hardware/service/processor.go:118-139`). **Recomendação: registar o FaceClock como um "device" neste módulo**, em vez de criar `/api/rh/attendance/events` duplicado.
   - Ajuste necessário: o `registarPresenca` actual não define `tipo` no insert (usa sempre o `DEFAULT 'presente'`) — estender o processor para decidir `atraso`/`falta` a partir do payload do FaceClock.

2. **Endpoint para listar funcionários**
   - Criado `GET /api/hardware/assiduidade/funcionarios` (`ListarFuncionariosIntegracao`), autenticado por API Key de device, com mapeamento PT→EN para `id`, `employee_code`, `full_name`, `email`, `role`, `is_active`, `tenant_id`. Traduz `companies.id → saas.tenants.id`.

3. **Modelo de presenças**
   - `hardware.device_events` já cumpre o papel de eventos brutos recebidos de dispositivos (incluindo o FaceClock); `rh.presencas` é a consolidação diária.
   - **Correcção:** a coluna `tipo` **já existe na BD real de produção** (`character varying(20) DEFAULT 'presente'`, com `CHECK` para `presente/atraso/falta/saida_antecipada`, e dados reais: 577 presente / 64 atraso / 32 falta). O que falta é uma **migration de catch-up** em `backend/migrations/` — nenhuma migration versionada cria essa coluna hoje.

4. **Auth/gateway**
   - Garantir que `/api/auth/gateway/validate` possa ser usado pelo gateway para validar tokens e obter `X-User-Id`, `X-Tenant-Id`, role/escopo.
   - **Correcção:** o endpoint já existe e funciona (`auth.go:821`), mas devolve `X-Auth-User-Id`/`X-Auth-Tenant-Id`/`X-Auth-User-Scope` (sem role/tipo) — ver ajuste detalhado na secção 5, Opção A.

### 6.2 No FaceClock (`assiduidade_system_backend`)

1. **Eliminar CRUD de dados mestres e tabelas correspondentes**
   - Remover routers `admin.py`, `users.py`, `units.py`, `devices.py`, `reports.py`, `integrations.py` (já removidos em 2026-07-12).
   - Remover modelos/tabelas `User`, `Tenant`, `Unit`, `Device`, `ClockRecord`, `AdjustmentRequest`, `AuditLog`, `Consent`, `IntegrationBatch`.

2. **Login**
   - `POST /api/v1/auth/login` passa a ser proxy para o ERP (fallback local desactivado em produção).
   - Manter `get_actor` aceitando headers de confiança do gateway (`X-Auth-*` + `X-Gateway-Secret`).

3. **Consulta de dados mestres**
   - Substituir `sync.py` por consultas sob demanda ao ERP (`GET /api/hardware/assiduidade/funcionarios`).
   - Manter cache em memória com TTL curto (60s); não há tabelas espelho persistentes.

4. **Integração de eventos**
   - Adaptar `app/erp_client.send_attendance_event()` para chamar o Nexora ERP.
   - Refazer `clock/register` para **não gravar localmente**; enviar evento directamente para o ERP e devolver a resposta.

5. **Dados a manter local (única excepção)**
   - `face_templates`, `fingerprint_templates` — cifrados em repouso, ligados por `erp_funcionario_id`.

---

## 7. Riscos e cuidados

| Risco | Mitigação |
|---|---|
| FaceClock acessível directamente sem gateway | **Mitigado (Fase 1, 2026-07-11):** `get_actor()` já não confia em `X-Auth-*` sem o segredo partilhado `GATEWAY_SHARED_SECRET`/`X-Gateway-Secret` (HMAC constant-time, obrigatório em produção). Isolamento de rede/Traefik continua recomendado como defesa em profundidade. |
| JWT auto-assinado no FaceClock | Em produção, desactivar validação JWT local; confiar só no gateway/ERP. |
| ERP offline = ponto não registado | Alta disponibilidade do ERP; ou aceitar perda temporária. Modo offline, se activado, mantém eventos apenas em memória/fila temporária. |
| Presença offline não chega ao ERP | Reenvio manual/proxy para retry no ERP; não há `/clock/sync` local. |
| Mapeamento de roles | Criar mapping claro entre `tipo`/`cargo` do ERP e `UserRole` do FaceClock. |
| LGPD/biometria | Templates cifrados no FaceClock; consentimentos e auditoria no ERP; remoção imediata ao revogar consentimento. |
| **`JWT_SECRET_KEY` com default hardcoded fraco** (`change-me-in-production`, `app/config.py:40-46`) | Exigir segredo forte via env var em qualquer ambiente não-dev; falhar startup se ausente em produção. |
| **`build_embedding()` degrada silenciosamente para embedding simulado e determinístico** (seed = comprimento do payload base64) quando `facenet-pytorch` não carrega (`app/services/biometric.py:424-449`), sem erro visível | Falhar explicitamente (ou alertar) em vez de simular, fora de ambiente de teste — risco alto de aceitar/rejeitar biometria sem qualquer alarme. |
| Zero testes automatizados em `auth.py`, `sync.py`, `erp_client.py` (confirmado por grep em `tests/test_api.py`) | Cobrir estas três áreas com testes antes de iniciar o refactor — são exactamente as que a integração vai alterar. |

---

## 8. Conclusão

> **Sim, é viável e recomendável.** O FaceClock deve ser reduzido a um **gateway stateless de captura e validação biométrica de presença**. O Nexora ERP assume o papel de sistema de registo: auth, funcionários, tenants, unidades, dispositivos, registos de ponto, consentimentos LGPD, auditoria e configuração de métodos.

> **Excepção controlada:** os **templates biométricos** (face e digitais) permanecem no FaceClock (Python) por isolamento de dados sensíveis e performance de matching local.

A principal mudança de mindset é: **o FaceClock deixa de ter base de dados própria.** Apenas mantém os templates biométricos cifrados; todo o resto é cache em memória ou delegação imediata ao ERP.

---

## 9. Configuração por tenant dos tipos de assiduidade no ERP

Uma mudança importante deve acontecer no **Nexora ERP**: quem gere o tenant — tipicamente um `ADMIN_SISTEMA` ou `GESTOR_RH` com permissão de configuração — deve poder decidir **quais métodos de assiduidade** a empresa vai usar (reconhecimento facial, impressão digital, QR Code, NFC, geolocalização, etc.).

### 9.1 Porquê no ERP?

- O ERP é o sistema de registo e gestão do tenant.
- Evita duplicação de configurações entre ERP e FaceClock.
- Permite cobrança/planeamento por funcionalidade (feature flags já existem).
- Centraliza controlo de acesso: só quem tem permissão pode alterar o método de registo de ponto da empresa.

### 9.2 Mecanismo existente no Nexora ERP

O Nexora ERP já tem um sistema de **feature flags por tenant**:

- `saas.feature_catalog` — catálogo de funcionalidades (`key`, `modulo`, `nome`, `ativo_por_defeito`, `configuravel`).
- `sistema_configuracao.tenant_feature_flags` — activação/desactivação por tenant, com coluna `configuracao JSONB`.
- Middleware `RequireFeature(pool, feature)` — verifica se uma feature está activa para o tenant autenticado.
- Middleware `RequirePermission(pool, modulo, acao)` — verifica permissões RBAC.

Exemplo de feature existente:

```sql
INSERT INTO saas.feature_catalog (key, modulo, nome, descricao, ativo_por_defeito, configuravel)
VALUES ('rh.ferias', 'recursos-humanos', 'Gestão de Férias', '...', true, true);
```

### 9.3 Proposta de modelagem

Criar uma feature principal `rh.assiduidade` e, dentro do JSONB `configuracao`, definir os métodos permitidos e respectivos parâmetros.

#### Opção recomendada: feature única com configuração JSONB

```sql
INSERT INTO saas.feature_catalog (key, modulo, nome, descricao, ativo_por_defeito, configuravel)
VALUES (
  'rh.assiduidade',
  'recursos-humanos',
  'Assiduidade / Controlo de Ponto',
  'Registo de presença via FaceClock com métodos configuráveis.',
  true,
  true
);
```

A configuração por tenant seria guardada em:

```sql
INSERT INTO sistema_configuracao.tenant_feature_flags
  (tenant_id, codigo, modulo, activo, configuracao, updated_by)
VALUES
  (1, 'rh.assiduidade', 'recursos-humanos', true, '{
    "metodos": {
      "facial":       { "ativo": true,  "obrigatorio_liveness": true, "threshold_match": 0.85 },
      "fingerprint":  { "ativo": true },
      "qr_code":      { "ativo": true,  "duracao_segundos": 60 },
      "nfc":          { "ativo": false },
      "geolocation":  { "ativo": true,  "raio_metros_padrao": 100 }
    },
    "eventos_permitidos": ["ENTRY", "BREAK_START", "BREAK_END", "EXIT"],
    "offline": { "ativo": true, "maximo_dias_reenvio": 7 }
  }'::jsonb, 42);
```

#### Opção alternativa: sub-features granulares

Criar uma feature por método:

```sql
INSERT INTO saas.feature_catalog (key, modulo, nome, descricao, ativo_por_defeito, configuravel) VALUES
  ('rh.assiduidade.face',        'recursos-humanos', 'Assiduidade - Reconhecimento Facial',   '...', true, true),
  ('rh.assiduidade.fingerprint', 'recursos-humanos', 'Assiduidade - Impressão Digital',       '...', true, true),
  ('rh.assiduidade.qr',          'recursos-humanos', 'Assiduidade - QR Code',                 '...', true, true),
  ('rh.assiduidade.nfc',         'recursos-humanos', 'Assiduidade - NFC',                     '...', false, true),
  ('rh.assiduidade.geo',         'recursos-humanos', 'Assiduidade - Geolocalização',          '...', true, true);
```

**Recomendação:** usar a **Opção 1 (feature única + JSONB)**, porque:
- É mais fácil de estender com novos parâmetros (thresholds, raio, etc.).
- Evita poluir o catálogo de features com dezenas de sub-features.
- Permite validar a coerência da configuração num único ponto.

### 9.4 Quem pode configurar?

A gestão desta configuração deve ser protegida por permissão RBAC. Recomenda-se reaproveitar a permissão já existente:

- Módulo: `sistema-configuracao`
- Ação: `editar_configuracoes`

Esta permissão já é usada em endpoints de `/api/system` e é apropriada para o administrador do tenant configurar o comportamento do sistema.

No registo de rotas do ERP:

```go
r.With(
    mw.RequireAuth(cfg.JWTSecret, db),
    mw.RequirePermission(db, "sistema-configuracao", "editar_configuracoes"),
).Put("/api/configuracao/tenant/feature/rh.assiduidade", handler.ConfigurarAssiduidade)
```

Quem tem esta permissão poderá:
- Activar/desactivar métodos de assiduidade.
- Ajustar thresholds (qualidade facial, raio geofencing, etc.).
- Definir se o modo offline é permitido.

A activação/desactivação da própria feature no catálogo (`saas.feature_catalog`) deve continuar a ser responsabilidade do **superadmin** ou de quem gere planos/subscrições.

### 9.5 Como o FaceClock consome essa configuração

O FaceClock não deve guardar a configuração dos métodos como master. Deve consultar o ERP nos seguintes momentos:

1. **No startup / cache por tenant**
   - Carregar configuração de `rh.assiduidade` para cada tenant e manter em cache (ex: Redis ou memória com TTL).

2. **Antes de cada registo de ponto**
   - Validar se o `source` do pedido está activo para o tenant.
   - Exemplo: se `facial` estiver desactivado, rejeitar `POST /clock/register` com `source=FACIAL`.

3. **Endpoint de consulta**
   - Criar `GET /api/v1/tenant/attendance-config` no FaceClock que retorna a configuração do tenant corrente (para a app saber quais botões mostrar).

Exemplo de resposta:

```json
{
  "tenant_id": "abc-123",
  "metodos": {
    "facial": { "ativo": true, "threshold_match": 0.85 },
    "fingerprint": { "ativo": true },
    "qr_code": { "ativo": true, "duracao_segundos": 60 },
    "nfc": { "ativo": false },
    "geolocation": { "ativo": true, "raio_metros_padrao": 100 }
  },
  "eventos_permitidos": ["ENTRY", "BREAK_START", "BREAK_END", "EXIT"],
  "offline": { "ativo": true, "maximo_dias_reenvio": 7 }
}
```

### 9.6 Validação no FaceClock

Adicionar um middleware ou helper em `clock/register` e `methods/*`:

```python
# pseudocódigo
async def validar_metodo_assiduidade(tenant_id: str, source: SourceType):
    config = await erp_client.get_attendance_config(tenant_id)
    metodo = MAPEAMENTO_SOURCE_METODO[source]  # FACIAL -> facial
    if not config.metodos.get(metodo, {}).get("ativo"):
        raise HTTPException(403, "Método de assiduidade não permitido para este tenant.")
```

Mapeamento sugerido:

| `SourceType` FaceClock | Método ERP |
|---|---|
| `FACIAL` | `facial` |
| `FINGERPRINT` | `fingerprint` |
| `QR_CODE` | `qr_code` |
| `NFC` | `nfc` |
| `SELFIE_GPS` / `GEOLOCATION` | `geolocation` |
| `PIN` | `pin` |
| `MANUAL` | `manual` |

### 9.7 Mudanças necessárias

#### No Nexora ERP

1. **Migrations**
   - Inserir `rh.assiduidade` no `saas.feature_catalog`.
   - Criar migration de catch-up para a coluna `tipo` em `rh.presencas` — já existe na BD real (com dados), mas ausente das migrations versionadas; já é referenciada em `self-service/handlers/assiduidade.go`.

2. **Endpoint de configuração**
   - `GET /api/configuracao/tenant/feature/rh.assiduidade` — ler configuração.
   - `PUT /api/configuracao/tenant/feature/rh.assiduidade` — atualizar configuração.
   - Protegido por `RequireAuth` + `RequirePermission(db, "sistema-configuracao", "editar_configuracoes")`.

3. **Endpoint para o FaceClock**
   - `GET /api/rh/assiduidade/config` — retorna configuração do tenant autenticado (ou via API key de integração).

4. **Permissão RBAC**
   - Reaproveitar `sistema-configuracao.editar_configuracoes` para o admin do tenant.
   - Reservar a gestão do catálogo (`saas.feature_catalog`) ao superadmin.

#### No FaceClock

1. **Client ERP**
   - Adicionar `erp_client.get_attendance_config(tenant_id)`.

2. **Validação**
   - Criar helper `validar_metodo_assiduidade()`.
   - Aplicar em `clock/register`, `biometric/verify`, `methods/*`.

3. **Cache**
   - Cachear configuração por tenant com TTL curto (ex: 60 segundos) para não sobrecarregar o ERP.

4. **Endpoint de consulta**
   - `GET /api/v1/tenant/attendance-config` para a app/dashboard.

---

## 10. Conclusão

> **Sim, é viável e recomendável.** O FaceClock deve ser reduzido a um **gateway stateless de captura e validação biométrica de presença**. O Nexora ERP assume o papel de sistema de registo: auth, funcionários, tenants, unidades, dispositivos, registos de ponto, consentimentos LGPD, auditoria, folha de pagamento **e configuração dos métodos de assiduidade permitidos por tenant**.

> **Excepção controlada:** os **templates biométricos** (face e digitais) permanecem no FaceClock (Python).

A principal mudança de mindset é: **o FaceClock deixa de ter base de dados própria**, excepto pelos templates biométricos cifrados.

---

## 11. Plano de implementação por fases

A implementação deve ser incremental, para reduzir risco e permitir validação contínua.

### Fase 0 — Preparação e alinhamento

**Objectivo:** definir contratos, decisões arquiteturais e infraestrutura mínima.

| Entregável | Detalhe |
|---|---|
| Decisão arquitetural | Confirmar: FaceClock stateless; **apenas templates biométricos ficam no Python**. |
| Contrato de integração | Definir endpoints, payloads, mapeamento de roles, códigos de erro. |
| Decisão de dados | ERP recebe eventos brutos; `hardware.device_events` já existe. |
| Rede Docker | Garantir que FaceClock só é acessível via gateway/Traefik. |
| Segredos | `GATEWAY_SHARED_SECRET` obrigatório em produção; `JWT_SECRET_KEY` só para dev/teste. |

**Validação:** documento de API acordado entre equipas.

---

### Fase 1 — Auth e gateway (foundation)

**Objectivo:** o FaceClock passa a confiar na identidade validada pelo ERP.

**Estado: implementada em código (2026-07-11)**, com uma revisão de abordagem no ponto 1.2:

| # | Tarefa | Sistema | Estado |
|---|---|---|---|
| 1.1 | `GatewayValidate` (`auth.go:821`) estendido para incluir `X-Auth-User-Role`. Labels Traefik/DNS público continuam por decidir (secção 5 do `CONTRATO-INTEGRACAO-ERP.md`) — não é bloqueador graças ao 1.2. | Infra + ERP | ✅ header; ⏳ Traefik/DNS |
| 1.2 | **Revisto:** em vez de depender só de isolamento de rede, foi adicionado um segredo partilhado `GATEWAY_SHARED_SECRET` + header `X-Gateway-Secret` (`app/deps.py:_check_gateway_secret`, HMAC constant-time). Qualquer pedido com `X-Auth-User-Id` sem o segredo correcto recebe `401`. Obrigatório em produção via `assert_production_secrets()`. | FaceClock | ✅ |
| 1.3 | Fallback de login local desactivado em produção: `Settings.local_login_fallback_enabled` devolve sempre `False` quando `ENVIRONMENT=production`, usado em `app/routers/auth.py` nos dois pontos que antes liam `erp_fallback_local_login` directamente. (Endpoint `/auth/login` mantém-se — continua a ser o único caminho de login da app, agora só sem fallback local em produção.) | FaceClock | ✅ |
| 1.4 | Testes de segurança adicionados em `tests/test_api.py` (`TestGatewaySecurity`, `TestProductionLoginFallback`): headers de confiança sem/segredo-errado → `401`; com segredo certo → sucesso; login local recusado com `ENVIRONMENT=production`. Suite completa corrida antes/depois — mesmas 4 falhas pré-existentes (não relacionadas), zero regressões. | FaceClock | ✅ |

**Validação:** login no ERP permite aceder a endpoints protegidos do FaceClock — pendente de wiring real do gateway (Fase 2+, quando o Go passar a chamar o FaceClock enviando `X-Auth-*` + `X-Gateway-Secret`).

---

### Fase 2 — Dados mestres e configuração por tenant

**Objectivo:** ERP é master de funcionários, tenants, unidades e métodos de assiduidade; FaceClock consome via API e mantém apenas cache em memória.

**Estado: lado ERP implementado e testado end-to-end (2026-07-11); lado FaceClock por fazer.**

| # | Tarefa | Sistema | Estado |
|---|---|---|---|
| 2.1 | Endpoint dedicado `GET /api/hardware/assiduidade/funcionarios` (não `/api/rh/funcionarios` adaptado — campos incompatíveis, confirmado). Autenticado por API Key de device, não JWT. | ERP | ✅ |
| 2.2 | FaceClock: `erp_client.get_employees()` consulta o ERP a cada necessidade (ou cache TTL curto). **Não grava em tabela local.** | FaceClock | ⏳ pendente |
| 2.3 | FaceClock: remover tabelas `users`, `tenants`, `units` (ou torná-las views/cache em memória). | FaceClock | ⏳ pendente |
| 2.4 | Feature `rh.assiduidade` criada em `saas.feature_catalog` (migration `20260711000001_rh_assiduidade_feature`, aplicada). | ERP | ✅ |
| 2.5 | `GET/PUT /api/system/configuracao/tenant/feature/rh.assiduidade` protegidos por `sistema-configuracao.editar_configuracoes`/`ver_configuracoes`. | ERP | ✅ |
| 2.6 | `GET /api/hardware/assiduidade/config` — path em `/api/hardware` (grupo autenticado por device). | ERP | ✅ |
| 2.7 | Adicionar `erp_client.get_attendance_config()` e cache por tenant em memória no FaceClock. | FaceClock | ⏳ pendente |
| 2.8 | Criar `GET /api/v1/tenant/attendance-config` para app/dashboard (proxy/cache do ERP). | FaceClock | ⏳ pendente |

**Bug crítico descoberto durante o teste desta fase (não introduzido por ela):** `hardware.devices.tenant_id` é na verdade `empresas.companies.id` (por FK), enquanto `rh.funcionarios`/`rh.presencas`/`tenant_feature_flags` usam `saas.tenants.id` — dois espaços de ID diferentes com o mesmo nome de coluna. Confirmado com dados reais (Enigma School: `companies.id=7` vs `saas.tenants.id=5`). O `hardware/service/processor.go` já existente **não traduz** isto, pelo que qualquer evento de um terminal ZKTeco/Hikvision já em produção pode estar a gravar `rh.presencas.tenant_id` errado sempre que essas duas IDs divergem para a empresa em causa — risco de contaminação de dados de assiduidade entre tenants. Os endpoints novos desta fase (2.1/2.6) traduzem correctamente via `resolveSaasTenantID()`; o `processor.go` **não foi alterado** (fora do âmbito, hardware já em uso) — ver detalhe em `CONTRATO-INTEGRACAO-ERP.md`, secção 3.

**Validação:** confirmada por teste manual (device de teste + curl) — `GET .../funcionarios` devolveu os 32 funcionários certos do tenant 5 (não do 7), `GET .../config` devolveu o JSONB correcto, pedido sem API Key deu `401`. Falta a parte "admin activa no ERP e a app reflecte" porque o lado FaceClock (2.2/2.7/2.8) ainda não consome nada disto.

---

### Fase 3 — Validação de métodos e registo de ponto

**Objectivo:** o FaceClock valida o método de assiduidade contra a configuração do ERP antes de aceitar o registo.

**Estado: 3.1/3.2 implementados e testados (2026-07-11); 3.3/3.4 por fazer.**

| # | Tarefa | Sistema | Estado |
|---|---|---|---|
| 3.1 | Helper `validar_metodo_assiduidade(source)` (`app/services/attendance_validation.py`) — **sem `tenant_id` como parâmetro**: o tenant já vem implícito na única API Key de device configurada (`get_attendance_config()` não recebe tenant_id). | FaceClock | ✅ |
| 3.2 | Validação aplicada em `clock/register`, `biometric/verify` (fixo em `FACIAL`), `methods/qr`, `methods/nfc`, `methods/geolocation`. | FaceClock | ✅ |
| 3.3 | Usar thresholds da configuração do ERP em vez de valores hardcoded. | FaceClock | ⏳ pendente |
| 3.4 | Tratar offline: permitir registo local quando configurado, mas marcar como `PENDING` até sync. | FaceClock | ⏳ pendente |

**Validação confirmada por teste (pytest, mockando `erp_client.get_attendance_config`):** método com `ativo: false` explícito no JSON de configuração é rejeitado com `403` em `clock/register` e `methods/qr/validate`; `source=ONLINE` (modo de transporte, não é um "método") continua sempre permitido mesmo com todos os métodos desactivados — decisão documentada em `attendance_validation.py` para não quebrar o fluxo normal de sync online/offline.

---

### Fase 4 — Eventos de presença no ERP

**Objectivo:** os registos de ponto são persistidos apenas no ERP; FaceClock atua como proxy.

**Estado: lado ERP implementado e testado end-to-end (2026-07-11); lado FaceClock por refazer.**

| # | Tarefa | Sistema | Estado |
|---|---|---|---|
| 4.1 | Migration de catch-up `20260711000002_rh_presencas_tipo_catchup` aplicada (coluna já existia na BD real, faltava só o registo versionado). | ERP | ✅ |
| 4.2 | **Não criada** — `hardware.device_events` (já existente, ver secção 3) já cumpre o papel de "eventos brutos"; criar `rh.eventos_presenca` seria duplicar. | ERP | ✅ (decisão: reaproveitar) |
| 4.3 | `processor.go`/`registarPresenca` estendido com `calcularTipoPresenca()`: compara a hora do evento com `rh.horarios_trabalho.hora_entrada` do funcionário (tolerância 10 min) e grava `tipo='atraso'`/`'presente'`. `tipo='falta'` resolvido à parte (ver 4.8). | ERP | ✅ |
| 4.8 | Rotina diária `process-daily-absences` (`backend/internal/background/jobs.go`) marca `tipo='falta'` em `rh.presencas`. | ERP | ✅ (2026-07-12) |
| 4.4 | `erp_client.send_attendance_event()` aponta para `/api/hardware/events/generic`. | FaceClock | ✅ (já feito) |
| 4.5 | **Refazer `clock/register`:** não gravar `ClockRecord` localmente; enviar evento directamente para o ERP e devolver resposta do ERP. | FaceClock | ⏳ pendente |
| 4.6 | **Remover `/clock/sync` local** — não há registos locais para sincronizar. Criar `/clock/erp/retry` apenas como proxy para reprocessamento no ERP (opcional). | FaceClock | ⏳ pendente |
| 4.7 | Consolidação síncrona em `registarPresenca` (upsert directo em `rh.presencas` por evento). | ERP | ✅ (já feito) |
| 4.9 | Novo endpoint no ERP para consulta de histórico de ponto do utilizador (`GET /api/self-service/assiduidade/historico` ou similar), a ser consumido pela app via FaceClock proxy. | ERP | ⏳ pendente |

**Bug adicional encontrado e corrigido durante o teste desta fase:** `registarPresenca`/`registarFrequencia` tinham uma concatenação SQL `\|\| $N::text` sobre um parâmetro `int64` (`eventID`) sem mais nenhum contexto de tipo — o pgx falhava em runtime com `cannot find encode plan` sempre que um evento de hardware chegava a essa linha. **Nunca tinha sido exercida** (0 eventos hardware processados em toda a história do projecto até esta sessão). Corrigido formatando `eventID` como string em Go antes de o passar à query.

**Validação:** testado manualmente end-to-end com device de teste + `hardware.device_users` mapeado — evento às 07:50 (horário esperado 07:30) gravou `tipo='atraso'`; evento às 07:35 (dentro da tolerância) gravou `tipo='presente'`. No FaceClock, testes automatizados confirmam que `clock/register` e `clock/sync` agendam o envio ao ERP com o `record_id` correcto, e que o mapeamento de payload (`device_serial`/`employee_no`/`direction`/`credential_type`) está correcto.

---

### Fase 5 — Refinamento, produção e limpeza stateless

**Objectivo:** remover persistência local desnecessária, reforçar segurança e preparar para produção.

**Estado: itens de segurança implementados (2026-07-11/12); limpeza de dados por fazer.**

| # | Tarefa | Sistema | Estado |
|---|---|---|---|
| 5.1 | **Remover routers administrativos duplicados** do FaceClock: `admin.py`, `users.py`, `units.py`, `devices.py`, `face_templates.py` (mantido), `reports.py`, `integrations.py`. Já removidos (2026-07-12). | FaceClock | ✅ |
| 5.2 | **Remover tabelas/modelos não biométricos** do FaceClock: `User`, `Tenant`, `Unit`, `Device`, `ClockRecord`, `AdjustmentRequest`, `AuditLog`, `Consent`, `IntegrationBatch`. Manter apenas `FaceTemplate` e `FingerprintTemplate` + entidades auxiliares de configuração/em dev. | FaceClock | ⏳ pendente |
| 5.3 | Auditoria da configuração de assiduidade no ERP (`mw.AuditSistemaConfiguracao` aplicado a `/api/system`). | ERP | ✅ |
| 5.4 | LGPD: "direito ao esquecimento" apaga `FaceTemplate` **e** `FingerprintTemplate`; revogação de consentimento desactiva templates. | FaceClock | ✅ |
| 5.5 | Métricas de sync (`erp_sync_metrics.py`) expostas em `/metrics`. | FaceClock | ✅ |
| 5.6 | Teste E2E cross-serviço real — bloqueado pela decisão de rede/gateway (secção 5 do contrato). | Ambos | ⚠️ parcial |

**Validação:** testes automatizados a passar (FaceClock: 41 testes, mesmas 4 falhas pré-existentes não relacionadas; Go: build limpo). Sistema pronto para produção *do ponto de vista de código*; a validação "com dados reais" continua a depender da decisão de rede/gateway (secção 5 do contrato) e do registo real do FaceClock como device no ERP.

---

### Fase 6 — Endpoints de dados no ERP para substituir funcionalidade do FaceClock

**Objectivo:** o ERP expõe endpoints que o FaceClock passa a consumir/proxyar, eliminando a necessidade de dados locais.

| # | Tarefa | Sistema | Estado |
|---|---|---|---|
| 6.1 | Histórico de ponto do utilizador: `GET /api/self-service/assiduidade/historico` (ou reaproveitar endpoint existente). | ERP | ⏳ pendente |
| 6.2 | Pedidos de correção de ponto: CRUD no ERP (`rh.pedidos_correcao_ponto` ou similar) + endpoint proxy no FaceClock. | ERP | ⏳ pendente |
| 6.3 | Consentimentos LGPD: tabela `lgpd.consents` + endpoints CRUD no ERP; FaceClock passa a proxy/cache. | ERP | ⏳ pendente |
| 6.4 | Auditoria: endpoint `POST /api/audit-logs/` já existe; FaceClock envia eventos de auditoria directamente para o ERP. | ERP | ✅ (endpoint existe) |
| 6.5 | Relatórios/exportação de ponto: usar relatórios do ERP; remover `ExportResponse` do FaceClock. | FaceClock | ⏳ pendente |

### Resumo das dependências entre fases

```
Fase 0 ──▶ Fase 1 ──▶ Fase 2 ──▶ Fase 3 ──▶ Fase 4 ──▶ Fase 5 ──▶ Fase 6
           (gateway)  (dados    (validação (eventos   (limpeza   (endpoints
                      mestres)   métodos)   ERP)       stateless)  ERP)
```

- A **Fase 1** pode ser feita em paralelo com parte da **Fase 2**.
- A **Fase 3** depende da **Fase 2** (configuração dos métodos).
- A **Fase 4** depende da **Fase 1** (autenticação) e da **Fase 2** (funcionários).
- A **Fase 5** deve começar após as Fases 2-4 estarem estáveis.
- A **Fase 6** substitui funcionalidades legadas por endpoints ERP.

---

## 12. Próximos passos imediatos

1. Revisar e aprovar a decisão arquitetural: **stateless, excepto biométricos no Python**.
2. Revisar e aprovar o contrato de integração (Fase 0).
3. Iniciar a Fase 5 (limpeza de modelos/tabelas não biométricos no FaceClock).
4. Em paralelo, iniciar a Fase 6 (novos endpoints no ERP para histórico, correções e consentimentos).
