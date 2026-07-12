# Contrato de Integração — Nexora ERP ↔ FaceClock

> **Decisão arquitetural vigente (2026-07-12):** O FaceClock é **stateless**. **Nenhum dado persiste no FaceClock**, com a única excepção dos **templates biométricos** (face e digitais), que permanecem no Python/FaceClock por isolamento de dados sensíveis e performance de matching local. Toda a auth, dados mestres, registos de ponto, consentimentos LGPD, auditoria, configurações e relatórios são persistidos no Nexora ERP.

**Fases:** 0 (Preparação e alinhamento), 1 (Auth e gateway), 2 (Dados mestres e configuração por tenant), 3 (Validação de métodos), 4 (Eventos de presença), 5 (Refinamento e limpeza stateless) e 6 (Endpoints ERP para funcionalidades legadas) — ver `proposta-arquitetura-assiduidade-erp.md`, secção 11.
**Data:** 2026-07-11
**Estado:** Fases 0-5 implementadas e testadas (5.6 parcial — ver nota), mais dois itens pós-Fase 5: controlo de acesso por role em `/admin/*` (secção 8.1) e reenvio em lote ao ERP (secção 8.2). Resumo por fase: gateway/segredos (0-1), dados mestres/config por tenant (2), validação de métodos (3), envio real de eventos com cálculo de `tipo='atraso'` (4), e produção — mutações de dados mestres bloqueadas em produção, auditoria da config de assiduidade, gap de LGPD corrigido (fingerprint templates), métricas de sync (5). Suite pytest do FaceClock: 71 testes a passar (sem falhas conhecidas); build Go limpo. Três bugs pré-existentes descobertos e corrigidos pelo caminho: `tenant_id` (`companies.id` vs `saas.tenants.id`), erro de inferência de tipo do pgx em `registarPresenca`/`registarFrequencia` (nunca antes exercido), `FingerprintTemplate` não apagado pelo endpoint de "direito ao esquecimento", e ausência total de controlo de role em `/admin/*`. Pendente: `tipo='falta'` (exige rotina diária), fila persistente com backoff real, E2E cross-serviço real, e rede/gateway físico (Traefik/DNS, secção 5).

---

## 1. Identidade do chamador (gateway → FaceClock)

O FaceClock resolve o "actor" de cada pedido em duas etapas (`app/deps.py:get_actor`), por ordem de prioridade:

1. **JWT Bearer local** (`Authorization: Bearer ...`) — usado pela app/totem quando ainda autentica directamente no FaceClock.
2. **Headers de confiança**, no formato devolvido por `GET /api/auth/gateway/validate` do Nexora ERP:

| Header | Origem | Obrigatório |
|---|---|---|
| `X-Auth-User-Id` | `auth.users.id` | Sim (senão actor é anónimo/`SYSTEM`) |
| `X-Auth-User-Role` | Role em vocabulário FaceClock (`COLABORADOR`/`GESTOR_RH`/`ADMIN_SISTEMA`/`AUDITOR`) — **não** o `tipo` bruto do ERP | Não (default `SYSTEM`) |
| `X-Auth-Tenant-Id` | `auth.memberships.tenant_id` | Não |

**Decisão registada:** o `GatewayValidate` do ERP (`backend/internal/modules/auth/handlers/auth.go:821`) foi estendido para também devolver `X-Auth-User-Role`, preenchido a partir de `auth.users.tipo`. Como o ERP só tem `tipo` (superadmin/funcionario/aluno/encarregado/candidato) e não o cargo/permissões RBAC completos, quem estiver a montar o gateway/Traefik deve traduzir esse valor para o vocabulário do FaceClock usando `map_erp_role()` (`app/deps.py`) **antes** de reencaminhar o header — `get_actor()` em si não faz essa tradução, porque o mesmo header também é usado por outros chamadores de confiança (ex.: testes automatizados) que já enviam directamente um role no vocabulário do FaceClock.

**Resolvido (Fase 1):** `get_actor()` já não confia cegamente nestes headers. Foi introduzido um **segredo partilhado** (`X-Gateway-Secret`, comparado com `GATEWAY_SHARED_SECRET` via `hmac.compare_digest`, `app/deps.py:_check_gateway_secret`): sempre que um pedido traz `X-Auth-User-Id`, tem também de apresentar o segredo correcto, senão recebe `401`. Se `GATEWAY_SHARED_SECRET` não estiver configurado (vazio), o comportamento antigo mantém-se (aceitável só em dev local — bloqueado em produção, ver secção 2). Isto não substitui o isolamento de rede (continua a ser boa prática não expor o FaceClock directamente), mas remove a dependência total nisso: mesmo que alguém alcance a porta do serviço, não consegue forjar identidade sem conhecer o segredo.

