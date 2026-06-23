# Requisitos Funcionais do Sistema de Faturacao

## 1. Introducao

Este documento descreve os requisitos funcionais do sistema de faturacao. Os requisitos funcionais definem as funcionalidades que o sistema deve oferecer aos utilizadores e aos processos do negocio.

## 2. Perfis envolvidos

- Admin
- Contabilista
- Vendedor
- Caixa

## 3. Requisitos funcionais

### RF01. Autenticacao de utilizadores

O sistema deve permitir que o utilizador faca login com credenciais validas.

### RF02. Gestao de perfis e permissoes

O sistema deve permitir controlar acessos por perfil, como admin, contabilista, vendedor e caixa.

### RF03. Cadastro de clientes

O sistema deve permitir criar, editar, consultar e desativar clientes.

Campos minimos:

- codigo ou id
- nome ou razao social
- NUIT
- endereco
- telefone
- email

### RF04. Cadastro de produtos

O sistema deve permitir criar, editar, consultar e desativar produtos ou servicos.

Campos minimos:

- codigo do produto
- nome
- descricao
- preco
- IVA
- estoque
- categoria

### RF05. Gestao de categorias

O sistema deve permitir classificar produtos por categoria.

### RF06. Consulta de estoque

O sistema deve mostrar a quantidade disponivel de cada produto.

### RF07. Atualizacao automatica de estoque

O sistema deve reduzir o estoque quando uma fatura for confirmada.

### RF08. Criacao de fatura proforma

O sistema deve permitir gerar proformas antes da confirmacao da venda.

### RF09. Criacao de fatura

O sistema deve permitir gerar faturas com numero unico e sequencial.

### RF10. Gestao de itens da fatura

O sistema deve permitir adicionar, editar e remover itens antes da finalizacao da fatura.

### RF11. Calculo automatico

O sistema deve calcular automaticamente:

- subtotal
- desconto
- IVA
- total final

### RF12. Validacao de dados da fatura

O sistema deve validar se a fatura possui cliente, ao menos um item e valores consistentes antes da emissao.

### RF13. Registo de pagamentos

O sistema deve permitir registar pagamentos por diferentes metodos.

Exemplos:

- dinheiro
- transferencia
- M-Pesa
- E-Mola
- cartao

### RF14. Controle de estado da fatura

O sistema deve permitir estados como:

- pendente
- paga
- parcialmente paga
- cancelada

### RF15. Emissao de PDF

O sistema deve permitir gerar e exportar a fatura em PDF.

### RF16. Impressao de documentos

O sistema deve permitir imprimir fatura, proforma e recibo.

### RF17. Pesquisa e filtragem

O sistema deve permitir pesquisar clientes, produtos, faturas e pagamentos.

### RF18. Relatorios

O sistema deve emitir relatorios de:

- vendas por periodo
- vendas por cliente
- produtos mais vendidos
- faturacao mensal
- IVA liquidado
- pagamentos recebidos

### RF19. Auditoria

O sistema deve guardar historico das operacoes importantes.

### RF20. Multiempresa ou multi-tenant

O sistema deve permitir separar os dados por empresa ou tenant.

### RF21. Configuracao fiscal

O sistema deve permitir configurar dados fiscais da empresa, incluindo NUIT, endereco, serie documental e regras de IVA.

### RF22. Numeracao documental

O sistema deve gerar numeracao sequencial por tipo de documento.

Exemplo:

```text
FT 2026/000123
PP 2026/000045
```

### RF23. Conversao de proforma para fatura

O sistema deve permitir transformar uma proforma em fatura quando a venda for confirmada.

### RF24. Cancelamento controlado

O sistema deve permitir cancelar documentos segundo permissao e registar o motivo.

## 4. Casos de uso principais

### UC01. Cadastrar cliente

Ator principal: Vendedor

1. O utilizador abre o modulo de clientes
2. Informa os dados obrigatorios
3. O sistema valida os campos
4. O sistema grava o cliente
5. O sistema confirma o cadastro

### UC02. Cadastrar produto

Ator principal: Admin ou Vendedor autorizado

1. O utilizador abre o modulo de produtos
2. Informa os dados do produto
3. O sistema valida preco, categoria e estoque inicial
4. O sistema grava o produto

### UC03. Emitir proforma

Ator principal: Vendedor

1. Selecionar cliente
2. Adicionar produtos
3. Informar quantidades
4. O sistema calcula subtotal, IVA e total
5. O utilizador confirma
6. O sistema gera a proforma

### UC04. Emitir fatura

Ator principal: Vendedor

1. Selecionar cliente
2. Adicionar produtos
3. Validar estoque
4. Calcular valores
5. Confirmar emissao
6. Gerar numero sequencial
7. Atualizar estoque
8. Gravar auditoria

### UC05. Registar pagamento

Ator principal: Caixa

1. Localizar a fatura
2. Escolher metodo de pagamento
3. Informar valor recebido
4. O sistema atualiza o estado da fatura
5. O sistema grava o pagamento

### UC06. Gerar relatorio

Ator principal: Admin ou Contabilista

1. Selecionar tipo de relatorio
2. Definir periodo e filtros
3. O sistema processa os dados
4. O sistema apresenta o resultado
5. O utilizador pode exportar
