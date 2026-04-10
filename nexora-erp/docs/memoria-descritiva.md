# Memória Descritiva — Nexora ERP

**Versão:** 1.0
**Data:** 2026-03-27
**Empresa:** E-258Tech
**Classificação:** Técnica / Interna

---

## 1. Identificação do Projecto

| Campo | Valor |
|---|---|
| Nome do sistema | Nexora ERP |
| Tipo | ERP SaaS multi-tenant |
| Mercado alvo | República de Moçambique |
| Versão actual | 1.0.0 |
| Repositório | `d:/projecto/e-258tech/2026/factPro/nexora-erp` |

---

## 2. Objectivo e Âmbito

O **Nexora ERP** é uma plataforma de gestão empresarial (ERP) concebida para empresas moçambicanas, disponibilizada em modelo SaaS (Software as a Service). O sistema substitui soluções de origem estrangeira como Primavera e Odoo, oferecendo uma alternativa nativa adaptada à legislação fiscal, monetária e operacional de Moçambique.

O sistema abrange os seguintes domínios funcionais:

- Gestão comercial e facturação conforme requisitos da AT (Autoridade Tributária)
- Contabilidade e finanças em conformidade com o PCISM
- Gestão de recursos humanos e processamento salarial
- Ponto de venda (POS) com integração de pagamentos móveis (M-Pesa, E-Mola)
- Gestão de assinaturas e facturação recorrente
- Auditoria, autenticação e controlo de acessos
- Notificações multi-canal (e-mail, SMS, WhatsApp, push)

---

## 3. Arquitectura do Sistema

### 3.1 Modelo arquitectural

O Nexora ERP adopta uma arquitectura de **microserviços**, em que cada domínio de negócio é implementado como um serviço independente, com base de dados própria (padrão *database-per-service*). Os serviços comunicam entre si via HTTP (REST) sincronamente e via mensageria assíncrona (RabbitMQ) para eventos de domínio.

```
Cloudflare (CDN + DDoS)
        │
        ▼
    Traefik (API Gateway / Reverse Proxy)
        │
        ├── auth-service            (JWT, sessões)
        ├── empresa-service
        ├── faturacao-service
        ├── clientes-service
        ├── produtos-service
        ├── stock-service
        ├── compras-service
        ├── pos-service
        ├── logistica-service
        ├── assinaturas-service
        ├── financeiro-service
        ├── tesouraria-service
        ├── contabilidade-service
        ├── impostos-service
        ├── multi-moeda-service
        ├── recursos-humanos-service
        ├── centros-custo-service
        ├── crm-service
        ├── gestao-escolar-service
        ├── autorizacao-service
        ├── auditoria-service
        ├── sistema-configuracao-service
        ├── notifications-service
        └── seguranca-service

    Infra compartilhada:
        ├── PostgreSQL (instância por serviço)
        ├── RabbitMQ  (mensageria de eventos)
        └── Redis     (cache / sessões)
```

### 3.2 Multi-tenancy

Todos os serviços implementam isolamento de dados por tenant. Cada tenant corresponde a uma empresa cliente do SaaS. O `tenant_id` é propagado via token JWT (campo `tid`) e aplicado em todas as queries como predicado obrigatório.

```
https://empresa-a.nexoraerp.co.mz  →  tenant_id = 101
https://empresa-b.nexoraerp.co.mz  →  tenant_id = 102
```

### 3.3 Autenticação e Autorização

- **Autenticação:** JWT Bearer Token emitido pelo `auth-service`. Cada token contém `sub` (user_id) e `tid` (tenant_id).
- **Autorização:** RBAC (Role-Based Access Control) gerido pelo `autorizacao-service`. Permissões verificadas por middleware em cada serviço.
- **Auditoria:** Todos os eventos de mutação são registados no `auditoria-service` com utilizador, acção, entidade afectada e timestamp.

---

## 4. Módulos do Sistema

### 4.1 Módulos Core (transversais)

| Módulo | Serviço | Porta | Responsabilidade |
|---|---|---|---|
| Autenticação | `auth-service` | 3001 | Login, JWT, refresh tokens, gestão de sessões |
| Autorização | `autorizacao-service` | 3002 | RBAC — roles, permissões, políticas de acesso |
| Utilizadores | (integrado no auth) | — | Perfis de utilizador, passwords, 2FA |
| Empresas | `empresa-service` | 3003 | Registo de tenants, dados fiscais (NUIT), logótipos |
| Configuração do sistema | `sistema-configuracao-service` | 3022 | Parâmetros globais, moedas base, preferências |
| Auditoria | `auditoria-service` | 3018 | Registo imutável de todas as acções do sistema |
| Segurança | `seguranca-service` | 3024 | Políticas de senha, bloqueio de contas, 2FA |

