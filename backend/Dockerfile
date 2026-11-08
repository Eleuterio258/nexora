FROM golang:1.25-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o nexora-api ./main.go
# nexora-worker corre os mesmos jobs em background (notificações, reminders)
# num processo separado da API — Fase 2, item 7. Opcional: por omissão a API
# continua a correr os jobs também (RUN_BACKGROUND_JOBS=true); ver
# docker-compose.yml na raiz do repositório para o serviço `worker`.
RUN CGO_ENABLED=0 GOOS=linux go build -o nexora-worker ./cmd/worker

FROM alpine:3.20
RUN apk --no-cache add ca-certificates tzdata
WORKDIR /app
COPY --from=builder /app/nexora-api .
COPY --from=builder /app/nexora-worker .
EXPOSE 8080
CMD ["./nexora-api"]
