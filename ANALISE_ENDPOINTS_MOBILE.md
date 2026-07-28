# Análise de todos os endpoints chamados pela app `nexora_assiduidade`

Data: 2026-07-28

## Fontes

Toda a comunicação de rede da app está declarada em duas interfaces Retrofit — não há chamadas de rede fora delas:

- `data/network/ErpApiService.kt` — 64 endpoints, todos contra o Nexora ERP (Go).
- `data/network/AssiduidadeApiService.kt` — 1 endpoint, contra o FaceClock (FastAPI).

Mais um WebSocket nativo (`data/network/ws/ChatWebSocketService.kt`, `ws/chat`), também contra o ERP.

`data/network/RetrofitClient.kt` mantém dois `Retrofit` distintos:

- `erpRetrofit` → `BuildConfig.ERP_BASE_URL`
- `assiduidadeRetrofit` → `BuildConfig.ASSIDUIDADE_BASE_URL`

Total: **65 endpoints REST + 1 WebSocket**. Na prática, a app é quase só um cliente do ERP — só 1 dos 65 endpoints REST ainda vai para o FaceClock.

---

## 1. Autenticação / sessão (ERP)

| Método | Endpoint | Auth | Propósito |
|---|---|---|---|
| POST | `oauth/token` (grant=password) | público | Login principal |
| POST | `oauth/token` (grant=refresh_token) | público | Renovação automática de sessão (`AuthAuthenticator`, chamada síncrona porque corre fora de coroutine, num callback OkHttp; o ERP roda o refresh_token a cada uso) |
| GET | `api/auth/me` | Bearer | Identidade pós-login (id/nome/email) |
| GET | `api/auth/me/acesso` | Bearer | Permissões RBAC em tempo real (`modulos`), chamado logo após login para corrigir um `modulos` desactualizado que o login em si pode devolver |
| POST | `api/authcode/pin/validate` | público | Login alternativo por PIN |
| POST | `api/authcode/totp/validate` | público | Login alternativo por TOTP |
| POST | `api/authcode/totp/setup` | Bearer | Configurar TOTP |
| POST | `api/authcode/admin/set-pin` | Bearer | Admin define PIN de outro utilizador |

## 2. Assiduidade — colaborador (self-service, ERP)

| Método | Endpoint | Auth | Propósito |
|---|---|---|---|
| GET | `api/self-service/assiduidade/` | Bearer | Histórico próprio de presenças |
| POST | `api/self-service/assiduidade/justificacoes` | Bearer | Criar justificação |
| GET | `api/self-service/assiduidade/justificacoes` | Bearer | Listar justificações próprias |
| GET | `api/self-service/assiduidade/qr/me` | Bearer | QR pessoal do colaborador |
| GET | `api/self-service/assiduidade/metodos` | Bearer (`assiduidade:ver_assiduidade`) | Métodos activos do tenant — usado por `HomeFuncionarioFragment` para esconder cards de métodos desactivados (adicionado em 2026-07-28) |

## 3. Assiduidade — marcação de ponto por device (`X-API-Key` embutida no APK)

| Método | Endpoint | Auth | Propósito |
|---|---|---|---|
| GET | `api/hardware/assiduidade/config` | X-API-Key | Config bruta do tenant do device |
| GET | `api/hardware/assiduidade/funcionarios` | X-API-Key | Resolver `employee_code` a partir do e-mail da sessão (`HardwareEventMapper.resolveEmployeeCode`) |
| POST | `api/hardware/events/generic` | X-API-Key | Registar o evento de ponto em si (facial/QR/NFC/PIN/manual/selfie) |
| POST | `api/hardware/assiduidade/qr/validar` | X-API-Key | Validar QR code lido |
| GET | `api/hardware/assiduidade/nfc/validar` | X-API-Key | Validar tag NFC |
| GET | `api/hardware/assiduidade/geofence/validar` | X-API-Key | Validar geolocalização contra o raio da unidade |

> ⚠️ **Risco aceite e já documentado no código** (`app/build.gradle.kts`): estes 6 endpoints usam uma `X-API-Key` de device **partilhada e embutida no APK** (`BuildConfig.DEVICE_API_KEY`), igual em todas as instalações. Qualquer descompilação do APK expõe uma credencial válida para gerar eventos de presença em nome de qualquer funcionário do tenant. Não é uma descoberta nova desta análise — está assumido explicitamente no repositório — mas continua activo e vale a pena ter presente.

## 4. Configuração de assiduidade (admin do tenant)

| Método | Endpoint | Auth | Propósito |
|---|---|---|---|
| GET | `api/system/configuracao/tenant/feature/rh.assiduidade` | Bearer (`sistema-configuracao:ver_configuracoes`) | Ecrã do gestor lê a configuração de métodos |
| PUT | `api/system/configuracao/tenant/feature/rh.assiduidade` | Bearer (`sistema-configuracao:editar_configuracoes`) | Ecrã do gestor grava a configuração de métodos |
| POST | `api/rh/assiduidade/qr/gerar` | Bearer (`recursos-humanos:ver_funcionarios`) | QR fixo do gestor |

## 5. Notificações / Agenda pessoal

