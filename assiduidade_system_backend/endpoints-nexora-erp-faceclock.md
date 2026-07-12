# Índice de Endpoints — Nexora ERP (Go) e FaceClock (Python)

Levantamento feito directamente do código-fonte em 2026-07-12 (não é uma listagem de memória — cada linha corresponde a uma rota real registada no router).

- FaceClock (`assiduidade_system_backend`): 26 endpoints
- Nexora ERP (`backend`): 993 endpoints

---

# Endpoints — FaceClock (`assiduidade_system_backend`, Python/FastAPI)

> **Decisão arquitetural (2026-07-12):** O FaceClock é **stateless**. **Nenhum dado persiste no FaceClock**, excepto os **templates biométricos** (face e digitais). Os endpoints abaixo estão divididos em:
> - **🟢 Mantidos no FaceClock** — apenas biometria face/digital.
> - **🟡 Proxy para o Nexora ERP** — o FaceClock recebe o pedido, valida o método/biometria, e delega a persistência/consulta ao ERP.
> - **🔴 A remover / substituir por endpoint ERP** — funcionalidade legada que deixa de existir localmente.

Prefixo base: `/api/v1` (excepto `/health` e `/metrics`, que ficam na raiz).

## 🟡 Autenticação (proxy/cache do ERP)
- `POST /auth/login` — login normal (delega no Nexora ERP; fallback local desactivado em produção)
- `POST /auth/refresh` — renovar token (delega no ERP)
- `POST /authcode/pin/validate` — login por PIN (delega no ERP)
- `POST /authcode/totp/setup` — configurar TOTP (delega no ERP)
- `POST /authcode/totp/validate` — validar código TOTP (delega no ERP)
- `POST /authcode/admin/set-pin` — admin define PIN de um utilizador (delega no ERP)

## 🟢 Biometria (única persistência autorizada no FaceClock)
- `POST /biometric/enroll` — registar rosto (template cifrado guardado localmente)
- `POST /biometric/verify` — verificar rosto contra template local
- `POST /fingerprint/enroll` — registar impressão digital (template cifrado guardado localmente)
- `POST /fingerprint/identify` — identificar por impressão digital contra templates locais
- `DELETE /fingerprint/enroll/{user_id}` — remover impressão digital local

## 🟡 Registo de ponto (proxy para o ERP)
- `POST /clock/register` — valida credencial/biometria e envia evento imediatamente para `POST /api/hardware/events/generic` no ERP
- `POST /clock/register/batch` — envia lote de eventos para `POST /api/hardware/events/batch` no ERP
- `🔴 POST /clock/sync` — obsoleto; não há registos locais para sincronizar
- `🔴 POST /clock/erp/retry-failed` — a substituir por reprocessamento no ERP ou proxy de retry ERP
- `🟡 GET /clock/me` — histórico de pontos do utilizador (proxy para endpoint ERP a criar)
- `🟡 POST /clock/adjustments` — pedir correcção de ponto (proxy para endpoint ERP a criar)
- `🟡 GET /clock/adjustments/me` — ver os meus pedidos de correcção (proxy para endpoint ERP a criar)
- `🟡 DELETE /clock/adjustments/{adjustment_id}` — cancelar pedido de correcção (proxy para endpoint ERP a criar)

## 🟡 Métodos de validação (validação local + configuração do ERP)
- `POST /qr/generate` — gerar QR Code de presença (valida se método `qr_code` está activo no ERP)
- `POST /qr/validate` — validar QR Code
- `POST /nfc/validate` — validar tag NFC
- `POST /geolocation/validate` — validar geolocalização

## 🟡 Consentimentos / LGPD (proxy para o ERP)
- `POST /consents` — registar consentimento (proxy para endpoint ERP a criar)
- `GET /consents/users/{user_id}/active` — consentimento activo (proxy para endpoint ERP a criar)
- `GET /consents/users/{user_id}/history` — histórico de consentimentos (proxy para endpoint ERP a criar)
- `POST /consents/users/{user_id}/revoke` — revogar consentimento (desactiva/apaga templates locais + notifica ERP)
- `DELETE /consents/users/{user_id}/biometric-data` — "direito ao esquecimento" (apaga templates faciais + digitais locais)

## 🟡 Sincronização / Integração com o Nexora ERP
- `🔴 POST /sync/employees` — obsoleto; não há tabela `users` local para importar. O FaceClock consulta o ERP sob demanda.
- `🔴 POST /sync/employees/{employee_id}` — obsoleto.
- `GET /tenant/attendance-config` — configuração de métodos de assiduidade do tenant (proxy/cache do ERP, TTL 60s)

## 🟡 Auditoria e monitorização
- `🟡 GET /audit/logs` — trilha de auditoria (proxy para `GET /api/audit-logs/` do ERP)
- `🟢 GET /metrics` — métricas Prometheus locais (stateless por natureza)
- `🟢 GET /health` — health check local

---


---

# Endpoints HTTP — `backend/internal/router/router.go`

Nota preliminar: o ficheiro contém várias linhas de comentário com encoding corrompido (multi-byte UTF-8 duplamente escapado, ex. linhas 142, 233, 295, 351-352, 368, 411, 488, 566, 637, 1439, 1523, 1587, 1639, 2207). Confirmei que todas essas linhas são apenas comentários (`// ...`) sem impacto na estrutura de rotas — foram ignoradas no conteúdo mas a estrutura de rotas à sua volta foi lida por completo.

Rotas soltas antes de qualquer `r.Route`: `GET /health`, `GET /ws/chat`, `Handle /socket.io/*` → `recrutRealtime.Handler()`.

---

## /api/auth
- `POST /api/auth/login` — auth.Login
- `POST /api/auth/refresh` — auth.Refresh
- `POST /api/auth/forgot-password` — auth.ForgotPassword
- `POST /api/auth/reset-password` — auth.ResetPassword
- `POST /api/auth/verify-email` — auth.VerifyEmail

**Autenticado (operações pessoais)**
- `GET /api/auth/me` — auth.Me
- `GET /api/auth/me/acesso` — auth.ObterAcessoUtilizador
- `GET /api/auth/me/perm-ts` — auth.MePermTs
- `POST /api/auth/logout` — auth.Logout
- `POST /api/auth/change-password` — auth.ChangePassword
- `GET /api/auth/gateway/validate` — auth.GatewayValidate

**Gestão de utilizadores (requer permissão)**
- `GET /api/auth/utilizadores/` — auth.ListarUtilizadores
- `POST /api/auth/utilizadores/` — auth.CriarUtilizador
- `GET /api/auth/utilizadores/{id}` — auth.ObterUtilizador
- `PUT /api/auth/utilizadores/{id}` — auth.ActualizarUtilizador
- `POST /api/auth/utilizadores/{id}/activar` — auth.ActivarUtilizador
- `POST /api/auth/utilizadores/{id}/bloquear` — auth.BloquearUtilizador
- `POST /api/auth/utilizadores/{id}/desactivar` — auth.DesactivarUtilizador
- `PUT /api/auth/utilizadores/{id}/cargo` — auth.AtribuirCargo
- `PUT /api/auth/utilizadores/{id}/tipo` — auth.AlterarTipo
- `POST /api/auth/utilizadores/{id}/reset-password` — auth.ResetPasswordAdmin
- `GET /api/auth/utilizadores/{id}/permissoes` — auth.ListarPermissoesDiretas
- `PUT /api/auth/utilizadores/{id}/permissoes` — auth.DefinirPermissoesDiretas
- `GET /api/auth/historico-login` — auth.HistoricoLogin

**Gestão de cargos e permissões**
- `GET /api/auth/cargos/` — auth.ListarCargos
- `POST /api/auth/cargos/` — auth.CriarCargo
- `GET /api/auth/cargos/{id}` — auth.ObterCargo
- `PUT /api/auth/cargos/{id}` — auth.ActualizarCargo
- `POST /api/auth/cargos/{id}/activar` — auth.ActivarCargo
- `POST /api/auth/cargos/{id}/desactivar` — auth.DesactivarCargo
- `GET /api/auth/cargos/{id}/permissoes` — auth.ListarPermissoesCargo
- `PUT /api/auth/cargos/{id}/permissoes` — auth.DefinirPermissoesCargo

**Gestão de sessões**
- `GET /api/auth/sessoes/` — auth.ListarSessoes
- `POST /api/auth/sessoes/{id}/revogar` — auth.RevogarSessao
- `POST /api/auth/sessoes/revogar-todas` — auth.RevogarTodasSessoes

**API Keys**
- `GET /api/auth/api-keys/` — auth.ListarAPIKeys
- `POST /api/auth/api-keys/` — auth.CriarAPIKey
- `GET /api/auth/api-keys/{id}` — auth.ObterAPIKey
- `PUT /api/auth/api-keys/{id}` — auth.ActualizarAPIKey
- `POST /api/auth/api-keys/{id}/revogar` — auth.RevogarAPIKey

---

## /api/authcode
Login alternativo por PIN/TOTP.

- `POST /api/authcode/pin/validate` — auth.LoginPorPIN (login por email + PIN)
- `POST /api/authcode/totp/validate` — auth.ValidarTOTP (login por email + código TOTP)

**Autenticado**
- `POST /api/authcode/totp/setup` — auth.SetupTOTP (gera e guarda secret TOTP; devolve `secret` e `provisioning_uri`)

**Gestão administrativa (requer permissão `auth.pin_admin`)**
- `POST /api/authcode/admin/set-pin` — auth.AdminDefinirPIN (admin define PIN de outro utilizador)

---

## /api/utilizadores

**Perfil (visualização)**
- `GET /api/utilizadores/perfis/{userId}` — util.ObterPerfil

**Perfil (edição)**
- `POST /api/utilizadores/perfis` — util.CriarPerfil
- `PUT /api/utilizadores/perfis/{userId}` — util.ActualizarPerfil

**Dados pessoais (`/{userId}`)**
- `GET /api/utilizadores/{userId}/preferences` — util.ListarPreferencias
- `POST /api/utilizadores/{userId}/preferences` — util.GuardarPreferencia
- `GET /api/utilizadores/{userId}/settings` — util.ListarSettings
- `POST /api/utilizadores/{userId}/settings` — util.GuardarSetting
- `GET /api/utilizadores/{userId}/notifications` — util.ListarNotificacoes
- `POST /api/utilizadores/{userId}/notifications` — util.CriarNotificacao
- `POST /api/utilizadores/{userId}/notifications/{notificationId}/read` — util.MarcarNotificacaoLida
- `POST /api/utilizadores/{userId}/notifications/read-all` — util.MarcarTodasNotificacoesLidas
- `GET /api/utilizadores/{userId}/devices` — util.ListarDispositivos
- `POST /api/utilizadores/{userId}/devices` — util.RegistarDispositivo
- `DELETE /api/utilizadores/{userId}/devices/{deviceId}` — util.RemoverDispositivo
- `GET /api/utilizadores/{userId}/activity` — util.ListarActividade
- `POST /api/utilizadores/{userId}/activity` — util.RegistarActividade
- `GET /api/utilizadores/{userId}/tokens` — util.ListarTokens
- `POST /api/utilizadores/{userId}/tokens` — util.CriarToken
- `POST /api/utilizadores/{userId}/tokens/{tokenId}/revogar` — util.RevogarToken
- `GET /api/utilizadores/{userId}/security-logs` — util.ListarSecurityLogs
- `GET /api/utilizadores/{userId}/avatar` — util.ObterAvatar
- `POST /api/utilizadores/{userId}/avatar` — util.UploadAvatar
- `DELETE /api/utilizadores/{userId}/avatar` — util.RemoverAvatar

---

## /api/companies
- `POST /api/companies/` (superadmin) — empresa.CriarEmpresa

