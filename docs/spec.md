# Nexora ERP - Especificacao Tecnica Modular

**Versao:** 2.0.0  
**Data:** 2026-05-06  
**Status:** Consolidado por modulo  
**Fonte principal:** `D:\projecto\e-258tech\2026\factPro\nexora ERP`

---

## 1. Visao Geral

O **Nexora ERP** e um sistema de gestao empresarial modular, multi-empresa e multi-tenant, desenhado para operar com empresas comerciais, servicos, retalho/POS, escolas, operacoes financeiras e gestao interna.

O sistema deixa de ser especificado apenas como faturacao/POS e passa a ser tratado como um ERP completo, composto por modulos independentes mas integrados: empresas, autenticacao, autorizacao, utilizadores, auditoria, clientes, produtos, stock, faturacao, POS, compras, financeiro, tesouraria, contabilidade, impostos, multi-moeda, centros de custo, CRM, recursos humanos, logistica, assinaturas SaaS e gestao escolar.

### 1.1 Objetivos

- Centralizar processos empresariais num ERP modular.
- Garantir isolamento por `tenant_id` ou `company_id`.
- Permitir ativacao de modulos por plano, empresa ou setor.
- Integrar vendas, compras, stock, financeiro, tesouraria e contabilidade.
- Suportar realidade operacional de Mocambique, incluindo MZN, NUIT, M-Pesa, e-Mola, faturacao, recibos e impostos.
- Permitir evolucao de monolito modular para servicos separados sem alterar contratos de negocio.

### 1.2 Escopo Funcional

- Multi-empresa e multi-tenant.
- Autenticacao, RBAC, perfis, sessoes, API keys e auditoria.
- Cadastros base: empresas, filiais, clientes, fornecedores, produtos, armazens, moedas, paises, cidades e configuracoes.
- Ciclo comercial completo: CRM, orcamento, encomenda, guia, fatura, recibo, nota de credito, devolucao e POS.
- Compras e fornecedores, com recepcao de mercadoria e contas a pagar.
- Stock multi-armazem, lotes, series, reservas, transferencias e contagens.
- Financeiro, tesouraria, contabilidade, impostos, multi-moeda e centros de custo.
- Recursos humanos, folha salarial, assiduidade, licencas e estrutura organizacional.
- Gestao escolar com submodulos academicos, financeiros, biblioteca, comunicacao e portais.
- Assinaturas SaaS, planos, limites, ciclos recorrentes e inadimplencia.

### 1.3 Fora do Escopo Imediato

- As pastas `info-organizado` e `info-copy-organizado` sao referencias de arquitetura, nao modulos ativos.
- A pasta `seguranca` e historica/descontinuada. O seu conteudo foi dividido em `autenticacao`, `autorizacao` e `auditoria`.

---

## 2. Arquitetura

### 2.1 Estilo Arquitetural

O sistema deve iniciar como **monolito modular** com limites claros por modulo.

Cada modulo deve possuir:

- schema SQL proprio;
- endpoints REST proprios;
- requisitos funcionais e nao funcionais;
- regras de negocio locais;
- integracoes explicitas com outros modulos;
- eventos de auditoria para operacoes sensiveis.

### 2.2 Camadas

```text
Frontend Web / POS / Portais
        |
API REST / BFF
        |
Servicos de Modulo
        |
Repositorios / Transacoes
        |
PostgreSQL + Views + Funcoes
        |
Jobs, Filas, Integracoes e Relatorios
```

### 2.3 Stack Recomendada

| Camada | Tecnologia |
| --- | --- |
| Frontend | React + TypeScript + Vite |
| Backend | Node.js + TypeScript + Express/Fastify |
| Base de dados | PostgreSQL 15+ |
| Cache e filas | Redis + BullMQ |
| Validacao | Zod |
| ORM opcional | Prisma ou query builder com SQL versionado |
| Autenticacao | JWT + refresh token + API keys |
| Observabilidade | logs estruturados, `api_logs`, `system_logs`, auditoria |
| Deploy | Docker, Docker Compose, Nginx, CI/CD |

### 2.4 Contratos Transversais

- Todas as tabelas de negocio devem possuir `tenant_id` ou `company_id`.
- Operacoes autenticadas devem receber `user_id` do modulo `autenticacao`.
- Permissoes devem ser verificadas pelo modulo `autorizacao`.
- Alteracoes sensiveis devem gerar registo em `audit_logs`.
- Documentos fiscais emitidos devem ser imutaveis; correcoes devem ocorrer por cancelamento, estorno ou nota de credito.
- Operacoes financeiras e de stock devem ser transacionais.
- APIs devem responder em JSON, usar paginacao, filtros e codigos HTTP previsiveis.
- Credenciais de integracoes externas devem ser armazenadas cifradas.

---

## 3. Ordem de Fundacao

A ordem recomendada para implementacao da base do ERP e:

1. `sistema-configuracao`
2. `empresas`
3. `autenticacao`
4. `autorizacao`
5. `utilizadores`
6. `auditoria`
7. `gestao-clientes`
8. `gestao-produtos`
9. `gestao-stock`
10. `financeiro`
11. `tesouraria`
12. `contabilidade`
13. modulos comerciais, operacionais e verticais

Esta ordem evita duplicacao de login, permissoes, tenant, configuracoes e logs.

---

## 4. Catalogo de Modulos

| Modulo | Status | Responsabilidade principal |
| --- | --- | --- |
| `empresas` | ativo | Multi-tenant, empresas, filiais, contactos, fiscalidade e licencas |
| `sistema-configuracao` | ativo | Configuracoes globais, moedas, taxas, paises, cidades, templates, logs e integracoes |
| `autenticacao` | ativo | Users, login, sessoes, historico, recuperacao de password e API keys |
| `autorizacao` | ativo | Roles, permissoes, role_permissions e user_roles |
| `utilizadores` | ativo | Perfis, preferencias, notificacoes, dispositivos, atividade, avatar e settings pessoais |
| `auditoria` | ativo | Logs imutaveis de acoes em todos os modulos |
| `gestao-clientes` | ativo | Clientes, contactos, moradas, credito, saldos, pagamentos, tags e descontos |
| `gestao-produtos` | ativo | Produtos, categorias, marcas, unidades, variantes, precos, imagens, kits e codigos |
| `gestao-stock` | ativo | Armazens, localizacoes, movimentos, ajustes, transferencias, reservas, lotes e alertas |
| `modulo-faturacao` | ativo | Orcamentos, encomendas, guias, faturas, recibos, notas de credito e devolucoes |
| `pos` | ativo | Terminais, sessoes de caixa, vendas, pagamentos, devolucoes e fecho de caixa |
| `compras` | ativo | Fornecedores, requisicoes, ordens, recepcoes, devolucoes, faturas e pagamentos |
| `financeiro` | ativo | Pagamentos, recebimentos, contas a receber, contas a pagar, fluxo de caixa e orcamentos |
| `tesouraria` | ativo | Contas bancarias, caixas, movimentos financeiros e reconciliacao |
| `contabilidade` | ativo | Plano de contas, lancamentos, impostos base, ativos fixos, balancetes e encerramentos |
| `impostos` | ativo | Regimes, isencoes, retencoes, declaracoes fiscais e certificados |
| `multi-moeda` | ativo | Politicas cambiais, conversoes, moeda do documento e arredondamentos |
| `centros-custo` | ativo | Centros de custo, orcamentos, alocacoes e movimentos |
| `crm` | ativo | Pipelines, leads, oportunidades, contactos, atividades, notas e relatorios comerciais |
| `recursos-humanos` | ativo | Estrutura organizacional, funcionarios, contratos, folha, assiduidade, licencas e avaliacao |
| `logistica` | ativo | Motoristas, viaturas, rotas, envios, tracking e logs de entrega |
| `assinaturas` | ativo | Planos SaaS, gateways, assinaturas, ciclos, pagamentos, uso, limites e churn |
| `gestao-escolar` | ativo | Administracao escolar, alunos, professores, academico, propinas, biblioteca e portais |
| `seguranca` | descontinuado | Referencia historica substituida por autenticacao, autorizacao e auditoria |

### 4.1 Divisao por Escopo: Super Admin e Tenant

O ERP deve separar claramente o que pertence ao **Super Admin da plataforma** e o que pertence ao **Tenant/Empresa cliente**.

**Super Admin** e o operador da plataforma Nexora ERP. Ele gere tenants, planos, licencas, modulos disponiveis, configuracoes globais, integracoes globais, logs tecnicos e suporte.

**Tenant** e a empresa cliente que usa o ERP. Ele gere os seus utilizadores, configuracoes locais, clientes, produtos, stock, faturacao, financeiro, contabilidade e modulos ativados no seu plano.

#### 4.1.1 Modulos de Super Admin

| Modulo | Service | Escopo do Super Admin |
| --- | --- | --- |
| `sistema-configuracao` | `sistema-configuracao-service` | Configuracoes globais, parametros padrao, moedas globais, integracoes globais, logs tecnicos e diagnostico |
| `empresas` | `empresa-service` | Cadastro de tenants/empresas, estado da conta, limites, licencas e associacao inicial de administradores |
| `autenticacao` | `auth-service` | Contas de super-admin, admins globais, sessoes administrativas e API keys da plataforma |
| `autorizacao` | `autorizacao-service` | Roles globais, permissoes globais, perfis padrao e matriz de acesso da plataforma |
| `auditoria` | `auditoria-service` | Auditoria global, eventos entre tenants, acoes de suporte e alteracoes de plataforma |
| `assinaturas` | `assinaturas-service` | Planos SaaS, funcionalidades por plano, limites, ciclos recorrentes, inadimplencia e suspensao de tenant |
| `notifications` | `notifications-service` | Templates globais, canais globais, avisos de sistema, fila e historico de comunicacoes da plataforma |
| `seguranca` | `seguranca-service` | Historico/descontinuado; nao deve receber novas telas de super-admin |

#### 4.1.2 Modulos de Tenant

| Modulo | Service | Escopo do Tenant |
| --- | --- | --- |
| `sistema-configuracao` | `sistema-configuracao-service` | Configuracoes locais do tenant, templates locais e parametros permitidos pelo plano |
| `empresas` | `empresa-service` | Dados da propria empresa, filiais, contactos, fiscal, bancos e utilizadores associados |
| `autenticacao` | `auth-service` | Login, sessoes, password, API keys e utilizadores do tenant |
| `autorizacao` | `autorizacao-service` | Roles e permissoes internas do tenant |
| `utilizadores` | `auth-service` ou service dedicado futuro | Perfil, preferencias e atividade dos utilizadores do tenant |
| `auditoria` | `auditoria-service` | Auditoria filtrada apenas pelo tenant/company permitido |
| `gestao-clientes` | `clientes-service` | Clientes, credito, saldo, pagamentos, tags e descontos |
| `gestao-produtos` | `produtos-service` | Produtos, categorias, precos, variantes, codigos e kits |
| `gestao-stock` | `stock-service` | Armazens, localizacoes, movimentos, reservas, lotes, series e contagens |
| `modulo-faturacao` | `faturacao-service` | Series, orcamentos, encomendas, guias, faturas, recibos e notas |
| `pos` | `pos-service` | Terminais, sessoes, vendas, devolucoes e fecho de caixa |
| `compras` | `compras-service` | Fornecedores, requisicoes, ordens, recepcoes, faturas e pagamentos |
| `financeiro` | `financeiro-service` | Contas a receber/pagar, pagamentos, recebimentos e fluxo de caixa |
| `tesouraria` | `tesouraria-service` | Bancos, caixas, movimentos e reconciliacao |
| `contabilidade` | `contabilidade-service` | Plano de contas, lancamentos, periodos, encerramentos e relatorios |
| `impostos` | `impostos-service` | Regimes, isencoes, retencoes, declaracoes e certificados do tenant |
| `multi-moeda` | `multi-moeda-service` | Politicas cambiais, conversoes e taxas aplicadas aos documentos do tenant |
| `centros-custo` | `centros-custo-service` | Centros, orcamentos, alocacoes e movimentos do tenant |
| `crm` | `crm-service` | Pipelines, leads, oportunidades, atividades e relatorios comerciais |
| `recursos-humanos` | `recursos-humanos-service` | Estrutura, funcionarios, contratos, folha, assiduidade e avaliacoes |
| `logistica` | `logistica-service` | Motoristas, viaturas, rotas, envios, tracking e logs de entrega |
| `gestao-escolar` | `gestao-escolar-service` | Operacao escolar do tenant quando o plano/vertical estiver ativo |

