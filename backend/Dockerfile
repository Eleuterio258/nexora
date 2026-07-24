FROM golang:1.25-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
# O replace em go.mod aponta para ./third_party/digitorus-pdfsign, que precisa
# de existir antes do download resolver o módulo local.
COPY third_party/ ./third_party/
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o nexora-api ./main.go

FROM alpine:3.20
RUN apk --no-cache add ca-certificates tzdata
WORKDIR /app
COPY --from=builder /app/nexora-api .
EXPOSE 8080
CMD ["./nexora-api"]
