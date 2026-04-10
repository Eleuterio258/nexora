# Seguranca e Cloudflare

## Camadas principais

Com Cloudflare, a arquitetura pode usar:

- SSL automatico
- Firewall
- Protecao DDoS
- Rate limiting
- CDN

## Fluxo de seguranca

```text
User
 |
Cloudflare
 |
Traefik
 |
API
 |
Database
```

## Camadas adicionais em escala maior

```text
Cloudflare WAF
       |
Rate Limiting
       |
API Gateway
       |
Auth Service
       |
Backend
```
