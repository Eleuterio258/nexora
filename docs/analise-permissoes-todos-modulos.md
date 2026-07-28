# Análise de Permissões — Todos os Módulos do Backend Go

> Data: 2026-07-27  
> Âmbito: `backend/internal/modules/*` + router + middleware + migrations de cargos padrão  
> Status: **nenhuma alteração de código foi efetuada** (análise apenas)

---

## 1. Resumo Executivo

Foram analisados **32 módulos** do backend Go. A conclusão principal é que o sistema tem **dois problemas sistémicos**:

1. **Desalinhamento massivo entre as permissões que o router exige e as permissões que as migrations de cargos padrão criam.**
   - O router exige ações **finas** (ex.: `ver_funcionarios`, `gerir_movimentos`, `emitir_faturas`).
   - As migrations de cargos padrão (`20260727000002_cargos_padrao_restore.up.sql`) inserem ações **genéricas** (`ver`, `criar`, `editar`, `apagar`, `relatorios`, etc.).
   - Como `UserAccess.Can()` exige correspondência exata, **dezenas de módulos ficam inacessíveis** a utilizadores normais (incluindo Administradores) em tenants novos.

2. **Falhas de isolamento por tenant (cross-tenant) em vários handlers sensíveis**, mesmo quando as rotas têm autenticação/RBAC.

---

## 2. Problema Sistémico #1 — Permissões do Router vs Cargos Padrão

### Módulos com acesso totalmente bloqueado em novos tenants

| Módulo | Permissões que o router exige | Permissões que os cargos padrão criam |
|---|---|---|
| `aprovacoes` (requests) | `compras:aprovar_pedidos` | `compras:aprovar` |
| `aprovacoes` (flows) | `compras:aprovar_pedidos` + feature | `compras:aprovar` |
| `assinatura-digital` | `ver_documentos`, `gerir_documentos`, `assinar_documentos` | nenhuma |
| `assinaturas` | `ver_assinaturas`, `gerir_assinaturas` | `ver`, `criar`, `editar`, `apagar`... |
| `auditoria` | `ver_logs`, `gerir_logs` | `ver`, `relatorios`, `exportar` |
| `centros-custo` | `ver_centros`, `gerir_centros`, `eliminar_centros` | `ver`, `criar`, `editar`, `apagar` |
| `compras` | `ver_compras`, `criar_pedidos`, `aprovar_pedidos` | `ver`, `criar`, `editar`, `apagar` |
| `contabilidade` | `ver_contabilidade`, `gerir_plano_contas`, `gerir_lancamentos`, `gerir_periodos`, `gerir_ativos_fixos`, `gerir_orcamentos`, `fechar_periodo`, `ver_relatorios` | `ver`, `criar`, `editar`, `apagar`, `relatorios` |
| `crm` | `ver_leads`, `gerir_leads`, `mover_leads`, `converter_leads`, `eliminar_leads`, `ver_oportunidades`, `gerir_oportunidades`, `gerir_atividades` | *parcialmente correto* |
| `empresas` | `ver_empresa`, `editar_empresa`, `gerir_filiais`, `gerir_licencas` | `ver`, `editar` etc. (em backups) |
| `financeiro` | `ver_financeiro`, `gerir_categorias`, `gerir_contas_receber`, `gerir_contas_pagar` | `ver`, `criar`, `editar` |
| `gestao-clientes` | `ver_clientes`, `gerir_clientes`, `eliminar_clientes`, `gerir_grupos`, `gerir_credito` | `ver`, `criar`, `editar`, `apagar` |
| `gestao-produtos` | `ver_stock`, `gerir_produtos`, `gerir_categorias`, `eliminar_produtos` | `ver`, `criar`, `editar`, `apagar` |
| `gestao-stock` | `ver_stock`, `gerir_movimentos` | `ver`, `criar`, `editar`, `apagar` |
| `hardware` | `ver_dispositivos`, `gerir_dispositivos`, `ver_eventos` | nenhuma |
| `impostos` | `ver_impostos`, `gerir_impostos` | `ver`, `criar`, `relatorios` |
| `logistica` | `ver_logistica`, `gerir_entregas` | `ver`, `criar`, `editar`, `apagar` |
| `modulo-faturacao` | `ver_documentos`, `configurar_series`, `emitir_orcamentos`, `emitir_encomendas`, `emitir_faturas`, `emitir_notas_credito` | `ver`, `criar`, `editar`, `relatorios` |
| `multi-moeda` | `ver_moedas`, `gerir_moedas` | `ver`, `criar`, `editar`, `configurar` |
| `notifications` | `ver_notificacoes`, `gerir_notificacoes` | `ver`, `criar`, `editar`, `apagar` |
| `pessoas` | usa `autorizacao:gerir_utilizadores` (único endpoint) | nenhuma própria |
| `pos` | `operar_pos`, `ver_vendas`, `gerir_terminais`, `gerir_catalogo`, `gerir_descontos` | `ver`, `criar`, `editar`, `apagar` |
| `recrutamento` | `ver_vagas`, `gerir_vagas`, `ver_candidaturas`, `gerir_candidaturas`, `contratar`, `configurar_recrutamento` | *parcialmente correto* |
| `recursos-humanos` | `ver_funcionarios`, `gerir_funcionarios`, `gerir_contratos`, `aprovar_ausencias`, `processar_salarios`, `ver_salarios`, `ver_recibos`, `gerir_beneficios`, `gerir_formacoes`, `gerir_avaliacoes`, `gerir_horarios`, `ver_processos_disciplinares`, `ver_relatorios` + permissões `assiduidade:*` | `ver`, `criar`, `editar`, `apagar` |
| `seguranca` | `ver_seguranca`, `gerir_politicas`, `gerir_allowlist` | `ver`, `editar`, `configurar`, `relatorios` |
| `self-service` | `perfil:*`, `chat:*`, `assiduidade:*` | muitas em falta para `funcionario` |
| `sistema-configuracao` | `ver_configuracoes`, `editar_configuracoes`, `gerir_templates` | `ver`, `editar`, `configurar`, `relatorios` |
| `tarefas` | `ver_quadros`, `gerir_quadros`, `gerir_listas`, `gerir_cartoes`, `mover_cartoes`, `eliminar_cartoes` | **nenhuma — módulo não está no catálogo** |
| `tesouraria` | `ver_tesouraria`, `gerir_movimentos`, `gerir_reconciliacao` | `ver`, `criar`, `editar`, `apagar` |
| `utilizadores` | `perfil:ver_perfil`, `perfil:editar_perfil` | **nenhuma** |

