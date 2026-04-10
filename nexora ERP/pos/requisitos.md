# Requisitos — Modulo POS

## Requisitos Funcionais

### RF01 — Terminais POS

O sistema deve configurar terminais POS com codigo, nome, armazem e caixa da tesouraria associados. Cada terminal pode ter impressora configurada.

### RF02 — Abertura de Sessao

O operador deve abrir uma sessao de caixa declarando o saldo inicial. O sistema regista user_id, terminal e hora de abertura. So pode existir uma sessao aberta por terminal.

### RF03 — Venda com Multiplos Itens

O sistema deve registar vendas com multiplos produtos, calcular automaticamente desconto por linha, IVA por linha, subtotal e total.

### RF04 — Multiplos Metodos de Pagamento

Uma venda POS deve aceitar pagamento dividido por varios metodos simultaneamente (ex: dinheiro + MPesa). O troco deve ser calculado automaticamente.

### RF05 — Baixa Automatica de Stock

A confirmacao de uma venda deve baixar o stock no armazem associado ao terminal na mesma transaccao.

### RF06 — Devolucoes com Tipo de Reembolso

O sistema deve registar devolucoes parciais ou totais com referencia aos itens originais e tipo de reembolso: numerario, credito em loja ou mesmo metodo de pagamento.

### RF07 — Movimentos Manuais de Caixa

O operador deve poder registar entradas e saidas manuais de caixa durante a sessao (fundo de maneio, despesas de caixa) com motivo obrigatorio.

### RF08 — Fecho de Sessao com Reconciliacao

O operador declara o saldo final ao fechar a sessao. O sistema calcula o saldo esperado (saldo_inicial + vendas - devolucoes + entradas - saidas) e regista a diferenca de caixa como coluna computed.

### RF09 — Resumo por Metodo de Pagamento

O sistema deve gerar no fecho um resumo de totais por metodo de pagamento (pos_session_payments) para reconciliacao com a tesouraria.

### RF10 — Cancelamento de Venda

O sistema deve cancelar uma venda com motivo obrigatorio, estornando o stock automaticamente.

### RF11 — Vendas Anonimas

O sistema deve suportar vendas sem cliente associado (customer_id opcional).

### RF12 — Recibo de Caixa

O sistema deve gerar os dados formatados para impressao de recibo de cada venda, incluindo itens, impostos, metodos de pagamento e troco.

### RF13 — Relatorios POS

O sistema deve gerar: vendas por sessao, vendas por terminal, produtos mais vendidos, distribuicao horaria e resumo de fecho de caixa para impressao.

---

## Requisitos Nao Funcionais

### RNF01 — Sessao Unica por Terminal

Nao pode existir mais de uma sessao aberta por terminal em simultaneo.

### RNF02 — Atomicidade

Venda, pagamentos e baixa de stock devem ocorrer na mesma transaccao de base de dados.

### RNF03 — Velocidade

Uma venda completa (scan + pagamento + emissao de recibo) deve concluir em menos de 3 segundos.

### RNF04 — Numeracao Sequencial

O numero de venda POS deve ser unico por tenant e sequencial por sessao ou por terminal.

### RNF05 — Diferenca de Caixa Calculada

O campo `diferenca_caixa` em `pos_sessions` deve ser coluna computed (`GENERATED ALWAYS AS STORED`) para garantir consistencia automatica.

### RNF06 — Auditoria

Abertura, fecho, cancelamentos e movimentos manuais de caixa devem gerar registos no modulo de auditoria.

### RNF07 — Seguranca

Apenas utilizadores com permissao `pos:operar` devem aceder a operacoes de venda. O fecho de sessao pode requerer permissao adicional `pos:fechar`.
