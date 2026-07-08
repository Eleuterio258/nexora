# Documentação Técnica do Banco de Dados — Nexora / ERP Escolar

**Versão:** 1.0  
**Origem:** documentação técnica reorganizada a partir do material fornecido.  
**Escopo:** autenticação, acessos de teste, módulo escolar, arquitetura multi-schema e observações de refatoração.

---

## 1. Visão geral

Esta documentação consolida a estrutura do banco de dados da plataforma, com foco em quatro frentes:

1. Acessos e associações de utilizadores para ambiente de teste.
2. Estrutura funcional do módulo `gestao_escolar`.
3. Organização dos 28 schemas e 304 tabelas do banco (após limpeza de duplicados legado).
4. Pontos críticos de refatoração, duplicidade e segurança.

### 1.1 Escopo técnico

| Item | Descrição |
|---|---|
| Produto | Plataforma ERP / Gestão Escolar / Gestão Empresarial |
| Modelo | Multi-tenant, com separação por tenants, módulos e permissões |
| Banco de dados | Organizado em schemas funcionais |
| Quantidade informada | 29 schemas e 332 tabelas |
| Módulo detalhado | `gestao_escolar` |

### 1.2 Alerta de segurança

As credenciais listadas abaixo devem ser tratadas como **credenciais de ambiente de desenvolvimento ou teste**. Não devem ser utilizadas em produção. Antes de qualquer publicação externa, recomenda-se:

- Remover senhas explícitas da documentação pública.
- Trocar a senha padrão dos utilizadores.
- Separar credenciais por perfil.
- Ativar MFA para perfis administrativos.
- Guardar hashes e segredos apenas em cofre seguro ou variável de ambiente.

---

## 2. Acessos, utilizadores e associações

Feito! A senha de **todos os utilizadores** foi definida para `1234567890` e as associações foram feitas.

Resumo:

| Tipo | Quantidade | Associação |
|---|---|---|
| Alunos | 31 | `school_students.user_id` → `auth.users` |
| Encarregados | 31 | `school_guardians.user_id` → `auth.users` |
| Funcionários | 41 | `auth.users` (inclui professores como funcionários) |
| Superadmin | 1 | `auth.users` |
| **Total** | **104** | Todos com a mesma senha |

### Professores associados
Criei users para os **32 professores** do tenant 5 que ainda não tinham `user_id` e actualizei `school_teachers.user_id`. Criado também `auth.memberships` para eles no tenant `5` com escopo `escola`.

Exemplo de emails de professores:
- `professor.prof-01@nexora.test` (Ana Joaquina Machava)
- `professor.prof-02@nexora.test` (Carlos António Nhacolo)
- `professor.matematica@nexora.test` (Antonio Silva)
- `professor.geologia@nexora.test` (Helena Mucavele)

### Exemplos de login

| Portal | Email | Senha |
|---|---|---|
| ERP / Escola | `admin@enigmaschool.mz` | `1234567890` |
| Portal do Aluno | `aluno01.pfa@nexora.test` | `1234567890` |
| Portal do Encarregado | `encarregado01.pfa@nexora.test` | `1234567890` |
| Professor | `professor.prof-01@nexora.test` | `1234567890` |

Hash usado (bcrypt `$2a$`):  
`$2a$12$fKX9WLMbacb6XcrLuagGR.4Krl22c4CG8XE0Pc5eF9drEehj9DZn6`

---

## 3. Módulo `gestao_escolar` — Estrutura funcional

### Configuração e estrutura escolar
| Tabela | Função |
|---|---|
| **school_years** | Anos letivos (ex.: 2026) |
| **school_levels** | Níveis de ensino (pré-escolar, primário, secundário, técnico médio) |
| **school_series** | Séries/anos dentro de cada nível (1º ano, 2º ano, etc.) |
| **school_cycles** | Ciclos do ensino (opcional) |
| **school_terms** | Períodos/trimestres do ano letivo |
| **school_courses** | Cursos técnicos/profissionais (CTA, PFA) |
| **school_course_subjects** | Disciplinas de cada curso/série/semestre |
| **school_subjects** | Cadastro de disciplinas |
| **school_classes** | Turmas (ex.: PFA-1ANO-A-2026) |
| **school_time_slots** | Horários das aulas (m1, m2, m3, etc.) |
| **school_timetable_entries** | Horários de aula por turma, dia, slot e disciplina |
| **school_academic_config** | Configurações académicas do sistema |

