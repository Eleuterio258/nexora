# Estrutura do Modulo de Faturacao e Vendas

## Submodulos

### 1. Clientes

Responsavel por:

- criar cliente
- editar cliente
- listar cliente
- consultar cliente
- desativar cliente
- gerir contactos do cliente
- consultar historico de compras
- consultar limite de credito
- consultar conta corrente
- consultar saldo em aberto

Informacoes principais do cliente:

- nome
- NUIT
- endereco
- telefone
- email
- pessoa de contacto
- limite de credito
- saldo da conta corrente
- estado do cliente

### 2. Produtos

Responsavel por:

- criar produto
- editar produto
- listar produto
- consultar estoque
- desativar produto

### 3. Documentos comerciais

Responsavel por:

- criar orcamento
- criar proforma
- criar fatura
- criar recibo
- criar nota de credito
- criar guia de remessa
- listar documentos
- consultar documento
- cancelar documento
- converter documentos entre etapas comerciais

### 4. Itens do documento

Responsavel por:

- adicionar item
- editar item
- remover item
- recalcular totais

### 5. Pagamentos

Responsavel por:

- registar pagamento
- listar pagamentos
- consultar saldo pendente
- atualizar estado do documento
- gerar recibo apos confirmacao

### 6. Estoque

Responsavel por:

- validar disponibilidade
- baixar estoque na faturacao ou remessa
- repor estoque em nota de credito quando aplicavel
- registar movimento de estoque

### 7. Relatorios

Responsavel por:

- vendas por periodo
- vendas por cliente
- produtos mais vendidos
- faturacao mensal
- IVA liquidado
- documentos emitidos por tipo

### 8. Auditoria

Responsavel por:

- guardar eventos de criacao
- guardar eventos de edicao
- guardar cancelamentos
- guardar conversoes documentais
- guardar pagamentos

## Camadas recomendadas

```text
UI / Frontend
  |
Controller / Route
  |
Application Service
  |
Domain Rules
  |
Repository / ORM
  |
Database
```

## Servicos principais

- ClienteService
- ProdutoService
- DocumentoComercialService
- PagamentoService
- EstoqueService
- RelatorioService
- PdfService
- AuditoriaService
- ContaCorrenteClienteService

## Regras de negocio principais

- nao emitir fatura sem cliente
- nao emitir documento comercial com itens vazios, exceto quando a regra do tipo permitir
- validar estoque antes de confirmar faturacao ou remessa
- gerar numero unico por tipo e serie documental
- recalcular totais sempre que itens forem alterados
- atualizar o estado do documento conforme pagamentos
- permitir conversoes: orcamento -> proforma -> fatura -> recibo
- permitir nota de credito vinculada a uma fatura
- permitir guia de remessa vinculada a uma venda ou entrega
- controlar o limite de credito do cliente antes da emissao de documentos a credito
- atualizar conta corrente do cliente com debitos e creditos
- guardar logs de auditoria em operacoes criticas