| Método | Endpoint | Auth | Propósito |
|---|---|---|---|
| GET | `api/utilizadores/{userId}/notifications` | Bearer | Listar notificações |
| POST | `api/utilizadores/{userId}/notifications/{id}/read` | Bearer | Marcar uma como lida |
| POST | `api/utilizadores/{userId}/notifications/read-all` | Bearer | Marcar todas como lidas |
| GET | `api/utilizadores/{userId}/agenda` | Bearer | Agenda pessoal |
| POST | `api/utilizadores/{userId}/agenda` | Bearer | Criar item de agenda |

## 6. RH — gestão de equipa (gestor)

| Método | Endpoint | Auth | Propósito |
|---|---|---|---|
| GET | `api/rh/funcionarios` | Bearer | Listar equipa (paginado, filtros por unidade/estado/pesquisa) |
| GET | `api/rh/funcionarios/{id}` | Bearer | Detalhe de um funcionário |
| GET | `api/rh/funcionarios/{id}/eventos` | Bearer | Eventos de assiduidade (modelo novo) |
| GET | `api/rh/funcionarios/{id}/resultados` | Bearer | Resultados diários de assiduidade |
| POST | `api/rh/funcionarios/{id}/biometria/facial/enroll` | Bearer | Enrolamento facial — proxy do ERP para o FaceClock, após validar consentimento LGPD e config do tenant |
| GET | `api/rh/funcionarios/{id}/consentimento` | Bearer | Consultar consentimento LGPD biométrico |
| POST | `api/rh/funcionarios/{id}/consentimento` | Bearer | Registar consentimento LGPD |
| GET | `api/rh/ausencias` | Bearer | Listar pedidos de férias/ausências |
| POST | `api/rh/ausencias/{id}/aprovar` | Bearer | Aprovar pedido |
| POST | `api/rh/ausencias/{id}/rejeitar` | Bearer | Rejeitar pedido |
| GET | `api/hardware/devices` | Bearer | Listar dispositivos biométricos cadastrados |
| GET | `api/rh/presencas` | Bearer | Ocorrências/alertas cross-equipa por tipo (atraso/falta) |
| GET | `api/rh/relatorios` | Bearer | Relatórios agregados de RH |

## 7. CRM — Leads, Oportunidades, Atividades

21 endpoints CRUD completos, todos Bearer:

- **Leads**: `GET/POST api/crm/leads`, `GET/PUT/DELETE api/crm/leads/{id}`, `PUT .../estado`, `POST .../converter`.
- **Oportunidades**: `GET/POST api/crm/oportunidades`, `GET/PUT/DELETE api/crm/oportunidades/{id}`, `PUT .../estagio`, `POST .../perder`.
- **Atividades**: `GET/POST api/crm/atividades`, `GET/PUT/DELETE api/crm/atividades/{id}`, `POST .../concluir`.

Nota: a app de assiduidade expõe o módulo CRM inteiro do ERP — não é só uma app de marcação de ponto, é um cliente geral do ERP com ecrãs de gestor cobrindo também vendas.

## 8. Chat (self-service + WebSocket)

| Método | Endpoint | Auth | Propósito |
|---|---|---|---|
| GET | `api/self-service/chat/conversas` | Bearer | Listar conversas |
| POST | `api/self-service/chat/conversas` | Bearer | Criar conversa |
| GET | `api/self-service/chat/conversas/{id}/mensagens` | Bearer | Histórico de mensagens |
| POST | `api/self-service/chat/conversas/{id}/mensagens` | Bearer | Enviar mensagem |
| WS | `ws/chat` | — | Tempo real (`ChatWebSocketService`): fila de mensagens pendentes, reconexão com backoff exponencial (1s→30s), heartbeat |

## 9. FaceClock (único endpoint ainda chamado directamente)

| Método | Endpoint | Auth | Propósito |
|---|---|---|---|
| POST | `biometric/verify` | Bearer | Único uso restante do FaceClock (`AssiduidadeApiService`) — compara a captura contra o template guardado localmente no FaceClock, capacidade que o ERP não tem. Todo o resto (login, PIN/TOTP, assiduidade própria, QR/NFC/geofence, registo de ponto) migrou para chamadas directas ao ERP em 2026-07-13. |

---

## Observações gerais

1. **Três mecanismos de autenticação coexistem**: Bearer (OAuth2 RS256 do ERP, maioria dos endpoints), `X-API-Key` de device partilhada (6 endpoints de hardware — risco aceite, ver secção 3), e público sem auth (3 endpoints: `oauth/token` grant=password, `authcode/pin/validate`, `authcode/totp/validate` — correcto, são os próprios pontos de entrada de login).
2. **Dois backends, uso muito assimétrico**: dos 65 endpoints REST, 64 vão para o ERP e só 1 (`biometric/verify`) ainda vai para o FaceClock.
3. **Sem endpoints especulativos/mortos** — comentário no próprio `ErpApiService.kt` (linhas 82-86) documenta que rotas antigas nunca correspondentes a rotas reais do ERP foram removidas em 2026-07-12.
4. **Consistência de permissões**: os endpoints de gestor (RH, CRM, configuração) exigem sempre uma permissão RBAC específica no ERP, nunca apenas "estar autenticado" — com a excepção deliberada da secção 3 (device) e dos 3 endpoints públicos de login.
