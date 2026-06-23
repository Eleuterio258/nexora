# Requisitos — Modulo Contabilidade

## Requisitos Funcionais

### RF01 — Plano de Contas

O sistema deve gerir o plano de contas por tenant com codigo, nome, tipo de conta e indicacao de aceita lancamento.

### RF02 — Tipos de Conta

O sistema deve suportar tipos de conta com natureza debito ou credito (activo, passivo, capital, receita, despesa).

### RF03 — Anos Fiscais

O sistema deve gerir anos fiscais por tenant com data de inicio, data de fim e estado (aberto/fechado).

### RF04 — Periodos Fiscais

O sistema deve suportar periodos fiscais (mensais ou trimestrais) dentro de um ano fiscal, com estado de abertura e fecho.

### RF05 — Lancamentos Contabilisticos

O sistema deve registar lancamentos com numero unico, data, periodo fiscal, referencia e origem (tipo e ID do documento).

### RF06 — Equacao Contabilistica

Cada lancamento deve ter pelo menos duas linhas e o total de debitos deve ser igual ao total de creditos antes de confirmar.

### RF07 — Impostos e Grupos de IVA

O sistema deve gerir grupos de impostos, taxas com percentagem e regras de calculo, usados pelos modulos de faturacao e compras.

### RF08 — Transaccoes de Imposto

O sistema deve registar cada transaccao de imposto com base imponivel, taxa aplicada, valor calculado e referencia ao documento.

### RF09 — Balancete

O sistema deve gerar o balancete por periodo fiscal com totais de debito, credito e saldo por conta.

### RF10 — Balanco e Demonstracao de Resultados

O sistema deve gerar o balanco (activos, passivos, capital) e a demonstracao de resultados por periodo fiscal.

### RF11 — Activos Fixos

O sistema deve registar activos fixos com codigo, conta contabilistica, valor de aquisicao, valor residual, vida util e metodo de amortizacao (linear, degressive, unidades de producao).

### RF12 — Plano de Amortizacao

O sistema deve gerar automaticamente o plano de amortizacao de cada activo fixo ao longo da sua vida util, com valor de amortizacao, valor acumulado e valor contabilistico por periodo.

### RF13 — Processamento de Amortizacoes

O sistema deve processar as amortizacoes do periodo criando lancamentos contabilisticos automaticos (debito: gastos de amortizacao; credito: amortizacoes acumuladas).

### RF14 — Alienacao de Activo

O sistema deve registar a alienacao de um activo fixo, calculando o resultado da alienacao (valor de realizacao vs. valor contabilistico).

### RF15 — Orcamentos Contabilisticos

O sistema deve permitir definir um valor orcamentado por conta contabilistica e ano fiscal para comparacao com os valores realizados.

### RF16 — Encerramento de Periodo

O sistema deve gerir o processo de encerramento de periodo com verificacoes automaticas (balancete equilibrado, amortizacoes processadas, impostos fechados) antes de confirmar o fecho.

### RF17 — Verificacoes de Encerramento

O sistema deve executar e registar verificacoes individuais de encerramento com estado (pendente, ok, erro) e detalhe de eventuais erros encontrados.

### RF18 — Razao Geral

O sistema deve disponibilizar o razao geral por conta e periodo, com todos os lancamentos que afectam cada conta.

---

## Requisitos Nao Funcionais

### RNF01 — Imutabilidade de Periodos Fechados

Nao devem ser permitidos lancamentos em periodos fiscais com status fechado.

### RNF02 — Numeracao Sequencial

O numero de lancamento deve ser unico por tenant e sequencial, sem lacunas, gerado pelo sistema.

### RNF03 — Rastreabilidade

Cada lancamento deve referenciar o documento que o originou (fatura, compra, salario, amortizacao) via origem_tipo e origem_id.

### RNF04 — Encerramento Seguro

O fecho de periodo so deve ser possivel quando todas as verificacoes de encerramento estao com status ok.

### RNF05 — Auditoria

Criacao de lancamentos, processamento de amortizacoes e encerramento de periodos devem gerar registos no modulo de auditoria.

### RNF06 — Desempenho de Relatorios

A geracao do balancete para um periodo com ate 10.000 lancamentos deve concluir em menos de 5 segundos.

### RNF07 — Unicidade de Orcamento

Nao pode existir mais de um orcamento para a mesma combinacao tenant + conta + ano fiscal (constraint UNIQUE).