#### 4.1.3 Modulos Compartilhados

Alguns services aparecem nos dois escopos, mas com regras diferentes:

| Service | Super Admin | Tenant |
| --- | --- | --- |
| `sistema-configuracao-service` | Parametros globais e defaults da plataforma | Parametros locais permitidos |
| `empresa-service` | Cria e controla tenants | Tenant atualiza seus dados internos |
| `auth-service` | Admins globais e suporte | Users do tenant |
| `autorizacao-service` | Roles globais e permissoes base | Roles internas do tenant |
| `auditoria-service` | Visao global e eventos de suporte | Visao filtrada por tenant |
| `notifications-service` | Canais/templates globais | Preferencias e mensagens do tenant |
| `assinaturas-service` | Planos, cobrancas e limites | Consulta do plano atual e uso |

#### 4.1.4 Regras de Acesso por Escopo

- Super Admin pode listar tenants, gerir planos e suspender empresas.
- Super Admin nao deve editar documentos operacionais do tenant diretamente, exceto em modo suporte auditado.
- Tenant Admin nao pode ver dados de outros tenants.
- Tenant Admin pode gerir apenas recursos dentro do seu `tenant_id` ou `company_id`.
- Toda tabela de negocio do tenant deve possuir `tenant_id` ou `company_id`.
- Tabelas globais da plataforma devem possuir `scope`, `is_global` ou separacao equivalente.
- Acesso em modo suporte deve registrar `support_user_id`, `tenant_id`, motivo e periodo da sessao.
- Relatorios globais devem agregar dados sem expor informacao sensivel de outro tenant.

---

## 5. Dependencias entre Modulos

| Modulo | Depende de | Alimenta / integra com |
| --- | --- | --- |
| `empresas` | `sistema-configuracao` | todos os modulos via `tenant_id`/`company_id` |
| `autenticacao` | `empresas` | todos os modulos via `user_id` |
| `autorizacao` | `empresas`, `autenticacao` | todos os modulos via RBAC |
| `utilizadores` | `autenticacao` | perfis e preferencias de UI |
| `auditoria` | `empresas` | recebe eventos de todos os modulos |
| `gestao-clientes` | `empresas` | faturacao, financeiro, CRM, assinaturas, impostos |
| `gestao-produtos` | `empresas`, `sistema-configuracao` | stock, faturacao, POS, compras |
| `gestao-stock` | `gestao-produtos`, `empresas` | faturacao, POS, compras, logistica |
| `modulo-faturacao` | `clientes`, `produtos`, `stock`, `financeiro`, `contabilidade` | contas a receber, lancamentos, documentos fiscais |
| `pos` | `produtos`, `stock`, `financeiro`, `tesouraria`, `contabilidade` | vendas rapidas, caixa, receita contabilistica |
| `compras` | `produtos`, `stock`, `financeiro`, `contabilidade` | entradas de stock, contas a pagar |
| `financeiro` | `clientes`, `compras`, `tesouraria`, `contabilidade` | cash flow, aging, pagamentos e recebimentos |
| `tesouraria` | `financeiro`, `empresas` | saldos de caixa/banco e reconciliacao |
| `contabilidade` | `financeiro`, `faturacao`, `compras`, `RH`, `POS` | relatorios contabilisticos e encerramentos |
| `impostos` | `contabilidade`, `clientes`, `compras`, `RH` | lancamentos de imposto retido e declaracoes |
| `multi-moeda` | `sistema-configuracao` | faturacao, compras, financeiro e contabilidade |
| `centros-custo` | `contabilidade` | analise de rentabilidade por departamento/projeto |
| `crm` | `autenticacao`, `clientes` | propostas/faturas ao ganhar oportunidade |
| `recursos-humanos` | `autenticacao`, `financeiro`, `contabilidade` | pagamentos salariais e lancamentos |
| `logistica` | `faturacao`, `stock` | rastreio de guias de remessa e entregas |
| `assinaturas` | `clientes`, `faturacao`, `financeiro` | limites do tenant e faturacao recorrente |
| `gestao-escolar` | `autenticacao`, `autorizacao`, `utilizadores`, `financeiro`, `tesouraria`, `auditoria` | cobrancas escolares, pagamentos e portais |

---

## 6. Especificacao por Modulo

### 6.1 Empresas e Multi-Tenant

**Objetivo:** controlar a estrutura multiempresa do ERP e servir como base de segregacao de dados.

**Escopo:** empresas, configuracoes, filiais, enderecos, contactos, documentos, informacao fiscal, contas bancarias, licencas e associacao empresa-utilizador.

**Entidades:** `companies`, `company_settings`, `company_branches`, `company_addresses`, `company_contacts`, `company_documents`, `company_tax_info`, `company_banks`, `company_licenses`, `company_users`.

**API:** `/api/companies`, `/api/companies/{id}/settings`, `/api/companies/{id}/branches`, `/api/companies/{id}/tax-info`, `/api/companies/{id}/banks`, `/api/companies/{id}/licenses`, `/api/companies/{id}/users`.

**Regra central:** todos os modulos devem referenciar `company_id` ou `tenant_id`.

### 6.2 Sistema e Configuracao

**Objetivo:** fornecer dados globais e configuracoes operacionais usadas por todos os modulos.

**Escopo:** configuracoes globais/tenant/utilizador, moedas, taxas de cambio, paises, cidades, idiomas, templates de email/SMS, logs, integracoes e logs de API.

**Entidades:** `settings`, `currencies`, `exchange_rates`, `countries`, `cities`, `languages`, `email_templates`, `sms_templates`, `system_logs`, `integrations`, `api_logs`.

**API:** `/api/settings`, `/api/currencies`, `/api/exchange-rates`, `/api/countries`, `/api/cities`, `/api/languages`, `/api/email-templates`, `/api/sms-templates`, `/api/integrations`, `/api/api-logs`.

**Regras:** configuracoes devem ser cacheadas; credenciais devem ser cifradas; referencias em uso nao devem ser eliminadas.

### 6.3 Autenticacao

**Objetivo:** gerir contas, sessoes, login, recuperacao de password e chaves de API.

**Escopo:** email/password, access token, refresh token, API key, revogacao de sessoes, historico de login e password reset.

**Entidades:** `users`, `sessions`, `login_history`, `password_resets`, `api_keys`.

**API:** `/api/auth/login`, `/api/auth/logout`, `/api/auth/refresh`, `/api/auth/me`, `/api/auth/change-password`, `/api/auth/forgot-password`, `/api/auth/reset-password`, `/api/auth/utilizadores`, `/api/auth/sessoes`, `/api/auth/api-keys`.

**Regras:** tokens devem ser armazenados como hash quando persistidos; API keys so devem ser exibidas em claro no momento da criacao.

### 6.4 Autorizacao

**Objetivo:** gerir controlo de acesso baseado em roles e permissoes.

**Escopo:** roles por tenant, permissoes por recurso/acao, associacao role-permissao e atribuicao de roles a users.

**Entidades:** `roles`, `permissions`, `role_permissions`, `user_roles`.

**API:** `/api/roles`, `/api/permissions`, `/api/roles/{id}/permissions`, `/api/users/{id}/roles`.

**Regras:** nenhuma operacao sensivel deve ser executada sem verificacao explicita de permissao.

### 6.5 Utilizadores

**Objetivo:** complementar autenticacao com dados pessoais e operacionais do utilizador.

**Escopo:** perfis, preferencias, notificacoes, dispositivos, atividade, tokens, logs de seguranca, avatar e configuracoes pessoais.

**Entidades:** `profiles`, `user_preferences`, `user_notifications`, `user_devices`, `user_activity`, `user_tokens`, `user_security_logs`, `user_avatar`, `user_settings`.

**API:** `/api/utilizadores/perfis`, `/api/utilizadores/{userId}/preferences`, `/api/utilizadores/{userId}/notifications`, `/api/utilizadores/{userId}/devices`, `/api/utilizadores/{userId}/activity`, `/api/utilizadores/{userId}/tokens`, `/api/utilizadores/{userId}/security-logs`, `/api/utilizadores/{userId}/avatar`, `/api/utilizadores/{userId}/settings`.

### 6.6 Auditoria

**Objetivo:** registar todas as acoes relevantes de utilizadores em qualquer modulo.

**Escopo:** criacao, alteracao, eliminacao, aprovacao, cancelamento, login, bloqueio, emissao e operacoes financeiras/fiscais.

**Entidade:** `audit_logs`.

**API:** `/api/audit-logs`, com filtros por `modulo`, `user_id`, `entidade`, `entidade_id` e periodo.

**Regras:** logs devem ser imutaveis; nao deve existir cascata que elimine auditoria.

### 6.7 Gestao de Clientes

**Objetivo:** concentrar a informacao completa dos clientes e o historico comercial.

**Escopo:** cadastro, grupos, contactos, enderecos, documentos, limite de credito, saldos, pagamentos, notas, historico, tags e descontos.

**Entidades:** `customers`, `customer_groups`, `customer_contacts`, `customer_addresses`, `customer_documents`, `customer_credit_limits`, `customer_balances`, `customer_payments`, `customer_notes`, `customer_history`, `customer_tags`, `customer_tag_links`, `customer_discounts`.

**API:** `/api/clientes`, `/api/clientes/grupos`, `/api/clientes/{id}/contactos`, `/api/clientes/{id}/enderecos`, `/api/clientes/{id}/documentos`, `/api/clientes/{id}/limite-credito`, `/api/clientes/{id}/saldo`, `/api/clientes/{id}/pagamentos`, `/api/clientes/{id}/tags`, `/api/clientes/{id}/descontos`.

**Indicadores:** total comprado, total pago, valor em aberto, limite de credito, credito disponivel, ultima compra e ultimo pagamento.

### 6.8 Gestao de Produtos

**Objetivo:** gerir o cadastro comercial, fiscal e estrutural de produtos e servicos.

**Escopo:** categorias, subcategorias, marcas, unidades, produtos, variantes, imagens, precos, descontos, codigos de barras, tags, atributos e kits.

**Entidades:** `product_categories`, `product_subcategories`, `product_brands`, `product_units`, `products`, `product_variants`, `product_images`, `product_prices`, `product_discounts`, `product_barcodes`, `product_tags`, `product_tag_links`, `product_attributes`, `product_attribute_values`, `product_kits`, `product_kit_items`, `warehouses`.

**API:** `/api/produtos`, `/api/produtos/categorias`, `/api/produtos/marcas`, `/api/produtos/unidades`, `/api/produtos/atributos`, `/api/produtos/{id}/variantes`, `/api/produtos/{id}/imagens`, `/api/produtos/{id}/precos`, `/api/produtos/{id}/stock`.

### 6.9 Gestao de Stock

**Objetivo:** controlar inventario por armazem, localizacao, lote, serie e documento de origem.

**Escopo:** armazens, localizacoes, itens de stock, movimentos, ajustes, transferencias, reservas, lotes, numeros de serie, contagens fisicas, alertas e logs.

**Entidades:** `warehouse_locations`, `stock_items`, `stock_movements`, `stock_adjustments`, `stock_transfers`, `stock_reservations`, `stock_batches`, `stock_serial_numbers`, `stock_counts`, `stock_count_items`, `stock_alerts`, `stock_logs`.

**API:** `/api/stock/warehouses`, `/api/stock/items`, `/api/stock/movements`, `/api/stock/adjustments`, `/api/stock/transfers`, `/api/stock/reservations`, `/api/stock/batches`, `/api/stock/serials`, `/api/stock/counts`, `/api/stock/alerts`, `/api/stock/reports/*`.

**Regras:** movimentos que afetam stock devem ser atomicos; reserva, libertacao e consumo de reserva devem usar funcoes transacionais.

### 6.10 Modulo de Faturacao

**Objetivo:** gerir o ciclo documental de vendas.

**Escopo:** series documentais, orcamentos, encomendas, guias de remessa, faturas, recibos, notas de credito e devolucoes.

