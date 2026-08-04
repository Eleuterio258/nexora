# Endpoints de Assiduidade — Nexora ERP

> Backend: `backend/internal/router/router.go`  
> Base URL: `/api`  
> Autenticação: JWT (`/api/rh/*`, `/api/self-service/*`) ou API Key de device (`/api/hardware/*`)

---

## `/api/rh` — Recursos Humanos

Requer feature `rh.assiduidade`.

### Relatórios / presenças

| Método | Endpoint | Handler | Permissão |
|--------|----------|---------|-----------|
| `GET` | `/api/rh/relatorios` | `rh.RelatoriosRH` | `recursos-humanos:ver_funcionarios` |
| `GET` | `/api/rh/presencas` | `rh.ListarPresencasPorTipo` | `recursos-humanos:ver_funcionarios` |

### Funcionários — presenças e eventos

| Método | Endpoint | Handler | Permissão |
|--------|----------|---------|-----------|
| `GET` | `/api/rh/funcionarios/{id}/presencas` | `rh.ListarPresencas` | `recursos-humanos:ver_funcionarios` |
| `POST` | `/api/rh/funcionarios/{id}/presencas` | `rh.CriarPresenca` | `recursos-humanos:gerir_funcionarios` |
| `DELETE` | `/api/rh/funcionarios/{id}/presencas/{presencaId}` | `rh.RemoverPresenca` | `recursos-humanos:gerir_funcionarios` |
| `GET` | `/api/rh/funcionarios/{id}/saldos-ausencia` | `rh.ListarSaldosAusenciaFuncionario` | `recursos-humanos:ver_funcionarios` |
| `POST` | `/api/rh/funcionarios/{id}/saldos-ausencia` | `rh.DefinirSaldoAusencia` | `recursos-humanos:gerir_funcionarios` |
| `GET` | `/api/rh/funcionarios/{id}/eventos` | `rh.ListarEventosFuncionario` | `recursos-humanos:ver_funcionarios` |
| `POST` | `/api/rh/funcionarios/{id}/recalcular` | `rh.RecalcularResultadoFuncionario` | `recursos-humanos:gerir_funcionarios` |

### Biometria / consentimento

| Método | Endpoint | Handler | Permissão |
|--------|----------|---------|-----------|
| `POST` | `/api/rh/funcionarios/biometria/facial/enroll` | `rh.EnrollFacial` | `recursos-humanos:gerir_funcionarios` |
| `GET` | `/api/rh/funcionarios/consentimento` | `rh.ObterConsentimentoFuncionario` | `recursos-humanos:ver_funcionarios` |
| `POST` | `/api/rh/funcionarios/consentimento` | `rh.CriarConsentimentoFuncionario` | `recursos-humanos:gerir_funcionarios` |

### Ausências

| Método | Endpoint | Handler | Permissão |
|--------|----------|---------|-----------|
| `GET` | `/api/rh/ausencias` | `rh.ListarAusencias` | `recursos-humanos:ver_funcionarios` |
| `POST` | `/api/rh/ausencias` | `rh.CriarAusencia` | `recursos-humanos:aprovar_ausencias` |
| `POST` | `/api/rh/ausencias/{id}/aprovar` | `rh.AprovarAusencia` | `recursos-humanos:aprovar_ausencias` |
| `POST` | `/api/rh/ausencias/{id}/rejeitar` | `rh.RejeitarAusencia` | `recursos-humanos:aprovar_ausencias` |
| `POST` | `/api/rh/ausencias/{id}/gozar` | `rh.MarcarAusenciaGozada` | `recursos-humanos:aprovar_ausencias` |
| `POST` | `/api/rh/ausencias/{id}/cancelar` | `rh.CancelarAusencia` | `recursos-humanos:aprovar_ausencias` |

### Pedidos de correção de ponto (modelo antigo — só leitura/aprovação)

| Método | Endpoint | Handler | Permissão |
|--------|----------|---------|-----------|
| `GET` | `/api/rh/correcoes-ponto` | `rh.ListarPedidosCorrecaoPendentes` | `assiduidade:aprovar_correcao` |
| `POST` | `/api/rh/correcoes-ponto/{id}/aprovar` | `rh.AprovarPedidoCorrecao` | `assiduidade:aprovar_correcao` |
| `POST` | `/api/rh/correcoes-ponto/{id}/rejeitar` | `rh.RejeitarPedidoCorrecao` | `assiduidade:aprovar_correcao` |

