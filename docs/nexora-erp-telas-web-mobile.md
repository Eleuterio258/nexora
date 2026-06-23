# Nexora ERP - Telas Web e Mobile

Documento consolidado das telas previstas para o Nexora ERP, organizado por modulo, com foco em uso Web e Mobile.

## Status dos Modulos

Modulos uteis concluidos: 23

Modulo descontinuado:

- `seguranca`

Motivo: o modulo `seguranca` foi substituido por:

- `autenticacao`
- `autorizacao`
- `auditoria`

Portanto, nao devem ser criadas telas novas para `seguranca`.

## Padrao Geral de Interface

### Web

- Sidebar com navegacao por modulos.
- Topbar com empresa ativa, pesquisa global, notificacoes e perfil do utilizador.
- Tabelas com filtros, ordenacao, pesquisa e acoes por linha.
- Dashboards com cards, graficos e listas de pendencias.
- Formularios em pagina dedicada, drawer lateral ou modal, conforme complexidade.
- Exportacao PDF, XLSX ou CSV onde aplicavel.
- Estados obrigatorios: vazio, carregando, erro, sem permissao, sucesso.

### Mobile

- Navegacao inferior ou menu lateral.
- Listas em cards.
- Filtros em bottom sheet.
- Formularios em etapas para fluxos longos.
- Acoes principais fixas no rodape quando necessario.
- Acoes rapidas por card.
- Estados obrigatorios: vazio, carregando, erro, sem permissao, sucesso.

## Ordem Recomendada de Implementacao

1. `empresas`
2. `autenticacao`
3. `autorizacao`
4. `utilizadores`
5. `auditoria`
6. `sistema-configuracao`
7. `gestao-clientes`
8. `gestao-produtos`
9. `gestao-stock`
10. `modulo-faturacao`
11. `tesouraria`
12. `financeiro`
13. `contabilidade`
14. `impostos`
15. `multi-moeda`
16. `compras`
17. `pos`
18. `logistica`
19. `crm`
20. `recursos-humanos`
21. `assinaturas`
22. `gestao-escolar`
23. `centros-custo`

---

# 1. Autenticacao

Objetivo: permitir acesso seguro ao Nexora ERP, gestao de sessao, recuperacao de senha, bloqueio de conta e autenticacao por API Key.

## Telas

1. Login
2. Selecao de Empresa
3. Recuperacao de Senha
4. Redefinicao de Senha
5. Primeiro Acesso
6. Sessao Expirada
7. Verificacao de Codigo
8. Gestao de Sessoes Ativas
9. Historico de Login
10. Chaves de API
11. Conta Bloqueada
12. Logout

## Regras Principais

- Login deve criar sessao ativa.
- Tentativas devem ser registadas em `login_history`.
- Recuperacao de senha usa token expiravel.
- API Keys devem mostrar segredo apenas uma vez.
- Conta bloqueada ou inativa nao pode autenticar.

## Permissoes Principais

- Publico: login, recuperacao, redefinicao e primeiro acesso.
- Autenticado: sessoes, logout e historico proprio.
- Administrador: historico da empresa e API keys.

---

# 2. Autorizacao

Objetivo: gerir RBAC, roles, permissoes e atribuicao de perfis a utilizadores.

## Telas

1. Perfis/Roles
2. Criar/Editar Perfil
3. Matriz de Permissoes
4. Permissoes do Sistema
5. Atribuicao de Perfil ao Utilizador
6. Permissoes Efetivas do Utilizador
7. Comparacao de Perfis
8. Logs de Alteracoes de Permissoes
9. Templates de Perfis
10. Acesso Negado

## Regras Principais

- Perfis pertencem ao tenant.
- Perfis de sistema nao devem ser eliminados.
- Permissoes seguem o padrao `modulo.recurso.acao`.
- Alteracoes de permissao devem ser auditadas.
- Nao permitir deixar a empresa sem administrador.

## Permissoes Principais

