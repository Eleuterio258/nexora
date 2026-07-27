# Permissões por Módulo — Nexora ERP

> Lista gerada automaticamente a partir de `backend/internal/router/router.go`.
> Cada permissão é verificada pelo middleware `RequirePermission` / `RequirePermissionAny`.

---

## `assiduidade`

- `aprovar_correcao`
- `corrigir_ponto`
- `gerir_configuracao`
- `justificar`
- `ver_assiduidade`
- `ver_configuracao`

---

## `assinatura-digital`

- `assinar_documentos`
- `gerir_documentos`
- `ver_documentos`

---

## `assinaturas`

- `gerir_assinaturas`
- `ver_assinaturas`

---

## `auditoria`

- `gerir_logs`
- `ver_logs`

---

## `auth`

- `pin_admin`

---

## `autorizacao`

- `gerir_perfis`
- `gerir_utilizadores`

---

## `centros-custo`

- `eliminar_centros`
- `gerir_centros`
- `ver_centros`

---

## `chat`

- `enviar_mensagem`
- `ver_conversas`

---

## `clientes`

- `eliminar_clientes`
- `gerir_clientes`
- `gerir_credito`
- `gerir_grupos`
- `ver_clientes`

---

## `compras`

- `aprovar_pedidos`
- `criar_pedidos`
- `ver_compras`

---

## `contabilidade`

- `fechar_periodo`
- `gerir_ativos_fixos`
- `gerir_lancamentos`
- `gerir_orcamentos`
- `gerir_periodos`
- `gerir_plano_contas`
- `ver_contabilidade`
- `ver_relatorios`

---

## `crm`

- `converter_leads`
- `eliminar_leads`
- `gerir_atividades`
- `gerir_leads`
- `gerir_oportunidades`
- `mover_leads`
- `ver_leads`
- `ver_oportunidades`

---

## `empresa`

- `editar_empresa`
- `gerir_filiais`
- `gerir_licencas`
- `ver_empresa`

---

## `faturacao`

- `configurar_series`
- `emitir_encomendas`
- `emitir_faturas`
- `emitir_notas_credito`
- `emitir_orcamentos`
- `ver_documentos`

---

## `financeiro`

- `gerir_categorias`
- `gerir_contas_pagar`
- `gerir_contas_receber`
- `ver_financeiro`

---

## `gestao-escolar`

- `gerir_alunos`
- `gerir_biblioteca`
- `gerir_calendario`
- `gerir_comunicacao`
- `gerir_horarios`
- `gerir_matriculas`
- `gerir_ocorrencias`
- `gerir_presencas`
- `gerir_propinas`
- `gerir_turmas`
- `lancar_notas`
- `portal_aluno`
- `ver`

---

## `hardware`

- `gerir_dispositivos`
- `ver_dispositivos`
- `ver_eventos`

---

## `impostos`

- `gerir_impostos`
- `ver_impostos`

---

## `logistica`

- `gerir_entregas`
- `ver_logistica`

---

## `multi-moeda`

- `gerir_moedas`
- `ver_moedas`

---

## `notificacoes`

- `gerir_notificacoes`
- `ver_notificacoes`

---

## `pedido-ferias`

- `submeter_pedido`
- `ver_pedidos`

---

## `perfil`

- `editar_perfil`
- `ver_perfil`

---

## `pos`

- `gerir_catalogo`
- `gerir_descontos`
- `gerir_terminais`
- `operar_pos`

---

## `recrutamento`

- `configurar_recrutamento`
- `gerir_candidaturas`
- `gerir_vagas`
- `ver_candidaturas`
- `ver_vagas`

---

## `recursos-humanos`

- `aprovar_ausencias`
- `gerir_avaliacoes`
- `gerir_beneficios`
- `gerir_contratos`
- `gerir_formacoes`
- `gerir_funcionarios`
- `gerir_horarios`
- `processar_salarios`
- `ver_beneficios`
- `ver_funcionarios`
- `ver_processos_disciplinares`
- `ver_recibos`
- `ver_salarios`

---

## `seguranca`

- `gerir_allowlist`
- `gerir_politicas`
- `ver_seguranca`

---

## `sistema-configuracao`

- `editar_configuracoes`
- `gerir_templates`
- `ver_configuracoes`

---

## `stock`

- `eliminar_produtos`
- `gerir_categorias`
- `gerir_movimentos`
- `gerir_produtos`
- `ver_stock`

---

## `tarefas`

- `eliminar_cartoes`
- `gerir_cartoes`
- `gerir_listas`
- `gerir_quadros`
- `mover_cartoes`
- `ver_quadros`

---

## `tesouraria`

- `gerir_movimentos`
- `gerir_reconciliacao`
- `ver_tesouraria`

---

## Total

- **31 módulos**
- **Permissões por módulo variam de 1 a 14**

### Módulos com mais permissões

1. `gestao-escolar` — 14 permissões
2. `contabilidade` — 8 permissões
3. `crm` — 8 permissões
4. `recursos-humanos` — 13 permissões
5. `stock` — 5 permissões
6. `clientes` — 5 permissões

---

## Nota

Para criar um novo cargo ou role, basta selecionar as permissões desejadas desta lista e associá-las via tabelas:

- `autorizacao.roles`
- `autorizacao.permissions`
- `autorizacao.role_permissions`
- `autorizacao.user_roles`

Ou, alternativamente, usar permissões de cargo via `auth.permissoes_cargo`.