### Catálogos configuráveis de assiduidade

| Método | Endpoint | Handler | Permissão |
|--------|----------|---------|-----------|
| `GET` | `/api/rh/tipos-evento` | `rh.ListarTiposEvento` | `recursos-humanos:ver_funcionarios` |
| `POST` | `/api/rh/tipos-evento` | `rh.CriarTipoEvento` | `assiduidade:gerir_configuracao` |
| `PUT` | `/api/rh/tipos-evento/{id}` | `rh.ActualizarTipoEvento` | `assiduidade:gerir_configuracao` |
| `DELETE` | `/api/rh/tipos-evento/{id}` | `rh.RemoverTipoEvento` | `assiduidade:gerir_configuracao` |
| `GET` | `/api/rh/metodos-marcacao` | `rh.ListarMetodosMarcacao` | `recursos-humanos:ver_funcionarios` |
| `POST` | `/api/rh/metodos-marcacao` | `rh.CriarMetodoMarcacao` | `assiduidade:gerir_configuracao` |
| `PUT` | `/api/rh/metodos-marcacao/{id}` | `rh.ActualizarMetodoMarcacao` | `assiduidade:gerir_configuracao` |
| `DELETE` | `/api/rh/metodos-marcacao/{id}` | `rh.RemoverMetodoMarcacao` | `assiduidade:gerir_configuracao` |
| `GET` | `/api/rh/tipos-regra` | `rh.ListarTiposRegra` | `recursos-humanos:ver_funcionarios` |
| `GET` | `/api/rh/regras` | `rh.ListarRegras` | `assiduidade:ver_configuracao` |
| `POST` | `/api/rh/regras` | `rh.CriarRegra` | `assiduidade:gerir_configuracao` |
| `PUT` | `/api/rh/regras/{id}` | `rh.ActualizarRegra` | `assiduidade:gerir_configuracao` |
| `DELETE` | `/api/rh/regras/{id}` | `rh.RemoverRegra` | `assiduidade:gerir_configuracao` |

### Eventos manuais / marcação gestor / QR

| Método | Endpoint | Handler | Permissão |
|--------|----------|---------|-----------|
| `POST` | `/api/rh/eventos` | `rh.CriarEvento` | `recursos-humanos:gerir_funcionarios` |
| `POST` | `/api/rh/assiduidade/ponto` | `rh.MarcarPontoGestor` | `recursos-humanos:gerir_funcionarios` |
| `POST` | `/api/rh/assiduidade/qr/gerar` | `rh.GerarQRDevice` | `recursos-humanos:ver_funcionarios` |

### Correções de eventos (novo modelo)

| Método | Endpoint | Handler | Permissão |
|--------|----------|---------|-----------|
| `POST` | `/api/rh/correcoes` | `rh.CriarCorrecaoEvento` | `recursos-humanos:gerir_funcionarios` |
| `GET` | `/api/rh/correcoes` | `rh.ListarCorrecoesEventoPendentes` | `assiduidade:aprovar_correcao` |
| `POST` | `/api/rh/correcoes/{id}/aprovar` | `rh.AprovarCorrecaoEvento` | `assiduidade:aprovar_correcao` |
| `POST` | `/api/rh/correcoes/{id}/rejeitar` | `rh.RejeitarCorrecaoEvento` | `assiduidade:aprovar_correcao` |

### Justificações de falta/atraso

| Método | Endpoint | Handler | Permissão |
|--------|----------|---------|-----------|
| `GET` | `/api/rh/justificacoes` | `rh.ListarJustificacoesPendentes` | `assiduidade:aprovar_correcao` |
| `POST` | `/api/rh/justificacoes/{id}/aprovar` | `rh.AprovarJustificacao` | `assiduidade:aprovar_correcao` |
| `POST` | `/api/rh/justificacoes/{id}/rejeitar` | `rh.RejeitarJustificacao` | `assiduidade:aprovar_correcao` |

### Tipos de ausência

| Método | Endpoint | Handler | Permissão |
|--------|----------|---------|-----------|
| `GET` | `/api/rh/tipos-ausencia` | `rh.ListarTiposAusencia` | `recursos-humanos:ver_funcionarios` |
| `POST` | `/api/rh/tipos-ausencia` | `rh.CriarTipoAusencia` | `recursos-humanos:gerir_funcionarios` |
| `PUT` | `/api/rh/tipos-ausencia/{id}` | `rh.ActualizarTipoAusencia` | `recursos-humanos:gerir_funcionarios` |
| `DELETE` | `/api/rh/tipos-ausencia/{id}` | `rh.RemoverTipoAusencia` | `recursos-humanos:gerir_funcionarios` |