**Visualização**
- `GET /api/companies/` — empresa.ListarEmpresas
- `GET /api/companies/{id}` — empresa.ObterEmpresa
- `GET /api/companies/{id}/settings` — empresa.ListarCompanySettings
- `GET /api/companies/{id}/branches` — empresa.ListarBranches
- `GET /api/companies/{id}/branches/{branchId}` — empresa.ObterBranch
- `GET /api/companies/{id}/tax-info` — empresa.ObterTaxInfo
- `GET /api/companies/{id}/banks` — empresa.ListarBancos
- `GET /api/companies/{id}/contacts` — empresa.ListarContactos
- `GET /api/companies/{id}/addresses` — empresa.ListarEnderecos
- `GET /api/companies/{id}/licenses` — empresa.ListarLicencas
- `GET /api/companies/{id}/users` — empresa.ListarCompanyUsers

**Editar empresa e configurações**
- `PUT /api/companies/{id}` — empresa.ActualizarEmpresa
- `POST /api/companies/{id}/settings` — empresa.GuardarCompanySetting
- `POST /api/companies/{id}/tax-info` — empresa.GuardarTaxInfo
- `PUT /api/companies/{id}/tax-info` — empresa.GuardarTaxInfo
- `POST /api/companies/{id}/banks` — empresa.AdicionarBanco
- `POST /api/companies/{id}/contacts` — empresa.AdicionarContacto
- `POST /api/companies/{id}/addresses` — empresa.AdicionarEndereco

**Gerir filiais**
- `POST /api/companies/{id}/branches` — empresa.CriarBranch
- `PUT /api/companies/{id}/branches/{branchId}` — empresa.ActualizarBranch

**Gerir licenças**
- `POST /api/companies/{id}/licenses` — empresa.AdicionarLicenca

**Gerir utilizadores da empresa**
- `POST /api/companies/{id}/users` — empresa.AdicionarCompanyUser
- `DELETE /api/companies/{id}/users/{userId}` — empresa.RemoverCompanyUser

---

## /api/audit-logs
- `GET /api/audit-logs/` — audit.ListarAuditLogs
- `GET /api/audit-logs/{id}` — audit.ObterAuditLog
- `POST /api/audit-logs/` — audit.RegistarAuditLog

---

## /api/system

**Visualização**
- `GET /api/system/settings` — sys.ListarSettings
- `GET /api/system/currencies` — sys.ListarMoedas
- `GET /api/system/exchange-rates` — sys.ListarTaxasCambio
- `GET /api/system/countries` — sys.ListarPaises
- `GET /api/system/cities` — sys.ListarCidades
- `GET /api/system/languages` — sys.ListarIdiomas
- `GET /api/system/email-templates` — sys.ListarEmailTemplates
- `GET /api/system/sms-templates` — sys.ListarSMSTemplates
- `GET /api/system/logs` — sys.ListarSystemLogs
- `GET /api/system/integrations` — sys.ListarIntegracoes
- `GET /api/system/api-logs` — sys.ListarAPILogs
- `GET /api/system/configuracao/tenant/feature/rh.assiduidade` — sys.ObterConfigAssiduidade

**Editar configurações gerais**
- `POST /api/system/settings` — sys.GuardarSetting
- `POST /api/system/currencies` — sys.CriarMoeda
- `POST /api/system/exchange-rates` — sys.CriarTaxaCambio
- `POST /api/system/countries` — sys.CriarPais
- `POST /api/system/cities` — sys.CriarCidade
- `POST /api/system/languages` — sys.CriarIdioma
- `PUT /api/system/configuracao/tenant/feature/rh.assiduidade` — sys.GuardarConfigAssiduidade

**Gerir templates e integrações**
- `POST /api/system/email-templates` — sys.CriarEmailTemplate
- `POST /api/system/sms-templates` — sys.CriarSMSTemplate
- `POST /api/system/integrations` — sys.CriarIntegracao

---

## /api/clientes

**Grupos de clientes**
- `GET /api/clientes/grupos` — cli.ListarGrupos
- `POST /api/clientes/grupos` — cli.CriarGrupo
- `GET /api/clientes/grupos/{id}` — cli.ObterGrupo
- `PUT /api/clientes/grupos/{id}` — cli.ActualizarGrupo

**Tags de cliente**
- `GET /api/clientes/tags` — cli.ListarTagsCliente
- `POST /api/clientes/tags` — cli.CriarTagCliente

**Visualização de clientes e relatórios**
- `GET /api/clientes/reports/{report}` — cli.RelatorioClientes
- `GET /api/clientes/` — cli.ListarClientes
- `GET /api/clientes/{id}` — cli.ObterCliente
- `GET /api/clientes/{id}/contactos` — cli.ListarContactosSeguro
- `GET /api/clientes/{id}/enderecos` — cli.ListarEnderecosSeguro
- `GET /api/clientes/{id}/documentos` — cli.ListarDocumentos
- `GET /api/clientes/{id}/limite-credito` — cli.ObterLimiteCreditoSeguro
- `GET /api/clientes/{id}/credito` — cli.ObterLimiteCreditoSeguro
- `GET /api/clientes/{id}/saldo` — cli.ObterSaldoSeguro
- `GET /api/clientes/{id}/pagamentos` — cli.ListarPagamentosSeguro
- `GET /api/clientes/{id}/notas` — cli.ListarNotas
- `GET /api/clientes/{id}/historico` — cli.ListarHistoricoSeguro
- `GET /api/clientes/{id}/descontos` — cli.ListarDescontosCliente

**Criar/editar clientes**
- `POST /api/clientes/` — cli.CriarCliente
- `PUT /api/clientes/{id}` — cli.ActualizarCliente
- `POST /api/clientes/{id}/activar` — cli.ActivarClienteSeguro
- `POST /api/clientes/{id}/bloquear` — cli.BloquearClienteSeguro
- `POST /api/clientes/{id}/desbloquear` — cli.DesbloquearClienteSeguro
- `POST /api/clientes/{id}/contactos` — cli.AdicionarContactoSeguro
- `PUT /api/clientes/{id}/contactos/{contactoId}` — cli.ActualizarContactoSeguro
- `POST /api/clientes/{id}/enderecos` — cli.AdicionarEnderecoSeguro
- `PUT /api/clientes/{id}/enderecos/{endId}` — cli.ActualizarEnderecoSeguro
- `POST /api/clientes/{id}/documentos` — cli.AdicionarDocumento
- `POST /api/clientes/{id}/limite-credito` — cli.DefinirLimiteCredito
- `PUT /api/clientes/{id}/credito` — cli.DefinirLimiteCredito
- `POST /api/clientes/{id}/pagamentos` — cli.RegistarPagamentoSeguro
- `POST /api/clientes/{id}/notas` — cli.AdicionarNota
- `POST /api/clientes/{id}/tags` — cli.AssociarTagCliente
- `POST /api/clientes/{id}/descontos` — cli.CriarDescontoCliente
- `PUT /api/clientes/{id}/descontos/{desc_id}` — cli.ActualizarDescontoCliente

**Eliminar clientes e dados associados**
- `DELETE /api/clientes/{id}/contactos/{contactoId}` — cli.RemoverContactoSeguro
- `DELETE /api/clientes/{id}/enderecos/{endId}` — cli.RemoverEnderecoSeguro
- `DELETE /api/clientes/{id}/documentos/{doc_id}` — cli.RemoverDocumento
- `DELETE /api/clientes/{id}/tags/{tag_id}` — cli.RemoverTagCliente
- `DELETE /api/clientes/{id}/descontos/{desc_id}` — cli.RemoverDescontoCliente

(Grupo "Gestão de crédito" existe mas sem endpoints próprios — apenas comentário.)

---

## /api/produtos

**Categorias, marcas, unidades e atributos**
- `GET /api/produtos/categorias` — prod.ListarCategoriasHierarquia
- `POST /api/produtos/categorias` — prod.CriarCategoriaHierarquia
- `GET /api/produtos/categorias/{id}` — prod.ObterCategoria
- `PUT /api/produtos/categorias/{id}` — prod.ActualizarCategoriaHierarquia
- `DELETE /api/produtos/categorias/{id}` — prod.RemoverCategoria
- `GET /api/produtos/marcas` — prod.ListarMarcas
- `POST /api/produtos/marcas` — prod.CriarMarca
- `GET /api/produtos/marcas/{id}` — prod.ObterMarca
- `PUT /api/produtos/marcas/{id}` — prod.ActualizarMarca
- `GET /api/produtos/unidades` — prod.ListarUnidades
- `POST /api/produtos/unidades` — prod.CriarUnidade
- `PUT /api/produtos/unidades/{id}` — prod.ActualizarUnidade
- `GET /api/produtos/atributos` — prod.ListarAtributos
- `POST /api/produtos/atributos` — prod.CriarAtributo
- `PUT /api/produtos/atributos/{id}` — prod.ActualizarAtributo
- `GET /api/produtos/tags` — prod.ListarTags
- `POST /api/produtos/tags` — prod.CriarTag

**Visualização de produtos, relatórios e stock**
- `GET /api/produtos/reports/mais-vendidos` — prod.RelatorioMaisVendidos
- `GET /api/produtos/reports/sem-movimentos` — prod.RelatorioSemMovimentos
- `GET /api/produtos/reports/stock-critico` — prod.RelatorioStockCritico
- `GET /api/produtos/reports/margem` — prod.RelatorioMargem
- `GET /api/produtos/` — prod.ListarProdutos
- `GET /api/produtos/{id}` — prod.ObterProdutoCompleto
- `GET /api/produtos/{id}/variantes` — prod.ListarVariantesCompleto
- `GET /api/produtos/{id}/imagens` — prod.ListarImagens
- `GET /api/produtos/{id}/precos` — prod.ListarPrecosSeguro
- `GET /api/produtos/{id}/descontos` — prod.ListarDescontos
- `GET /api/produtos/{id}/codigos-barras` — prod.ListarCodigosBarras
- `GET /api/produtos/{id}/componentes` — prod.ListarComponentes
- `GET /api/produtos/{id}/stock` — prod.StockProduto
- `GET /api/produtos/{id}/stock/alertas` — prod.AlertasStockProduto

**Criar/editar produtos e dados associados**
- `POST /api/produtos/` — prod.CriarProduto
- `PUT /api/produtos/{id}` — prod.ActualizarProdutoCompleto
- `POST /api/produtos/{id}/activar` — prod.ActivarProduto
- `POST /api/produtos/{id}/desactivar` — prod.DesactivarProduto
- `POST /api/produtos/{id}/variantes` — prod.CriarVarianteCompleta
- `PUT /api/produtos/{id}/variantes/{var_id}` — prod.ActualizarVariante
- `POST /api/produtos/{id}/imagens` — prod.AdicionarImagem
- `PUT /api/produtos/{id}/imagens/{img_id}` — prod.DefinirImagemPrincipal
- `POST /api/produtos/{id}/precos` — prod.DefinirPrecoSeguro
- `PUT /api/produtos/{id}/precos/{preco_id}` — prod.ActualizarPreco
- `POST /api/produtos/{id}/descontos` — prod.CriarDesconto
- `PUT /api/produtos/{id}/descontos/{desc_id}` — prod.ActualizarDesconto
- `POST /api/produtos/{id}/codigos-barras` — prod.AdicionarCodigoBarras
- `POST /api/produtos/{id}/componentes` — prod.AdicionarComponente
- `PUT /api/produtos/{id}/componentes/{comp_id}` — prod.ActualizarComponente
- `POST /api/produtos/{id}/tags` — prod.AssociarTagProduto

**Eliminar produtos e dados associados**
- `DELETE /api/produtos/{id}/variantes/{var_id}` — prod.RemoverVariante
- `DELETE /api/produtos/{id}/imagens/{img_id}` — prod.RemoverImagem
- `DELETE /api/produtos/{id}/descontos/{desc_id}` — prod.RemoverDesconto
- `DELETE /api/produtos/{id}/codigos-barras/{cb_id}` — prod.RemoverCodigoBarras
- `DELETE /api/produtos/{id}/componentes/{comp_id}` — prod.RemoverComponente
- `DELETE /api/produtos/{id}/tags/{tag_id}` — prod.RemoverTagProduto

---

## /api/stock

