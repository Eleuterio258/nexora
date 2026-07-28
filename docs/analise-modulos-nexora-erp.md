# Análise de Todos os Módulos — Nexora ERP

> Documento com visão geral de todos os módulos do backend Go, baseado em `backend/internal/router/router.go`.

---

## 1. Módulo: `auth`

**Descrição:** Autenticação, sessões, OAuth2, PINs, JWT.

**Permissões:**
- `auth:pin_admin`

**Principais endpoints:**
- `POST /api/auth/login`
- `POST /api/auth/logout`
- `POST /api/auth/refresh`
- `POST /api/auth/mfa/verify`
- `POST /api/auth/password/reset`
- `POST /api/auth/pin/reset`
- `POST /api/oauth/token`
- `GET /api/auth/me`

---

## 2. Módulo: `autorizacao`

**Descrição:** Gestão de utilizadores, roles, permissões e membros.

**Permissões:**
- `autorizacao:gerir_utilizadores`
- `autorizacao:gerir_perfis`

**Principais endpoints:**
- `GET /api/utilizadores`
- `POST /api/utilizadores`
- `PUT /api/utilizadores/{id}`
- `GET /api/utilizadores/{id}/permissoes`
- `POST /api/utilizadores/{id}/roles`
- `GET /api/modules` (listar módulos/permissões)

---

## 3. Módulo: `empresa`

**Descrição:** Gestão da empresa, filiais, licenças e configurações globais.

**Permissões:**
- `empresa:ver_empresa`
- `empresa:editar_empresa`
- `empresa:gerir_filiais`
- `empresa:gerir_licencas`

**Principais endpoints:**
- `GET /api/companies`
- `GET /api/companies/{id}`
- `POST /api/companies`
- `PUT /api/companies/{id}`
- `GET /api/companies/{id}/branches`
- `POST /api/companies/{id}/subscriptions`
- `GET /api/plans`
- `GET /api/features`

---

## 4. Módulo: `sistema-configuracao`

**Descrição:** Configurações do sistema, templates, notificações.

**Permissões:**
- `sistema-configuracao:ver_configuracoes`
- `sistema-configuracao:editar_configuracoes`
- `sistema-configuracao:gerir_templates`

**Principais endpoints:**
- `GET /api/system/settings`
- `PUT /api/system/settings`
- `GET /api/system/templates`
- `POST /api/system/templates`
- `GET /api/notificacoes`
- `POST /api/notificacoes`

---

## 5. Módulo: `seguranca`

**Descrição:** Segurança, políticas de password, allowlist de IPs.

**Permissões:**
- `seguranca:ver_seguranca`
- `seguranca:gerir_politicas`
- `seguranca:gerir_allowlist`

**Principais endpoints:**
- `GET /api/system/security/policies`
- `PUT /api/system/security/policies`
- `GET /api/system/security/ip-allowlist`
- `POST /api/system/security/ip-allowlist`

---

## 6. Módulo: `auditoria`

**Descrição:** Logs de auditoria e eventos do sistema.

**Permissões:**
- `auditoria:ver_logs`
- `auditoria:gerir_logs`

**Principais endpoints:**
- `GET /api/audit-logs`
- `GET /api/audit-logs/{id}`

---

## 7. Módulo: `perfil`

**Descrição:** Perfil do utilizador autenticado, notificações pessoais, self-service geral.

**Permissões:**
- `perfil:ver_perfil`
- `perfil:editar_perfil`

**Principais endpoints:**
- `GET /api/self-service/home`
- `PUT /api/self-service/perfil`
- `POST /api/self-service/notificacoes/lida`
- `POST /api/self-service/comunicados/lido`

---

## 8. Módulo: `chat`

**Descrição:** Mensagens e conversas internas.

**Permissões:**
- `chat:ver_conversas`
- `chat:enviar_mensagem`

**Principais endpoints:**
- `GET /api/chat/conversations`
- `POST /api/chat/conversations`
- `GET /api/chat/conversations/{id}/messages`
- `POST /api/chat/conversations/{id}/messages`

---

## 9. Módulo: `notificacoes`

**Descrição:** Notificações push, email, comunicados.

