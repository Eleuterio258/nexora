# Requisitos — Modulo Faturacao

## Requisitos Funcionais

### RF01 — Series Documentais

O sistema deve gerir series documentais por tipo (ORC, ENC, GR, FT, NC, RB), ano e tenant, com sequencia atomica que garante numeracao sem lacunas nem duplicados.

### RF02 — Orcamentos

O sistema deve permitir criar orcamentos com validade, itens com preco, desconto por linha e imposto por linha. O total deve ser calculado automaticamente.

### RF03 — Conversao de Orcamento

O sistema deve converter um orcamento aprovado em encomenda de venda sem reintroducao de dados, transitando o orcamento para estado convertido.

### RF04 — Encomendas de Venda

O sistema deve gerir encomendas com estados: rascunho, confirmada, parcial, entregue, cancelada. A confirmacao deve verificar a disponibilidade de stock.

### RF05 — Guias de Remessa

O sistema deve gerar guias de remessa a partir de encomendas com controlo de entrega parcial por linha, actualizando a quantidade entregue na encomenda.

### RF06 — Emissao de Faturas

O sistema deve emitir faturas com numero definitivo a partir de serie configurada, associadas a encomendas ou directamente a clientes, com calculo automatico de subtotal, desconto, IVA e total.

### RF07 — Desconto por Linha e por Documento

O sistema deve suportar desconto percentual e de valor fixo ao nivel de cada linha de fatura e ao nivel do documento (header).

### RF08 — IVA por Linha

O sistema deve calcular e registar o IVA separadamente por linha, com referencia a taxa, base imponivel e valor, consolidando no resumo de impostos da fatura.

### RF09 — Saldo Pendente Calculado

O saldo pendente da fatura deve ser coluna computed (`GENERATED ALWAYS AS STORED`: total - valor_pago) para garantir consistencia.

### RF10 — Recibos de Pagamento

O sistema deve emitir recibos numerados a partir de serie propria, associados a faturas, suportando pagamentos parciais com actualizacao atomica do saldo da fatura.

### RF11 — Estado Automatico de Fatura

O sistema deve actualizar automaticamente o estado da fatura para parcialmente_paga, paga ou vencida conforme os pagamentos recebidos e a data de vencimento.

### RF12 — Notas de Credito

O sistema deve emitir notas de credito como documento fiscal independente (serie NC), com referencia facultativa a fatura original e possibilidade de aplicar como credito.

### RF13 — Cancelamento por Nota de Credito

A anulacao de uma fatura emitida deve ser feita atraves de nota de credito pelo valor total, nunca por eliminacao directa.

### RF14 — Devolucoes Fisicas

O sistema deve registar devolucoes fisicas de mercadoria com controlo por produto, quantidade e estado do produto devolvido, com actualizacao de stock ao confirmar recepcao.

### RF15 — Ciclo Completo Orcamento-Fatura

O sistema deve suportar o ciclo completo: Orcamento -> Encomenda -> Guia de Remessa -> Fatura -> Recibo.

### RF16 — Exportacao PDF

O sistema deve exportar em PDF cada tipo de documento: orcamento, encomenda, guia de remessa, fatura, recibo e nota de credito.

### RF17 — Relatorios de Vendas

O sistema deve gerar relatorios de vendas por periodo, por cliente, por produto, antiguidade de saldos e resumo de IVA para declaracao fiscal.

---

## Requisitos Nao Funcionais

### RNF01 — Numeracao Atomica

A geracao do numero de documento deve ser atomica (SELECT ... FOR UPDATE na serie) para garantir unicidade em ambiente multi-utilizador.

### RNF02 — Imutabilidade Pos-Emissao

Uma fatura, nota de credito ou recibo emitidos nao podem ser alterados. Qualquer correcao requer emissao de novo documento.

### RNF03 — Atomicidade com Stock

A emissao de fatura e a baixa de stock devem ocorrer na mesma transaccao de base de dados.

### RNF04 — Atomicidade com Financeiro

O registo de recibo e a actualizacao do saldo da fatura e da conta a receber no modulo financeiro devem ocorrer na mesma transaccao.

### RNF05 — Auditoria

Emissao, cancelamento e registo de recibos devem gerar registos no modulo de auditoria.

### RNF06 — Desempenho

A emissao de uma fatura com ate 50 linhas deve concluir em menos de 1 segundo.

### RNF07 — Conformidade Fiscal

O calculo de IVA deve suportar isencoes, taxa zero e multiplas taxas por documento, respeitando as regras fiscais vigentes.