**Visualização de stock e relatórios**
- `GET /api/stock/warehouses` — stock.ListarArmazens
- `GET /api/stock/warehouses/{id}` — stock.ObterArmazem
- `GET /api/stock/warehouses/{id}/locations` — stock.ListarLocalizacoes
- `GET /api/stock/items` — stock.ListarStockItems
- `GET /api/stock/items/{id}` — stock.ObterStockItem
- `GET /api/stock/movements` — stock.ListarMovimentosCompleto
- `GET /api/stock/movements/{id}` — stock.ObterMovimento
- `GET /api/stock/adjustments` — stock.ListarAjustesCompleto
- `GET /api/stock/adjustments/{id}` — stock.ObterAjuste
- `GET /api/stock/transfers` — stock.ListarTransferenciasCompleto
- `GET /api/stock/transfers/{id}` — stock.ObterTransferencia
- `GET /api/stock/reservations` — stock.ListarReservas
- `GET /api/stock/reservations/{id}` — stock.ObterReserva
- `GET /api/stock/batches/a-expirar` — stock.LotesAExpirar
- `GET /api/stock/batches` — stock.ListarLotes
- `GET /api/stock/batches/{id}` — stock.ObterLote
- `GET /api/stock/serials` — stock.ListarSeriais
- `GET /api/stock/serials/{serial}` — stock.ObterSerial
- `GET /api/stock/counts` — stock.ListarContagens
- `GET /api/stock/counts/{id}` — stock.ObterContagem
- `GET /api/stock/alerts` — stock.ListarAlertas
- `GET /api/stock/reports/position` — stock.RelatorioPosicao
- `GET /api/stock/reports/movements-summary` — stock.RelatorioResumoMovimentos
- `GET /api/stock/reports/low-stock` — stock.RelatorioStockBaixo
- `GET /api/stock/reports/expiring-batches` — stock.RelatorioLotesExpirar
- `GET /api/stock/reports/count-divergences` — stock.RelatorioDivergencias
- `GET /api/stock/reports/valuation` — stock.RelatorioValorizacao

**Movimentações e gestão de stock**
- `POST /api/stock/warehouses` — stock.CriarArmazem
- `PUT /api/stock/warehouses/{id}` — stock.ActualizarArmazem
- `POST /api/stock/warehouses/{id}/activar` — stock.ActivarArmazem
- `POST /api/stock/warehouses/{id}/desactivar` — stock.DesactivarArmazem
- `POST /api/stock/warehouses/{id}/locations` — stock.CriarLocalizacao
- `PUT /api/stock/warehouses/{id}/locations/{loc_id}` — stock.ActualizarLocalizacao
- `DELETE /api/stock/warehouses/{id}/locations/{loc_id}` — stock.RemoverLocalizacaoSeguro
- `POST /api/stock/items` — stock.InicializarStockItemSeguro
- `PUT /api/stock/items/{id}/minimos` — stock.DefinirMinimoMaximoSeguro
- `POST /api/stock/movements` — stock.RegistarMovimentoSeguro
- `POST /api/stock/adjustments` — stock.CriarAjusteSeguro
- `POST /api/stock/transfers` — stock.CriarTransferenciaCompleta
- `POST /api/stock/transfers/{id}/confirmar` — stock.ConfirmarTransferencia
- `POST /api/stock/transfers/{id}/receber` — stock.ReceberTransferencia
- `POST /api/stock/transfers/{id}/cancelar` — stock.CancelarTransferencia
- `POST /api/stock/reservations` — stock.CriarReserva
- `POST /api/stock/reservations/{id}/liberar` — stock.LiberarReserva
- `POST /api/stock/reservations/{id}/consumir` — stock.ConsumirReserva
- `POST /api/stock/batches` — stock.CriarLote
- `PUT /api/stock/batches/{id}` — stock.ActualizarLote
- `POST /api/stock/serials` — stock.CriarSerial
- `PUT /api/stock/serials/{id}/status` — stock.ActualizarStatusSerial
- `POST /api/stock/counts` — stock.CriarContagem
- `POST /api/stock/counts/{id}/items` — stock.AdicionarItemContagem
- `PUT /api/stock/counts/{id}/items/{item_id}` — stock.ActualizarItemContagem
- `POST /api/stock/counts/{id}/fechar` — stock.FecharContagem
- `POST /api/stock/counts/{id}/cancelar` — stock.CancelarContagem
- `POST /api/stock/alerts/{id}/resolver` — stock.ResolverAlerta
- `POST /api/stock/alerts/{id}/ignorar` — stock.IgnorarAlerta

---

## /api/compras

**Visualização**
- `GET /api/compras/purchase-requests` — compras.ListarRequisicoesCompra
- `GET /api/compras/purchase-orders` — compras.ListarOrdensCompra
- `GET /api/compras/purchase-receipts` — compras.ListarRecepcoesCompra
- `GET /api/compras/purchase-returns` — compras.ListarDevolucoesCompra
- `GET /api/compras/purchase-invoices` — compras.ListarFacturasCompra
- `GET /api/compras/purchase-payments` — compras.ListarPagamentosCompra

**Criar requisições, ordens e itens**
- `POST /api/compras/purchase-requests` — compras.CriarRequisicaoCompra
- `POST /api/compras/purchase-request-items` — compras.AdicionarItemRequisicaoCompra
- `POST /api/compras/purchase-orders` — compras.CriarOrdemCompra
- `POST /api/compras/purchase-order-items` — compras.AdicionarItemOrdemCompra

**Aprovar/receber/devolver/facturar/pagar**
- `POST /api/compras/purchase-receipts` — compras.CriarRecepcaoCompra
- `POST /api/compras/purchase-receipt-items` — compras.AdicionarItemRecepcaoCompra
- `POST /api/compras/purchase-returns` — compras.CriarDevolucaoCompra
- `POST /api/compras/purchase-return-items` — compras.AdicionarItemDevolucaoCompra
- `POST /api/compras/purchase-invoices` — compras.CriarFacturaCompra
- `POST /api/compras/purchase-invoice-items` — compras.AdicionarItemFacturaCompra
- `POST /api/compras/purchase-payments` — compras.CriarPagamentoCompra
- `POST /api/compras/purchase-payment-items` — compras.AdicionarItemPagamentoCompra

---

## /api/aprovacoes

**Flows (configuração)**
- `GET /api/aprovacoes/flows` — aprov.ListarFlows
- `POST /api/aprovacoes/flows` — aprov.CriarFlow
- `GET /api/aprovacoes/flows/{id}` — aprov.ObterFlow
- `PUT /api/aprovacoes/flows/{id}` — aprov.ActualizarFlow
- `DELETE /api/aprovacoes/flows/{id}` — aprov.EliminarFlow

**Requests (qualquer utilizador autenticado)**
- `GET /api/aprovacoes/requests` — aprov.ListarRequests
- `GET /api/aprovacoes/requests/pendentes-meu-cargo` — aprov.ListarPendentesCargoActual
- `GET /api/aprovacoes/requests/{id}` — aprov.ObterRequest
- `POST /api/aprovacoes/requests/{id}/decidir` — aprov.DecidirRequest
- `POST /api/aprovacoes/requests/{id}/cancelar` — aprov.CancelarRequest

---

## /api/tesouraria

**Visualização**
- `GET /api/tesouraria/contas-bancarias` — tesouraria.ListarContasBancarias
- `GET /api/tesouraria/caixas` — tesouraria.ListarCaixas
- `GET /api/tesouraria/movimentos` — tesouraria.ListarMovimentos
- `GET /api/tesouraria/reconciliacoes` — tesouraria.ListarReconciliacoes

**Movimentos e contas**
- `POST /api/tesouraria/contas-bancarias` — tesouraria.CriarContaBancaria
- `POST /api/tesouraria/caixas` — tesouraria.CriarCaixa
- `POST /api/tesouraria/movimentos` — tesouraria.CriarMovimento

**Reconciliação bancária**
- `POST /api/tesouraria/reconciliacoes` — tesouraria.CriarReconciliacao
- `POST /api/tesouraria/reconciliacoes/{id}/fechar` — tesouraria.FecharReconciliacao

---

## /api/escolar

**Visualização geral**
- `GET /api/escolar/years` — escolar.ListarAnosLectivos
- `GET /api/escolar/years/{id}` — escolar.ObterAnoLectivo
- `GET /api/escolar/terms` — escolar.ListarPeriodosLectivos
- `GET /api/escolar/classes` — escolar.ListarTurmas
- `GET /api/escolar/classes/{id}` — escolar.ObterTurma
- `GET /api/escolar/subjects` — escolar.ListarDisciplinas
- `GET /api/escolar/subjects/{id}` — escolar.ObterDisciplina
- `GET /api/escolar/students` — escolar.ListarAlunos
- `GET /api/escolar/students/{id}` — escolar.ObterAluno
- `GET /api/escolar/enrollments` — escolar.ListarMatriculas
- `GET /api/escolar/enrollments/{id}` — escolar.ObterMatricula
- `GET /api/escolar/student-roles` — escolar.ListarCargosAlunos
- `GET /api/escolar/teacher-roles` — escolar.ListarCargosProfessores
- `GET /api/escolar/attendance` — escolar.ListarFrequencias
- `GET /api/escolar/attendance/{id}` — escolar.ObterFrequencia
- `GET /api/escolar/grades` — escolar.ListarNotas
- `GET /api/escolar/grades/{id}` — escolar.ObterNota
- `GET /api/escolar/grade-items` — escolar.ListarAvaliacoesV2
- `GET /api/escolar/fee-plans` — escolar.ListarPlanosPropinas
- `GET /api/escolar/fee-plans/{id}` — escolar.ObterPlanoPropina
- `GET /api/escolar/student-invoices` — escolar.ListarCobrancasAluno
- `GET /api/escolar/student-invoices/{id}` — escolar.ObterCobrancaAluno
- `GET /api/escolar/payments/{id}` — escolar.ObterPagamentoEscolar
- `GET /api/escolar/payments/{id}/receipt` — escolar.ObterReciboEscolar
- `GET /api/escolar/library/books` — escolar.ListarLivros
- `GET /api/escolar/library/loans` — escolar.ListarEmprestimos
- `GET /api/escolar/messages` — escolar.ListarMensagensEscolares
- `GET /api/escolar/notificacoes` — escolar.ListarNotificacoesEscolares
- `GET /api/escolar/teachers` — escolar.ListarProfessores
- `GET /api/escolar/teachers/{id}` — escolar.ObterProfessor
- `GET /api/escolar/levels` — escolar.ListarNiveisEnsino
- `GET /api/escolar/levels/{id}` — escolar.ObterNivelEnsino
- `GET /api/escolar/cycles` — escolar.ListarCiclos
- `GET /api/escolar/cycles/{id}` — escolar.ObterCiclo
- `GET /api/escolar/series` — escolar.ListarSeries
- `GET /api/escolar/series/{id}` — escolar.ObterSerie
- `GET /api/escolar/courses` — escolar.ListarCursos
- `GET /api/escolar/courses/{id}` — escolar.ObterCurso
- `GET /api/escolar/course-subjects` — escolar.ListarCurriculo
- `GET /api/escolar/course-subjects/{id}` — escolar.ObterItemCurriculo
- `GET /api/escolar/course-subjects/{id}/terms` — escolar.ListarPeriodosDisciplina
- `GET /api/escolar/dashboard` — escolar.DashboardEscolar
- `GET /api/escolar/dashboard/direction` — escolar.DashboardDireccao

**Relatórios**
- `GET /api/escolar/reports/academic-summary` — escolar.RelatorioAcademico
- `GET /api/escolar/reports/financial-summary` — escolar.RelatorioFinanceiroEscolar
- `GET /api/escolar/reports/delinquency` — escolar.RelatorioInadimplencia
- `GET /api/escolar/report-cards/{student_id}` — escolar.ObterBoletimV2

