# Requisitos — Modulo Tesouraria

## Requisitos Funcionais

### RF01 — Contas Bancarias
O sistema deve permitir gerir contas bancarias da empresa com banco, numero de conta, NIB, moeda e saldo actual.

### RF02 — Caixas
O sistema deve permitir gerir caixas fisicas com nome, saldo actual e estado activo/inactivo.

### RF03 — Movimentos Financeiros
O sistema deve registar todos os movimentos financeiros (recebimento, pagamento, transferencia, ajuste) com referencia ao modulo de origem.

### RF04 — Origens de Movimento
O sistema deve identificar a origem de cada movimento: faturacao, compras, RH ou ajuste manual.

### RF05 — Reconciliacao Bancaria
O sistema deve suportar a reconciliacao entre o saldo do sistema e o extrato bancario por periodo, registando a diferenca.

### RF06 — Fecho de Reconciliacao
O sistema deve permitir fechar uma reconciliacao quando o saldo do sistema coincide com o extrato, impedindo novos movimentos no periodo.

### RF07 — Saldo Actualizado
O sistema deve manter o saldo actual de cada conta bancaria e caixa actualizado apos cada movimento.

---

## Requisitos Nao Funcionais

### RNF01 — Atomicidade de Saldos
A actualizacao do saldo de uma conta ou caixa deve ocorrer atomicamente com o registo do movimento.

### RNF02 — Saldo Nunca Negativo em Caixa
Por omissao, o sistema nao deve permitir saidas que resultem em saldo negativo numa caixa, salvo configuracao explicita.

### RNF03 — Imutabilidade de Reconciliacoes Fechadas
Uma reconciliacao fechada nao deve poder ser reaberta nem alterada.

### RNF04 — Auditoria
Criacao de contas bancarias, caixas, movimentos e reconciliacoes devem gerar registos no modulo de auditoria.

### RNF05 — Rastreabilidade
Cada movimento deve referenciar o documento origem (fatura, ordem de compra, folha de salarios) via origem_tipo e origem_id.