### 4.2 Módulos de Dados Mestre

| Módulo | Serviço | Porta | Responsabilidade |
|---|---|---|---|
| Gestão de Clientes | `clientes-service` | 3005 | Clientes B2B/B2C, NUIT, contactos, moradas |
| Gestão de Produtos | `produtos-service` | 3006 | Artigos, serviços, categorias, preços, taxas |
| Gestão de Stock | `stock-service` | 3008 | Armazéns, movimentos, inventário, alertas de ruptura |
| Compras | `compras-service` | 3010 | Fornecedores, ordens de compra, recepções |

### 4.3 Módulos Transacionais

| Módulo | Serviço | Porta | Responsabilidade |
|---|---|---|---|
| Facturação | `faturacao-service` | 3004 | Proformas, facturas, recibos, notas de crédito |
| POS | `pos-service` | 3019 | Ponto de venda, caixa, pagamentos M-Pesa/E-Mola |
| Logística | `logistica-service` | 3025 | Guias de remessa, entregas, rotas |
| Assinaturas | `assinaturas-service` | 3021 | Planos, subscriptions, facturação recorrente |

### 4.4 Módulos Financeiros

| Módulo | Serviço | Porta | Responsabilidade |
|---|---|---|---|
| Financeiro | `financeiro-service` | 3009 | Recebimentos, pagamentos, fluxo de caixa |
| Tesouraria | `tesouraria-service` | 3011 | Contas bancárias, conciliação, transferências |
| Contabilidade | `contabilidade-service` | 3012 | Plano de contas, lançamentos, balancetes |
| Impostos | `impostos-service` | 3007 | IVA 17%, retenções, apuramento fiscal |
| Multi-moeda | `multi-moeda-service` | 3014 | Taxas de câmbio, conversões, MZN/USD/ZAR/EUR |
| Centros de Custo | `centros-custo-service` | 3020 | Imputação de custos por departamento/projecto |

### 4.5 Módulos Operacionais

| Módulo | Serviço | Porta | Responsabilidade |
|---|---|---|---|
| Recursos Humanos | `recursos-humanos-service` | 3013 | Colaboradores, folha salarial, contratos, férias |
| CRM | `crm-service` | 3017 | Pipeline comercial, oportunidades, actividades |
| Gestão Escolar | `gestao-escolar-service` | 3026 | Matrículas, propinas, turmas, resultados |

### 4.6 Módulos de Infraestrutura

| Módulo | Serviço | Porta | Responsabilidade |
|---|---|---|---|
| Notificações | `notifications-service` | 3016 | E-mail, SMS, WhatsApp, push — canais e templates |

---

## 5. Dependências Funcionais entre Módulos

```
autenticacao ──► autorizacao
autenticacao ──► utilizadores
sistema-configuracao ──► multi-moeda

gestao-produtos ──► gestao-stock
gestao-produtos, gestao-stock ──► compras

gestao-clientes, gestao-produtos, gestao-stock ──► modulo-faturacao
gestao-produtos, gestao-stock ──► pos
modulo-faturacao, gestao-stock ──► logistica
gestao-clientes ──► assinaturas ──► modulo-faturacao
                                └──► financeiro

tesouraria ──► financeiro ──► contabilidade
pos ──► financeiro
pos ──► tesouraria
compras ──► financeiro
assinaturas ──► financeiro
recursos-humanos ──► financeiro
recursos-humanos ──► contabilidade

contabilidade ──► centros-custo
contabilidade ──► impostos

autenticacao, autorizacao, utilizadores ──► gestao-escolar
financeiro, tesouraria ──► gestao-escolar

todos os modulos ──► auditoria
```

**Regra de propriedade:** Cada módulo é dono exclusivo das suas tabelas. Referências cruzadas usam IDs — nunca duplicam dados de outros domínios.

---

## 6. Stack Tecnológica

### 6.1 Backend