**Permissões:**
- `notificacoes:ver_notificacoes`
- `notificacoes:gerir_notificacoes`

**Principais endpoints:**
- `GET /api/notificacoes`
- `POST /api/notificacoes`
- `POST /api/notificacoes/send`

---

## 10. Módulo: `recursos-humanos`

**Descrição:** Gestão completa de funcionários, contratos, salários, benefícios, formações, avaliações, cargos, horários, unidades.

**Permissões:**
- `recursos-humanos:ver_funcionarios`
- `recursos-humanos:gerir_funcionarios`
- `recursos-humanos:ver_recibos`
- `recursos-humanos:ver_salarios`
- `recursos-humanos:processar_salarios`
- `recursos-humanos:ver_beneficios`
- `recursos-humanos:gerir_beneficios`
- `recursos-humanos:gerir_formacoes`
- `recursos-humanos:gerir_contratos`
- `recursos-humanos:gerir_avaliacoes`
- `recursos-humanos:gerir_horarios`
- `recursos-humanos:aprovar_ausencias`
- `recursos-humanos:ver_processos_disciplinares`

**Principais endpoints:**
- `GET /api/rh/funcionarios`
- `POST /api/rh/funcionarios`
- `GET /api/rh/funcionarios/{id}`
- `PUT /api/rh/funcionarios/{id}`
- `POST /api/rh/funcionarios/{id}/biometria/facial/enroll`
- `POST /api/rh/funcionarios/{id}/desligar`
- `GET /api/rh/contratos`
- `POST /api/rh/contratos`
- `GET /api/rh/folhas-pagamento`
- `POST /api/rh/folhas-pagamento`
- `GET /api/rh/cargos`
- `GET /api/rh/horarios`
- `GET /api/rh/unidades`

---

## 11. Módulo: `assiduidade`

**Descrição:** Controlo de presenças, marcações, justificações, correções, configuração de eventos e regras.

**Permissões:**
- `assiduidade:ver_assiduidade`
- `assiduidade:justificar`
- `assiduidade:corrigir_ponto`
- `assiduidade:ver_configuracao`
- `assiduidade:gerir_configuracao`
- `assiduidade:aprovar_correcao`

**Principais endpoints:**
- `GET /api/self-service/assiduidade`
- `POST /api/self-service/assiduidade/justificacoes`
- `POST /api/self-service/assiduidade/correcoes`
- `GET /api/rh/assiduidade/eventos`
- `GET /api/rh/tipos-evento`
- `POST /api/rh/tipos-evento`
- `GET /api/rh/metodos-marcacao`
- `POST /api/rh/metodos-marcacao`
- `GET /api/rh/regras`
- `POST /api/rh/regras`
- `GET /api/rh/correcoes-ponto`
- `POST /api/rh/correcoes-ponto/{id}/aprovar`

---

## 12. Módulo: `pedido-ferias`

**Descrição:** Pedidos de férias e ausências pelo funcionário.

**Permissões:**
- `pedido-ferias:ver_pedidos`
- `pedido-ferias:submeter_pedido`

**Principais endpoints:**
- `GET /api/pedido-ferias`
- `POST /api/pedido-ferias`
- `POST /api/pedido-ferias/{id}/cancelar`
- `GET /api/pedido-ferias/tipos`

---

## 13. Módulo: `hardware`

**Descrição:** Dispositivos de assiduidade (terminais, leitores, relógios de ponto) e eventos de hardware.

**Permissões:**
- `hardware:ver_dispositivos`
- `hardware:gerir_dispositivos`
- `hardware:ver_eventos`

**Principais endpoints:**
- `GET /api/hardware/dispositivos`
- `POST /api/hardware/dispositivos`
- `GET /api/hardware/dispositivos/{id}`
- `POST /api/hardware/assiduidade/eventos`
- `POST /api/hardware/assiduidade/consentimentos`
- `GET /api/hardware/eventos`

---

## 14. Módulo: `stock`

**Descrição:** Gestão de inventário, produtos, categorias, movimentações de stock.

**Permissões:**
- `stock:ver_stock`
- `stock:gerir_produtos`
- `stock:gerir_categorias`
- `stock:gerir_movimentos`
- `stock:eliminar_produtos`

