# Requisitos — Modulo Centros de Custo

## Requisitos Funcionais

### RF01 — Criacao de Centros de Custo
O sistema deve permitir criar centros de custo com codigo unico, nome e centro de custo pai (hierarquia).

### RF02 — Hierarquia de Dois Niveis
O sistema deve suportar hierarquia de centros de custo (ex: Departamento > Projecto).

### RF03 — Orcamento por Periodo
O sistema deve permitir definir orcamento de receita e despesa por centro de custo e periodo fiscal.

### RF04 — Alocacao de Lancamentos
Ao criar um lancamento contabilistico, o utilizador deve poder alocar a percentagem a um ou mais centros de custo.

### RF05 — Alocacao Automatica
O sistema deve suportar regras de alocacao automatica para lancamentos de determinados tipos ou contas.

### RF06 — Movimentos por Centro
O sistema deve registar todos os movimentos (receita e despesa) por centro de custo com referencia ao documento origem.

### RF07 — Relatorio Orcado vs Realizado
O sistema deve gerar relatorio comparando o valor orcamentado com o realizado por centro de custo e periodo.

### RF08 — Desactivacao
O sistema deve permitir desactivar um centro de custo sem eliminar o seu historico.

---

## Requisitos Nao Funcionais

### RNF01 — Consistencia com Contabilidade
Os movimentos de centros de custo devem estar sempre sincronizados com os lancamentos contabilisticos.

### RNF02 — Soma de Percentagens
Quando um lancamento e alocado a multiplos centros, a soma das percentagens deve ser igual a 100%.

### RNF03 — Auditoria
Criacao de centros, definicao de orcamentos e alocacoes devem gerar registos de auditoria.

### RNF04 — Desempenho
O relatorio orcado vs realizado para um periodo com ate 50 centros deve responder em menos de 2 segundos.