- `roles.view`
- `roles.create`
- `roles.update`
- `permissions.view`
- `permissions.assign`
- `user_roles.assign`
- `authorization.audit.view`

---

# 3. Utilizadores

Objetivo: gerir utilizadores, dados administrativos, estado da conta, perfis, sessoes e historico.

## Telas

1. Lista de Utilizadores
2. Criar Utilizador
3. Editar Utilizador
4. Detalhes do Utilizador
5. Perfis do Utilizador
6. Convites Pendentes
7. Reset de Senha do Utilizador
8. Bloqueio/Desbloqueio de Utilizador
9. Preferencias do Meu Perfil
10. Alterar Minha Senha
11. Importacao de Utilizadores
12. Auditoria do Utilizador

## Regras Principais

- Email deve ser unico.
- Convites usam token com expiracao.
- Bloqueio impede novo login.
- Reset de senha nao deve expor senha ao administrador.
- Alteracoes de perfis e estado devem ser auditadas.

## Permissoes Principais

- `users.view`
- `users.create`
- `users.update`
- `users.block`
- `users.deactivate`
- `users.password.reset`
- `users.import`

---

# 4. Empresas

Objetivo: gerir empresas/tenants, dados legais, filiais, licenciamento, preferencias e estado operacional.

## Telas

1. Lista de Empresas
2. Criar Empresa
3. Editar Empresa
4. Detalhes da Empresa
5. Filiais/Unidades
6. Criar/Editar Filial
7. Configuracoes da Empresa
8. Dados Fiscais da Empresa
9. Logotipo e Identidade Visual
10. Plano/Licenca da Empresa
11. Suspensao/Reativacao da Empresa
12. Auditoria da Empresa

## Regras Principais

- Toda empresa deve ter `tenant_id`.
- NUIT deve ser unico quando aplicavel.
- Empresa suspensa bloqueia operacao.
- Toda empresa deve ter pelo menos uma unidade principal.
- Alteracoes fiscais devem ser auditadas.

## Permissoes Principais

- `companies.view`
- `companies.create`
- `companies.update`
- `companies.suspend`
- `branches.manage`
- `company_settings.update`

---

# 5. Auditoria

Objetivo: garantir rastreabilidade de acoes, acessos criticos, alteracoes e operacoes sensiveis.

## Telas

1. Dashboard de Auditoria
2. Lista de Eventos de Auditoria
3. Detalhe do Evento de Auditoria
4. Eventos Criticos
5. Historico por Entidade
6. Historico por Utilizador
7. Exportacao de Logs
8. Configuracoes de Auditoria
9. Alertas de Auditoria
10. Tentativas Bloqueadas
11. Retencao e Integridade dos Logs

## Regras Principais

- Logs nao podem ser editados ou apagados.
- Exportacao de logs deve ser auditada.
- Dados sensiveis devem ser mascarados.
- Eventos criticos exigem permissao especifica.
- Logs devem respeitar isolamento por tenant.

## Permissoes Principais

- `audit.dashboard.view`
- `audit_logs.view`
- `audit_logs.export`
- `audit_critical.view`
- `audit_settings.update`

---

# 6. Sistema e Configuracao

Objetivo: gerir configuracoes globais, moedas, localizacao, notificacoes, templates, integracoes, logs tecnicos e numeracao.

## Telas

1. Configuracoes Gerais
2. Paises, Provincias e Cidades
3. Moedas
4. Taxas de Cambio
5. Idiomas
6. Templates de Email
7. Templates de SMS
8. Notificacoes
9. Integracoes
10. Webhooks
11. Logs do Sistema
12. Logs de API
13. Numeracao Global
14. Backup e Manutencao

## Regras Principais

- Configuracoes sao isoladas por tenant.
- Moeda padrao nao deve ser desativada.
- Segredos de integracao devem ser mascarados.
- Webhooks em producao devem usar HTTPS.
- Sequencias documentais nao devem regredir.

## Permissoes Principais

