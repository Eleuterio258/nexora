# Prompt Mobile - Gestao de Clientes

Use este prompt para gerar ou implementar o modulo **Gestao de Clientes Mobile** do Nexora ERP.

---

## Prompt Principal

Crie um app mobile ou modulo mobile para **Gestao de Clientes** do Nexora ERP, com foco em uso por vendedores, gestores comerciais, cobradores, administradores do tenant e equipas de atendimento.

O app deve permitir consultar clientes rapidamente, cadastrar novos clientes em campo, editar dados essenciais, gerir contactos e enderecos, consultar saldo, verificar limite de credito, registrar pagamento, anexar documentos usando camera, ver historico e enviar avisos.

A experiencia deve ser simples, rapida e adequada para telas pequenas. Evite tabelas largas. Use listas, cards compactos, filtros em bottom sheet, formularios por etapas, acoes principais fixas e navegacao clara.

---

## Contexto

**Modulo:** Gestao de Clientes  
**Service:** `clientes-service`  
**Base API:** `/api/clientes`  
**Escopo:** Tenant/Empresa  
**Plataforma alvo:** Android e iOS  
**Usuarios principais:** vendedor, gestor comercial, cobrador, tenant admin  
**Regras:** filtrar sempre por `tenant_id` ou `company_id`.

---

## Objetivos Mobile

- Consultar clientes rapidamente.
- Criar cliente em poucos passos.
- Ver saldo e credito no telemovel.
- Registrar contacto, endereco e documento em campo.
- Fotografar/anexar documentos.
- Registrar pagamento ou promessa de pagamento.
- Enviar aviso de cobranca.
- Ver historico comercial.
- Funcionar bem em conectividade limitada.

---

## Navegacao Mobile

Use uma estrutura com:

- Bottom navigation para as areas principais.
- Header compacto com pesquisa.
- Floating action button para novo cliente.
- Bottom sheets para filtros e acoes.
- Abas horizontais no detalhe do cliente.
- Pull to refresh nas listagens.

### Bottom Navigation

| Aba | Rota Mobile | Conteudo |
| --- | --- | --- |
| Inicio | `/m/clientes/dashboard` | KPIs e alertas |
| Clientes | `/m/clientes` | Lista e pesquisa |
| Aging | `/m/clientes/aging` | Vencidos por faixa |
| Relatorios | `/m/clientes/relatorios` | Resumos simples |
| Mais | `/m/clientes/mais` | Grupos, tags e configuracoes |

---

## Telas Mobile Obrigatorias

| Ordem | Tela | Rota Mobile | Endpoint |
| --- | --- | --- | --- |
| 1 | Inicio Clientes | `/m/clientes/dashboard` | `GET /api/clientes/reports/summary` |
| 2 | Lista de Clientes | `/m/clientes` | `GET /api/clientes` |
| 3 | Novo Cliente | `/m/clientes/novo` | `POST /api/clientes` |
| 4 | Detalhe do Cliente | `/m/clientes/:id` | `GET /api/clientes/:id` |
| 5 | Contactos | `/m/clientes/:id/contactos` | `/api/clientes/:id/contactos` |
| 6 | Enderecos | `/m/clientes/:id/enderecos` | `/api/clientes/:id/enderecos` |
| 7 | Documentos | `/m/clientes/:id/documentos` | `/api/clientes/:id/documentos` |
| 8 | Credito | `/m/clientes/:id/credito` | `/api/clientes/:id/limite-credito` |
| 9 | Saldo | `/m/clientes/:id/saldo` | `/api/clientes/:id/saldo` |
| 10 | Pagamentos | `/m/clientes/:id/pagamentos` | `/api/clientes/:id/pagamentos` |
| 11 | Historico | `/m/clientes/:id/historico` | `/api/clientes/:id/historico` |
| 12 | Aging | `/m/clientes/aging` | `GET /api/clientes/reports/aging` |
| 13 | Grupos | `/m/clientes/grupos` | `/api/clientes/grupos` |
| 14 | Tags | `/m/clientes/tags` | `/api/clientes/tags` |

---

## Padrao de Design Mobile

### Visual