**Entidades:** `invoice_series`, `sales_quotes`, `sales_quote_items`, `sales_orders`, `sales_order_items`, `sales_deliveries`, `sales_delivery_items`, `invoices`, `invoice_items`, `invoice_taxes`, `invoice_discounts`, `invoice_receipts`, `credit_notes`, `credit_note_items`, `sales_returns`, `sales_return_items`.

**API:** `/api/faturacao/series`, `/api/faturacao/quotes`, `/api/faturacao/orders`, `/api/faturacao/deliveries`, `/api/faturacao/invoices`, `/api/faturacao/receipts`, `/api/faturacao/credit-notes`, `/api/faturacao/returns`, `/api/faturacao/reports/*`.

**Regras:** emissao gera numero definitivo e documento imutavel; fatura emitida cria conta a receber; recibo confirmado atualiza saldo; nota de credito referencia fatura original.

### 6.11 POS

**Objetivo:** operar vendas rapidas em loja, caixa e terminais.

**Escopo:** terminais, sessoes de caixa, vendas, pagamentos, devolucoes, movimentos manuais e reconciliacao no fecho.

**Entidades:** `pos_terminals`, `pos_sessions`, `pos_session_payments`, `pos_sales`, `pos_sale_items`, `pos_payments`, `pos_returns`, `pos_return_items`, `pos_cash_movements`.

**API:** `/api/pos/terminals`, `/api/pos/sessions`, `/api/pos/sales`, `/api/pos/returns`, `/api/pos/sessions/{id}/cash-movements`, `/api/pos/reports/*`.

**Regras:** apenas uma sessao ativa por terminal; venda confirma baixa de stock; fecho calcula diferenca entre saldo declarado e calculado.

### 6.12 Compras

**Objetivo:** gerir fornecedores e o ciclo de compra ate recepcao, fatura e pagamento.

**Escopo:** fornecedores, contactos, moradas, requisicoes, ordens de compra, recepcoes parciais, devolucoes, faturas de fornecedor e pagamentos.

**Entidades:** `suppliers`, `supplier_contacts`, `supplier_addresses`, `purchase_requests`, `purchase_request_items`, `purchase_orders`, `purchase_order_items`, `purchase_receipts`, `purchase_receipt_items`, `purchase_returns`, `purchase_return_items`, `purchase_invoices`, `purchase_invoice_items`, `purchase_payments`, `purchase_payment_items`.

**API:** `/api/purchase-requests`, `/api/purchase-orders`, `/api/purchase-receipts`, `/api/purchase-returns`, `/api/purchase-invoices`, `/api/purchase-payments`.

**Regras:** recepcao de mercadoria deve atualizar stock na mesma transacao; faturas confirmadas devem ser imutaveis; fatura de fornecedor deve ser rastreavel ate ordem e recepcao.

### 6.13 Financeiro

**Objetivo:** gerir pagamentos, recebimentos, dividas e fluxo de caixa.

**Escopo:** meios de pagamento, categorias financeiras, pagamentos, recebimentos, contas a receber, contas a pagar, orcamentos, cash flow e relatorios financeiros.

**Entidades:** `payment_methods`, `financial_categories`, `payments`, `payment_transactions`, `accounts_receivable`, `accounts_receivable_payments`, `accounts_payable`, `accounts_payable_payments`, `financial_budgets`, `cash_flow_entries`, `financial_reports`.

**API:** `/api/financeiro/payment-methods`, `/api/financeiro/categories`, `/api/financeiro/payments`, `/api/financeiro/receivables`, `/api/financeiro/payables`, `/api/financeiro/budgets`, `/api/financeiro/cash-flow`, `/api/financeiro/reports/*`.

**Regras:** pagamentos confirmados devem distribuir valores para caixa/banco via tesouraria; contas a receber/pagar devem manter saldo pendente calculado.

### 6.14 Tesouraria

**Objetivo:** controlar recursos financeiros liquidos.

**Escopo:** contas bancarias, caixas fisicas, movimentos financeiros, origem de movimento, reconciliacao bancaria e saldos.

**Entidades:** `contas_bancarias`, `caixas`, `movimentos_financeiros`, `reconciliacoes_bancarias`.

**API:** `/api/tesouraria/contas-bancarias`, `/api/tesouraria/caixas`, `/api/tesouraria/movimentos`, `/api/tesouraria/reconciliacoes`.

**Regras:** atualizacao de saldo deve ser atomica com movimento; reconciliacao fechada nao pode ser alterada; caixa nao deve ficar negativa salvo configuracao explicita.

### 6.15 Contabilidade

**Objetivo:** suportar contabilidade de dupla entrada e relatorios legais/gerenciais.

**Escopo:** tipos de conta, plano de contas, anos e periodos fiscais, lancamentos, impostos base, balancetes, demonstracoes, ativos fixos, amortizacoes, orcamentos e encerramentos.

**Entidades:** `account_types`, `chart_of_accounts`, `fiscal_years`, `fiscal_periods`, `journal_entries`, `journal_entry_lines`, `tax_groups`, `taxes`, `tax_rules`, `tax_transactions`, `trial_balance`, `balance_sheet`, `income_statement`, `fixed_assets`, `depreciation_schedules`, `budget_accounts`, `period_closings`, `closing_checks`.

**API:** `/api/contabilidade/account-types`, `/api/contabilidade/accounts`, `/api/contabilidade/fiscal-years`, `/api/contabilidade/fiscal-periods`, `/api/contabilidade/journal-entries`, `/api/contabilidade/taxes`, `/api/contabilidade/fixed-assets`, `/api/contabilidade/depreciation`, `/api/contabilidade/budgets`, `/api/contabilidade/period-closings`, `/api/contabilidade/reports/*`.

**Regras:** lancamentos devem fechar debito igual a credito; periodos encerrados so podem ser reabertos com permissao e justificacao.

### 6.16 Impostos Avancados

**Objetivo:** complementar contabilidade com isencoes, retencoes, declaracoes e certificados.

**Escopo:** regimes fiscais, isencoes de IVA, retencoes na fonte, transacoes de retencao, declaracoes fiscais periodicas, linhas de declaracao e certificados.

**Entidades:** `tax_regimes`, `tax_exemptions`, `withholding_taxes`, `withholding_tax_transactions`, `tax_returns`, `tax_return_lines`, `tax_certificates`.

**API:** `/api/impostos/regimes`, `/api/impostos/isencoes`, `/api/impostos/retencoes`, `/api/impostos/declaracoes`, `/api/impostos/certificados`.

**Regras:** `taxes`, `tax_groups`, `tax_rules` e `tax_transactions` pertencem a `contabilidade`; este modulo apenas estende o tratamento fiscal.

### 6.17 Multi-Moeda

**Objetivo:** gerir conversoes entre moeda do documento e moeda base da empresa.

**Escopo:** politicas de taxa, conversoes por documento, historico de taxa aplicada, moeda do documento e regras de arredondamento.

**Entidades:** `exchange_rate_policies`, `currency_conversions`, `document_currencies`, `currency_rounding_rules`.

**API:** `/api/multi-moeda/policies`, `/api/multi-moeda/converter`, `/api/multi-moeda/taxa`, `/api/multi-moeda/historico`, `/api/multi-moeda/documentos/{tipo}/{id}`, `/api/multi-moeda/arredondamento`.

**Regras:** `currencies` e `exchange_rates` pertencem a `sistema-configuracao`; os documentos devem guardar a taxa aplicada historicamente.

### 6.18 Centros de Custo

**Objetivo:** analisar receitas e despesas por departamento, projeto ou area de negocio.

**Escopo:** hierarquia de centros de custo, orcamentos por periodo, alocacoes de lancamentos e relatorio orcado vs realizado.

**Entidades:** `cost_centers`, `cost_center_budgets`, `cost_center_allocations`, `cost_center_movements`.

**API:** `/api/cost-centers`, `/api/cost-centers/{id}/children`, `/api/cost-centers/{id}/budgets`, `/api/cost-centers/{id}/allocations`, `/api/cost-centers/{id}/movements`, `/api/cost-centers/{id}/relatorio`.

### 6.19 CRM

**Objetivo:** gerir relacionamento comercial antes da venda.

**Escopo:** pipelines, etapas, leads, oportunidades, contactos, atividades, notas, tags, funil e previsao de receita.

**Entidades:** `crm_pipelines`, `crm_stages`, `crm_leads`, `crm_opportunities`, `crm_contacts`, `crm_activities`, `crm_notes`, `crm_tags`, `crm_tag_links`.

**API:** `/api/crm/pipelines`, `/api/crm/leads`, `/api/crm/opportunities`, `/api/crm/contacts`, `/api/crm/activities`, `/api/crm/notes`, `/api/crm/relatorio/*`.

**Regras:** lead convertido deve criar/ligar cliente; oportunidade ganha deve poder originar proposta, orcamento ou fatura.

### 6.20 Recursos Humanos

**Objetivo:** gerir o ciclo de vida do colaborador.

**Escopo:** estrutura organizacional, cargos, horarios, funcionarios, documentos, contratos, salarios, beneficios, assiduidade, horas extra, licencas, folha salarial, avaliacoes, formacoes e disciplina.

**Entidades:** `org_units`, `org_closures`, `employee_positions`, `work_schedules`, `employees`, `employee_addresses`, `employee_emergency_contacts`, `employee_documents`, `employee_contracts`, `payroll_components`, `employee_salaries`, `employee_benefits`, `employee_attendance`, `employee_overtime`, `employee_leave_types`, `employee_leave_balances`, `employee_leaves`, `payroll_runs`, `employee_payroll`, `employee_payroll_items`, `employee_evaluations`, `evaluation_criteria`, `employee_training`, `employee_disciplinary`.

**API:** `/api/rh/org`, `/api/rh/positions`, `/api/rh/work-schedules`, `/api/rh/employees`, `/api/rh/contracts`, `/api/rh/payroll-components`, `/api/rh/attendance`, `/api/rh/overtime`, `/api/rh/leaves`, `/api/rh/payroll-runs`, `/api/rh/payslips`, `/api/rh/evaluations`.

**Regras:** hierarquia usa closure table; processamento salarial aprovado deve alimentar financeiro e contabilidade.

### 6.21 Logistica

**Objetivo:** gerir entregas e rastreio operacional.

**Escopo:** motoristas, viaturas, rotas, estados de envio, envios, itens, tracking GPS opcional e logs de eventos.

**Entidades:** `delivery_drivers`, `delivery_vehicles`, `delivery_routes`, `delivery_status`, `shipments`, `shipment_items`, `delivery_tracking`, `delivery_logs`.

**API:** `/api/delivery-drivers`, `/api/delivery-vehicles`, `/api/delivery-routes`, `/api/delivery-status`, `/api/shipments`, `/api/shipment-items`, `/api/delivery-tracking`, `/api/delivery-logs`.

**Regras:** uma guia de remessa ativa nao deve estar associada a mais de um envio ativo; GPS e opcional e nao deve bloquear entrega.

### 6.22 Assinaturas SaaS e Licencas

**Objetivo:** gerir planos, faturacao recorrente, limites por empresa e ciclo de inadimplencia.

**Escopo:** gateways, planos, funcionalidades, assinaturas, ciclos, pagamentos, uso por metrica, pausas, cancelamentos, eventos e relatorios SaaS.

**Entidades:** `payment_gateways`, `subscription_plans`, `subscription_plan_features`, `subscriptions`, `subscription_billing_cycles`, `subscription_payments`, `subscription_usage`, `subscription_pauses`, `subscription_cancellations`, `subscription_events`.

**API:** `/api/assinaturas/gateways`, `/api/assinaturas/planos`, `/api/assinaturas`, `/api/assinaturas/{id}/ciclos`, `/api/assinaturas/{id}/pagamentos`, `/api/assinaturas/{id}/uso`, `/api/assinaturas/reports/*`.

**Estados:** `trial`, `activa`, `pausada`, `suspensa`, `cancelada`, `expirada`.

**Regras:** job diario de faturacao deve ser idempotente; limites de plano devem ser verificados antes de criar utilizadores, filiais, produtos ou documentos.

### 6.23 Gestao Escolar

**Objetivo:** gerir operacoes academicas, financeiras e comunicacionais de escolas e colegios.

**Escopo:** administracao escolar, alunos, professores, cargos, academico, financeiro escolar, biblioteca, comunicacao, relatorios e portais.