---

## 2. Segredos

- `JWT_SECRET_KEY`: `app/config.py` define `ENVIRONMENT` (default `development`). Em arranque (`app/main.py:lifespan`), `settings.assert_production_secrets()` **falha o arranque** se `ENVIRONMENT=production` e `JWT_SECRET_KEY` estiver ausente ou igual ao default versionado (`change-me-in-production`). Não escolhemos o segredo por vós — quem fizer o deploy de produção tem de definir `JWT_SECRET_KEY` real no `.env`/secret manager antes de definir `ENVIRONMENT=production`.
- `GATEWAY_SHARED_SECRET` (Fase 1): a mesma guarda `assert_production_secrets()` também exige este segredo em produção. Sem ele, o arranque falha com uma mensagem explícita — não silenciosamente inseguro.
- Sem `ENVIRONMENT=production` explícito, o comportamento por omissão mantém-se inalterado (compatível com dev/staging actuais).

---

## 1.1 Login local desactivado em produção (Fase 1)

`Settings.local_login_fallback_enabled` (`app/config.py`) devolve sempre `False` quando `ENVIRONMENT=production`, independentemente de `ERP_FALLBACK_LOCAL_LOGIN`. `app/routers/auth.py` usa esta propriedade nos dois pontos onde antes lia `erp_fallback_local_login` directamente. Em produção, se o ERP estiver indisponível ou não configurado, o login falha com `401` em vez de cair para a password local da BD do FaceClock — consistente com "a identidade tem de vir sempre do ERP".

---

## 3. Decisão de dados: stateless no FaceClock

**Decisão:** O FaceClock **não persiste** registos de ponto. Cada evento capturado é enviado imediatamente para o ERP via módulo `hardware` já existente (`backend/internal/modules/hardware/`). O FaceClock deve ser registado como um **device** com API Key nesse módulo (`RequireDeviceAuth`, `middleware/device_auth.go:34`), enviando eventos para `/api/hardware/events` (ou variante `generic`/batch). O processor (`hardware/service/processor.go:118`) já grava directamente em `rh.presencas` via upsert.

**Templates biométricos:** são a única excepção — permanecem no FaceClock (tabelas `face_templates` e `fingerprint_templates`), cifrados em repouso, ligados apenas por `erp_funcionario_id`.

**Trabalho pendente (Fase 4/5):**
- Refazer `clock/register` para não gravar localmente; enviar directamente para o ERP.
- Remover `/clock/sync` local e tabela `clock_records`.
- Adicionar endpoints no ERP para histórico de ponto, pedidos de correção e consentimentos LGPD (Fase 6).

**⚠️ Bug pré-existente descoberto ao testar a Fase 2 (2026-07-11), não corrigido aqui:** `hardware.devices.tenant_id` tem FK para `empresas.companies.id`, **não** para `saas.tenants.id`. Mas `rh.funcionarios.tenant_id`, `rh.presencas.tenant_id` e `sistema_configuracao.tenant_feature_flags.tenant_id` usam `saas.tenants.id`. São dois espaços de identificadores diferentes que só coincidem por acaso terem o mesmo nome de coluna — confirmado com dados reais: Enigma School tem `companies.id=7` mas `saas.tenants.id=5`. O `hardware/service/processor.go` (`registarPresenca`, linha ~124) grava `rh.presencas.tenant_id` directamente com `device.TenantID` (= `companies.id`) **sem traduzir**, o que insere presenças de dispositivos ZKTeco/Hikvision já em uso com o `tenant_id` errado sempre que `companies.id ≠ saas.tenants.id` para essa empresa — risco de contaminação cross-tenant em dados de assiduidade já em produção. Não alterei `processor.go` (fora do âmbito desta integração e usado por hardware já em campo — requer decisão e teste dedicados). Os meus dois novos endpoints (secção 4) fazem a tradução correctamente via `resolveSaasTenantID()`.

---

## 4. Endpoints de funcionários e configuração para o FaceClock (Fase 2 — implementado no ERP)

