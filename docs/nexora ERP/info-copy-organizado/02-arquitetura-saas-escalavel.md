# Arquitetura SaaS Escalavel

## Visao geral

```text
                Internet
                    |
              Cloudflare DNS
        (SSL + WAF + CDN + Cache)
                    |
             VPS / Cloud Server
                    |
           Traefik Reverse Proxy
                    |
        .-----------+-----------.
        |           |           |
     Frontend      API        Admin
      React       Node        Panel
                    |
              Internal Network
                    |
              .-------------.
              |   Database  |
              `-------------`
                    |
                 Redis
```