**Gestão de turmas, anos, disciplinas, atribuições e estrutura académica**
- `POST /api/escolar/years` — escolar.CriarAnoLectivo
- `PUT /api/escolar/years/{id}` — escolar.ActualizarAnoLectivo
- `POST /api/escolar/years/{id}/activar` — escolar.ActivarAnoLectivo
- `POST /api/escolar/years/{id}/close` — escolar.EncerrarAnoLectivo
- `POST /api/escolar/years/{id}/terms` — escolar.CriarPeriodoLectivo
- `PUT /api/escolar/terms/{id}` — escolar.ActualizarPeriodoLectivo
- `DELETE /api/escolar/terms/{id}` — escolar.EliminarPeriodoLectivo
- `POST /api/escolar/classes` — escolar.CriarTurmaV2
- `PUT /api/escolar/classes/{id}` — escolar.ActualizarTurmaV2
- `POST /api/escolar/classes/{id}/assign-teacher` — escolar.AssociarProfessorDirector
- `POST /api/escolar/subjects` — escolar.CriarDisciplina
- `PUT /api/escolar/subjects/{id}` — escolar.ActualizarDisciplina
- `DELETE /api/escolar/subjects/{id}` — escolar.RemoverDisciplina
- `POST /api/escolar/teacher-assignments` — escolar.AtribuirProfessor
- `POST /api/escolar/student-roles` — escolar.AtribuirCargoAluno
- `PUT /api/escolar/student-roles/{id}` — escolar.ActualizarCargoAluno
- `POST /api/escolar/student-roles/{id}/revoke` — escolar.RevogarCargoAluno
- `POST /api/escolar/teacher-roles` — escolar.AtribuirCargoProfessor
- `PUT /api/escolar/teacher-roles/{id}` — escolar.ActualizarCargoProfessor
- `POST /api/escolar/teacher-roles/{id}/revoke` — escolar.RevogarCargoProfessor
- `POST /api/escolar/teachers` — escolar.CriarProfessor
- `PUT /api/escolar/teachers/{id}` — escolar.ActualizarProfessor
- `DELETE /api/escolar/teachers/{id}` — escolar.RemoverProfessor
- `GET /api/escolar/teachers/{id}/rh-link` — escolar.ObterLigacaoRH
- `POST /api/escolar/teachers/{id}/rh-link` — escolar.LigarRH
- `POST /api/escolar/levels` — escolar.CriarNivelEnsino
- `PUT /api/escolar/levels/{id}` — escolar.ActualizarNivelEnsino
- `DELETE /api/escolar/levels/{id}` — escolar.RemoverNivelEnsino
- `POST /api/escolar/cycles` — escolar.CriarCiclo
- `PUT /api/escolar/cycles/{id}` — escolar.ActualizarCiclo
- `DELETE /api/escolar/cycles/{id}` — escolar.RemoverCiclo
- `POST /api/escolar/series` — escolar.CriarSerie
- `PUT /api/escolar/series/{id}` — escolar.ActualizarSerie
- `DELETE /api/escolar/series/{id}` — escolar.RemoverSerie
- `POST /api/escolar/courses` — escolar.CriarCurso
- `PUT /api/escolar/courses/{id}` — escolar.ActualizarCurso
- `DELETE /api/escolar/courses/{id}` — escolar.RemoverCurso
- `POST /api/escolar/course-subjects` — escolar.CriarItemCurriculo
- `PUT /api/escolar/course-subjects/{id}` — escolar.ActualizarItemCurriculo
- `DELETE /api/escolar/course-subjects/{id}` — escolar.RemoverItemCurriculo
- `POST /api/escolar/course-subjects/{id}/terms` — escolar.CriarPeriodoDisciplina
- `PUT /api/escolar/course-subjects/{id}/terms/{termId}` — escolar.ActualizarPeriodoDisciplina
- `DELETE /api/escolar/course-subjects/{id}/terms/{termId}` — escolar.RemoverPeriodoDisciplina

**Alunos e matrículas**
- `POST /api/escolar/students` — escolar.CriarAluno
- `PUT /api/escolar/students/{id}` — escolar.ActualizarAluno
- `POST /api/escolar/students/{id}/guardians` — escolar.AdicionarEncarregado
- `GET /api/escolar/students/{id}/client-link` — escolar.ObterLigacaoCliente
- `POST /api/escolar/students/{id}/client-link` — escolar.LigarCliente

**Matrículas**
- `POST /api/escolar/enrollments` — escolar.CriarMatriculaV2
- `POST /api/escolar/enrollments/{id}/transfer` — escolar.TransferirMatriculaV2
- `POST /api/escolar/enrollments/{id}/cancel` — escolar.CancelarMatriculaV2

**Presenças e assiduidade**
- `POST /api/escolar/attendance` — escolar.LancarFrequencia
- `PUT /api/escolar/attendance/{id}` — escolar.CorrigirFrequencia

**Lançamento de notas**
- `POST /api/escolar/grade-items` — escolar.CriarAvaliacaoV2
- `POST /api/escolar/grade-items/{id}/publish` — escolar.PublicarAvaliacao
- `POST /api/escolar/grades` — escolar.LancarNotasV2
- `PUT /api/escolar/grades/{id}` — escolar.CorrigirNotaV2

**Propinas e financeiro escolar**
- `POST /api/escolar/fee-plans` — escolar.CriarPlanoPropina
- `POST /api/escolar/fee-plans/{id}/generate` — escolar.GerarCobrancasPlano
- `POST /api/escolar/student-invoices` — escolar.GerarCobrancaAluno
- `POST /api/escolar/student-invoices/{id}/emit` — escolar.EmitirCobrancaAluno
- `POST /api/escolar/student-invoices/{id}/discount` — escolar.AplicarDescontoCobrancaV2
- `POST /api/escolar/payments` — escolar.RegistarPagamentoEscolarV2
- `POST /api/escolar/payments/callback` — escolar.CallbackPagamentoEscolar
- `GET /api/escolar/config/financial` — escolar.ObterConfigFinanceira
- `POST /api/escolar/config/financial` — escolar.GravarConfigFinanceira

**Biblioteca**
- `POST /api/escolar/library/books` — escolar.CriarLivro
- `POST /api/escolar/library/loans` — escolar.RegistarEmprestimo
- `POST /api/escolar/library/loans/{id}/return` — escolar.ConfirmarDevolucao

**Comunicação escolar**
- `POST /api/escolar/messages` — escolar.CriarMensagemEscolar
- `POST /api/escolar/messages/{id}/publish` — escolar.PublicarMensagemEscolar

**Horários e calendário escolar**
- `GET /api/escolar/time-slots` — escolar.ListarTimeSlots
- `POST /api/escolar/time-slots` — escolar.CriarTimeSlot
- `GET /api/escolar/timetables/class/{class_id}` — escolar.ListarHorarioTurma
- `GET /api/escolar/timetables/teacher/{teacher_id}` — escolar.ListarHorarioProfessor
- `POST /api/escolar/timetables` — escolar.CriarHorario
- `PUT /api/escolar/timetables/{id}` — escolar.ActualizarHorario
- `DELETE /api/escolar/timetables/{id}` — escolar.RemoverHorario

**Calendário escolar**
- `GET /api/escolar/calendar-event-types` — escolar.ListarTiposEvento
- `POST /api/escolar/calendar-event-types` — escolar.CriarTipoEvento
- `GET /api/escolar/calendar-events` — escolar.ListarEventosCalendario
- `GET /api/escolar/calendar-events/{id}` — escolar.ObterEventoCalendario
- `POST /api/escolar/calendar-events` — escolar.CriarEventoCalendario
- `PUT /api/escolar/calendar-events/{id}` — escolar.ActualizarEventoCalendario
- `DELETE /api/escolar/calendar-events/{id}` — escolar.RemoverEventoCalendario

**Ocorrências disciplinares**
- `GET /api/escolar/incident-types` — escolar.ListarTiposOcorrencia
- `POST /api/escolar/incident-types` — escolar.CriarTipoOcorrencia
- `GET /api/escolar/incidents` — escolar.ListarOcorrencias
- `GET /api/escolar/incidents/{id}` — escolar.ObterOcorrencia
- `POST /api/escolar/incidents` — escolar.CriarOcorrencia
- `PUT /api/escolar/incidents/{id}` — escolar.ActualizarOcorrencia
- `POST /api/escolar/incidents/{id}/anexos` — escolar.UploadAnexoIncidente
- `GET /api/escolar/incidents/{id}/anexos/{idx}/download` — escolar.DownloadAnexoIncidente
- `DELETE /api/escolar/incidents/{id}/anexos/{idx}` — escolar.EliminarAnexoIncidente
- `POST /api/escolar/sanctions` — escolar.CriarSancao
- `POST /api/escolar/merits` — escolar.CriarMerito

**Tarefas escolares (professor)**
- `GET /api/escolar/tasks` — escolar.ListarTarefasEscolares
- `POST /api/escolar/tasks` — escolar.CriarTarefaEscolar
- `GET /api/escolar/tasks/{id}` — escolar.ObterTarefaEscolar

**Portal do aluno (activação/gestão pelo admin)**
- `GET /api/escolar/portal/alunos` — escolar.PortalListarAlunos
- `GET /api/escolar/portal/sessions` — escolar.PortalRelatorioSessoes
- `POST /api/escolar/classes/{id}/portal/invite-all` — escolar.PortalInvitarTurma
- `GET /api/escolar/students/{id}/portal/status` — escolar.PortalStatusAluno
- `POST /api/escolar/students/{id}/portal/activate` — escolar.PortalActivarAluno
- `POST /api/escolar/students/{id}/portal/deactivate` — escolar.PortalDesactivarAluno
- `POST /api/escolar/students/{id}/portal/invite` — escolar.PortalConvidarAluno
- `POST /api/escolar/students/{id}/portal/reset-senha` — escolar.PortalResetSenhaAluno

**Cobranças — cancelamento, parcelas, emissão com referência**
- `POST /api/escolar/student-invoices/{id}/cancel` — escolar.CancelarCobrancaAluno
- `POST /api/escolar/student-invoices/{id}/emit` — escolar.EmitirCobrancaComReferencia
- `POST /api/escolar/student-invoices/{id}/parcelas` — escolar.CriarParcelasCobranca
- `GET /api/escolar/student-invoices/{id}/parcelas` — escolar.ListarParcelasCobranca

**Bolsas/Isenções**
- `GET /api/escolar/bolsas` — escolar.ListarBolsas
- `POST /api/escolar/bolsas` — escolar.CriarBolsa
- `DELETE /api/escolar/bolsas/{id}` — escolar.RemoverBolsa

**Relatório aging**
- `GET /api/escolar/relatorios/aging` — escolar.RelatorioAging

**Encarregado — convidar/reset admin**
- `POST /api/escolar/encarregados/convidar` — escolar.EncarregadoConvidar
- `POST /api/escolar/encarregados/reset-senha` — escolar.EncarregadoResetSenha

---

## /api/impostos

**Visualização**
- `GET /api/impostos/regimes` — impostos.ListarRegimes
- `GET /api/impostos/isencoes` — impostos.ListarIsencoes
- `GET /api/impostos/retencoes` — impostos.ListarRetencoes
- `GET /api/impostos/retencoes/{id}/transaccoes` — impostos.ListarTransaccoesRetencao
- `GET /api/impostos/declaracoes` — impostos.ListarDeclaracoes
- `GET /api/impostos/declaracoes/{id}` — impostos.ObterDeclaracao
- `GET /api/impostos/declaracoes/{id}/linhas` — impostos.ListarLinhasDeclaracao
- `GET /api/impostos/certificados` — impostos.ListarCertificados
- `GET /api/impostos/certificados/{id}/download` — impostos.DownloadCertificadoFicheiro

**Gestão de regras fiscais**
- `POST /api/impostos/regimes` — impostos.CriarRegime
- `POST /api/impostos/isencoes` — impostos.CriarIsencao
- `PUT /api/impostos/isencoes/{id}` — impostos.ActualizarIsencao
- `DELETE /api/impostos/isencoes/{id}` — impostos.RemoverIsencao
- `POST /api/impostos/retencoes` — impostos.CriarOuRegistarRetencao
- `POST /api/impostos/declaracoes` — impostos.CriarDeclaracao
- `POST /api/impostos/declaracoes/{id}/submeter` — impostos.SubmeterDeclaracao
- `POST /api/impostos/certificados` — impostos.CriarCertificado
- `POST /api/impostos/certificados/{id}/upload` — impostos.UploadCertificadoFicheiro

---

## /api/contabilidade

