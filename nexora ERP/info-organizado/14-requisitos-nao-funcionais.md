# Requisitos Nao Funcionais do Sistema de Faturacao

## 1. Introducao

Este documento descreve os requisitos nao funcionais do sistema de faturacao. Os requisitos nao funcionais definem atributos de qualidade, restricoes operacionais e caracteristicas tecnicas esperadas do sistema.

## 2. Requisitos nao funcionais

### RNF01. Seguranca

O sistema deve proteger autenticacao, autorizacao, sessao e dados sensiveis.

### RNF02. Desempenho

Operacoes comuns, como listar clientes, listar produtos e emitir fatura, devem responder rapidamente em condicoes normais de uso.

### RNF03. Disponibilidade

O sistema deve ter alta disponibilidade em ambiente de producao.

### RNF04. Escalabilidade

O sistema deve suportar crescimento do numero de utilizadores, tenants, produtos e faturas sem perda severa de desempenho.

### RNF05. Usabilidade

As telas devem ser simples, claras e adequadas para operadores administrativos e comerciais.

### RNF06. Integridade de dados

O sistema deve garantir consistencia entre cliente, fatura, itens, pagamento e estoque.

### RNF07. Auditabilidade

Todas as operacoes criticas devem ser rastreaveis com utilizador, acao, data e entidade afetada.

### RNF08. Portabilidade

O sistema deve poder ser executado em ambiente web e, se necessario, adaptado para mobile.

### RNF09. Manutenibilidade

O codigo deve ser modular, documentado e de facil evolucao.

### RNF10. Backup e recuperacao

O sistema deve permitir backups regulares e recuperacao de dados em caso de falha.

### RNF11. Conformidade legal

O sistema deve permitir configuracao conforme a legislacao fiscal aplicavel, incluindo IVA, numeracao e identificacao fiscal.

### RNF12. Multi-tenant seguro

O sistema deve isolar os dados de cada tenant para impedir acesso cruzado entre empresas.

## 3. Regras de negocio relacionadas

### RN01. Cliente obrigatorio

Nao e permitido emitir fatura sem cliente associado, salvo regra especifica de consumidor final.

### RN02. Fatura deve ter itens

Nenhuma fatura pode ser emitida sem pelo menos um item.

### RN03. Estoque suficiente

Nao e permitido confirmar venda de produto com estoque insuficiente, exceto se a empresa permitir venda sem estoque.

### RN04. Calculo do IVA

O IVA deve ser calculado com base na taxa configurada por produto ou regra fiscal.

### RN05. Numero unico

Cada documento deve possuir numero unico dentro da sua serie.

### RN06. Conversao documental

Uma proforma pode ser convertida em fatura, preservando os dados principais do documento.

### RN07. Pagamento parcial

Uma fatura pode permanecer em estado parcialmente pago ate a liquidacao total.

### RN08. Auditoria obrigatoria

Criacao, edicao, cancelamento e pagamento de documentos devem gerar log de auditoria.

## 4. Diretrizes tecnicas recomendadas

- usar autenticacao segura e controlo de sessoes
- isolar dados por tenant em todas as consultas e operacoes
- registar logs de auditoria para eventos criticos
- preparar backups automatizados
- organizar o sistema em modulos independentes
- permitir crescimento horizontal dos servicos
- garantir consistencia transacional na emissao de faturas e pagamentos