### Módulos com permissões relativamente alinhadas
- `auth` — RBAC maduro, mas com problemas de tenant isolation no login/refresh/POS.
- `gestao-escolar` — permissões finas existem e são atribuídas aos cargos escolares, mas há problemas de escopo/portal.
- `crm` / `recrutamento` — parcialmente alinhados, com bugs específicos.

---

## 3. Problema Sistémico #2 — Cross-Tenant e Autorização Fraca

### Cross-tenant confirmado (CRÍTICO)

| Módulo | Endpoint/Handler | O que falta |
|---|---|---|
| `auth` | `POST /api/authcode/admin/set-pin` | Não valida se `user_id` alvo pertence ao tenant do caller. |
| `auth` | `POST /api/auth/login`, `/refresh` | Membership ativa sem `ORDER BY`; múltiplas memberships causam tenant errado. |
| `auth` | `POST /api/pos/login` (terminal) | Itera todos os tenants por `codigo`/`activation_code`; ignora `tenant_slug`. |
| `empresas` | Quase todos os endpoints com `{id}` | Nenhum valida se a empresa pertence ao `TenantID` do caller (IDOR massivo). |
| `modulo-faturacao` | `POST /quotes/{id}/items`, `DELETE /quotes/{id}/items/{itemId}` | Handlers não chamam `mw.GetUser`; queries sem `tenant_id`. |
| `modulo-faturacao` | `POST /receipts` | UPDATE em `invoices` sem `tenant_id`. |
| `crm` | `POST /leads/{id}/converter` | UPDATE final sem `tenant_id`. |
| `crm` | `PUT /oportunidades/{id}/estagio`, `POST /oportunidades/{id}/perder` | UPDATE sem `tenant_id`. |
| `crm` | `POST /oportunidades`, `PUT /oportunidades/{id}` | `lead_id`/`cliente_id` não validados contra o tenant. |
| `financeiro` | `POST /contas-receber`, `/contas-pagar` | `customer_id`/`supplier_id` sem validação de tenant; sem FK. |
| `gestao-stock` | `GET /warehouses/{id}/locations`, `POST /warehouses/{id}/locations` | Não filtra/valida `warehouse_id` por tenant. |
| `logistica` | `POST /shipments` | `route_id`/`driver_id`/`vehicle_id`/`customer_id` não validados por tenant. |
| `multi-moeda` | `POST /moedas` | Cria moeda global sem restrição de superadmin. |
| `self-service` | `POST /chat/conversas` | Permite adicionar participantes de outros tenants. |
| `self-service` | `POST /comunicados/lido` | Não valida se o comunicado pertence ao tenant. |
| `sistema-configuracao` | `POST /currencies`, `/exchange-rates`, `/countries`, `/cities`, `/languages` | Tabelas globais sem isolamento por tenant. |
| `utilizadores` | Todos os endpoints `/{userId}/*` | Tabelas sem `tenant_id`; handlers não validam relação caller↔user. |

