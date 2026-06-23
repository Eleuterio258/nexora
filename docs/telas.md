# Nexora ERP - Mapa Geral de Telas

**Arquivo:** `D:\projecto\e-258tech\2026\factPro\telas.md`  
**Referencia:** `spec.md`, secao `13. Nomes de Telas por Modulo`  
**Objetivo:** listar as telas principais do frontend por modulo, com rotas sugeridas e descricao resumida.

---

## 1. Visao Geral

Este documento organiza as telas do Nexora ERP por modulo funcional. Ele deve ser usado como base para:

- menu lateral;
- breadcrumbs;
- permissao de acesso por tela;
- planejamento de frontend;
- criacao de rotas;
- desenho de wireframes;
- criacao de componentes por modulo.

Cada tela deve respeitar:

- autenticacao quando for privada;
- permissao RBAC quando for administrativa;
- filtro por `tenant_id` ou `company_id`;
- auditoria quando a tela executar acao sensivel;
- padrao visual consistente entre modulos.

Os detalhes completos por microsservico ficam em:

```text
nexora-erp/services/<nome-do-service>/telas.md
```

O indice de services fica em:

```text
nexora-erp/services/telas.md
```

### 1.1 Divisao de Menus por Escopo

O frontend deve separar menus de **Super Admin** e menus de **Tenant**. O mesmo service pode ter telas nos dois escopos, mas as rotas, permissoes e filtros devem ser diferentes.

#### Menu Super Admin

| Grupo | Modulos/Telas | Rotas sugeridas |
| --- | --- | --- |
| Plataforma | Dashboard, diagnostico, logs e configuracoes globais | `/super-admin`, `/super-admin/configuracao`, `/super-admin/logs` |
| Tenants | Empresas, filiais, estado, licencas e admins iniciais | `/super-admin/tenants`, `/super-admin/tenants/:id` |
| Planos SaaS | Planos, funcionalidades, limites, assinaturas e inadimplencia | `/super-admin/assinaturas`, `/super-admin/planos` |
| Acesso Global | Super admins, roles globais, permissoes globais e matriz | `/super-admin/auth`, `/super-admin/autorizacao` |
| Auditoria Global | Eventos de plataforma, suporte e acoes entre tenants | `/super-admin/auditoria` |
| Comunicacoes | Templates globais, canais, fila e historico global | `/super-admin/notificacoes` |

#### Menu Tenant

| Grupo | Modulos/Telas | Rotas sugeridas |
| --- | --- | --- |
| Administracao | Configuracoes locais, empresa, filiais, utilizadores, roles e auditoria | `/configuracao`, `/empresas`, `/auth`, `/autorizacao`, `/auditoria` |
| Cadastros | Clientes, produtos e stock | `/clientes`, `/produtos`, `/stock` |
| Comercial | Faturacao, POS, compras, CRM e logistica | `/faturacao`, `/pos`, `/compras`, `/crm`, `/logistica` |
| Financeiro | Financeiro, tesouraria, contabilidade, impostos, multi-moeda e centros de custo | `/financeiro`, `/tesouraria`, `/contabilidade`, `/impostos`, `/multi-moeda`, `/centros-custo` |
| Operacao Interna | RH, notificacoes e relatorios internos | `/rh`, `/notificacoes`, `/relatorios` |
| Vertical Escolar | Gestao escolar e portais | `/escolar`, `/portal/aluno`, `/portal/professor`, `/portal/encarregado` |

#### Regras de UI por Escopo

- Super Admin usa rotas prefixadas por `/super-admin`.
- Tenant usa as rotas operacionais atuais.
- A troca de tenant no Super Admin deve exigir permissao e registrar auditoria.
- Tenant Admin nunca deve ver seletor global de tenants.
- Telas de suporte devem mostrar claramente quando o Super Admin esta acessando um tenant.

---

## 2. Ordem Recomendada de Implementacao das Telas

1. Telas publicas de autenticacao.
2. Telas base de sistema e empresa.
3. Telas administrativas de utilizadores, roles e auditoria.
4. Telas de clientes, produtos e stock.
5. Telas comerciais de faturacao, POS, compras, CRM e logistica.
6. Telas financeiras, fiscais e contabilisticas.
7. Telas de RH, assinaturas e gestao escolar.

---

## 3. Telas por Modulo

### 3.1 Sistema e Configuracao

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
| Integracoes | `/configuracao/integracoes` | Gateways e servicos externos |
| Logs do Sistema | `/configuracao/logs-sistema` | Logs internos por modulo |
| Logs de API | `/configuracao/logs-api` | Chamadas de API e tempos de resposta |

### 3.2 Empresas

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

### 3.3 Autenticacao

| Tela | Rota sugerida | Descricao |
| --- | --- | --- |
| Login | `/login` | Entrada no sistema |
| Recuperar Password | `/recuperar-password` | Pedido de redefinicao de password |
| Redefinir Password | `/reset-password` | Nova password por token |
| Verificar Email | `/verificar-email` | Confirmacao de email |
| Minha Conta | `/minha-conta` | Dados do utilizador autenticado |
| Alterar Password | `/minha-conta/password` | Alteracao de password autenticada |
| Utilizadores de Acesso | `/auth/utilizadores` | Users de autenticacao |
| Novo Utilizador | `/auth/utilizadores/novo` | Criacao de user |
| Detalhe do Utilizador | `/auth/utilizadores/:id` | Consulta e estado do user |
| Sessoes Activas | `/auth/sessoes` | Dispositivos e sessoes abertas |
| Historico de Login | `/auth/historico-login` | Tentativas de login |
| Chaves de API | `/auth/api-keys` | API keys para integracoes |
| Nova Chave de API | `/auth/api-keys/nova` | Criacao de API key |
| Detalhe da Chave de API | `/auth/api-keys/:id` | Metadados e revogacao |