| Componente | Tecnologia |
|---|---|
| Runtime principal | Node.js 22 (LTS) |
| Framework HTTP | Express.js 4.x |
| ORM / DB Driver | `pg` (PostgreSQL driver nativo — sem ORM) |
| Autenticação | JSON Web Tokens (`jsonwebtoken`) |
| Segurança HTTP | Helmet, CORS, express-rate-limit |
| Linguagem | JavaScript (ES2022+) |

> Nota: Serviços mais intensivos em cálculo (contabilidade, impostos) podem adoptar Python FastAPI ou Java Spring Boot em iterações futuras.

### 6.2 Base de Dados

| Componente | Tecnologia |
|---|---|
| SGBD | PostgreSQL 16 |
| Modelo | Uma instância lógica por serviço (schema isolation) |
| Migrations | SQL puro (`migrations/001_init.sql` por serviço) |
| Multi-tenancy | Coluna `tenant_id` em todas as tabelas |
| Tipos especiais | JSONB para dados flexíveis (limites, metadata) |
| Enumerações | Tipos ENUM nativos do PostgreSQL |

### 6.3 Mensageria

| Componente | Tecnologia |
|---|---|
| Message Broker | RabbitMQ 3.x |
| Padrão | Eventos de domínio (publish/subscribe) |
| Uso | Notificações assíncronas, auditoria, integrações |

### 6.4 Infraestrutura

| Componente | Tecnologia |
|---|---|
| Containerização | Docker + Docker Compose |
| API Gateway / Proxy | Traefik v3 |
| CDN / Protecção | Cloudflare |
| Cache | Redis 7 |
| Orquestração (produção) | Docker Swarm / Kubernetes (planeado) |

### 6.5 Frontend (planeado)

| Canal | Tecnologia |
|---|---|
| Web (backoffice) | React + TypeScript |
| Mobile | Flutter |
| POS (terminal) | React (PWA) ou Flutter |

---

## 7. Modelo de Segurança

### 7.1 Autenticação
- Todos os endpoints protegidos exigem Bearer JWT no header `Authorization`.
- Tokens têm duração limitada com suporte a refresh token.
- Middleware `requireAuth` aplicado globalmente em todos os routers de negócio.

### 7.2 Isolamento de dados
- `tenant_id` extraído do JWT e aplicado em todas as queries — nunca aceite do corpo do pedido.
- Impossibilidade de acesso cross-tenant por design.