**Submodulos:**

| Submodulo | Responsabilidade |
| --- | --- |
| `administracao-escolar` | anos lectivos, periodos, turmas, salas, horarios e calendario |
| `gestao-alunos` | alunos, encarregados, matriculas, rematriculas, transferencias e historico |
| `gestao-professores` | professores, atribuicoes, carga lectiva e disciplinas |
| `academico` | disciplinas, frequencia, avaliacoes, notas, medias e boletins |
| `cargos-escolares` | cargos de alunos e professores por turma, ciclo ou escola |
| `financeiro-escolar` | propinas, matriculas, taxas, descontos, bolsas, entidade/referencia e recibos |
| `biblioteca` | livros, emprestimos, devolucoes e atrasos |
| `comunicacao-escolar` | mensagens, circulares, alertas e notificacoes |
| `relatorios-escolares` | indicadores academicos, financeiros e dashboard da direccao |
| `portal-aluno` | notas, frequencia, pagamentos e comunicados |
| `portal-professor` | diario de turma, lancamento de notas, frequencia e materiais |
| `portal-encarregado` | acompanhamento academico e financeiro do educando |

**Entidades principais:** `school_years`, `school_terms`, `classes`, `subjects`, `teachers`, `teacher_assignments`, `teacher_roles`, `students`, `student_guardians`, `enrollments`, `student_roles`, `attendance_records`, `grade_items`, `grades`, `fee_plans`, `student_invoices`, `student_payments`, `library_books`, `library_loans`, `school_messages`, `time_slots`, `timetable_entries`, `school_events`, `student_incidents`, `student_sanctions`.

**API:** `/api/escolar/years`, `/api/escolar/classes`, `/api/escolar/subjects`, `/api/escolar/students`, `/api/escolar/enrollments`, `/api/escolar/attendance`, `/api/escolar/grades`, `/api/escolar/fee-plans`, `/api/escolar/student-invoices`, `/api/escolar/payments`, `/api/escolar/library/*`, `/api/escolar/messages`, `/api/escolar/reports/*`.

**Regras:** notas, frequencias, matriculas e pagamentos escolares devem ser auditados; financeiro escolar deve integrar com financeiro e tesouraria.

### 6.24 Seguranca

**Status:** descontinuado como modulo ativo.

O conteudo de `seguranca` foi dividido em:

- `autenticacao`: contas, sessoes, login, password reset e API keys.
- `autorizacao`: roles, permissoes e associacoes.
- `auditoria`: trilha imutavel de eventos.

Novos desenvolvimentos nao devem depender diretamente da pasta `seguranca`.

---

## 7. APIs REST

### 7.1 Convencoes

