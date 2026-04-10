# Observabilidade e Custos

## Observabilidade

| Tipo | Ferramenta |
| --- | --- |
| Logs | ELK Stack |
| Monitoramento | Prometheus |
| Dashboards | Grafana |
| Erro | Sentry |

## Fluxo completo

```text
User
 |
Cloudflare
 |
Load Balancer
 |
Kubernetes Cluster
 |
API Service
 |
Redis Cache
 |
Database Cluster
 |
Object Storage
```

## Custos aproximados

| Escala | Custo mensal |
| --- | --- |
| 10k empresas | $1k-$3k |
| 100k empresas | $10k-$30k |
| 1M empresas | $80k-$200k |