---

## `/api/self-service` — Portal do colaborador

| Método | Endpoint | Handler | Permissão |
|--------|----------|---------|-----------|
| `GET` | `/api/self-service/assiduidade` | `ss.MinhaAssiduidade` | `assiduidade:ver_assiduidade` |
| `GET` | `/api/self-service/assiduidade/resumo` | `ss.ResumoAssiduidade` | `assiduidade:ver_assiduidade` |
| `GET` | `/api/self-service/assiduidade/metodos` | `ss.ObterMetodosAssiduidade` | `assiduidade:ver_assiduidade` |
| `GET` | `/api/self-service/assiduidade/justificacoes` | `ss.ListarJustificacoes` | `assiduidade:ver_assiduidade` |
| `GET` | `/api/self-service/assiduidade/qr/me` | `rh.GerarQRMe` | `assiduidade:ver_assiduidade` |
| `POST` | `/api/self-service/assiduidade/biometria/facial/verificar` | `ss.VerificarFacial` | `assiduidade:ver_assiduidade` |
| `POST` | `/api/self-service/assiduidade/ponto` | `ss.MarcarPonto` | `assiduidade:marcar_ponto` |
| `POST` | `/api/self-service/assiduidade/justificacoes` | `ss.CriarJustificacao` | `assiduidade:justificar` |
| `POST` | `/api/self-service/assiduidade/correcoes` | `ss.CriarPedidoCorrecao` | `assiduidade:corrigir_ponto` |
| `GET` | `/api/self-service/assiduidade/correcoes` | `ss.ListarPedidosCorrecao` | `assiduidade:corrigir_ponto` |
| `POST` | `/api/self-service/assiduidade/correcoes/{id}/cancelar` | `ss.CancelarPedidoCorrecao` | `assiduidade:corrigir_ponto` |

---

## `/api/hardware` — Dispositivos/terminais

Autenticação por API Key de device.

### Eventos genéricos

| Método | Endpoint | Handler |
|--------|----------|---------|
| `POST` | `/api/hardware/events` | `hardware.ReceberEvento` |
| `POST` | `/api/hardware/events/generic` | `hardware.ReceberEventoGenerico` |
| `POST` | `/api/hardware/events/zkteco` | `hardware.ReceberEventoZKTeco` |
| `POST` | `/api/hardware/events/batch` | `hardware.ReceberEventosEmLote` |
| `GET` | `/api/hardware/ping` | `hardware.Ping` |

### Integração de assiduidade

| Método | Endpoint | Handler |
|--------|----------|---------|
| `GET` | `/api/hardware/assiduidade/config` | `rh.ObterConfigAssiduidadeDevice` |
| `GET` | `/api/hardware/assiduidade/funcionarios` | `rh.ListarFuncionariosIntegracao` |
| `GET` | `/api/hardware/assiduidade/funcionarios/{id}` | `rh.ObterFuncionarioIntegracao` |
| `GET` | `/api/hardware/assiduidade/geofence/validar` | `rh.ValidarGeofenceDevice` |
| `POST` | `/api/hardware/assiduidade/consentimentos` | `rh.CriarConsentimentoDevice` |
| `GET` | `/api/hardware/assiduidade/consentimentos` | `rh.ListarConsentimentosDevice` |
| `GET` | `/api/hardware/assiduidade/consentimentos/activo` | `rh.ObterConsentimentoActivoDevice` |
| `POST` | `/api/hardware/assiduidade/consentimentos/revogar` | `rh.RevogarConsentimentoDevice` |
| `POST` | `/api/hardware/assiduidade/qr/validar` | `rh.ValidarQRDevice` |
| `POST` | `/api/hardware/assiduidade/qr/registar` | `rh.RegistarQRDevice` |
| `POST` | `/api/hardware/assiduidade/qr/gerar-terminal` | `rh.GerarQRTerminal` |
| `GET` | `/api/hardware/assiduidade/nfc/validar` | `rh.ValidarNFCDevice` |

### Auditoria

| Método | Endpoint | Handler |
|--------|----------|---------|
| `GET` | `/api/hardware/audit-logs` | `audit.ListarAuditLogs` |