**Principais endpoints:**
- `GET /api/produtos`
- `POST /api/produtos`
- `GET /api/produtos/{id}`
- `PUT /api/produtos/{id}`
- `GET /api/categorias`
- `POST /api/stock/movimentos`
- `GET /api/stock/movimentos`

---

## 15. Módulo: `compras`

**Descrição:** Pedidos de compra, aprovações, fornecedores.

**Permissões:**
- `compras:ver_compras`
- `compras:criar_pedidos`
- `compras:aprovar_pedidos`

**Principais endpoints:**
- `GET /api/compras/pedidos`
- `POST /api/compras/pedidos`
- `POST /api/compras/pedidos/{id}/aprovar`
- `GET /api/compras/fornecedores`

---

## 16. Módulo: `clientes`

**Descrição:** Gestão de clientes, grupos de clientes e crédito.

**Permissões:**
- `clientes:ver_clientes`
- `clientes:gerir_clientes`
- `clientes:gerir_grupos`
- `clientes:gerir_credito`
- `clientes:eliminar_clientes`

**Principais endpoints:**
- `GET /api/clientes`
- `POST /api/clientes`
- `GET /api/clientes/{id}`
- `POST /api/clientes/{id}/credit-limit`
- `GET /api/clientes/grupos`

---

## 17. Módulo: `crm`

**Descrição:** Leads, oportunidades, atividades comerciais.

**Permissões:**
- `crm:ver_leads`
- `crm:gerir_leads`
- `crm:mover_leads`
- `crm:converter_leads`
- `crm:eliminar_leads`
- `crm:gerir_oportunidades`
- `crm:ver_oportunidades`
- `crm:gerir_atividades`

**Principais endpoints:**
- `GET /api/crm/leads`
- `POST /api/crm/leads`
- `POST /api/crm/leads/{id}/convert`
- `GET /api/crm/oportunidades`
- `POST /api/crm/oportunidades`
- `GET /api/crm/atividades`

---

## 18. Módulo: `faturacao`

**Descrição:** Emissão de faturas, orçamentos, notas de crédito, encomendas e séries de documentos.

**Permissões:**
- `faturacao:ver_documentos`
- `faturacao:emitir_faturas`
- `faturacao:emitir_orcamentos`
- `faturacao:emitir_notas_credito`
- `faturacao:emitir_encomendas`
- `faturacao:configurar_series`

**Principais endpoints:**
- `GET /api/faturacao/faturas`
- `POST /api/faturacao/faturas`
- `GET /api/faturacao/orcamentos`
- `POST /api/faturacao/orcamentos`
- `POST /api/faturacao/notas-credito`
- `GET /api/faturacao/series`

---

## 19. Módulo: `pos`

**Descrição:** Ponto de venda (POS), terminais, catálogo, descontos.

**Permissões:**
- `pos:operar_pos`
- `pos:gerir_terminais`
- `pos:gerir_catalogo`
- `pos:gerir_descontos`

**Principais endpoints:**
- `POST /api/pos/sales`
- `GET /api/pos/terminais`
- `POST /api/pos/terminais`
- `GET /api/pos/catalogo`
- `POST /api/pos/descontos`

---

## 20. Módulo: `financeiro`

**Descrição:** Contas a pagar, contas a receber, categorias financeiras.

**Permissões:**
- `financeiro:ver_financeiro`
- `financeiro:gerir_contas_pagar`
- `financeiro:gerir_contas_receber`
- `financeiro:gerir_categorias`

**Principais endpoints:**
- `GET /api/financeiro/contas-pagar`
- `POST /api/financeiro/contas-pagar`
- `GET /api/financeiro/contas-receber`
- `POST /api/financeiro/contas-receber`

---

## 21. Módulo: `tesouraria`

**Descrição:** Movimentos de caixa/banco, reconciliação bancária.

**Permissões:**
- `tesouraria:ver_tesouraria`
- `tesouraria:gerir_movimentos`
- `tesouraria:gerir_reconciliacao`