- Interface limpa, empresarial e objetiva.
- Cards compactos com bordas leves.
- Tipografia legivel.
- Alto contraste para estados e valores.
- Icones para acoes comuns.
- Evitar tabelas horizontais.
- Priorizar listas e cards.

### Interacao

- Toque simples abre detalhe.
- Toque longo abre acoes rapidas.
- Swipe pode revelar acoes secundarias.
- Filtros em bottom sheet.
- Acoes sensiveis em modal de confirmacao.
- Formularios longos em etapas.

### Estados

Implementar estados:

- loading;
- vazio;
- erro;
- offline;
- sincronizando;
- sucesso;
- sem permissao.

---

## Tela 1 - Inicio Clientes

**Rota:** `/m/clientes/dashboard`  
**Endpoint:** `GET /api/clientes/reports/summary`

### Conteudo

Mostrar cards compactos:

- Clientes ativos.
- Novos clientes.
- Clientes bloqueados.
- Saldo em aberto.
- Credito excedido.
- Vencidos.

### Blocos

- Alertas de credito.
- Clientes com saldo alto.
- Clientes sem compra recente.
- Acoes rapidas.

### Acoes Rapidas

- Novo cliente.
- Procurar cliente.
- Registrar pagamento.
- Ver aging.

---

## Tela 2 - Lista de Clientes

**Rota:** `/m/clientes`  
**Endpoint:** `GET /api/clientes`

### Layout

Usar lista de cards. Cada card deve mostrar:

- Nome.
- Codigo.
- Estado.
- Grupo.
- Telefone.
- Saldo.
- Credito disponivel.
- Indicador de atraso.

### Pesquisa

Campo de pesquisa no topo:

- nome;
- codigo;
- NUIT;
- telefone;
- email.

### Filtros em Bottom Sheet

- Grupo.
- Estado.
- Com saldo em aberto.
- Com credito bloqueado.
- Com atraso.
- Vendedor.

### Acoes por Card

- Abrir detalhe.
- Ligar.
- Enviar mensagem.
- Criar fatura.
- Registrar pagamento.
- Ver saldo.

---

## Tela 3 - Novo Cliente

**Rota:** `/m/clientes/novo`  
**Endpoint:** `POST /api/clientes`

### Formulario por Etapas

#### Etapa 1 - Dados Basicos

- Nome.
- Tipo.
- Telefone.
- Email.
- NUIT.

#### Etapa 2 - Comercial

- Grupo.
- Vendedor responsavel.
- Moeda padrao.
- Condicao de pagamento.

#### Etapa 3 - Endereco

- Pais.
- Provincia.
- Cidade.
- Endereco.

#### Etapa 4 - Confirmacao

- Rever dados.
- Guardar.
- Guardar e abrir detalhe.

### Validacoes

- Nome e obrigatorio.
- Email deve ter formato valido.
- NUIT deve ser unico quando informado.
- Telefone deve aceitar formato local.

### Mobile

- Permitir salvar rascunho offline.
- Sincronizar quando voltar conexao.
- Mostrar estado de sincronizacao.

---

## Tela 4 - Detalhe do Cliente

**Rota:** `/m/clientes/:id`  
**Endpoint:** `GET /api/clientes/:id`

### Header

Mostrar:

- Nome do cliente.
- Estado.
- Grupo.
- Saldo.
- Credito disponivel.

### Acoes Fixas

Usar botoes compactos:

- Ligar.
- Mensagem.
- Pagamento.
- Fatura.
- Mais.

### Abas Horizontais

- Resumo.
- Contactos.
- Enderecos.
- Documentos.
- Credito.
- Saldo.
- Pagamentos.
- Historico.

### Resumo

Mostrar:

- Total comprado.
- Total pago.
- Valor em aberto.
- Valor vencido.
- Ultima compra.
- Ultimo pagamento.

---

## Tela 5 - Contactos

**Rota:** `/m/clientes/:id/contactos`  
**Endpoint:** `/api/clientes/:id/contactos`

### Card de Contacto

- Nome.
- Cargo.
- Telefone.
- Email.
- Principal.
- Recebe cobranca.
- Recebe documentos.

### Acoes

- Ligar.
- Enviar SMS/WhatsApp.
- Enviar email.
- Editar.
- Definir principal.

### Criar Contacto

Formulario em bottom sheet com:

- Nome.
- Cargo.
- Telefone.
- Email.
- Principal.
- Recebe cobranca.
- Recebe documentos.

---

## Tela 6 - Enderecos

**Rota:** `/m/clientes/:id/enderecos`  
**Endpoint:** `/api/clientes/:id/enderecos`

### Card de Endereco

- Tipo.
- Cidade.
- Endereco.
- Principal.

### Acoes

- Abrir mapa.
- Editar.
- Definir principal.
- Remover.

### Criar Endereco

Formulario:

- Tipo.
- Pais.
- Provincia.
- Cidade.
- Endereco.
- Codigo postal.
- Principal.

---

## Tela 7 - Documentos

**Rota:** `/m/clientes/:id/documentos`  
**Endpoint:** `/api/clientes/:id/documentos`

### Mobile

Permitir:

- tirar foto com camera;
- escolher arquivo;
- visualizar documento;
- substituir arquivo;
- remover quando permitido.

### Campos

- Tipo.
- Numero.
- Arquivo.
- Data de emissao.
- Validade.
- Observacoes.

### Alertas

- Documento expirado.
- Documento obrigatorio ausente.
- Upload pendente de sincronizacao.

---

## Tela 8 - Credito

**Rota:** `/m/clientes/:id/credito`  
**Endpoint:** `/api/clientes/:id/limite-credito`

### Conteudo

Mostrar:

- Limite atual.
- Saldo em aberto.
- Credito disponivel.
- Venda bloqueada acima do limite.
- Vigencia.

### Acoes

- Solicitar alteracao de limite.
- Aprovar alteracao, se tiver permissao.
- Bloquear venda a credito.
- Desbloquear venda a credito.

### Regra

Alteracao de limite deve exigir:

- permissao `customers.credit.manage`;
- motivo;
- confirmacao;
- auditoria.

---

## Tela 9 - Saldo

**Rota:** `/m/clientes/:id/saldo`  
**Endpoint:** `/api/clientes/:id/saldo`

### Cards

- Total comprado.
- Total pago.
- Valor em aberto.
- Valor vencido.
- Credito disponivel.

### Listas

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

## Tela 10 - Pagamentos

**Rota:** `/m/clientes/:id/pagamentos`  
**Endpoint:** `/api/clientes/:id/pagamentos`

### Lista

Cada item deve mostrar:

- Data.
- Valor.
- Moeda.
- Meio de pagamento.
- Referencia.
- Estado.

### Novo Pagamento

Formulario por etapas:

1. Selecionar faturas.
2. Informar valor por fatura.
3. Escolher meio de pagamento.
4. Informar referencia.
5. Confirmar.

### Regras

- Pagamento pode ser parcial.
- Pagamento confirmado nao pode ser editado.
- Confirmacao integra financeiro e tesouraria.

---

## Tela 11 - Historico

**Rota:** `/m/clientes/:id/historico`  
**Endpoint:** `/api/clientes/:id/historico`

### Layout

Usar timeline vertical.

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

### Filtros

- Tipo.
- Periodo.
- Usuario.

---

## Tela 12 - Aging

**Rota:** `/m/clientes/aging`  
**Endpoint:** `GET /api/clientes/reports/aging`

### Layout

Usar lista de cards por cliente.

### Dados por Card

- Cliente.
- Saldo atual.
- 0-30 dias.
- 31-60 dias.
- 61-90 dias.
- Mais de 90 dias.
- Total vencido.

### Acoes

- Abrir cliente.
- Ligar.
- Enviar aviso.
- Registrar pagamento.

---

## Tela 13 - Grupos

**Rota:** `/m/clientes/grupos`  
**Endpoint:** `/api/clientes/grupos`

### Campos

- Codigo.
- Nome.
- Descricao.
- Desconto padrao.
- Limite de credito padrao.
- Estado.

### Acoes

- Criar grupo.
- Editar grupo.
- Ver clientes do grupo.

---

## Tela 14 - Tags

**Rota:** `/m/clientes/tags`  
**Endpoint:** `/api/clientes/tags`

### Campos

- Nome.
- Cor.
- Descricao.
- Estado.

### Acoes

- Criar tag.
- Editar.
- Associar ao cliente.
- Remover do cliente.

