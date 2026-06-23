# Docker Compose Exemplo

## Estrutura de containers

```text
docker-compose
|
|-- traefik
|-- frontend
|-- backend
|-- database
|-- redis
|-- worker
`-- backup
```

## Exemplo

```yaml
version: '3.8'

services:
  traefik:
    image: traefik:v3.0
    command:
      - "--api.insecure=true"
      - "--providers.docker=true"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock

  backend:
    image: erp-backend
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.api.rule=Host(`api.e258tech.tech`)"
      - "traefik.http.routers.api.entrypoints=websecure"

  frontend:
    image: erp-frontend
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.front.rule=Host(`erp.e258tech.tech`)"
      - "traefik.http.routers.front.entrypoints=websecure"

  mysql:
    image: mysql:8
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: erp
    volumes:
      - mysql_data:/var/lib/mysql

  redis:
    image: redis:7

volumes:
  mysql_data:
```
