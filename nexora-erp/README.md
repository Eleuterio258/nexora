# Nexora ERP

Sistema ERP (Enterprise Resource Planning) moderno baseado em microsserviços, projetado para gestão empresarial completa.

## 🚀 Início Rápido

### Pré-requisitos

- Docker (versão 24+)
- Docker Compose (versão 2.20+)
- Git
- 4GB+ de RAM disponível

### 1. Clonar o Repositório

```bash
git clone https://github.com/Eleuterio258/nexora-erp.git
cd nexora-erp
```

### 2. Configurar Variáveis de Ambiente

```bash
# Copiar o ficheiro de exemplo
cp .env.example .env

# Editar com as suas configurações
# ATENÇÃO: Altere todas as passwords e segredos!
```

**Variáveis obrigatórias:**
- `JWT_SECRET` - Segredo para tokens JWT (gerar com `openssl rand -base64 64`)
- `JWT_REFRESH_SECRET` - Segredo para tokens de refresh
- `DB_PASSWORD` - Password do PostgreSQL
- `REDIS_PASSWORD` - Password do Redis
- `RABBITMQ_PASS` - Password do RabbitMQ

### 3. Iniciar o Sistema

```bash
# Construir e iniciar todos os serviços
docker compose up -d

# Verificar status
docker compose ps

# Ver logs
docker compose logs -f
```

### 4. Aceder às APIs

- **API Principal:** https://nexora-erp.e258tech.tech
- **Traefik Dashboard:** https://nexora-erp.e258tech.tech/dashboard (requer autenticação)
- **API Endpoints:**
  - Auth: `https://nexora-erp.e258tech.tech/api/auth/...`
  - Empresas: `https://nexora-erp.e258tech.tech/api/companies/...`
  - Faturação: `https://nexora-erp.e258tech.tech/api/faturacao/...`
  - (todos os 24 serviços disponíveis)

### 5. Configurar DNS (Produção)

Para usar o seu próprio domínio:

1. Crie um registo DNS do tipo `A`:
   - **Host:** `nexora-erp.e258tech.tech`
   - **Valor:** `<IP do seu servidor>`

2. O Traefik irá automaticamente:
   - Solicitar certificado SSL da Let's Encrypt
   - Redirecionar HTTP → HTTPS
   - Gerir renovação automática de certificados

## 📦 Arquitetura

### Microsserviços (24 total)

| Serviço | Porta | Descrição |
|---------|-------|-----------|
| auth-service | 3001 | Autenticação e autorização |
| empresa-service | 3002 | Gestão de empresas/tenants |
| faturacao-service | 3003 | Faturação e documentos fiscais |
| autorizacao-service | 3004 | Controle de acesso e permissões |
| clientes-service | 3005 | Gestão de clientes |
| produtos-service | 3006 | Catálogo de produtos |
| impostos-service | 3007 | Configuração de impostos |
| stock-service | 3008 | Gestão de inventário |
| financeiro-service | 3009 | Contas a pagar/receber |
| tesouraria-service | 3010 | Gestão de contas bancárias |
| compras-service | 3011 | Processo de compras |
| contabilidade-service | 3012 | Gestão contabilística |
| recursos-humanos-service | 3013 | Gestão de RH e folha |
| multi-moeda-service | 3014 | Suporte multi-moeda |
| sistema-configuracao-service | 3015 | Configurações do sistema |
| auditoria-service | 3016 | Logs de auditoria |
| crm-service | 3017 | Gestão de relacionamento |
| pos-service | 3018 | Ponto de venda |
| centros-custo-service | 3019 | Centros de custo |
| seguranca-service | 3020 | Políticas de segurança |
| assinaturas-service | 3021 | Gestão de assinaturas |
| notifications-service | 3022 | Notificações (email, SMS, WhatsApp) |
| logistica-service | 3023 | Gestão logística |
| gestao-escolar-service | 3024 | Módulo escolar |

### Infraestrutura

- **API Gateway:** Traefik v3.0
- **Base de Dados:** PostgreSQL 16 (schema-per-tenant)
- **Cache:** Redis 7.2
- **Message Broker:** RabbitMQ 3.13

## 🛠️ Desenvolvimento

### Executar um Serviço Localmente (fora do Docker)

```bash
# Instalar dependências
cd services/auth-service
npm install

# Copiar .env do projeto root
cp ../../.env .

# Iniciar em modo desenvolvimento
npm run dev
```

### Base de Dados

#### Executar Migrações

```bash
# Dentro do container ou localmente
node scripts/migrate.js

# Migrar um serviço específico
node scripts/migrate.js auth

# Listar migrações pendentes
node scripts/migrate.js --list
```

#### Dados de Demonstração

O sistema inclui dados seed com:
- Tenant de demonstração (ID: 1)
- Utilizador admin: `admin@nexora.local` / `Admin@123`
- Empresa de demonstração
- Produtos de exemplo

## 📚 Documentação

### API Documentation

Documentação OpenAPI/Swagger disponível em `docs/swagger.yaml`.

Para visualizar:
1. Aceda a https://editor.swagger.io/
2. Cole o conteúdo do ficheiro `docs/swagger.yaml`

### Documentação por Módulo

Cada módulo na pasta `nexora ERP/` contém:
- `README.md` - Visão geral
- `requisitos.md` - Requisitos do módulo
- `api-*.md` - Documentação da API
- `database-*.sql` - Schema da base de dados
- `uml.md` - Diagramas UML

## 🔐 Segurança

### Antes de Publicar em Produção

- [ ] Alterar todas as passwords no ficheiro `.env`
- [ ] Gerar novos `JWT_SECRET` e `JWT_REFRESH_SECRET`
- [ ] Alterar credenciais do Traefik Dashboard (executar `node scripts/generate-traefik-credentials.js`)
- [ ] Configurar CORS corretamente (não usar `*` em produção)
- [ ] Ativar HTTPS/TLS no Traefik
- [ ] Rever políticas de rate limiting
- [ ] Configurar backups automáticos da base de dados
- [ ] Configurar monitorização e alertas

## 🚧 Estado Atual

**Status:** Desenvolvimento/Testing ✅
**Produção:** Requer ajustes de segurança ⚠️

### Funcionalidades Completas
- ✅ 24 microsserviços estruturados
- ✅ API Gateway com autenticação JWT
- ✅ Base de dados com schema isolation
- ✅ Health checks em todos os serviços
- ✅ Docker Compose para orquestração
- ✅ Migrations de base de dados
- ✅ Dados seed para demonstração

### A Melhorar
- ⚠️ Testes automatizados
- ⚠️ CI/CD pipeline
- ⚠️ Integração RabbitMQ (atualmente disponível mas não utilizada)
- ⚠️ Dispatchers reais para notificações (SMTP, SMS, WhatsApp)
- ⚠️ Documentação OpenAPI completa

## 📝 Scripts Úteis

```bash
# Gerar credenciais seguras para Traefik
node scripts/generate-traefik-credentials.js

# Executar migrações da base de dados
node scripts/migrate.js

# Ver logs de um serviço
docker compose logs -f auth-service

# Reiniciar um serviço
docker compose restart auth-service

# Parar tudo
docker compose down

# Parar e limpar volumes (CUIDADO: apaga dados!)
docker compose down -v
```

## 🤝 Contribuir

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto é propriedade de **e-258tech** e **Nexora**. Todos os direitos reservados.

## 👥 Equipa

- **Eleuterio** - [GitHub](https://github.com/Eleuterio258)
- **e-258tech** - Desenvolvimento e consultoria

---

**Versão:** 1.0.0  
**Última atualização:** Abril 2026