`GET /api/rh/funcionarios` existe mas devolve campos em português incompatíveis com o que o `sync.py` do FaceClock espera (`employee_code`, `full_name`, `email`, `role`, `is_active`, `tenant_id`). Em vez de adaptar esse endpoint (serve a UI do ERP), foram criados dois endpoints novos, dedicados a integrações, autenticados por API Key de device (não por JWT de utilizador):

| Endpoint | Handler | Ficheiro |
|---|---|---|
| `GET /api/hardware/assiduidade/funcionarios` | `ListarFuncionariosIntegracao` | `backend/internal/modules/recursos-humanos/handlers/assiduidade_integracao.go` |
| `GET /api/hardware/assiduidade/config` | `ObterConfigAssiduidadeDevice` | idem |

Ambos protegidos por `RequireDeviceAuth` (mesmo grupo de rotas do `/api/hardware/events*`) — o FaceClock deve ser registado como uma linha em `hardware.devices` (`driver='custom'`, já que `hikvision`/`zkteco`/`generic_rest`/`generic_mqtt` não se aplicam) com uma API Key própria. Ambos traduzem `companies.id → saas.tenants.id` via `resolveSaasTenantID()` antes de consultar `rh.funcionarios`/`tenant_feature_flags` (ver bug na secção 3).

**Simplificação assumida nesta fase:** `role` é sempre `"COLABORADOR"` no payload de `ListarFuncionariosIntegracao` — o ERP não distingue `GESTOR_RH`/`AUDITOR` por funcionário nesta integração (só por cargo/RBAC completo, que não é exposto aqui). Se for preciso diferenciar, terá de se cruzar com `auth.cargos`/`auth.permissoes_cargo`, fora do âmbito desta fase.

**Testado end-to-end em 2026-07-11** contra a BD local: device de teste registado em `hardware.devices` (tenant Enigma School, `companies.id=7`), `rh.assiduidade` activada para `saas.tenants.id=5`; `GET .../funcionarios` devolveu correctamente os 32 funcionários do tenant 5 (não do 7); `GET .../config` devolveu a configuração JSONB correcta; pedido sem `X-API-Key` devolveu `401`. Dados de teste removidos após validação.

### Endpoint de administração (tenant admin, JWT)

| Endpoint | Handler | Permissão |
|---|---|---|
| `GET /api/system/configuracao/tenant/feature/rh.assiduidade` | `ObterConfigAssiduidade` (`sistema-configuracao/handlers/assiduidade.go`) | `sistema-configuracao.ver_configuracoes` |
| `PUT /api/system/configuracao/tenant/feature/rh.assiduidade` | `GuardarConfigAssiduidade` | `sistema-configuracao.editar_configuracoes` |

**Correcção face à proposta original:** o path base é `/api/system`, não `/api/configuracao` como a secção 9.7 da proposta assumia — `/api/configuracao` não existe no router; a árvore de rotas de configuração está toda sob `/api/system`.

Migration `20260711000001_rh_assiduidade_feature` insere a feature `rh.assiduidade` em `saas.feature_catalog` (aplicada e confirmada na BD local).

---

## 5. Rede Docker / gateway (aberto — decisão de infraestrutura)

Ainda por decidir, porque depende de escolha de domínio/DNS que não é decisão técnica unilateral:

- Se o FaceClock deve ter um hostname público próprio atrás do Traefik (seguindo o padrão `*.e258tech.tech` usado pelos outros serviços), ou
- Se deve ficar acessível apenas internamente na rede Docker `e258techmozambique` (sem hostname público), confiando só em quem estiver na mesma rede (ex.: o próprio `nexora-api` como proxy/relay).

**Recomendação:** manter sem hostname público por agora (é o estado actual) e restringir por rede Docker + validação futura de mTLS ou API Key adicional entre `nexora-api` e `controle-api`, evitando expor mais uma superfície pública antes de a Fase 1 (auth) estar concluída.

---

## 6. Códigos de erro (convenção)

| Situação | Código HTTP |
|---|---|
| Identidade ausente (sem JWT nem headers) | Actor `SYSTEM`/anónimo — depende do endpoint aplicar `require_roles` |
| Método de assiduidade desactivado para o tenant (Fase 3) | `403` |
| Feature `rh.assiduidade` inactiva no ERP (Fase 2) | `402 Payment Required` (consistente com `RequireFeature` do ERP) |
| Segredo de produção em falta | Aplicação não arranca (falha rápida, não é um código HTTP) |

