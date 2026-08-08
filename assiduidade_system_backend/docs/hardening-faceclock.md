# Guia de Hardening — FaceClock

**Data:** 2026-08-08
**Sistema:** FaceClock (`assiduidade_system_backend/`)
**Objectivo:** checklist de segurança operacional para além do que já está no código (encriptação, HMAC, rate limiting) — permissões de ficheiros, isolamento de rede, política de segredos.

---

## 1. Segredos

- **Nunca** commitar `.env` — já está no `.gitignore`, confirmar antes de cada `git add`.
- Gerar todos os segredos com `secrets.token_urlsafe(32)` (ver `docs/runbook-rotacao-chaves-self-hosted.md`), nunca reutilizar entre `BIOMETRIC_ENCRYPTION_KEY`, `FACIAL_VERIFICATION_SECRET` e `NEXORA_CREDENTIAL_ENCRYPTION_KEY` — são domínios de ameaça diferentes (comprometer um não deve comprometer os outros).
- `settings.assert_production_secrets()` já falha o arranque em `ENVIRONMENT=production` se algum segredo estiver no valor por omissão — não contornar isto em produção.
- Rodar `NEXORA_CREDENTIAL_ENCRYPTION_KEY` e `BIOMETRIC_ENCRYPTION_KEY`/`BIOMETRIC_ENCRYPTION_KEYS` periodicamente (ver runbook de rotação); documentar a data da última rotação fora do repositório (ex.: gestor de segredos, não em ficheiro versionado).
- Se uma credencial (chave AWS, password de BD, `.env`) for colada num chat, ticket, ou log por engano, considerá-la comprometida e rodar imediatamente — não esperar por confirmação de uso indevido.

## 2. Permissões de ficheiros

- `app/ml_models/*.onnx`, `*.tflite`, `*.task` — só leitura para o utilizador que corre o processo (`chmod 444` ou equivalente); nunca escritos em runtime.
- `.env` — `chmod 600`, propriedade do utilizador do serviço, nunca do grupo/world.
- Volumes Docker que persistem a BD (`postgres_data` no `docker-compose.yml`) — sem acesso de outros containers além do `postgres`/`pgadmin` explicitamente autorizados.

## 3. Isolamento de rede

- O FaceClock não deve estar exposto directamente à internet — só através do reverse proxy (Traefik/Nginx) com TLS terminado aí (ver `docs/runbook-deploy-producao-faceclock.md` secção 1).
- `DATABASE_URL`/`REDIS_URL` devem apontar para hosts só acessíveis na rede interna (VPC/rede Docker), nunca com a porta do Postgres/Redis publicada publicamente.
- Comunicação ERP↔FaceClock: autenticada por HMAC Nexora (já implementado) — ver secção 4 para mTLS como camada adicional.
- `NEXORA_HMAC_REQUIRE_HTTPS=true` (default) — não desactivar em produção; só faz sentido `false` em desenvolvimento local sem TLS.

## 4. mTLS ERP↔FaceClock (infraestrutura, não código)

O HMAC Nexora já garante autenticação e integridade das mensagens serviço-a-serviço. mTLS é uma camada adicional contra MITM ao nível de transporte, útil se o tráfego ERP↔FaceClock atravessar uma rede não totalmente confiável.

**Isto é configuração de infraestrutura (Traefik/Nginx + certificados), não uma alteração ao código do FaceClock** — nada em `app/` precisa de mudar; a aplicação continua a falar HTTP simples internamente, o TLS mútuo é terminado no reverse proxy.

Esboço de configuração com Traefik (`docker-compose.yml` / labels):

```yaml
# Exemplo ilustrativo — adaptar aos certificados reais emitidos para o ERP e o FaceClock.
services:
  faceclock:
    labels:
      - "traefik.http.routers.faceclock.tls=true"
      - "traefik.http.routers.faceclock.tls.options=mtls@file"

# traefik/dynamic/tls.yml
tls:
  options:
    mtls:
      clientAuth:
        caFiles:
          - /certs/erp-ca.pem
        clientAuthType: RequireAndVerifyClientCert
```

Passos (a executar por quem tem acesso à infraestrutura real, não algo que o FaceClock faça sozinho):

1. Gerar uma CA interna (ou usar uma já existente) para os certificados de serviço ERP/FaceClock — nunca reutilizar a CA pública usada para TLS de utilizador final.
2. Emitir um certificado cliente para o ERP e um certificado servidor para o FaceClock, ambos assinados por essa CA.
3. Configurar o reverse proxy do FaceClock para exigir certificado cliente válido (`RequireAndVerifyClientCert`) na rota usada pelo ERP.
4. Configurar o cliente HTTP do ERP (Go, `backend/internal/pkg/faceclock/client.go`) para apresentar o certificado cliente — isto sim é uma alteração de código, no lado do ERP, fora do âmbito deste documento.
5. Testar com `openssl s_client -connect faceclock.dominio:443 -cert erp-client.pem -key erp-client.key` antes de activar em produção.
6. Definir rotação/expiração dos certificados (ex.: 90 dias) e um processo de renovação — certificados expirados sem aviso são uma causa comum de outage.

**Não activar mTLS sem testar primeiro num ambiente de staging** — um erro de configuração aqui bloqueia toda a comunicação ERP↔FaceClock, incluindo o próprio `/health`.

## 5. Superfície de ataque

- `requirements-extras.txt` (anti-spoofing ONNX) só deve ser instalado onde o modelo treinado real estiver presente — instalar dependências não usadas aumenta a superfície de ataque sem benefício.
- Endpoints `/admin/*` exigem `require_nexora_signature("biometric:admin")` (ou `audit:read`) — nunca expor sem essa gate, mesmo atrás de rede interna (defesa em profundidade).
- `REQUIRE_IMAGE_SIGNATURE=true` deve ser activado assim que os dispositivos suportarem geração de chaves Ed25519 (ver `docs/runbook-deploy-producao-faceclock.md` secção 7.2) — sem isto, qualquer imagem chega ao pipeline biométrico sem prova de proveniência do dispositivo.
- Rever periodicamente `/admin/biometric/suspicious-activity` — contadores de falhas consecutivas por utilizador/dispositivo são o sinal mais barato de tentativa de ataque antes de escalar para análise mais profunda.

## 6. Auditoria e monitorização

- `/admin/biometric/audit-logs` (local) e `GET /audit/logs` (proxy ERP) são complementares — o local sobrevive a indisponibilidade do ERP, o do ERP tem visão cross-módulo.
- `/admin/biometric/metrics-dashboard` agrega métricas de processo (`biometric_metrics`, global, não por tenant) com actividade suspeita e resumo de auditoria (esses sim, por tenant) — ver nota de design no próprio endpoint.
- Nenhum destes substitui logs centralizados (ELK/Loki) mencionados no runbook de deploy — são complementares, não alternativos.

## Referências

- `docs/runbook-deploy-producao-faceclock.md` — checklist de deploy
- `docs/runbook-rotacao-chaves-self-hosted.md` — rotação de chaves
- `docs/self-hosted-faceclock.md` — stack mínima self-hosted
- `docs/proximas-implementacoes-self-hosted.md` — backlog de melhorias
