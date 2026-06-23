# Requisitos — Modulo Compras

## Requisitos Funcionais

### RF01 — Registo de Fornecedores
O sistema deve permitir criar fornecedores com codigo, nome, NUIT, telefone, email, moradas e contactos.

### RF02 — Estado do Fornecedor
O sistema deve suportar os estados de fornecedor: ativo, inativo e bloqueado, com impacto na emissao de ordens de compra.

### RF03 — Requisicoes de Compra
O sistema deve permitir criar requisicoes internas de compra com itens e quantidades, sujeitas a aprovacao.

### RF04 — Ordens de Compra
O sistema deve permitir criar ordens de compra para fornecedores, com itens, quantidades, precos e totais.

### RF05 — Conversao de Requisicao em Ordem
O sistema deve permitir converter uma requisicao aprovada em ordem de compra sem reintroducao de dados.

### RF06 — Recepcao de Mercadoria
O sistema deve registar a recepcao de mercadoria contra uma ordem de compra, suportando recepcoes parciais.

### RF07 — Devolucoes a Fornecedores
O sistema deve suportar a devolucao de mercadoria a fornecedores com referencia a recepcao original.

### RF08 — Faturas de Fornecedor
O sistema deve registar faturas recebidas de fornecedores, associadas a ordens de compra, com controlo de saldo em divida.

### RF09 — Pagamentos a Fornecedores
O sistema deve registar pagamentos a fornecedores com alocacao a faturas especificas, suportando pagamentos parciais.

### RF10 — Actualizacao de Stock na Recepcao
O sistema deve actualizar automaticamente o stock no modulo gestao-stock ao registar a recepcao de mercadoria.

---

## Requisitos Nao Funcionais

### RNF01 — Unicidade de NUIT do Fornecedor
O NUIT do fornecedor deve ser unico por tenant.

### RNF02 — Atomicidade com Stock
O registo de recepcao e a entrada de stock devem ocorrer na mesma transaccao de base de dados.

### RNF03 — Numeracao Sequencial
Numeros de requisicao, ordem, recepcao e fatura de fornecedor devem ser sequenciais e unicos por tenant.

### RNF04 — Imutabilidade de Documentos Confirmados
Ordens de compra e faturas de fornecedor confirmadas nao devem poder ser alteradas directamente.

### RNF05 — Auditoria
Criacao e confirmacao de ordens, recepcoes e pagamentos devem gerar registos no modulo de auditoria.

### RNF06 — Rastreabilidade
Cada fatura de fornecedor deve ser rastreavel ate a ordem de compra e recepcao que a originou.