### 3.4 Autorizacao

| Tela | Rota sugerida | Descricao |
| --- | --- | --- |
| Roles | `/autorizacao/roles` | Perfis de acesso |
| Nova Role | `/autorizacao/roles/nova` | Criacao de perfil |
| Permissoes | `/autorizacao/permissoes` | Catalogo de permissoes |
| Permissoes da Role | `/autorizacao/roles/:id/permissoes` | Associacao role-permissao |
| Roles do Utilizador | `/autorizacao/utilizadores/:id/roles` | Perfis atribuidos ao utilizador |
| Matriz de Acessos | `/autorizacao/matriz` | Visao cruzada de roles e permissoes |

### 3.5 Utilizadores

| Tela | Rota sugerida | Descricao |
| --- | --- | --- |
| Perfis de Utilizador | `/utilizadores/perfis` | Dados pessoais e operacionais |
| Meu Perfil | `/minha-conta/perfil` | Perfil do utilizador autenticado |
| Preferencias | `/minha-conta/preferencias` | Idioma, tema e preferencias |
| Notificacoes | `/minha-conta/notificacoes` | Notificacoes do utilizador |
| Dispositivos | `/minha-conta/dispositivos` | Dispositivos associados |
| Actividade do Utilizador | `/utilizadores/:id/actividade` | Historico de actividade |
| Tokens do Utilizador | `/utilizadores/:id/tokens` | Tokens pessoais |
| Logs de Seguranca | `/utilizadores/:id/logs-seguranca` | Eventos de seguranca |
| Avatar | `/minha-conta/avatar` | Imagem do utilizador |

### 3.6 Auditoria

| Tela | Rota sugerida | Descricao |
| --- | --- | --- |
| Auditoria | `/auditoria` | Lista geral de eventos |
| Detalhe do Evento | `/auditoria/:id` | Detalhes da alteracao |
| Auditoria por Modulo | `/auditoria/modulos` | Filtro por modulo |
| Auditoria por Utilizador | `/auditoria/utilizadores` | Filtro por user |
| Auditoria por Entidade | `/auditoria/entidades` | Filtro por entidade e ID |

### 3.7 Gestao de Clientes

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

### 3.8 Gestao de Produtos

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

### 3.9 Gestao de Stock

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

### 3.10 Faturacao

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

### 3.11 POS

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

### 3.12 Compras

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

### 3.13 Financeiro

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

### 3.14 Tesouraria

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

### 3.15 Contabilidade

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

### 3.16 Impostos

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

### 3.17 Multi-Moeda

| Tela | Rota sugerida | Descricao |
| --- | --- | --- |
| Dashboard Multi-Moeda | `/multi-moeda` | Exposicao cambial |
| Politicas de Cambio | `/multi-moeda/politicas` | Taxa do dia, fixa ou media |
| Conversor de Moeda | `/multi-moeda/conversor` | Conversao pontual |
| Historico de Conversoes | `/multi-moeda/historico` | Conversoes realizadas |
| Moedas por Documento | `/multi-moeda/documentos` | Documentos em moeda estrangeira |
| Regras de Arredondamento | `/multi-moeda/arredondamentos` | Casas decimais e arredondamento |

### 3.18 Centros de Custo

| Tela | Rota sugerida | Descricao |
| --- | --- | --- |
| Centros de Custo | `/centros-custo` | Lista e hierarquia |
| Novo Centro de Custo | `/centros-custo/novo` | Criacao de centro |
| Detalhe do Centro de Custo | `/centros-custo/:id` | Dados, filhos e movimentos |
| Orcamentos por Centro | `/centros-custo/:id/orcamentos` | Orcado por periodo |
| Alocacoes | `/centros-custo/:id/alocacoes` | Lancamentos alocados |
| Movimentos do Centro | `/centros-custo/:id/movimentos` | Realizado por centro |
| Relatorio Orcado vs Realizado | `/centros-custo/relatorios/orcado-realizado` | Comparativo por periodo |

### 3.19 CRM

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

### 3.20 Recursos Humanos

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

### 3.21 Logistica

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

### 3.22 Assinaturas

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

### 3.23 Gestao Escolar

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

### 3.24 Seguranca

`seguranca` nao deve ter telas novas. O menu deve redirecionar para:

- Autenticacao
- Autorizacao
- Auditoria
- Utilizadores

---

## 4. Agrupamento Sugerido do Menu

| Grupo de Menu | Telas principais |
| --- | --- |
| Inicio | Dashboards principais |
| Administracao | Empresas, Configuracao, Utilizadores, Autorizacao, Auditoria |
| Comercial | Clientes, CRM, Faturacao |
| Operacao | Produtos, Stock, Compras, POS, Logistica |
| Financeiro | Financeiro, Tesouraria, Contabilidade, Impostos, Multi-Moeda, Centros de Custo |
| Pessoas | Recursos Humanos |
| SaaS | Assinaturas |
| Escolar | Gestao Escolar e Portais |

---

## 5. Criterios para Criar Cada Tela

- A tela deve ter titulo claro e breadcrumb.
- Listagens devem ter filtros, pesquisa e paginacao.
- Formularios devem validar campos obrigatorios antes de enviar.
- Acoes sensiveis devem pedir confirmacao.
- Estados devem aparecer com badge visual.
- Erros de API devem ser exibidos de forma legivel.
- Cada tela privada deve verificar permissao.
- Telas de detalhe devem exibir auditoria ou historico quando aplicavel.
- Relatorios devem permitir filtro por periodo e exportacao quando necessario.