### Pessoas
| Tabela | Função |
|---|---|
| **school_students** | Alunos matriculados |
| **school_guardians** | Encarregados de educação dos alunos |
| **school_teachers** | Professores |
| **school_teacher_assignments** | Atribuição de professores a disciplinas/turmas |
| **school_teacher_roles** | Funções/cargos dos professores |
| **school_student_roles** | Funções/cargos dos alunos |

### Matrículas e frequência
| Tabela | Função |
|---|---|
| **school_enrollments** | Matrículas dos alunos nas turmas |
| **school_attendance** | Presenças/faltas dos alunos |
| **school_incident_types** | Tipos de incidentes disciplinares |
| **school_student_incidents** | Incidentes registados aos alunos |
| **school_sanction_types** | Tipos de sanções |
| **school_student_sanctions** | Sanções aplicadas aos alunos |
| **school_student_merits** | Méritos/distinções dos alunos |

### Avaliação e notas
| Tabela | Função |
|---|---|
| **school_evaluation_types** | Tipos de avaliação (teste, trabalho, exame) |
| **school_grade_items** | Itens de avaliação |
| **school_grades** | Notas dos alunos |
| **school_grade_formulas** | Fórmulas de cálculo de médias |
| **school_academic_transcripts** | Pautas/declarações |
| **school_transcript_subjects** | Disciplinas das pautas |

### Finanças
| Tabela | Função |
|---|---|
| **school_financial_config** | Configuração financeira |
| **school_fee_plans** | Planos de propinas |
| **school_fees** | Propinas a pagar |
| **school_fee_generations** | Geração de propinas |
| **school_student_fee_discounts** | Descontos de propina por aluno |
| **school_payments** | Pagamentos efectuados |

### Biblioteca e recursos
| Tabela | Função |
|---|---|
| **school_books** | Livros da biblioteca |
| **school_library_loans** | Empréstimos de livros |

### Comunicação e calendário
| Tabela | Função |
|---|---|
| **school_calendar_event_types** | Tipos de eventos do calendário escolar |
| **school_calendar_events** | Eventos do calendário escolar |
| **school_messages** | Mensagens enviadas no portal |
| **school_tasks** | Tarefas/actividades |

### Sessões dos portais
| Tabela | Função |
|---|---|
| **portal_sessions** | Sessões do portal do aluno |
| **guardian_portal_sessions** | Sessões do portal do encarregado |

---

## 4. Arquitetura global do banco de dados

O banco de dados possui **28 schemas** e **304 tabelas** (após remoção de tabelas/schemas duplicados legado). A organização abaixo descreve a finalidade de cada schema e suas principais tabelas.

---

## 1. `auth` — Autenticação e autorização central
| Tabela | Função |
|---|---|
| `users` | Utilizadores do sistema (superadmin, funcionário, aluno, encarregado) |
| `memberships` | Ligação utilizador ↔ tenant/empresa |
| `cargos` | Cargos/funções dos utilizadores |
| `permissoes_cargo` | Permissões associadas a cada cargo |
| `permissoes_diretas` | Permissões directas atribuídas a utilizadores |
| `permissoes_tipo` | Permissões por tipo de utilizador |
| `sessions` | Sessões activas no backend |
| `login_history` | Histórico de logins |
| `password_resets` | Tokens de recuperação de senha |
| `email_verifications` | Verificação de email |
| `api_keys` | Chaves de API |
| `superadmin_ip_allowlist` | IPs permitidos para superadmin |
| `superadmin_security_settings` | Configurações de segurança do superadmin |
| `schema_migrations` | Controlo de migrations do schema auth |
| `audit_logs` | Logs de auditoria do auth |

---

## 2. `autorizacao` — Perfis e papéis
| Tabela | Função |
|---|---|
| `roles` | Papéis/funções genéricas |
| `permissions` | Permissões do sistema |
| `role_permissions` | Permissões atribuídas a papéis |
| `user_roles` | Papéis atribuídos a utilizadores |

---

