# Prompt - Telas de Gestao de Clientes

Use este prompt para gerar ou implementar as telas do modulo **Gestao de Clientes** do Nexora ERP.

---

## Prompt Principal

Crie o modulo frontend **Gestao de Clientes** para o Nexora ERP, seguindo uma interface empresarial, limpa, responsiva e orientada a produtividade.

O modulo deve permitir cadastrar, consultar, editar, bloquear, desbloquear e analisar clientes. Deve tambem gerir grupos, contactos, enderecos, documentos, limite de credito, saldo, pagamentos, historico, tags, descontos, aging e relatorios.

A experiencia deve parecer um ERP profissional: menus claros, tabelas densas mas legiveis, filtros eficientes, formularios organizados por secoes, abas no detalhe do cliente, estados visuais e acoes sensiveis com confirmacao.

---

## Contexto do Modulo

**Modulo:** Gestao de Clientes  
**Service:** `clientes-service`  
**Base API:** `/api/clientes`  
**Escopo:** Tenant/Empresa  
**Isolamento:** todas as listagens e acoes devem respeitar `tenant_id` ou `company_id`.  
**Auditoria:** bloquear, desbloquear, alterar credito, editar dados fiscais e registrar pagamentos devem gerar auditoria.

O modulo alimenta:

- Faturacao;
- Financeiro;
- Tesouraria;
- CRM;
- Assinaturas;
- Impostos;
- Notificacoes;
- Auditoria.

---

## Telas Obrigatorias

| Ordem | Tela | Rota | Endpoint |
| --- | --- | --- | --- |
| 1 | Dashboard de Clientes | `/clientes/dashboard` | `GET /api/clientes/reports/summary` |
| 2 | Clientes | `/clientes` | `GET /api/clientes` |
| 3 | Novo Cliente | `/clientes/novo` | `POST /api/clientes` |
| 4 | Detalhe do Cliente | `/clientes/:id` | `GET /api/clientes/:id` |
| 5 | Grupos de Clientes | `/clientes/grupos` | `GET /api/clientes/grupos` |
| 6 | Novo Grupo | `/clientes/grupos/novo` | `POST /api/clientes/grupos` |
| 7 | Contactos do Cliente | `/clientes/:id/contactos` | `/api/clientes/:id/contactos` |
| 8 | Enderecos do Cliente | `/clientes/:id/enderecos` | `/api/clientes/:id/enderecos` |
| 9 | Documentos do Cliente | `/clientes/:id/documentos` | `/api/clientes/:id/documentos` |
| 10 | Limite de Credito | `/clientes/:id/credito` | `/api/clientes/:id/limite-credito` |
| 11 | Saldo do Cliente | `/clientes/:id/saldo` | `/api/clientes/:id/saldo` |
| 12 | Pagamentos do Cliente | `/clientes/:id/pagamentos` | `/api/clientes/:id/pagamentos` |
| 13 | Historico do Cliente | `/clientes/:id/historico` | `/api/clientes/:id/historico` |
| 14 | Tags de Clientes | `/clientes/tags` | `/api/clientes/tags` |
| 15 | Descontos do Cliente | `/clientes/:id/descontos` | `/api/clientes/:id/descontos` |
| 16 | Aging de Clientes | `/clientes/aging` | `GET /api/clientes/reports/aging` |
| 17 | Relatorios de Clientes | `/clientes/relatorios` | `/api/clientes/reports/*` |

---

## Layout Geral

### Navegacao

Criar menu lateral ou submenu do modulo com:

- Dashboard;
- Clientes;
- Grupos;
- Tags;
- Aging;
- Relatorios.

No detalhe do cliente, usar abas:

- Dados gerais;
- Contactos;
- Enderecos;
- Documentos;
- Credito;
- Saldo;
- Pagamentos;
- Faturas;
- CRM;
- Historico;
- Tags;
- Descontos;
- Auditoria.

### Padrao Visual