**account-types**
- `GET /api/contabilidade/account-types/` — contab.ListarTiposConta
- `GET /api/contabilidade/account-types/{id}` — contab.ObterTipoConta
- `POST /api/contabilidade/account-types/` — contab.CriarTipoConta
- `PUT /api/contabilidade/account-types/{id}` — contab.ActualizarTipoConta
- `DELETE /api/contabilidade/account-types/{id}` — contab.EliminarTipoConta

**accounts**
- `GET /api/contabilidade/accounts/` — contab.ListarContas
- `GET /api/contabilidade/accounts/{id}` — contab.ObterConta
- `POST /api/contabilidade/accounts/` — contab.CriarConta
- `PUT /api/contabilidade/accounts/{id}` — contab.ActualizarConta
- `DELETE /api/contabilidade/accounts/{id}` — contab.EliminarConta

**tax-groups**
- `GET /api/contabilidade/tax-groups/` — contab.ListarGruposImposto
- `POST /api/contabilidade/tax-groups/` — contab.CriarGrupoImposto
- `PUT /api/contabilidade/tax-groups/{id}` — contab.ActualizarGrupoImposto

**taxes**
- `GET /api/contabilidade/taxes/` — contab.ListarTaxas
- `GET /api/contabilidade/taxes/{id}` — contab.ObterTaxa
- `POST /api/contabilidade/taxes/` — contab.CriarTaxa
- `PUT /api/contabilidade/taxes/{id}` — contab.ActualizarTaxa
- `POST /api/contabilidade/taxes/{id}/rules` — contab.AdicionarRegraTaxa

**tax-transactions**
- `GET /api/contabilidade/tax-transactions/` — contab.ListarTransacoesImposto
- `GET /api/contabilidade/tax-transactions/{id}` — contab.ObterTransacaoImposto
- `POST /api/contabilidade/tax-transactions/` — contab.RegistarTransacaoImposto

**journals**
- `GET /api/contabilidade/journals/` — contab.ListarDiarios
- `POST /api/contabilidade/journals/` — contab.CriarDiario
- `PUT /api/contabilidade/journals/{id}` — contab.ActualizarDiario

**journal-entries**
- `GET /api/contabilidade/journal-entries/` — contab.ListarLancamentos
- `GET /api/contabilidade/journal-entries/{id}` — contab.ObterLancamento
- `POST /api/contabilidade/journal-entries/` — contab.CriarLancamento
- `PUT /api/contabilidade/journal-entries/{id}` — contab.ActualizarLancamento
- `DELETE /api/contabilidade/journal-entries/{id}` — contab.EstornarLancamento
- `POST /api/contabilidade/journal-entries/{id}/lines` — contab.AdicionarLinhaLancamento

**fiscal-years**
- `GET /api/contabilidade/fiscal-years/` — contab.ListarAnosFiscais
- `GET /api/contabilidade/fiscal-years/{id}` — contab.ObterAnoFiscal
- `POST /api/contabilidade/fiscal-years/` — contab.CriarAnoFiscal
- `PUT /api/contabilidade/fiscal-years/{id}` — contab.ActualizarAnoFiscal
- `POST /api/contabilidade/fiscal-years/{id}/fechar` — contab.FecharAnoFiscal

**fiscal-periods**
- `GET /api/contabilidade/fiscal-periods/` — contab.ListarPeriodosFiscais
- `GET /api/contabilidade/fiscal-periods/{id}` — contab.ObterPeriodoFiscal
- `POST /api/contabilidade/fiscal-periods/` — contab.CriarPeriodoFiscal
- `POST /api/contabilidade/fiscal-periods/{id}/abrir` — contab.AbrirPeriodoFiscal
- `POST /api/contabilidade/fiscal-periods/{id}/fechar` — contab.FecharPeriodoFiscal

**fixed-assets**
- `GET /api/contabilidade/fixed-assets/` — contab.ListarAtivosFixos
- `GET /api/contabilidade/fixed-assets/{id}` — contab.ObterAtivoFixo
- `GET /api/contabilidade/fixed-assets/{id}/schedule` — contab.ObterPlanoAmortizacao
- `POST /api/contabilidade/fixed-assets/` — contab.CriarAtivoFixo
- `PUT /api/contabilidade/fixed-assets/{id}` — contab.ActualizarAtivoFixo
- `POST /api/contabilidade/fixed-assets/{id}/alienar` — contab.AlienarAtivoFixo

**depreciation**
- `GET /api/contabilidade/depreciation/` — contab.ListarAmortizacoes
- `GET /api/contabilidade/depreciation/{id}` — contab.ObterAmortizacao
- `POST /api/contabilidade/depreciation/processar` — contab.ProcessarAmortizacoes
- `POST /api/contabilidade/depreciation/{id}/cancelar` — contab.CancelarAmortizacao

**budgets**
- `GET /api/contabilidade/budgets/vs-realizado` — contab.OrcadoVsRealizado
- `GET /api/contabilidade/budgets/` — contab.ListarOrcamentos
- `POST /api/contabilidade/budgets/` — contab.CriarOrcamento
- `PUT /api/contabilidade/budgets/{id}` — contab.ActualizarOrcamento
- `DELETE /api/contabilidade/budgets/{id}` — contab.EliminarOrcamento

**period-closings**
- `GET /api/contabilidade/period-closings/` — contab.ListarEncerramentos
- `GET /api/contabilidade/period-closings/{id}` — contab.ObterEncerramento
- `POST /api/contabilidade/period-closings/` — contab.IniciarEncerramento
- `POST /api/contabilidade/period-closings/{id}/verificar` — contab.ExecutarVerificacoes
- `POST /api/contabilidade/period-closings/{id}/encerrar` — contab.ConfirmarEncerramento
- `POST /api/contabilidade/period-closings/{id}/reabrir` — contab.ReabrirEncerramento

**reports**
- `GET /api/contabilidade/reports/trial-balance` — contab.BalanceteGeral
- `GET /api/contabilidade/reports/balance-sheet` — contab.Balanco
- `GET /api/contabilidade/reports/income-statement` — contab.DemonstracaoResultados
- `GET /api/contabilidade/reports/general-ledger` — contab.RazaoGeral
- `GET /api/contabilidade/reports/depreciation-summary` — contab.ResumoAmortizacoes
- `GET /api/contabilidade/reports/budget-execution` — contab.ExecucaoOrcamental
- `GET /api/contabilidade/reports/` — contab.ListarRelatorios
- `GET /api/contabilidade/reports/{id}` — contab.ObterRelatorio
- `POST /api/contabilidade/reports/generate` — contab.GerarRelatorio

---

## /api/centros-custo

**cost-centers**
- `GET /api/centros-custo/cost-centers/` — centros.ListarCentrosCusto
- `GET /api/centros-custo/cost-centers/{id}` — centros.ObterCentroCusto
- `POST /api/centros-custo/cost-centers/` — centros.CriarCentroCusto
- `PUT /api/centros-custo/cost-centers/{id}` — centros.ActualizarCentroCusto
- `DELETE /api/centros-custo/cost-centers/{id}` — centros.EliminarCentroCusto

**budgets**
- `GET /api/centros-custo/budgets/vs-realizado` — centros.OrcadoVsRealizadoCC
- `GET /api/centros-custo/budgets/` — centros.ListarOrcamentosCC
- `POST /api/centros-custo/budgets/` — centros.CriarOrcamentoCC
- `PUT /api/centros-custo/budgets/{id}` — centros.ActualizarOrcamentoCC
- `DELETE /api/centros-custo/budgets/{id}` — centros.EliminarOrcamentoCC

**allocations**
- `GET /api/centros-custo/allocations/` — centros.ListarAlocacoesCC
- `GET /api/centros-custo/allocations/{id}` — centros.ObterAlocacaoCC
- `POST /api/centros-custo/allocations/` — centros.CriarAlocacaoCC

---

## /api/faturacao

**Visualização de documentos e recibos**
- `GET /api/faturacao/quotes` — fat.ListarOrcamentos
- `GET /api/faturacao/quotes/{id}` — fat.ObterOrcamento
- `GET /api/faturacao/orders` — fat.ListarEncomendas
- `GET /api/faturacao/invoices` — fat.ListarFaturas
- `GET /api/faturacao/invoices/{id}` — fat.ObterFatura
- `GET /api/faturacao/receipts` — fat.ListarRecibos
- `GET /api/faturacao/credit-notes` — fat.ListarNotasCredito

**Configuração de séries de faturação**
- `GET /api/faturacao/series` — fat.ListarSeries
- `POST /api/faturacao/series` — fat.CriarSerie
- `POST /api/faturacao/series/{id}/activar` — fat.ActivarSerie
- `POST /api/faturacao/series/{id}/desactivar` — fat.DesactivarSerie

**Orçamentos**
- `POST /api/faturacao/quotes` — fat.CriarOrcamento
- `POST /api/faturacao/quotes/{id}/enviar` — fat.EnviarOrcamento
- `POST /api/faturacao/quotes/{id}/aprovar` — fat.AprovarOrcamento
- `POST /api/faturacao/quotes/{id}/rejeitar` — fat.RejeitarOrcamento
- `POST /api/faturacao/quotes/{id}/items` — fat.AdicionarItemOrcamento
- `DELETE /api/faturacao/quotes/{id}/items/{itemId}` — fat.RemoverItemOrcamento

**Encomendas**
- `POST /api/faturacao/orders` — fat.CriarEncomenda
- `POST /api/faturacao/orders/{id}/confirmar` — fat.ConfirmarEncomenda
- `POST /api/faturacao/orders/{id}/cancelar` — fat.CancelarEncomenda

**Faturas**
- `POST /api/faturacao/invoices` — fat.CriarFatura
- `POST /api/faturacao/invoices/{id}/items` — fat.AdicionarItemFaturaFiscal
- `POST /api/faturacao/invoices/{id}/emitir` — fat.EmitirFaturaFiscal
- `POST /api/faturacao/invoices/{id}/cancelar` — fat.CancelarFatura

**Notas de crédito e recibos**
- `POST /api/faturacao/credit-notes` — fat.CriarNotaCredito
- `POST /api/faturacao/receipts` — fat.CriarRecibo

---

## /api/recrutamento
- `GET /api/recrutamento/dashboard` — recrut.Dashboard

**vagas**
- `GET /api/recrutamento/vagas/` — recrut.ListarVagas
- `GET /api/recrutamento/vagas/{id}` — recrut.ObterVaga
- `POST /api/recrutamento/vagas/` — recrut.CriarVaga
- `PUT /api/recrutamento/vagas/{id}` — recrut.ActualizarVaga
- `DELETE /api/recrutamento/vagas/{id}` — recrut.RemoverVaga
- `POST /api/recrutamento/vagas/{id}/activar` — recrut.ActivarVaga
- `POST /api/recrutamento/vagas/{id}/desactivar` — recrut.DesactivarVaga

**candidaturas**
- `GET /api/recrutamento/candidaturas/` — recrut.ListarCandidaturas
- `GET /api/recrutamento/candidaturas/{id}` — recrut.ObterCandidatura
- `GET /api/recrutamento/candidaturas/{id}/cv` — recrut.DownloadCV
- `GET /api/recrutamento/candidaturas/{id}/carta` — recrut.DownloadCarta
- `PUT /api/recrutamento/candidaturas/{id}/estado` — recrut.MoverCandidatura
- `POST /api/recrutamento/candidaturas/{id}/avaliar` — recrut.AvaliarCandidatura
- `POST /api/recrutamento/candidaturas/{id}/entrevista` — recrut.AgendarEntrevista
- `POST /api/recrutamento/candidaturas/{id}/notas` — recrut.AdicionarNota
- `POST /api/recrutamento/candidaturas/{id}/contratar` — recrut.ContratarCandidato

**contactos**
- `GET /api/recrutamento/contactos/` — recrut.ListarContactos
- `POST /api/recrutamento/contactos/{id}/lido` — recrut.MarcarLido

**Campos por vaga (Form Builder)**
- `GET /api/recrutamento/vagas/{vagaID}/campos/` — recrut.ListarVagaCampos
- `POST /api/recrutamento/vagas/{vagaID}/campos/` — recrut.CriarVagaCampo
- `PUT /api/recrutamento/vagas/{vagaID}/campos/{campoID}` — recrut.ActualizarVagaCampo
- `DELETE /api/recrutamento/vagas/{vagaID}/campos/{campoID}` — recrut.EliminarVagaCampo