- `settings.view`
- `settings.update`
- `locations.manage`
- `currencies.manage`
- `integrations.configure`
- `system_logs.view`
- `numbering.update`

---

# 7. Gestao de Clientes

Objetivo: gerir cadastro completo de clientes, contactos, enderecos, documentos, credito, saldos e historico.

## Telas

1. Lista de Clientes
2. Criar Cliente
3. Editar Cliente
4. Detalhes do Cliente
5. Grupos de Clientes
6. Contactos do Cliente
7. Enderecos do Cliente
8. Documentos Anexos do Cliente
9. Limite de Credito
10. Conta Corrente do Cliente
11. Pagamentos do Cliente
12. Historico Comercial
13. Notas Internas do Cliente
14. Etiquetas de Clientes
15. Descontos por Cliente

## Regras Principais

- Cliente pertence ao tenant ativo.
- NUIT deve ser unico por tenant quando preenchido.
- Cliente com documentos nao deve ser apagado.
- Bloqueio de credito impede vendas a credito.
- Conta corrente vem de faturacao e financeiro.

## Permissoes Principais

- `customers.view`
- `customers.create`
- `customers.update`
- `customers.credit.update`
- `customers.statement.view`
- `customer_documents.upload`

---

# 8. Gestao de Produtos

Objetivo: gerir produtos, servicos, categorias, precos, unidades, variantes, codigos de barras, imagens, descontos e kits.

## Telas

1. Lista de Produtos
2. Criar Produto
3. Editar Produto
4. Detalhes do Produto
5. Categorias de Produtos
6. Marcas
7. Unidades de Medida
8. Precos do Produto
9. Descontos de Produto
10. Codigos de Barras
11. Imagens do Produto
12. Atributos e Variantes
13. Kits de Produtos
14. Etiquetas de Produto
15. Importacao de Produtos
16. Historico do Produto

## Regras Principais

- SKU deve ser unico por tenant.
- Produto com movimentos nao deve ser apagado.
- Servico nao controla stock.
- Alteracoes de preco devem manter historico.
- Produto com variantes exige SKU unico por variante.

## Permissoes Principais

- `products.view`
- `products.create`
- `products.update`
- `product_prices.manage`
- `product_barcodes.manage`
- `products.import`

---

# 9. Gestao de Stock

Objetivo: controlar armazens, localizacoes, saldos, movimentos, entradas, saidas, ajustes, transferencias, reservas, lotes, series, contagens e alertas.

## Telas

1. Dashboard de Stock
2. Armazens
3. Localizacoes do Armazem
4. Saldos de Stock
5. Movimentos de Stock
6. Entrada de Stock
7. Saida de Stock
8. Ajuste de Stock
9. Transferencia de Stock
10. Reservas de Stock
11. Lotes
12. Numeros de Serie
13. Contagem de Inventario
14. Alertas de Stock
15. Configuracoes de Stock

## Regras Principais

- Movimentos nao devem ser editados diretamente.
- Produtos sem controlo de stock nao entram nos saldos.
- Ajuste exige motivo.
- Transferencia nao pode ter origem igual ao destino.
- Reserva reduz disponibilidade.

## Permissoes Principais

- `stock.dashboard.view`
- `warehouses.manage`
- `stock_balances.view`
- `stock_movements.view`
- `stock_adjustments.create`
- `stock_transfers.create`

---

# 10. Faturacao

Objetivo: gerir orcamentos, encomendas, guias, faturas, recibos, notas de credito, devolucoes, series e integracoes.

## Telas

1. Dashboard de Faturacao
2. Series Documentais
3. Orcamentos
4. Criar/Editar Orcamento
5. Encomendas de Venda
6. Guias de Remessa
7. Faturas
8. Criar/Editar Fatura
9. Detalhes da Fatura
10. Recibos
11. Criar Recibo
12. Notas de Credito
13. Devolucoes
14. Documentos Vencidos
15. Relatorios de Faturacao

## Regras Principais