---

## 7. FaceClock: consumo dos endpoints do ERP (Fase 2, lado FaceClock) e validação de métodos (Fase 3)

- `app/erp_client.py`: `get_employees()`/`get_employee()` passam a chamar `/api/hardware/assiduidade/funcionarios[/{id}]`; `send_attendance_event()` passa a chamar `/api/hardware/events/generic` (contrato `GenericPayload`: `device_serial`, `employee_no`, `event_time` RFC3339, `event_type`, `direction`, `credential_type` — ver `hardware/adapters/generic_rest.go`). Novo método `get_attendance_config()` chama `/api/hardware/assiduidade/config`. Todos usam `X-API-Key` (`_device_headers()`), não `X-Integration-Key` (nome antigo, nunca consumido por nada no ERP — confirmado por grep).
- `app/routers/sync.py` **não precisou de alterações** — o mapeamento de campos já assumia o formato `id/employee_code/full_name/email/role/is_active/tenant_id` que os novos endpoints do ERP devolvem.
- Novo router `app/routers/attendance_config.py`: `GET /api/v1/tenant/attendance-config`, com cache em memória (TTL 60s, `_get_config_cached()`). **Limitação conhecida:** cache e API Key são globais (uma instância do FaceClock = um tenant do ERP); não há suporte a múltiplas API Keys de device por tenant.
- Novo serviço `app/services/attendance_validation.py`: `validar_metodo_assiduidade(source: SourceType)`, aplicado em `clock/register`, `biometric/verify` (fixo em `FACIAL`), `methods/qr`, `methods/nfc`, `methods/geolocation`. Falha aberta (permite) quando: `source` não mapeado (`ONLINE`/`OFFLINE_SYNC`/`INTEGRATION` são modos de transporte, não métodos), método sem entrada explícita na configuração, ou ERP indisponível — só bloqueia (`403`) quando o método está **explicitamente** `ativo: false` na configuração do tenant.
- Testes: suite `tests/test_api.py` cresceu de 19 para 31 testes a passar ao longo desta sessão (`TestGatewaySecurity`, `TestProductionLoginFallback`, `TestAttendanceConfig`, `TestAttendanceMethodValidation`); as mesmas 4 falhas pré-existentes (não relacionadas com esta integração) mantêm-se.

---

## 8. Fase 5 — Refinamento, produção e limpeza stateless

- **5.1 (remoção de routers administrativos):** removidos do FaceClock os routers duplicados: `admin.py`, `users.py`, `units.py`, `devices.py`, `reports.py`, `integrations.py`. Mantêm-se `biometric.py` e `fingerprint.py` (templates locais) e `authcode.py` (proxy PIN/TOTP).
- **5.2 (remoção de tabelas/modelos não biométricos):** em curso — remover `User`, `Tenant`, `Unit`, `Device`, `ClockRecord`, `AdjustmentRequest`, `AuditLog`, `Consent`, `IntegrationBatch` do FaceClock. Manter apenas `FaceTemplate`, `FingerprintTemplate` e entidades de configuração/dev.
- **5.3 (auditoria):** `internal/middleware/audit.go` generalizado — `AuditSistemaConfiguracao` aplicado ao grupo `/api/system`, cobrindo `PUT /api/system/configuracao/tenant/feature/rh.assiduidade`. Grava em `auditoria.audit_logs`.
- **5.4 (LGPD):** `DELETE /consents/users/{user_id}/biometric-data` apaga `FaceTemplate` **e** `FingerprintTemplate`; revogação de consentimento desactiva templates.
- **5.5 (métricas):** `app/erp_sync_metrics.py` exposto em `GET /metrics`.
- **5.6 (E2E):** bloqueado pela decisão de rede/gateway (secção 5).

## 9. Fase 6 — Endpoints ERP para funcionalidades legadas do FaceClock

Como o FaceClock deixa de persistir dados, o ERP precisa de expor endpoints para substituir funcionalidade anteriormente local:

| Funcionalidade FaceClock (legada) | Endpoint ERP proposto | Estado |
|---|---|---|
| `GET /clock/me` (histórico de ponto) | `GET /api/self-service/assiduidade/historico` | ⏳ pendente |
| `POST/GET /clock/adjustments` (pedidos de correção) | `POST/GET /api/rh/assiduidade/correcoes` | ⏳ pendente |
| `POST/GET /consents` (consentimentos LGPD) | `POST/GET /api/lgpd/consents` | ⏳ pendente |
| `GET /audit/logs` | `GET /api/audit-logs/` (já existe) + `POST /api/audit-logs/` | ✅ endpoint existe |
| Relatórios/exportação CSV | Módulos de relatórios do ERP | ⏳ pendente |

O FaceClock continuará a expor paths idênticos (ex.: `GET /api/v1/clock/me`), mas funcionará como **proxy/cache** para estes endpoints ERP.

## 8.1 Controlo de acesso por role nos endpoints `/admin/*` (pós-Fase 5)

**Bug real descoberto e corrigido:** quase todos os endpoints `/admin/*` do FaceClock não tinham qualquer verificação de role — a restrição a "só admin" existia apenas por convenção do caminho do URL, não era imposta pelo código. Qualquer `COLABORADOR` autenticado (via gateway ou JWT local) conseguia chamar `/admin/users`, `/admin/devices`, `/admin/face-templates`, etc.

- Nova dependency factory `require_role(*allowed_roles)` (`app/deps.py`), aplicada via `dependencies=[Depends(require_role(...))]`:
  - `users.py`, `units.py`, `devices.py`, `face_templates.py`: `ADMIN_SISTEMA`/`GESTOR_RH`.
  - `admin.py` (clock-records/reports/export): `ADMIN_SISTEMA`/`GESTOR_RH`/`AUDITOR`; retenção/cleanup: só `ADMIN_SISTEMA`.
  - `audit.py` (`list_audit_logs`): `ADMIN_SISTEMA`/`GESTOR_RH`/`AUDITOR`.
  - `integrations.py` (`list_batches`): `ADMIN_SISTEMA`/`GESTOR_RH`.
- Testes: `TestAdminRoleEnforcement` — prova `COLABORADOR` bloqueado (`403`), `ADMIN_SISTEMA` aceite (`200`) e pedido sem qualquer identidade também bloqueado.

## 8.2 Reenvio em lote ao ERP (pós-Fase 5)

Corrige a limitação registada na secção 10 ("retry com backoff real... hoje é best-effort simples"): `POST /clock/erp/retry-failed` deixou de reenviar um registo de cada vez e passou a agrupar até 100 por chamada, usando `POST /api/hardware/events/batch` do ERP (que já existia e não era consumido por nada no FaceClock).

- `app/erp_client.py`: novo `send_attendance_events_batch(events)` — contrato diferente do envio individual: `{"events": [...]}` no formato `models.NormalizedEvent` do Go (**PascalCase**, sem tags JSON custom: `DeviceSerial`, `EmployeeNo`, `EventTime`, `EventType`, `Direction`, `CredentialType`), não o `GenericPayload` em snake_case usado por `send_attendance_event()`. Limite de 100 eventos por lote (levanta `ValueError` acima disso, espelhando o limite do ERP).
- `app/services/erp_attendance_forwarder.py`: novo `_build_normalized_event()` (mesma informação que `_build_payload()`, nomes de campo diferentes) e `forward_clock_records_batch(record_ids)` — correlaciona sucesso/falha por posição no lote (a ordem dos `results` devolvidos pelo ERP corresponde à ordem do pedido), gravando o mesmo `payload.erp_synced`/`erp_sync_error` que o envio individual.
- `app/routers/clock.py`: `retry_failed_erp_forwarding()` reescrito para agrupar os registos elegíveis em lotes de 100 e agendar `forward_clock_records_batch` (uma `BackgroundTask` por lote) em vez de uma por registo.
- Continua sem fila persistente/backoff — é reenvio manual sob pedido (`/clock/erp/retry-failed`), só a granularidade da chamada HTTP ao ERP passou de N pedidos para N/100.
- Testes: `TestErpBatchForwarding` (limite de 100, lote vazio, sucesso/falha por registo, e que o retry agenda lotes em vez de chamadas individuais).

---

## 8.3 `tipo='falta'` — rotina diária (pós-Fase 5)

Resolve a lacuna registada desde a Fase 4: `tipo='falta'` não é derivável de um único evento (é ausência de evento), por isso não podia viver em `hardware/service/processor.go` — precisava de uma rotina diária a comparar dias úteis esperados vs. ausência de registo.