**campos-custom**
- `GET /api/recrutamento/campos-custom/` — recrut.ListarCamposCustom
- `POST /api/recrutamento/campos-custom/` — recrut.CriarCampoCustom
- `PUT /api/recrutamento/campos-custom/{id}` — recrut.ActualizarCampoCustom
- `DELETE /api/recrutamento/campos-custom/{id}` — recrut.EliminarCampoCustom

**config-notificacoes**
- `GET /api/recrutamento/config-notificacoes/` — recrut.ObterConfigNotificacoes
- `PUT /api/recrutamento/config-notificacoes/` — recrut.ActualizarConfigNotificacoes

---

## /api/crm

**leads**
- `GET /api/crm/leads/` — crm.ListarLeads
- `GET /api/crm/leads/{id}` — crm.ObterLead
- `POST /api/crm/leads/` — crm.CriarLead
- `PUT /api/crm/leads/{id}` — crm.ActualizarLead
- `PUT /api/crm/leads/{id}/estado` — crm.MoverLead
- `POST /api/crm/leads/{id}/converter` — crm.ConverterLead
- `DELETE /api/crm/leads/{id}` — crm.RemoverLead

**oportunidades**
- `GET /api/crm/oportunidades/` — crm.ListarOportunidades
- `GET /api/crm/oportunidades/{id}` — crm.ObterOportunidade
- `POST /api/crm/oportunidades/` — crm.CriarOportunidade
- `PUT /api/crm/oportunidades/{id}` — crm.ActualizarOportunidade
- `PUT /api/crm/oportunidades/{id}/estagio` — crm.MoverOportunidade
- `POST /api/crm/oportunidades/{id}/perder` — crm.MarcarPerdida
- `DELETE /api/crm/oportunidades/{id}` — crm.RemoverOportunidade

**atividades**
- `GET /api/crm/atividades/` — crm.ListarAtividades
- `GET /api/crm/atividades/{id}` — crm.ObterAtividade
- `POST /api/crm/atividades/` — crm.CriarAtividade
- `PUT /api/crm/atividades/{id}` — crm.ActualizarAtividade
- `POST /api/crm/atividades/{id}/concluir` — crm.ConcluirAtividade
- `DELETE /api/crm/atividades/{id}` — crm.RemoverAtividade

---

## /api/pos

**Visualização e operação do terminal**
- `GET /api/pos/produtos` — pos.BuscarProdutos
- `GET /api/pos/sessoes/` — pos.ListarSessoes
- `POST /api/pos/sessoes/` — pos.AbrirSessao
- `GET /api/pos/sessoes/atual` — pos.ObterSessaoAtual
- `POST /api/pos/sessoes/{id}/fechar` — pos.FecharSessao
- `POST /api/pos/sales/` — pos.CriarVenda
- `GET /api/pos/sales/{id}` — pos.ObterVenda
- `POST /api/pos/sales/{id}/cancelar` — pos.CancelarVenda
- `GET /api/pos/sales/` — pos.ListarVendas

**Gerir terminais**
- `GET /api/pos/terminais/` — pos.ListarTerminais
- `POST /api/pos/terminais/` — pos.CriarTerminal

**Gerir catálogo POS**
- `GET /api/pos/catalogo/` — pos.ListarCatalogo
- `POST /api/pos/catalogo/` — pos.AdicionarAoCatalogo
- `DELETE /api/pos/catalogo/{id}` — pos.RemoverDoCatalogo

---

## /api/rh
- `GET /api/rh/relatorios` — rh.RelatoriosRH

**unidades**
- `GET /api/rh/unidades/` — rh.ListarUnidades
- `GET /api/rh/unidades/{id}` — rh.ObterUnidade
- `GET /api/rh/unidades/{id}/filhos` — rh.ListarFilhosUnidade
- `GET /api/rh/unidades/{id}/subarvore` — rh.ListarSubarvoreUnidade
- `GET /api/rh/unidades/{id}/caminho` — rh.ObterCaminhoUnidade
- `GET /api/rh/unidades/{id}/funcionarios` — rh.ListarFuncionariosUnidade
- `GET /api/rh/unidades/{id}/funcionarios/todos` — rh.ListarFuncionariosSubarvore
- `POST /api/rh/unidades/` — rh.CriarUnidade
- `PUT /api/rh/unidades/{id}` — rh.ActualizarUnidade
- `DELETE /api/rh/unidades/{id}` — rh.RemoverUnidade
- `POST /api/rh/unidades/{id}/mover` — rh.MoverUnidade

**Configurações RH**
- `GET /api/rh/configuracoes` — rh.ObterConfiguracoesRH
- `GET /api/rh/irps-escaloes` — rh.ListarEscaloesIRPS
- `POST /api/rh/configuracoes` — rh.GuardarConfiguracaoRH
- `POST /api/rh/irps-escaloes` — rh.CriarEscalaoIRPS
- `POST /api/rh/irps-escaloes/seed-mozambique-2024` — rh.SeedEscaloesIRPSMozambique2024
- `PUT /api/rh/irps-escaloes/{id}` — rh.ActualizarEscalaoIRPS
- `DELETE /api/rh/irps-escaloes/{id}` — rh.EliminarEscalaoIRPS

**Funcionários**
- `GET /api/rh/funcionarios/` — rh.ListarFuncionarios
- `GET /api/rh/funcionarios/proximo-numero` — rh.ProximoNumeroFuncionario
- `GET /api/rh/funcionarios/{id}` — rh.ObterFuncionario
- `GET /api/rh/funcionarios/{id}/recibos-vencimento` — rh.ListarRecibosVencimentoFuncionario
- `POST /api/rh/funcionarios/` — rh.CriarFuncionario
- `PUT /api/rh/funcionarios/{id}` — rh.ActualizarFuncionario
- `POST /api/rh/funcionarios/{id}/desligar` — rh.DesligarFuncionario
- `GET /api/rh/funcionarios/{id}/historico-salarial` — rh.ListarHistoricoSalarial
- `GET /api/rh/funcionarios/{id}/componentes-salariais` — rh.ListarComponentesFuncionario
- `POST /api/rh/funcionarios/{id}/historico-salarial` — rh.CriarAlteracaoSalarial
- `POST /api/rh/funcionarios/{id}/componentes-salariais` — rh.AdicionarComponenteFuncionario
- `DELETE /api/rh/funcionarios/{id}/componentes-salariais/{componenteId}` — rh.RemoverComponenteFuncionario
- `GET /api/rh/funcionarios/{id}/adiantamentos` — rh.ListarAdiantamentos
- `POST /api/rh/funcionarios/{id}/adiantamentos` — rh.CriarAdiantamento
- `GET /api/rh/funcionarios/{id}/emprestimos` — rh.ListarEmprestimos
- `POST /api/rh/funcionarios/{id}/emprestimos` — rh.CriarEmprestimo
- `POST /api/rh/funcionarios/adiantamentos/{id}/cancelar` — rh.CancelarAdiantamento
- `POST /api/rh/funcionarios/emprestimos/{id}/cancelar` — rh.CancelarEmprestimo
- `GET /api/rh/funcionarios/{id}/beneficios` — rh.ListarBeneficiosFuncionario
- `POST /api/rh/funcionarios/{id}/beneficios` — rh.AdicionarBeneficioFuncionario
- `DELETE /api/rh/funcionarios/{id}/beneficios/{beneficioId}` — rh.RemoverBeneficioFuncionario
- `GET /api/rh/funcionarios/{id}/presencas` — rh.ListarPresencas
- `GET /api/rh/funcionarios/{id}/saldos-ausencia` — rh.ListarSaldosAusenciaFuncionario
- `POST /api/rh/funcionarios/{id}/presencas` — rh.CriarPresenca
- `DELETE /api/rh/funcionarios/{id}/presencas/{presencaId}` — rh.RemoverPresenca
- `POST /api/rh/funcionarios/{id}/saldos-ausencia` — rh.DefinirSaldoAusencia
- `GET /api/rh/funcionarios/{id}/processos-disciplinares` — rh.ListarProcessosDisciplinaresFuncionario
- `POST /api/rh/funcionarios/{id}/processos-disciplinares` — rh.CriarProcessoDisciplinarFuncionario
- `PUT /api/rh/funcionarios/{id}/processos-disciplinares/{registoId}` — rh.ActualizarProcessoDisciplinarFuncionario
- `DELETE /api/rh/funcionarios/{id}/processos-disciplinares/{registoId}` — rh.RemoverProcessoDisciplinarFuncionario
- `GET /api/rh/funcionarios/{id}/formacoes` — rh.ListarFormacoesFuncionario
- `POST /api/rh/funcionarios/{id}/formacoes` — rh.AdicionarFormacaoFuncionario
- `PUT /api/rh/funcionarios/{id}/formacoes/{registoId}` — rh.ActualizarFormacaoFuncionario
- `DELETE /api/rh/funcionarios/{id}/formacoes/{registoId}` — rh.RemoverFormacaoFuncionario
- `POST /api/rh/funcionarios/{id}/formacoes/{registoId}/upload` — rh.UploadCertificadoFormacao
- `GET /api/rh/funcionarios/{id}/formacoes/{registoId}/download` — rh.DownloadCertificadoFormacao

**Contratos**
- `GET /api/rh/contratos/` — rh.ListarContratos
- `GET /api/rh/contratos/{id}` — rh.ObterContrato
- `GET /api/rh/contratos/{id}/download` — rh.DownloadContratoFicheiro
- `GET /api/rh/contratos/{id}/pdf` — rh.ObterContratoPDF
- `POST /api/rh/contratos/` — rh.CriarContrato
- `PUT /api/rh/contratos/{id}` — rh.ActualizarContrato
- `POST /api/rh/contratos/{id}/renovar` — rh.RenovarContrato
- `POST /api/rh/contratos/{id}/rescindir` — rh.RescindirContrato
- `POST /api/rh/contratos/{id}/upload` — rh.UploadContratoFicheiro
- `POST /api/rh/contratos/{id}/pdf` — rh.GuardarContratoPDF

**Ausências**
- `GET /api/rh/ausencias/` — rh.ListarAusencias
- `POST /api/rh/ausencias/` — rh.CriarAusencia
- `POST /api/rh/ausencias/{id}/aprovar` — rh.AprovarAusencia
- `POST /api/rh/ausencias/{id}/rejeitar` — rh.RejeitarAusencia
- `POST /api/rh/ausencias/{id}/gozar` — rh.MarcarAusenciaGozada
- `POST /api/rh/ausencias/{id}/cancelar` — rh.CancelarAusencia

**Tipos de ausência**
- `GET /api/rh/tipos-ausencia/` — rh.ListarTiposAusencia
- `POST /api/rh/tipos-ausencia/` — rh.CriarTipoAusencia
- `PUT /api/rh/tipos-ausencia/{id}` — rh.ActualizarTipoAusencia
- `DELETE /api/rh/tipos-ausencia/{id}` — rh.RemoverTipoAusencia

**Avaliações de desempenho**
- `GET /api/rh/avaliacoes/` — rh.ListarAvaliacoes
- `POST /api/rh/avaliacoes/` — rh.CriarAvaliacao
- `POST /api/rh/avaliacoes/{id}/submeter` — rh.SubmeterAvaliacao
- `POST /api/rh/avaliacoes/{id}/aprovar` — rh.AprovarAvaliacaoDesempenho

**Critérios de avaliação**
- `GET /api/rh/criterios-avaliacao/` — rh.ListarCriteriosAvaliacao
- `POST /api/rh/criterios-avaliacao/` — rh.CriarCriterioAvaliacao
- `PUT /api/rh/criterios-avaliacao/{id}` — rh.ActualizarCriterioAvaliacao
- `DELETE /api/rh/criterios-avaliacao/{id}` — rh.RemoverCriterioAvaliacao

**Períodos**
- `GET /api/rh/periodos/` — rh.ListarPeriodos
- `POST /api/rh/periodos/` — rh.CriarPeriodo
- `PUT /api/rh/periodos/{id}` — rh.ActualizarPeriodo

