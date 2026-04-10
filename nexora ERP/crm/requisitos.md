# Requisitos — Modulo CRM

## Requisitos Funcionais

### RF01 — Pipelines Configurados
O sistema deve permitir criar pipelines de venda com etapas ordenadas, probabilidade e tipo (aberta, ganha, perdida).

### RF02 — Gestao de Leads
O sistema deve registar leads com nome, empresa, contacto, origem e estado de qualificacao.

### RF03 — Qualificacao de Lead
O sistema deve suportar os estados de lead: novo, contactado, qualificado, desqualificado e convertido.

### RF04 — Conversao de Lead em Cliente
O sistema deve permitir converter um lead qualificado em cliente no modulo gestao-clientes, criando automaticamente o registo.

### RF05 — Oportunidades de Venda
O sistema deve registar oportunidades com valor estimado, probabilidade de fecho, data prevista e etapa no pipeline.

### RF06 — Movimento de Etapa
O sistema deve permitir mover uma oportunidade entre etapas do pipeline com registo do historico de movimentos.

### RF07 — Registo de Actividades
O sistema deve registar actividades (chamadas, reunioes, emails, demos) associadas a oportunidades ou leads.

### RF08 — Gestao de Contactos
O sistema deve gerir contactos por cliente ou lead, com cargo, email, telefone e LinkedIn.

### RF09 — Relatorio de Funil
O sistema deve mostrar o funil de vendas: quantidade e valor por etapa do pipeline.

### RF10 — Previsao de Receita
O sistema deve calcular a receita prevista por periodo: soma de (valor_oportunidade x probabilidade) para oportunidades abertas.

---

## Requisitos Nao Funcionais

### RNF01 — Kanban em Tempo Real
A vista de pipeline em kanban deve actualizar em tempo real ao mover oportunidades entre etapas.

### RNF02 — Atribuicao de Responsavel
Cada lead e oportunidade deve ter um responsavel. O sistema deve filtrar por responsavel na listagem.

### RNF03 — Alertas de Actividades
O sistema deve enviar notificacao ao responsavel quando uma actividade fica em atraso (data_prevista < hoje).

### RNF04 — Auditoria
Criacao de leads, movimentos de etapa e fecho de oportunidades devem gerar registos de auditoria.

### RNF05 — Desempenho de Pipeline
O carregamento do pipeline com ate 500 oportunidades abertas deve responder em menos de 1 segundo.