---

## Offline e Sincronizacao

Implementar comportamento para uso em campo:

- cache local da lista de clientes recentes;
- cache do detalhe dos clientes abertos recentemente;
- criacao de cliente em rascunho offline;
- upload de documentos pendente;
- fila de sincronizacao;
- indicador de sincronizacao;
- conflito de dados quando cliente foi alterado no servidor.

### Regras Offline

- Acoes financeiras sensiveis podem ser bloqueadas offline.
- Pagamento offline deve ficar como rascunho local, nao confirmado.
- Alteracao de limite de credito deve exigir conexao.
- Bloqueio/desbloqueio deve exigir conexao.

---

## Componentes Mobile

Criar ou usar componentes equivalentes:

- `MobileCustomerCard`
- `MobileCustomerSearch`
- `MobileFilterSheet`
- `MobileCustomerHeader`
- `MobileKpiCard`
- `MobileActionBar`
- `MobileContactCard`
- `MobileAddressCard`
- `MobileDocumentCapture`
- `MobileCreditSummary`
- `MobileBalanceSummary`
- `MobilePaymentStepper`
- `MobileTimeline`
- `SyncStatusBadge`

---

## Permissoes

Aplicar permissoes por tela e acao:

| Permissao | Uso Mobile |
| --- | --- |
| `customers.dashboard.read` | Ver inicio |
| `customers.read` | Ver clientes |
| `customers.create` | Criar cliente |
| `customers.update` | Editar cliente |
| `customers.block` | Bloquear/desbloquear |
| `customers.groups.manage` | Gerir grupos |
| `customers.contacts.manage` | Gerir contactos |
| `customers.addresses.manage` | Gerir enderecos |
| `customers.documents.manage` | Anexar documentos |
| `customers.credit.manage` | Alterar credito |
| `customers.balance.read` | Ver saldo |
| `customers.payments.manage` | Registrar pagamento |
| `customers.tags.manage` | Gerir tags |
| `customers.discounts.manage` | Gerir descontos |
| `customers.reports.read` | Ver aging e relatorios |

---

## Dados Mockados Para Prototipo

Usar dados mockados quando a API ainda nao existir:

- 30 clientes.
- 5 grupos: Retalho, Grossista, Governo, Escola, Empresa.
- Estados: ativo, inativo, bloqueado, credito_excedido.
- Moedas: MZN, USD, ZAR.
- Meios de pagamento: numerario, transferencia, M-Pesa, e-Mola, TPA.
- Faturas abertas e vencidas.
- Pagamentos parciais.
- Documentos com e sem validade.
- Historico com eventos variados.

---

## Regras de Negocio Mobile

- Cliente bloqueado nao pode comprar a credito.
- Cliente acima do limite deve bloquear venda a credito quando configurado.
- Alteracao de limite exige motivo.
- Bloqueio e desbloqueio exigem permissao.
- Pagamento confirmado nao pode ser editado.
- Contacto principal deve ser unico quando regra estiver ativa.
- NUIT deve ser unico por tenant quando informado.
- Dados sensiveis devem gerar auditoria.
- Toda listagem deve respeitar tenant/company.

---

## Criterios de Aceite

- App permite pesquisar cliente rapidamente.
- Lista de clientes funciona em tela pequena sem tabela larga.
- Novo cliente pode ser criado em etapas.
- Detalhe mostra resumo, saldo e acoes principais.
- Contactos permitem ligar e enviar mensagem.
- Documentos podem ser anexados com camera.
- Saldo e aging sao legiveis no mobile.
- Pagamento pode ser registrado com fluxo guiado.
- Estados offline e sincronizacao sao visiveis.
- Acoes sensiveis exigem confirmacao.
- Permissoes sao respeitadas.
- Interface funciona em Android e iOS.

---

## Saida Esperada

Entregar o modulo mobile de Gestao de Clientes com:

- rotas mobile implementadas;
- bottom navigation;
- lista de clientes em cards;
- formulario de novo cliente em etapas;
- detalhe com abas horizontais;
- camera/upload para documentos;
- estado offline/sync;
- permissoes por acao;
- dados mockados ou integracao API;
- layout responsivo para telemovel e tablet;
- criterios de aceite cumpridos.