**Principais endpoints:**
- `GET /api/tesouraria/movimentos`
- `POST /api/tesouraria/movimentos`
- `GET /api/tesouraria/reconciliacao`
- `POST /api/tesouraria/reconciliacao`

---

## 22. Módulo: `multi-moeda`

**Descrição:** Moedas e taxas de câmbio.

**Permissões:**
- `multi-moeda:ver_moedas`
- `multi-moeda:gerir_moedas`

**Principais endpoints:**
- `GET /api/moedas`
- `POST /api/moedas`
- `GET /api/taxas-cambio`
- `POST /api/taxas-cambio`

---

## 23. Módulo: `contabilidade`

**Descrição:** Plano de contas, lançamentos, ativos fixos, orçamentos, períodos fiscais.

**Permissões:**
- `contabilidade:ver_contabilidade`
- `contabilidade:gerir_plano_contas`
- `contabilidade:gerir_lancamentos`
- `contabilidade:gerir_periodos`
- `contabilidade:gerir_ativos_fixos`
- `contabilidade:gerir_orcamentos`
- `contabilidade:fechar_periodo`
- `contabilidade:ver_relatorios`

**Principais endpoints:**
- `GET /api/contabilidade/plano-contas`
- `POST /api/contabilidade/plano-contas`
- `GET /api/contabilidade/lancamentos`
- `POST /api/contabilidade/lancamentos`
- `GET /api/contabilidade/fixed-assets`
- `GET /api/contabilidade/reports`

---

## 24. Módulo: `impostos`

**Descrição:** Taxas de imposto, grupos fiscais, transações fiscais.

**Permissões:**
- `impostos:ver_impostos`
- `impostos:gerir_impostos`

**Principais endpoints:**
- `GET /api/impostos/taxas`
- `POST /api/impostos/taxas`
- `GET /api/impostos/grupos`
- `POST /api/impostos/grupos`

---

## 25. Módulo: `centros-custo`

**Descrição:** Centros de custo e análise de custos.

**Permissões:**
- `centros-custo:ver_centros`
- `centros-custo:gerir_centros`
- `centros-custo:eliminar_centros`

**Principais endpoints:**
- `GET /api/centros-custo`
- `POST /api/centros-custo`
- `PUT /api/centros-custo/{id}`

---

## 26. Módulo: `logistica`

**Descrição:** Entregas, transporte e logística.

**Permissões:**
- `logistica:ver_logistica`
- `logistica:gerir_entregas`

**Principais endpoints:**
- `GET /api/logistica/entregas`
- `POST /api/logistica/entregas`
- `PUT /api/logistica/entregas/{id}/status`

---

## 27. Módulo: `tarefas`

**Descrição:** Quadros Kanban, listas, cartões de tarefas.

**Permissões:**
- `tarefas:ver_quadros`
- `tarefas:gerir_quadros`
- `tarefas:gerir_listas`
- `tarefas:gerir_cartoes`
- `tarefas:mover_cartoes`
- `tarefas:eliminar_cartoes`

**Principais endpoints:**
- `GET /api/tarefas/quadros`
- `POST /api/tarefas/quadros`
- `GET /api/tarefas/quadros/{id}/listas`
- `POST /api/tarefas/listas/{id}/cartoes`

---

## 28. Módulo: `recrutamento`

**Descrição:** Vagas, candidaturas, processo seletivo.

**Permissões:**
- `recrutamento:ver_vagas`
- `recrutamento:gerir_vagas`
- `recrutamento:ver_candidaturas`
- `recrutamento:gerir_candidaturas`
- `recrutamento:configurar_recrutamento`

**Principais endpoints:**
- `GET /api/recrutamento/vagas`
- `POST /api/recrutamento/vagas`
- `GET /api/recrutamento/candidaturas`
- `POST /api/recrutamento/candidaturas/{id}/avancar`
- `GET /api/public/recrutamento/vagas`
- `GET /api/public/recrutamento/candidatos/perfil`

---

## 29. Módulo: `assinatura-digital`

**Descrição:** Assinatura digital de documentos.

**Permissões:**
- `assinatura-digital:ver_documentos`
- `assinatura-digital:gerir_documentos`
- `assinatura-digital:assinar_documentos`

