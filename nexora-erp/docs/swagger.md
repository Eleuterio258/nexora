# Swagger / OpenAPI

O ficheiro principal de Swagger/OpenAPI do `nexora-erp` esta em:

- `docs/swagger.yaml`

## Cobertura atual

Esta primeira versao documenta:

- API Gateway
- `notifications-service`

## Como evoluir

Os proximos modulos a adicionar ao OpenAPI central devem ser:

1. `auth-service`
2. `compras-service`
3. `contabilidade-service`
4. `faturacao-service`

## Observacao

O repositório ainda nao tem `swagger-ui` servido por nenhum container. Neste momento, o ficheiro `docs/swagger.yaml` deve ser aberto numa ferramenta compatível com OpenAPI, como Swagger Editor ou Redoc.