**Cargos**
- `GET /api/rh/cargos/` — rh.ListarCargos
- `POST /api/rh/cargos/` — rh.CriarCargo
- `PUT /api/rh/cargos/{id}` — rh.ActualizarCargo
- `DELETE /api/rh/cargos/{id}` — rh.RemoverCargo

**Horários**
- `GET /api/rh/horarios/` — rh.ListarHorarios
- `POST /api/rh/horarios/` — rh.CriarHorario
- `PUT /api/rh/horarios/{id}` — rh.ActualizarHorario
- `DELETE /api/rh/horarios/{id}` — rh.RemoverHorario

**Componentes salariais**
- `GET /api/rh/componentes-salariais/` — rh.ListarComponentesSalariais
- `POST /api/rh/componentes-salariais/` — rh.CriarComponenteSalarial
- `PUT /api/rh/componentes-salariais/{id}` — rh.ActualizarComponenteSalarial
- `DELETE /api/rh/componentes-salariais/{id}` — rh.RemoverComponenteSalarial

**Benefícios**
- `GET /api/rh/beneficios/` — rh.ListarBeneficios
- `POST /api/rh/beneficios/` — rh.CriarBeneficio
- `PUT /api/rh/beneficios/{id}` — rh.ActualizarBeneficio
- `DELETE /api/rh/beneficios/{id}` — rh.RemoverBeneficio

**Formações**
- `GET /api/rh/formacoes/` — rh.ListarFormacoes
- `POST /api/rh/formacoes/` — rh.CriarFormacao
- `PUT /api/rh/formacoes/{id}` — rh.ActualizarFormacao
- `DELETE /api/rh/formacoes/{id}` — rh.RemoverFormacao

**Folhas de pagamento**
- `GET /api/rh/folhas-pagamento/` — rh.ListarFolhasPagamento
- `GET /api/rh/folhas-pagamento/{id}` — rh.ObterFolhaPagamento
- `POST /api/rh/folhas-pagamento/` — rh.CriarFolhaPagamento
- `POST /api/rh/folhas-pagamento/{id}/processar` — rh.ProcessarFolhaPagamento
- `POST /api/rh/folhas-pagamento/{id}/pagar` — rh.PagarFolhaPagamento
- `POST /api/rh/folhas-pagamento/{id}/cancelar` — rh.CancelarFolhaPagamento

**Recibos de vencimento**
- `GET /api/rh/recibos-vencimento/{id}` — rh.ObterReciboVencimento
- `GET /api/rh/recibos-vencimento/{id}/pdf` — rh.ObterReciboVencimentoPDF
- `POST /api/rh/recibos-vencimento/{id}/pdf` — rh.GuardarReciboVencimentoPDF

**Contactos de emergência**
- `POST /api/rh/contactos-emergencia/` — rh.CriarContactoEmergencia
- `DELETE /api/rh/contactos-emergencia/{id}` — rh.RemoverContactoEmergencia

**Documentos**
- `GET /api/rh/documentos/{id}/download` — rh.DownloadDocumentoFuncionario
- `POST /api/rh/documentos/` — rh.CriarDocumento
- `POST /api/rh/documentos/{id}/upload` — rh.UploadDocumentoFuncionario
- `DELETE /api/rh/documentos/{id}` — rh.RemoverDocumento

---

## /api/assinaturas

**planos**
- `GET /api/assinaturas/planos/` — ass.ListarPlanos
- `POST /api/assinaturas/planos/` — ass.CriarPlano
- `PUT /api/assinaturas/planos/{id}` — ass.ActualizarPlano

**subscriptions**
- `GET /api/assinaturas/subscriptions/` — ass.ListarAssinaturas
- `GET /api/assinaturas/subscriptions/{id}/facturas` — ass.ListarFacturasAssinatura
- `GET /api/assinaturas/subscriptions/{id}/utilizacao` — ass.ListarUtilizacaoAssinatura
- `POST /api/assinaturas/subscriptions/` — ass.CriarAssinatura
- `POST /api/assinaturas/subscriptions/{id}/cancelar` — ass.CancelarAssinatura
- `POST /api/assinaturas/subscriptions/{id}/renovar` — ass.RenovarAssinatura

---

## /api/assinatura-digital

**documentos**
- `GET /api/assinatura-digital/documentos/` — assD.ListarDocumentos
- `GET /api/assinatura-digital/documentos/{id}` — assD.ObterDocumento
- `GET /api/assinatura-digital/documentos/{id}/download` — assD.BaixarDocumento
- `POST /api/assinatura-digital/documentos/` — assD.CriarDocumento
- `POST /api/assinatura-digital/documentos/{id}/enviar` — assD.EnviarParaAssinatura
- `POST /api/assinatura-digital/documentos/{id}/cancelar` — assD.CancelarDocumento
- `POST /api/assinatura-digital/documentos/{id}/signatarios` — assD.AdicionarSignatario
- `DELETE /api/assinatura-digital/documentos/{id}/signatarios/{sigId}` — assD.RemoverSignatario
- `POST /api/assinatura-digital/documentos/{id}/assinar` — assD.AssinarDocumento

---

## /api/financeiro
- `GET /api/financeiro/cash-flow` — fin.ListarCashFlow

**categorias**
- `GET /api/financeiro/categorias/` — fin.ListarCategorias
- `POST /api/financeiro/categorias/` — fin.CriarCategoria

**metodos-pagamento**
- `GET /api/financeiro/metodos-pagamento/` — fin.ListarMetodosPagamento
- `POST /api/financeiro/metodos-pagamento/` — fin.CriarMetodoPagamento

**contas-receber**
- `GET /api/financeiro/contas-receber/` — fin.ListarContasAReceber
- `POST /api/financeiro/contas-receber/` — fin.CriarContaAReceber
- `POST /api/financeiro/contas-receber/{id}/pagamento` — fin.RegistarPagamentoAReceber

**contas-pagar**
- `GET /api/financeiro/contas-pagar/` — fin.ListarContasAPagar
- `POST /api/financeiro/contas-pagar/` — fin.CriarContaAPagar
- `POST /api/financeiro/contas-pagar/{id}/pagamento` — fin.RegistarPagamentoAPagar

---

## /api/multi-moeda
- `POST /api/multi-moeda/converter` — mm.ConverterValor

**moedas**
- `GET /api/multi-moeda/moedas/` — mm.ListarMoedas
- `POST /api/multi-moeda/moedas/` — mm.CriarMoeda

**taxas-cambio**
- `GET /api/multi-moeda/taxas-cambio/` — mm.ListarTaxasCambio
- `POST /api/multi-moeda/taxas-cambio/` — mm.CriarTaxaCambio

**tenant-moedas**
- `GET /api/multi-moeda/tenant-moedas/` — mm.ListarMoedasTenant
- `POST /api/multi-moeda/tenant-moedas/` — mm.AdicionarMoedaTenant
- `DELETE /api/multi-moeda/tenant-moedas/{id}` — mm.RemoverMoedaTenant

---

## /api/notificacoes

**canais**
- `GET /api/notificacoes/canais/` — notif.ListarCanais
- `POST /api/notificacoes/canais/` — notif.CriarCanal

**templates**
- `GET /api/notificacoes/templates/` — notif.ListarTemplates
- `POST /api/notificacoes/templates/` — notif.CriarTemplate
- `PUT /api/notificacoes/templates/{id}` — notif.ActualizarTemplate

**mensagens**
- `GET /api/notificacoes/mensagens/` — notif.ListarMensagens
- `POST /api/notificacoes/mensagens/` — notif.EnviarNotificacao

---

## /api/seguranca
- `GET /api/seguranca/mfa-enrollments` — seg.ListarMFAEnrollments

**politicas**
- `GET /api/seguranca/politicas/` — seg.ListarPoliticas
- `POST /api/seguranca/politicas/` — seg.CriarPolitica
- `PUT /api/seguranca/politicas/{id}` — seg.ActualizarPolitica

**ip-allowlist**
- `GET /api/seguranca/ip-allowlist/` — seg.ListarIPAllowlist
- `POST /api/seguranca/ip-allowlist/` — seg.AdicionarIP
- `DELETE /api/seguranca/ip-allowlist/{id}` — seg.RemoverIP

---

## /api/self-service
(qualquer funcionário autenticado)

**Home / Dashboard**
- `GET /api/self-service/home` — ss.Home
- `POST /api/self-service/notificacoes/lida` — ss.MarcarNotificacaoLida
- `POST /api/self-service/comunicados/lido` — ss.ComunicadoMarcarLido

**Chat**
- `GET /api/self-service/chat/conversas` — ss.ListarConversas
- `GET /api/self-service/chat/conversas/{id}/mensagens` — ss.ListarMensagens
- `POST /api/self-service/chat/conversas` — ss.CriarConversa
- `POST /api/self-service/chat/conversas/{id}/mensagens` — ss.EnviarMensagem

**Assiduidade**
- `GET /api/self-service/assiduidade/` — ss.MinhaAssiduidade
- `GET /api/self-service/assiduidade/resumo` — ss.ResumoAssiduidade
- `GET /api/self-service/assiduidade/justificacoes` — ss.ListarJustificacoes
- `POST /api/self-service/assiduidade/justificacoes` — ss.CriarJustificacao

**Recibos de vencimento (self-service)**
- `GET /api/self-service/recibos/` — ss.MeusRecibos
- `GET /api/self-service/recibos/{id}` — ss.MeuReciboDetalhe
- `GET /api/self-service/recibos/{id}/pdf` — ss.MeuReciboPDF
- `POST /api/self-service/recibos/{id}/pdf` — ss.GuardarMeuReciboPDF

**Perfil**
- `GET /api/self-service/perfil/` — ss.MeuPerfil
- `GET /api/self-service/perfil/documentos` — ss.MeusDocumentos
- `PUT /api/self-service/perfil/` — ss.ActualizarPerfil
- `POST /api/self-service/perfil/senha` — ss.AlterarSenha

---

## /api/pedido-ferias
(mantido por compatibilidade)
- `GET /api/pedido-ferias/` — rh.ListarMeusPedidosFerias
- `GET /api/pedido-ferias/tipos` — rh.ListarTiposAusencia
- `POST /api/pedido-ferias/` — rh.CriarMeuPedidoFerias
- `POST /api/pedido-ferias/{id}/cancelar` — rh.CancelarMeuPedidoFerias

---

## /api/superadmin
(acesso global à plataforma)
- `GET /api/superadmin/dashboard` — super.Dashboard
- `GET /api/superadmin/utilizadores` — super.ListarUtilizadoresGlobais

**tenants**
- `GET /api/superadmin/tenants/` — super.ListarTenants
- `POST /api/superadmin/tenants/` — super.CriarTenant
- `GET /api/superadmin/tenants/{id}` — super.ObterTenant
- `PUT /api/superadmin/tenants/{id}` — super.ActualizarTenant
- `DELETE /api/superadmin/tenants/{id}` — super.EliminarTenant
- `POST /api/superadmin/tenants/{id}/suspender` — super.SuspenderTenant
- `POST /api/superadmin/tenants/{id}/reativar` — super.ReativarTenant
- `POST /api/superadmin/tenants/{id}/inativar` — super.InativarTenant
- `POST /api/superadmin/tenants/{id}/cargos-padrao` — super.ProvisionarCargosPadrao
- `GET /api/superadmin/tenants/{tenantId}/funcionarios/proximo-numero` — super.ProximoNumeroFuncionarioTenant
- `POST /api/superadmin/tenants/{tenantId}/funcionarios` — super.CriarFuncionarioTenant

**plans**
- `GET /api/superadmin/plans/` — super.ListarPlanos
- `POST /api/superadmin/plans/` — super.CriarPlano
- `GET /api/superadmin/plans/{id}` — super.ObterPlano
- `PUT /api/superadmin/plans/{id}` — super.ActualizarPlano
- `DELETE /api/superadmin/plans/{id}` — super.EliminarPlano
- `GET /api/superadmin/plans/{id}/modules` — super.ListarModulosPlano
- `PUT /api/superadmin/plans/{id}/modules` — super.DefinirModulosPlano