- Fatura emitida cria conta a receber.
- Fatura emitida pode gerar lancamento contabilistico.
- Documento emitido nao deve ser editado diretamente.
- Recibo movimenta financeiro e tesouraria.
- Nota de credito deve referenciar fatura emitida.

## Permissoes Principais

- `billing.dashboard.view`
- `invoice_series.manage`
- `sales_quotes.create`
- `invoices.create`
- `invoices.issue`
- `invoice_receipts.create`
- `credit_notes.issue`

---

# 11. Tesouraria

Objetivo: controlar caixa, bancos, movimentos liquidos, saldos, reconciliacao, transferencias, fechos e extratos.

## Telas

1. Dashboard de Tesouraria
2. Caixas
3. Contas Bancarias
4. Movimentos de Tesouraria
5. Nova Entrada de Tesouraria
6. Nova Saida de Tesouraria
7. Transferencia Interna
8. Reconciliacao Bancaria
9. Extrato de Caixa
10. Extrato Bancario Interno
11. Fecho de Caixa
12. Categorias de Tesouraria
13. Relatorios de Tesouraria

## Regras Principais

- Movimento confirmado altera saldo.
- Caixa fechado nao recebe movimentos.
- Transferencia gera saida na origem e entrada no destino.
- Reconciliacao deve preservar divergencias.
- Fecho com diferenca exige observacao.

## Permissoes Principais

- `treasury.dashboard.view`
- `cash_registers.manage`
- `bank_accounts.manage`
- `treasury_entries.create`
- `treasury_exits.create`
- `bank_reconciliation.match`

---

# 12. Financeiro

Objetivo: gerir contas a receber, contas a pagar, pagamentos, recebimentos, fluxo de caixa, categorias, orcamentos e relatorios.

## Telas

1. Dashboard Financeiro
2. Contas a Receber
3. Detalhe da Conta a Receber
4. Registar Recebimento
5. Contas a Pagar
6. Criar Conta a Pagar
7. Registar Pagamento
8. Pagamentos e Recebimentos
9. Metodos de Pagamento
10. Categorias Financeiras
11. Fluxo de Caixa
12. Orcamentos Financeiros
13. Aging de Clientes
14. Relatorios Financeiros

## Regras Principais

- Fatura cria conta a receber.
- Compra pode criar conta a pagar.
- Pagamento/recebimento movimenta tesouraria.
- Anulacao gera movimento inverso.
- Fluxo separa previsto de realizado.

## Permissoes Principais

- `financial.dashboard.view`
- `accounts_receivable.view`
- `receivables_payments.create`
- `accounts_payable.view`
- `payables_payments.create`
- `financial_reports.export`

---

# 13. Contabilidade

Objetivo: gerir dupla entrada, plano de contas, periodos fiscais, lancamentos, impostos contabilisticos, ativos fixos, demonstracoes e encerramento.

## Telas

1. Dashboard Contabilistico
2. Plano de Contas
3. Tipos de Conta
4. Anos Fiscais
5. Periodos Fiscais
6. Lancamentos Contabilisticos
7. Criar Lancamento Manual
8. Detalhe do Lancamento
9. Razao Geral
10. Balancete
11. Demonstracao de Resultados
12. Balanco Patrimonial
13. Impostos Contabilisticos
14. Ativos Fixos
15. Plano de Amortizacao
16. Encerramento de Periodo
17. Orcamento Contabilistico
18. Relatorios Contabilisticos

## Regras Principais

- Debito e credito devem fechar.
- Periodo encerrado nao aceita lancamento normal.
- Conta sintetica nao aceita lancamento.
- Estorno gera lancamento inverso.
- Encerramento exige checklist sem pendencias criticas.

## Permissoes Principais

- `accounting.dashboard.view`
- `chart_accounts.manage`
- `journal_entries.create`
- `journal_entries.approve`
- `journal_entries.reverse`
- `period_closing.close`

---

# 14. Impostos

