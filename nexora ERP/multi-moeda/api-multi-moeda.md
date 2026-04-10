# API Multi-Moeda

## Exchange Rate Policies

### POST /api/multi-moeda/policies
### GET /api/multi-moeda/policies
### PUT /api/multi-moeda/policies/{id}

## Conversions

### POST /api/multi-moeda/converter
### GET /api/multi-moeda/taxa?from={moeda}&to={moeda}&data={date}
### GET /api/multi-moeda/historico

## Document Currencies

### GET /api/multi-moeda/documentos/{tipo}/{id}

## Rounding Rules

### POST /api/multi-moeda/arredondamento
### GET /api/multi-moeda/arredondamento
### PUT /api/multi-moeda/arredondamento/{currency}