### Autorização fraca / granularidade insuficiente (MÉDIO)

| Módulo | Problema |
|---|---|
| `aprovacoes` | Todos os endpoints `/requests/*` acessíveis sem `RequirePermission`; decisão apenas por cargo. |
| `aprovacoes` | `EliminarFlow` conta pedidos pendentes sem filtrar por tenant. |
| `assinatura-digital` | `POST /documentos/{id}/revalidar` está no grupo de leitura; `Evidencias` expõe dados sensíveis com `ver_documentos`. |
| `auth` | `POST /authcode/totp/setup` sem reautenticação obrigatória; sem rate-limit em autenticação. |
| `compras` | Não há endpoints de atualização/eliminação. |
| `crm` | `DELETE /oportunidades/{id}` usa permissão `eliminar_leads` (errada). |
| `financeiro` | `POST /metodos-pagamento` exige `gerir_categorias` (copy-paste). |
| `gestao-clientes` | `gerir_credito` é permissão vazia; `DefinirLimiteCredito` sob `gerir_clientes`. |
| `gestao-escolar` | Webhook de pagamento requer JWT (inutilizável); professor vê qualquer turma; eventos não respeitam `publico_alvo`. |
| `hardware` | `GET /drivers` sem permissão RBAC. |
| `impostos` | `gerir_impostos` única para todas as escritas incluindo submissão de declarações. |
| `pos` | `POST /sales/{id}/cancelar` usa `operar_pos`; sem permissão de leitura dedicada. |
| `recrutamento` | `ContratarCandidato` cruza para RH/Auth/Escolar sem verificar permissões destinos. |
| `recursos-humanos` | Muitos endpoints de mutação por funcionário não usam `podeGerirFuncionario`. |
| `recursos-humanos` | `GET /funcionarios/{id}/formacoes` exige `gerir_formacoes` para leitura. |
| `recursos-humanos` | `POST /ausencias` exige `aprovar_ausencias` para criar. |
| `seguranca` | `EnviarPoliticaParaAssinatura` é dead code; `ListarMFAEnrollments` lista todos do tenant. |
| `self-service` | `/recibos/*` sem nenhuma permissão RBAC. |
| `superadmin` | Apenas `tipo == "superadmin"`; sem IP allowlist ativa, sem 2FA, sem granularidade. |
| `tarefas` | Sem modelo de membros do quadro; qualquer um com permissão opera sobre todos os quadros. |
| `tesouraria` | `gerir_movimentos` cobre contas/carteiras + movimentos. |

---

## 4. Módulos com Código Morto / Handlers Órfãos

| Módulo | Handler | Risco |
|---|---|---|
| `aprovacoes` | `EnviarRequestParaAssinatura` | Não registado no router. |
| `auditoria` | `EnviarDocumentoAuditoriaParaAssinatura` | Não registado; sem permissão. |
| `gestao-produtos` | `ListarCategorias`, `CriarCategoria`, `ActualizarCategoria`, `ObterProduto`, `ActualizarProduto`, `ListarPrecos`, `DefinirPreco`, `ListarVariantes`, `CriarVariante` | Não registados; alguns sem `tenant_id`. |
| `gestao-stock` | `ListarStockItems`, `InicializarStockItem`, `DefinirMinimoMaximo`, `ListarMovimentos`, `RegistarMovimento`, `ListarAjustes`, `CriarAjuste`, `ListarTransferencias`, `CriarTransferencia`, `RemoverLocalizacao` | Não registados; versões antigas sem isolamento. |
| `modulo-faturacao` | `AdicionarItemFatura`, `EmitirFatura` | Não registados; `AdicionarItemFatura` sem tenant. |
| `seguranca` | `EnviarPoliticaParaAssinatura` | Não registado; depende de colunas inexistentes. |

