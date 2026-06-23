# API Impostos Avancados

## Tax Regimes

### POST /api/impostos/regimes
### GET /api/impostos/regimes

## Tax Exemptions

### POST /api/impostos/isencoes
### GET /api/impostos/isencoes
### PUT /api/impostos/isencoes/{id}
### DELETE /api/impostos/isencoes/{id}

## Withholding Taxes

### POST /api/impostos/retencoes
### GET /api/impostos/retencoes
### GET /api/impostos/retencoes/{id}/transaccoes

## Tax Returns

### POST /api/impostos/declaracoes
### GET /api/impostos/declaracoes
### GET /api/impostos/declaracoes/{id}
### POST /api/impostos/declaracoes/{id}/submeter
### GET /api/impostos/declaracoes/{id}/linhas

## Tax Certificates

### POST /api/impostos/certificados
### GET /api/impostos/certificados?entity_type={}&entity_id={}
