# Plano de Correção de Permissões — Dividido em Fases

> Data: 2026-07-27  
> Última actualização: 2026-07-27  
> Baseado em: `docs/analise-permissoes-todos-modulos.md`
>
> **Estado geral:** Todas as fases concluídas.

---

## Objetivo

Restaurar o RBAC funcional em todos os módulos do backend Go, corrigir falhas de isolamento por tenant e eliminar código morto/orfão, sem quebrar contratos de API existentes.

---

## Fase 1 — Permissões dos Cargos Padrão (fundamental) ✅ CONCLUÍDA
**Objetivo:** resolver o bloqueio sistémico onde módulos ficam inacessíveis a utilizadores normais.

**Tarefas concluídas:**
1. Revisadas todas as permissões exigidas pelo router em `internal/router/router.go`.
2. Recriada `auth.criar_cargos_padrao()` na migration `20260727093000_permissoes_cargos_padrao_finas.up.sql` para atribuir ações **finas** por cargo em vez de ações genéricas (`ver`, `criar`, etc.).
3. Feito backfill idempotente nos tenants existentes:
   - Conversão de ações genéricas em finas (compras, financeiro, tesouraria, contabilidade, etc.).
   - Correção do CRM: adicionadas ações finas (`ver_leads`, `gerir_leads`, `mover_leads`, etc.) a cargos `Administrador` que não as tinham.
   - Remoção das ações genéricas órfãs do módulo `crm`.
4. Garantida criação automática de cargos padrão para novos tenants.

**Módulos afetados principais:**
- `compras`, `contabilidade`, `financeiro`, `tesouraria`, `impostos`
- `gestao-clientes`, `gestao-produtos`, `gestao-stock`, `centros-custo`, `multi-moeda`, `logistica`
- `modulo-faturacao`, `assinaturas`, `notifications`, `auditoria`, `seguranca`
- `recursos-humanos`, `hardware`, `tarefas`, `utilizadores`, `pessoas`, `self-service`

**Entregável:** migration aplicada em dev/staging; `go build ./...` e `go test ./...` passando.

---

## Fase 2 — Correção de Cross-Tenant (segurança crítica) ✅ CONCLUÍDA
**Objetivo:** eliminar leituras/escritas entre tenants.

**Tarefas concluídas:**
1. Adicionar `AND tenant_id = $N` em UPDATEs/DELETEs que faltam.
2. Validar IDs de entidades relacionadas (`customer_id`, `supplier_id`, `lead_id`, `company_id`, `route_id`, etc.) contra o tenant.
3. Corrigir módulos `auth` (login/refresh/PIN/POS login).
4. Criar testes de integração que provem isolamento cross-tenant.

**Endpoints/handlers corrigidos:**
- `empresas` — `ListarEmpresas`, `CriarEmpresa`, `ObterEmpresa`, `ActualizarEmpresa`, branches, settings, tax info, bancos, contactos, endereços, licenças, company users.
- `modulo-faturacao` — `AdicionarItemOrcamento`, `RemoverItemOrcamento`, `AdicionarItemFatura`, `CriarRecibo`, `CriarNotaCredito`, validação de `customer_id` em orçamentos/encomendas/faturas.
- `crm` — validação de `lead_id`/`cliente_id` em atividades/oportunidades, `tenant_id` em UPDATEs de leads/oportunidades.
- `gestao-stock` — localizações de armazém (`ListarLocalizacoes`, `CriarLocalizacao`, `RemoverLocalizacao`).
- `logistica` — `CriarEnvio` valida `customer_id`, `route_id`, `driver_id`, `vehicle_id`.
- `financeiro` — valida `customer_id`, `supplier_id`, `financial_category_id`, `payment_method_id` em contas e pagamentos.
- `auth` — `ORDER BY` determinístico em login/refresh/me; `AdminDefinirPIN` restringe por tenant; `loginTerminalPOS` exige `tenant_slug`.

**Testes adicionados:**
- `backend/internal/modules/empresas/handlers/cross_tenant_test.go`
- `backend/internal/modules/modulo-faturacao/handlers/cross_tenant_test.go`