---

## 5. Recomendações Prioritárias

### 5.1 Corrigir o desalinhamento de permissões (impacto máximo) ✅ CONCLUÍDO

**Migration criada:** `backend/migrations/20260727093000_permissoes_cargos_padrao_finas.up.sql`

**O que foi feito:**
- Recriada `auth.criar_cargos_padrao()` para inserir **ações finas** em novos tenants.
- Backfill idempotente nos tenants existentes (5, 7, 10) convertendo ações genéricas (`ver`, `criar`, `editar`, `apagar`, etc.) nas ações finas que o router realmente verifica.
- Adicionadas permissões de módulos recentes: `tarefas`, `hardware`, `assinatura-digital`, `notificacoes`, `perfil`, `chat`.
- Atualizadas `auth.permissoes_tipo` para o tipo `funcionario`.
- Migration registada em `schema_migrations` e aplicada em produção.

**Validação:**
- `go build ./...` e `go test ./...` passam.
- Verificado em produção que cargos `Administrador` têm as permissões finas esperadas
  (`compras:ver_compras`, `financeiro:ver_financeiro`, `recursos-humanos:ver_funcionarios`,
  `stock:ver_stock`, `faturacao:emitir_faturas`, `pos:operar_pos`, `tarefas:ver_quadros`, etc.).

Exemplo de ações agora atribuídas:
- RH: `ver_funcionarios`, `gerir_funcionarios`, `gerir_contratos`, `aprovar_ausencias`, `processar_salarios`, `ver_salarios`, `ver_recibos`, `gerir_beneficios`, `gerir_formacoes`, `gerir_avaliacoes`, `gerir_horarios`, `ver_processos_disciplinares`, `ver_relatorios`.
- Assiduidade: `ver_configuracao`, `gerir_configuracao`, `aprovar_correcao`.
- Stock: `ver_stock`, `gerir_movimentos`, `gerir_produtos`, `gerir_categorias`, `eliminar_produtos`.
- Faturação: `ver_documentos`, `configurar_series`, `emitir_orcamentos`, `emitir_encomendas`, `emitir_faturas`, `emitir_notas_credito`.

### 5.2 Corrigir falhas cross-tenant (segurança)

1. Adicionar `AND tenant_id = $N` em todos os UPDATEs/DELETEs dos módulos CRM, Faturação, Empresas.
2. Validar FKs de entradas nos handlers (ex.: `customer_id`, `supplier_id`, `lead_id`, `company_id`) contra `tenant_id`.
3. Corrigir `auth/login`, `auth/refresh`, `authcode/admin/set-pin`, `pos/login`.
4. Adicionar `tenant_id` às tabelas de utilizadores ou validar relação caller↔user.

### 5.3 Revisar granularidade

- Separar permissões de leitura/escrita/administração.
- Criar permissões específicas para ações destrutivas: eliminar, submeter declaração, cancelar venda, contratar, enviar para assinatura.
- Adicionar `podeGerirFuncionario` em endpoints de mutação por funcionário no RH.

### 5.4 Remover ou proteger código morto

- Remover handlers não registados ou adicioná-los ao router com permissões corretas e `tenant_id`.

### 5.5 Superadmin

- Ativar `auth.superadmin_ip_allowlist`.
- Adicionar re-autenticação/2FA para operações críticas.
- Criar permissões granulares de superadmin.

---

## 6. Módulos com Menor Risco Imediato

- `gestao-escolar` — RBAC relativamente alinhado; problemas são de escopo/portal/webhook.
- `auth` — RBAC maduro; problemas de tenant isolation no login.
- `crm` / `recrutamento` — parcialmente alinhados, com bugs localizados.

---

## 7. Próximos Passos Sugeridos

1. ✅ **Fase 1 — Permissões dos cargos padrão:** concluída.
2. **Fase 2 — Corrigir falhas cross-tenant** (segurança): prioridade máxima.
3. **Fase 3 — Revisar granularidade** de permissões.
4. **Fase 4 — Remover ou proteger código morto**, corrigir webhooks e portais.
5. **Fase 5 — Superadmin e auditoria:** ativar IP allowlist, re-autenticação/2FA.
6. **Fase 6 — Testes e documentação final.**
