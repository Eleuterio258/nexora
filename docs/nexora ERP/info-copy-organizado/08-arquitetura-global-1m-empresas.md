# Arquitetura Global para 1M Empresas

## Visao global

```text
                 Internet
                     |
              Cloudflare CDN
      (DNS + WAF + SSL + DDoS)
                     |
             Global Load Balancer
                     |
        .------------+------------.
        |            |            |
     Region 1     Region 2     Region 3
     Europe       Africa       America
```

## Dentro de uma regiao

```text
            Load Balancer
                 |
        .--------+--------.
        |        |        |
    API Node  API Node  API Node
        |        |        |
        `--------+--------'
                 |
           Service Layer
                 |
      .----------+----------.
      |          |          |
    Auth      Billing     ERP Core
                 |
               Redis
                 |
          Database Cluster
```