## 3. `saas` — Multi-tenant e subscrições
| Tabela | Função |
|---|---|
| `tenants` | Empresas/instituições (tenants) |
| `plans` | Planos de subscrição |
| `plan_modules` | Módulos incluídos em cada plano |
| `feature_catalog` | Catálogo de funcionalidades |
| `module_catalog` | Catálogo de módulos |
| `module_dependencies` | Dependências entre módulos |
| `tenant_modules` | Módulos activos por tenant |
| `tenant_subscriptions` | Subscrições dos tenants |
| `tenant_feature_flags` | Funcionalidades ligadas/desligadas por tenant |
| `approval_flows` | Fluxos de aprovação |
| `approval_requests` | Pedidos de aprovação |
| `approval_decisions` | Decisões de aprovação |
| `global_settings` | Configurações globais do sistema |

---

## 4. `empresas` — Dados da empresa
Schema oficial para dados da empresa/instituição. O schema legado `empresa` foi removido após migração.

| Tabela | Função |
|---|---|
| `companies` | Empresas registadas |
| `company_branches` | Sucursais |
| `company_addresses` | Endereços |
| `company_banks` | Contas bancárias |
| `company_contacts` | Contactos |
| `company_documents` | Documentos |
| `company_licenses` | Licenças |
| `company_settings` | Configurações |
| `company_tax_info` | Informação fiscal |
| `company_users` | Utilizadores associados à empresa |

---

## 5. `utilizadores` — Perfil e actividade dos utilizadores
| Tabela | Função |
|---|---|
| `profiles` | Perfis dos utilizadores |
| `user_preferences` | Preferências |
| `user_settings` | Configurações pessoais |
| `user_devices` | Dispositivos registados |
| `user_activity` | Actividade |
| `user_security_logs` | Logs de segurança |
| `user_notifications` | Notificações pessoais |
| `user_tokens` | Tokens pessoais |
| `user_avatar` | Avatares |

---

## 6. `clientes` — Gestão de clientes
| Tabela | Função |
|---|---|
| `customers` | Clientes |
| `customer_addresses` | Endereços |
| `customer_contacts` | Contactos |
| `customer_documents` | Documentos |
| `customer_groups` | Grupos de clientes |
| `customer_tags` / `customer_tag_links` | Etiquetas |
| `customer_discounts` | Descontos |
| `customer_credit_limits` | Limites de crédito |
| `customer_balances` | Saldos |
| `customer_payments` | Pagamentos de clientes |
| `customer_history` | Histórico |
| `customer_notes` | Notas |

---

## 7. `produtos` — Catálogo de produtos
| Tabela | Função |
|---|---|
| `products` | Produtos |
| `product_categories` / `product_subcategories` | Categorias |
| `product_brands` | Marcas |
| `product_units` | Unidades de medida |
| `product_attributes` / `product_attribute_values` | Atributos |
| `product_variants` | Variantess |
| `product_barcodes` | Códigos de barras |
| `product_prices` | Preços |
| `product_discounts` | Descontos |
| `product_kits` / `product_kit_items` | Kits de produtos |
| `product_tags` / `product_tag_links` | Etiquetas |
| `product_images` | Imagens |
| `warehouses` | Armazéns |

---

## 8. `stock` — Gestão de stock
| Tabela | Função |
|---|---|
| `stock_items` | Itens em stock |
| `stock_movements` | Movimentos de stock |
| `stock_adjustments` | Ajustes |
| `stock_counts` / `stock_count_items` | Inventários |
| `stock_transfers` / `stock_transfer_items` | Transferências entre armazéns |
| `stock_batches` | Lotes |
| `stock_serial_numbers` | Números de série |
| `stock_reservations` | Reservas |
| `stock_alerts` | Alertas de stock |
| `stock_logs` | Logs de stock |
| `warehouse_locations` | Localizações no armazém |

---

## 9. `compras` — Compras e fornecedores
| Tabela | Função |
|---|---|
| `suppliers` | Fornecedores |
| `supplier_addresses` / `supplier_contacts` / `supplier_groups` | Dados dos fornecedores |
| `purchase_requests` / `purchase_request_items` | Pedidos de compra internos |
| `purchase_orders` / `purchase_order_items` | Ordens de compra |
| `goods_receipts` / `goods_receipt_items` | Recepção de mercadorias |
| `purchase_invoices` / `purchase_invoice_items` | Facturas de compra |
| `purchase_payments` / `purchase_payment_items` | Pagamentos a fornecedores |
| `purchase_returns` / `purchase_return_items` | Devoluções |

---

