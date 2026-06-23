# Requisitos — Modulo Multi-Moeda

## Requisitos Funcionais

### RF01 — Politicas de Taxa de Cambio
O sistema deve suportar tres politicas: taxa do dia (busca taxa vigente), taxa fixa (configurada manualmente) e taxa media mensal.

### RF02 — Documentos em Moeda Estrangeira
O sistema deve permitir emitir faturas, ordens de compra e pagamentos em moeda diferente da moeda base da empresa.

### RF03 — Conversao Automatica
Ao confirmar um documento em moeda estrangeira, o sistema deve calcular e registar o valor equivalente na moeda base usando a politica configurada.

### RF04 — Historico de Conversoes
O sistema deve manter historico de todas as conversoes realizadas com a taxa aplicada, para rastreabilidade contabilistica.

### RF05 — Regras de Arredondamento
O sistema deve suportar regras de arredondamento por moeda (casas decimais e metodo).

### RF06 — Consulta de Taxa Historica
O sistema deve permitir consultar a taxa de cambio vigente numa data especifica.

### RF07 — Relatorio de Exposicao Cambial
O sistema deve calcular a exposicao da empresa em moeda estrangeira (total de documentos em aberto por moeda).

---

## Requisitos Nao Funcionais

### RNF01 — Precisao
As conversoes devem usar no minimo 6 casas decimais na taxa de cambio para evitar erros de arredondamento.

### RNF02 — Consistencia Contabilistica
O lancamento contabilistico de um documento em moeda estrangeira deve registar tanto o valor original como o valor convertido em MZN.

### RNF03 — Imutabilidade
A taxa aplicada a um documento confirmado nao pode ser alterada retroactivamente.

### RNF04 — Auditoria
Criacao de politicas e alteracoes de taxas fixas devem gerar registos de auditoria.