**modules**
- `GET /api/superadmin/modules/disponiveis` — super.ListarModulosDisponiveis
- `GET /api/superadmin/modules/tenants/{tenantId}` — super.ListarModulosTenant
- `POST /api/superadmin/modules/tenants/{tenantId}/{modulo}` — super.ActualizarModuloTenant
- `POST /api/superadmin/modules/tenants/{tenantId}/reset` — super.ResetarModulosTenant
- `GET /api/superadmin/modules/dependencies` — super.ListarDependencias
- `POST /api/superadmin/modules/dependencies` — super.AdicionarDependencia
- `DELETE /api/superadmin/modules/dependencies/{modulo}/{requires}` — super.RemoverDependencia

**features**
- `GET /api/superadmin/features/catalog` — super.ListarFeatureCatalog
- `GET /api/superadmin/features/tenants/{tenantId}` — super.ListarFeaturesTenant
- `POST /api/superadmin/features/tenants/{tenantId}/{key}` — super.AlterarFeatureTenant
- `DELETE /api/superadmin/features/tenants/{tenantId}/{key}` — super.ReporFeatureTenant

**settings**
- `GET /api/superadmin/settings/` — super.ListarConfiguracoesGlobais
- `PUT /api/superadmin/settings/` — super.ActualizarConfiguracaoGlobal

---

## /api/tarefas

**quadros**
- `GET /api/tarefas/quadros/` — tarefas.ListarQuadros
- `POST /api/tarefas/quadros/` — tarefas.CriarQuadro
- `GET /api/tarefas/quadros/{id}/` — tarefas.ObterQuadro
- `PUT /api/tarefas/quadros/{id}/` — tarefas.ActualizarQuadro
- `DELETE /api/tarefas/quadros/{id}/` — tarefas.EliminarQuadro
- `POST /api/tarefas/quadros/{id}/arquivar` — tarefas.ArquivarQuadro
- `POST /api/tarefas/quadros/{id}/listas` — tarefas.CriarLista

**listas**
- `PUT /api/tarefas/listas/{id}/` — tarefas.ActualizarLista
- `DELETE /api/tarefas/listas/{id}/` — tarefas.EliminarLista
- `POST /api/tarefas/listas/{id}/reordenar` — tarefas.ReordenarListas
- `POST /api/tarefas/listas/{id}/cartoes` — tarefas.CriarCartao

**cartoes**
- `GET /api/tarefas/cartoes/{id}/` — tarefas.ObterCartao
- `PUT /api/tarefas/cartoes/{id}/` — tarefas.ActualizarCartao
- `PUT /api/tarefas/cartoes/{id}/mover` — tarefas.MoverCartao
- `POST /api/tarefas/cartoes/{id}/concluir` — tarefas.ConcluirCartao
- `DELETE /api/tarefas/cartoes/{id}/` — tarefas.EliminarCartao

---

## /api/hardware

**Endpoints públicos (dispositivos autenticados por API Key)**
- `POST /api/hardware/events` — hardware.ReceberEvento
- `POST /api/hardware/events/generic` — hardware.ReceberEventoGenerico
- `POST /api/hardware/events/zkteco` — hardware.ReceberEventoZKTeco
- `POST /api/hardware/events/batch` — hardware.ReceberEventosEmLote
- `GET /api/hardware/ping` — hardware.Ping
- `GET /api/hardware/assiduidade/config` — rh.ObterConfigAssiduidadeDevice
- `GET /api/hardware/assiduidade/funcionarios` — rh.ListarFuncionariosIntegracao
- `GET /api/hardware/assiduidade/funcionarios/{id}` — rh.ObterFuncionarioIntegracao

**Gestão de dispositivos e eventos (admin do tenant)**
- `GET /api/hardware/events` — hardware.ListarEventos
- `GET /api/hardware/drivers` — hardware.ListarDrivers
- `GET /api/hardware/devices` — hardware.ListarDispositivos
- `POST /api/hardware/devices` — hardware.CriarDispositivo
- `GET /api/hardware/devices/{id}/` — hardware.ObterDispositivo
- `PUT /api/hardware/devices/{id}/` — hardware.ActualizarDispositivo
- `POST /api/hardware/devices/{id}/toggle` — hardware.AlternarEstadoDispositivo
- `POST /api/hardware/devices/{id}/rotate-key` — hardware.GerarNovaChave
- `GET /api/hardware/devices/{id}/users` — hardware.ListarDeviceUsers
- `POST /api/hardware/devices/{id}/users` — hardware.CriarDeviceUser
- `DELETE /api/hardware/devices/{id}/users/{mappingId}` — hardware.RemoverDeviceUser

---

## Extras (grupos fora da lista dos 31 prefixos pedidos)

Estes existem no ficheiro mas não constavam na lista dos 31 prefixos indicados — incluídos por exaustividade.

### Rotas soltas iniciais
- `GET /health` — handler inline
- `GET /ws/chat` — handler inline (ws.ServeWS)
- `Handle /socket.io/*` — recrutRealtime.Handler()

### Logística (r.Group simples, sem r.Route dedicado — entre /api/tesouraria e /api/escolar)
**Visualização**
- `GET /api/delivery-drivers` — logistica.ListarMotoristas
- `GET /api/delivery-vehicles` — logistica.ListarViaturas
- `GET /api/delivery-routes` — logistica.ListarRotas
- `GET /api/shipments` — logistica.ListarEnvios
- `GET /api/delivery-tracking` — logistica.ListarTracking
- `GET /api/delivery-logs` — logistica.ListarLogsEntrega

**Gestão de entregas e expedições**
- `POST /api/delivery-drivers` — logistica.CriarMotorista
- `POST /api/delivery-vehicles` — logistica.CriarViatura
- `POST /api/delivery-routes` — logistica.CriarRota
- `POST /api/shipments` — logistica.CriarEnvio
- `POST /api/delivery-tracking` — logistica.CriarTracking

### /api/portal/aluno (auth via /api/auth/login)
- `POST /api/portal/aluno/definir-senha` — escolar.PortalDefinirSenha
- `POST /api/portal/aluno/logout` — escolar.PortalLogout
- `GET /api/portal/aluno/me` — escolar.PortalMe
- `POST /api/portal/aluno/alterar-senha` — escolar.PortalAlterarSenha
- `GET /api/portal/aluno/me/boletim` — escolar.PortalBoletim
- `GET /api/portal/aluno/me/notas` — escolar.PortalDetalhesNotas
- `GET /api/portal/aluno/me/cobrancas` — escolar.PortalCobrancas
- `GET /api/portal/aluno/me/cobrancas/{id}/recibo` — escolar.PortalReciboCobranca
- `GET /api/portal/aluno/me/horario` — escolar.PortalHorario
- `GET /api/portal/aluno/me/mensagens` — escolar.PortalMensagens
- `GET /api/portal/aluno/me/eventos` — escolar.PortalEventos
- `GET /api/portal/aluno/me/presencas` — escolar.PortalPresencas
- `GET /api/portal/aluno/me/ocorrencias` — escolar.PortalOcorrencias
- `GET /api/portal/aluno/me/biblioteca` — escolar.PortalBiblioteca
- `POST /api/portal/aluno/me/cobrancas/{id}/pagar` — escolar.PortalIniciarPagamento
- `GET /api/portal/aluno/me/cobrancas/{id}/pagamento/{gtid}` — escolar.PortalStatusPagamento
- `GET /api/portal/aluno/me/dashboard` — escolar.PortalDashboardAluno
- `GET /api/portal/aluno/me/turma` — escolar.PortalTurmaAluno
- `GET /api/portal/aluno/me/noticias` — escolar.PortalNoticias
- `PUT /api/portal/aluno/me` — escolar.PortalActualizarPerfil
- `POST /api/portal/aluno/me/presencas/{id}/justificar` — escolar.PortalJustificarFalta

### /api/portal/professor
- `POST /api/portal/professor/logout` — escolar.ProfessorPortalLogout
- `POST /api/portal/professor/alterar-senha` — escolar.ProfessorPortalAlterarSenha
- `GET /api/portal/professor/me` — escolar.ProfessorPortalMe
- `GET /api/portal/professor/me/dashboard` — escolar.ProfessorPortalDashboard
- `GET /api/portal/professor/me/turmas` — escolar.ProfessorPortalTurmas
- `GET /api/portal/professor/me/turmas/{id}` — escolar.ProfessorPortalTurma
- `GET /api/portal/professor/me/turmas/{id}/alunos` — escolar.ProfessorPortalTurmaAlunos
- `GET /api/portal/professor/me/horario` — escolar.ProfessorPortalHorario
- `GET /api/portal/professor/me/presencas` — escolar.ProfessorPortalGetPresencas
- `POST /api/portal/professor/me/presencas` — escolar.ProfessorPortalSalvarPresencas
- `GET /api/portal/professor/me/notas` — escolar.ProfessorPortalGetNotas
- `POST /api/portal/professor/me/notas` — escolar.ProfessorPortalSalvarNotas
- `GET /api/portal/professor/me/comunicacao` — escolar.ProfessorPortalComunicacao

### /api/portal/encarregado
- `POST /api/portal/encarregado/definir-senha` — escolar.EncarregadoDefinirSenha
- `POST /api/portal/encarregado/logout` — escolar.EncarregadoLogout
- `GET /api/portal/encarregado/me` — escolar.EncarregadoMe
- `POST /api/portal/encarregado/alterar-senha` — escolar.EncarregadoAlterarSenha
- `GET /api/portal/encarregado/me/educandos/{id}/boletim` — escolar.EncarregadoBoletim
- `GET /api/portal/encarregado/me/educandos/{id}/cobrancas` — escolar.EncarregadoCobrancas
- `GET /api/portal/encarregado/me/educandos/{id}/presencas` — escolar.EncarregadoPresencas
- `GET /api/portal/encarregado/me/educandos/{id}/ocorrencias` — escolar.EncarregadoOcorrencias

### /api/public/recrutamento
- `GET /api/public/recrutamento/vagas` — recrut.ListarVagasPublicas
- `GET /api/public/recrutamento/vagas/abertas` — recrut.VagasAbertasCount
- `GET /api/public/recrutamento/vagas/{id}` — recrut.ObterVagaPublica
- `GET /api/public/recrutamento/campos-custom` — recrut.ListarCamposCustomPublicos
- `POST /api/public/recrutamento/candidaturas` — recrut.SubmeterCandidatura (rate-limited)
- `GET /api/public/recrutamento/candidaturas/{codigo}` — recrut.ConsultarCandidaturaPorCodigo
- `POST /api/public/recrutamento/candidatos/registar` — recrut.RegistarCandidato (rate-limited)
- `POST /api/public/recrutamento/candidatos/logout` — recrut.LogoutCandidato
- `POST /api/public/recrutamento/contacto` — recrut.SubmeterContacto (rate-limited)

**Rotas protegidas (sessão de candidato)**
- `GET /api/public/recrutamento/candidatos/perfil` — recrut.MeuPerfil
- `PUT /api/public/recrutamento/candidatos/perfil` — recrut.ActualizarMeuPerfil
- `GET /api/public/recrutamento/candidatos/candidaturas` — recrut.MinhasCandidaturas
- `GET /api/public/recrutamento/candidatos/conversas` — recrut.MinhasConversas
- `GET /api/public/recrutamento/candidatos/candidaturas/{id}/mensagens` — recrut.MensagensCandidatura
- `POST /api/public/recrutamento/candidatos/candidaturas/{id}/mensagens` — recrut.EnviarMensagemCandidatura
- `POST /api/public/recrutamento/candidatos/push-token` — recrut.RegistarPushToken

### Aliases curtos (fora de /api, para o portal público de recrutamento)
- `GET /vagas` — recrut.ListarVagasPublicas
- `GET /vagas/abertas` — recrut.VagasAbertasCount
- `GET /vagas/{id}` — recrut.ObterVagaPublica
- `POST /candidaturas` — recrut.SubmeterCandidatura (rate-limited)
- `GET /candidaturas/{codigo}` — recrut.ConsultarCandidaturaPorCodigo