## 10. `faturacao` — Vendas e facturação
| Tabela | Função |
|---|---|
| `sales_quotes` / `sales_quote_items` | Orçamentos |
| `sales_orders` / `sales_order_items` | Ordens de venda |
| `sales_deliveries` / `sales_delivery_items` | Guias de remessa |
| `invoices` / `invoice_items` | Facturas |
| `invoice_taxes` | Impostos das facturas |
| `invoice_discounts` | Descontos |
| `invoice_series` | Séries de facturação |
| `invoice_receipts` | Recibos |
| `credit_notes` / `credit_note_items` | Notas de crédito |
| `sales_returns` / `sales_return_items` | Devoluções de vendas |

---

## 11. `financeiro` — Contas a pagar/receber
| Tabela | Função |
|---|---|
| `accounts_receivable` | Contas a receber |
| `accounts_receivable_payments` | Pagamentos recebidos |
| `accounts_payable` | Contas a pagar |
| `accounts_payable_payments` | Pagamentos efectuados |
| `payments` | Pagamentos gerais |
| `payment_methods` | Métodos de pagamento |
| `financial_categories` | Categorias financeiras |
| `financial_budgets` | Orçamentos |
| `cash_flow_entries` | Fluxo de caixa |

---

## 12. `contabilidade` — Contabilidade geral
| Tabela | Função |
|---|---|
| `chart_of_accounts` | Plano de contas |
| `account_types` | Tipos de conta |
| `journal_entries` / `journal_entry_lines` | Lançamentos contábeis |
| `journal_entry_sequences` | Sequências de lançamentos |
| `accounting_journals` | Diários contábeis |
| `fiscal_years` / `fiscal_periods` | Anos/períodos fiscais |
| `fixed_assets` | Activos fixos |
| `depreciation_entries` | Depreciações |
| `accounting_budgets` | Orçamentos contábeis |
| `accounting_reports` | Relatórios |
| `period_closings` / `period_closing_checks` | Fechos de período |

---

## 13. `impostos` — Gestão fiscal
| Tabela | Função |
|---|---|
| `taxes` | Impostos |
| `tax_groups` | Grupos de impostos |
| `tax_rules` | Regras de impostos |
| `tax_regimes` | Regimes fiscais |
| `tax_exemptions` | Isenções |
| `tax_transactions` | Transacções fiscais |
| `withholding_taxes` / `withholding_tax_transactions` | Retenções na fonte |
| `tax_returns` / `tax_return_lines` | Declarações fiscais |
| `tax_certificates` | Certificados fiscais |

---

## 14. `tesouraria` — Caixa e bancos
Schema padronizado em inglês. As tabelas legado em português foram removidas.

| Tabela | Função |
|---|---|
| `cash_registers` | Caixas |
| `bank_accounts` | Contas bancárias |
| `movements` | Movimentos financeiros |
| `reconciliations` | Reconciliações bancárias |

---

## 15. `multi_moeda` — Moedas e câmbios
| Tabela | Função |
|---|---|
| `currencies` | Moedas |
| `exchange_rates` | Taxas de câmbio |
| `tenant_currencies` | Moedas activas por tenant |

---

## 16. `centros_custo` — Centros de custo
| Tabela | Função |
|---|---|
| `cost_centers` | Centros de custo |
| `cost_center_budgets` | Orçamentos |
| `cost_center_allocations` | Alocações |

---

## 17. `rh` — Recursos Humanos
| Tabela | Função |
|---|---|
| `funcionarios` | Funcionários |
| `cargos` | Cargos |
| `contratos` | Contratos |
| `contactos_emergencia` | Contactos de emergência |
| `documentos_funcionario` | Documentos |
| `beneficios` / `funcionario_beneficios` | Benefícios |
| `componentes_salariais` / `funcionario_componentes_salariais` | Componentes do salário |
| `formacoes` / `funcionario_formacoes` | Formações |
| `horarios_trabalho` | Horários |
| `presencas` / `ausencias` / `justificacoes` | Presenças/faltas |
| `tipos_ausencia` / `saldos_ausencia` | Tipos e saldos de ausência |
| `adiantamentos` | Adiantamentos |
| `emprestimos` | Empréstimos ao funcionário |
| `folhas_pagamento` / `recibos_vencimento` / `recibo_vencimento_itens` | Processamento salarial |
| `historico_salarial` | Histórico salarial |
| `avaliacoes` / `avaliacao_criterios` / `criterios_avaliacao` / `periodos_avaliacao` | Avaliações de desempenho |
| `processos_disciplinares` | Processos disciplinares |
| `unidades_organizacionais` | Unidades orgânicas |
| `irps_escaloes` | Escalões de IRPS |
| `config_contabilidade_folha` | Configuração contábil da folha |

