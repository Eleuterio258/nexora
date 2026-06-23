# API CRM

## Pipelines

### POST /api/crm/pipelines
### GET /api/crm/pipelines
### PUT /api/crm/pipelines/{id}

## Stages

### POST /api/crm/pipelines/{id}/stages
### GET /api/crm/pipelines/{id}/stages
### PUT /api/crm/pipelines/{id}/stages/{stage_id}

## Leads

### POST /api/crm/leads
### GET /api/crm/leads
### GET /api/crm/leads/{id}
### PUT /api/crm/leads/{id}
### POST /api/crm/leads/{id}/converter

## Opportunities

### POST /api/crm/opportunities
### GET /api/crm/opportunities
### GET /api/crm/opportunities/{id}
### PUT /api/crm/opportunities/{id}
### POST /api/crm/opportunities/{id}/mover-stage
### POST /api/crm/opportunities/{id}/ganhar
### POST /api/crm/opportunities/{id}/perder

## Contacts

### POST /api/crm/contacts
### GET /api/crm/contacts
### PUT /api/crm/contacts/{id}

## Activities

### POST /api/crm/activities
### GET /api/crm/activities
### PUT /api/crm/activities/{id}
### POST /api/crm/activities/{id}/concluir

## Notes

### POST /api/crm/notes
### GET /api/crm/notes?opportunity_id={}&lead_id={}

## Reports

### GET /api/crm/relatorio/pipeline
### GET /api/crm/relatorio/funil
### GET /api/crm/relatorio/previsao
