# Requisitos — Modulo Impostos Avancados

## Requisitos Funcionais

### RF01 — Regimes Fiscais
O sistema deve suportar a configuracao de regimes fiscais por tenant (simplificado, normal, isento).

### RF02 — Isencoes de IVA
O sistema deve permitir registar isencoes de IVA para clientes, fornecedores, produtos ou categorias, com numero de isencao e validade.

### RF03 — Aplicacao Automatica de Isencoes
Ao emitir um documento, o sistema deve verificar se existe isencao activa e aplicar automaticamente taxa 0%.

### RF04 — Retencoes na Fonte
O sistema deve calcular e registar retencoes na fonte (IRPS, IRPC) em pagamentos a fornecedores e colaboradores.

### RF05 — Declaracao de IVA
O sistema deve gerar automaticamente a declaracao periodica de IVA (IVA liquidado - IVA dedutivel = IVA a pagar/recuperar).

### RF06 — Declaracao de Retencoes
O sistema deve gerar a declaracao de retencoes na fonte realizadas no periodo, para entrega a AT.

### RF07 — Certificados Fiscais
O sistema deve gerir certificados de contribuinte (isencao, bom contribuinte) com numero, emissao e validade.

### RF08 — Alerta de Validade
O sistema deve alertar quando certificados ou isencoes estao proximos do vencimento (30 dias de antecedencia).

---

## Requisitos Nao Funcionais

### RNF01 — Conformidade Legal
O calculo de impostos deve respeitar a legislacao fiscal moçambicana vigente (Codigo do IVA, IRPS, IRPC).

### RNF02 — Imutabilidade de Declaracoes Submetidas
Uma declaracao submetida a AT nao deve poder ser alterada. Apenas pode ser substituida por uma declaracao de substituicao.

### RNF03 — Rastreabilidade
Cada retencao e cada linha de declaracao devem ser rastreaveis ao documento de origem.

### RNF04 — Auditoria
Criacao de isencoes, submissao de declaracoes e registo de retencoes devem gerar registos de auditoria.