---

## 18. `crm` — Gestão de relacionamento com clientes
Tabelas ativas em português. As tabelas legado com prefixo `crm_` foram removidas.

| Tabela | Função |
|---|---|
| `leads` | Potenciais clientes |
| `oportunidades` | Oportunidades de negócio |
| `atividades` | Actividades comerciais |

---

## 19. `pos` — Ponto de venda
| Tabela | Função |
|---|---|
| `pos_terminals` | Terminais POS |
| `pos_sessions` | Sessões de caixa |
| `pos_sales` / `pos_sale_items` | Vendas POS |
| `pos_sale_payments` | Pagamentos das vendas |
| `pos_catalog_items` | Itens do catálogo POS |

---

## 20. `logistica` — Logística e entregas
Schema reescrito com prefixo `logistics_`. As tabelas legado `delivery_*` e `shipments` foram removidas, e o handler `internal/modules/logistica/handlers/logistica.go` foi adaptado para o novo modelo.

| Tabela | Função |
|---|---|
| `logistics_vehicles` | Viaturas |
| `logistics_drivers` | Motoristas |
| `logistics_routes` | Rotas |
| `logistics_shipments` | Envios |
| `logistics_tracking_events` | Rastreamento |

**Nota sobre a API:** os endpoints `/api/delivery-status` e `/api/shipment-items` foram removidos por não terem equivalente no novo schema. O campo `status` de envio passou a ser texto (`planeada`, `em_transito`, `entregue`, `cancelada`).

---

## 21. `assinaturas` — Subscrições de serviços
| Tabela | Função |
|---|---|
| `subscriptions` | Subscrições |
| `subscription_plans` | Planos |
| `subscription_invoices` | Facturas de subscrição |
| `subscription_usage` | Consumo/utilização |

---

## 22. `auditoria` — Auditoria
| Tabela | Função |
|---|---|
| `audit_events` | Eventos de auditoria |
| `audit_logs` | Logs de auditoria |

---

## 23. `notificacoes` — Notificações do sistema
| Tabela | Função |
|---|---|
| `notification_templates` | Templates |
| `notification_messages` | Mensagens enviadas |
| `notification_channels` | Canais (email, SMS, push) |

---

## 24. `public` — Dados partilhados/legacy
| Tabela | Função |
|---|---|
| `schema_migrations` | Controlo de migrations (Go migrate) |
| `comunicados` / `comunicados_lidos` | Comunicados internos |
| `chat_conversas` / `chat_mensagens` / `chat_participantes` | Chat interno |
| `notif_colaborador` | Notificações a colaboradores |

---

## 25. `recrutamento` — Recrutamento
| Tabela | Função |
|---|---|
| `vagas` | Ofertas de emprego |
| `vaga_campos` | Campos personalizados das vagas |
| `candidaturas` | Candidaturas |
| `candidatura_respostas_vaga` | Respostas aos campos |
| `candidatura_campos_custom` / `candidatura_valores_custom` | Campos customizados |
| `candidatura_notas` | Notas das candidaturas |
| `candidatos` | Candidatos |
| `contactos` | Contactos |
| `config_notificacoes` | Configurações de notificação |

---

## 26. `seguranca` — Segurança
| Tabela | Função |
|---|---|
| `security_policies` | Políticas de segurança |
| `security_ip_allowlist` | IPs permitidos |
| `security_mfa_enrollments` | Autenticação multi-factor |

---

## 27. `sistema_configuracao` — Configurações do sistema
| Tabela | Função |
|---|---|
| `settings` | Configurações gerais |
| `currencies` / `exchange_rates` / `languages` / `countries` / `cities` | Tabelas auxiliares |
| `email_templates` / `sms_templates` | Templates |
| `integrations` / `tenant_integrations` | Integrações |
| `tenant_branding` / `tenant_defaults` / `tenant_document_settings` / `tenant_feature_flags` | Configurações por tenant |
| `api_logs` / `system_logs` | Logs |