- Interface empresarial e objetiva.
- Cards de KPI apenas no dashboard e detalhe.
- Tabelas com filtros no topo.
- Formularios em secoes.
- Acoes destrutivas ou sensiveis com modal de confirmacao.
- Badges para estados.
- Valores monetarios alinhados a direita.
- Datas em formato local.
- Componentes responsivos para desktop e tablet.

---

## Tela 1 - Dashboard de Clientes

Criar uma tela com resumo comercial e financeiro.

### KPIs

- Total de clientes ativos.
- Novos clientes no periodo.
- Clientes bloqueados.
- Saldo total em aberto.
- Clientes acima do limite de credito.
- Clientes sem compra recente.
- Top clientes por receita.
- Top clientes por atraso.

### Componentes

- Cards de indicadores.
- Grafico de clientes por grupo.
- Ranking de saldos.
- Lista de clientes com credito excedido.
- Lista de clientes sem contacto recente.

### Filtros

- Periodo.
- Grupo.
- Estado.
- Vendedor.
- Com saldo em aberto.

---

## Tela 2 - Clientes

Criar uma listagem principal de clientes.

### Filtros

- Grupo.
- Estado.
- Nome.
- Codigo.
- Email.
- Telefone.
- NUIT.
- Com saldo em aberto.
- Com credito bloqueado.

### Colunas

- Codigo.
- Nome.
- NUIT.
- Email.
- Telefone.
- Grupo.
- Estado.
- Saldo.
- Credito disponivel.

### Acoes

- Novo cliente.
- Abrir detalhe.
- Ativar.
- Bloquear.
- Desbloquear.
- Exportar.

### Estados Visuais

- `ativo`: verde.
- `inativo`: cinza.
- `bloqueado`: vermelho.
- `credito_excedido`: laranja.

---

## Tela 3 - Novo Cliente

Criar formulario de cadastro de cliente.

### Campos

- Codigo.
- Nome.
- Nome comercial.
- Tipo.
- NUIT.
- Email.
- Telefone.
- Grupo.
- Vendedor responsavel.
- Moeda padrao.
- Condicao de pagamento.
- Estado.

### Tipos de Cliente

- Individual.
- Empresa.
- Instituicao.
- Governo.

### Acoes

- Guardar.
- Guardar e abrir detalhe.
- Guardar e criar fatura.
- Cancelar.

### Validacoes

- Nome e obrigatorio.
- NUIT deve ser unico quando informado.
- Email deve ter formato valido.
- Telefone deve aceitar formato local.

---

## Tela 4 - Detalhe do Cliente

Criar ficha completa do cliente.

### Cabecalho

Mostrar:

- Nome do cliente.
- Codigo.
- Estado.
- Grupo.
- Saldo em aberto.
- Credito disponivel.
- Ultima compra.
- Ultimo pagamento.

### Acoes no Cabecalho

- Editar.
- Bloquear.
- Desbloquear.
- Criar fatura.
- Criar oportunidade CRM.
- Registrar pagamento.
- Enviar aviso.

### Abas

Implementar as abas:

- Dados gerais;
- Contactos;
- Enderecos;
- Documentos;
- Credito;
- Saldo;
- Pagamentos;
- Faturas;
- CRM;
- Historico;
- Tags;
- Descontos;
- Auditoria.

### Indicadores

- Total comprado.
- Total pago.
- Valor em aberto.
- Limite de credito.
- Credito disponivel.
- Dias em atraso.

---

## Tela 5 - Grupos de Clientes

Criar gestao de grupos comerciais.

### Campos

- Codigo.
- Nome.
- Descricao.
- Desconto padrao.
- Limite de credito padrao.
- Condicao de pagamento padrao.
- Estado.

### Acoes

- Novo grupo.
- Editar.
- Ativar.
- Inativar.
- Ver clientes do grupo.

### Regra

Grupo com clientes associados nao deve ser eliminado fisicamente.

---