**Principais endpoints:**
- `GET /api/assinaturas/documentos`
- `POST /api/assinaturas/documentos`
- `POST /api/assinaturas/documentos/{id}/sign`

---

## 30. Módulo: `assinaturas`

**Descrição:** Configuração de assinaturas e templates.

**Permissões:**
- `assinaturas:ver_assinaturas`
- `assinaturas:gerir_assinaturas`

**Principais endpoints:**
- `GET /api/assinaturas/config`
- `POST /api/assinaturas/config`

---

## 31. Módulo: `gestao-escolar`

**Descrição:** Gestão de escolas: alunos, turmas, matrículas, notas, presenças, propinas, horários.

**Permissões:**
- `gestao-escolar:ver`
- `gestao-escolar:gerir_alunos`
- `gestao-escolar:gerir_turmas`
- `gestao-escolar:gerir_matriculas`
- `gestao-escolar:gerir_horarios`
- `gestao-escolar:gerir_presencas`
- `gestao-escolar:lancar_notas`
- `gestao-escolar:gerir_propinas`
- `gestao-escolar:gerir_comunicacao`
- `gestao-escolar:gerir_calendario`
- `gestao-escolar:gerir_ocorrencias`
- `gestao-escolar:gerir_biblioteca`
- `gestao-escolar:portal_aluno`

**Principais endpoints:**
- `GET /api/escolar/alunos`
- `POST /api/escolar/alunos`
- `GET /api/escolar/turmas`
- `POST /api/escolar/turmas`
- `GET /api/escolar/matriculas`
- `POST /api/escolar/matriculas`
- `GET /api/escolar/propinas`
- `POST /api/escolar/propinas`
- `GET /api/portal/aluno`
- `GET /api/portal/professor`

---

## Resumo por módulo

| # | Módulo | Foco principal | Nº permissões |
|---|--------|----------------|---------------|
| 1 | `auth` | Autenticação | 1 |
| 2 | `autorizacao` | Roles e utilizadores | 2 |
| 3 | `empresa` | Empresa e filiais | 4 |
| 4 | `sistema-configuracao` | Configurações e templates | 3 |
| 5 | `seguranca` | Segurança e IPs | 3 |
| 6 | `auditoria` | Logs | 2 |
| 7 | `perfil` | Perfil pessoal | 2 |
| 8 | `chat` | Mensagens | 2 |
| 9 | `notificacoes` | Notificações | 2 |
| 10 | `recursos-humanos` | Funcionários e salários | 13 |
| 11 | `assiduidade` | Presenças e ponto | 6 |
| 12 | `pedido-ferias` | Férias | 2 |
| 13 | `hardware` | Dispositivos de ponto | 3 |
| 14 | `stock` | Inventário | 5 |
| 15 | `compras` | Compras | 3 |
| 16 | `clientes` | Clientes | 5 |
| 17 | `crm` | Leads e vendas | 8 |
| 18 | `faturacao` | Faturas e documentos | 6 |
| 19 | `pos` | Ponto de venda | 4 |
| 20 | `financeiro` | Contas | 4 |
| 21 | `tesouraria` | Caixa/banco | 3 |
| 22 | `multi-moeda` | Moedas | 2 |
| 23 | `contabilidade` | Contabilidade | 8 |
| 24 | `impostos` | Impostos | 2 |
| 25 | `centros-custo` | Centros de custo | 3 |
| 26 | `logistica` | Entregas | 2 |
| 27 | `tarefas` | Tarefas | 6 |
| 28 | `recrutamento` | Recrutamento | 5 |
| 29 | `assinatura-digital` | Assinatura digital | 3 |
| 30 | `assinaturas` | Config assinaturas | 2 |
| 31 | `gestao-escolar` | Escolas | 14 |

**Total: 31 módulos**

---

## Referências

- [Permissões por Módulo](./permissoes-por-modulo.md)
- [Roles Recomendados](./roles-recomendados.md)
- [Permissões do Módulo Recursos Humanos](./permissoes-modulo-recursos-humanos.md)
- [Endpoints FaceClock Python](./endpoints-faceclock-python.md)