---

## 28. `gestao_escolar` — Módulo escolar
Já foi detalhado anteriormente — inclui alunos, professores, turmas, notas, presenças, propinas, biblioteca, calendário, etc.

---

## Observação importante
A limpeza de duplicados legado foi realizada. Foram removidos:
- Schema `empresa` (substituído por `empresas`)
- Tabelas `crm.crm_*` (reescrita não adotada; mantidas `crm.leads`, `crm.oportunidades`, `crm.atividades`)
- Tabelas `logistica.delivery_*`, `logistica.shipments`, `logistica.shipment_items` (substituídas por `logistica.logistics_*`)
- Tabelas `tesouraria.caixas`, `tesouraria.contas_bancarias`, `tesouraria.movimentos_financeiros`, `tesouraria.reconciliacoes_bancarias` (substituídas pelas equivalentes em inglês)
- `public.schema_migrations_legacy` (controlo de migrations SQL custom)

Os backups estão em `backend/scripts/backups/`.

### 5.4 Correções aplicadas no backend

Foram corrigidas as referências a tabelas legado nos seguintes ficheiros:

| Ficheiro | Correção |
|---|---|
| `backend/internal/shared/adapters/treasury.go` | `tesouraria.movimentos_financeiros` → `tesouraria.movements` |
| `backend/internal/modules/gestao-escolar/repositories/fee.go` | `tesouraria.movimentos_financeiros` → `tesouraria.movements` |
| `backend/internal/modules/logistica/handlers/logistica.go` | Reescrito para usar `logistica.logistics_*` |
| `backend/internal/router/router.go` | Removidos endpoints de status e itens de envio obsoletos |
| `backend/migrations/20260629000044_logistica_tesouraria.up.sql` | Cria apenas tabelas `logistics_*` e `tesouraria.*` em inglês |
| `backend/migrations/20260629000067_*.up.sql` | Removida manutenção da tabela legado `movimentos_financeiros` |
| `backend/migrations/20260629000075_*.up.sql` | Removida criação da tabela legado `movimentos_financeiros` |
| `backend/correcoes_aplicadas.md` | Removido `empresa` do `search_path` |

Queres que eu analise em detalhe algum schema específico ou preencha dados de teste noutro módulo?

---

## 5. Pontos de atenção técnica

### 5.1 Duplicidades identificadas

| Área | Duplicidade observada | Estado |
|---|---|---|
| Empresa | `empresa` vs `empresas` | ✅ Resolvido — schema `empresa` removido; backend usa `empresas` |
| CRM | `atividades` vs `crm_activities` | ✅ Resolvido — tabelas `crm_*` removidas; backend usa `crm.leads/oportunidades/atividades` |
| Logística | `delivery_*` vs `logistics_*` | ✅ Resolvido — tabelas `delivery_*`/`shipments` removidas; handler reescrito para `logistics_*` |
| Tesouraria | `cash_registers` vs `caixas`; `bank_accounts` vs `contas_bancarias` | ✅ Resolvido — tabelas em português removidas; backend usa `tesouraria.movements` |
| Migrations | `schema_migrations` vs `schema_migrations_legacy` | ✅ Resolvido — `schema_migrations_legacy` removida |

### 5.2 Recomendações de padronização

| Recomendação | Ação sugerida |
|---|---|
| Padronizar idioma dos nomes técnicos | Escolher português ou inglês para tabelas e colunas novas |
| Separar legado de produção | Manter schemas/tabelas antigas com prefixo ou documentação de migração |
| Criar dicionário de dados oficial | Documentar tipo, chave primária, chave estrangeira e regra de negócio |
| Criar mapa ERD por domínio | Um diagrama por schema crítico: `auth`, `saas`, `gestao_escolar`, `financeiro`, `rh` |
| Rever segurança de acessos | Eliminar senha única, ativar expiração e registrar auditoria de login |

### 5.3 Próximo nível da documentação

Para transformar esta documentação em material de engenharia completo, faltam três camadas:

| Camada | Conteúdo necessário |
|---|---|
| Dicionário de dados | Colunas, tipos, constraints, chaves e índices |
| Regras de negócio | Como cada tabela é usada no fluxo real do sistema |
| Diagramas técnicos | ERD, fluxo de autenticação, fluxo de matrícula, fluxo financeiro e permissões |

