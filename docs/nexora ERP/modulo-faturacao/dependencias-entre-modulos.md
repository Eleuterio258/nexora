# Dependencias Entre Modulos

## Visao geral

Os modulos estao separados por responsabilidade, mas nao sao independentes. Existe dependencia funcional e dependencia de dados entre eles.

A separacao correta e esta:

- `gestao-clientes`: dono dos dados do cliente
- `gestao-produtos`: dono dos dados de produtos, categorias e armazens
- `gestao-stock`: dono dos movimentos e saldos de inventario
- `modulo-faturacao`: dono dos documentos comerciais e pagamentos

## Regra principal

Cada modulo deve ser dono apenas das suas tabelas principais.
Os outros modulos referenciam essas tabelas por chave estrangeira ou contrato de servico.

## Mapa de dependencias

```text
gestao-clientes
      |
      v
modulo-faturacao
      ^
      |
gestao-produtos ----> gestao-stock
      ^                 |
      |                 v
      +----------- modulo-faturacao
```

## Dependencias por modulo

### 1. Gestao de Clientes

Depende de:

- nenhum modulo para existir como cadastro base

E consumido por:

- `modulo-faturacao`
- `gestao-clientes` consulta historico e conta corrente com base em documentos e pagamentos

Tabelas base:

- `clientes`
- `cliente_contactos`
- `cliente_conta_corrente`

Observacao:

O historico de compras do cliente nao nasce dentro do modulo de clientes. Ele depende dos documentos gerados pelo modulo de faturacao.

### 2. Gestao de Produtos

Depende de:

- nenhum modulo para existir como cadastro base

E consumido por:

- `gestao-stock`
- `modulo-faturacao`

Tabelas base:

- `categorias`
- `armazens`
- `produtos`
- `produto_stock`

Observacao:

O stock atual por produto depende dos movimentos do modulo de stock.

### 3. Gestao de Stock

Depende de:

- `gestao-produtos`

Porque precisa de:

- `produtos`
- `armazens`
- `produto_stock`

E consumido por:

- `modulo-faturacao`

Tabelas base:

- `movimentos_stock`
- `transferencias_stock`
- `transferencia_itens`
- `inventarios`
- `inventario_itens`

Observacao:

O modulo de faturacao nao deve ser dono do stock. Ele apenas solicita validacao e baixa de stock ao modulo de stock.

### 4. Modulo de Faturacao

Depende de:

- `gestao-clientes`
- `gestao-produtos`
- `gestao-stock`

Porque precisa de:

- cliente valido
- produto valido
- preco e IVA do produto
- stock disponivel no armazem

Tabelas base:

- `documentos_comerciais`
- `documento_itens`
- `pagamentos`
- `audit_logs`

Observacao:

Recibos, notas de credito, proformas, orcamentos e faturas dependem sempre do cadastro de clientes e produtos.

## Dependencias de negocio

### Historico de compras do cliente

Fonte principal:

- `documentos_comerciais`
- `pagamentos`

Modulo dono:

- faturacao

Modulo consumidor:

- gestao-clientes

### Conta corrente do cliente

Fonte principal:

- `documentos_comerciais`
- `pagamentos`
- `cliente_conta_corrente`

Modulos envolvidos:

- faturacao
- gestao-clientes

### Stock disponivel

Fonte principal:

- `produto_stock`
- `movimentos_stock`

Modulo dono:

- gestao-stock

Modulo consumidor:

- faturacao
- gestao-produtos

## Recomendacao de arquitetura

A melhor organizacao nao e duplicar tabelas em cada modulo.
A melhor organizacao e esta:

- `core-clientes.sql`
- `core-produtos.sql`
- `core-stock.sql`
- `core-faturacao.sql`

Ou entao um schema unico com ownership logico:

- schema `clientes`
- schema `produtos`
- schema `stock`
- schema `faturacao`

## Conclusao

Sim, os modulos estao separados, mas existe dependencia entre eles.
Isso e normal.
O importante e controlar:

- quem e dono de cada tabela
- quem apenas consome os dados
- quais operacoes cruzam modulos
- quais regras de negocio pertencem a cada dominio
