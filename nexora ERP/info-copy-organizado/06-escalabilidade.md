# Escalabilidade

## Escala inicial

```text
               Load Balancer
                     |
         .-----------+-----------.
         |                       |
      Server 1               Server 2
      Traefik                Traefik
         |                       |
    Backend x3              Backend x3
         |                       |
             Database Cluster
```

## Fluxo de uma requisicao

```text
Cliente abre tenant1.e258tech.tech
        |
Cloudflare DNS
        |
Traefik
        |
Frontend React
        |
API Node.js
        |
Database MySQL
```
