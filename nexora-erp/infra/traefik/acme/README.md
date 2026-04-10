# ACME Certificates Directory

This directory stores Let's Encrypt SSL certificates.

## Important

- The `acme.json` file will be automatically created when Traefik starts
- This file contains your SSL certificates and private keys
- **KEEP THIS FILE SECURE** - Do not commit to git in production
- Permissions will be set to 600 (owner read/write only)

## Setup

The directory is mounted as a volume in the Traefik container:
```
./infra/traefik/acme:/etc/traefik/acme
```

Traefik will automatically:
1. Request a certificate from Let's Encrypt on first start
2. Store it in `acme.json`
3. Renew certificates automatically before expiration
