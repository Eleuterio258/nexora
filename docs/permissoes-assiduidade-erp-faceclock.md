# Permissões de Assiduidade: ERP vs FaceClock

## Visão geral

O sistema de assiduidade do Nexora é dividido em dois backends:

| Backend | Tecnologia | Função | Autenticação | Autorização |
|---------|-----------|--------|--------------|-------------|
| **Nexora ERP** | Go (Chi) | Gestão de funcionários, configuração de assiduidade, eventos de ponto | JWT OAuth2 (RS256) | RBAC por cargo + permissões diretas |
| **FaceClock** | Python (FastAPI) | Gateway biométrico (face, dedo, QR) | `X-API-Key` | Nenhuma — só valida a API key |

> O FaceClock **nunca** verifica permissões do utilizador. Ele confia que o ERP só o chama quando o utilizador já tem permissão.

---

## Diagrama de fluxo

```
┌─────────────────────────────────────────────────────────────────┐
│                     UTILIZADOR (app/web)                        │
│            Gestor RH / Funcionário autenticado                  │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                    NEXORA ERP (Go)                              │
│                                                                 │
│  1. /api/auth/login  ─────►  JWT OAuth2 + RBAC                  │
│                                    │                            │
│                                    ▼                            │
│              Verifica permissões do cargo/utilizador            │
│     ┌─────────────────────────────────────────────────┐         │
│     │ recursos-humanos:gerir_funcionarios             │         │
│     │ recursos-humanos:ver_funcionarios               │         │
│     │ assiduidade:gerir_configuracao                  │         │
│     │ assiduidade:ver_configuracao                    │         │
│     │ assiduidade:ver_assiduidade                     │         │
│     │ assiduidade:justificar                          │         │
│     │ assiduidade:corrigir_ponto                      │         │
│     │ assiduidade:aprovar_correcao                    │         │
│     └─────────────────────────────────────────────────┘         │
│                      │                                          │
│          ┌───────────┴────────────┐                             │
│          ▼                        ▼                             │
│  /api/rh/funcionarios/{id}   /api/rh/assiduidade/*              │
│  /biometria/facial/enroll    (gestão RH)                        │
│          │                        │                             │
│          │   ┌──────────────────┐ │                             │
│          └──►│  X-API-Key       │◄┘                             │
│              │  (ERP ► FaceClock)│                               │
│              └────────┬─────────┘                               │
└───────────────────────┼─────────────────────────────────────────┘
                        ▼
┌─────────────────────────────────────────────────────────────────┐
│                 FACECLOCK (Python/FastAPI)                      │
│                                                                 │
│     NÃO TEM PERMISSÕES DE UTILIZADOR                            │
│     Só valida: X-API-Key                                        │
│                                                                 │
│     ► /api/v1/biometric/enroll  (guarda template facial)        │
│     ► /api/v1/biometric/verify  (verifica identidade)           │
│     ► /api/v1/biometric/identify (identifica funcionário)       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Permissões do ERP necessárias para assiduidade

### Self-service (funcionário vê a própria assiduidade)

| Permissão | Endpoint | Ação |
|-----------|----------|------|
| `assiduidade:ver_assiduidade` | `GET /api/self-service/assiduidade` | Ver minha assiduidade |
| `assiduidade:ver_assiduidade` | `GET /api/self-service/assiduidade/resumo` | Ver resumo |
| `assiduidade:ver_assiduidade` | `GET /api/self-service/assiduidade/justificacoes` | Ver justificações |
| `assiduidade:justificar` | `POST /api/self-service/assiduidade/justificacoes` | Criar justificação |
| `assiduidade:corrigir_ponto` | `POST /api/self-service/assiduidade/correcoes` | Pedir correção de ponto |

### Configuração da assiduidade (RH / admin)

| Permissão | Endpoint | Ação |
|-----------|----------|------|
| `assiduidade:ver_configuracao` | `GET /api/rh/tipos-evento` | Listar tipos de evento |
| `assiduidade:gerir_configuracao` | `POST /api/rh/tipos-evento` | Criar tipo de evento |
| `assiduidade:gerir_configuracao` | `PUT /api/rh/tipos-evento/{id}` | Editar tipo de evento |
| `assiduidade:gerir_configuracao` | `DELETE /api/rh/tipos-evento/{id}` | Remover tipo de evento |
| `assiduidade:ver_configuracao` | `GET /api/rh/regras` | Listar regras |
| `assiduidade:gerir_configuracao` | `POST /api/rh/regras` | Criar regra |
| `assiduidade:gerir_configuracao` | `PUT /api/rh/regras/{id}` | Editar regra |
| `assiduidade:gerir_configuracao` | `DELETE /api/rh/regras/{id}` | Remover regra |
| `recursos-humanos:ver_funcionarios` | `GET /api/rh/metodos-marcacao` | Listar métodos de marcação |
| `assiduidade:gerir_configuracao` | `POST /api/rh/metodos-marcacao` | Criar método de marcação |
| `assiduidade:gerir_configuracao` | `PUT /api/rh/metodos-marcacao/{id}` | Editar método de marcação |
| `assiduidade:gerir_configuracao` | `DELETE /api/rh/metodos-marcacao/{id}` | Remover método de marcação |

### Gestão de funcionários e biometria

| Permissão | Endpoint | Ação |
|-----------|----------|------|
| `recursos-humanos:ver_funcionarios` | `GET /api/rh/funcionarios` | Listar funcionários |
| `recursos-humanos:ver_funcionarios` | `GET /api/rh/funcionarios/{id}` | Ver detalhe do funcionário |
| `recursos-humanos:gerir_funcionarios` | `POST /api/rh/funcionarios` | Criar funcionário |
| `recursos-humanos:gerir_funcionarios` | `PUT /api/rh/funcionarios/{id}` | Actualizar funcionário |
| `recursos-humanos:gerir_funcionarios` | `POST /api/rh/funcionarios/{id}/desligar` | Desligar funcionário |
| `recursos-humanos:gerir_funcionarios` | `POST /api/rh/funcionarios/{id}/biometria/facial/enroll` | **Cadastrar rosto** |

### Correções e aprovações

| Permissão | Endpoint | Ação |
|-----------|----------|------|
| `assiduidade:aprovar_correcao` | `GET /api/rh/correcoes-ponto` | Listar pedidos pendentes |
| `assiduidade:aprovar_correcao` | `POST /api/rh/correcoes-ponto/{id}/aprovar` | Aprovar correção |
| `assiduidade:aprovar_correcao` | `POST /api/rh/correcoes-ponto/{id}/rejeitar` | Rejeitar correção |
| `recursos-humanos:gerir_funcionarios` | `POST /api/rh/correcoes` | Criar correção de evento |
| `assiduidade:aprovar_correcao` | `GET /api/rh/correcoes` | Listar correções pendentes |
| `assiduidade:aprovar_correcao` | `POST /api/rh/correcoes/{id}/aprovar` | Aprovar correção de evento |
| `assiduidade:aprovar_correcao` | `POST /api/rh/correcoes/{id}/rejeitar` | Rejeitar correção de evento |

---

## Permissões que NÃO existem no FaceClock

O FaceClock não tem as seguintes permissões (e não precisa):

- `recursos-humanos:gerir_funcionarios`
- `recursos-humanos:ver_funcionarios`
- `assiduidade:gerir_configuracao`
- `assiduidade:ver_configuracao`
- `assiduidade:ver_assiduidade`
- `assiduidade:justificar`
- `assiduidade:corrigir_ponto`
- `assiduidade:aprovar_correcao`

No FaceClock, o único requisito de segurança é a `X-API-Key` configurada no ERP.

---

## Como funciona o cadastro de rosto

1. O **gestor** faz login no ERP (`POST /api/auth/login`).
2. O ERP devolve um **JWT** com as permissões do gestor.
3. O gestor chama `POST /api/rh/funcionarios/{id}/biometria/facial/enroll` com 3 imagens base64.
4. O ERP valida:
   - Token JWT válido.
   - Permissão `recursos-humanos:gerir_funcionarios`.
   - Funcionário existe e pertence ao mesmo tenant.
   - Consentimento LGPD do funcionário.
   - Método facial activo na configuração de assiduidade.
5. O ERP chama o FaceClock `POST /api/v1/biometric/enroll` com a `X-API-Key`.
6. O FaceClock processa as imagens e guarda o template facial.
7. O FaceClock devolve o `template_id` / `face_id`.
8. O ERP guarda a referência biométrica na base de dados.

---

## Referências

- Diagrama Mermaid: [`diagrama_permissoes_assiduidade.mmd`](../diagrama_permissoes_assiduidade.mmd)
- Collection Postman: [`nexora_rh_funcionarios.postman_collection.json`](../nexora_rh_funcionarios.postman_collection.json)