**Entregável:** `go build ./...` e `go test ./...` passando; isolamento cross-tenant reforçado.

---

## Fase 3 — Granularidade e Permissões Específicas
**Objetivo:** separar permissões de leitura, escrita, administração e ações sensíveis.

**Tarefas:**
1. Criar permissões específicas para ações destrutivas/sensíveis (ex.: `eliminar_vagas`, `submeter_declaracao`, `cancelar_vendas`, `enviar_para_assinatura`).
2. Separar permissões de configuração vs operação (ex.: `gerir_contas` vs `gerir_movimentos` na tesouraria).
3. Aplicar `podeGerirFuncionario` nos endpoints de mutação por funcionário no RH.
4. Corrigir mapeamentos errados (ex.: CRM `eliminar_oportunidades`, `ver_atividades`).
5. Atualizar router e migrations.

**Entregável:** modelo de permissões mais fino; testes de RBAC atualizados.

---

## Fase 4 — Código Morto, Webhooks e Portais
**Objetivo:** limpar handlers órfãos e corrigir endpoints especiais.

**Tarefas:**
1. Remover ou registar/proteger handlers não roteados (`gestao-produtos`, `gestao-stock`, `modulo-faturacao`, `auditoria`, `seguranca`, `aprovacoes`).
2. Corrigir webhook de pagamento escolar (`/api/escolar/payments/callback`) para não exigir JWT.
3. Corrigir portais do professor (verificar atribuição à turma) e do aluno (respeitar `publico_alvo`).
4. Adicionar `RequireFeature` onde falta (ex.: `rh.assiduidade`, `logistica`).

**Entregável:** código limpo; webhooks e portais funcionais.

---

## Fase 5 — Superadmin e Auditoria
**Objetivo:** reforçar segurança administrativa.

**Tarefas:**
1. Ativar `auth.superadmin_ip_allowlist` via middleware.
2. Exigir re-autenticação/2FA para operações críticas de superadmin.
3. Criar permissões granulares de superadmin (`superadmin:gerir_tenants`, etc.) ou manter modelo atual documentado.
4. Adicionar `mw.AuditModule` aos módulos que ainda não têm (`tarefas`, `hardware`, `crm`, `empresas`, etc.).

**Entregável:** superadmin protegido; auditoria alargada.

---

## Fase 6 — Testes e Documentação Final
**Objetivo:** garantir que as correções não regredem.

**Tarefas:**
1. Criar suite de testes de permissões por módulo (pgxmock ou containers PostgreSQL).
2. Criar testes cross-tenant automatizados.
3. Atualizar `docs/permissoes-por-modulo.md` com permissões finais.
4. Documentar cargos padrão e permissões por módulo.

**Entregável:** `go test ./...` passando; documentação atualizada.

---

## Ordem de execução recomendada

```
Fase 1 → Fase 2 → Fase 3 → Fase 4 → Fase 5 → Fase 6
```

**Porquê:**
- Sem a **Fase 1**, os utilizários não conseguem sequer usar os módulos.
- Sem a **Fase 2**, os dados entre tenants não estão seguros.
- As restantes fases são melhorias de governança e manutenção.

---

## Estimativa de esforço (aproximada)

| Fase | Duração estimada | Complexidade |
|---|---|---|
| 1 — Permissões dos cargos padrão | 1–2 dias | Média |
| 2 — Cross-tenant | 2–3 dias | Alta |
| 3 — Granularidade | 1–2 dias | Média |
| 4 — Código morto/webhooks/portais | 1–2 dias | Média |
| 5 — Superadmin e auditoria | 1 dia | Média |
| 6 — Testes e documentação | 1–2 dias | Média |

**Total estimado:** 7–12 dias de trabalho focado.

---

## Próxima decisão

Escolher por onde começar:
1. **Fase 1** (resolver bloqueio geral de permissões).
2. **Fase 2** (corrigir cross-tenant primeiro — risco de segurança mais alto).
3. **Fase 1 + Fase 2 em paralelo** (maior risco de conflitos, mas mais rápido).