Objetivo: gerir regimes fiscais, isencoes, retencoes, declaracoes, certificados e calendario fiscal.

## Telas

1. Dashboard Fiscal
2. Regimes Fiscais
3. Isencoes Fiscais
4. Retencoes na Fonte
5. Transacoes de Retencao
6. Declaracoes Fiscais
7. Criar Declaracao Fiscal
8. Linhas da Declaracao
9. Certificados Fiscais
10. Calendario Fiscal
11. Relatorios Fiscais

## Regras Principais

- Apenas um regime fiscal padrao ativo por empresa.
- Isencao vencida nao deve ser aplicada.
- Retencao nao deve ser lancada duas vezes.
- Declaracao submetida bloqueia edicao direta.
- Exportacoes fiscais devem ser auditadas.

## Permissoes Principais

- `tax_dashboard.view`
- `tax_regimes.manage`
- `tax_exemptions.create`
- `withholding_taxes.manage`
- `tax_returns.submit`
- `tax_reports.export`

---

# 15. Multi-Moeda

Objetivo: permitir operacoes em varias moedas, gerir cambio, conversoes, ganhos/perdas e reavaliacoes.

## Telas

1. Dashboard Multi-Moeda
2. Moedas Ativas
3. Taxas de Cambio
4. Conversao de Moeda
5. Documento em Moeda Estrangeira
6. Ganhos e Perdas Cambiais
7. Reavaliacao Cambial
8. Historico de Taxas
9. Configuracoes Multi-Moeda
10. Relatorios Multi-Moeda

## Regras Principais

- Documento em moeda estrangeira deve guardar taxa usada.
- Moeda padrao nao deve ser desativada.
- Diferenca cambial surge na liquidacao.
- Reavaliacao exige taxa de fecho.
- Ganhos/perdas integram contabilidade.

## Permissoes Principais

- `multi_currency.dashboard.view`
- `multi_currency.currencies.manage`
- `exchange_rates.manage`
- `currency_gain_loss.post`
- `currency_revaluation.post`

---

# 16. Compras

Objetivo: gerir fornecedores, requisicoes, pedidos, rececao, faturas, devolucoes, pagamentos e integracoes.

## Telas

1. Dashboard de Compras
2. Fornecedores
3. Criar/Editar Fornecedor
4. Detalhes do Fornecedor
5. Requisicoes de Compra
6. Pedido de Compra
7. Criar/Editar Pedido de Compra
8. Rececao de Mercadorias
9. Faturas de Fornecedor
10. Devolucoes a Fornecedor
11. Pagamentos a Fornecedor
12. Produtos por Fornecedor
13. Avaliacao de Fornecedores
14. Relatorios de Compras

## Regras Principais

- Fornecedor com documentos nao deve ser apagado.
- Requisicao aprovada pode gerar pedido.
- Rececao atualiza stock.
- Fatura validada cria conta a pagar.
- Devolucao reduz stock e pode gerar credito de fornecedor.

## Permissoes Principais

- `purchases.dashboard.view`
- `suppliers.manage`
- `purchase_requests.approve`
- `purchase_orders.create`
- `purchase_receipts.create`
- `purchase_invoices.validate`

---

# 17. POS

Objetivo: gerir vendas rapidas, terminais, sessoes, pagamentos, devolucoes, fecho de caixa e recibos.

## Telas

1. Selecao de Terminal POS
2. Abertura de Sessao POS
3. Tela Principal de Venda POS
4. Selecao de Cliente no POS
5. Pagamento POS
6. Venda Finalizada
7. Vendas POS
8. Detalhe da Venda POS
9. Devolucao POS
10. Movimentos de Caixa POS
11. Fecho de Sessao POS
12. Sessoes POS
13. Configuracao de Terminais POS
14. Relatorios POS

## Regras Principais

- Terminal precisa de caixa e armazem.
- Sessao aberta habilita vendas.
- Venda concluida baixa stock e movimenta tesouraria.
- Devolucao nao pode exceder quantidade vendida.
- Fecho com diferenca exige observacao.