## Tela 6 - Contactos do Cliente

Criar CRUD de contactos dentro da ficha do cliente.

### Campos

- Nome.
- Cargo.
- Telefone.
- Email.
- Principal.
- Recebe cobranca.
- Recebe documentos.
- Observacoes.

### Acoes

- Adicionar contacto.
- Editar.
- Definir principal.
- Remover.

### Regra

Permitir no maximo um contacto principal quando a configuracao do tenant exigir.

---

## Tela 7 - Enderecos do Cliente

Criar CRUD de enderecos.

### Tipos

- Principal.
- Fiscal.
- Entrega.
- Cobranca.

### Campos

- Tipo.
- Pais.
- Provincia.
- Cidade.
- Endereco.
- Codigo postal.
- Principal.
- Observacoes.

### Regras

- Fatura deve usar endereco fiscal quando existir.
- Guia de remessa deve usar endereco de entrega quando existir.

---

## Tela 8 - Documentos do Cliente

Criar area para anexos e documentos.

### Tipos

- Identificacao.
- NUIT.
- Alvara.
- Contrato.
- Certificado fiscal.

### Campos

- Tipo.
- Numero.
- Arquivo.
- Data de emissao.
- Validade.
- Observacoes.

### Regra

Documento expirado deve gerar alerta quando for obrigatorio.

---

## Tela 9 - Limite de Credito

Criar tela de consulta e alteracao de credito.

### Campos

- Limite.
- Moeda.
- Vigencia.
- Condicao de pagamento.
- Bloqueia venda acima do limite.
- Motivo.
- Aprovador.

### Fluxo

1. Mostrar limite atual e saldo.
2. Permitir inserir novo limite.
3. Exigir permissao `customers.credit.manage`.
4. Exigir motivo.
5. Confirmar alteracao.
6. Registrar auditoria.

---

## Tela 10 - Saldo do Cliente

Criar visao financeira do cliente.

### Indicadores

- Total comprado.
- Total pago.
- Valor em aberto.
- Valor vencido.
- Limite de credito.
- Credito disponivel.
- Ultima compra.
- Ultimo pagamento.

### Tabelas

- Faturas abertas.
- Faturas vencidas.
- Recibos.
- Notas de credito.

### Acoes

- Abrir fatura.
- Registrar pagamento.
- Exportar extrato.
- Enviar aviso.

---

## Tela 11 - Pagamentos do Cliente

Criar listagem e formulario de pagamentos.

### Campos

- Valor.
- Moeda.
- Meio de pagamento.
- Data.
- Referencia.
- Faturas a liquidar.
- Observacao.

### Regras

- Pagamento pode ser parcial.
- Pagamento deve integrar financeiro e tesouraria.
- Pagamento confirmado nao deve ser editado.

---

## Tela 12 - Historico do Cliente

Criar linha do tempo de eventos comerciais.

### Eventos

- Criacao.
- Atualizacao.
- Compra.
- Fatura emitida.
- Pagamento.
- Bloqueio.
- Desbloqueio.
- Alteracao de credito.
- Actividade CRM.

### Acoes

- Filtrar por tipo.
- Abrir evento origem.
- Exportar historico.

---

## Tela 13 - Tags de Clientes

Criar gestao de etiquetas comerciais.

### Campos

- Nome.
- Cor.
- Descricao.
- Estado.

### Acoes

- Criar tag.
- Editar tag.
- Associar a cliente.
- Remover de cliente.

---

## Tela 14 - Descontos do Cliente

Criar gestao de descontos especificos por cliente.

### Campos

- Tipo.
- Valor.
- Produto.
- Categoria.
- Data de inicio.
- Data de fim.
- Estado.

### Tipos

- Percentual.
- Valor fixo.

### Regras

- Desconto expirado nao deve ser aplicado.
- Desconto por cliente deve respeitar a politica de preco do ERP.

---

## Tela 15 - Aging de Clientes

Criar relatorio de vencidos por faixa.

