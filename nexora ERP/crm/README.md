# Modulo CRM

## Objetivo

Gerir o ciclo de relacionamento com clientes: leads, oportunidades de venda, actividades e pipeline comercial.

## Escopo

- Pipelines de venda configurados por tenant
- Gestao de leads com origem e qualificacao
- Oportunidades com valor estimado, probabilidade e data de fecho prevista
- Actividades (chamadas, reunioes, demos, tarefas) associadas a oportunidades e leads
- Contactos associados a clientes ou leads
- Notas internas
- Relatorios de funil, pipeline e previsao de receita

## Entidades

- `crm_pipelines`
- `crm_stages`
- `crm_leads`
- `crm_opportunities`
- `crm_contacts`
- `crm_activities`
- `crm_notes`
- `crm_tags` + `crm_tag_links`

## Dependencias

- Depende de: `autenticacao` (responsavel_id, user_id)
- Integra com: `gestao-clientes` (customer_id ao converter lead)
- Alimenta: `modulo-faturacao` (ao ganhar oportunidade -> criar proposta/fatura)

## Arquivos

- `database-crm.sql`
- `api-crm.md`
- `requisitos.md`
- `uml.md`
