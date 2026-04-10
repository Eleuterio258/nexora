# Requisitos — Modulo Gestao de Stock

## Requisitos Funcionais

### RF01 — Niveis de Stock
O sistema deve manter a quantidade disponivel, reservada e total por produto/variante/armazem/localizacao.

### RF02 — Localizacoes de Armazem
O sistema deve suportar sub-localizacoes dentro de um armazem (prateleira, corredor, zona) para rastreio granular.

### RF03 — Movimentos de Stock
O sistema deve registar todos os movimentos com tipo (entrada, saida, transferencia, ajuste, reserva, liberacao), quantidade e referencia ao documento origem.

### RF04 — Ajustes de Stock
O sistema deve permitir ajustes manuais de inventario (positivo ou negativo) com obrigatoriedade de motivo.

### RF05 — Transferencias entre Armazens
O sistema deve suportar transferencias de stock entre armazens com numero unico, estado e rastreio de itens.

### RF06 — Reservas de Stock
O sistema deve suportar a reserva de quantidade para pedidos de venda pendentes, descontando da quantidade disponivel.

### RF07 — Controlo por Lotes
O sistema deve suportar rastreio de stock por numero de lote, data de fabrico e data de validade.

### RF08 — Controlo por Numero de Serie
O sistema deve suportar rastreio de stock por numero de serie, com estado (disponivel, reservado, vendido, devolvido).

### RF09 — Contagem Fisica
O sistema deve gerir contagens fisicas de inventario com numero unico, comparando quantidades do sistema com as contadas.

### RF10 — Alertas de Stock
O sistema deve gerar alertas automaticos quando o stock fica abaixo do minimo, acima do maximo ou quando um lote esta proximo do vencimento.

### RF11 — Logs de Stock
O sistema deve manter um log interno de todas as operacoes de stock para rastreabilidade interna do modulo.

---

## Requisitos Nao Funcionais

### RNF01 — Atomicidade
Qualquer operacao que altere o stock (entrada, saida, transferencia) deve ser atomica — sem estados parciais em caso de erro.

### RNF02 — Stock Nunca Negativo
O sistema nao deve permitir saidas que resultem em stock negativo, salvo configuracao explicita por armazem.

### RNF03 — Consistencia com Faturacao
A baixa de stock ao emitir uma fatura deve ocorrer na mesma transaccao de base de dados que a criacao da fatura.

### RNF04 — Desempenho
A consulta de stock disponivel por produto e armazem deve responder em menos de 200ms.

### RNF05 — Auditoria
Todos os movimentos, ajustes e transferencias de stock devem gerar registos no modulo de auditoria.

### RNF06 — Rastreabilidade
Cada movimento de stock deve referenciar o documento que o originou (fatura, compra, ajuste) via reference_type e reference_id.