## Permissoes Principais

- `pos_terminals.view`
- `pos_sessions.open`
- `pos_sales.create`
- `pos_payments.create`
- `pos_returns.create`
- `pos_sessions.close`

---

# 18. Logistica

Objetivo: gerir expedicoes, rotas, entregas, motoristas, viaturas, rastreamento, ocorrencias e prova de entrega.

## Telas

1. Dashboard de Logistica
2. Expedicoes
3. Criar/Editar Expedicao
4. Detalhe da Expedicao
5. Rotas de Entrega
6. Tela Mobile do Motorista
7. Motoristas
8. Viaturas
9. Rastreamento de Entregas
10. Estados de Entrega
11. Prova de Entrega
12. Ocorrencias de Entrega
13. Relatorios de Logistica

## Regras Principais

- Expedicao referencia documento origem.
- Motorista so ve entregas atribuidas.
- Entrega finalizada exige prova conforme configuracao.
- Viatura em manutencao nao pode ser atribuida.
- Ocorrencia pode alterar estado da entrega.

## Permissoes Principais

- `logistics.dashboard.view`
- `shipments.create`
- `shipments.dispatch`
- `delivery_routes.manage`
- `driver_app.view`
- `delivery_proof.create`

---

# 19. CRM

Objetivo: gerir leads, oportunidades, pipeline, atividades, contactos, notas, previsao e relatorios comerciais.

## Telas

1. Dashboard CRM
2. Pipelines de Venda
3. Leads
4. Criar/Editar Lead
5. Detalhes do Lead
6. Oportunidades
7. Criar/Editar Oportunidade
8. Detalhe da Oportunidade
9. Atividades Comerciais
10. Contactos CRM
11. Notas CRM
12. Etiquetas CRM
13. Previsao de Receita
14. Relatorios CRM

## Regras Principais

- Lead convertido pode criar cliente.
- Oportunidade ganha pode gerar orcamento ou fatura.
- Oportunidade perdida exige motivo.
- Atividade vencida gera alerta.
- Visibilidade depende da permissao/equipa.

## Permissoes Principais

- `crm.dashboard.view`
- `crm_pipelines.manage`
- `crm_leads.convert`
- `crm_opportunities.close`
- `crm_activities.complete`
- `crm_reports.export`

---

# 20. Recursos Humanos

Objetivo: gerir estrutura organizacional, funcionarios, contratos, salarios, assiduidade, licencas, payroll, avaliacoes e formacao.

## Telas

1. Dashboard RH
2. Estrutura Organizacional
3. Cargos/Funcoes
4. Funcionarios
5. Criar/Editar Funcionario
6. Detalhe do Funcionario
7. Contratos
8. Salarios e Beneficios
9. Componentes Salariais
10. Assiduidade
11. Horas Extra
12. Ferias e Licencas
13. Processamento Salarial
14. Recibo de Vencimento
15. Avaliacoes de Desempenho
16. Formacao e Desenvolvimento
17. Processos Disciplinares
18. Relatorios RH

## Regras Principais

- Dados salariais exigem permissao especifica.
- Funcionario desligado mantem historico.
- Contrato ativo principal deve ser unico.
- Processamento salarial fechado nao deve ser editado.
- Processos disciplinares sao altamente sensiveis.

## Permissoes Principais

- `hr.dashboard.view`
- `employees.manage`
- `employee_contracts.manage`
- `employee_salaries.manage`
- `payroll_runs.approve`
- `hr_reports.export`

---

# 21. Assinaturas

Objetivo: gerir planos SaaS, licencas, ciclos recorrentes, pagamentos, limites, uso, suspensao e cancelamento.

## Telas