- `backend/internal/background/jobs.go`: novo job `process-daily-absences` (mesmo padrão `runDaily` dos restantes jobs — warm-up 30s, depois a cada 24h), chamando `processDailyAbsences(db)` → `processAbsencesForDate(ctx, db, data)` para o **dia anterior** (o dia corrente ainda pode receber um evento de entrada mais tarde).
- Marca `tipo='falta'` em `rh.presencas` para funcionários com `estado='ativo'`, `horario_id` configurado (`horarios_trabalho.ativo=TRUE`), activos nessa data (`data_admissao`/`data_saida`), cujo dia seja um dia útil do horário (`dias_semana`, convenção ISO 1=segunda...7=domingo — consistente com o valor por omissão `'1,2,3,4,5'` já usado em toda a BD), **sem** entrada registada nesse dia e **sem** uma ausência aprovada (`rh.ausencias.estado='aprovado'`) a cobrir a data.
- `ON CONFLICT (funcionario_id, data) DO UPDATE` — idempotente (reexecutar para a mesma data não duplica nem altera o resultado).
- Testado manualmente contra a BD local real (34 funcionários com `horario_id=9`, Mon-Sex 07:30, marcados `falta` para uma segunda-feira sem registos; confirmada idempotência ao correr duas vezes; confirmado que um funcionário com entrada real registada **não** é sobreposto por `falta`); dados de teste removidos no fim.

## 8.4 Login único via ERP (2026-07-12)

O app Android deixou de autenticar directamente no FaceClock — o login passa a ser feito sempre no Nexora ERP (`POST /api/auth/login`), para todos os utilizadores (colaborador e gestor). O FaceClock deixou de emitir/validar os seus próprios tokens de login.

- **Go (`GatewayValidate`, `auth.go`):** passou a devolver `X-Auth-User-Role` já traduzido para o vocabulário do FaceClock (`ADMIN_SISTEMA`/`GESTOR_RH`/`COLABORADOR`), em vez do `tipo` bruto — resolve a lacuna "mapeamento fino de roles" que constava na secção 10: `gatewayAppRole()` reutiliza `models.LoadUserAccess`/`UserAccess.Can("recursos-humanos", "aprovar_ausencias")` para decidir `GESTOR_RH` a partir de permissões RBAC reais, não de um role dedicado (que não existe em `auth.users.tipo`). Testado com `TestGatewayAppRole_*` (superadmin/gestor/colaborador, via pgxmock).
- **FaceClock (`app/deps.py`):** `get_actor()` passou a `async def`; `_get_actor_from_jwt` tenta primeiro decifrar como JWT local (compatibilidade), e se falhar delega em `erp_client.validate_bearer_token()` (novo método, `GET /api/auth/gateway/validate` com o próprio Bearer token do utilizador, não API Key de device) — cache em memória 60s por hash do token.
- **FaceClock (`app/routers/auth.py`):** esvaziado — `POST /auth/login`/`POST /auth/refresh` removidos, assim como `_authenticate_with_erp`/`_authenticate_local`/`create_access_token`/`create_refresh_token` e `erp_client.authenticate_user()` (todos dead code depois da remoção). Testes: `TestErpJwtDelegation` substitui `TestProductionLoginFallback` (que testava exactamente o mecanismo removido).
- **Android:** `ErpApiService.login()` novo (`POST api/auth/login`, contrato `email`+`password`, diferente do antigo `username`+`password` do FaceClock); `LoginActivity` chama-o directamente; `RoleUtils.fromErpLogin(tipo, modulos)` deriva o mesmo role que `gatewayAppRole()` no Go, a partir de `modulos`/`acoes` devolvidos no login. Modelos/endpoints mortos do FaceClock removidos (`LoginRequest`, `LoginResponse`, `AuthenticatedUser`, `RefreshTokenRequest`/`Response`, `AssiduidadeApiService.login()`/`refreshToken()`).
- Verificado: suite pytest do FaceClock (47/47), suite Go (`go test ./...`, sem falhas), build Kotlin (`compileDebugKotlin`, sucesso).

## 8.5 Ecrãs de gestor (Android) — preparação (2026-07-12)

Antes de implementar os 12 ecrãs `ui/gestor/*` (até agora placeholders), corrigido/preparado o terreno:

- **`ErpApiService.kt` corrigido:** vários métodos apontavam para rotas especulativas nunca implementadas no ERP (`employees`, `dashboard/summary`, `alerts`, `devices` sem prefixo, `reports/attendance`, `agenda*`, `departments`, `notifications`). Substituídos por rotas reais: `getFuncionarios`/`getFuncionarioDetalhe` (`/api/rh/funcionarios[/{id}]`), `getAusencias`/`aprovarAusencia`/`rejeitarAusencia` (`/api/rh/ausencias`), `getDispositivos` (`/api/hardware/devices`), `getPresencasPorTipo` (novo, ver abaixo). 16 ficheiros de modelo mortos removidos (`Employee`, `Device`, `DashboardSummary`, `Alert`, `VacationModels`, `ReportModels`, etc.), substituídos por modelos com os nomes de campo exactos que o Go devolve (`Funcionario`, `FuncionarioDetalhe`, `Ausencia`, `DispositivoErp`, `PresencaOcorrencia`).
- **Novo endpoint ERP `GET /api/rh/presencas`** (`ListarPresencasPorTipo`, `recursos-humanos/handlers/presencas.go`), permissão `recursos-humanos.ver_funcionarios`: lista presenças **cross-equipa** filtradas por `tipo` (atraso/falta/presente/saida_antecipada), `data_inicio`/`data_fim`, `unit_id` — faltava (só existia `GET /api/rh/funcionarios/{id}/presencas`, por funcionário, sem coluna `tipo`). Alimenta o ecrã "Ocorrências/Alertas". Testado manualmente contra a BD local real (672 linhas totais do tenant 5, 96 com `tipo IN (atraso,falta)`, 0 linhas vazadas de outro tenant); dados de teste não deixados (é só leitura).
- **Bug de segurança corrigido em `POST /clock/register`** (FaceClock): não havia nenhuma verificação de que `actor.id == payload.user_id` — qualquer `COLABORADOR` autenticado conseguia marcar ponto em nome de **qualquer outro** utilizador só por conhecer o seu `user_id`. Corrigido em `_create_clock_record` (`app/routers/clock.py`): registar por conta de outro utilizador agora exige `ADMIN_SISTEMA`/`GESTOR_RH`; auto-registo continua livre para qualquer role. Necessário antes de expor `RegistoManualFragment` (gestor regista ponto de um funcionário). Testes: `TestClockRegisterOnBehalfOf` (colaborador bloqueado, colaborador continua a registar-se a si próprio, admin consegue registar por outrem).
- Verificado: suite pytest do FaceClock (50/50), build Go limpo.

## 10. O que este contrato NÃO cobre ainda

- Fila persistente com backoff real do FaceClock para o ERP — o reenvio em lote (secção 8.2) reduz o número de chamadas HTTP, mas continua a ser best-effort sob pedido manual, sem agendamento automático nem tentativas com espaçamento crescente.
- Mapeamento fino de `AUDITOR` — `GESTOR_RH` já é derivado de permissões RBAC reais (`gatewayAppRole`, secção 8.4); `AUDITOR` continua sem critério equivalente definido no ERP.
- Remoção completa das tabelas/modelos não biométricos do FaceClock (Fase 5.2) — `users`, `tenants`, `units`, `devices`, `clock_records`, `adjustment_requests`, `audit_logs`, `consents`, `integration_batches`.
- Novos endpoints no ERP para histórico de ponto, pedidos de correção e consentimentos LGPD (Fase 6).
- Labels Traefik / DNS público para o FaceClock — decisão de infraestrutura em aberto (secção 5).
- **Quem gera e distribui o valor de `GATEWAY_SHARED_SECRET`/`JWT_SECRET_KEY` de produção** — isto é responsabilidade de quem faz o deploy (secret manager ou `.env` fora do controlo de versão), não foi gerado nem escolhido por esta implementação.
- Nenhum código no `backend/` (Go) chama ainda o FaceClock — o segredo partilhado só protege o lado FaceClock; falta decidir e implementar quem, no ERP ou no gateway, efectivamente envia `X-Gateway-Secret` nos pedidos reencaminhados.
- Registo real do FaceClock como `hardware.devices` em produção (API Key gerada, mapeamento `hardware.device_users` por funcionário) — só foi feito com dados de teste, removidos no fim de cada sessão.
- Teste E2E automatizado cross-serviço (8.6) — bloqueado pela mesma decisão de rede/gateway.
