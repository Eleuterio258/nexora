# Nexora ERP: o que faz cada endpoint da API

Gerado a partir de [`backend/internal/router/router.go`](backend/internal/router/router.go) em 2026-09-26: **1185 rotas**. O [`all_endpoints.txt`](all_endpoints.txt), de 2026-08-01, lista 1071 e já está desactualizado.

## Como ler as tabelas

- **Rota**: os parâmetros vêm entre `{}`. Os IDs aparecem ofuscados (hash) nas URLs, através do middleware `idhash`.
- **Acesso**: o que é exigido além do CORS/log globais:
  - `modulo.acao` é uma permissão RBAC (`RequirePermission`), vinda do cargo ou atribuída directamente ao utilizador. "A ou B" significa que basta uma delas.
  - *feature `x`* indica que a funcionalidade tem de estar activa no plano do tenant (`RequireFeature`); se não estiver, a resposta é HTTP 402.
  - *autenticado* significa qualquer utilizador com login válido no tenant certo (`RequireAuth` + `EnforceTenantHost`).
  - **público** significa que não há login; normalmente estas rotas têm *rate limit*.
  - O superadmin passa por cima de features e licenças.
- Todas as rotas de escrita dos módulos ficam registadas na auditoria (`AuditModule`).

## Índice

- [Infraestrutura](#infraestrutura): 3
- [Autenticação e utilizadores (`/api/auth`)](#autenticação-e-utilizadores-apiauth): 37
- [Autenticação alternativa: PIN, 2FA e OAuth2](#autenticação-alternativa-pin-2fa-e-oauth2): 10
- [API v1 (integrações externas)](#api-v1-integrações-externas): 12
- [Perfil pessoal do utilizador (`/api/utilizadores`)](#perfil-pessoal-do-utilizador-apiutilizadores): 25
- [Empresa (`/api/companies`)](#empresa-apicompanies): 25
- [Pessoas (`/api/pessoas`)](#pessoas-apipessoas): 1
- [Auditoria (`/api/audit-logs`, `/api/audit-events`)](#auditoria-apiaudit-logs-apiaudit-events): 8
- [Configuração do sistema (`/api/system`)](#configuração-do-sistema-apisystem): 26
- [Segurança (`/api/seguranca`)](#segurança-apiseguranca): 7
- [Notificações (`/api/notificacoes`)](#notificações-apinotificacoes): 10
- [Clientes (`/api/clientes`)](#clientes-apiclientes): 41
- [CRM (`/api/crm`)](#crm-apicrm): 20
- [Produtos (`/api/produtos`)](#produtos-apiprodutos): 53
- [Stock (`/api/stock`)](#stock-apistock): 56
- [Compras (`/api/compras`)](#compras-apicompras): 19
- [Aprovações (`/api/aprovacoes`)](#aprovações-apiaprovacoes): 10
- [Facturação (`/api/faturacao`)](#facturação-apifaturacao): 38
- [Ponto de venda (`/api/pos`)](#ponto-de-venda-apipos): 47
- [Financeiro (`/api/financeiro`)](#financeiro-apifinanceiro): 11
- [Tesouraria (`/api/tesouraria`)](#tesouraria-apitesouraria): 10
- [Multi-moeda (`/api/multi-moeda`)](#multi-moeda-apimulti-moeda): 8
- [Impostos (`/api/impostos`)](#impostos-apiimpostos): 18
- [Contabilidade (`/api/contabilidade`)](#contabilidade-apicontabilidade): 71
- [Centros de custo (`/api/centros-custo`)](#centros-de-custo-apicentros-custo): 13
- [Logística (`/api/delivery-*`, `/api/shipments`)](#logística-apidelivery--apishipments): 11
- [Subscrições (`/api/assinaturas`)](#subscrições-apiassinaturas): 9
- [Assinatura digital (`/api/assinatura-digital`, `/assinar`, `/verificar-assinatura`)](#assinatura-digital-apiassinatura-digital-assinar-verificar-assinatura): 26
- [Recursos Humanos (`/api/rh`)](#recursos-humanos-apirh): 163
- [Área do funcionário (`/api/self-service`)](#área-do-funcionário-apiself-service): 32
- [Pedidos de férias (`/api/pedido-ferias`)](#pedidos-de-férias-apipedido-ferias): 4
- [Recrutamento, área interna (`/api/recrutamento`)](#recrutamento-área-interna-apirecrutamento): 30
- [Recrutamento, área pública (`/api/public/recrutamento`, `/vagas`, `/candidaturas`)](#recrutamento-área-pública-apipublicrecrutamento-vagas-candidaturas): 32
- [Gestão escolar (`/api/escolar`)](#gestão-escolar-apiescolar): 166
- [Portal do aluno (`/api/portal/aluno`)](#portal-do-aluno-apiportalaluno): 22
- [Portal do professor (`/api/portal/professor`)](#portal-do-professor-apiportalprofessor): 16
- [Portal do encarregado (`/api/portal/encarregado`)](#portal-do-encarregado-apiportalencarregado): 8
- [Tarefas (`/api/tarefas`)](#tarefas-apitarefas): 16
- [Hardware e dispositivos (`/api/hardware`)](#hardware-e-dispositivos-apihardware): 32
- [Superadmin (`/api/superadmin`)](#superadmin-apisuperadmin): 38
- [Notas e inconsistências encontradas](#notas-e-inconsistências-encontradas)

## Infraestrutura

Rotas técnicas: verificação de vida e canais de tempo real.

| Método | Rota | O que faz | Acesso |
|---|---|---|---|
| GET | `/health` | Verificação de vida da API (devolve `{"status":"ok"}`), usada pelo balanceador/Docker. | **público** |
| GET | `/ws/chat` | Abre o WebSocket do chat interno (token JWT na ligação). | **público** |
| * | `/socket.io/*` | Servidor Socket.IO do recrutamento: mensagens e notificações em tempo real entre RH e candidatos. | **público** |

## Autenticação e utilizadores (`/api/auth`)

Login, tokens, recuperação de senha e gestão de utilizadores, cargos (perfis de permissões) e sessões do tenant.

| Método | Rota | O que faz | Acesso |
|---|---|---|---|
| POST | `/api/auth/login` | Login com email/senha; devolve access + refresh token (ou pede 2FA). | **público** |
| POST | `/api/auth/refresh` | Troca o refresh token por um novo access token. | **público** |
| POST | `/api/auth/forgot-password` | Pede recuperação de senha (envia email com link). | **público** |
| POST | `/api/auth/reset-password` | Define nova senha usando o token recebido por email. | **público** |
| POST | `/api/auth/verify-email` | Confirma o endereço de email a partir do link de verificação. | **público** |
| GET | `/api/auth/me` | Dados do utilizador autenticado (perfil, tenant, cargo). | autenticado |
| GET | `/api/auth/me/acesso` | Permissões e features efectivas do utilizador — usado pelo frontend para montar menus. | autenticado |
| POST | `/api/auth/papel` | Muda o papel activo da sessão (ex.: funcionário ↔ professor ↔ encarregado) e emite novo token. | autenticado |
| GET | `/api/auth/me/perm-ts` | Timestamp da última alteração de permissões — o frontend usa-o para saber quando recarregar o acesso. | autenticado |
| POST | `/api/auth/logout` | Termina a sessão actual (revoga o refresh token). | autenticado |
| POST | `/api/auth/change-password` | O próprio utilizador altera a senha. | autenticado |
| POST | `/api/auth/push-token` | Regista o token FCM do dispositivo para receber notificações push. | autenticado |
| POST | `/api/auth/reauth` | Reconfirma a senha para obter uma autenticação "recente" (exigida em operações críticas, ex.: superadmin). | autenticado |
| GET | `/api/auth/utilizadores` | Lista os utilizadores do tenant. | `autorizacao.gerir_utilizadores` |
| POST | `/api/auth/utilizadores` | Cria um utilizador (conta de acesso) no tenant. | `autorizacao.gerir_utilizadores` |
| GET | `/api/auth/utilizadores/{id}` | Detalhe de utilizador. | `autorizacao.gerir_utilizadores` |
| PUT | `/api/auth/utilizadores/{id}` | Actualiza utilizador. | `autorizacao.gerir_utilizadores` |
| POST | `/api/auth/utilizadores/{id}/activar` | Reactiva uma conta desactivada. | `autorizacao.gerir_utilizadores` |
| POST | `/api/auth/utilizadores/{id}/bloquear` | Bloqueia a conta (impede login). | `autorizacao.gerir_utilizadores` |
| POST | `/api/auth/utilizadores/{id}/desactivar` | Desactiva a conta. | `autorizacao.gerir_utilizadores` |
| PUT | `/api/auth/utilizadores/{id}/cargo` | Atribui um cargo (perfil de permissões) ao utilizador. | `autorizacao.gerir_utilizadores` |
| PUT | `/api/auth/utilizadores/{id}/tipo` | Muda o tipo de utilizador (ex.: admin, funcionário). | `autorizacao.gerir_utilizadores` |
| POST | `/api/auth/utilizadores/{id}/reset-password` | Administrador repõe a senha de um utilizador. | `autorizacao.gerir_utilizadores` |
| GET | `/api/auth/utilizadores/{id}/permissoes` | Permissões atribuídas directamente ao utilizador (além das do cargo). | `autorizacao.gerir_utilizadores` |
| PUT | `/api/auth/utilizadores/{id}/permissoes` | Substitui as permissões directas do utilizador. | `autorizacao.gerir_utilizadores` |
| GET | `/api/auth/historico-login` | Histórico de logins (sucessos/falhas, IP, data). | `autorizacao.gerir_utilizadores` |
| GET | `/api/auth/cargos` | Lista os cargos (perfis de permissões) do tenant. | `autorizacao.gerir_perfis` |
| POST | `/api/auth/cargos` | Cria um cargo. | `autorizacao.gerir_perfis` |
| GET | `/api/auth/cargos/{id}` | Detalhe de cargo. | `autorizacao.gerir_perfis` |
| PUT | `/api/auth/cargos/{id}` | Actualiza cargo. | `autorizacao.gerir_perfis` |
| POST | `/api/auth/cargos/{id}/activar` | Activa cargo. | `autorizacao.gerir_perfis` |
| POST | `/api/auth/cargos/{id}/desactivar` | Desactiva cargo. | `autorizacao.gerir_perfis` |
| GET | `/api/auth/cargos/{id}/permissoes` | Permissões associadas a um cargo. | `autorizacao.gerir_perfis` |
| PUT | `/api/auth/cargos/{id}/permissoes` | Substitui as permissões de um cargo. | `autorizacao.gerir_perfis` |
| GET | `/api/auth/sessoes` | Lista as sessões activas (dispositivos com sessão aberta). | `autorizacao.gerir_utilizadores` ou `auth.ver_sessoes` |
| POST | `/api/auth/sessoes/{id}/revogar` | Termina uma sessão específica. | `autorizacao.gerir_utilizadores` ou `auth.ver_sessoes` |
| POST | `/api/auth/sessoes/revogar-todas` | Termina todas as sessões (logout global). | `autorizacao.gerir_utilizadores` ou `auth.ver_sessoes` |

## Autenticação alternativa: PIN, 2FA e OAuth2

Login por PIN, 2FA com TOTP e o servidor OAuth2 próprio (para apps de terceiros e integrações).

| Método | Rota | O que faz | Acesso |
|---|---|---|---|
| POST | `/api/authcode/pin/validate` | Login rápido com PIN numérico (ex.: terminais de ponto/POS); devolve tokens. | **público** |
| POST | `/api/authcode/totp/validate` | Segundo passo do login quando o utilizador tem 2FA: valida o código TOTP e emite os tokens. | **público** |
| POST | `/api/authcode/totp/setup` | Inicia a activação do 2FA: gera o segredo TOTP e o QR para a app autenticadora. | autenticado |
| POST | `/api/authcode/pin/verify` | Confirma o PIN do utilizador já autenticado (ex.: antes de uma acção sensível). | autenticado |
| POST | `/api/authcode/totp/verify` | Confirma um código TOTP do utilizador autenticado (termina o setup do 2FA). | autenticado |
| POST | `/api/authcode/admin/set-pin` | Administrador define/repõe o PIN de outro utilizador. | `auth.pin_admin` |
| POST | `/oauth/token` | Endpoint de token OAuth2 (troca de código/refresh/client credentials por access token). | **público** |
| GET | `/oauth/authorize` | Endpoint de autorização OAuth2 (consentimento e emissão do código para apps terceiras). | **público** |
| POST | `/oauth/authorize` | Endpoint de autorização OAuth2 (consentimento e emissão do código para apps terceiras). | **público** |
| GET | `/oauth/jwks` | Chaves públicas (JWKS) para validar os tokens OAuth emitidos pelo Nexora. | **público** |

## API v1 (integrações externas)

Endpoints num formato estável para integrações externas (compatível com PayCore) e para leitores de impressão digital.

| Método | Rota | O que faz | Acesso |
|---|---|---|---|
| GET | `/api/v1/users` | API v1 (formato PayCore/integração externa): lista utilizadores. | `autorizacao.gerir_utilizadores` |
| POST | `/api/v1/users` | API v1: cria utilizador. | `autorizacao.gerir_utilizadores` |
| GET | `/api/v1/users/{id}` | API v1: detalhe de utilizador. | `autorizacao.gerir_utilizadores` |
| PUT | `/api/v1/users/{id}` | API v1: actualiza utilizador. | `autorizacao.gerir_utilizadores` |
| DELETE | `/api/v1/users/{id}` | API v1: remove utilizador. | `autorizacao.gerir_utilizadores` |
| GET | `/api/v1/transactions` | API v1: lista transacções de venda (POS). | `faturacao.ver_documentos` |
| GET | `/api/v1/transactions/{id}` | API v1: detalhe de uma transacção. | `faturacao.ver_documentos` |
| POST | `/api/v1/transactions/{id}/cancel` | API v1: cancela uma transacção. | `faturacao.cancelar_documentos` |
| POST | `/api/v1/transactions/{id}/reverse` | API v1: estorna (reembolsa) uma transacção. | `faturacao.cancelar_documentos` |
| POST | `/api/v1/fingerprint/enroll` | Regista impressão digital (API v1). | `hardware.gerir_dispositivos` |
| POST | `/api/v1/fingerprint/identify` | Identifica por impressão digital (API v1). | `hardware.ver_dispositivos` |
| DELETE | `/api/v1/fingerprint/enroll/{user_id}` | Apaga impressão digital (API v1). | `hardware.gerir_dispositivos` |

## Perfil pessoal do utilizador (`/api/utilizadores`)

Dados pessoais, preferências, notificações, agenda, dispositivos e tokens de cada utilizador.

| Método | Rota | O que faz | Acesso |
|---|---|---|---|
| GET | `/api/utilizadores/perfis/{userId}` | Perfil pessoal alargado do utilizador (dados pessoais, contactos). | `perfil.ver_perfil` |
| POST | `/api/utilizadores/perfis` | Cria o perfil pessoal do utilizador. | `perfil.editar_perfil` |
| PUT | `/api/utilizadores/perfis/{userId}` | Actualiza o perfil pessoal. | `perfil.editar_perfil` |
| GET | `/api/utilizadores/{userId}/preferences` | Preferências do utilizador (idioma, tema, etc.). | `perfil.ver_perfil` |
| POST | `/api/utilizadores/{userId}/preferences` | Grava uma preferência. | `perfil.editar_perfil` |
| GET | `/api/utilizadores/{userId}/settings` | Definições da conta do utilizador. | `perfil.ver_perfil` |
| POST | `/api/utilizadores/{userId}/settings` | Grava uma definição da conta. | `perfil.editar_perfil` |
| GET | `/api/utilizadores/{userId}/notifications` | Notificações recebidas pelo utilizador. | `perfil.ver_perfil` |
| POST | `/api/utilizadores/{userId}/notifications` | Cria uma notificação para o utilizador. | `perfil.editar_perfil` |
| POST | `/api/utilizadores/{userId}/notifications/{notificationId}/read` | Marca uma notificação como lida. | `perfil.editar_perfil` |
| POST | `/api/utilizadores/{userId}/notifications/read-all` | Marca todas as notificações como lidas. | `perfil.editar_perfil` |
| GET | `/api/utilizadores/{userId}/agenda` | Itens da agenda pessoal. | `perfil.ver_perfil` |
| POST | `/api/utilizadores/{userId}/agenda` | Adiciona um item à agenda pessoal. | `perfil.editar_perfil` |
| GET | `/api/utilizadores/{userId}/devices` | Dispositivos registados na conta. | `perfil.ver_perfil` |
| POST | `/api/utilizadores/{userId}/devices` | Regista um dispositivo na conta. | `perfil.editar_perfil` |
| DELETE | `/api/utilizadores/{userId}/devices/{deviceId}` | Remove um dispositivo da conta. | `perfil.editar_perfil` |
| GET | `/api/utilizadores/{userId}/activity` | Registo de actividade do utilizador. | `perfil.ver_perfil` |
| POST | `/api/utilizadores/{userId}/activity` | Regista uma entrada de actividade. | `perfil.editar_perfil` |
| GET | `/api/utilizadores/{userId}/tokens` | Tokens de API pessoais do utilizador. | `perfil.ver_perfil` |
| POST | `/api/utilizadores/{userId}/tokens` | Cria um token de API pessoal. | `perfil.editar_perfil` |
| POST | `/api/utilizadores/{userId}/tokens/{tokenId}/revogar` | Revoga um token de API pessoal. | `perfil.editar_perfil` |
| GET | `/api/utilizadores/{userId}/security-logs` | Eventos de segurança da conta (mudança de senha, 2FA, bloqueios). | `perfil.ver_perfil` |
| GET | `/api/utilizadores/{userId}/avatar` | Devolve a foto de perfil. | `perfil.ver_perfil` |
| POST | `/api/utilizadores/{userId}/avatar` | Carrega a foto de perfil. | `perfil.editar_perfil` |
| DELETE | `/api/utilizadores/{userId}/avatar` | Remove a foto de perfil. | `perfil.editar_perfil` |

## Empresa (`/api/companies`)

Dados da empresa do tenant: dados fiscais, filiais, bancos, contactos e licenças.

| Método | Rota | O que faz | Acesso |
|---|---|---|---|
| POST | `/api/companies` | Cria uma empresa (só superadmin). | superadmin |
| GET | `/api/companies` | Lista as empresas visíveis ao tenant. | `empresa.ver_empresa` |
| GET | `/api/companies/{id}` | Dados da empresa (NUIT, nome, morada…). | `empresa.ver_empresa` |
| GET | `/api/companies/{id}/settings` | Definições da empresa. | `empresa.ver_empresa` |
| GET | `/api/companies/{id}/branches` | Filiais/sucursais da empresa. | `empresa.ver_empresa` |
| GET | `/api/companies/{id}/branches/{branchId}` | Detalhe de uma filial. | `empresa.ver_empresa` |
| GET | `/api/companies/{id}/tax-info` | Dados fiscais da empresa (NUIT, regime de IVA). | `empresa.ver_empresa` |
| GET | `/api/companies/{id}/banks` | Contas bancárias da empresa (para documentos). | `empresa.ver_empresa` |
| GET | `/api/companies/{id}/contacts` | Contactos da empresa. | `empresa.ver_empresa` |
| GET | `/api/companies/{id}/addresses` | Moradas da empresa. | `empresa.ver_empresa` |
| GET | `/api/companies/{id}/licenses` | Licenças de aplicação da empresa (validade, estado). | `empresa.ver_empresa` |
| GET | `/api/companies/{id}/users` | Utilizadores associados à empresa. | `empresa.ver_empresa` |
| PUT | `/api/companies/{id}` | Actualiza os dados da empresa. | `empresa.editar_empresa` |
| POST | `/api/companies/{id}/settings` | Grava uma definição da empresa. | `empresa.editar_empresa` |
| POST | `/api/companies/{id}/tax-info` | Grava os dados fiscais da empresa. | `empresa.editar_empresa` |
| PUT | `/api/companies/{id}/tax-info` | Grava os dados fiscais da empresa. | `empresa.editar_empresa` |
| POST | `/api/companies/{id}/banks` | Adiciona conta bancária da empresa. | `empresa.editar_empresa` |
| POST | `/api/companies/{id}/contacts` | Adiciona contacto da empresa. | `empresa.editar_empresa` |
| POST | `/api/companies/{id}/addresses` | Adiciona morada da empresa. | `empresa.editar_empresa` |
| POST | `/api/companies/{id}/branches` | Cria uma filial. | `empresa.gerir_filiais` |
| PUT | `/api/companies/{id}/branches/{branchId}` | Actualiza uma filial. | `empresa.gerir_filiais` |
| POST | `/api/companies/{id}/licenses` | Regista uma licença de aplicação (controla `RequireLicencaAtiva`). | `empresa.gerir_licencas` |
| POST | `/api/companies/{id}/users` | Associa um utilizador à empresa. | `empresa.editar_empresa` |
| DELETE | `/api/companies/{id}/users/{userId}` | Desassocia um utilizador da empresa. | `empresa.editar_empresa` |
| POST | `/api/companies/documents/{id}/enviar-para-assinatura` | Envia um documento da empresa para o fluxo de assinatura digital. | `empresa.editar_empresa` |

## Pessoas (`/api/pessoas`)

Entidade central Pessoa, que liga os vários papéis de um indivíduo (funcionário, cliente, aluno…).

| Método | Rota | O que faz | Acesso |
|---|---|---|---|
| GET | `/api/pessoas/{id}/relacoes` | Todos os papéis de uma pessoa central (funcionário, cliente, aluno, encarregado…). | `autorizacao.gerir_utilizadores` |

## Auditoria (`/api/audit-logs`, `/api/audit-events`)

Rasto de auditoria. `audit-logs` é o log clássico e `audit-events` é a cadeia append-only com hashes, onde se consegue detectar adulteração.

| Método | Rota | O que faz | Acesso |
|---|---|---|---|
| GET | `/api/audit-logs` | Lista o log de auditoria (quem fez o quê, quando), com filtros. | `auditoria.ver_logs` |
| GET | `/api/audit-logs/export` | Exporta o log de auditoria em CSV. | `auditoria.ver_logs` |
| GET | `/api/audit-logs/{id}` | Detalhe de uma entrada de auditoria (antes/depois). | `auditoria.ver_logs` |
| POST | `/api/audit-logs` | Regista manualmente uma entrada de auditoria (ex.: acções feitas no frontend). | `auditoria.gerir_logs` |
| GET | `/api/audit-events` | Lista eventos de auditoria encadeados (append-only, à prova de adulteração). | `auditoria.ver_logs` |
| GET | `/api/audit-events/verificar-integridade` | Verifica a cadeia de hashes dos eventos de auditoria (detecta adulteração). | `auditoria.ver_logs` |
| GET | `/api/audit-events/export` | Exporta os eventos de auditoria em CSV. | `auditoria.ver_logs` |
| GET | `/api/audit-events/{id}` | Detalhe de um evento de auditoria. | `auditoria.ver_logs` |

## Configuração do sistema (`/api/system`)

Configurações do tenant: moedas, países, modelos de email/SMS, integrações, branding, documentos e assiduidade.

| Método | Rota | O que faz | Acesso |
|---|---|---|---|
| GET | `/api/system/settings` | Configurações gerais do tenant. | `sistema-configuracao.ver_configuracoes` |
| GET | `/api/system/currencies` | Moedas disponíveis no sistema. | `sistema-configuracao.ver_configuracoes` |
| GET | `/api/system/exchange-rates` | Taxas de câmbio registadas. | `sistema-configuracao.ver_configuracoes` |
| GET | `/api/system/countries` | Tabela de países. | `sistema-configuracao.ver_configuracoes` |
| GET | `/api/system/cities` | Tabela de cidades. | `sistema-configuracao.ver_configuracoes` |
| GET | `/api/system/languages` | Idiomas suportados. | `sistema-configuracao.ver_configuracoes` |
| GET | `/api/system/email-templates` | Modelos de email do tenant. | `sistema-configuracao.ver_configuracoes` |
| GET | `/api/system/sms-templates` | Modelos de SMS do tenant. | `sistema-configuracao.ver_configuracoes` |
| GET | `/api/system/logs` | Logs técnicos do sistema. | `sistema-configuracao.ver_configuracoes` |
| GET | `/api/system/integrations` | Integrações configuradas (gateways, APIs externas). | `sistema-configuracao.ver_configuracoes` |
| GET | `/api/system/api-logs` | Registo de chamadas à API. | `sistema-configuracao.ver_configuracoes` |
| GET | `/api/system/configuracao/tenant/feature/rh.assiduidade` | Configuração de assiduidade do tenant (métodos de marcação, geofence, tolerâncias). | `sistema-configuracao.ver_configuracoes` |
| GET | `/api/system/branding` | Identidade visual do tenant (logótipo, cores). | `sistema-configuracao.ver_configuracoes` |
| GET | `/api/system/document-settings` | Definições dos documentos impressos (cabeçalho, rodapé, textos legais). | `sistema-configuracao.ver_configuracoes` |
| POST | `/api/system/settings` | Grava uma configuração geral. | `sistema-configuracao.editar_configuracoes` |
| POST | `/api/system/currencies` | Adiciona uma moeda. | `sistema-configuracao.editar_configuracoes` |
| POST | `/api/system/exchange-rates` | Regista uma taxa de câmbio. | `sistema-configuracao.editar_configuracoes` |
| POST | `/api/system/countries` | Adiciona um país. | `sistema-configuracao.editar_configuracoes` |
| POST | `/api/system/cities` | Adiciona uma cidade. | `sistema-configuracao.editar_configuracoes` |
| POST | `/api/system/languages` | Adiciona um idioma. | `sistema-configuracao.editar_configuracoes` |
| PUT | `/api/system/configuracao/tenant/feature/rh.assiduidade` | Grava a configuração de assiduidade do tenant. | `sistema-configuracao.editar_configuracoes` |
| PUT | `/api/system/branding` | Grava a identidade visual. | `sistema-configuracao.editar_configuracoes` |
| PUT | `/api/system/document-settings` | Grava as definições dos documentos impressos. | `sistema-configuracao.editar_configuracoes` |
| POST | `/api/system/email-templates` | Cria modelo de email. | `sistema-configuracao.gerir_templates` |
| POST | `/api/system/sms-templates` | Cria modelo de SMS. | `sistema-configuracao.gerir_templates` |
| POST | `/api/system/integrations` | Regista uma integração externa. | `sistema-configuracao.gerir_templates` |

## Segurança (`/api/seguranca`)

Políticas de segurança, 2FA e lista de IPs autorizados do tenant.

| Método | Rota | O que faz | Acesso |
|---|---|---|---|
| GET | `/api/seguranca/mfa-enrollments` | Utilizadores com 2FA activo. | `seguranca.ver_seguranca` |
| GET | `/api/seguranca/politicas` | Políticas de segurança (senha, sessão, bloqueio). | `seguranca.ver_seguranca` |
| POST | `/api/seguranca/politicas` | Cria política. | `seguranca.gerir_politicas` |
| PUT | `/api/seguranca/politicas/{id}` | Actualiza política. | `seguranca.gerir_politicas` |
| GET | `/api/seguranca/ip-allowlist` | IPs autorizados a aceder ao tenant. | `seguranca.ver_seguranca` |
| POST | `/api/seguranca/ip-allowlist` | Autoriza IP. | `seguranca.gerir_allowlist` |
| DELETE | `/api/seguranca/ip-allowlist/{id}` | Remove IP autorizado. | `seguranca.gerir_allowlist` |

## Notificações (`/api/notificacoes`)

Canais, modelos e fila de envio de notificações (email, SMS, push).

| Método | Rota | O que faz | Acesso |
|---|---|---|---|
| GET | `/api/notificacoes/canais` | Canais de notificação (email, SMS, push). | `notificacoes.ver_notificacoes` |
| POST | `/api/notificacoes/canais` | Configura canal. | `notificacoes.gerir_notificacoes` |
| GET | `/api/notificacoes/templates` | Modelos de notificação. | `notificacoes.ver_notificacoes` |
| POST | `/api/notificacoes/templates` | Cria modelo. | `notificacoes.gerir_notificacoes` |
| PUT | `/api/notificacoes/templates/{id}` | Actualiza modelo. | `notificacoes.gerir_notificacoes` |
| GET | `/api/notificacoes/mensagens` | Mensagens enviadas/em fila (com estado). | `notificacoes.ver_notificacoes` |
| POST | `/api/notificacoes/mensagens` | Envia notificação (entra na fila). | `notificacoes.gerir_notificacoes` |
| POST | `/api/notificacoes/mensagens/{id}/reprocessar` | Volta a tentar enviar uma mensagem falhada. | `notificacoes.gerir_notificacoes` |
| POST | `/api/notificacoes/mensagens/reprocessar-falhas` | Volta a tentar todas as mensagens falhadas. | `notificacoes.gerir_notificacoes` |
| POST | `/api/notificacoes/broadcast` | Envia push para todos os utilizadores do tenant. | `notificacoes.gerir_notificacoes` |

## Clientes (`/api/clientes`)

Ficha de cliente, contactos, moradas, crédito, saldo, descontos e relatórios.

| Método | Rota | O que faz | Acesso |
|---|---|---|---|
| GET | `/api/clientes/grupos` | Grupos de clientes (segmentação, tabelas de preço). | `clientes.gerir_grupos` |
| POST | `/api/clientes/grupos` | Cria grupo de clientes. | `clientes.gerir_grupos` |
| GET | `/api/clientes/grupos/{id}` | Detalhe de um grupo de clientes. | `clientes.gerir_grupos` |
| PUT | `/api/clientes/grupos/{id}` | Actualiza grupo de clientes. | `clientes.gerir_grupos` |
| GET | `/api/clientes/tags` | Etiquetas disponíveis para clientes. | `clientes.gerir_grupos` |
| POST | `/api/clientes/tags` | Cria etiqueta de cliente. | `clientes.gerir_grupos` |
| GET | `/api/clientes/reports/{report:top-clientes\|saldos-devedores\|credito-utilizado\|sem-actividade}` | Relatórios de clientes: `top-clientes`, `saldos-devedores`, `credito-utilizado` ou `sem-actividade` (escolhido no caminho). | `clientes.ver_clientes` |
| GET | `/api/clientes` | Lista clientes (pesquisa, filtros, paginação). | `clientes.ver_clientes` |
| GET | `/api/clientes/{id}` | Ficha completa do cliente. | `clientes.ver_clientes` |
| GET | `/api/clientes/{id}/contactos` | Contactos do cliente. | `clientes.ver_clientes` |
| GET | `/api/clientes/{id}/enderecos` | Moradas do cliente. | `clientes.ver_clientes` |
| GET | `/api/clientes/{id}/documentos` | Documentos anexados ao cliente. | `clientes.ver_clientes` |
| GET | `/api/clientes/{id}/limite-credito` | Limite de crédito e crédito utilizado pelo cliente (duas rotas, mesmo handler). | `clientes.ver_clientes` |
| GET | `/api/clientes/{id}/credito` | Limite de crédito e crédito utilizado pelo cliente (duas rotas, mesmo handler). | `clientes.ver_clientes` |
| GET | `/api/clientes/{id}/saldo` | Saldo em dívida do cliente (conta-corrente). | `clientes.ver_clientes` |
| GET | `/api/clientes/{id}/pagamentos` | Pagamentos recebidos do cliente. | `clientes.ver_clientes` |
| GET | `/api/clientes/{id}/notas` | Notas internas sobre o cliente. | `clientes.ver_clientes` |
| GET | `/api/clientes/{id}/historico` | Histórico de alterações/interacções do cliente. | `clientes.ver_clientes` |
| GET | `/api/clientes/{id}/descontos` | Descontos específicos do cliente. | `clientes.ver_clientes` |
| POST | `/api/clientes` | Cria cliente. | `clientes.gerir_clientes` |
| PUT | `/api/clientes/{id}` | Actualiza a ficha do cliente. | `clientes.gerir_clientes` |
| POST | `/api/clientes/{id}/activar` | Reactiva cliente. | `clientes.gerir_clientes` |
| POST | `/api/clientes/{id}/bloquear` | Bloqueia cliente (impede novas vendas). | `clientes.gerir_clientes` |
| POST | `/api/clientes/{id}/desbloquear` | Desbloqueia cliente. | `clientes.gerir_clientes` |
| POST | `/api/clientes/{id}/contactos` | Adiciona contacto ao cliente. | `clientes.gerir_clientes` |
| PUT | `/api/clientes/{id}/contactos/{contactoId}` | Actualiza contacto do cliente. | `clientes.gerir_clientes` |
| POST | `/api/clientes/{id}/enderecos` | Adiciona morada ao cliente. | `clientes.gerir_clientes` |
| PUT | `/api/clientes/{id}/enderecos/{endId}` | Actualiza morada do cliente. | `clientes.gerir_clientes` |
| POST | `/api/clientes/{id}/documentos` | Anexa documento ao cliente. | `clientes.gerir_clientes` |
| POST | `/api/clientes/{id}/limite-credito` | Define o limite de crédito do cliente (duas rotas, mesmo handler). | `clientes.gerir_clientes` |
| PUT | `/api/clientes/{id}/credito` | Define o limite de crédito do cliente (duas rotas, mesmo handler). | `clientes.gerir_clientes` |
| POST | `/api/clientes/{id}/pagamentos` | Regista um pagamento do cliente (abate ao saldo). | `clientes.gerir_clientes` |
| POST | `/api/clientes/{id}/notas` | Adiciona nota interna ao cliente. | `clientes.gerir_clientes` |
| POST | `/api/clientes/{id}/tags` | Associa etiqueta ao cliente. | `clientes.gerir_clientes` |
| POST | `/api/clientes/{id}/descontos` | Cria desconto específico para o cliente. | `clientes.gerir_clientes` |
| PUT | `/api/clientes/{id}/descontos/{desc_id}` | Actualiza desconto do cliente. | `clientes.gerir_clientes` |
| DELETE | `/api/clientes/{id}/contactos/{contactoId}` | Remove contacto do cliente. | `clientes.eliminar_clientes` |
| DELETE | `/api/clientes/{id}/enderecos/{endId}` | Remove morada do cliente. | `clientes.eliminar_clientes` |
| DELETE | `/api/clientes/{id}/documentos/{doc_id}` | Remove documento do cliente. | `clientes.eliminar_clientes` |
| DELETE | `/api/clientes/{id}/tags/{tag_id}` | Retira etiqueta do cliente. | `clientes.eliminar_clientes` |
| DELETE | `/api/clientes/{id}/descontos/{desc_id}` | Remove desconto do cliente. | `clientes.eliminar_clientes` |

## CRM (`/api/crm`)

Leads, oportunidades (pipeline de vendas) e actividades comerciais. Depende das features `crm.*`.

| Método | Rota | O que faz | Acesso |
|---|---|---|---|
| GET | `/api/crm/leads` | Leads (potenciais clientes). | feature `crm.leads` · `crm.ver_leads` |
| GET | `/api/crm/leads/{id}` | Detalhe de lead. | feature `crm.leads` · `crm.ver_leads` |
| POST | `/api/crm/leads` | Cria lead. | feature `crm.leads` · `crm.gerir_leads` |
| PUT | `/api/crm/leads/{id}` | Actualiza lead. | feature `crm.leads` · `crm.gerir_leads` |
| PUT | `/api/crm/leads/{id}/estado` | Muda o estado do lead (novo → contactado → qualificado…). | feature `crm.leads` · `crm.mover_leads` |
| POST | `/api/crm/leads/{id}/converter` | Converte lead em cliente (e opcionalmente oportunidade). | feature `crm.leads` · `crm.converter_leads` |
| DELETE | `/api/crm/leads/{id}` | Remove lead. | feature `crm.leads` · `crm.eliminar_leads` |
| GET | `/api/crm/oportunidades` | Oportunidades de negócio (pipeline). | feature `crm.leads` · feature `crm.oportunidades` · `crm.ver_oportunidades` |
| GET | `/api/crm/oportunidades/{id}` | Detalhe de oportunidade. | feature `crm.leads` · feature `crm.oportunidades` · `crm.ver_oportunidades` |
| POST | `/api/crm/oportunidades` | Cria oportunidade. | feature `crm.leads` · feature `crm.oportunidades` · `crm.gerir_oportunidades` |
| PUT | `/api/crm/oportunidades/{id}` | Actualiza oportunidade. | feature `crm.leads` · feature `crm.oportunidades` · `crm.gerir_oportunidades` |
| PUT | `/api/crm/oportunidades/{id}/estagio` | Muda o estágio no pipeline. | feature `crm.leads` · feature `crm.oportunidades` · `crm.gerir_oportunidades` |
| POST | `/api/crm/oportunidades/{id}/perder` | Marca oportunidade como perdida (com motivo). | feature `crm.leads` · feature `crm.oportunidades` · `crm.gerir_oportunidades` |
| DELETE | `/api/crm/oportunidades/{id}` | Remove oportunidade. | feature `crm.leads` · feature `crm.oportunidades` · `crm.eliminar_oportunidades` |
| GET | `/api/crm/atividades` | Actividades comerciais (chamadas, reuniões, tarefas). | feature `crm.leads` · feature `crm.atividades` · `crm.ver_atividades` |
| GET | `/api/crm/atividades/{id}` | Detalhe de actividade. | feature `crm.leads` · feature `crm.atividades` · `crm.ver_atividades` |
| POST | `/api/crm/atividades` | Cria actividade. | feature `crm.leads` · feature `crm.atividades` · `crm.gerir_atividades` |
| PUT | `/api/crm/atividades/{id}` | Actualiza actividade. | feature `crm.leads` · feature `crm.atividades` · `crm.gerir_atividades` |
| POST | `/api/crm/atividades/{id}/concluir` | Marca actividade como concluída. | feature `crm.leads` · feature `crm.atividades` · `crm.gerir_atividades` |
| DELETE | `/api/crm/atividades/{id}` | Remove actividade. | feature `crm.leads` · feature `crm.atividades` · `crm.gerir_atividades` |

## Produtos (`/api/produtos`)

Catálogo: categorias, marcas, unidades, variantes, preços, códigos de barras, kits e relatórios.

| Método | Rota | O que faz | Acesso |
|---|---|---|---|
| GET | `/api/produtos/categorias` | Árvore de categorias de produtos. | `stock.gerir_categorias` |
| POST | `/api/produtos/categorias` | Cria categoria (pode ter categoria-mãe). | `stock.gerir_categorias` |
| GET | `/api/produtos/categorias/{id}` | Detalhe de categoria. | `stock.gerir_categorias` |
| PUT | `/api/produtos/categorias/{id}` | Actualiza categoria (incl. mudar de categoria-mãe). | `stock.gerir_categorias` |
| DELETE | `/api/produtos/categorias/{id}` | Remove categoria. | `stock.gerir_categorias` |
| GET | `/api/produtos/marcas` | Lista marcas. | `stock.gerir_categorias` |
| POST | `/api/produtos/marcas` | Cria marca. | `stock.gerir_categorias` |
| GET | `/api/produtos/marcas/{id}` | Detalhe de marca. | `stock.gerir_categorias` |
| PUT | `/api/produtos/marcas/{id}` | Actualiza marca. | `stock.gerir_categorias` |
| GET | `/api/produtos/unidades` | Unidades de medida (un, kg, cx…). | `stock.gerir_categorias` |
| POST | `/api/produtos/unidades` | Cria unidade de medida. | `stock.gerir_categorias` |
| PUT | `/api/produtos/unidades/{id}` | Actualiza unidade de medida. | `stock.gerir_categorias` |
| GET | `/api/produtos/atributos` | Atributos de variantes (cor, tamanho…). | `stock.gerir_categorias` |
| POST | `/api/produtos/atributos` | Cria atributo de variante. | `stock.gerir_categorias` |
| PUT | `/api/produtos/atributos/{id}` | Actualiza atributo de variante. | `stock.gerir_categorias` |
| GET | `/api/produtos/tags` | Etiquetas de produto. | `stock.gerir_categorias` |
| POST | `/api/produtos/tags` | Cria etiqueta de produto. | `stock.gerir_categorias` |
| GET | `/api/produtos/reports/mais-vendidos` | Relatório: produtos mais vendidos. | `stock.ver_stock` |
| GET | `/api/produtos/reports/sem-movimentos` | Relatório: produtos sem movimentos (parados). | `stock.ver_stock` |
| GET | `/api/produtos/reports/stock-critico` | Relatório: produtos abaixo do stock mínimo. | `stock.ver_stock` |
| GET | `/api/produtos/reports/margem` | Relatório: margem por produto (preço vs custo). | `stock.ver_stock` |
| GET | `/api/produtos` | Lista produtos (pesquisa, filtros). | `stock.ver_stock` |
| GET | `/api/produtos/{id}` | Ficha completa do produto (preços, variantes, stock). | `stock.ver_stock` |
| GET | `/api/produtos/{id}/variantes` | Variantes do produto. | `stock.ver_stock` |
| GET | `/api/produtos/{id}/imagens` | Imagens do produto. | `stock.ver_stock` |
| GET | `/api/produtos/{id}/precos` | Preços do produto (por lista/grupo/moeda). | `stock.ver_stock` |
| GET | `/api/produtos/{id}/descontos` | Descontos do produto. | `stock.ver_stock` |
| GET | `/api/produtos/{id}/codigos-barras` | Códigos de barras do produto. | `stock.ver_stock` |
| GET | `/api/produtos/{id}/componentes` | Componentes (produto composto/kit). | `stock.ver_stock` |
| GET | `/api/produtos/{id}/stock` | Stock actual do produto por armazém. | `stock.ver_stock` |
| GET | `/api/produtos/{id}/stock/alertas` | Alertas de stock do produto. | `stock.ver_stock` |
| POST | `/api/produtos` | Cria produto. | `stock.gerir_produtos` |
| PUT | `/api/produtos/{id}` | Actualiza produto. | `stock.gerir_produtos` |
| POST | `/api/produtos/{id}/activar` | Activa produto (volta a poder ser vendido). | `stock.gerir_produtos` |
| POST | `/api/produtos/{id}/desactivar` | Desactiva produto. | `stock.gerir_produtos` |
| POST | `/api/produtos/{id}/variantes` | Cria variante do produto. | `stock.gerir_produtos` |
| PUT | `/api/produtos/{id}/variantes/{var_id}` | Actualiza variante. | `stock.gerir_produtos` |
| POST | `/api/produtos/{id}/imagens` | Adiciona imagem. | `stock.gerir_produtos` |
| PUT | `/api/produtos/{id}/imagens/{img_id}` | Define a imagem principal do produto. | `stock.gerir_produtos` |
| POST | `/api/produtos/{id}/precos` | Define um preço do produto. | `stock.gerir_produtos` |
| PUT | `/api/produtos/{id}/precos/{preco_id}` | Actualiza preço. | `stock.gerir_produtos` |
| POST | `/api/produtos/{id}/descontos` | Cria desconto. | `stock.gerir_produtos` |
| PUT | `/api/produtos/{id}/descontos/{desc_id}` | Actualiza desconto. | `stock.gerir_produtos` |
| POST | `/api/produtos/{id}/codigos-barras` | Adiciona código de barras. | `stock.gerir_produtos` |
| POST | `/api/produtos/{id}/componentes` | Adiciona componente ao kit. | `stock.gerir_produtos` |
| PUT | `/api/produtos/{id}/componentes/{comp_id}` | Actualiza componente. | `stock.gerir_produtos` |
| POST | `/api/produtos/{id}/tags` | Associa etiqueta ao produto. | `stock.gerir_produtos` |
| DELETE | `/api/produtos/{id}/variantes/{var_id}` | Remove variante. | `stock.eliminar_produtos` |
| DELETE | `/api/produtos/{id}/imagens/{img_id}` | Remove imagem. | `stock.eliminar_produtos` |
| DELETE | `/api/produtos/{id}/descontos/{desc_id}` | Remove desconto. | `stock.eliminar_produtos` |
| DELETE | `/api/produtos/{id}/codigos-barras/{cb_id}` | Remove código de barras. | `stock.eliminar_produtos` |
| DELETE | `/api/produtos/{id}/componentes/{comp_id}` | Remove componente. | `stock.eliminar_produtos` |
| DELETE | `/api/produtos/{id}/tags/{tag_id}` | Retira etiqueta do produto. | `stock.eliminar_produtos` |

## Stock (`/api/stock`)

Armazéns, movimentos, ajustes, transferências, reservas, lotes, números de série, inventários e alertas.

| Método | Rota | O que faz | Acesso |
|---|---|---|---|
| GET | `/api/stock/warehouses` | Lista armazéns. | feature `stock` · `stock.ver_stock` |
| GET | `/api/stock/warehouses/{id}` | Detalhe de armazém. | feature `stock` · `stock.ver_stock` |
| GET | `/api/stock/warehouses/{id}/locations` | Localizações (corredor/prateleira) de um armazém. | feature `stock` · `stock.ver_stock` |
| GET | `/api/stock/items` | Quantidades em stock por produto/armazém. | feature `stock` · `stock.ver_stock` |
| GET | `/api/stock/items/{id}` | Detalhe de uma posição de stock. | feature `stock` · `stock.ver_stock` |
| GET | `/api/stock/movements` | Histórico de movimentos de stock (entradas/saídas). | feature `stock` · `stock.ver_stock` |
| GET | `/api/stock/movements/{id}` | Detalhe de movimento de stock. | feature `stock` · `stock.ver_stock` |
| GET | `/api/stock/adjustments` | Ajustes de inventário (correcções de quantidade). | feature `stock` · `stock.ver_stock` |
| GET | `/api/stock/adjustments/{id}` | Detalhe de ajuste. | feature `stock` · `stock.ver_stock` |
| GET | `/api/stock/transfers` | Transferências entre armazéns. | feature `stock` · `stock.ver_stock` |
| GET | `/api/stock/transfers/{id}` | Detalhe de transferência. | feature `stock` · `stock.ver_stock` |
| GET | `/api/stock/reservations` | Reservas de stock (quantidade prometida a encomendas). | feature `stock` · `stock.ver_stock` |
| GET | `/api/stock/reservations/{id}` | Detalhe de reserva. | feature `stock` · `stock.ver_stock` |
| GET | `/api/stock/batches/a-expirar` | Lotes perto da data de validade. | feature `stock` · `stock.ver_stock` |
| GET | `/api/stock/batches` | Lotes (com validade). | feature `stock` · `stock.ver_stock` |
| GET | `/api/stock/batches/{id}` | Detalhe de lote. | feature `stock` · `stock.ver_stock` |
| GET | `/api/stock/serials` | Números de série registados. | feature `stock` · `stock.ver_stock` |
| GET | `/api/stock/serials/{serial}` | Detalhe/rasto de um número de série. | feature `stock` · `stock.ver_stock` |
| GET | `/api/stock/counts` | Contagens de inventário físico. | feature `stock` · `stock.ver_stock` |
| GET | `/api/stock/counts/{id}` | Detalhe de contagem. | feature `stock` · `stock.ver_stock` |
| GET | `/api/stock/alerts` | Alertas de stock (mínimo, ruptura, validade). | feature `stock` · `stock.ver_stock` |
| GET | `/api/stock/reports/position` | Relatório: posição de stock actual. | feature `stock` · `stock.ver_stock` |
| GET | `/api/stock/reports/movements-summary` | Relatório: resumo de movimentos por período. | feature `stock` · `stock.ver_stock` |
| GET | `/api/stock/reports/low-stock` | Relatório: stock abaixo do mínimo. | feature `stock` · `stock.ver_stock` |
| GET | `/api/stock/reports/expiring-batches` | Relatório: lotes a expirar. | feature `stock` · `stock.ver_stock` |
| GET | `/api/stock/reports/count-divergences` | Relatório: divergências entre contagem e sistema. | feature `stock` · `stock.ver_stock` |
| GET | `/api/stock/reports/valuation` | Relatório: valor do stock (quantidade × custo). | feature `stock` · `stock.ver_stock` |
| POST | `/api/stock/warehouses` | Cria armazém. | feature `stock` · `stock.gerir_movimentos` |
| PUT | `/api/stock/warehouses/{id}` | Actualiza armazém. | feature `stock` · `stock.gerir_movimentos` |
| POST | `/api/stock/warehouses/{id}/activar` | Activa armazém. | feature `stock` · `stock.gerir_movimentos` |
| POST | `/api/stock/warehouses/{id}/desactivar` | Desactiva armazém. | feature `stock` · `stock.gerir_movimentos` |
| POST | `/api/stock/warehouses/{id}/locations` | Cria localização no armazém. | feature `stock` · `stock.gerir_movimentos` |
| PUT | `/api/stock/warehouses/{id}/locations/{loc_id}` | Actualiza localização. | feature `stock` · `stock.gerir_movimentos` |
| DELETE | `/api/stock/warehouses/{id}/locations/{loc_id}` | Remove localização (se vazia). | feature `stock` · `stock.gerir_movimentos` |
| POST | `/api/stock/items` | Cria a posição de stock inicial de um produto num armazém. | feature `stock` · `stock.gerir_movimentos` |
| PUT | `/api/stock/items/{id}/minimos` | Define stock mínimo/máximo (dispara alertas). | feature `stock` · `stock.gerir_movimentos` |
| POST | `/api/stock/movements` | Regista entrada/saída manual de stock. | feature `stock` · `stock.gerir_movimentos` |
| POST | `/api/stock/adjustments` | Cria ajuste de inventário. | feature `stock` · `stock.gerir_movimentos` |
| POST | `/api/stock/transfers` | Cria transferência entre armazéns. | feature `stock` · `stock.gerir_movimentos` |
| POST | `/api/stock/transfers/{id}/confirmar` | Confirma envio da transferência (sai do armazém de origem). | feature `stock` · `stock.gerir_movimentos` |
| POST | `/api/stock/transfers/{id}/receber` | Confirma recepção (entra no armazém de destino). | feature `stock` · `stock.gerir_movimentos` |
| POST | `/api/stock/transfers/{id}/cancelar` | Cancela transferência. | feature `stock` · `stock.gerir_movimentos` |
| POST | `/api/stock/reservations` | Reserva quantidade de stock. | feature `stock` · `stock.gerir_movimentos` |
| POST | `/api/stock/reservations/{id}/liberar` | Liberta a reserva (quantidade volta a estar disponível). | feature `stock` · `stock.gerir_movimentos` |
| POST | `/api/stock/reservations/{id}/consumir` | Consome a reserva (converte em saída efectiva). | feature `stock` · `stock.gerir_movimentos` |
| POST | `/api/stock/batches` | Cria lote. | feature `stock` · `stock.gerir_movimentos` |
| PUT | `/api/stock/batches/{id}` | Actualiza lote. | feature `stock` · `stock.gerir_movimentos` |
| POST | `/api/stock/serials` | Regista número de série. | feature `stock` · `stock.gerir_movimentos` |
| PUT | `/api/stock/serials/{id}/status` | Muda estado do número de série (vendido, avariado…). | feature `stock` · `stock.gerir_movimentos` |
| POST | `/api/stock/counts` | Abre contagem de inventário. | feature `stock` · `stock.gerir_movimentos` |
| POST | `/api/stock/counts/{id}/items` | Adiciona linha à contagem. | feature `stock` · `stock.gerir_movimentos` |
| PUT | `/api/stock/counts/{id}/items/{item_id}` | Actualiza a quantidade contada de uma linha. | feature `stock` · `stock.gerir_movimentos` |
| POST | `/api/stock/counts/{id}/fechar` | Fecha a contagem e gera os ajustes das divergências. | feature `stock` · `stock.gerir_movimentos` |
| POST | `/api/stock/counts/{id}/cancelar` | Cancela contagem. | feature `stock` · `stock.gerir_movimentos` |
| POST | `/api/stock/alerts/{id}/resolver` | Marca alerta como resolvido. | feature `stock` · `stock.gerir_movimentos` |
| POST | `/api/stock/alerts/{id}/ignorar` | Ignora alerta. | feature `stock` · `stock.gerir_movimentos` |

## Compras (`/api/compras`)

Ciclo de compra: requisição → ordem de compra → recepção → factura do fornecedor → pagamento, com devoluções.

| Método | Rota | O que faz | Acesso |
|---|---|---|---|
| GET | `/api/compras/purchase-requests` | Requisições internas de compra. | feature `compras` · `compras.ver_compras` |
| GET | `/api/compras/purchase-orders` | Ordens (notas de encomenda) a fornecedores. | feature `compras` · `compras.ver_compras` |
| GET | `/api/compras/purchase-receipts` | Recepções de mercadoria. | feature `compras` · `compras.ver_compras` |
| GET | `/api/compras/purchase-returns` | Devoluções a fornecedores. | feature `compras` · `compras.ver_compras` |
| GET | `/api/compras/purchase-invoices` | Facturas de fornecedores. | feature `compras` · `compras.ver_compras` |
| GET | `/api/compras/purchase-payments` | Pagamentos a fornecedores. | feature `compras` · `compras.ver_compras` |
| POST | `/api/compras/purchase-requests` | Cria requisição de compra (pode disparar fluxo de aprovação). | feature `compras` · `compras.criar_pedidos` |
| POST | `/api/compras/purchase-request-items` | Adiciona linha à requisição. | feature `compras` · `compras.criar_pedidos` |
| POST | `/api/compras/purchase-orders` | Cria ordem de compra. | feature `compras` · `compras.criar_pedidos` |
| POST | `/api/compras/purchase-order-items` | Adiciona linha à ordem de compra. | feature `compras` · `compras.criar_pedidos` |
| POST | `/api/compras/purchase-orders/{id}/enviar-para-assinatura` | Envia a ordem de compra para assinatura digital. | feature `compras` · `compras.aprovar_pedidos` |
| POST | `/api/compras/purchase-receipts` | Regista recepção de mercadoria (dá entrada no stock). | feature `compras` · `compras.receber_mercadoria` |
| POST | `/api/compras/purchase-receipt-items` | Adiciona linha à recepção. | feature `compras` · `compras.receber_mercadoria` |
| POST | `/api/compras/purchase-returns` | Cria devolução a fornecedor. | feature `compras` · `compras.gerir_devolucoes` |
| POST | `/api/compras/purchase-return-items` | Adiciona linha à devolução. | feature `compras` · `compras.gerir_devolucoes` |
| POST | `/api/compras/purchase-invoices` | Regista factura de fornecedor. | feature `compras` · `compras.faturar_compras` |
| POST | `/api/compras/purchase-invoice-items` | Adiciona linha à factura de fornecedor. | feature `compras` · `compras.faturar_compras` |
| POST | `/api/compras/purchase-payments` | Regista pagamento a fornecedor. | feature `compras` · `compras.gerir_pagamentos` |
| POST | `/api/compras/purchase-payment-items` | Associa o pagamento a facturas (linhas de liquidação). | feature `compras` · `compras.gerir_pagamentos` |

## Aprovações (`/api/aprovacoes`)

Motor genérico de aprovação multinível. Os `flows` definem as regras (feature, limiar de valor, níveis por cargo); os `requests` são os pedidos concretos criados por outros módulos (ex.: compras) através de `aprovacoes.NeedsApproval`/`CreateRequest`.

| Método | Rota | O que faz | Acesso |
|---|---|---|---|
| GET | `/api/aprovacoes/flows` | Lista fluxos de aprovação configurados (por feature, com níveis e limiar de valor). | `compras.aprovar_pedidos` · feature `compras.aprovacoes` |
| POST | `/api/aprovacoes/flows` | Cria fluxo de aprovação (ex.: requisições acima de X precisam de N níveis). | `compras.aprovar_pedidos` · feature `compras.aprovacoes` |
| GET | `/api/aprovacoes/flows/{id}` | Detalhe de um fluxo. | `compras.aprovar_pedidos` · feature `compras.aprovacoes` |
| PUT | `/api/aprovacoes/flows/{id}` | Actualiza um fluxo. | `compras.aprovar_pedidos` · feature `compras.aprovacoes` |
| DELETE | `/api/aprovacoes/flows/{id}` | Elimina um fluxo. | `compras.aprovar_pedidos` · feature `compras.aprovacoes` |
| GET | `/api/aprovacoes/requests` | Lista pedidos de aprovação (pendentes, aprovados, rejeitados). | autenticado |
| GET | `/api/aprovacoes/requests/pendentes-meu-cargo` | Pedidos à espera de decisão do cargo do utilizador (a sua caixa de entrada). | autenticado |
| GET | `/api/aprovacoes/requests/{id}` | Detalhe de um pedido, com o histórico de decisões por nível. | autenticado |
| POST | `/api/aprovacoes/requests/{id}/decidir` | Aprova ou rejeita o nível actual do pedido (o handler valida se o cargo pode decidir). | autenticado |
| POST | `/api/aprovacoes/requests/{id}/cancelar` | Cancela o pedido de aprovação. | autenticado |

## Facturação (`/api/faturacao`)

Documentos fiscais de venda: orçamentos, encomendas, facturas, notas de crédito, recibos e séries de numeração.

| Método | Rota | O que faz | Acesso |
|---|---|---|---|
| GET | `/api/faturacao/quotes` | Orçamentos/cotações a clientes. | feature `vendas.fatura_direta` · `faturacao.ver_documentos` |
| GET | `/api/faturacao/quotes/{id}` | Detalhe de orçamento. | feature `vendas.fatura_direta` · `faturacao.ver_documentos` |
| GET | `/api/faturacao/orders` | Encomendas de clientes. | feature `vendas.fatura_direta` · `faturacao.ver_documentos` |
| GET | `/api/faturacao/invoices` | Facturas emitidas. | feature `vendas.fatura_direta` · `faturacao.ver_documentos` |
| GET | `/api/faturacao/invoices/{id}` | Detalhe de factura. | feature `vendas.fatura_direta` · `faturacao.ver_documentos` |
| GET | `/api/faturacao/invoices/{id}/pdf` | PDF da factura. | feature `vendas.fatura_direta` · `faturacao.ver_documentos` |
| GET | `/api/faturacao/receipts` | Recibos emitidos. | feature `vendas.fatura_direta` · `faturacao.ver_documentos` |
| GET | `/api/faturacao/credit-notes` | Notas de crédito. | feature `vendas.fatura_direta` · `faturacao.ver_documentos` |
| GET | `/api/faturacao/credit-notes/{id}` | Detalhe de nota de crédito. | feature `vendas.fatura_direta` · `faturacao.ver_documentos` |
| GET | `/api/faturacao/credit-notes/{id}/pdf` | PDF da nota de crédito. | feature `vendas.fatura_direta` · `faturacao.ver_documentos` |
| GET | `/api/faturacao/series` | Séries de numeração dos documentos fiscais. | feature `vendas.fatura_direta` · `faturacao.configurar_series` |
| POST | `/api/faturacao/series` | Cria série de numeração. | feature `vendas.fatura_direta` · `faturacao.configurar_series` |
| POST | `/api/faturacao/series/{id}/activar` | Activa série. | feature `vendas.fatura_direta` · `faturacao.configurar_series` |
| POST | `/api/faturacao/series/{id}/desactivar` | Desactiva série. | feature `vendas.fatura_direta` · `faturacao.configurar_series` |
| POST | `/api/faturacao/quotes` | Cria orçamento (rascunho). | feature `vendas.fatura_direta` · feature `vendas.orcamentos` · `faturacao.emitir_orcamentos` |
| POST | `/api/faturacao/quotes/{id}/enviar` | Envia orçamento ao cliente. | feature `vendas.fatura_direta` · feature `vendas.orcamentos` · `faturacao.emitir_orcamentos` |
| POST | `/api/faturacao/quotes/{id}/aprovar` | Marca orçamento como aceite. | feature `vendas.fatura_direta` · feature `vendas.orcamentos` · `faturacao.emitir_orcamentos` |
| POST | `/api/faturacao/quotes/{id}/rejeitar` | Marca orçamento como rejeitado. | feature `vendas.fatura_direta` · feature `vendas.orcamentos` · `faturacao.emitir_orcamentos` |
| POST | `/api/faturacao/quotes/{id}/items` | Adiciona linha ao orçamento. | feature `vendas.fatura_direta` · feature `vendas.orcamentos` · `faturacao.emitir_orcamentos` |
| DELETE | `/api/faturacao/quotes/{id}/items/{itemId}` | Remove linha do orçamento. | feature `vendas.fatura_direta` · feature `vendas.orcamentos` · `faturacao.emitir_orcamentos` |
| POST | `/api/faturacao/orders` | Cria encomenda. | feature `vendas.fatura_direta` · feature `vendas.encomendas` · `faturacao.emitir_encomendas` |
| POST | `/api/faturacao/orders/{id}/confirmar` | Confirma encomenda. | feature `vendas.fatura_direta` · feature `vendas.encomendas` · `faturacao.emitir_encomendas` |
| POST | `/api/faturacao/orders/{id}/cancelar` | Cancela encomenda. | feature `vendas.fatura_direta` · `faturacao.cancelar_documentos` |
| POST | `/api/faturacao/invoices` | Cria factura (rascunho). | feature `vendas.fatura_direta` · `faturacao.emitir_faturas` |
| POST | `/api/faturacao/invoices/{id}/items` | Adiciona linha à factura. | feature `vendas.fatura_direta` · `faturacao.emitir_faturas` |
| POST | `/api/faturacao/invoices/{id}/emitir` | Emite a factura: atribui número da série, fecha o documento (deixa de ser editável). | feature `vendas.fatura_direta` · `faturacao.emitir_faturas` |
| POST | `/api/faturacao/invoices/{id}/enviar-para-assinatura` | Envia factura para assinatura digital. | feature `vendas.fatura_direta` · `faturacao.emitir_faturas` |
| POST | `/api/faturacao/invoices/{id}/gerar-pdf` | Gera/regenera o PDF da factura. | feature `vendas.fatura_direta` · `faturacao.emitir_faturas` |
| POST | `/api/faturacao/invoices/{id}/enviar-email` | Envia a factura por email ao cliente. | feature `vendas.fatura_direta` · `faturacao.emitir_faturas` |
| POST | `/api/faturacao/invoices/{id}/cancelar` | Anula a factura. | feature `vendas.fatura_direta` · `faturacao.cancelar_documentos` |
| POST | `/api/faturacao/credit-notes` | Cria nota de crédito (devolução/correcção). | feature `vendas.fatura_direta` · feature `vendas.devolucoes` · `faturacao.emitir_notas_credito` |
| POST | `/api/faturacao/credit-notes/{id}/items` | Adiciona linha à nota de crédito. | feature `vendas.fatura_direta` · feature `vendas.devolucoes` · `faturacao.emitir_notas_credito` |
| POST | `/api/faturacao/credit-notes/{id}/emitir` | Emite a nota de crédito. | feature `vendas.fatura_direta` · feature `vendas.devolucoes` · `faturacao.emitir_notas_credito` |
| POST | `/api/faturacao/credit-notes/{id}/enviar-para-assinatura` | Envia nota de crédito para assinatura digital. | feature `vendas.fatura_direta` · feature `vendas.devolucoes` · `faturacao.emitir_notas_credito` |
| POST | `/api/faturacao/credit-notes/{id}/gerar-pdf` | Gera o PDF da nota de crédito. | feature `vendas.fatura_direta` · feature `vendas.devolucoes` · `faturacao.emitir_notas_credito` |
| POST | `/api/faturacao/credit-notes/{id}/enviar-email` | Envia a nota de crédito por email. | feature `vendas.fatura_direta` · feature `vendas.devolucoes` · `faturacao.emitir_notas_credito` |
| POST | `/api/faturacao/receipts` | Emite recibo de pagamento. ⚠️ Protegido pela permissão de notas de crédito — ver notas. | feature `vendas.fatura_direta` · feature `vendas.devolucoes` · `faturacao.emitir_notas_credito` |
| POST | `/api/faturacao/credit-notes/{id}/cancelar` | Anula nota de crédito. | feature `vendas.fatura_direta` · `faturacao.cancelar_documentos` |

## Ponto de venda (`/api/pos`)

App de caixa: login do terminal/operador, sessões de caixa, vendas, estornos, pagamento móvel, sincronização offline e relatórios. Quase tudo exige uma licença activa.

| Método | Rota | O que faz | Acesso |
|---|---|---|---|
| POST | `/api/pos/pagamentos/webhook` | Webhook do gateway de pagamento a confirmar pagamento móvel de uma venda POS. Sem login, com rate limit. | **público** · rate limit |
| POST | `/api/pos/login` | Login da app POS (utilizador ou terminal); devolve tokens. | **público** |
| POST | `/api/pos/refresh` | Renova o token da app POS. | **público** |
| POST | `/api/pos/licenca/validar` | App POS valida a chave de licença antes do login (sem login, rate limit). | **público** · rate limit |
| GET | `/api/pos/licenca` | Estado da licença do tenant. | autenticado |
| GET | `/api/pos/produtos` | Pesquisa produtos para venda no caixa (nome/código de barras). | licença activa · `pos.operar_pos` |
| GET | `/api/pos/sessoes/atual` | Sessão de caixa aberta do operador. | licença activa · `pos.operar_pos` |
| POST | `/api/pos/sales` | Regista venda no caixa (baixa stock, gera documento). | licença activa · `pos.operar_pos` · `pos.registar_venda` · operador humano (não token de terminal) |
| GET | `/api/pos/sales/{id}` | Detalhe de venda. | licença activa · `pos.operar_pos` · `pos.operar_pos` ou `pos.ver_vendas` ou `pos.supervisionar` ou `pos.relatorios` |
| POST | `/api/pos/sales/{id}/cancelar` | Anula venda. | licença activa · `pos.operar_pos` · `pos.cancelar_venda` ou `pos.supervisionar_pos` · operador humano (não token de terminal) |
| POST | `/api/pos/sales/{id}/estorno-parcial` | Devolve parte da venda (supervisor). | licença activa · `pos.operar_pos` · `pos.supervisionar_pos` · operador humano (não token de terminal) |
| GET | `/api/pos/sales/{id}/estornos` | Estornos de uma venda. | licença activa · `pos.operar_pos` · `pos.operar_pos` ou `pos.ver_vendas` ou `pos.supervisionar` ou `pos.relatorios` |
| GET | `/api/pos/sales/{id}/recibo` | Recibo/talão da venda. | licença activa · `pos.operar_pos` · `pos.operar_pos` ou `pos.ver_vendas` ou `pos.supervisionar` ou `pos.relatorios` |
| GET | `/api/pos/sales` | Lista vendas. | licença activa · `pos.operar_pos` · `pos.operar_pos` ou `pos.ver_vendas` ou `pos.supervisionar` ou `pos.relatorios` |
| POST | `/api/pos/pagamentos/iniciar` | Inicia pagamento móvel (M-Pesa/e-Mola) para uma venda. | licença activa · `pos.operar_pos` · operador humano (não token de terminal) |
| GET | `/api/pos/pagamentos/{gatewayTxnId}/status` | Estado do pagamento móvel. | licença activa · `pos.operar_pos` |
| GET | `/api/pos/sync/download` | Descarrega dados para funcionamento offline (produtos, preços, descontos). | licença activa · `pos.operar_pos` |
| POST | `/api/pos/login-operador` | No terminal POS já autenticado, identifica o operador de caixa pelo PIN. | licença activa · `pos.operar_pos` |
| GET | `/api/pos/terminais` | Terminais POS. | licença activa · `pos.gerir_terminais` |
| POST | `/api/pos/terminais` | Regista terminal. | licença activa · `pos.gerir_terminais` |
| GET | `/api/pos/terminais/{id}` | Detalhe de terminal. | licença activa · `pos.gerir_terminais` |
| PUT | `/api/pos/terminais/{id}` | Actualiza terminal. | licença activa · `pos.gerir_terminais` |
| DELETE | `/api/pos/terminais/{id}` | Arquiva terminal (DELETE lógico). | licença activa · `pos.gerir_terminais` |
| POST | `/api/pos/terminais/{id}/activar` | Activa terminal. | licença activa · `pos.gerir_terminais` |
| POST | `/api/pos/terminais/{id}/desactivar` | Desactiva terminal. | licença activa · `pos.gerir_terminais` |
| GET | `/api/pos/terminais/{id}/sessao-activa` | Sessão aberta no terminal. | licença activa · `pos.gerir_terminais` |
| GET | `/api/pos/catalogo` | Produtos disponíveis no POS. | licença activa · `pos.gerir_catalogo` |
| POST | `/api/pos/catalogo` | Adiciona produto ao catálogo POS. | licença activa · `pos.gerir_catalogo` |
| DELETE | `/api/pos/catalogo/{id}` | Retira produto do catálogo POS. | licença activa · `pos.gerir_catalogo` |
| GET | `/api/pos/descontos` | Descontos do POS. | licença activa · `pos.gerir_descontos` |
| POST | `/api/pos/descontos` | Cria desconto POS. | licença activa · `pos.gerir_descontos` |
| PUT | `/api/pos/descontos/{id}` | Actualiza desconto POS. | licença activa · `pos.gerir_descontos` |
| DELETE | `/api/pos/descontos/{id}` | Remove desconto POS. | licença activa · `pos.gerir_descontos` |
| GET | `/api/pos/configuracao` | Configuração do POS (impressão, métodos de pagamento…). | licença activa · `pos.configurar` |
| PUT | `/api/pos/configuracao` | Grava configuração do POS. | licença activa · `pos.configurar` |
| GET | `/api/pos/sessoes` | Sessões de caixa. | licença activa · `pos.ver` ou `pos.supervisionar` ou `pos.relatorios` |
| POST | `/api/pos/sessoes` | Abre caixa (valor inicial). | licença activa · `pos.abrir_sessao` · operador humano (não token de terminal) |
| GET | `/api/pos/sessoes/{id}` | Detalhe de sessão. | licença activa · `pos.ver` ou `pos.supervisionar` ou `pos.relatorios` |
| POST | `/api/pos/sessoes/{id}/fechar` | Fecha caixa (contagem, diferenças). | licença activa · `pos.fechar_sessao` ou `pos.supervisionar_pos` ou `pos.fechar_outra_sessao` · operador humano (não token de terminal) |
| GET | `/api/pos/sessoes/{id}/fecho` | Mapa de fecho da sessão. | licença activa · `pos.ver` ou `pos.relatorios` |
| GET | `/api/pos/sessoes/{id}/movimentacoes` | Entradas/saídas de dinheiro na sessão. | licença activa · `pos.ver` ou `pos.supervisionar` |
| POST | `/api/pos/sessoes/{id}/movimentacoes` | Regista sangria/reforço de caixa. | licença activa · `pos.movimentar_caixa` · operador humano (não token de terminal) |
| GET | `/api/pos/relatorios/vendas` | Relatório de vendas. | licença activa · `pos.relatorios` |
| GET | `/api/pos/relatorios/top-produtos` | Relatório: produtos mais vendidos. | licença activa · `pos.relatorios` |
| GET | `/api/pos/relatorios/cancelamentos` | Relatório de cancelamentos. | licença activa · `pos.relatorios` |
| GET | `/api/pos/relatorios/fecho-caixa` | Relatório de fechos de caixa. | licença activa · `pos.relatorios` |
| GET | `/api/pos/relatorios/terminais` | Relatório por terminal. | licença activa · `pos.relatorios` |

## Financeiro (`/api/financeiro`)

Contas a receber/pagar, categorias, métodos de pagamento e fluxo de caixa.

| Método | Rota | O que faz | Acesso |
|---|---|---|---|
| GET | `/api/financeiro/cash-flow` | Fluxo de caixa (entradas vs saídas previstas/realizadas). | `financeiro.ver_financeiro` |
| GET | `/api/financeiro/categorias` | Categorias financeiras (receitas/despesas). | `financeiro.ver_financeiro` |
| POST | `/api/financeiro/categorias` | Cria categoria financeira. | `financeiro.gerir_categorias` |
| GET | `/api/financeiro/metodos-pagamento` | Métodos de pagamento. | `financeiro.ver_financeiro` |
| POST | `/api/financeiro/metodos-pagamento` | Cria método de pagamento. | `financeiro.gerir_categorias` |
| GET | `/api/financeiro/contas-receber` | Contas a receber. | `financeiro.gerir_contas_receber` |
| POST | `/api/financeiro/contas-receber` | Regista conta a receber. | `financeiro.gerir_contas_receber` |
| POST | `/api/financeiro/contas-receber/{id}/pagamento` | Regista recebimento (total/parcial). | `financeiro.gerir_contas_receber` |
| GET | `/api/financeiro/contas-pagar` | Contas a pagar. | `financeiro.gerir_contas_pagar` |
| POST | `/api/financeiro/contas-pagar` | Regista conta a pagar. | `financeiro.gerir_contas_pagar` |
| POST | `/api/financeiro/contas-pagar/{id}/pagamento` | Regista pagamento (total/parcial). | `financeiro.gerir_contas_pagar` |

## Tesouraria (`/api/tesouraria`)

Contas bancárias, caixas, movimentos e reconciliação bancária.

| Método | Rota | O que faz | Acesso |
|---|---|---|---|
| GET | `/api/tesouraria/contas-bancarias` | Contas bancárias da tesouraria. | `tesouraria.ver_tesouraria` |
| GET | `/api/tesouraria/caixas` | Caixas (dinheiro físico). | `tesouraria.ver_tesouraria` |
| GET | `/api/tesouraria/movimentos` | Movimentos de tesouraria. | `tesouraria.ver_tesouraria` |
| GET | `/api/tesouraria/reconciliacoes` | Reconciliações bancárias. | `tesouraria.ver_tesouraria` |
| POST | `/api/tesouraria/contas-bancarias` | Cria conta bancária. | `tesouraria.gerir_contas` |
| POST | `/api/tesouraria/caixas` | Cria caixa. | `tesouraria.gerir_contas` |
| POST | `/api/tesouraria/movimentos` | Regista movimento (entrada/saída) numa conta/caixa. | `tesouraria.gerir_movimentos` |
| POST | `/api/tesouraria/reconciliacoes` | Inicia reconciliação bancária (extracto vs sistema). | `tesouraria.gerir_reconciliacao` |
| POST | `/api/tesouraria/reconciliacoes/{id}/fechar` | Fecha a reconciliação. | `tesouraria.gerir_reconciliacao` |
| POST | `/api/tesouraria/reconciliacoes/{id}/enviar-para-assinatura` | Envia a reconciliação para assinatura digital. | `tesouraria.gerir_reconciliacao` |

## Multi-moeda (`/api/multi-moeda`)

Moedas, taxas de câmbio e conversão.

| Método | Rota | O que faz | Acesso |
|---|---|---|---|
| POST | `/api/multi-moeda/converter` | Converte um valor entre moedas à taxa em vigor. | `multi-moeda.ver_moedas` |
| GET | `/api/multi-moeda/moedas` | Moedas. | `multi-moeda.ver_moedas` |
| POST | `/api/multi-moeda/moedas` | Cria moeda. | `multi-moeda.gerir_moedas` |
| GET | `/api/multi-moeda/taxas-cambio` | Taxas de câmbio. | `multi-moeda.ver_moedas` |
| POST | `/api/multi-moeda/taxas-cambio` | Regista taxa de câmbio. | `multi-moeda.gerir_moedas` |
| GET | `/api/multi-moeda/tenant-moedas` | Moedas activas no tenant. | `multi-moeda.ver_moedas` |
| POST | `/api/multi-moeda/tenant-moedas` | Activa moeda no tenant. | `multi-moeda.gerir_moedas` |
| DELETE | `/api/multi-moeda/tenant-moedas/{id}` | Desactiva moeda no tenant. | `multi-moeda.gerir_moedas` |

## Impostos (`/api/impostos`)

Regimes fiscais, isenções, retenções na fonte, declarações e certificados.

| Método | Rota | O que faz | Acesso |
|---|---|---|---|
| GET | `/api/impostos/regimes` | Regimes fiscais (normal, simplificado, isento…). | `impostos.ver_impostos` |
| GET | `/api/impostos/isencoes` | Isenções fiscais registadas. | `impostos.ver_impostos` |
| GET | `/api/impostos/retencoes` | Retenções na fonte. | `impostos.ver_impostos` |
| GET | `/api/impostos/retencoes/{id}/transaccoes` | Transacções sujeitas a uma retenção. | `impostos.ver_impostos` |
| GET | `/api/impostos/declaracoes` | Declarações fiscais (IVA, IRPS…). | `impostos.ver_impostos` |
| GET | `/api/impostos/declaracoes/{id}` | Detalhe de declaração. | `impostos.ver_impostos` |
| GET | `/api/impostos/declaracoes/{id}/linhas` | Linhas/campos da declaração. | `impostos.ver_impostos` |
| GET | `/api/impostos/certificados` | Certificados fiscais (quitação, etc.). | `impostos.ver_impostos` |
| GET | `/api/impostos/certificados/{id}/download` | Descarrega o ficheiro do certificado. | `impostos.ver_impostos` |
| POST | `/api/impostos/regimes` | Cria regime fiscal. | `impostos.gerir_impostos` |
| POST | `/api/impostos/isencoes` | Regista isenção. | `impostos.gerir_impostos` |
| PUT | `/api/impostos/isencoes/{id}` | Actualiza isenção. | `impostos.gerir_impostos` |
| DELETE | `/api/impostos/isencoes/{id}` | Remove isenção. | `impostos.gerir_impostos` |
| POST | `/api/impostos/retencoes` | Cria tipo de retenção ou regista uma retenção efectuada. | `impostos.gerir_impostos` |
| POST | `/api/impostos/declaracoes` | Prepara declaração fiscal para um período. | `impostos.gerir_impostos` |
| POST | `/api/impostos/declaracoes/{id}/submeter` | Marca a declaração como submetida. | `impostos.gerir_impostos` |
| POST | `/api/impostos/certificados` | Regista certificado fiscal. | `impostos.gerir_impostos` |
| POST | `/api/impostos/certificados/{id}/upload` | Carrega o ficheiro do certificado. | `impostos.gerir_impostos` |

## Contabilidade (`/api/contabilidade`)

Plano de contas, diários, lançamentos, exercícios e períodos, imobilizado e amortizações, orçamentos, encerramento e demonstrações financeiras.

| Método | Rota | O que faz | Acesso |
|---|---|---|---|
| GET | `/api/contabilidade/account-types` | Tipos de conta (activo, passivo, capital, proveitos, custos). | feature `contabilidade` · `contabilidade.ver_contabilidade` |
| GET | `/api/contabilidade/account-types/{id}` | Detalhe de tipo de conta. | feature `contabilidade` · `contabilidade.ver_contabilidade` |
| POST | `/api/contabilidade/account-types` | Cria tipo de conta. | feature `contabilidade` · `contabilidade.gerir_plano_contas` |
| PUT | `/api/contabilidade/account-types/{id}` | Actualiza tipo de conta. | feature `contabilidade` · `contabilidade.gerir_plano_contas` |
| DELETE | `/api/contabilidade/account-types/{id}` | Elimina tipo de conta. | feature `contabilidade` · `contabilidade.gerir_plano_contas` |
| GET | `/api/contabilidade/accounts` | Plano de contas. | feature `contabilidade` · `contabilidade.ver_contabilidade` |
| GET | `/api/contabilidade/accounts/{id}` | Detalhe de conta (com saldo). | feature `contabilidade` · `contabilidade.ver_contabilidade` |
| POST | `/api/contabilidade/accounts` | Cria conta no plano de contas. | feature `contabilidade` · `contabilidade.gerir_plano_contas` |
| PUT | `/api/contabilidade/accounts/{id}` | Actualiza conta. | feature `contabilidade` · `contabilidade.gerir_plano_contas` |
| DELETE | `/api/contabilidade/accounts/{id}` | Elimina conta. | feature `contabilidade` · `contabilidade.gerir_plano_contas` |
| GET | `/api/contabilidade/tax-groups` | Grupos de imposto (para mapear IVA a contas). | feature `contabilidade` · `contabilidade.ver_contabilidade` |
| POST | `/api/contabilidade/tax-groups` | Cria grupo de imposto. | feature `contabilidade` · `contabilidade.gerir_plano_contas` |
| PUT | `/api/contabilidade/tax-groups/{id}` | Actualiza grupo de imposto. | feature `contabilidade` · `contabilidade.gerir_plano_contas` |
| GET | `/api/contabilidade/taxes` | Taxas de imposto. | feature `contabilidade` · `contabilidade.ver_contabilidade` |
| GET | `/api/contabilidade/taxes/{id}` | Detalhe de taxa. | feature `contabilidade` · `contabilidade.ver_contabilidade` |
| POST | `/api/contabilidade/taxes` | Cria taxa. | feature `contabilidade` · `contabilidade.gerir_plano_contas` |
| PUT | `/api/contabilidade/taxes/{id}` | Actualiza taxa. | feature `contabilidade` · `contabilidade.gerir_plano_contas` |
| POST | `/api/contabilidade/taxes/{id}/rules` | Adiciona regra de aplicação à taxa (por produto, cliente, região…). | feature `contabilidade` · `contabilidade.gerir_plano_contas` |
| GET | `/api/contabilidade/tax-transactions` | Movimentos de imposto registados. | feature `contabilidade` · `contabilidade.ver_contabilidade` |
| GET | `/api/contabilidade/tax-transactions/{id}` | Detalhe de transacção de imposto. | feature `contabilidade` · `contabilidade.ver_contabilidade` |
| POST | `/api/contabilidade/tax-transactions` | Regista movimento de imposto. | feature `contabilidade` · `contabilidade.gerir_plano_contas` |
| GET | `/api/contabilidade/journals` | Diários contabilísticos (vendas, compras, caixa…). | feature `contabilidade` · `contabilidade.ver_contabilidade` |
| POST | `/api/contabilidade/journals` | Cria diário. | feature `contabilidade` · `contabilidade.gerir_lancamentos` |
| PUT | `/api/contabilidade/journals/{id}` | Actualiza diário. | feature `contabilidade` · `contabilidade.gerir_lancamentos` |
| GET | `/api/contabilidade/journal-entries` | Lançamentos contabilísticos. | feature `contabilidade` · `contabilidade.ver_contabilidade` |
| GET | `/api/contabilidade/journal-entries/{id}` | Detalhe de lançamento (linhas débito/crédito). | feature `contabilidade` · `contabilidade.ver_contabilidade` |
| POST | `/api/contabilidade/journal-entries` | Cria lançamento. | feature `contabilidade` · `contabilidade.gerir_lancamentos` |
| PUT | `/api/contabilidade/journal-entries/{id}` | Actualiza lançamento (se ainda não fechado). | feature `contabilidade` · `contabilidade.gerir_lancamentos` |
| POST | `/api/contabilidade/journal-entries/{id}/lines` | Adiciona linha débito/crédito ao lançamento. | feature `contabilidade` · `contabilidade.gerir_lancamentos` |
| DELETE | `/api/contabilidade/journal-entries/{id}` | Estorna o lançamento (gera contra-lançamento; não apaga). | feature `contabilidade` · `contabilidade.estornar_lancamentos` |
| GET | `/api/contabilidade/fiscal-years` | Exercícios fiscais. | feature `contabilidade` · `contabilidade.ver_contabilidade` |
| GET | `/api/contabilidade/fiscal-years/{id}` | Detalhe de exercício. | feature `contabilidade` · `contabilidade.ver_contabilidade` |
| POST | `/api/contabilidade/fiscal-years` | Cria exercício fiscal. | feature `contabilidade` · `contabilidade.gerir_periodos` |
| PUT | `/api/contabilidade/fiscal-years/{id}` | Actualiza exercício. | feature `contabilidade` · `contabilidade.gerir_periodos` |
| POST | `/api/contabilidade/fiscal-years/{id}/fechar` | Fecha o exercício (apura resultados, bloqueia lançamentos). | feature `contabilidade` · `contabilidade.fechar_ano_fiscal` |
| GET | `/api/contabilidade/fiscal-periods` | Períodos (meses) do exercício. | feature `contabilidade` · `contabilidade.ver_contabilidade` |
| GET | `/api/contabilidade/fiscal-periods/{id}` | Detalhe de período. | feature `contabilidade` · `contabilidade.ver_contabilidade` |
| POST | `/api/contabilidade/fiscal-periods` | Cria período. | feature `contabilidade` · `contabilidade.gerir_periodos` |
| POST | `/api/contabilidade/fiscal-periods/{id}/abrir` | Abre período para lançamentos. | feature `contabilidade` · `contabilidade.gerir_periodos` |
| POST | `/api/contabilidade/fiscal-periods/{id}/fechar` | Fecha período. | feature `contabilidade` · `contabilidade.gerir_periodos` |
| GET | `/api/contabilidade/fixed-assets` | Imobilizado (activos fixos). | feature `contabilidade` · `contabilidade.ver_contabilidade` |
| GET | `/api/contabilidade/fixed-assets/{id}` | Detalhe de activo. | feature `contabilidade` · `contabilidade.ver_contabilidade` |
| GET | `/api/contabilidade/fixed-assets/{id}/schedule` | Plano de amortização do activo. | feature `contabilidade` · `contabilidade.ver_contabilidade` |
| POST | `/api/contabilidade/fixed-assets` | Regista activo fixo. | feature `contabilidade` · `contabilidade.gerir_ativos_fixos` |
| PUT | `/api/contabilidade/fixed-assets/{id}` | Actualiza activo. | feature `contabilidade` · `contabilidade.gerir_ativos_fixos` |
| POST | `/api/contabilidade/fixed-assets/{id}/alienar` | Regista venda/abate do activo. | feature `contabilidade` · `contabilidade.gerir_ativos_fixos` |
| GET | `/api/contabilidade/depreciation` | Amortizações processadas. | feature `contabilidade` · `contabilidade.ver_contabilidade` |
| GET | `/api/contabilidade/depreciation/{id}` | Detalhe de amortização. | feature `contabilidade` · `contabilidade.ver_contabilidade` |
| POST | `/api/contabilidade/depreciation/processar` | Processa as amortizações do período (gera lançamentos). | feature `contabilidade` · `contabilidade.gerir_ativos_fixos` |
| POST | `/api/contabilidade/depreciation/{id}/cancelar` | Cancela amortização processada. | feature `contabilidade` · `contabilidade.gerir_ativos_fixos` |
| GET | `/api/contabilidade/budgets/vs-realizado` | Comparação orçamento vs realizado. | feature `contabilidade` · `contabilidade.ver_contabilidade` |
| GET | `/api/contabilidade/budgets` | Orçamentos. | feature `contabilidade` · `contabilidade.ver_contabilidade` |
| POST | `/api/contabilidade/budgets` | Cria orçamento. | feature `contabilidade` · `contabilidade.gerir_orcamentos` |
| PUT | `/api/contabilidade/budgets/{id}` | Actualiza orçamento. | feature `contabilidade` · `contabilidade.gerir_orcamentos` |
| DELETE | `/api/contabilidade/budgets/{id}` | Elimina orçamento. | feature `contabilidade` · `contabilidade.gerir_orcamentos` |
| GET | `/api/contabilidade/period-closings` | Processos de encerramento de período. | feature `contabilidade` · `contabilidade.ver_contabilidade` |
| GET | `/api/contabilidade/period-closings/{id}` | Detalhe de encerramento (checklist). | feature `contabilidade` · `contabilidade.ver_contabilidade` |
| POST | `/api/contabilidade/period-closings` | Inicia o encerramento de um período. | feature `contabilidade` · `contabilidade.fechar_periodo` |
| POST | `/api/contabilidade/period-closings/{id}/verificar` | Corre as verificações pré-fecho (balancete equilibrado, lançamentos pendentes…). | feature `contabilidade` · `contabilidade.fechar_periodo` |
| POST | `/api/contabilidade/period-closings/{id}/encerrar` | Confirma e encerra o período. | feature `contabilidade` · `contabilidade.fechar_periodo` |
| POST | `/api/contabilidade/period-closings/{id}/reabrir` | Reabre um período encerrado. | feature `contabilidade` · `contabilidade.reabrir_periodo` |
| GET | `/api/contabilidade/reports/trial-balance` | Balancete de verificação. | feature `contabilidade` · `contabilidade.ver_contabilidade` |
| GET | `/api/contabilidade/reports/balance-sheet` | Balanço. | feature `contabilidade` · `contabilidade.ver_contabilidade` |
| GET | `/api/contabilidade/reports/income-statement` | Demonstração de resultados. | feature `contabilidade` · `contabilidade.ver_contabilidade` |
| GET | `/api/contabilidade/reports/general-ledger` | Razão geral (movimentos por conta). | feature `contabilidade` · `contabilidade.ver_contabilidade` |
| GET | `/api/contabilidade/reports/depreciation-summary` | Mapa resumo de amortizações. | feature `contabilidade` · `contabilidade.ver_contabilidade` |
| GET | `/api/contabilidade/reports/budget-execution` | Execução orçamental. | feature `contabilidade` · `contabilidade.ver_contabilidade` |
| GET | `/api/contabilidade/reports` | Relatórios gerados e guardados. | feature `contabilidade` · `contabilidade.ver_contabilidade` |
| GET | `/api/contabilidade/reports/{id}` | Detalhe/ficheiro de relatório gerado. | feature `contabilidade` · `contabilidade.ver_contabilidade` |
| POST | `/api/contabilidade/reports/generate` | Gera e guarda um relatório contabilístico. | feature `contabilidade` · `contabilidade.ver_relatorios` |
| POST | `/api/contabilidade/reports/{id}/enviar-para-assinatura` | Envia relatório para assinatura digital. | feature `contabilidade` · `contabilidade.ver_relatorios` |

## Centros de custo (`/api/centros-custo`)

Centros de custo, orçamentos e imputações.

| Método | Rota | O que faz | Acesso |
|---|---|---|---|
| GET | `/api/centros-custo/cost-centers` | Centros de custo. | feature `cont.centros_custo` · `centros-custo.ver_centros` |
| GET | `/api/centros-custo/cost-centers/{id}` | Detalhe de centro de custo. | feature `cont.centros_custo` · `centros-custo.ver_centros` |
| POST | `/api/centros-custo/cost-centers` | Cria centro de custo. | feature `cont.centros_custo` · `centros-custo.gerir_centros` |
| PUT | `/api/centros-custo/cost-centers/{id}` | Actualiza centro de custo. | feature `cont.centros_custo` · `centros-custo.gerir_centros` |
| DELETE | `/api/centros-custo/cost-centers/{id}` | Elimina centro de custo. | feature `cont.centros_custo` · `centros-custo.eliminar_centros` |
| GET | `/api/centros-custo/budgets/vs-realizado` | Orçado vs realizado por centro de custo. | feature `cont.centros_custo` · `centros-custo.ver_centros` |
| GET | `/api/centros-custo/budgets` | Orçamentos por centro de custo. | feature `cont.centros_custo` · `centros-custo.ver_centros` |
| POST | `/api/centros-custo/budgets` | Cria orçamento de centro de custo. | feature `cont.centros_custo` · `centros-custo.gerir_centros` |
| PUT | `/api/centros-custo/budgets/{id}` | Actualiza orçamento de centro de custo. | feature `cont.centros_custo` · `centros-custo.gerir_centros` |
| DELETE | `/api/centros-custo/budgets/{id}` | Elimina orçamento de centro de custo. | feature `cont.centros_custo` · `centros-custo.eliminar_centros` |
| GET | `/api/centros-custo/allocations` | Imputações de custos/proveitos a centros. | feature `cont.centros_custo` · `centros-custo.ver_centros` |
| GET | `/api/centros-custo/allocations/{id}` | Detalhe de imputação. | feature `cont.centros_custo` · `centros-custo.ver_centros` |
| POST | `/api/centros-custo/allocations` | Imputa um valor a um centro de custo. | feature `cont.centros_custo` · `centros-custo.gerir_centros` |

## Logística (`/api/delivery-*`, `/api/shipments`)

Motoristas, viaturas, rotas, envios e rastreio de entregas.

| Método | Rota | O que faz | Acesso |
|---|---|---|---|
| GET | `/api/delivery-drivers` | Motoristas de entrega. | feature `logistica` · `logistica.ver_logistica` |
| GET | `/api/delivery-vehicles` | Viaturas de entrega. | feature `logistica` · `logistica.ver_logistica` |
| GET | `/api/delivery-routes` | Rotas de entrega. | feature `logistica` · `logistica.ver_logistica` |
| GET | `/api/shipments` | Envios/expedições. | feature `logistica` · `logistica.ver_logistica` |
| GET | `/api/delivery-tracking` | Pontos de rastreio das entregas. | feature `logistica` · `logistica.ver_logistica` |
| GET | `/api/delivery-logs` | Registo de eventos das entregas. | feature `logistica` · `logistica.ver_logistica` |
| POST | `/api/delivery-drivers` | Cria motorista. | feature `logistica` · `logistica.gerir_entregas` |
| POST | `/api/delivery-vehicles` | Cria viatura. | feature `logistica` · `logistica.gerir_entregas` |
| POST | `/api/delivery-routes` | Cria rota. | feature `logistica` · `logistica.gerir_entregas` |
| POST | `/api/shipments` | Cria envio. | feature `logistica` · `logistica.gerir_entregas` |
| POST | `/api/delivery-tracking` | Regista ponto de rastreio (posição/estado da entrega). | feature `logistica` · `logistica.gerir_entregas` |

## Subscrições (`/api/assinaturas`)

Planos de subscrição **que o tenant vende aos seus clientes** (facturação recorrente). Não confundir com assinatura digital nem com os planos do SaaS (superadmin).

| Método | Rota | O que faz | Acesso |
|---|---|---|---|
| GET | `/api/assinaturas/planos` | Planos de subscrição que o tenant vende aos seus clientes. | `assinaturas.ver_assinaturas` |
| POST | `/api/assinaturas/planos` | Cria plano de subscrição. | `assinaturas.gerir_assinaturas` |
| PUT | `/api/assinaturas/planos/{id}` | Actualiza plano. | `assinaturas.gerir_assinaturas` |
| GET | `/api/assinaturas/subscriptions` | Subscrições de clientes. | `assinaturas.ver_assinaturas` |
| GET | `/api/assinaturas/subscriptions/{id}/facturas` | Facturas geradas pela subscrição. | `assinaturas.ver_assinaturas` |
| GET | `/api/assinaturas/subscriptions/{id}/utilizacao` | Consumo/utilização da subscrição. | `assinaturas.ver_assinaturas` |
| POST | `/api/assinaturas/subscriptions` | Cria subscrição para um cliente. | `assinaturas.gerir_assinaturas` |
| POST | `/api/assinaturas/subscriptions/{id}/cancelar` | Cancela subscrição. | `assinaturas.gerir_assinaturas` |
| POST | `/api/assinaturas/subscriptions/{id}/renovar` | Renova subscrição. | `assinaturas.gerir_assinaturas` |

## Assinatura digital (`/api/assinatura-digital`, `/assinar`, `/verificar-assinatura`)

Assinatura electrónica de PDFs (PAdES). As rotas `/convites/{token}`, `/assinar/{token}` e as de verificação são públicas: servem signatários externos que não têm conta.

| Método | Rota | O que faz | Acesso |
|---|---|---|---|
| GET | `/api/assinatura-digital/documentos` | Documentos em assinatura digital. | `assinatura-digital.ver_documentos` |
| GET | `/api/assinatura-digital/documentos/{id}` | Detalhe (signatários, estado). | `assinatura-digital.ver_documentos` |
| GET | `/api/assinatura-digital/documentos/{id}/download` | Descarrega o PDF assinado. | `assinatura-digital.ver_documentos` |
| GET | `/api/assinatura-digital/documentos/{id}/original/download` | Descarrega o PDF original, antes das assinaturas. | `assinatura-digital.ver_documentos` |
| GET | `/api/assinatura-digital/documentos/{id}/versoes` | Versões do documento (uma por assinatura). | `assinatura-digital.ver_documentos` |
| GET | `/api/assinatura-digital/documentos/{id}/versoes/{versaoId}/download` | Descarrega uma versão. | `assinatura-digital.ver_documentos` |
| GET | `/api/assinatura-digital/documentos/{id}/evidencias` | Trilho de evidências (IP, hora, OTP, hash) de cada assinatura. | `assinatura-digital.ver_documentos` |
| GET | `/api/assinatura-digital/documentos/{id}/validacao` | Resultado da validação criptográfica (PAdES). | `assinatura-digital.ver_documentos` |
| POST | `/api/assinatura-digital/documentos/{id}/revalidar` | Revalida as assinaturas do documento. | `assinatura-digital.ver_documentos` |
| POST | `/api/assinatura-digital/documentos` | Carrega documento para assinatura. | `assinatura-digital.gerir_documentos` |
| POST | `/api/assinatura-digital/documentos/{id}/enviar` | Envia aos signatários (convites por email/SMS). | `assinatura-digital.gerir_documentos` |
| POST | `/api/assinatura-digital/documentos/{id}/cancelar` | Cancela o processo de assinatura. | `assinatura-digital.gerir_documentos` |
| POST | `/api/assinatura-digital/documentos/{id}/signatarios` | Adiciona signatário. | `assinatura-digital.gerir_documentos` |
| DELETE | `/api/assinatura-digital/documentos/{id}/signatarios/{sigId}` | Remove signatário. | `assinatura-digital.gerir_documentos` |
| POST | `/api/assinatura-digital/documentos/{id}/assinar` | Utilizador interno assina o documento. | `assinatura-digital.assinar_documentos` |
| POST | `/api/assinatura-digital/documentos/{id}/signatarios/{sigId}/recusar` | Signatário recusa assinar. | `assinatura-digital.assinar_documentos` |
| GET | `/api/assinatura-digital/convites/{token}` | Dados do convite de assinatura (signatário externo, pelo token). | **público** · rate limit |
| POST | `/api/assinatura-digital/convites/{token}/otp/enviar` | Envia código OTP ao signatário externo. | **público** · rate limit |
| POST | `/api/assinatura-digital/convites/{token}/otp/validar` | Valida o OTP. | **público** · rate limit |
| POST | `/api/assinatura-digital/convites/{token}/assinar` | Signatário externo assina. | **público** · rate limit |
| POST | `/api/assinatura-digital/convites/{token}/recusar` | Signatário externo recusa. | **público** · rate limit |
| GET | `/api/assinatura-digital/convites/{token}/preview` | Pré-visualização do documento para o signatário externo. | **público** · rate limit |
| POST | `/api/assinatura-digital/webhooks/{provider}` | Webhook de fornecedor externo de assinatura (estado das assinaturas). | **público** · rate limit |
| GET | `/api/public/assinatura-digital/verificar/{hash}` | Verificação pública: confirma que um documento com este hash foi assinado. | **público** · rate limit |
| GET | `/verificar-assinatura` | Página HTML pública de verificação de assinaturas. | **público** |
| GET | `/assinar/{token}` | Página HTML onde o signatário externo assina (link do convite). | **público** · rate limit |

## Recursos Humanos (`/api/rh`)

Estrutura orgânica, funcionários, contratos, salários (IRPS/INSS), folhas de pagamento, ausências, avaliações, formações e todo o motor de assiduidade (eventos, regras, métodos de marcação, correcções, justificações, biometria). **Todas** as rotas exigem a feature `rh.assiduidade`.

| Método | Rota | O que faz | Acesso |
|---|---|---|---|
| GET | `/api/rh/relatorios` | Relatórios de RH (efectivos, assiduidade, custos). | feature `rh.assiduidade` · `recursos-humanos.ver_funcionarios` |
| GET | `/api/rh/presencas` | Presenças de todos os funcionários, filtráveis por tipo/data. | feature `rh.assiduidade` · `recursos-humanos.ver_funcionarios` |
| GET | `/api/rh/unidades` | Unidades orgânicas (departamentos, secções). | feature `rh.assiduidade` · `recursos-humanos.ver_funcionarios` |
| GET | `/api/rh/unidades/{id}` | Detalhe de unidade. | feature `rh.assiduidade` · `recursos-humanos.ver_funcionarios` |
| GET | `/api/rh/unidades/{id}/filhos` | Sub-unidades directas. | feature `rh.assiduidade` · `recursos-humanos.ver_funcionarios` |
| GET | `/api/rh/unidades/{id}/subarvore` | Árvore completa abaixo da unidade. | feature `rh.assiduidade` · `recursos-humanos.ver_funcionarios` |
| GET | `/api/rh/unidades/{id}/caminho` | Caminho da unidade até à raiz (breadcrumb). | feature `rh.assiduidade` · `recursos-humanos.ver_funcionarios` |
| GET | `/api/rh/unidades/{id}/funcionarios` | Funcionários da unidade. | feature `rh.assiduidade` · `recursos-humanos.ver_funcionarios` |
| GET | `/api/rh/unidades/{id}/funcionarios/todos` | Funcionários da unidade e sub-unidades. | feature `rh.assiduidade` · `recursos-humanos.ver_funcionarios` |
| POST | `/api/rh/unidades` | Cria unidade orgânica. | feature `rh.assiduidade` · `recursos-humanos.gerir_funcionarios` |
| PUT | `/api/rh/unidades/{id}` | Actualiza unidade. | feature `rh.assiduidade` · `recursos-humanos.gerir_funcionarios` |
| DELETE | `/api/rh/unidades/{id}` | Remove unidade. | feature `rh.assiduidade` · `recursos-humanos.gerir_funcionarios` |
| POST | `/api/rh/unidades/{id}/mover` | Muda a unidade de posição na hierarquia. | feature `rh.assiduidade` · `recursos-humanos.gerir_funcionarios` |
| GET | `/api/rh/configuracoes` | Configurações de RH (INSS, horas, regras salariais). | feature `rh.assiduidade` · `recursos-humanos.ver_funcionarios` |
| GET | `/api/rh/irps-escaloes` | Escalões de IRPS. | feature `rh.assiduidade` · `recursos-humanos.ver_funcionarios` |
| POST | `/api/rh/configuracoes` | Grava configuração de RH. | feature `rh.assiduidade` · `recursos-humanos.gerir_funcionarios` |
| POST | `/api/rh/irps-escaloes` | Cria escalão de IRPS. | feature `rh.assiduidade` · `recursos-humanos.gerir_funcionarios` |
| POST | `/api/rh/irps-escaloes/seed-mozambique-2024` | Carrega a tabela oficial de IRPS de Moçambique 2024. | feature `rh.assiduidade` · `recursos-humanos.gerir_funcionarios` |
| PUT | `/api/rh/irps-escaloes/{id}` | Actualiza escalão. | feature `rh.assiduidade` · `recursos-humanos.gerir_funcionarios` |
| DELETE | `/api/rh/irps-escaloes/{id}` | Elimina escalão. | feature `rh.assiduidade` · `recursos-humanos.gerir_funcionarios` |
| GET | `/api/rh/funcionarios` | Funcionários. | feature `rh.assiduidade` · `recursos-humanos.ver_funcionarios` |
| GET | `/api/rh/funcionarios/proximo-numero` | Sugere o próximo número de funcionário. | feature `rh.assiduidade` · `recursos-humanos.ver_funcionarios` |
| GET | `/api/rh/funcionarios/{id}` | Ficha do funcionário. | feature `rh.assiduidade` · `recursos-humanos.ver_funcionarios` |
| GET | `/api/rh/funcionarios/{id}/nfc-tags` | Cartões NFC do funcionário (marcação de ponto). | feature `rh.assiduidade` · `recursos-humanos.ver_funcionarios` |
| GET | `/api/rh/funcionarios/consentimento` | Consentimento de dados biométricos do funcionário. | feature `rh.assiduidade` · `recursos-humanos.ver_funcionarios` |
| GET | `/api/rh/funcionarios/{id}/recibos-vencimento` | Recibos de vencimento do funcionário. | feature `rh.assiduidade` · `recursos-humanos.ver_recibos` |
| POST | `/api/rh/funcionarios` | Cria funcionário (e a pessoa central, se não existir). | feature `rh.assiduidade` · `recursos-humanos.gerir_funcionarios` |
| PUT | `/api/rh/funcionarios/{id}` | Actualiza ficha. | feature `rh.assiduidade` · `recursos-humanos.gerir_funcionarios` |
| POST | `/api/rh/funcionarios/{id}/desligar` | Regista saída do funcionário (desvinculação). | feature `rh.assiduidade` · `recursos-humanos.gerir_funcionarios` |
| POST | `/api/rh/funcionarios/{id}/nfc-tags` | Associa cartão NFC ao funcionário. | feature `rh.assiduidade` · `recursos-humanos.gerir_funcionarios` |
| DELETE | `/api/rh/funcionarios/nfc-tags/{id}` | Remove cartão NFC. | feature `rh.assiduidade` · `recursos-humanos.gerir_funcionarios` |
| POST | `/api/rh/funcionarios/biometria/facial/enroll` | Regista o rosto do funcionário no FaceClock (reconhecimento facial). | feature `rh.assiduidade` · `recursos-humanos.gerir_funcionarios` |
| POST | `/api/rh/funcionarios/consentimento` | Regista consentimento biométrico. | feature `rh.assiduidade` · `recursos-humanos.gerir_funcionarios` |
| GET | `/api/rh/funcionarios/{id}/historico-salarial` | Histórico de alterações salariais. | feature `rh.assiduidade` · `recursos-humanos.ver_salarios` |
| GET | `/api/rh/funcionarios/{id}/componentes-salariais` | Componentes salariais do funcionário (subsídios, descontos). | feature `rh.assiduidade` · `recursos-humanos.ver_salarios` |
| POST | `/api/rh/funcionarios/{id}/historico-salarial` | Regista alteração salarial. | feature `rh.assiduidade` · `recursos-humanos.processar_salarios` |
| POST | `/api/rh/funcionarios/{id}/componentes-salariais` | Atribui componente salarial. | feature `rh.assiduidade` · `recursos-humanos.processar_salarios` |
| DELETE | `/api/rh/funcionarios/{id}/componentes-salariais/{componenteId}` | Retira componente salarial. | feature `rh.assiduidade` · `recursos-humanos.processar_salarios` |
| GET | `/api/rh/funcionarios/{id}/adiantamentos` | Adiantamentos salariais. | feature `rh.assiduidade` · `recursos-humanos.processar_salarios` |
| POST | `/api/rh/funcionarios/{id}/adiantamentos` | Regista adiantamento (descontado no salário). | feature `rh.assiduidade` · `recursos-humanos.processar_salarios` |
| GET | `/api/rh/funcionarios/{id}/emprestimos` | Empréstimos ao funcionário. | feature `rh.assiduidade` · `recursos-humanos.processar_salarios` |
| POST | `/api/rh/funcionarios/{id}/emprestimos` | Regista empréstimo (prestações descontadas). | feature `rh.assiduidade` · `recursos-humanos.processar_salarios` |
| POST | `/api/rh/funcionarios/adiantamentos/{id}/cancelar` | Cancela adiantamento. | feature `rh.assiduidade` · `recursos-humanos.processar_salarios` |
| POST | `/api/rh/funcionarios/emprestimos/{id}/cancelar` | Cancela empréstimo. | feature `rh.assiduidade` · `recursos-humanos.processar_salarios` |
| GET | `/api/rh/funcionarios/{id}/beneficios` | Benefícios do funcionário. | feature `rh.assiduidade` · `recursos-humanos.ver_beneficios` |
| POST | `/api/rh/funcionarios/{id}/beneficios` | Atribui benefício. | feature `rh.assiduidade` · `recursos-humanos.gerir_beneficios` |
| DELETE | `/api/rh/funcionarios/{id}/beneficios/{beneficioId}` | Retira benefício. | feature `rh.assiduidade` · `recursos-humanos.gerir_beneficios` |
| GET | `/api/rh/funcionarios/{id}/presencas` | Presenças do funcionário. | feature `rh.assiduidade` · `recursos-humanos.ver_funcionarios` |
| GET | `/api/rh/funcionarios/{id}/saldos-ausencia` | Saldos de férias/ausências. | feature `rh.assiduidade` · `recursos-humanos.ver_funcionarios` |
| GET | `/api/rh/funcionarios/{id}/eventos` | Eventos de assiduidade brutos (marcações). | feature `rh.assiduidade` · `recursos-humanos.ver_funcionarios` |
| GET | `/api/rh/funcionarios/{id}/resultados` | Resultados diários calculados (horas, atrasos, faltas). | feature `rh.assiduidade` · `recursos-humanos.ver_funcionarios` |
| POST | `/api/rh/funcionarios/{id}/presencas` | Regista presença manual. | feature `rh.assiduidade` · `recursos-humanos.gerir_funcionarios` |
| DELETE | `/api/rh/funcionarios/{id}/presencas/{presencaId}` | Remove presença. | feature `rh.assiduidade` · `recursos-humanos.gerir_funcionarios` |
| POST | `/api/rh/funcionarios/{id}/saldos-ausencia` | Define saldo de férias/ausência. | feature `rh.assiduidade` · `recursos-humanos.gerir_funcionarios` |
| POST | `/api/rh/funcionarios/{id}/recalcular` | Recalcula os resultados de assiduidade (após mudar regras/horário). | feature `rh.assiduidade` · `recursos-humanos.gerir_funcionarios` |
| GET | `/api/rh/funcionarios/{id}/processos-disciplinares` | Processos disciplinares. | feature `rh.assiduidade` · `recursos-humanos.ver_processos_disciplinares` |
| POST | `/api/rh/funcionarios/{id}/processos-disciplinares` | Abre processo disciplinar. | feature `rh.assiduidade` · `recursos-humanos.gerir_funcionarios` |
| PUT | `/api/rh/funcionarios/{id}/processos-disciplinares/{registoId}` | Actualiza processo disciplinar. | feature `rh.assiduidade` · `recursos-humanos.gerir_funcionarios` |
| DELETE | `/api/rh/funcionarios/{id}/processos-disciplinares/{registoId}` | Remove processo disciplinar. | feature `rh.assiduidade` · `recursos-humanos.gerir_funcionarios` |
| GET | `/api/rh/funcionarios/{id}/formacoes` | Formações frequentadas. | feature `rh.assiduidade` · `recursos-humanos.gerir_formacoes` |
| POST | `/api/rh/funcionarios/{id}/formacoes` | Regista formação. | feature `rh.assiduidade` · `recursos-humanos.gerir_formacoes` |
| PUT | `/api/rh/funcionarios/{id}/formacoes/{registoId}` | Actualiza formação. | feature `rh.assiduidade` · `recursos-humanos.gerir_formacoes` |
| DELETE | `/api/rh/funcionarios/{id}/formacoes/{registoId}` | Remove formação. | feature `rh.assiduidade` · `recursos-humanos.gerir_formacoes` |
| POST | `/api/rh/funcionarios/{id}/formacoes/{registoId}/upload` | Carrega certificado da formação. | feature `rh.assiduidade` · `recursos-humanos.gerir_formacoes` |
| GET | `/api/rh/funcionarios/{id}/formacoes/{registoId}/download` | Descarrega certificado da formação. | feature `rh.assiduidade` · `recursos-humanos.gerir_formacoes` |
| GET | `/api/rh/contratos` | Contratos de trabalho. | feature `rh.assiduidade` · `recursos-humanos.ver_funcionarios` |
| GET | `/api/rh/contratos/{id}` | Detalhe de contrato. | feature `rh.assiduidade` · `recursos-humanos.ver_funcionarios` |
| GET | `/api/rh/contratos/{id}/download` | Descarrega o ficheiro carregado do contrato. | feature `rh.assiduidade` · `recursos-humanos.ver_funcionarios` |
| GET | `/api/rh/contratos/{id}/pdf` | PDF gerado do contrato. | feature `rh.assiduidade` · `recursos-humanos.ver_funcionarios` |
| POST | `/api/rh/contratos` | Cria contrato. | feature `rh.assiduidade` · `recursos-humanos.gerir_contratos` |
| PUT | `/api/rh/contratos/{id}` | Actualiza contrato. | feature `rh.assiduidade` · `recursos-humanos.gerir_contratos` |
| POST | `/api/rh/contratos/{id}/renovar` | Renova contrato. | feature `rh.assiduidade` · `recursos-humanos.gerir_contratos` |
| POST | `/api/rh/contratos/{id}/rescindir` | Rescinde contrato. | feature `rh.assiduidade` · `recursos-humanos.gerir_contratos` |
| POST | `/api/rh/contratos/{id}/upload` | Carrega ficheiro assinado do contrato. | feature `rh.assiduidade` · `recursos-humanos.gerir_contratos` |
| POST | `/api/rh/contratos/{id}/pdf` | Guarda o PDF gerado no frontend. | feature `rh.assiduidade` · `recursos-humanos.gerir_contratos` |
| POST | `/api/rh/contratos/{id}/enviar-para-assinatura` | Envia contrato para assinatura digital. | feature `rh.assiduidade` · `recursos-humanos.gerir_contratos` |
| GET | `/api/rh/ausencias` | Pedidos de ausência/férias. | feature `rh.assiduidade` · `recursos-humanos.ver_funcionarios` |
| POST | `/api/rh/ausencias` | Regista ausência (pelo RH). | feature `rh.assiduidade` · `recursos-humanos.aprovar_ausencias` |
| POST | `/api/rh/ausencias/{id}/aprovar` | Aprova ausência. | feature `rh.assiduidade` · `recursos-humanos.aprovar_ausencias` |
| POST | `/api/rh/ausencias/{id}/rejeitar` | Rejeita ausência. | feature `rh.assiduidade` · `recursos-humanos.aprovar_ausencias` |
| POST | `/api/rh/ausencias/{id}/gozar` | Marca ausência como gozada (desconta saldo). | feature `rh.assiduidade` · `recursos-humanos.aprovar_ausencias` |
| POST | `/api/rh/ausencias/{id}/cancelar` | Cancela ausência. | feature `rh.assiduidade` · `recursos-humanos.aprovar_ausencias` |
| GET | `/api/rh/correcoes-ponto` | Pedidos de correcção de ponto por aprovar (modelo antigo, `rh.presencas`). | feature `rh.assiduidade` · `assiduidade.aprovar_correcao` |
| POST | `/api/rh/correcoes-ponto/{id}/aprovar` | Aprova correcção de ponto. | feature `rh.assiduidade` · `assiduidade.aprovar_correcao` |
| POST | `/api/rh/correcoes-ponto/{id}/rejeitar` | Rejeita correcção de ponto. | feature `rh.assiduidade` · `assiduidade.aprovar_correcao` |
| GET | `/api/rh/tipos-evento` | Tipos de evento de assiduidade (entrada, saída, pausa…). | feature `rh.assiduidade` · `recursos-humanos.ver_funcionarios` |
| POST | `/api/rh/tipos-evento` | Cria tipo de evento. | feature `rh.assiduidade` · `assiduidade.gerir_configuracao` |
| PUT | `/api/rh/tipos-evento/{id}` | Actualiza tipo de evento. | feature `rh.assiduidade` · `assiduidade.gerir_configuracao` |
| DELETE | `/api/rh/tipos-evento/{id}` | Remove tipo de evento. | feature `rh.assiduidade` · `assiduidade.gerir_configuracao` |
| GET | `/api/rh/metodos-marcacao` | Métodos de marcação (facial, QR, NFC, PIN, GPS…). | feature `rh.assiduidade` · `recursos-humanos.ver_funcionarios` |
| POST | `/api/rh/metodos-marcacao` | Cria método de marcação. | feature `rh.assiduidade` · `assiduidade.gerir_configuracao` |
| PUT | `/api/rh/metodos-marcacao/{id}` | Actualiza método. | feature `rh.assiduidade` · `assiduidade.gerir_configuracao` |
| DELETE | `/api/rh/metodos-marcacao/{id}` | Remove método. | feature `rh.assiduidade` · `assiduidade.gerir_configuracao` |
| GET | `/api/rh/tipos-regra` | Tipos de regra disponíveis no motor de assiduidade. | feature `rh.assiduidade` · `recursos-humanos.ver_funcionarios` |
| GET | `/api/rh/regras` | Regras de assiduidade configuradas (tolerâncias, horas extra…). | feature `rh.assiduidade` · `assiduidade.ver_configuracao` |
| POST | `/api/rh/regras` | Cria regra. | feature `rh.assiduidade` · `assiduidade.gerir_configuracao` |
| PUT | `/api/rh/regras/{id}` | Actualiza regra. | feature `rh.assiduidade` · `assiduidade.gerir_configuracao` |
| DELETE | `/api/rh/regras/{id}` | Remove regra. | feature `rh.assiduidade` · `assiduidade.gerir_configuracao` |
| POST | `/api/rh/eventos` | Regista evento de assiduidade manual. | feature `rh.assiduidade` · `recursos-humanos.gerir_funcionarios` |
| POST | `/api/rh/assiduidade/ponto` | Gestor marca ponto em nome de um funcionário. | feature `rh.assiduidade` · `recursos-humanos.gerir_funcionarios` |
| POST | `/api/rh/assiduidade/biometric/enroll` | Regista o rosto do funcionário no FaceClock (rota alternativa). | feature `rh.assiduidade` · `recursos-humanos.gerir_funcionarios` |
| POST | `/api/rh/assiduidade/fingerprint/enroll` | Regista impressão digital do funcionário. | feature `rh.assiduidade` · `recursos-humanos.gerir_funcionarios` |
| POST | `/api/rh/assiduidade/fingerprint/identify` | Identifica funcionário pela impressão digital. | feature `rh.assiduidade` · `recursos-humanos.gerir_funcionarios` |
| DELETE | `/api/rh/assiduidade/fingerprint/enroll/{user_id}` | Apaga o registo de impressão digital. | feature `rh.assiduidade` · `recursos-humanos.gerir_funcionarios` |
| POST | `/api/rh/assiduidade/qr/gerar` | Gera QR de marcação para um dispositivo/local. | feature `rh.assiduidade` · `recursos-humanos.ver_funcionarios` |
| POST | `/api/rh/correcoes` | Cria correcção de evento (modelo novo, `eventos_assiduidade`). | feature `rh.assiduidade` · `recursos-humanos.gerir_funcionarios` |
| GET | `/api/rh/correcoes` | Correcções de evento por aprovar. | feature `rh.assiduidade` · `assiduidade.aprovar_correcao` |
| POST | `/api/rh/correcoes/{id}/aprovar` | Aprova correcção de evento. | feature `rh.assiduidade` · `assiduidade.aprovar_correcao` |
| POST | `/api/rh/correcoes/{id}/rejeitar` | Rejeita correcção de evento. | feature `rh.assiduidade` · `assiduidade.aprovar_correcao` |
| GET | `/api/rh/justificacoes` | Justificações de falta por aprovar. | feature `rh.assiduidade` · `assiduidade.aprovar_correcao` |
| POST | `/api/rh/justificacoes/{id}/aprovar` | Aprova justificação. | feature `rh.assiduidade` · `assiduidade.aprovar_correcao` |
| POST | `/api/rh/justificacoes/{id}/rejeitar` | Rejeita justificação. | feature `rh.assiduidade` · `assiduidade.aprovar_correcao` |
| GET | `/api/rh/tipos-ausencia` | Tipos de ausência (férias, doença, luto…). | feature `rh.assiduidade` · `recursos-humanos.ver_funcionarios` |
| POST | `/api/rh/tipos-ausencia` | Cria tipo de ausência. | feature `rh.assiduidade` · `recursos-humanos.gerir_funcionarios` |
| PUT | `/api/rh/tipos-ausencia/{id}` | Actualiza tipo de ausência. | feature `rh.assiduidade` · `recursos-humanos.gerir_funcionarios` |
| DELETE | `/api/rh/tipos-ausencia/{id}` | Remove tipo de ausência. | feature `rh.assiduidade` · `recursos-humanos.gerir_funcionarios` |
| GET | `/api/rh/avaliacoes` | Avaliações de desempenho. | feature `rh.assiduidade` · `recursos-humanos.ver_funcionarios` |
| POST | `/api/rh/avaliacoes` | Cria avaliação. | feature `rh.assiduidade` · `recursos-humanos.gerir_avaliacoes` |
| POST | `/api/rh/avaliacoes/{id}/submeter` | Submete avaliação para aprovação. | feature `rh.assiduidade` · `recursos-humanos.gerir_avaliacoes` |
| POST | `/api/rh/avaliacoes/{id}/aprovar` | Aprova avaliação. | feature `rh.assiduidade` · `recursos-humanos.gerir_avaliacoes` |
| GET | `/api/rh/criterios-avaliacao` | Critérios de avaliação. | feature `rh.assiduidade` · `recursos-humanos.ver_funcionarios` |
| POST | `/api/rh/criterios-avaliacao` | Cria critério. | feature `rh.assiduidade` · `recursos-humanos.gerir_avaliacoes` |
| PUT | `/api/rh/criterios-avaliacao/{id}` | Actualiza critério. | feature `rh.assiduidade` · `recursos-humanos.gerir_avaliacoes` |
| DELETE | `/api/rh/criterios-avaliacao/{id}` | Remove critério. | feature `rh.assiduidade` · `recursos-humanos.gerir_avaliacoes` |
| GET | `/api/rh/periodos` | Períodos de processamento salarial. | feature `rh.assiduidade` · `recursos-humanos.ver_funcionarios` |
| POST | `/api/rh/periodos` | Cria período salarial. | feature `rh.assiduidade` · `recursos-humanos.processar_salarios` |
| PUT | `/api/rh/periodos/{id}` | Actualiza período salarial. | feature `rh.assiduidade` · `recursos-humanos.processar_salarios` |
| GET | `/api/rh/cargos` | Cargos/funções profissionais (usados também em vagas). | feature `rh.assiduidade` · `recursos-humanos.ver_funcionarios` ou `recrutamento.gerir_vagas` |
| POST | `/api/rh/cargos` | Cria cargo profissional. | feature `rh.assiduidade` · `recursos-humanos.gerir_funcionarios` |
| PUT | `/api/rh/cargos/{id}` | Actualiza cargo profissional. | feature `rh.assiduidade` · `recursos-humanos.gerir_funcionarios` |
| DELETE | `/api/rh/cargos/{id}` | Remove cargo profissional. | feature `rh.assiduidade` · `recursos-humanos.gerir_funcionarios` |
| GET | `/api/rh/horarios` | Horários de trabalho. | feature `rh.assiduidade` · `recursos-humanos.ver_funcionarios` |
| POST | `/api/rh/horarios` | Cria horário. | feature `rh.assiduidade` · `recursos-humanos.gerir_horarios` |
| PUT | `/api/rh/horarios/{id}` | Actualiza horário. | feature `rh.assiduidade` · `recursos-humanos.gerir_horarios` |
| DELETE | `/api/rh/horarios/{id}` | Remove horário. | feature `rh.assiduidade` · `recursos-humanos.gerir_horarios` |
| GET | `/api/rh/componentes-salariais` | Catálogo de componentes salariais. | feature `rh.assiduidade` · `recursos-humanos.ver_funcionarios` |
| POST | `/api/rh/componentes-salariais` | Cria componente salarial. | feature `rh.assiduidade` · `recursos-humanos.processar_salarios` |
| PUT | `/api/rh/componentes-salariais/{id}` | Actualiza componente. | feature `rh.assiduidade` · `recursos-humanos.processar_salarios` |
| DELETE | `/api/rh/componentes-salariais/{id}` | Remove componente. | feature `rh.assiduidade` · `recursos-humanos.processar_salarios` |
| GET | `/api/rh/beneficios` | Catálogo de benefícios. | feature `rh.assiduidade` · `recursos-humanos.ver_beneficios` |
| POST | `/api/rh/beneficios` | Cria benefício. | feature `rh.assiduidade` · `recursos-humanos.gerir_beneficios` |
| PUT | `/api/rh/beneficios/{id}` | Actualiza benefício. | feature `rh.assiduidade` · `recursos-humanos.gerir_beneficios` |
| DELETE | `/api/rh/beneficios/{id}` | Remove benefício. | feature `rh.assiduidade` · `recursos-humanos.gerir_beneficios` |
| GET | `/api/rh/formacoes` | Catálogo de formações. | feature `rh.assiduidade` · `recursos-humanos.ver_funcionarios` |
| POST | `/api/rh/formacoes` | Cria formação. | feature `rh.assiduidade` · `recursos-humanos.gerir_formacoes` |
| PUT | `/api/rh/formacoes/{id}` | Actualiza formação. | feature `rh.assiduidade` · `recursos-humanos.gerir_formacoes` |
| DELETE | `/api/rh/formacoes/{id}` | Remove formação. | feature `rh.assiduidade` · `recursos-humanos.gerir_formacoes` |
| GET | `/api/rh/folhas-pagamento` | Folhas de pagamento (processamentos salariais). | feature `rh.assiduidade` · `recursos-humanos.ver_salarios` |
| GET | `/api/rh/folhas-pagamento/{id}` | Detalhe da folha (linhas por funcionário). | feature `rh.assiduidade` · `recursos-humanos.ver_salarios` |
| GET | `/api/rh/folhas-pagamento/{id}/exportar-bancario` | Exporta ficheiro de transferências para o banco. | feature `rh.assiduidade` · `recursos-humanos.ver_salarios` |
| POST | `/api/rh/folhas-pagamento` | Cria folha para um período. | feature `rh.assiduidade` · `recursos-humanos.processar_salarios` |
| POST | `/api/rh/folhas-pagamento/{id}/processar` | Calcula salários (IRPS, INSS, componentes, faltas) e gera recibos. | feature `rh.assiduidade` · `recursos-humanos.processar_salarios` |
| POST | `/api/rh/folhas-pagamento/{id}/pagar` | Marca a folha como paga. | feature `rh.assiduidade` · `recursos-humanos.processar_salarios` |
| POST | `/api/rh/folhas-pagamento/{id}/cancelar` | Cancela a folha. | feature `rh.assiduidade` · `recursos-humanos.processar_salarios` |
| GET | `/api/rh/recibos-vencimento/{id}` | Detalhe de recibo de vencimento. | feature `rh.assiduidade` · `recursos-humanos.ver_recibos` |
| GET | `/api/rh/recibos-vencimento/{id}/pdf` | PDF do recibo de vencimento. | feature `rh.assiduidade` · `recursos-humanos.ver_recibos` |
| POST | `/api/rh/recibos-vencimento/{id}/pdf` | Guarda o PDF do recibo gerado no frontend. | feature `rh.assiduidade` · `recursos-humanos.ver_recibos` |
| POST | `/api/rh/contactos-emergencia` | Adiciona contacto de emergência. | feature `rh.assiduidade` · `recursos-humanos.gerir_funcionarios` |
| DELETE | `/api/rh/contactos-emergencia/{id}` | Remove contacto de emergência. | feature `rh.assiduidade` · `recursos-humanos.gerir_funcionarios` |
| GET | `/api/rh/documentos/{id}/download` | Descarrega documento do funcionário. | feature `rh.assiduidade` · `recursos-humanos.ver_funcionarios` |
| POST | `/api/rh/documentos` | Regista documento do funcionário (BI, NUIT…). | feature `rh.assiduidade` · `recursos-humanos.gerir_funcionarios` |
| POST | `/api/rh/documentos/{id}/upload` | Carrega o ficheiro do documento. | feature `rh.assiduidade` · `recursos-humanos.gerir_funcionarios` |
| DELETE | `/api/rh/documentos/{id}` | Remove documento. | feature `rh.assiduidade` · `recursos-humanos.gerir_funcionarios` |

## Área do funcionário (`/api/self-service`)

O que o próprio funcionário faz na app: marcar ponto (facial com prova de vida, QR), ver assiduidade e recibos, pedir correcções/justificações, chat e perfil.

| Método | Rota | O que faz | Acesso |
|---|---|---|---|
| GET | `/api/self-service/home` | Página inicial do funcionário (resumo, avisos, comunicados). | `perfil.ver_perfil` |
| POST | `/api/self-service/notificacoes/lida` | Marca notificação como lida. | `perfil.editar_perfil` |
| POST | `/api/self-service/comunicados/lido` | Marca comunicado como lido. | `perfil.editar_perfil` |
| GET | `/api/self-service/chat/conversas` | Conversas do chat interno. | `chat.ver_conversas` |
| GET | `/api/self-service/chat/conversas/{id}/mensagens` | Mensagens de uma conversa. | `chat.ver_conversas` |
| POST | `/api/self-service/chat/conversas` | Inicia conversa. | `chat.enviar_mensagem` |
| POST | `/api/self-service/chat/conversas/{id}/mensagens` | Envia mensagem no chat. | `chat.enviar_mensagem` |
| GET | `/api/self-service/assiduidade` | Marcações do próprio funcionário. | `assiduidade.ver_assiduidade` |
| GET | `/api/self-service/assiduidade/resumo` | Resumo mensal (horas, atrasos, faltas). | `assiduidade.ver_assiduidade` |
| GET | `/api/self-service/assiduidade/metodos` | Métodos de marcação disponíveis para o funcionário. | `assiduidade.ver_assiduidade` |
| GET | `/api/self-service/assiduidade/justificacoes` | Justificações submetidas. | `assiduidade.ver_assiduidade` |
| GET | `/api/self-service/assiduidade/qr/me` | Gera o QR pessoal do funcionário (para ser lido por um gestor). | `assiduidade.ver_assiduidade` |
| POST | `/api/self-service/assiduidade/biometria/facial/verificar` | Verifica o rosto (FaceClock) antes de marcar ponto. Duas rotas, mesmo handler. | `assiduidade.ver_assiduidade` |
| POST | `/api/self-service/assiduidade/biometric/verify` | Verifica o rosto (FaceClock) antes de marcar ponto. Duas rotas, mesmo handler. | `assiduidade.ver_assiduidade` |
| POST | `/api/self-service/assiduidade/biometric/liveness/challenge` | Pede desafio de prova de vida (piscar, virar a cabeça). Duas rotas, mesmo handler. | `assiduidade.ver_assiduidade` |
| POST | `/api/self-service/assiduidade/biometric/liveness/verify` | Valida a resposta ao desafio de prova de vida. Duas rotas, mesmo handler. | `assiduidade.ver_assiduidade` |
| POST | `/api/self-service/assiduidade/biometria/facial/liveness/challenge` | Pede desafio de prova de vida (piscar, virar a cabeça). Duas rotas, mesmo handler. | `assiduidade.ver_assiduidade` |
| POST | `/api/self-service/assiduidade/biometria/facial/liveness/verify` | Valida a resposta ao desafio de prova de vida. Duas rotas, mesmo handler. | `assiduidade.ver_assiduidade` |
| POST | `/api/self-service/assiduidade/qr/validar` | Gestor/RH lê o QR pessoal de um funcionário e regista o ponto em nome dele. | `recursos-humanos.gerir_funcionarios` |
| POST | `/api/self-service/assiduidade/ponto` | Funcionário marca ponto (entrada/saída) com o método validado. | `assiduidade.marcar_ponto` |
| POST | `/api/self-service/assiduidade/ponto/batch` | Sincroniza as marcações feitas offline na app (só PIN e impressão digital, hora do telemóvel até 72h, idempotente por `idempotency_key`). | `assiduidade.marcar_ponto` · rate limit |
| POST | `/api/self-service/assiduidade/justificacoes` | Funcionário justifica falta/atraso. | `assiduidade.justificar` |
| POST | `/api/self-service/assiduidade/correcoes` | Funcionário pede correcção de uma marcação. | `assiduidade.corrigir_ponto` |
| GET | `/api/self-service/assiduidade/correcoes` | Pedidos de correcção do funcionário. | `assiduidade.corrigir_ponto` |
| POST | `/api/self-service/assiduidade/correcoes/{id}/cancelar` | Cancela pedido de correcção. | `assiduidade.corrigir_ponto` |
| GET | `/api/self-service/recibos` | Recibos de vencimento do próprio funcionário. | autenticado |
| GET | `/api/self-service/recibos/{id}` | Detalhe do recibo. | autenticado |
| GET | `/api/self-service/recibos/{id}/pdf` | PDF do recibo. | autenticado |
| POST | `/api/self-service/recibos/{id}/pdf` | Guarda o PDF do recibo gerado no frontend. | autenticado |
| GET | `/api/self-service/perfil` | Perfil do funcionário. | `perfil.ver_perfil` |
| GET | `/api/self-service/perfil/documentos` | Documentos do funcionário. | `perfil.ver_perfil` |
| PUT | `/api/self-service/perfil` | Actualiza dados pessoais. | `perfil.editar_perfil` |
| POST | `/api/self-service/perfil/senha` | Altera senha. | `perfil.editar_perfil` |

## Pedidos de férias (`/api/pedido-ferias`)

O funcionário pede e cancela as suas próprias férias/ausências.

| Método | Rota | O que faz | Acesso |
|---|---|---|---|
| GET | `/api/pedido-ferias` | Pedidos de férias do próprio funcionário. | `pedido-ferias.ver_pedidos` |
| GET | `/api/pedido-ferias/tipos` | Tipos de ausência que o funcionário pode pedir. | `pedido-ferias.ver_pedidos` |
| POST | `/api/pedido-ferias` | Funcionário pede férias/ausência. | `pedido-ferias.submeter_pedido` |
| POST | `/api/pedido-ferias/{id}/cancelar` | Funcionário cancela o pedido. | `pedido-ferias.submeter_pedido` |

## Recrutamento, área interna (`/api/recrutamento`)

Gestão de vagas, pipeline de candidaturas, entrevistas, contratação e configuração de formulários.

| Método | Rota | O que faz | Acesso |
|---|---|---|---|
| GET | `/api/recrutamento/dashboard` | Painel do recrutamento (vagas, candidaturas por estado). | `recrutamento.ver_vagas` |
| GET | `/api/recrutamento/vagas` | Vagas (internas). | `recrutamento.ver_vagas` |
| GET | `/api/recrutamento/vagas/{id}` | Detalhe de vaga. | `recrutamento.ver_vagas` |
| POST | `/api/recrutamento/vagas` | Cria vaga. | `recrutamento.gerir_vagas` |
| PUT | `/api/recrutamento/vagas/{id}` | Actualiza vaga. | `recrutamento.gerir_vagas` |
| DELETE | `/api/recrutamento/vagas/{id}` | Remove vaga. | `recrutamento.gerir_vagas` |
| POST | `/api/recrutamento/vagas/{id}/activar` | Publica/abre a vaga. | `recrutamento.gerir_vagas` |
| POST | `/api/recrutamento/vagas/{id}/desactivar` | Fecha a vaga. | `recrutamento.gerir_vagas` |
| GET | `/api/recrutamento/candidaturas` | Candidaturas recebidas. | `recrutamento.ver_candidaturas` |
| GET | `/api/recrutamento/candidaturas/{id}` | Detalhe de candidatura. | `recrutamento.ver_candidaturas` |
| GET | `/api/recrutamento/candidaturas/{id}/cv` | Descarrega o CV do candidato. | `recrutamento.ver_candidaturas` |
| GET | `/api/recrutamento/candidaturas/{id}/carta` | Descarrega a carta de apresentação. | `recrutamento.ver_candidaturas` |
| PUT | `/api/recrutamento/candidaturas/{id}/estado` | Muda a fase da candidatura no pipeline (triagem → entrevista → …). | `recrutamento.gerir_candidaturas` |
| POST | `/api/recrutamento/candidaturas/{id}/avaliar` | Regista avaliação/pontuação do candidato. | `recrutamento.gerir_candidaturas` |
| POST | `/api/recrutamento/candidaturas/{id}/entrevista` | Agenda entrevista (notifica o candidato). | `recrutamento.gerir_candidaturas` |
| POST | `/api/recrutamento/candidaturas/{id}/notas` | Nota interna sobre a candidatura. | `recrutamento.gerir_candidaturas` |
| POST | `/api/recrutamento/candidaturas/{id}/contratar` | Contrata: converte o candidato em funcionário no RH. | `recrutamento.contratar` ou `recrutamento.gerir_candidaturas` |
| POST | `/api/recrutamento/candidaturas/{id}/enviar-para-assinatura` | Envia documento da contratação para assinatura digital. | `recrutamento.contratar` ou `recrutamento.gerir_candidaturas` |
| GET | `/api/recrutamento/contactos` | Mensagens do formulário de contacto público. | `recrutamento.ver_candidaturas` |
| POST | `/api/recrutamento/contactos/{id}/lido` | Marca mensagem de contacto como lida. | `recrutamento.gerir_candidaturas` |
| GET | `/api/recrutamento/vagas/{vagaID}/campos` | Campos extra do formulário de uma vaga. | `recrutamento.configurar_recrutamento` |
| POST | `/api/recrutamento/vagas/{vagaID}/campos` | Adiciona campo extra à vaga. | `recrutamento.configurar_recrutamento` |
| PUT | `/api/recrutamento/vagas/{vagaID}/campos/{campoID}` | Actualiza campo da vaga. | `recrutamento.configurar_recrutamento` |
| DELETE | `/api/recrutamento/vagas/{vagaID}/campos/{campoID}` | Remove campo da vaga. | `recrutamento.configurar_recrutamento` |
| GET | `/api/recrutamento/campos-custom` | Campos personalizados globais das candidaturas. | `recrutamento.configurar_recrutamento` |
| POST | `/api/recrutamento/campos-custom` | Cria campo personalizado. | `recrutamento.configurar_recrutamento` |
| PUT | `/api/recrutamento/campos-custom/{id}` | Actualiza campo personalizado. | `recrutamento.configurar_recrutamento` |
| DELETE | `/api/recrutamento/campos-custom/{id}` | Remove campo personalizado. | `recrutamento.configurar_recrutamento` |
| GET | `/api/recrutamento/config-notificacoes` | Configuração de notificações do recrutamento. | `recrutamento.configurar_recrutamento` |
| PUT | `/api/recrutamento/config-notificacoes` | Grava configuração de notificações. | `recrutamento.configurar_recrutamento` |

## Recrutamento, área pública (`/api/public/recrutamento`, `/vagas`, `/candidaturas`)

Portal de carreiras e conta de candidato. As listagens são públicas; a área `/candidatos/*` usa a sessão própria do candidato.

| Método | Rota | O que faz | Acesso |
|---|---|---|---|
| GET | `/api/public/recrutamento/vagas` | Vagas abertas (página pública de carreiras). | **público** |
| GET | `/api/public/recrutamento/vagas/abertas` | Número de vagas abertas. | **público** |
| GET | `/api/public/recrutamento/vagas/{id}` | Detalhe público de vaga. | **público** |
| GET | `/api/public/recrutamento/campos-custom` | Campos do formulário de candidatura (público). | **público** |
| POST | `/api/public/recrutamento/candidaturas` | Submete candidatura (com CV); devolve código de acompanhamento. | **público** · rate limit |
| GET | `/api/public/recrutamento/candidaturas/{codigo}` | Consulta estado da candidatura pelo código. | **público** |
| POST | `/api/public/recrutamento/candidatos/registar` | Cria conta de candidato. | **público** · rate limit |
| POST | `/api/public/recrutamento/candidatos/logout` | Termina sessão do candidato. | **público** |
| POST | `/api/public/recrutamento/contacto` | Formulário de contacto público. | **público** · rate limit |
| GET | `/api/public/recrutamento/candidatos/perfil` | Perfil do candidato autenticado. | sessão de candidato |
| PUT | `/api/public/recrutamento/candidatos/perfil` | Candidato actualiza o perfil. | sessão de candidato |
| GET | `/api/public/recrutamento/candidatos/candidaturas` | Candidaturas do candidato. | sessão de candidato |
| GET | `/api/public/recrutamento/candidatos/conversas` | Conversas do candidato com o RH. | sessão de candidato |
| GET | `/api/public/recrutamento/candidatos/candidaturas/{id}/mensagens` | Mensagens de uma candidatura. | sessão de candidato |
| POST | `/api/public/recrutamento/candidatos/candidaturas/{id}/mensagens` | Candidato envia mensagem ao RH. | sessão de candidato |
| POST | `/api/public/recrutamento/candidatos/push-token` | Regista token push da app do candidato. | sessão de candidato |
| GET | `/api/public/recrutamento/candidatos/experiencias` | Experiência profissional do candidato. | sessão de candidato |
| POST | `/api/public/recrutamento/candidatos/experiencias` | Adiciona experiência. | sessão de candidato |
| PUT | `/api/public/recrutamento/candidatos/experiencias/{id}` | Actualiza experiência. | sessão de candidato |
| DELETE | `/api/public/recrutamento/candidatos/experiencias/{id}` | Remove experiência. | sessão de candidato |
| GET | `/api/public/recrutamento/candidatos/formacoes` | Formação académica do candidato. | sessão de candidato |
| POST | `/api/public/recrutamento/candidatos/formacoes` | Adiciona formação. | sessão de candidato |
| PUT | `/api/public/recrutamento/candidatos/formacoes/{id}` | Actualiza formação. | sessão de candidato |
| DELETE | `/api/public/recrutamento/candidatos/formacoes/{id}` | Remove formação. | sessão de candidato |
| GET | `/api/public/recrutamento/candidatos/notificacoes` | Notificações do candidato. | sessão de candidato |
| PUT | `/api/public/recrutamento/candidatos/notificacoes/lidas` | Marca todas como lidas. | sessão de candidato |
| PUT | `/api/public/recrutamento/candidatos/notificacoes/{id}/lida` | Marca uma como lida. | sessão de candidato |
| GET | `/vagas` | Alias público curto de `/api/public/recrutamento/vagas`. | **público** |
| GET | `/vagas/abertas` | Alias de `/api/public/recrutamento/vagas/abertas`. | **público** |
| GET | `/vagas/{id}` | Alias de `/api/public/recrutamento/vagas/{id}`. | **público** |
| POST | `/candidaturas` | Alias de `/api/public/recrutamento/candidaturas`. | **público** · rate limit |
| GET | `/candidaturas/{codigo}` | Alias de `/api/public/recrutamento/candidaturas/{codigo}`. | **público** |

## Gestão escolar (`/api/escolar`)

Módulo escolar completo: estrutura (anos, níveis, cursos, turmas, disciplinas, currículo), alunos, matrículas, presenças, avaliações e notas, propinas e pagamentos, biblioteca, horários, calendário, ocorrências e gestão dos portais.

| Método | Rota | O que faz | Acesso |
|---|---|---|---|
| POST | `/api/escolar/payments/callback` | Webhook do gateway de pagamento (NexoraPay) a confirmar pagamento de propina. Sem login, com rate limit. | **público** · rate limit |
| GET | `/api/escolar/years` | Anos lectivos. | `gestao-escolar.ver` |
| GET | `/api/escolar/years/{id}` | Detalhe de ano lectivo. | `gestao-escolar.ver` |
| GET | `/api/escolar/terms` | Períodos lectivos (trimestres/semestres). | `gestao-escolar.ver` |
| GET | `/api/escolar/classes` | Turmas. | `gestao-escolar.ver` |
| GET | `/api/escolar/classes/{id}` | Detalhe de turma. | `gestao-escolar.ver` |
| GET | `/api/escolar/subjects` | Disciplinas. | `gestao-escolar.ver` |
| GET | `/api/escolar/subjects/{id}` | Detalhe de disciplina. | `gestao-escolar.ver` |
| GET | `/api/escolar/students` | Alunos. | `gestao-escolar.ver` |
| GET | `/api/escolar/students/{id}` | Ficha do aluno. | `gestao-escolar.ver` |
| GET | `/api/escolar/enrollments` | Matrículas. | `gestao-escolar.ver` |
| GET | `/api/escolar/enrollments/{id}` | Detalhe de matrícula. | `gestao-escolar.ver` |
| GET | `/api/escolar/student-roles` | Cargos de alunos (chefe de turma, delegado…). | `gestao-escolar.ver` |
| GET | `/api/escolar/teacher-roles` | Cargos de professores (director de turma, coordenador…). | `gestao-escolar.ver` |
| GET | `/api/escolar/cargo-permissoes` | Permissões associadas aos cargos escolares. | `gestao-escolar.ver` |
| GET | `/api/escolar/attendance` | Registos de presença dos alunos. | `gestao-escolar.ver` |
| GET | `/api/escolar/attendance/{id}` | Detalhe de registo de presença. | `gestao-escolar.ver` |
| GET | `/api/escolar/grades` | Notas lançadas. | `gestao-escolar.ver` |
| GET | `/api/escolar/grades/{id}` | Detalhe de nota. | `gestao-escolar.ver` |
| GET | `/api/escolar/grade-items` | Itens de avaliação (testes, trabalhos) com pesos. | `gestao-escolar.ver` |
| GET | `/api/escolar/fee-plans` | Planos de propinas. | `gestao-escolar.ver` |
| GET | `/api/escolar/fee-plans/{id}` | Detalhe de plano de propinas. | `gestao-escolar.ver` |
| GET | `/api/escolar/student-invoices` | Cobranças (facturas de propina) dos alunos. | `gestao-escolar.ver` |
| GET | `/api/escolar/student-invoices/{id}` | Detalhe de cobrança. | `gestao-escolar.ver` |
| GET | `/api/escolar/payments/{id}` | Detalhe de pagamento escolar. | `gestao-escolar.ver` |
| GET | `/api/escolar/payments/{id}/receipt` | Recibo de um pagamento escolar. | `gestao-escolar.ver` |
| GET | `/api/escolar/library/books` | Livros da biblioteca. | `gestao-escolar.ver` |
| GET | `/api/escolar/library/loans` | Empréstimos de livros. | `gestao-escolar.ver` |
| GET | `/api/escolar/messages` | Comunicados/mensagens da escola. | `gestao-escolar.ver` |
| GET | `/api/escolar/notificacoes` | Notificações escolares. | `gestao-escolar.ver` |
| GET | `/api/escolar/teachers` | Professores. | `gestao-escolar.ver` |
| GET | `/api/escolar/teachers/{id}` | Ficha do professor. | `gestao-escolar.ver` |
| GET | `/api/escolar/levels` | Níveis de ensino (primário, secundário…). | `gestao-escolar.ver` |
| GET | `/api/escolar/levels/{id}` | Detalhe de nível de ensino. | `gestao-escolar.ver` |
| GET | `/api/escolar/cycles` | Ciclos de ensino. | `gestao-escolar.ver` |
| GET | `/api/escolar/cycles/{id}` | Detalhe de ciclo. | `gestao-escolar.ver` |
| GET | `/api/escolar/series` | Séries/classes (1ª, 2ª…). | `gestao-escolar.ver` |
| GET | `/api/escolar/series/{id}` | Detalhe de série. | `gestao-escolar.ver` |
| GET | `/api/escolar/courses` | Cursos. | `gestao-escolar.ver` |
| GET | `/api/escolar/courses/{id}` | Detalhe de curso. | `gestao-escolar.ver` |
| GET | `/api/escolar/course-subjects` | Currículo: disciplinas por curso/série. | `gestao-escolar.ver` |
| GET | `/api/escolar/course-subjects/{id}` | Detalhe de item do currículo. | `gestao-escolar.ver` |
| GET | `/api/escolar/course-subjects/{id}/terms` | Períodos em que a disciplina do currículo é leccionada. | `gestao-escolar.ver` |
| GET | `/api/escolar/dashboard` | Painel geral da escola (indicadores). | `gestao-escolar.ver` |
| GET | `/api/escolar/dashboard/direction` | Painel da direcção (indicadores académicos e financeiros). | `gestao-escolar.ver` |
| GET | `/api/escolar/reports/academic-summary` | Relatório: resumo académico (aproveitamento, médias). | `gestao-escolar.ver` ou `gestao-escolar.relatorios` |
| GET | `/api/escolar/reports/financial-summary` | Relatório: resumo financeiro (facturado, recebido). | `gestao-escolar.ver` ou `gestao-escolar.relatorios` |
| GET | `/api/escolar/reports/delinquency` | Relatório: alunos com propinas em atraso. | `gestao-escolar.ver` ou `gestao-escolar.relatorios` |
| GET | `/api/escolar/report-cards/{student_id}` | Boletim de notas de um aluno. | `gestao-escolar.ver` ou `gestao-escolar.relatorios` |
| POST | `/api/escolar/years` | Cria ano lectivo. | `gestao-escolar.gerir_turmas` |
| PUT | `/api/escolar/years/{id}` | Actualiza ano lectivo. | `gestao-escolar.gerir_turmas` |
| POST | `/api/escolar/years/{id}/activar` | Define o ano lectivo como activo. | `gestao-escolar.gerir_turmas` |
| POST | `/api/escolar/years/{id}/close` | Encerra o ano lectivo. | `gestao-escolar.gerir_turmas` |
| POST | `/api/escolar/years/{id}/terms` | Cria período dentro do ano lectivo. | `gestao-escolar.gerir_turmas` |
| PUT | `/api/escolar/terms/{id}` | Actualiza período lectivo. | `gestao-escolar.gerir_turmas` |
| DELETE | `/api/escolar/terms/{id}` | Elimina período lectivo. | `gestao-escolar.gerir_turmas` |
| POST | `/api/escolar/classes` | Cria turma. | `gestao-escolar.gerir_turmas` |
| PUT | `/api/escolar/classes/{id}` | Actualiza turma. | `gestao-escolar.gerir_turmas` |
| POST | `/api/escolar/classes/{id}/assign-teacher` | Define o director de turma. | `gestao-escolar.gerir_turmas` |
| POST | `/api/escolar/subjects` | Cria disciplina. | `gestao-escolar.gerir_turmas` |
| PUT | `/api/escolar/subjects/{id}` | Actualiza disciplina. | `gestao-escolar.gerir_turmas` |
| DELETE | `/api/escolar/subjects/{id}` | Remove disciplina. | `gestao-escolar.gerir_turmas` |
| POST | `/api/escolar/teacher-assignments` | Atribui professor a uma disciplina/turma. | `gestao-escolar.gerir_turmas` |
| POST | `/api/escolar/student-roles` | Atribui cargo a um aluno. | `gestao-escolar.gerir_turmas` |
| PUT | `/api/escolar/student-roles/{id}` | Actualiza cargo de aluno. | `gestao-escolar.gerir_turmas` |
| POST | `/api/escolar/student-roles/{id}/revoke` | Retira cargo a um aluno. | `gestao-escolar.gerir_turmas` |
| POST | `/api/escolar/teacher-roles` | Atribui cargo a um professor. | `gestao-escolar.gerir_turmas` |
| PUT | `/api/escolar/teacher-roles/{id}` | Actualiza cargo de professor. | `gestao-escolar.gerir_turmas` |
| POST | `/api/escolar/teacher-roles/{id}/revoke` | Retira cargo a um professor. | `gestao-escolar.gerir_turmas` |
| POST | `/api/escolar/teachers` | Cria professor. | `gestao-escolar.gerir_turmas` |
| PUT | `/api/escolar/teachers/{id}` | Actualiza professor. | `gestao-escolar.gerir_turmas` |
| DELETE | `/api/escolar/teachers/{id}` | Remove professor. | `gestao-escolar.gerir_turmas` |
| GET | `/api/escolar/teachers/{id}/rh-link` | Mostra a ligação professor ↔ funcionário no RH. | `gestao-escolar.gerir_turmas` |
| POST | `/api/escolar/teachers/{id}/rh-link` | Liga o professor a um funcionário do RH (assiduidade/salário). | `gestao-escolar.gerir_turmas` |
| POST | `/api/escolar/levels` | Cria nível de ensino. | `gestao-escolar.gerir_turmas` |
| PUT | `/api/escolar/levels/{id}` | Actualiza nível de ensino. | `gestao-escolar.gerir_turmas` |
| DELETE | `/api/escolar/levels/{id}` | Remove nível de ensino. | `gestao-escolar.gerir_turmas` |
| POST | `/api/escolar/cycles` | Cria ciclo. | `gestao-escolar.gerir_turmas` |
| PUT | `/api/escolar/cycles/{id}` | Actualiza ciclo. | `gestao-escolar.gerir_turmas` |
| DELETE | `/api/escolar/cycles/{id}` | Remove ciclo. | `gestao-escolar.gerir_turmas` |
| POST | `/api/escolar/series` | Cria série. | `gestao-escolar.gerir_turmas` |
| PUT | `/api/escolar/series/{id}` | Actualiza série. | `gestao-escolar.gerir_turmas` |
| DELETE | `/api/escolar/series/{id}` | Remove série. | `gestao-escolar.gerir_turmas` |
| POST | `/api/escolar/courses` | Cria curso. | `gestao-escolar.gerir_turmas` |
| PUT | `/api/escolar/courses/{id}` | Actualiza curso. | `gestao-escolar.gerir_turmas` |
| DELETE | `/api/escolar/courses/{id}` | Remove curso. | `gestao-escolar.gerir_turmas` |
| POST | `/api/escolar/course-subjects` | Adiciona disciplina ao currículo. | `gestao-escolar.gerir_turmas` |
| PUT | `/api/escolar/course-subjects/{id}` | Actualiza item do currículo. | `gestao-escolar.gerir_turmas` |
| DELETE | `/api/escolar/course-subjects/{id}` | Remove item do currículo. | `gestao-escolar.gerir_turmas` |
| POST | `/api/escolar/course-subjects/{id}/terms` | Define período em que a disciplina é leccionada. | `gestao-escolar.gerir_turmas` |
| PUT | `/api/escolar/course-subjects/{id}/terms/{termId}` | Actualiza período da disciplina. | `gestao-escolar.gerir_turmas` |
| DELETE | `/api/escolar/course-subjects/{id}/terms/{termId}` | Remove período da disciplina. | `gestao-escolar.gerir_turmas` |
| POST | `/api/escolar/students` | Cria aluno. | `gestao-escolar.gerir_alunos` |
| PUT | `/api/escolar/students/{id}` | Actualiza ficha do aluno. | `gestao-escolar.gerir_alunos` |
| POST | `/api/escolar/students/{id}/guardians` | Associa encarregado de educação ao aluno. | `gestao-escolar.gerir_alunos` |
| GET | `/api/escolar/students/{id}/client-link` | Mostra o cliente (facturação) associado ao aluno. | `gestao-escolar.gerir_alunos` |
| POST | `/api/escolar/students/{id}/client-link` | Liga o aluno a um cliente para facturar as propinas. | `gestao-escolar.gerir_alunos` |
| POST | `/api/escolar/enrollments` | Matricula aluno numa turma/ano. | `gestao-escolar.gerir_matriculas` |
| POST | `/api/escolar/enrollments/{id}/transfer` | Transfere a matrícula para outra turma. | `gestao-escolar.gerir_matriculas` |
| POST | `/api/escolar/enrollments/{id}/cancel` | Anula a matrícula. | `gestao-escolar.gerir_matriculas` |
| POST | `/api/escolar/enrollments/{id}/enviar-para-assinatura` | Envia a ficha de matrícula para assinatura digital. | `gestao-escolar.gerir_matriculas` |
| POST | `/api/escolar/attendance` | Lança presenças/faltas de uma aula. | `gestao-escolar.gerir_presencas` |
| PUT | `/api/escolar/attendance/{id}` | Corrige registo de presença. | `gestao-escolar.gerir_presencas` |
| POST | `/api/escolar/grade-items` | Cria item de avaliação (teste, trabalho). | `gestao-escolar.lancar_notas` |
| POST | `/api/escolar/grade-items/{id}/publish` | Publica as notas da avaliação (ficam visíveis a alunos/encarregados). | `gestao-escolar.lancar_notas` |
| POST | `/api/escolar/grades` | Lança notas (em lote). | `gestao-escolar.lancar_notas` |
| PUT | `/api/escolar/grades/{id}` | Corrige uma nota. | `gestao-escolar.lancar_notas` |
| POST | `/api/escolar/fee-plans` | Cria plano de propinas (valores, vencimentos). | `gestao-escolar.gerir_propinas` |
| POST | `/api/escolar/fee-plans/{id}/generate` | Gera as cobranças de todos os alunos abrangidos pelo plano. | `gestao-escolar.gerir_propinas` |
| POST | `/api/escolar/student-invoices` | Gera cobrança avulsa para um aluno. | `gestao-escolar.gerir_propinas` |
| POST | `/api/escolar/student-invoices/{id}/emit` | ⚠️ Registo sobreposto — ver notas no fim. Emitiria a cobrança. | `gestao-escolar.gerir_propinas` |
| POST | `/api/escolar/student-invoices/{id}/discount` | Aplica desconto a uma cobrança. | `gestao-escolar.gerir_propinas` |
| POST | `/api/escolar/payments` | Regista pagamento de propina (balcão). | `gestao-escolar.gerir_propinas` |
| GET | `/api/escolar/config/financial` | Configuração financeira da escola (multas, prazos, integração com facturação). | `gestao-escolar.gerir_propinas` |
| POST | `/api/escolar/config/financial` | Grava a configuração financeira da escola. | `gestao-escolar.gerir_propinas` |
| POST | `/api/escolar/library/books` | Adiciona livro à biblioteca. | `gestao-escolar.gerir_biblioteca` |
| POST | `/api/escolar/library/loans` | Regista empréstimo de livro. | `gestao-escolar.gerir_biblioteca` |
| POST | `/api/escolar/library/loans/{id}/return` | Regista devolução de livro. | `gestao-escolar.gerir_biblioteca` |
| POST | `/api/escolar/messages` | Cria comunicado (rascunho). | `gestao-escolar.gerir_comunicacao` |
| POST | `/api/escolar/messages/{id}/publish` | Publica o comunicado aos destinatários. | `gestao-escolar.gerir_comunicacao` |
| GET | `/api/escolar/time-slots` | Tempos lectivos (blocos de horário). | `gestao-escolar.gerir_horarios` |
| POST | `/api/escolar/time-slots` | Cria tempo lectivo. | `gestao-escolar.gerir_horarios` |
| GET | `/api/escolar/timetables/class/{class_id}` | Horário semanal de uma turma. | `gestao-escolar.gerir_horarios` |
| GET | `/api/escolar/timetables/teacher/{teacher_id}` | Horário semanal de um professor. | `gestao-escolar.gerir_horarios` |
| POST | `/api/escolar/timetables` | Cria aula no horário. | `gestao-escolar.gerir_horarios` |
| PUT | `/api/escolar/timetables/{id}` | Actualiza aula no horário. | `gestao-escolar.gerir_horarios` |
| DELETE | `/api/escolar/timetables/{id}` | Remove aula do horário. | `gestao-escolar.gerir_horarios` |
| GET | `/api/escolar/calendar-event-types` | Tipos de evento do calendário escolar. | `gestao-escolar.gerir_calendario` |
| POST | `/api/escolar/calendar-event-types` | Cria tipo de evento. | `gestao-escolar.gerir_calendario` |
| GET | `/api/escolar/calendar-events` | Eventos do calendário escolar. | `gestao-escolar.gerir_calendario` |
| GET | `/api/escolar/calendar-events/{id}` | Detalhe de evento. | `gestao-escolar.gerir_calendario` |
| POST | `/api/escolar/calendar-events` | Cria evento no calendário. | `gestao-escolar.gerir_calendario` |
| PUT | `/api/escolar/calendar-events/{id}` | Actualiza evento. | `gestao-escolar.gerir_calendario` |
| DELETE | `/api/escolar/calendar-events/{id}` | Remove evento. | `gestao-escolar.gerir_calendario` |
| GET | `/api/escolar/incident-types` | Tipos de ocorrência disciplinar. | `gestao-escolar.gerir_ocorrencias` |
| POST | `/api/escolar/incident-types` | Cria tipo de ocorrência. | `gestao-escolar.gerir_ocorrencias` |
| GET | `/api/escolar/incidents` | Ocorrências disciplinares. | `gestao-escolar.gerir_ocorrencias` |
| GET | `/api/escolar/incidents/{id}` | Detalhe de ocorrência. | `gestao-escolar.gerir_ocorrencias` |
| POST | `/api/escolar/incidents` | Regista ocorrência disciplinar. | `gestao-escolar.gerir_ocorrencias` |
| PUT | `/api/escolar/incidents/{id}` | Actualiza ocorrência. | `gestao-escolar.gerir_ocorrencias` |
| POST | `/api/escolar/incidents/{id}/anexos` | Anexa ficheiro à ocorrência. | `gestao-escolar.gerir_ocorrencias` |
| GET | `/api/escolar/incidents/{id}/anexos/{idx}/download` | Descarrega anexo da ocorrência. | `gestao-escolar.gerir_ocorrencias` |
| DELETE | `/api/escolar/incidents/{id}/anexos/{idx}` | Remove anexo da ocorrência. | `gestao-escolar.gerir_ocorrencias` |
| POST | `/api/escolar/sanctions` | Aplica sanção a um aluno. | `gestao-escolar.gerir_ocorrencias` |
| POST | `/api/escolar/merits` | Regista mérito/louvor a um aluno. | `gestao-escolar.gerir_ocorrencias` |
| GET | `/api/escolar/tasks` | Trabalhos de casa/tarefas. | `gestao-escolar.lancar_notas` |
| POST | `/api/escolar/tasks` | Cria tarefa para a turma. | `gestao-escolar.lancar_notas` |
| GET | `/api/escolar/tasks/{id}` | Detalhe de tarefa. | `gestao-escolar.lancar_notas` |
| GET | `/api/escolar/portal/alunos` | Alunos e o estado do seu acesso ao portal. | `gestao-escolar.portal_aluno` |
| GET | `/api/escolar/portal/sessions` | Relatório de utilização do portal do aluno. | `gestao-escolar.portal_aluno` |
| POST | `/api/escolar/classes/{id}/portal/invite-all` | Envia convite de acesso ao portal a toda a turma. | `gestao-escolar.portal_aluno` |
| GET | `/api/escolar/students/{id}/portal/status` | Estado do acesso do aluno ao portal. | `gestao-escolar.portal_aluno` |
| POST | `/api/escolar/students/{id}/portal/activate` | Activa o acesso do aluno ao portal. | `gestao-escolar.portal_aluno` |
| POST | `/api/escolar/students/{id}/portal/deactivate` | Desactiva o acesso do aluno ao portal. | `gestao-escolar.portal_aluno` |
| POST | `/api/escolar/students/{id}/portal/invite` | Envia convite de acesso ao portal ao aluno. | `gestao-escolar.portal_aluno` |
| POST | `/api/escolar/students/{id}/portal/reset-senha` | Repõe a senha do aluno no portal. | `gestao-escolar.portal_aluno` |
| POST | `/api/escolar/student-invoices/{id}/cancel` | Anula a cobrança. | `gestao-escolar.gerir_propinas` |
| POST | `/api/escolar/student-invoices/{id}/emit` | ⚠️ **Registo duplicado**: este segundo registo substitui o anterior. Emite a cobrança com referência de pagamento (bancária/móvel). | `gestao-escolar.gerir_propinas` |
| POST | `/api/escolar/student-invoices/{id}/parcelas` | Divide a cobrança em prestações. | `gestao-escolar.gerir_propinas` |
| GET | `/api/escolar/student-invoices/{id}/parcelas` | Prestações da cobrança. | `gestao-escolar.gerir_propinas` |
| GET | `/api/escolar/bolsas` | Bolsas/isenções de propina. | `gestao-escolar.gerir_propinas` |
| POST | `/api/escolar/bolsas` | Atribui bolsa a um aluno. | `gestao-escolar.gerir_propinas` |
| DELETE | `/api/escolar/bolsas/{id}` | Remove bolsa. | `gestao-escolar.gerir_propinas` |
| GET | `/api/escolar/relatorios/aging` | Relatório: antiguidade das dívidas (0-30, 31-60, 61-90, +90 dias). | `gestao-escolar.ver` ou `gestao-escolar.relatorios` |
| POST | `/api/escolar/encarregados/convidar` | Convida o encarregado para o portal do encarregado. | `gestao-escolar.portal_aluno` |
| POST | `/api/escolar/encarregados/reset-senha` | Repõe a senha do encarregado no portal. | `gestao-escolar.portal_aluno` |

## Portal do aluno (`/api/portal/aluno`)

App/portal do aluno, com sessão própria (`RequireAlunoAuth`).

| Método | Rota | O que faz | Acesso |
|---|---|---|---|
| POST | `/api/portal/aluno/definir-senha` | Aluno define a senha a partir do link de convite (sem login). | **público** |
| POST | `/api/portal/aluno/logout` | Termina a sessão no portal do aluno. | sessão de aluno |
| GET | `/api/portal/aluno/me` | Dados do aluno autenticado. | sessão de aluno |
| POST | `/api/portal/aluno/alterar-senha` | Aluno altera a senha. | sessão de aluno |
| GET | `/api/portal/aluno/me/boletim` | Boletim do próprio aluno. | sessão de aluno |
| GET | `/api/portal/aluno/me/notas` | Notas detalhadas por avaliação. | sessão de aluno |
| GET | `/api/portal/aluno/me/cobrancas` | Propinas do aluno (pagas e por pagar). | sessão de aluno |
| GET | `/api/portal/aluno/me/cobrancas/{id}/recibo` | Recibo de uma propina paga. | sessão de aluno |
| GET | `/api/portal/aluno/me/horario` | Horário da turma do aluno. | sessão de aluno |
| GET | `/api/portal/aluno/me/mensagens` | Comunicados recebidos. | sessão de aluno |
| GET | `/api/portal/aluno/me/eventos` | Eventos do calendário. | sessão de aluno |
| GET | `/api/portal/aluno/me/presencas` | Presenças/faltas do aluno. | sessão de aluno |
| POST | `/api/portal/aluno/me/turma/presencas` | Aluno com cargo (ex.: chefe de turma) marca presenças da turma. | sessão de aluno |
| GET | `/api/portal/aluno/me/ocorrencias` | Ocorrências disciplinares do aluno. | sessão de aluno |
| GET | `/api/portal/aluno/me/biblioteca` | Empréstimos de livros do aluno. | sessão de aluno |
| POST | `/api/portal/aluno/me/cobrancas/{id}/pagar` | Inicia pagamento móvel (M-Pesa/e-Mola via NexoraPay) de uma propina. | sessão de aluno |
| GET | `/api/portal/aluno/me/cobrancas/{id}/pagamento/{gtid}` | Estado do pagamento móvel iniciado. | sessão de aluno |
| GET | `/api/portal/aluno/me/dashboard` | Painel inicial do aluno. | sessão de aluno |
| GET | `/api/portal/aluno/me/turma` | Dados da turma do aluno. | sessão de aluno |
| GET | `/api/portal/aluno/me/noticias` | Notícias da escola. | sessão de aluno |
| PUT | `/api/portal/aluno/me` | Aluno actualiza os seus dados. | sessão de aluno |
| POST | `/api/portal/aluno/me/presencas/{id}/justificar` | Aluno justifica uma falta. | sessão de aluno |

## Portal do professor (`/api/portal/professor`)

Portal do professor: usa o login normal e exige perfil de professor (`RequireProfessorAuth`).

| Método | Rota | O que faz | Acesso |
|---|---|---|---|
| POST | `/api/portal/professor/logout` | Termina a sessão no portal do professor. | perfil professor |
| POST | `/api/portal/professor/alterar-senha` | Professor altera a senha. | perfil professor |
| GET | `/api/portal/professor/me` | Dados do professor autenticado. | perfil professor |
| GET | `/api/portal/professor/me/dashboard` | Painel do professor. | perfil professor |
| GET | `/api/portal/professor/me/turmas` | Turmas que o professor lecciona. | perfil professor |
| GET | `/api/portal/professor/me/turmas/{id}` | Detalhe de uma turma do professor. | perfil professor |
| GET | `/api/portal/professor/me/turmas/{id}/alunos` | Alunos de uma turma do professor. | perfil professor |
| GET | `/api/portal/professor/me/horario` | Horário do professor. | perfil professor |
| GET | `/api/portal/professor/me/presencas` | Presenças das aulas do professor. | perfil professor |
| POST | `/api/portal/professor/me/presencas` | Professor lança presenças. | perfil professor |
| GET | `/api/portal/professor/me/turmas/{id}/cargo-permissoes` | Permissões delegadas a cargos de alunos na turma. | perfil professor |
| POST | `/api/portal/professor/me/turmas/{id}/cargo-permissoes` | Delega uma permissão a um cargo de aluno (ex.: chefe marca presenças). | perfil professor |
| DELETE | `/api/portal/professor/me/turmas/{id}/cargo-permissoes/{permId}` | Retira a permissão delegada. | perfil professor |
| GET | `/api/portal/professor/me/notas` | Notas das turmas do professor. | perfil professor |
| POST | `/api/portal/professor/me/notas` | Professor lança notas. | perfil professor |
| GET | `/api/portal/professor/me/comunicacao` | Comunicados relevantes para o professor. | perfil professor |

## Portal do encarregado (`/api/portal/encarregado`)

Portal do encarregado de educação, com sessão própria (`RequireEncarregadoAuth`).

| Método | Rota | O que faz | Acesso |
|---|---|---|---|
| POST | `/api/portal/encarregado/definir-senha` | Encarregado define a senha a partir do convite (sem login). | **público** |
| POST | `/api/portal/encarregado/logout` | Termina a sessão no portal do encarregado. | sessão de encarregado |
| GET | `/api/portal/encarregado/me` | Dados do encarregado e lista de educandos. | sessão de encarregado |
| POST | `/api/portal/encarregado/alterar-senha` | Encarregado altera a senha. | sessão de encarregado |
| GET | `/api/portal/encarregado/me/educandos/{id}/boletim` | Boletim de um educando. | sessão de encarregado |
| GET | `/api/portal/encarregado/me/educandos/{id}/cobrancas` | Propinas de um educando. | sessão de encarregado |
| GET | `/api/portal/encarregado/me/educandos/{id}/presencas` | Presenças de um educando. | sessão de encarregado |
| GET | `/api/portal/encarregado/me/educandos/{id}/ocorrencias` | Ocorrências de um educando. | sessão de encarregado |

## Tarefas (`/api/tarefas`)

Quadros Kanban: quadros → listas → cartões.

| Método | Rota | O que faz | Acesso |
|---|---|---|---|
| GET | `/api/tarefas/quadros` | Quadros Kanban. | `tarefas.ver_quadros` |
| POST | `/api/tarefas/quadros` | Cria quadro. | `tarefas.gerir_quadros` |
| GET | `/api/tarefas/quadros/{id}` | Quadro com listas e cartões. | `tarefas.ver_quadros` |
| PUT | `/api/tarefas/quadros/{id}` | Actualiza quadro. | `tarefas.gerir_quadros` |
| DELETE | `/api/tarefas/quadros/{id}` | Elimina quadro. | `tarefas.gerir_quadros` |
| POST | `/api/tarefas/quadros/{id}/arquivar` | Arquiva quadro. | `tarefas.gerir_quadros` |
| POST | `/api/tarefas/quadros/{id}/listas` | Cria lista (coluna) no quadro. | `tarefas.gerir_listas` |
| PUT | `/api/tarefas/listas/{id}` | Actualiza lista. | `tarefas.gerir_listas` |
| DELETE | `/api/tarefas/listas/{id}` | Elimina lista. | `tarefas.gerir_listas` |
| POST | `/api/tarefas/listas/{id}/reordenar` | Reordena as listas. | `tarefas.gerir_listas` |
| POST | `/api/tarefas/listas/{id}/cartoes` | Cria cartão (tarefa). | `tarefas.gerir_cartoes` |
| GET | `/api/tarefas/cartoes/{id}` | Detalhe de cartão. | `tarefas.ver_quadros` |
| PUT | `/api/tarefas/cartoes/{id}` | Actualiza cartão. | `tarefas.gerir_cartoes` |
| PUT | `/api/tarefas/cartoes/{id}/mover` | Move cartão entre listas/posições. | `tarefas.mover_cartoes` |
| POST | `/api/tarefas/cartoes/{id}/concluir` | Marca cartão como concluído. | `tarefas.mover_cartoes` |
| DELETE | `/api/tarefas/cartoes/{id}` | Elimina cartão. | `tarefas.eliminar_cartoes` |

## Hardware e dispositivos (`/api/hardware`)

Integração com relógios de ponto e outros dispositivos. As rotas de eventos e de assiduidade são chamadas **pelo próprio dispositivo** (chave de API/HMAC, `RequireDeviceAuth`); as restantes são a gestão feita pelo admin.

| Método | Rota | O que faz | Acesso |
|---|---|---|---|
| POST | `/api/hardware/events` | Dispositivo envia um evento (marcação, porta…). | dispositivo (chave API) |
| POST | `/api/hardware/events/generic` | Evento em formato genérico (dispositivos sem driver próprio). | dispositivo (chave API) |
| POST | `/api/hardware/events/zkteco` | Evento no formato dos relógios ZKTeco. | dispositivo (chave API) |
| POST | `/api/hardware/events/batch` | Vários eventos de uma vez (sincronização após estar offline). | dispositivo (chave API) |
| GET | `/api/hardware/ping` | Dispositivo confirma que está ligado (heartbeat). | dispositivo (chave API) |
| GET | `/api/hardware/assiduidade/config` | Configuração de assiduidade para o dispositivo. | dispositivo (chave API) |
| GET | `/api/hardware/assiduidade/funcionarios` | Funcionários para sincronizar no dispositivo. | dispositivo (chave API) |
| GET | `/api/hardware/assiduidade/funcionarios/{id}` | Dados de um funcionário para o dispositivo. | dispositivo (chave API) |
| GET | `/api/hardware/assiduidade/geofence/validar` | Verifica se uma posição GPS está dentro da zona permitida. | dispositivo (chave API) |
| POST | `/api/hardware/assiduidade/consentimentos` | Regista consentimento biométrico a partir do dispositivo. | dispositivo (chave API) |
| GET | `/api/hardware/assiduidade/consentimentos` | Consentimentos biométricos. | dispositivo (chave API) |
| GET | `/api/hardware/assiduidade/consentimentos/activo` | Consentimento activo de um funcionário. | dispositivo (chave API) |
| POST | `/api/hardware/assiduidade/consentimentos/revogar` | Revoga consentimento biométrico. | dispositivo (chave API) |
| POST | `/api/hardware/assiduidade/qr/validar` | Valida um QR de marcação e regista o ponto. | dispositivo (chave API) |
| POST | `/api/hardware/assiduidade/qr/registar` | Regista marcação por QR vinda do dispositivo. | dispositivo (chave API) |
| POST | `/api/hardware/assiduidade/qr/gerar-terminal` | Gera QR rotativo mostrado no ecrã do terminal. | dispositivo (chave API) |
| GET | `/api/hardware/assiduidade/nfc/validar` | Valida cartão NFC lido no dispositivo. | dispositivo (chave API) |
| POST | `/api/hardware/assiduidade/biometria/reenroll-required` | Webhook do FaceClock: o rosto tem de ser registado de novo (mudou a versão do modelo). | dispositivo (chave API) |
| GET | `/api/hardware/audit-logs` | Logs de auditoria lidos por um dispositivo autorizado (ex.: FaceClock). ⚠️ Ver notas. | dispositivo (chave API) |
| GET | `/api/hardware/events` | Eventos recebidos dos dispositivos. | `hardware.ver_eventos` |
| POST | `/api/hardware/events/{id}/reprocessar` | Reprocessa um evento (ex.: após corrigir mapeamento de utilizador). | `hardware.gerir_eventos` |
| POST | `/api/hardware/events/reprocessar-nao-processados` | Reprocessa todos os eventos pendentes. | `hardware.gerir_eventos` |
| GET | `/api/hardware/drivers` | Drivers de dispositivo suportados. | autenticado |
| GET | `/api/hardware/devices` | Dispositivos registados. | `hardware.ver_dispositivos` |
| POST | `/api/hardware/devices` | Regista dispositivo (gera chave de API). | `hardware.gerir_dispositivos` |
| GET | `/api/hardware/devices/{id}` | Detalhe de dispositivo. | `hardware.ver_dispositivos` |
| PUT | `/api/hardware/devices/{id}` | Actualiza dispositivo. | `hardware.gerir_dispositivos` |
| POST | `/api/hardware/devices/{id}/toggle` | Liga/desliga dispositivo. | `hardware.gerir_dispositivos` |
| POST | `/api/hardware/devices/{id}/rotate-key` | Roda a chave de API do dispositivo. | `hardware.gerir_dispositivos` |
| GET | `/api/hardware/devices/{id}/users` | Mapeamento ID-no-dispositivo ↔ funcionário. | `hardware.ver_dispositivos` |
| POST | `/api/hardware/devices/{id}/users` | Cria mapeamento de utilizador. | `hardware.gerir_dispositivos` |
| DELETE | `/api/hardware/devices/{id}/users/{mappingId}` | Remove mapeamento. | `hardware.gerir_dispositivos` |

## Superadmin (`/api/superadmin`)

Administração da plataforma SaaS (acima dos tenants): tenants, planos, módulos, features e configuração global. Exige o tipo superadmin e um IP autorizado; a gestão de tenants/planos pede ainda reautenticação recente.

| Método | Rota | O que faz | Acesso |
|---|---|---|---|
| GET | `/api/superadmin/dashboard` | Painel global da plataforma (tenants, uso, receitas). | superadmin · IP autorizado |
| GET | `/api/superadmin/utilizadores` | Utilizadores de todos os tenants. | superadmin · IP autorizado |
| GET | `/api/superadmin/ip-allowlist` | IPs autorizados para o superadmin. | superadmin · IP autorizado |
| POST | `/api/superadmin/ip-allowlist` | Autoriza IP para superadmin. | superadmin · IP autorizado |
| DELETE | `/api/superadmin/ip-allowlist/{id}` | Remove IP do superadmin. | superadmin · IP autorizado |
| GET | `/api/superadmin/tenants` | Tenants (empresas clientes do SaaS). | superadmin · IP autorizado · reauth recente |
| POST | `/api/superadmin/tenants` | Cria tenant (empresa, subdomínio, plano). | superadmin · IP autorizado · reauth recente |
| GET | `/api/superadmin/tenants/{id}` | Detalhe de tenant. | superadmin · IP autorizado · reauth recente |
| PUT | `/api/superadmin/tenants/{id}` | Actualiza tenant. | superadmin · IP autorizado · reauth recente |
| DELETE | `/api/superadmin/tenants/{id}` | Elimina tenant. | superadmin · IP autorizado · reauth recente |
| POST | `/api/superadmin/tenants/{id}/suspender` | Suspende tenant (ex.: falta de pagamento). | superadmin · IP autorizado · reauth recente |
| POST | `/api/superadmin/tenants/{id}/reativar` | Reactiva tenant suspenso. | superadmin · IP autorizado · reauth recente |
| POST | `/api/superadmin/tenants/{id}/inativar` | Inactiva tenant. | superadmin · IP autorizado · reauth recente |
| POST | `/api/superadmin/tenants/{id}/cargos-padrao` | Cria os cargos e permissões padrão no tenant. | superadmin · IP autorizado · reauth recente |
| GET | `/api/superadmin/tenants/{tenantId}/funcionarios/proximo-numero` | Próximo número de funcionário num tenant. | superadmin · IP autorizado · reauth recente |
| POST | `/api/superadmin/tenants/{tenantId}/funcionarios` | Cria funcionário num tenant (ex.: admin inicial). | superadmin · IP autorizado · reauth recente |
| GET | `/api/superadmin/plans` | Planos comerciais do SaaS. | superadmin · IP autorizado · reauth recente |
| POST | `/api/superadmin/plans` | Cria plano SaaS. | superadmin · IP autorizado · reauth recente |
| GET | `/api/superadmin/plans/{id}` | Detalhe de plano SaaS. | superadmin · IP autorizado · reauth recente |
| PUT | `/api/superadmin/plans/{id}` | Actualiza plano SaaS. | superadmin · IP autorizado · reauth recente |
| DELETE | `/api/superadmin/plans/{id}` | Elimina plano SaaS. | superadmin · IP autorizado · reauth recente |
| GET | `/api/superadmin/plans/{id}/modules` | Módulos incluídos no plano. | superadmin · IP autorizado · reauth recente |
| PUT | `/api/superadmin/plans/{id}/modules` | Define os módulos do plano. | superadmin · IP autorizado · reauth recente |
| GET | `/api/superadmin/modules/disponiveis` | Todos os módulos do ERP. | superadmin · IP autorizado · reauth recente |
| GET | `/api/superadmin/modules/tenants/{tenantId}` | Módulos activos num tenant. | superadmin · IP autorizado · reauth recente |
| POST | `/api/superadmin/modules/tenants/{tenantId}/{modulo}` | Liga/desliga um módulo num tenant. | superadmin · IP autorizado · reauth recente |
| POST | `/api/superadmin/modules/tenants/{tenantId}/reset` | Repõe os módulos do tenant aos do plano. | superadmin · IP autorizado · reauth recente |
| GET | `/api/superadmin/modules/dependencies` | Dependências entre módulos (ex.: facturação requer clientes). | superadmin · IP autorizado · reauth recente |
| POST | `/api/superadmin/modules/dependencies` | Cria dependência entre módulos. | superadmin · IP autorizado · reauth recente |
| DELETE | `/api/superadmin/modules/dependencies/{modulo}/{requires}` | Remove dependência. | superadmin · IP autorizado · reauth recente |
| GET | `/api/superadmin/features/catalog` | Catálogo de features (usadas por `RequireFeature`). | superadmin · IP autorizado · reauth recente |
| GET | `/api/superadmin/features/tenants/{tenantId}` | Features activas num tenant. | superadmin · IP autorizado · reauth recente |
| POST | `/api/superadmin/features/tenants/{tenantId}/{key}` | Liga/desliga uma feature num tenant. | superadmin · IP autorizado · reauth recente |
| DELETE | `/api/superadmin/features/tenants/{tenantId}/{key}` | Remove a excepção: a feature volta ao valor do plano/catálogo. | superadmin · IP autorizado · reauth recente |
| GET | `/api/superadmin/settings` | Configurações globais da plataforma. | superadmin · IP autorizado · reauth recente |
| PUT | `/api/superadmin/settings` | Actualiza configuração global. | superadmin · IP autorizado · reauth recente |
| GET | `/api/superadmin/faceclock/metrics` | Métricas do serviço FaceClock (latência, taxas de reconhecimento). | superadmin · IP autorizado |
| GET | `/api/superadmin/faceclock/audit-logs` | Logs de auditoria do FaceClock. | superadmin · IP autorizado |

## Notas e inconsistências encontradas

Encontrei estes pontos ao gerar o documento. Convém confirmar cada um antes de alterar código.

1. **Rota duplicada**: `POST /api/escolar/student-invoices/{id}/emit` está registada duas vezes, com `EmitirCobrancaAluno` (router.go:1130) e `EmitirCobrancaComReferencia` (router.go:1217). No chi, o segundo registo substitui o primeiro, por isso `EmitirCobrancaAluno` nunca é chamado.
2. **Recibos com a permissão errada**: `POST /api/faturacao/receipts` (`fat.CriarRecibo`) está no grupo das notas de crédito. Exige `faturacao.emitir_notas_credito` e a feature `vendas.devolucoes`, pelo que um utilizador que só emite facturas não consegue emitir recibos.
3. **Logs de auditoria acessíveis a dispositivos**: `GET /api/hardware/audit-logs` usa o mesmo handler de `/api/audit-logs`, mas só com `RequireDeviceAuth`. Qualquer dispositivo com uma chave válida lê a auditoria do tenant. É intencional (serve o FaceClock), mas convém confirmar que o handler filtra os registos que devolve ao dispositivo.
4. **O RH inteiro depende da feature `rh.assiduidade`**: funcionários, contratos e salários ficam indisponíveis num tenant que não tenha a assiduidade activa.
5. **Escrita com permissão de leitura**: `POST /api/rh/recibos-vencimento/{id}/pdf` grava o PDF com a permissão `recursos-humanos.ver_recibos`.
6. **Rotas repetidas de propósito** (aliases): `/vagas*` e `/candidaturas*` repetem `/api/public/recrutamento/*`; `self-service/assiduidade/biometric/*` e `.../biometria/facial/*` apontam para os mesmos handlers; `/api/rh/assiduidade/fingerprint/*` e `/api/v1/fingerprint/*` também se sobrepõem.
7. **Aprovações**: `POST /api/aprovacoes/requests/{id}/decidir` só exige login no router. Não é uma falha: o handler confirma que o cargo do utilizador corresponde ao nível actual (`podeDecidir`, em `aprovacoes/handlers/requests.go`).