- Base: `/api`.
- Autenticacao: Bearer JWT ou API key para integracoes externas.
- Todos os endpoints de negocio devem validar tenant.
- Listagens devem suportar `page`, `limit`, `sort`, `search` e filtros por periodo/status quando aplicavel.
- Erros devem seguir formato consistente:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Descricao curta do erro",
    "details": []
  }
}
```

### 7.2 Modulos e Bases de API

| Modulo | Base de API |
| --- | --- |
| Empresas | `/api/companies` |
| Sistema/configuracao | `/api/settings`, `/api/currencies`, `/api/integrations` |
| Autenticacao | `/api/auth` |
| Autorizacao | `/api/roles`, `/api/permissions` |
| Utilizadores | `/api/utilizadores` |
| Auditoria | `/api/audit-logs` |
| Clientes | `/api/clientes` |
| Produtos | `/api/produtos` |
| Stock | `/api/stock` |
| Faturacao | `/api/faturacao` |
| POS | `/api/pos` |
| Compras | `/api/purchase-*` |
| Financeiro | `/api/financeiro` |
| Tesouraria | `/api/tesouraria` |
| Contabilidade | `/api/contabilidade` |
| Impostos | `/api/impostos` |
| Multi-moeda | `/api/multi-moeda` |
| Centros de custo | `/api/cost-centers` |
| CRM | `/api/crm` |
| Recursos humanos | `/api/rh` |
| Logistica | `/api/shipments`, `/api/delivery-*` |
| Assinaturas | `/api/assinaturas` |
| Gestao escolar | `/api/escolar` |

---

## 8. Base de Dados e Scripts

Cada modulo possui SQL versionavel na propria pasta.

| Modulo | Script principal | Complementos |
| --- | --- | --- |
| `empresas` | `database-empresas.sql` | `views-empresas.sql`, `dependencias-empresas.md` |
| `sistema-configuracao` | `database-sistema.sql` | `api-sistema.md`, `requisitos.md`, `uml.md` |
| `autenticacao` | `database-autenticacao.sql` | `api-autenticacao.md`, `requisitos.md`, `uml.md` |
| `autorizacao` | `database-autorizacao.sql` | `api-autorizacao.md`, `requisitos.md`, `uml.md` |
| `utilizadores` | `database-utilizadores.sql` | `views-utilizadores.sql`, `dependencias-utilizadores.md` |
| `auditoria` | `database-auditoria.sql` | `api-auditoria.md` |
| `gestao-clientes` | `database-clientes.sql` | `views-clientes.sql`, `funcoes-clientes.sql` |
| `gestao-produtos` | `database-produtos.sql` | `views-produtos.sql` |
| `gestao-stock` | `database-stock.sql` | `views-stock.sql`, `funcoes-stock.sql` |
| `modulo-faturacao` | `database.sql` | `dependencias-entre-modulos.md`, `estrutura-do-modulo.md` |
| `pos` | `database-pos.sql` | `api-pos.md`, `requisitos.md`, `uml.md` |
| `compras` | `database-compras.sql` | `views-compras.sql` |
| `financeiro` | `database-financeiro.sql` | `api-financeiro.md`, `requisitos.md`, `uml.md` |
| `tesouraria` | `database-tesouraria.sql` | `views-tesouraria.sql` |
| `contabilidade` | `database-contabilidade.sql` | `views-contabilidade.sql` |
| `impostos` | `database-impostos.sql` | `api-impostos.md`, `requisitos.md`, `uml.md` |
| `multi-moeda` | `database-multi-moeda.sql` | `api-multi-moeda.md`, `requisitos.md`, `uml.md` |
| `centros-custo` | `database-centros-custo.sql` | `api-centros-custo.md`, `requisitos.md`, `uml.md` |
| `crm` | `database-crm.sql` | `api-crm.md`, `requisitos.md`, `uml.md` |
| `recursos-humanos` | `database-rh.sql` | `hierarchy-rh.sql`, `views-rh.sql` |
| `logistica` | `database-logistica.sql` | `api-logistica.md`, `requisitos.md`, `uml.md` |
| `assinaturas` | `database-assinaturas.sql` | `api-assinaturas.md`, `requisitos.md`, `uml.md` |
| `gestao-escolar` | `database-gestao-escolar.sql` | `submodulos/*`, `api-gestao-escolar.md` |

### 8.1 Regras de Modelagem

- Usar `created_at`, `updated_at`, `created_by`, `updated_by` quando aplicavel.
- Usar `status` explicito para documentos com ciclo de vida.
- Usar `origem_tipo` e `origem_id` para rastrear integracoes entre modulos.
- Usar constraints para saldos, totais e unicidade por tenant.
- Usar views para relatorios de leitura pesada.
- Usar funcoes SQL para operacoes criticas de stock, saldo e hierarquia.

---

## 9. Regras de Negocio Transversais

### 9.1 Multi-Tenant

- Nenhuma consulta de negocio pode retornar dados de outro tenant.
- `tenant_id`/`company_id` deve compor indices de consulta frequente.
- Numeracoes devem ser unicas por tenant, tipo de documento e ano quando aplicavel.

### 9.2 Documentos

- Rascunhos podem ser editados.
- Documentos confirmados ou emitidos nao podem ser alterados diretamente.
- Cancelamentos exigem motivo, permissao e auditoria.
- Documentos fiscais devem manter numero original mesmo quando cancelados.

### 9.3 Financeiro, Tesouraria e Contabilidade

- Recebimentos e pagamentos confirmados devem atualizar saldos em transacao.
- Contas a receber/pagar devem permitir pagamentos parciais e imputacao.
- Lancamentos contabilisticos devem respeitar debito igual a credito.
- Periodos encerrados bloqueiam novos lancamentos salvo reabertura autorizada.

### 9.4 Stock

- Stock nao deve ficar negativo sem configuracao explicita.
- Movimentos de entrada/saida devem referenciar documento ou motivo.
- Reservas devem ser consumidas ou libertadas de forma atomica.
- Contagens fisicas devem gerar ajustes rastreaveis.

### 9.5 Auditoria e Seguranca

- Login, bloqueio, emissao, cancelamento, aprovacao, pagamento e alteracoes financeiras devem ser auditados.
- Logs de auditoria nao devem ser atualizados nem eliminados por operacoes normais.
- Passwords devem ser armazenadas com hash forte.
- API keys devem ser revogaveis e rastreaveis.

---

## 10. Plano de Desenvolvimento

### Fase 1 - Fundacao

- Sistema/configuracao.
- Empresas e multi-tenant.
- Autenticacao, autorizacao, utilizadores e auditoria.
- Estrutura base de API, validacao, logging e migrations.

### Fase 2 - Cadastros Comerciais

- Clientes.
- Produtos.
- Stock base.
- Fornecedores dentro de compras.

### Fase 3 - Ciclo Comercial

- Faturacao.
- POS.
- Compras.
- Logistica basica.

### Fase 4 - Financeiro e Fiscal

- Financeiro.
- Tesouraria.
- Contabilidade.
- Impostos.
- Multi-moeda.
- Centros de custo.

### Fase 5 - Operacoes e Crescimento

- CRM.
- Recursos humanos.
- Assinaturas SaaS.
- Relatorios consolidados.

### Fase 6 - Verticais

- Gestao escolar.
- Portais de aluno, professor e encarregado.
- Financeiro escolar e comunicacao escolar.

---

## 11. Passo a Passo Detalhado de Implementacao

Esta secao descreve como transformar a especificacao em desenvolvimento real, modulo por modulo. A ordem deve ser respeitada porque cada grupo cria bases usadas pelos modulos seguintes.

### 11.1 Passo 0 - Preparacao do Ambiente

**Objetivo:** garantir que o projeto esta pronto para receber implementacao sem duplicar responsabilidades.

**Acoes:**

1. Abrir o diretorio principal:

```text
D:\projecto\e-258tech\2026\factPro
```

1. Usar `spec.md` como documento principal de referencia.

2. Usar `nexora ERP/` como fonte de requisitos por modulo.

3. Usar `nexora-erp/` como base de implementacao, quando o objetivo for codificar os servicos.

4. Confirmar que `seguranca` nao sera usado para novo desenvolvimento.

5. Confirmar que os novos modulos de seguranca sao:

```text
autenticacao
autorizacao
auditoria
```

**Resultado esperado:** equipe e codigo trabalham com a mesma ordem de modulos e as mesmas responsabilidades.

### 11.2 Passo 1 - Ler a Documentacao do Modulo

Para cada modulo, antes de codificar, abrir a pasta correspondente em:

```text
D:\projecto\e-258tech\2026\factPro\nexora ERP\<modulo>
```

Ler os arquivos nesta ordem:

| Ordem | Arquivo | Para que serve |
| --- | --- | --- |
| 1 | `README.md` | Entender objetivo, escopo, entidades e dependencias |
| 2 | `requisitos.md` | Extrair requisitos funcionais e nao funcionais |
| 3 | `api-*.md` | Mapear endpoints REST obrigatorios |
| 4 | `database-*.sql` ou `database.sql` | Criar tabelas, indices, constraints e dados base |
| 5 | `views-*.sql` | Criar consultas prontas para relatorios |
| 6 | `funcoes-*.sql` | Criar regras transacionais no banco quando existirem |
| 7 | `uml.md` | Confirmar entidades, fluxos e estados |

**Resultado esperado:** nenhuma tabela, rota ou regra deve ser criada sem estar ligada a requisito ou dependencia documentada.

### 11.3 Passo 2 - Criar ou Atualizar Base de Dados

**Objetivo:** garantir que a persistencia do modulo esta correta antes de criar API.

**Acoes:**

1. Criar migration do modulo no servico correspondente.
2. Copiar/adaptar tabelas do SQL documentado.
3. Garantir `tenant_id` ou `company_id` em toda tabela de negocio.
4. Criar constraints de unicidade por tenant quando necessario.
5. Criar indices para campos de busca frequente.
6. Criar foreign keys quando o modulo depende de entidades internas.
7. Evitar foreign keys fortes entre schemas quando isso quebrar independecia de microsservicos; nesses casos usar `origem_tipo`, `origem_id` e validacao por API/evento.
8. Criar views e funcoes auxiliares quando existirem no modulo.

**Checklist de banco:**

- Tabelas principais existem.
- Campos obrigatorios existem.
- Estados (`status`) estao controlados por `CHECK` ou enum equivalente.
- Numeracao de documentos e unica por tenant.
- Campos monetarios usam `NUMERIC`, nao `FLOAT`.
- Datas importantes usam `DATE` ou `TIMESTAMPTZ` corretamente.
- `created_at` e `updated_at` existem quando aplicavel.

### 11.4 Passo 3 - Criar Models, Repositorios ou Queries

**Objetivo:** isolar acesso a dados antes de implementar regras.

**Acoes:**

1. Criar funcoes de consulta por ID.
2. Criar listagens paginadas.
3. Criar insercao, atualizacao e alteracao de estado.
4. Criar funcoes transacionais para operacoes criticas.
5. Garantir filtro por tenant em todas as queries.

**Resultado esperado:** nenhuma controller deve conter SQL complexo ou regra de negocio longa.

### 11.5 Passo 4 - Criar Validacoes

**Objetivo:** impedir dados invalidos antes de chegar ao banco.

**Acoes:**

1. Validar campos obrigatorios.
2. Validar tipos de dados.
3. Validar estados permitidos.
4. Validar valores monetarios positivos.
5. Validar datas de inicio/fim.
6. Validar relacoes obrigatorias entre entidades.

**Exemplos:**

- Fatura nao pode ser emitida sem cliente.
- Venda POS nao pode ser fechada sem pagamento.
- Movimento de stock precisa de produto, armazem, quantidade e origem.
- Reconciliacao fechada nao pode ser alterada.

### 11.6 Passo 5 - Criar Services com Regras de Negocio

**Objetivo:** concentrar as regras do modulo em uma camada clara.

**Acoes:**

1. Implementar casos de uso do modulo.
2. Tratar estados de documento.
3. Chamar outros modulos quando necessario.
4. Criar eventos de auditoria.
5. Garantir transacoes para operacoes financeiras, stock e documentos.

**Padrao recomendado:**

```text
controller -> validation -> service -> repository/db -> response
```

**Resultado esperado:** regra de negocio deve estar no service, nao espalhada em rotas.

### 11.7 Passo 6 - Criar Controllers e Rotas REST

**Objetivo:** expor o contrato definido em `api-*.md`.

**Acoes:**

1. Criar rotas `GET`, `POST`, `PUT`, `DELETE` conforme documentado.
2. Criar endpoints de acao para mudancas de estado.
3. Criar endpoints de relatorio.
4. Padronizar resposta JSON.
5. Padronizar erros.

**Exemplos de endpoints de acao:**

```text
POST /api/faturacao/invoices/{id}/emitir
POST /api/pos/sessions/{id}/fechar
POST /api/stock/transfers/{id}/receber
POST /api/rh/payroll-runs/{id}/aprovar
POST /api/assinaturas/{id}/suspender
```

### 11.8 Passo 7 - Aplicar Autenticacao, Autorizacao e Auditoria

**Objetivo:** garantir seguranca operacional.

**Acoes:**

1. Todas as rotas privadas devem exigir token.
2. Todas as rotas sensiveis devem verificar permissao RBAC.
3. Criacao, alteracao, cancelamento, emissao, aprovacao e pagamento devem gerar auditoria.
4. Auditoria deve registrar:

```text
tenant_id
user_id
modulo
entidade
entidade_id
acao
dados_anteriores
dados_novos
created_at
```

**Resultado esperado:** qualquer alteracao importante pode ser rastreada.

### 11.9 Passo 8 - Criar Testes do Modulo

**Objetivo:** provar que o modulo funciona antes de integrar com outros.

**Testes minimos:**

1. Criacao de entidade principal.
2. Listagem filtrada por tenant.
3. Atualizacao permitida.
4. Bloqueio de atualizacao quando estado nao permite.
5. Validacao de campos obrigatorios.
6. Permissao negada quando user nao tem acesso.
7. Auditoria criada em operacao sensivel.

**Testes adicionais para modulos criticos:**

- Stock: entrada, saida, reserva, transferencia e contagem.
- Faturacao: rascunho, emissao, recibo, nota de credito e cancelamento.
- Financeiro: conta a receber, pagamento parcial, pagamento total e vencimento.
- Contabilidade: lancamento balanceado e bloqueio em periodo fechado.
- RH: processamento salarial, aprovacao e pagamento.

### 11.10 Passo 9 - Atualizar Documentacao

**Objetivo:** manter `spec.md` e documentos do modulo alinhados ao codigo.

**Acoes:**

1. Atualizar `api-*.md` se uma rota mudar.
2. Atualizar `database-*.sql` se uma tabela mudar.
3. Atualizar `README.md` se o escopo mudar.
4. Atualizar `spec.md` se houver nova dependencia, regra ou modulo.

**Regra:** codigo nao deve evoluir longe da documentacao.

---

## 12. Passo a Passo por Ordem de Modulos

### 12.1 Primeiro Grupo - Base do ERP

#### 12.1.1 `sistema-configuracao`

**Descricao:** cria configuracoes globais, moedas, taxas de cambio, paises, cidades, idiomas, templates, integracoes e logs.

**Implementar:**

1. Tabelas `settings`, `currencies`, `exchange_rates`, `countries`, `cities`, `languages`.
2. Tabelas `email_templates`, `sms_templates`, `system_logs`, `integrations`, `api_logs`.
3. APIs de configuracoes, moedas, cambio, paises, cidades, idiomas, templates e integracoes.
4. Cache de configuracoes.
5. Protecao de credenciais de integracao.

**Concluido quando:** outros modulos conseguem buscar moeda base, pais/cidade, templates e parametros do tenant.

#### 12.1.2 `empresas`

**Descricao:** cria a estrutura multi-tenant e identifica empresas, filiais e dados fiscais.

**Implementar:**

1. Empresas e dados principais.
2. Filiais.
3. Enderecos e contactos.
4. Documentos e informacao fiscal.
5. Contas bancarias da empresa.
6. Licencas e associacao empresa-utilizador.

**Concluido quando:** existe `company_id`/`tenant_id` confiavel para todos os modulos.

#### 12.1.3 `autenticacao`

**Descricao:** controla login, sessoes, users, password reset e API keys.

**Implementar:**

1. Criacao de utilizador.
2. Login com access token e refresh token.
3. Logout e revogacao de sessao.
4. Recuperacao de password.
5. API keys para integracoes.
6. Historico de login.

**Concluido quando:** qualquer servico consegue identificar `user_id` e `tenant_id`.

#### 12.1.4 `autorizacao`

**Descricao:** controla roles e permissoes.

**Implementar:**

1. Roles por tenant.
2. Permissoes por recurso e acao.
3. Associacao role-permissao.
4. Associacao user-role.
5. Middleware de permissao.

**Concluido quando:** cada endpoint sensivel consegue verificar permissao antes de executar.

#### 12.1.5 `utilizadores`

**Descricao:** controla perfil, preferencias e atividade do utilizador.

**Implementar:**

1. Perfil do utilizador.
2. Preferencias.
3. Notificacoes.
4. Dispositivos.
5. Atividade.
6. Avatar.
7. Configuracoes pessoais.

**Concluido quando:** a UI consegue carregar dados pessoais e preferencias do user.

#### 12.1.6 `auditoria`

**Descricao:** registra eventos de todos os modulos.

**Implementar:**

1. Tabela `audit_logs`.
2. API de consulta.
3. Helper ou client interno para outros servicos gravarem eventos.
4. Filtros por modulo, user, entidade e periodo.

**Concluido quando:** qualquer modulo consegue gravar auditoria sem depender de `seguranca`.

### 12.2 Segundo Grupo - Cadastros Comerciais

#### 12.2.1 `gestao-clientes`

**Descricao:** cadastro completo de clientes, credito, saldos e historico comercial.

**Implementar:** grupos, clientes, contactos, enderecos, documentos, limite de credito, saldos, pagamentos, notas, historico, tags e descontos.

**Concluido quando:** faturacao, CRM e financeiro conseguem referenciar clientes.

#### 12.2.2 `gestao-produtos`

**Descricao:** catalogo de produtos e servicos.

**Implementar:** categorias, marcas, unidades, produtos, variantes, imagens, precos, descontos, codigos de barras, atributos, tags e kits.

**Concluido quando:** POS, faturacao, compras e stock conseguem consultar produto e preco.

#### 12.2.3 `gestao-stock`

**Descricao:** inventario multi-armazem.

**Implementar:** armazens, localizacoes, posicao de stock, movimentos, ajustes, transferencias, reservas, lotes, numeros de serie, contagens e alertas.

**Concluido quando:** compras aumenta stock, vendas baixa stock e relatorios mostram posicao correta.

### 12.3 Terceiro Grupo - Operacao Comercial

#### 12.3.1 `modulo-faturacao`

**Descricao:** ciclo documental de venda.

**Implementar:** series, orcamentos, encomendas, guias, faturas, recibos, notas de credito e devolucoes.

**Concluido quando:** fatura emitida gera conta a receber, baixa stock quando aplicavel e cria lancamento contabilistico.

#### 12.3.2 `pos`

**Descricao:** ponto de venda e caixa.

**Implementar:** terminais, sessoes, vendas, pagamentos, devolucoes, movimentos de caixa e fecho.

**Concluido quando:** uma venda POS reduz stock, registra recebimento e fecha caixa com diferenca calculada.

#### 12.3.3 `compras`

**Descricao:** ciclo de compra e fornecedores.

**Implementar:** fornecedores, requisicoes, ordens, recepcoes, devolucoes, faturas de fornecedor e pagamentos.

**Concluido quando:** recepcao aumenta stock e fatura de fornecedor cria conta a pagar.

#### 12.3.4 `crm`

**Descricao:** funil comercial antes da venda.

**Implementar:** pipelines, leads, oportunidades, contactos, atividades, notas, tags e relatorios.

**Concluido quando:** lead pode virar cliente e oportunidade ganha pode gerar orcamento/fatura.

#### 12.3.5 `logistica`

**Descricao:** entregas e rastreio.

**Implementar:** motoristas, viaturas, rotas, estados, envios, itens, tracking e logs.

**Concluido quando:** guia de remessa pode ser associada a envio e acompanhada ate entrega.

### 12.4 Quarto Grupo - Financeiro e Fiscal

#### 12.4.1 `financeiro`

**Descricao:** contas a receber, contas a pagar, pagamentos, recebimentos e fluxo de caixa.

**Implementar:** meios de pagamento, categorias, pagamentos, recebimentos, receivables, payables, orcamentos e cash flow.

**Concluido quando:** faturacao, compras e assinaturas conseguem registrar dividas e pagamentos.

#### 12.4.2 `tesouraria`

**Descricao:** caixa, bancos e reconciliacao.

**Implementar:** contas bancarias, caixas, movimentos e reconciliacoes.

**Concluido quando:** cada pagamento confirmado altera saldo de caixa/banco de forma atomica.

#### 12.4.3 `contabilidade`

**Descricao:** dupla entrada e relatorios contabilisticos.

**Implementar:** plano de contas, anos fiscais, periodos, journal entries, impostos base, ativos fixos, amortizacoes, orcamentos e encerramentos.

**Concluido quando:** documentos comerciais e financeiros geram lancamentos balanceados.

#### 12.4.4 `impostos`

**Descricao:** regras fiscais avancadas.

**Implementar:** regimes, isencoes, retencoes, declaracoes, linhas e certificados.

**Concluido quando:** imposto calculado pode ser declarado, retido e rastreado.

#### 12.4.5 `multi-moeda`

**Descricao:** conversao cambial e moeda do documento.

**Implementar:** politicas de cambio, conversoes, historico, moeda por documento e arredondamentos.

**Concluido quando:** documentos em moeda estrangeira guardam taxa historica e equivalente em moeda base.

#### 12.4.6 `centros-custo`

**Descricao:** rentabilidade por departamento, projeto ou area.

**Implementar:** centros, orcamentos, alocacoes, movimentos e relatorio orcado vs realizado.

**Concluido quando:** lancamentos podem ser analisados por centro de custo.

### 12.5 Quinto Grupo - Operacoes Internas e SaaS

#### 12.5.1 `recursos-humanos`

**Descricao:** ciclo de vida do colaborador.

**Implementar:** estrutura organizacional, funcionarios, contratos, salarios, beneficios, assiduidade, licencas, folha, avaliacoes, formacoes e disciplina.

**Concluido quando:** folha salarial aprovada gera obrigacoes financeiras e lancamentos contabilisticos.

#### 12.5.2 `assinaturas`

**Descricao:** licencas SaaS e faturacao recorrente.

**Implementar:** gateways, planos, funcionalidades, assinaturas, ciclos, pagamentos, uso, pausas, cancelamentos e eventos.

**Concluido quando:** tenant tem plano ativo, limites aplicados e faturacao recorrente idempotente.

### 12.6 Sexto Grupo - Vertical Escolar

#### 12.6.1 `gestao-escolar`

**Descricao:** operacao academica, financeira e comunicacional de escolas.

**Implementar:** anos lectivos, periodos, turmas, alunos, encarregados, professores, frequencia, notas, propinas, pagamentos, biblioteca, mensagens, relatorios e portais.

**Concluido quando:** escola consegue matricular aluno, lancar notas, cobrar propinas, registrar pagamento e disponibilizar portais.

---

## 13. Nomes de Telas por Modulo

Esta secao define nomes sugeridos para as telas do frontend por modulo. Os nomes podem ser usados no menu lateral, breadcrumbs, permissao de acesso e documentacao funcional.

### 13.1 `sistema-configuracao`

| Tela | Rota sugerida | Descricao |
| --- | --- | --- |
| Dashboard de Configuracao | `/configuracao` | Visao geral das configuracoes do sistema |
| Configuracoes Globais | `/configuracao/settings` | Parametros globais, tenant e utilizador |
| Moedas | `/configuracao/moedas` | Cadastro de moedas activas |
| Taxas de Cambio | `/configuracao/cambios` | Historico de taxas por data |
| Paises | `/configuracao/paises` | Paises de referencia |
| Cidades | `/configuracao/cidades` | Cidades associadas a paises |
| Idiomas | `/configuracao/idiomas` | Idiomas disponiveis na interface |
| Templates de Email | `/configuracao/templates-email` | Modelos de email por codigo |
| Templates de SMS | `/configuracao/templates-sms` | Modelos de SMS por codigo |
| Integracoes | `/configuracao/integracoes` | Configuracoes de gateways e servicos externos |
| Logs do Sistema | `/configuracao/logs-sistema` | Logs internos por modulo |
| Logs de API | `/configuracao/logs-api` | Chamadas de API e tempos de resposta |

### 13.2 `empresas`

| Tela | Rota sugerida | Descricao |
| --- | --- | --- |
| Empresas | `/empresas` | Lista de empresas/tenants |
| Nova Empresa | `/empresas/nova` | Cadastro de empresa |
| Detalhe da Empresa | `/empresas/:id` | Dados gerais da empresa |
| Filiais | `/empresas/:id/filiais` | Filiais da empresa |
| Enderecos da Empresa | `/empresas/:id/enderecos` | Enderecos fiscal, entrega e cobranca |
| Contactos da Empresa | `/empresas/:id/contactos` | Contactos por area |
| Documentos da Empresa | `/empresas/:id/documentos` | Alvaras, licencas e anexos |
| Informacao Fiscal | `/empresas/:id/fiscal` | NUIT, regime e dados fiscais |
| Bancos da Empresa | `/empresas/:id/bancos` | Contas bancarias da empresa |
| Licencas da Empresa | `/empresas/:id/licencas` | Licencas e planos activos |
| Utilizadores da Empresa | `/empresas/:id/utilizadores` | Associacao de users ao tenant |

### 13.3 `autenticacao`

| Tela | Rota sugerida | Descricao |
| --- | --- | --- |
| Login | `/login` | Entrada no sistema |
| Recuperar Password | `/recuperar-password` | Pedido de redefinicao de password |
| Redefinir Password | `/reset-password` | Definicao de nova password por token |
| Verificar Email | `/verificar-email` | Confirmacao de email |
| Alterar Password | `/minha-conta/password` | Alteracao de password autenticada |
| Utilizadores de Acesso | `/auth/utilizadores` | Users de autenticacao |
| Sessoes Activas | `/auth/sessoes` | Dispositivos e sessoes abertas |
| Historico de Login | `/auth/historico-login` | Tentativas de login |
| Chaves de API | `/auth/api-keys` | API keys para integracoes |

### 13.4 `autorizacao`

| Tela | Rota sugerida | Descricao |
| --- | --- | --- |
| Roles | `/autorizacao/roles` | Perfis de acesso |
| Nova Role | `/autorizacao/roles/nova` | Criacao de perfil |
| Permissoes | `/autorizacao/permissoes` | Catalogo de permissoes |
| Permissoes da Role | `/autorizacao/roles/:id/permissoes` | Associacao role-permissao |
| Roles do Utilizador | `/autorizacao/utilizadores/:id/roles` | Perfis atribuidos ao utilizador |
| Matriz de Acessos | `/autorizacao/matriz` | Visao cruzada de roles e permissoes |

### 13.5 `utilizadores`

| Tela | Rota sugerida | Descricao |
| --- | --- | --- |
| Perfis de Utilizador | `/utilizadores/perfis` | Dados pessoais e operacionais |
| Meu Perfil | `/minha-conta/perfil` | Perfil do utilizador autenticado |
| Preferencias | `/minha-conta/preferencias` | Idioma, tema e preferencias |
| Notificacoes | `/minha-conta/notificacoes` | Notificacoes do utilizador |
| Dispositivos | `/minha-conta/dispositivos` | Dispositivos associados |
| Actividade do Utilizador | `/utilizadores/:id/actividade` | Historico de actividade |
| Tokens do Utilizador | `/utilizadores/:id/tokens` | Tokens pessoais |
| Logs de Seguranca | `/utilizadores/:id/logs-seguranca` | Eventos de seguranca do user |
| Avatar | `/minha-conta/avatar` | Imagem do utilizador |

### 13.6 `auditoria`

| Tela | Rota sugerida | Descricao |
| --- | --- | --- |
| Auditoria | `/auditoria` | Lista geral de eventos |
| Detalhe do Evento | `/auditoria/:id` | Detalhes da alteracao |
| Auditoria por Modulo | `/auditoria/modulos` | Filtro por modulo |
| Auditoria por Utilizador | `/auditoria/utilizadores` | Filtro por user |
| Auditoria por Entidade | `/auditoria/entidades` | Filtro por entidade e ID |

### 13.7 `gestao-clientes`

| Tela | Rota sugerida | Descricao |
| --- | --- | --- |
| Clientes | `/clientes` | Lista e pesquisa de clientes |
| Novo Cliente | `/clientes/novo` | Cadastro de cliente |
| Detalhe do Cliente | `/clientes/:id` | Ficha completa do cliente |
| Grupos de Clientes | `/clientes/grupos` | Segmentacao comercial |
| Contactos do Cliente | `/clientes/:id/contactos` | Pessoas de contacto |
| Enderecos do Cliente | `/clientes/:id/enderecos` | Moradas do cliente |
| Documentos do Cliente | `/clientes/:id/documentos` | Anexos e documentos |
| Limite de Credito | `/clientes/:id/credito` | Definicao de limite |
| Saldo do Cliente | `/clientes/:id/saldo` | Valor em aberto e credito disponivel |
| Pagamentos do Cliente | `/clientes/:id/pagamentos` | Pagamentos recebidos |
| Historico do Cliente | `/clientes/:id/historico` | Interacoes e eventos |
| Tags de Clientes | `/clientes/tags` | Etiquetas comerciais |
| Descontos do Cliente | `/clientes/:id/descontos` | Condicoes comerciais |

### 13.8 `gestao-produtos`

| Tela | Rota sugerida | Descricao |
| --- | --- | --- |
| Produtos | `/produtos` | Catalogo de produtos |
| Novo Produto | `/produtos/novo` | Cadastro de produto |
| Detalhe do Produto | `/produtos/:id` | Ficha do produto |
| Categorias | `/produtos/categorias` | Categorias e subcategorias |
| Marcas | `/produtos/marcas` | Marcas comerciais |
| Unidades de Medida | `/produtos/unidades` | Unidades de venda/stock |
| Variantes do Produto | `/produtos/:id/variantes` | Tamanho, cor e combinacoes |
| Imagens do Produto | `/produtos/:id/imagens` | Galeria do produto |
| Precos do Produto | `/produtos/:id/precos` | Listas de preco |
| Descontos do Produto | `/produtos/:id/descontos` | Promocoes e descontos |
| Codigos de Barras | `/produtos/:id/codigos-barras` | EAN, SKU e codigos |
| Atributos de Produto | `/produtos/atributos` | Atributos configuraveis |
| Kits e Composicao | `/produtos/:id/componentes` | Produtos compostos |
| Relatorios de Produtos | `/produtos/relatorios` | Mais vendidos, margem e stock critico |

### 13.9 `gestao-stock`

| Tela | Rota sugerida | Descricao |
| --- | --- | --- |
| Dashboard de Stock | `/stock` | Indicadores de inventario |
| Armazens | `/stock/armazens` | Cadastro de armazens |
| Localizacoes | `/stock/armazens/:id/localizacoes` | Prateleiras, corredores e zonas |
| Posicao de Stock | `/stock/posicao` | Quantidade por produto/armazem |
| Movimentos de Stock | `/stock/movimentos` | Entradas e saidas |
| Ajustes de Stock | `/stock/ajustes` | Ajustes manuais |
| Transferencias | `/stock/transferencias` | Transferencia entre armazens |
| Reservas | `/stock/reservas` | Stock reservado por documento |
| Lotes | `/stock/lotes` | Lotes e validades |
| Numeros de Serie | `/stock/series` | Itens serializados |
| Contagens Fisicas | `/stock/contagens` | Inventario fisico |
| Alertas de Stock | `/stock/alertas` | Minimos, expiracao e divergencias |
| Relatorios de Stock | `/stock/relatorios` | Valorizacao, movimentos e baixo stock |

### 13.10 `modulo-faturacao`

| Tela | Rota sugerida | Descricao |
| --- | --- | --- |
| Dashboard de Faturacao | `/faturacao` | Indicadores de vendas e documentos |
| Series Documentais | `/faturacao/series` | Numeracao por tipo e ano |
| Orcamentos | `/faturacao/orcamentos` | Propostas comerciais |
| Novo Orcamento | `/faturacao/orcamentos/novo` | Criacao de orcamento |
| Encomendas de Venda | `/faturacao/encomendas` | Pedidos aprovados |
| Guias de Remessa | `/faturacao/guias` | Entregas e transporte |
| Faturas | `/faturacao/faturas` | Documentos fiscais |
| Nova Fatura | `/faturacao/faturas/nova` | Criacao de fatura |
| Recibos | `/faturacao/recibos` | Pagamentos recebidos |
| Notas de Credito | `/faturacao/notas-credito` | Creditos e anulacoes |
| Devolucoes de Venda | `/faturacao/devolucoes` | Devolucoes fisicas |
| Faturas Vencidas | `/faturacao/faturas/vencidas` | Saldos em atraso |
| Relatorios de Faturacao | `/faturacao/relatorios` | Vendas, impostos, aging e clientes |

### 13.11 `pos`

| Tela | Rota sugerida | Descricao |
| --- | --- | --- |
| POS | `/pos` | Tela principal de venda |
| Terminais POS | `/pos/terminais` | Configuracao de terminais |
| Abrir Sessao | `/pos/sessoes/abrir` | Abertura de caixa |
| Sessao Activa | `/pos/sessoes/activa` | Operacao do caixa actual |
| Vendas POS | `/pos/vendas` | Historico de vendas |
| Detalhe da Venda POS | `/pos/vendas/:id` | Itens, pagamentos e recibo |
| Pagamentos POS | `/pos/vendas/:id/pagamentos` | Pagamentos multi-metodo |
| Devolucoes POS | `/pos/devolucoes` | Devolucoes no ponto de venda |
| Movimentos de Caixa | `/pos/sessoes/:id/movimentos` | Sangria, reforco e ajuste |
| Fecho de Caixa | `/pos/sessoes/:id/fecho` | Fecho e reconciliacao |
| Relatorios POS | `/pos/relatorios` | Vendas por terminal, hora e sessao |

### 13.12 `compras`

| Tela | Rota sugerida | Descricao |
| --- | --- | --- |
| Dashboard de Compras | `/compras` | Indicadores de compras |
| Fornecedores | `/compras/fornecedores` | Cadastro de fornecedores |
| Novo Fornecedor | `/compras/fornecedores/novo` | Criacao de fornecedor |
| Requisicoes de Compra | `/compras/requisicoes` | Pedidos internos |
| Ordens de Compra | `/compras/ordens` | Compras aprovadas |
| Recepcao de Mercadoria | `/compras/recepcoes` | Entrada contra ordem |
| Devolucoes a Fornecedor | `/compras/devolucoes` | Devolucao de mercadoria |
| Faturas de Fornecedor | `/compras/faturas` | Documentos recebidos |
| Pagamentos a Fornecedor | `/compras/pagamentos` | Pagamentos e imputacoes |
| Saldos de Fornecedor | `/compras/fornecedores/saldos` | Dividas por fornecedor |
| Relatorios de Compras | `/compras/relatorios` | Compras, fornecedores e pendencias |

### 13.13 `financeiro`

| Tela | Rota sugerida | Descricao |
| --- | --- | --- |
| Dashboard Financeiro | `/financeiro` | Resumo financeiro |
| Meios de Pagamento | `/financeiro/meios-pagamento` | Numerario, TPA, M-Pesa e outros |
| Categorias Financeiras | `/financeiro/categorias` | Receitas e despesas |
| Pagamentos e Recebimentos | `/financeiro/pagamentos` | Movimentos financeiros confirmaveis |
| Contas a Receber | `/financeiro/receber` | Dividas de clientes |
| Contas a Pagar | `/financeiro/pagar` | Dividas a fornecedores |
| Recebimentos Vencidos | `/financeiro/receber/vencidas` | Clientes em atraso |
| Pagamentos Vencidos | `/financeiro/pagar/vencidas` | Fornecedores em atraso |
| Orcamentos Financeiros | `/financeiro/orcamentos` | Orcado por categoria e periodo |
| Fluxo de Caixa | `/financeiro/fluxo-caixa` | Realizado e previsto |
| Projecao de Caixa | `/financeiro/fluxo-caixa/projecao` | Saldo futuro |
| Relatorios Financeiros | `/financeiro/relatorios` | DRE, aging, fluxo e orcamento |

### 13.14 `tesouraria`

| Tela | Rota sugerida | Descricao |
| --- | --- | --- |
| Dashboard de Tesouraria | `/tesouraria` | Saldos e movimentos liquidos |
| Contas Bancarias | `/tesouraria/contas-bancarias` | Bancos e saldos |
| Caixas | `/tesouraria/caixas` | Caixas fisicas |
| Movimentos Financeiros | `/tesouraria/movimentos` | Entradas, saidas e transferencias |
| Nova Transferencia | `/tesouraria/transferencias/nova` | Movimento entre caixa/banco |
| Reconciliacao Bancaria | `/tesouraria/reconciliacoes` | Conciliacao por periodo |
| Detalhe da Reconciliacao | `/tesouraria/reconciliacoes/:id` | Itens e diferencas |
| Extratos Financeiros | `/tesouraria/extratos` | Extrato de conta ou caixa |

### 13.15 `contabilidade`

| Tela | Rota sugerida | Descricao |
| --- | --- | --- |
| Dashboard Contabilistico | `/contabilidade` | Indicadores contabilisticos |
| Tipos de Conta | `/contabilidade/tipos-conta` | Natureza debito/credito |
| Plano de Contas | `/contabilidade/plano-contas` | Contas contabilisticas |
| Anos Fiscais | `/contabilidade/anos-fiscais` | Exercicios fiscais |
| Periodos Fiscais | `/contabilidade/periodos` | Meses/trimestres fiscais |
| Lancamentos | `/contabilidade/lancamentos` | Journal entries |
| Novo Lancamento | `/contabilidade/lancamentos/novo` | Lancamento manual |
| Impostos Contabilisticos | `/contabilidade/impostos` | Taxas e regras base |
| Transaccoes de Imposto | `/contabilidade/impostos/transaccoes` | Movimentos de imposto |
| Activos Fixos | `/contabilidade/activos-fixos` | Cadastro de activos |
| Amortizacoes | `/contabilidade/amortizacoes` | Processamento de depreciacao |
| Orcamento Contabilistico | `/contabilidade/orcamentos` | Budget por conta |
| Encerramento de Periodo | `/contabilidade/encerramentos` | Fecho contabilistico |
| Relatorios Contabilisticos | `/contabilidade/relatorios` | Balancete, balanco, DRE e razao |

### 13.16 `impostos`

| Tela | Rota sugerida | Descricao |
| --- | --- | --- |
| Dashboard Fiscal | `/impostos` | Indicadores fiscais |
| Regimes Fiscais | `/impostos/regimes` | Regimes por tenant |
| Isencoes | `/impostos/isencoes` | Isencoes por entidade/produto |
| Retencoes na Fonte | `/impostos/retencoes` | IRPS, IRPC e regras |
| Transaccoes de Retencao | `/impostos/retencoes/transaccoes` | Valores retidos |
| Declaracoes Fiscais | `/impostos/declaracoes` | IVA, IRPS e retencoes |
| Detalhe da Declaracao | `/impostos/declaracoes/:id` | Linhas e submissao |
| Certificados Fiscais | `/impostos/certificados` | Bom contribuinte e isencoes |

### 13.17 `multi-moeda`

| Tela | Rota sugerida | Descricao |
| --- | --- | --- |
| Dashboard Multi-Moeda | `/multi-moeda` | Exposicao cambial |
| Politicas de Cambio | `/multi-moeda/politicas` | Taxa do dia, fixa ou media |
| Conversor de Moeda | `/multi-moeda/conversor` | Conversao pontual |
| Historico de Conversoes | `/multi-moeda/historico` | Conversoes realizadas |
| Moedas por Documento | `/multi-moeda/documentos` | Documentos em moeda estrangeira |
| Regras de Arredondamento | `/multi-moeda/arredondamentos` | Casas decimais e arredondamento |

### 13.18 `centros-custo`

| Tela | Rota sugerida | Descricao |
| --- | --- | --- |
| Centros de Custo | `/centros-custo` | Lista e hierarquia |
| Novo Centro de Custo | `/centros-custo/novo` | Criacao de centro |
| Detalhe do Centro de Custo | `/centros-custo/:id` | Dados, filhos e movimentos |
| Orcamentos por Centro | `/centros-custo/:id/orcamentos` | Orcado por periodo |
| Alocacoes | `/centros-custo/:id/alocacoes` | Lancamentos alocados |
| Movimentos do Centro | `/centros-custo/:id/movimentos` | Realizado por centro |
| Relatorio Orcado vs Realizado | `/centros-custo/relatorios/orcado-realizado` | Comparativo por periodo |

### 13.19 `crm`

| Tela | Rota sugerida | Descricao |
| --- | --- | --- |
| Dashboard CRM | `/crm` | KPIs comerciais |
| Pipelines | `/crm/pipelines` | Funis comerciais |
| Etapas do Pipeline | `/crm/pipelines/:id/etapas` | Stages por pipeline |
| Leads | `/crm/leads` | Prospects e qualificacao |
| Novo Lead | `/crm/leads/novo` | Cadastro de lead |
| Oportunidades | `/crm/oportunidades` | Negocios em aberto |
| Kanban de Oportunidades | `/crm/oportunidades/kanban` | Pipeline visual |
| Contactos CRM | `/crm/contactos` | Contactos comerciais |
| Actividades CRM | `/crm/actividades` | Chamadas, reunioes e tarefas |
| Notas CRM | `/crm/notas` | Notas internas |
| Relatorios CRM | `/crm/relatorios` | Funil, pipeline e previsao |

### 13.20 `recursos-humanos`

| Tela | Rota sugerida | Descricao |
| --- | --- | --- |
| Dashboard RH | `/rh` | Indicadores de pessoas |
| Organograma | `/rh/organograma` | Estrutura organizacional |
| Departamentos | `/rh/departamentos` | Nos organizacionais |
| Cargos | `/rh/cargos` | Posicoes e grades |
| Horarios de Trabalho | `/rh/horarios` | Escalas e carga horaria |
| Funcionarios | `/rh/funcionarios` | Lista de colaboradores |
| Novo Funcionario | `/rh/funcionarios/novo` | Admissao |
| Ficha do Funcionario | `/rh/funcionarios/:id` | Dados completos |
| Contratos | `/rh/contratos` | Contratos de trabalho |
| Salarios | `/rh/salarios` | Historico salarial |
| Beneficios | `/rh/beneficios` | Beneficios por funcionario |
| Assiduidade | `/rh/assiduidade` | Presencas e ausencias |
| Horas Extra | `/rh/horas-extra` | Pedidos e aprovacao |
| Ferias e Licencas | `/rh/licencas` | Saldos e pedidos |
| Processamento Salarial | `/rh/folha` | Folhas mensais |
| Recibos de Vencimento | `/rh/recibos` | Payslips |
| Avaliacoes | `/rh/avaliacoes` | Desempenho |
| Formacoes | `/rh/formacoes` | Desenvolvimento |
| Processos Disciplinares | `/rh/disciplina` | Disciplina e sancoes |
| Relatorios RH | `/rh/relatorios` | Headcount, massa salarial e licencas |

### 13.21 `logistica`

| Tela | Rota sugerida | Descricao |
| --- | --- | --- |
| Dashboard de Logistica | `/logistica` | Entregas e atrasos |
| Motoristas | `/logistica/motoristas` | Cadastro de motoristas |
| Viaturas | `/logistica/viaturas` | Frota |
| Rotas de Entrega | `/logistica/rotas` | Origem e destino |
| Estados de Envio | `/logistica/estados` | Workflow de entrega |
| Envios | `/logistica/envios` | Lista de envios |
| Novo Envio | `/logistica/envios/novo` | Criacao de envio |
| Detalhe do Envio | `/logistica/envios/:id` | Itens, rota e estado |
| Tracking de Entrega | `/logistica/envios/:id/tracking` | Coordenadas e eventos |
| Logs de Entrega | `/logistica/logs` | Historico de eventos |

### 13.22 `assinaturas`

| Tela | Rota sugerida | Descricao |
| --- | --- | --- |
| Dashboard SaaS | `/assinaturas` | MRR, ARR, churn e inadimplencia |
| Gateways de Pagamento | `/assinaturas/gateways` | M-Pesa, e-Mola, Stripe e outros |
| Planos | `/assinaturas/planos` | Planos SaaS |
| Funcionalidades do Plano | `/assinaturas/planos/:id/features` | Features por plano |
| Assinaturas | `/assinaturas/subscricoes` | Subscricoes por tenant |
| Detalhe da Assinatura | `/assinaturas/subscricoes/:id` | Estado, plano e limites |
| Ciclos de Faturacao | `/assinaturas/subscricoes/:id/ciclos` | Ciclos recorrentes |
| Pagamentos da Assinatura | `/assinaturas/subscricoes/:id/pagamentos` | Pagamentos por gateway |
| Uso da Assinatura | `/assinaturas/subscricoes/:id/uso` | Consumo por metrica |
| Eventos da Assinatura | `/assinaturas/subscricoes/:id/eventos` | Audit trail da licenca |
| Inadimplentes | `/assinaturas/inadimplentes` | Assinaturas em atraso |
| Relatorios SaaS | `/assinaturas/relatorios` | MRR, ARR, churn e renovacoes |

### 13.23 `gestao-escolar`

| Tela | Rota sugerida | Descricao |
| --- | --- | --- |
| Dashboard Escolar | `/escolar` | Indicadores da escola |
| Anos Lectivos | `/escolar/anos-lectivos` | Anos e estados |
| Periodos Lectivos | `/escolar/periodos` | Trimestres/semestres |
| Turmas | `/escolar/turmas` | Turmas, salas e turnos |
| Horarios Escolares | `/escolar/horarios` | Horarios por turma |
| Calendario Escolar | `/escolar/calendario` | Eventos escolares |
| Disciplinas | `/escolar/disciplinas` | Catalogo academico |
| Professores | `/escolar/professores` | Cadastro de professores |
| Atribuicoes de Professores | `/escolar/professores/atribuicoes` | Professor por turma/disciplina |
| Alunos | `/escolar/alunos` | Cadastro de alunos |
| Novo Aluno | `/escolar/alunos/novo` | Matricula inicial |
| Encarregados | `/escolar/encarregados` | Responsaveis por aluno |
| Matriculas | `/escolar/matriculas` | Matriculas e rematriculas |
| Transferencias | `/escolar/transferencias` | Transferencia de aluno |
| Cargos de Alunos | `/escolar/cargos/alunos` | Chefe de turma e outros |
| Cargos de Professores | `/escolar/cargos/professores` | Director de turma/ciclo |
| Frequencia | `/escolar/frequencia` | Presencas por aula |
| Avaliacoes | `/escolar/avaliacoes` | Provas e trabalhos |
| Lancamento de Notas | `/escolar/notas` | Notas por aluno |
| Boletins | `/escolar/boletins` | Boletim por periodo |
| Planos de Propina | `/escolar/financeiro/planos` | Mensalidades e taxas |
| Cobrancas de Alunos | `/escolar/financeiro/cobrancas` | Propinas, matriculas e taxas |
| Pagamentos Escolares | `/escolar/financeiro/pagamentos` | Pagamentos e callbacks |
| Recibos Escolares | `/escolar/financeiro/recibos` | Recibos digitais |
| Biblioteca | `/escolar/biblioteca` | Catalogo de livros |
| Emprestimos da Biblioteca | `/escolar/biblioteca/emprestimos` | Emprestimos e devolucoes |
| Comunicados | `/escolar/comunicados` | Mensagens e circulares |
| Incidentes Disciplinares | `/escolar/incidentes` | Ocorrencias e sancoes |
| Relatorios Escolares | `/escolar/relatorios` | Academico, financeiro e inadimplencia |
| Portal do Aluno | `/portal/aluno` | Consulta do aluno |
| Portal do Professor | `/portal/professor` | Diario, notas e frequencia |
| Portal do Encarregado | `/portal/encarregado` | Acompanhamento do educando |

### 13.24 `seguranca`

`seguranca` nao deve ter telas novas. O menu deve redirecionar para:

- Autenticacao
- Autorizacao
- Auditoria
- Utilizadores

---

## 14. Checklist de Conclusao por Modulo

Antes de marcar qualquer modulo como concluido, validar:

- O modulo tem migration executavel.
- Todas as tabelas principais existem.
- Todas as entidades possuem isolamento por tenant quando aplicavel.
- Endpoints do `api-*.md` foram implementados ou justificados.
- Requisitos funcionais principais foram cobertos.
- Requisitos nao funcionais criticos foram cobertos.
- Permissoes RBAC foram aplicadas.
- Auditoria foi aplicada nas operacoes sensiveis.
- Estados de documentos/processos foram respeitados.
- Integracoes com modulos dependentes foram testadas.
- Erros possuem resposta padronizada.
- Listagens possuem filtros e paginacao quando necessario.
- Testes basicos foram executados.
- Documentacao foi atualizada.

---

## 15. Estrutura do Projeto

```text
nexora ERP/
  assinaturas/
  auditoria/
  autenticacao/
  autorizacao/
  centros-custo/
  compras/
  contabilidade/
  crm/
  empresas/
  financeiro/
  gestao-clientes/
  gestao-escolar/
    submodulos/
  gestao-produtos/
  gestao-stock/
  impostos/
  logistica/
  modulo-faturacao/
  multi-moeda/
  pos/
  recursos-humanos/
  seguranca/                 # historico/descontinuado
  sistema-configuracao/
  tesouraria/
  utilizadores/
```

Cada modulo deve manter pelo menos:

- `README.md`
- `requisitos.md`
- `api-*.md`
- `database-*.sql` ou `database.sql`
- `uml.md`

Quando necessario:

- `views-*.sql`
- `funcoes-*.sql`
- `dependencias-*.md`
- scripts auxiliares de hierarquia ou relatorio.

---

## 16. Criterios de Aceitacao Global

- Todos os modulos ativos documentados em `nexora ERP` estao refletidos nesta especificacao.
- O modulo `seguranca` esta tratado como historico e nao como dependencia nova.
- Dependencias criticas entre modulos estao explicitas.
- Endpoints principais por modulo estao mapeados.
- Entidades principais por modulo estao listadas.
- Regras transversais de tenant, auditoria, documentos, stock e financeiro estao definidas.
- O plano de desenvolvimento segue a ordem de dependencias do ERP.

---

## 17. Referencias Internas

- `nexora ERP/*/README.md`
- `nexora ERP/*/requisitos.md`
- `nexora ERP/*/api-*.md`
- `nexora ERP/*/database-*.sql`
- `nexora ERP/modulo-faturacao/database.sql`
- `nexora ERP/gestao-escolar/submodulos/*`

---

## 18. Aplicacao Mobile — Nexora ERP Android

**Diretorio:** `nexora-mobile/`  
**Plataforma:** Android (Kotlin, minSdk 24, targetSdk 36)  
**Stack:** View Binding, ViewPager2, CardView, ConstraintLayout, Material3

---

### 18.1 Fluxo de Entrada

```text
Launcher
    └── SplashActivity
            ├── [primeira execucao]  → OnboardingActivity → LoginActivity
            └── [execucao seguinte]  → LoginActivity
                                              └── MainActivity
```

A preferencia `onboarding_complete` e armazenada em `SharedPreferences` ("nexora_prefs") para controlar o fluxo pos-splash.

---

### 18.2 Splash Screen

**Activity:** `SplashActivity`  
**Layout:** `activity_splash.xml`  
**Tema:** `Theme.Nexoramobile.Splash` (fundo `primary_blue`, status bar e navigation bar azuis)

**Animacoes (PropertyAnimator):**

| Elemento | Animacao | Duracao | Interpolador |
| --- | --- | --- | --- |
| Logo (`llLogo`) | ScaleX + ScaleY 0.3→1 + Alpha 0→1 | 700 ms | OvershootInterpolator(1.5) |
| Tagline (`tvTagline`) | TranslationY 30→0 + Alpha 0→1 | 500 ms | AccelerateDecelerateInterpolator |
| Dots (`llDots`) | Alpha 0→1 | 400 ms | default |

**Navegacao:** apos 2800 ms, navega para `OnboardingActivity` ou `LoginActivity` com transicao `fade_in/fade_out`.

---

### 18.3 Onboarding

**Activity:** `OnboardingActivity`  
**Layout:** `activity_onboarding.xml`  
**Adapter:** `OnboardingAdapter` (RecyclerView.Adapter com `ItemOnboardingPageBinding`)  
**Item:** `item_onboarding_page.xml`

**Paginas:**

| # | Titulo | Descricao | Tint |
| --- | --- | --- | --- |
| 1 | Manage Your Business | ERP completo para empresas mocambicanas | `#2563EB` (azul) |
| 2 | Real-Time Insights | Dashboards e relatorios em tempo real | `#7C3AED` (violeta) |
| 3 | Collaborate & Scale | Multi-utilizador, multi-filial, RBAC | `#059669` (verde) |
| 4 | Built for Mozambique | Suporte nativo a MZN, M-Pesa, e-Mola, NUIT e legislacao fiscal local | `#D97706` (ambar) |

**Indicadores de pagina:**

- Activo: pilula horizontal (24 dp × 8 dp), fundo `bg_indicator_active` (`#2563EB`)
- Inactivo: circulo (8 dp × 8 dp), fundo `bg_indicator_inactive` (`#D1D5DB`)
- IDs: `indicator0`, `indicator1`, `indicator2`, `indicator3`
- Animacao: `layoutParams.width` atualizado + `requestLayout()` a cada `onPageSelected`

**Controlos:**

| Elemento | Comportamento |
| --- | --- |
| `tvSkip` | Visivel nas paginas 1-2; invisivel na pagina 3; navega para Login |
| `btnNext` | Texto "Next" nas paginas 1-2; "Get Started" na pagina 3 |
| Swipe | ViewPager2 com gestos nativos |

**Conclusao:** grava `onboarding_complete = true`, navega para `LoginActivity` com transicao `slide_in_left/slide_out_right`.

---

### 18.4 Login

**Activity:** `LoginActivity`  
**Layout:** `activity_login.xml`

**Campos:**

| Campo | Tipo | ID |
| --- | --- | --- |
| Organization | Spinner | `spinnerOrganization` |
| Email | EditText (textEmailAddress) | `etEmail` |
| Password | EditText (textPassword) | `etPassword` |
| Toggle password | ImageView | `ivTogglePassword` |
| Remember me | CheckBox | `cbRememberMe` |
| Forgot password | TextView | `tvForgotPassword` |
| Enter | Button | `btnEnter` |
| Google | Button | `btnGoogle` |
| Microsoft | Button | `btnMicrosoft` |
| Contact admin | TextView | `tvContactAdmin` |

**Comportamento:**

- Toggle de password alterna entre `PasswordTransformationMethod` e `HideReturnsTransformationMethod`.
- Botao Enter valida email e password nao vazios antes de navegar para `MainActivity`.

---

### 18.5 Drawables Criados

| Ficheiro | Uso |
| --- | --- |
| `bg_input_field.xml` | Fundo branco com borda cinza e cantos 12 dp para campos de input |
| `bg_social_button.xml` | Fundo branco com borda cinza e cantos 12 dp para botoes sociais |
| `bg_dot_active.xml` | Circulo branco para dots activos no splash |
| `bg_dot_inactive.xml` | Circulo branco 50% transparente para dots inactivos no splash |
| `bg_indicator_active.xml` | Pilula azul para indicador activo do onboarding |
| `bg_indicator_inactive.xml` | Circulo cinza para indicadores inactivos do onboarding |
| `bg_onboarding_circle.xml` | Circulo de fundo para ilustracao do onboarding (`#EFF6FF`) |
| `ic_google.xml` | Icone Google multicolor (vector) |
| `ic_microsoft.xml` | Icone Microsoft 4-quadrantes (vector) |

---

### 18.6 Dependencias Android

| Biblioteca | Versao | Uso |
| --- | --- | --- |
| `androidx.cardview:cardview` | 1.0.0 | Card do formulario de login |
| `androidx.viewpager2:viewpager2` | 1.1.0 | Slides do onboarding |

**View Binding:** activado em `build.gradle.kts` via `buildFeatures { viewBinding = true }`.

Classes geradas:

| Layout | Classe de Binding |
| --- | --- |
| `activity_splash.xml` | `ActivitySplashBinding` |
| `activity_onboarding.xml` | `ActivityOnboardingBinding` |
| `item_onboarding_page.xml` | `ItemOnboardingPageBinding` |
| `activity_login.xml` | `ActivityLoginBinding` |
| `activity_main.xml` | `ActivityMainBinding` |

---

### 18.7 Regras e Decisoes

- `SplashActivity` e declarada como `LAUNCHER` no `AndroidManifest.xml`; `MainActivity` e `LoginActivity` sao `exported="false"`.
- Todas as activities usam `screenOrientation="portrait"` para consistencia visual.
- A `LoginActivity` usa `windowSoftInputMode="adjustResize"` para evitar sobreposicao do teclado.
- O fluxo de onboarding e de uso unico: apos concluido, o splash salta directamente para o login.
- Nao existe retrocesso para o onboarding apos conclusao (sem entrada no back stack).

---

## Conclusao

Esta especificacao consolida o Nexora ERP como plataforma modular, multi-tenant e extensivel. O arquivo `spec.md` passa a representar os modulos reais existentes no diretorio `nexora ERP`, com responsabilidades, dependencias, APIs, entidades e regras de integracao por modulo.