1. Dashboard de Assinaturas
2. Planos de Assinatura
3. Funcionalidades do Plano
4. Assinaturas
5. Criar/Editar Assinatura
6. Detalhe da Assinatura
7. Ciclos de Faturacao
8. Pagamentos de Assinatura
9. Gateways de Pagamento
10. Uso da Assinatura
11. Pausas de Assinatura
12. Cancelamentos
13. Eventos da Assinatura
14. Relatorios de Assinaturas

## Regras Principais

- Plano em uso nao deve ser apagado.
- Uma empresa nao deve ter assinaturas ativas conflitantes.
- Ciclo faturado gera documento em faturacao.
- Pagamento confirmado pode reativar assinatura suspensa.
- Limites do plano bloqueiam ou alertam uso.

## Permissoes Principais

- `subscriptions.dashboard.view`
- `subscription_plans.manage`
- `subscriptions.manage`
- `subscription_billing_cycles.generate`
- `subscription_payments.confirm`
- `subscription_reports.export`

---

# 22. Gestao Escolar

Objetivo: gerir administracao escolar, alunos, encarregados, professores, turmas, disciplinas, matriculas, notas, frequencia, propinas, biblioteca, comunicacao e portais.

## Telas

1. Dashboard Escolar
2. Anos Letivos
3. Periodos Letivos
4. Turmas
5. Alunos
6. Criar/Editar Aluno
7. Encarregados
8. Matriculas e Rematriculas
9. Professores
10. Disciplinas
11. Atribuicao Professor-Turma-Disciplina
12. Frequencia Escolar
13. Avaliacoes e Notas
14. Propinas e Cobrancas Escolares
15. Pagamento Escolar
16. Biblioteca
17. Comunicacao Escolar
18. Portal do Aluno
19. Portal do Professor
20. Portal do Encarregado
21. Relatorios Escolares

## Regras Principais

- Dados filtrados por ano letivo ativo.
- Aluno nao deve ter duas matriculas ativas no mesmo ano.
- Professor so lanca notas/frequencia nas turmas atribuidas.
- Notas publicadas aparecem nos portais.
- Pagamentos escolares integram financeiro e tesouraria.

## Permissoes Principais

- `school.dashboard.view`
- `school_years.manage`
- `students.manage`
- `enrollments.confirm`
- `grades.publish`
- `school_payments.create`
- `school_reports.export`

---

# 23. Centros de Custo

Objetivo: gerir centros de custo, rateios, alocacao de despesas/receitas, orcamentos, rentabilidade e integracao contabilistica.

## Telas

1. Dashboard de Centros de Custo
2. Lista de Centros de Custo
3. Criar/Editar Centro de Custo
4. Detalhe do Centro de Custo
5. Hierarquia de Centros de Custo
6. Lancamentos por Centro de Custo
7. Alocacao Manual
8. Regras de Rateio
9. Simulacao de Rateio
10. Orcamento por Centro de Custo
11. Despesas Sem Centro de Custo
12. Rentabilidade por Centro
13. Configuracoes de Centros de Custo
14. Relatorios de Centros de Custo

## Regras Principais

- Codigo deve ser unico por tenant.
- Centro com movimentos nao deve ser apagado.
- Rateio percentual deve somar 100%.
- Valor total alocado deve bater com valor do lancamento.
- Relatorios respeitam permissoes financeiras e contabilisticas.

## Permissoes Principais

- `cost_centers.dashboard.view`
- `cost_centers.manage`
- `cost_center_entries.view`
- `cost_center_allocations.create`
- `cost_allocation_rules.manage`
- `cost_center_reports.export`

---

# Modulo Descontinuado: Seguranca

O modulo `seguranca` nao deve ser implementado como modulo separado.

Ele foi substituido por:

- `autenticacao`: login, sessoes, API keys, recuperacao de senha.
- `autorizacao`: roles, permissoes e RBAC.
- `auditoria`: rastreabilidade, logs e eventos criticos.

## Decisao

Nao criar telas novas para `seguranca`.

## Status Final

- Modulos uteis: concluidos.
- Telas Web/Mobile: consolidadas.
- Falta util: nenhum modulo.