### 7.3 Protecção de transporte
- HTTPS obrigatório em produção via Cloudflare + Traefik (Let's Encrypt).
- Headers de segurança via Helmet (HSTS, CSP, X-Frame-Options, etc.).

### 7.4 Rate limiting
- 200 req/min por IP por defeito (configurável por serviço).

### 7.5 Auditoria
- Registo imutável de criações, actualizações e eliminações.
- Campos: `user_id`, `tenant_id`, `entidade`, `acao`, `payload_antes`, `payload_depois`, `timestamp`.

---

## 8. Conformidade com a Legislação Moçambicana

| Requisito | Implementação |
|---|---|
| NUIT (Número Único de Identificação Tributária) | Campo obrigatório em `empresas` e `clientes` |
| IVA à taxa de 17% | Gerido pelo módulo `impostos` com suporte a isenções |
| Numeração sequencial de facturas | Gerada e controlada pelo `faturacao-service` |
| Moeda local (MZN) | Moeda base; suporte a múltiplas moedas via `multi-moeda` |
| Pagamentos móveis | M-Pesa e E-Mola integrados no módulo `pos` e `financeiro` |
| Plano de Contas (PCISM) | Estrutura de contas no `contabilidade-service` |
| Retenções na fonte e impostos laborais | Módulo `impostos` + `recursos-humanos` |

---

## 9. Módulo Assinaturas — Detalhe Técnico

O módulo de assinaturas (`assinaturas-service`) gere o ciclo de vida das subscrições dos clientes, sendo central no modelo de negócio SaaS do Nexora ERP.

### 9.1 Entidades principais

| Entidade | Tabela | Descrição |
|---|---|---|
| Planos | `subscription_plans` | Definição de planos: mensal, trimestral, anual; preço; limites JSONB |
| Subscrições | `subscriptions` | Instância activa de um plano por empresa cliente |
| Facturas de subscrição | `subscription_invoices` | Documento de cobrança por ciclo de facturação |
| Registos de uso | `subscription_usage` | Consumo de recursos por subscriptor (para billing por uso) |

### 9.2 Estados de uma subscrição

```
[pendente] ──activar()──► [activa] ──cancelar()──► [cancelada]
[suspensa] ──activar()──► [activa]
[activa]   ─────────────────────────────────────► [expirada]  (automático)
```

### 9.3 Endpoints REST

| Método | Path | Descrição |
|---|---|---|
| GET | `/api/assinaturas/plans` | Listar planos activos |
| POST | `/api/assinaturas/plans` | Criar plano |
| PATCH | `/api/assinaturas/plans/:id` | Actualizar plano |
| GET | `/api/assinaturas/subscriptions` | Listar subscrições |
| GET | `/api/assinaturas/subscriptions/:id` | Detalhe de subscrição |
| POST | `/api/assinaturas/subscriptions` | Criar subscrição |
| PATCH | `/api/assinaturas/subscriptions/:id` | Actualizar subscrição |
| POST | `/api/assinaturas/subscriptions/:id/activate` | Activar subscrição |
| POST | `/api/assinaturas/subscriptions/:id/cancel` | Cancelar subscrição |
| GET | `/api/assinaturas/invoices` | Listar facturas |
| POST | `/api/assinaturas/invoices` | Emitir factura |
| POST | `/api/assinaturas/invoices/:id/pay` | Registar pagamento |
| GET | `/api/assinaturas/usage` | Listar registos de uso |
| POST | `/api/assinaturas/usage` | Registar uso de recurso |
| GET | `/api/assinaturas/reports/summary` | Dashboard de subscrições |

---

## 10. Deployment e Operação

### 10.1 Configuração por serviço

Cada microserviço requer as seguintes variáveis de ambiente:

| Variável | Descrição |
|---|---|
| `DATABASE_URL` | Connection string PostgreSQL |
| `JWT_SECRET` | Segredo para validação de tokens JWT |
| `PORT` | Porta HTTP do serviço |
| `CORS_ORIGIN` | Origem permitida (domínio do frontend) |
| `RABBITMQ_URL` | URL do broker de mensagens (quando aplicável) |

### 10.2 Estrutura Docker Compose

```yaml
# docker-compose.yml (raiz)
include:
  - compose/traefik.yml          # API Gateway
  - compose/rabbitmq.yml         # Mensageria
  - compose/redis.yml            # Cache
  - compose/db_postgres.yml      # Base de dados

  # 24 microserviços de negócio
  - compose/auth-service.yml
  - compose/faturacao-service.yml
  - compose/assinaturas-service.yml
  # ... (todos os serviços)
```

### 10.3 Saúde dos serviços

Cada serviço expõe `GET /health` sem autenticação, retornando:

```json
{ "status": "ok", "service": "assinaturas-service" }
```

---

## 11. Roadmap e Estado actual

| Fase | Estado | Descrição |
|---|---|---|
| Fase 1 — Core | Em desenvolvimento | auth, empresa, autorizacao, auditoria, utilizadores |
| Fase 2 — Comercial | Em desenvolvimento | clientes, produtos, stock, faturacao, impostos |
| Fase 3 — Financeiro | Planeada | financeiro, tesouraria, contabilidade, multi-moeda |
| Fase 4 — Operacional | Planeada | RH, CRM, POS, logistica, assinaturas |
| Fase 5 — Frontend | Planeada | Web (React), Mobile (Flutter), POS (PWA) |
| Fase 6 — Integrações | Planeada | M-Pesa, E-Mola, AT (portal fiscal), bancos MZ |

---

## 12. Glossário

| Termo | Definição |
|---|---|
| Tenant | Empresa cliente do SaaS; unidade de isolamento de dados |
| NUIT | Número Único de Identificação Tributária (Moçambique) |
| IVA | Imposto sobre o Valor Acrescentado — taxa geral 17% em Moçambique |
| PCISM | Plano de Contas para o Sistema de Informação das Micro, Pequenas e Médias Empresas |
| JWT | JSON Web Token — mecanismo de autenticação stateless |
| RBAC | Role-Based Access Control — controlo de acessos baseado em funções |
| MZN | Metical Moçambicano — moeda base do sistema |
| M-Pesa / E-Mola | Plataformas de pagamento móvel predominantes em Moçambique |
| Proforma | Documento pré-fiscal que precede a factura definitiva |
| SaaS | Software as a Service — modelo de distribuição por subscrição |

---

*Documento gerado em 2026-03-27 — Nexora ERP v1.0 — E-258Tech*
