# Configuração de Domínio e DNS

## Domínio Configurado: `nexora-erp.e258tech.tech`

### 1. Registos DNS Necessários

Crie os seguintes registos no seu fornecedor de DNS:

| Tipo | Host | Valor | TTL |
|------|------|-------|-----|
| A | nexora-erp.e258tech.tech | `<IP_DO_SEU_SERVIDOR>` | 300 |
| CNAME | www (opcional) | nexora-erp.e258tech.tech | 300 |

### 2. Certificado SSL (Automático)

O Traefik utiliza **Let's Encrypt** para gerar certificados SSL automaticamente:

- ✅ Certificado solicitado automaticamente no primeiro arranque
- ✅ Renovação automática antes da expiração
- ✅ Armazenado em `infra/traefik/acme/acme.json`
- ✅ Redirecionamento HTTP → HTTPS ativado

### 3. Endpoints Disponíveis

Todos os serviços estão acessíveis via HTTPS:

| Serviço | URL |
|---------|-----|
| API Gateway | https://nexora-erp.e258tech.tech |
| Dashboard | https://nexora-erp.e258tech.tech/dashboard |
| Auth | https://nexora-erp.e258tech.tech/api/auth/* |
| Empresas | https://nexora-erp.e258tech.tech/api/companies/* |
| Faturação | https://nexora-erp.e258tech.tech/api/faturacao/* |
| Clientes | https://nexora-erp.e258tech.tech/api/clientes/* |
| Produtos | https://nexora-erp.e258tech.tech/api/produtos/* |
| Stock | https://nexora-erp.e258tech.tech/api/stock/* |
| Financeiro | https://nexora-erp.e258tech.tech/api/financeiro/* |
| CRM | https://nexora-erp.e258tech.tech/api/crm/* |
| POS | https://nexora-erp.e258tech.tech/api/pos/* |
| ... | ... (todos os 24 serviços) |

### 4. Verificar Configuração

Após configurar o DNS e iniciar o sistema:

```bash
# Verificar certificado SSL
curl -I https://nexora-erp.e258tech.tech/api/auth/health

# Verificar redirecionamento HTTP -> HTTPS
curl -I http://nexora-erp.e258tech.tech

# Verificar resposta da API
curl https://nexora-erp.e258tech.tech/api/auth/health
```

### 5. Resolução de Problemas

**Certificado não foi gerado:**
```bash
# Verificar logs do Traefik
docker compose logs traefik

# Verificar se acme.json existe
ls -la infra/traefik/acme/

# Forçar renovação (apagar certificado atual)
rm infra/traefik/acme/acme.json
docker compose restart traefik
```

**Domínio não resolve:**
```bash
# Verificar registo DNS
nslookup nexora-erp.e258tech.tech

# Verificar propagação DNS
dig nexora-erp.e258tech.tech
```

### 6. Segurança Adicional

Para produção, considere:

- [ ] Restringir acesso ao dashboard por IP
- [ ] Ativar HSTS (HTTP Strict Transport Security)
- [ ] Configurar Content Security Policy
- [ ] Ativar OCSP Stapling
- [ ] Monitorizar expiração de certificados
