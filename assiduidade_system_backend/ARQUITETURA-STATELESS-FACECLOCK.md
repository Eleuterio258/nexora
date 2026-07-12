# Decisão Arquitetural — FaceClock Stateless

**Data:** 2026-07-12  
**Escopo:** `assiduidade_system_backend` (FaceClock, Python/FastAPI) ↔ `backend` (Nexora ERP, Go)

---

## 1. Princípio fundamental

> **Nenhum dado persiste no FaceClock.**

O FaceClock passa a ser um **gateway stateless** de captura e validação biométrica de assiduidade. Toda a persistência é delegada ao Nexora ERP.

---

## 2. Única excepção

| Dado | Onde fica | Porquê |
|---|---|---|
| Templates faciais (`face_templates`) | FaceClock (Python) | Dados biométricos sensíveis; matching local precisa de latência baixa. |
| Templates digitais (`fingerprint_templates`) | FaceClock (Python) | Idem. |

**Requisitos para os templates biométricos:**
- Cifrados em repouso (AES-256 ou equivalente).
- Ligados ao funcionário apenas por `erp_funcionario_id`.
- Removidos imediatamente quando o consentimento é revogado ou o funcionário desactivado no ERP.
- **Não replicados para o ERP.** O Nexora ERP não armazena templates biométricos.

---

## 3. O que vai para o ERP

| Dados | Entidade/endpoint ERP |
|---|---|
| Auth (login, refresh, PIN, TOTP) | `auth.users`, `/api/auth/*`, `/api/authcode/*` |
| Funcionários | `rh.funcionarios` |
| Unidades/empresas | `rh.unidades_organizacionais`, `empresas.companies` |
| Dispositivos/totems | `hardware.devices` |
| Registos de ponto (eventos brutos) | `hardware.device_events` |
| Presenças consolidadas | `rh.presencas` |
| Pedidos de correção de ponto | `rh.pedidos_correcao_ponto` (a criar) |
| Consentimentos LGPD | `lgpd.consents` (a criar) |
| Auditoria | `auditoria.audit_logs` |
| Configuração de métodos | `sistema_configuracao.tenant_feature_flags` (`rh.assiduidade`) |
| Relatórios/exportação | Módulos de RH/relatórios do ERP |

---

## 4. O que o FaceClock pode manter em memória

O FaceClock pode usar **cache em memória** com TTL curto (máx. 60s):

- Configuração de métodos de assiduidade (`rh.assiduidade`).
- Lista de funcionários do tenant (apenas para lookup de matching).
- Tokens JWT de curta duração.

**Não pode haver tabelas espelho persistentes.** Quando o serviço reinicia, o cache é reconstruído a partir do ERP.

---

## 5. Fluxo de um registo de ponto

1. Utilizador autentica-se no **Nexora ERP** e recebe token ERP.
2. App/Totem chama gateway com token ERP.
3. Gateway valida token no ERP (`GET /api/auth/gateway/validate`) e adiciona headers `X-Auth-*` + `X-Gateway-Secret`.
4. FaceClock valida o segredo do gateway e extrai o actor.
5. FaceClock valida biometria localmente (se aplicável) e/ou NFC / QR / geolocalização / PIN / TOTP.
6. FaceClock **não grava** o registo localmente; envia o evento imediatamente para o ERP via `POST /api/hardware/events/generic` (ou batch).
7. ERP persiste em `hardware.device_events` e consolida em `rh.presencas`.
8. FaceClock devolve ao App/Totem o resultado do ERP.

---

## 6. Endpoints do FaceClock — classificação

### 🟢 Mantidos no FaceClock (biometria)
- `POST /api/v1/biometric/enroll`
- `POST /api/v1/biometric/verify`
- `POST /api/v1/fingerprint/enroll`
- `POST /api/v1/fingerprint/identify`
- `DELETE /api/v1/fingerprint/enroll/{user_id}`

### 🟡 Proxy para o ERP
- `POST /api/v1/auth/login`
- `POST /api/v1/auth/refresh`
- `POST /api/v1/authcode/pin/validate`
- `POST /api/v1/authcode/totp/setup`
- `POST /api/v1/authcode/totp/validate`
- `POST /api/v1/authcode/admin/set-pin`
- `POST /api/v1/clock/register`
- `POST /api/v1/clock/register/batch`
- `GET /api/v1/clock/me`
- `POST /api/v1/clock/adjustments`
- `GET /api/v1/clock/adjustments/me`
- `DELETE /api/v1/clock/adjustments/{adjustment_id}`
- `POST /api/v1/consents`
- `GET /api/v1/consents/users/{user_id}/active`
- `GET /api/v1/consents/users/{user_id}/history`
- `POST /api/v1/consents/users/{user_id}/revoke`
- `GET /api/v1/audit/logs`
- `GET /api/v1/tenant/attendance-config`

### 🔴 A remover / obsoleto
- `POST /api/v1/clock/sync`
- `POST /api/v1/clock/erp/retry-failed`
- `POST /api/v1/sync/employees`
- `POST /api/v1/sync/employees/{employee_id}`
- Routers administrativos: `admin.py`, `users.py`, `units.py`, `devices.py`, `reports.py`, `integrations.py`

---

## 7. Tabelas/modelos a remover do FaceClock

- `User`
- `Tenant`
- `Unit`
- `Device`
- `ClockRecord`
- `AdjustmentRequest`
- `AuditLog`
- `Consent`
- `IntegrationBatch`

**Manter:**
- `FaceTemplate`
- `FingerprintTemplate`

---

## 8. Novos endpoints necessários no ERP (Fase 6)

| Funcionalidade | Endpoint ERP proposto |
|---|---|
| Histórico de ponto do utilizador | `GET /api/self-service/assiduidade/historico` |
| Pedidos de correção de ponto | `POST/GET /api/rh/assiduidade/correcoes` |
| Consentimentos LGPD | `POST/GET /api/lgpd/consents` |
| Auditoria (já existe) | `GET /api/audit-logs/`, `POST /api/audit-logs/` |

---

## 9. Checklist de implementação

- [ ] Remover routers administrativos duplicados do FaceClock.
- [ ] Remover modelos/tabelas não biométricos do FaceClock.
- [ ] Refazer `clock/register` para enviar evento diretamente ao ERP sem gravar localmente.
- [ ] Remover `/clock/sync` local.
- [ ] Substituir `sync.py` por consultas sob demanda ao ERP com cache em memória.
- [ ] Criar endpoints ERP para histórico de ponto, correções e consentimentos.
- [ ] Transformar endpoints do FaceClock em proxy/cache para os novos endpoints ERP.
- [ ] Garantir criptografia em repouso dos templates biométricos.
- [ ] Atualizar testes automatizados.

---

## 10. Referências

- [`proposta-arquitetura-assiduidade-erp.md`](./proposta-arquitetura-assiduidade-erp.md)
- [`CONTRATO-INTEGRACAO-ERP.md`](./CONTRATO-INTEGRACAO-ERP.md)
- [`endpoints-nexora-erp-faceclock.md`](./endpoints-nexora-erp-faceclock.md)
- [`openapi.yaml`](./openapi.yaml)