### Colunas

- Cliente.
- Saldo atual.
- 0-30 dias.
- 31-60 dias.
- 61-90 dias.
- Mais de 90 dias.
- Total vencido.

### Acoes

- Abrir cliente.
- Enviar aviso.
- Exportar.

---

## Tela 16 - Relatorios de Clientes

Criar pagina de relatorios.

### Relatorios

- Clientes por grupo.
- Clientes por estado.
- Saldos por cliente.
- Aging.
- Clientes sem compra.
- Top clientes por receita.
- Limite de credito utilizado.
- Descontos por cliente.

---

## Componentes Reutilizaveis

Criar ou usar componentes equivalentes:

- `CustomerSelector`
- `CustomerStatusBadge`
- `CreditLimitCard`
- `CustomerBalanceCard`
- `CustomerContactForm`
- `CustomerAddressForm`
- `CustomerTagPicker`
- `CustomerAgingTable`
- `CustomerTimeline`
- `CustomerPaymentForm`
- `CustomerDocumentUploader`

---

## Permissoes

Aplicar permissoes por tela e acao:

| Permissao | Uso |
| --- | --- |
| `customers.dashboard.read` | Ver dashboard |
| `customers.read` | Ver clientes |
| `customers.create` | Criar clientes |
| `customers.update` | Editar clientes |
| `customers.block` | Bloquear/desbloquear |
| `customers.groups.manage` | Gerir grupos |
| `customers.contacts.manage` | Gerir contactos |
| `customers.addresses.manage` | Gerir enderecos |
| `customers.documents.manage` | Gerir documentos |
| `customers.credit.manage` | Alterar credito |
| `customers.balance.read` | Ver saldo |
| `customers.payments.manage` | Registrar pagamentos |
| `customers.tags.manage` | Gerir tags |
| `customers.discounts.manage` | Gerir descontos |
| `customers.reports.read` | Ver relatorios |

---

## Dados Mockados Para Prototipo

Use dados mockados quando a API ainda nao existir:

- Clientes: 20 registros.
- Grupos: Retalho, Grossista, Governo, Escola, Empresa.
- Estados: ativo, inativo, bloqueado.
- Moedas: MZN, USD, ZAR.
- Meios de pagamento: numerario, transferencia, M-Pesa, e-Mola, TPA.
- Faturas abertas e vencidas.
- Pagamentos parciais e totais.
- Historico com eventos variados.

---

## Regras de Negocio

- Cliente bloqueado nao pode comprar a credito.
- Cliente acima do limite deve bloquear venda a credito quando a regra estiver ativa.
- Alteracao de limite de credito exige motivo.
- Bloqueio e desbloqueio exigem permissao.
- Dados fiscais devem gerar auditoria quando alterados.
- Pagamento confirmado nao pode ser editado diretamente.
- Contacto principal deve ser unico quando a regra estiver ativa.
- NUIT deve ser unico por tenant quando informado.
- Todas as listagens devem filtrar por tenant/company.

---

## Criterios de Aceite

- Cliente pode ser criado, consultado e atualizado.
- Listagem filtra por tenant.
- Contactos, enderecos e documentos funcionam.
- Credito e saldo sao exibidos corretamente.
- Pagamento pode ser parcial e integra financeiro.
- Bloqueio/desbloqueio exige permissao.
- Aging mostra vencidos por faixa.
- Alteracoes sensiveis geram auditoria.
- Interface e responsiva.
- Tabelas possuem filtros e paginacao.
- Formularios validam campos obrigatorios.
- Acoes sensiveis usam confirmacao.

---

## Saida Esperada

Entregar as telas frontend do modulo Gestao de Clientes com:

- rotas implementadas;
- menu do modulo;
- componentes reutilizaveis;
- dados mockados ou integracao API;
- estados de loading, vazio e erro;
- validacoes de formulario;
- permissao por acao;
- layout responsivo;
- criterios de aceite cumpridos.
