# Stakeholders e Restricoes Arquiteturais

| Campo | Detalhe |
|---|---|
| Sistema | FaceClock |
| Versao do documento | 1.0.0 (Final) |
| Status | Aprovado para referencia de arquitetura do MVP |
| Data | 2026-07-09 |
| Documento relacionado | `spec.md` |

## Objetivo

Documentar os stakeholders do FaceClock, suas preocupacoes e as restricoes arquiteturais que impactam a solucao. Esta e a versao final consolidada: fecha as pendencias da versao anterior (ADRs, custos/capacidade, C4, disaster recovery) e regista o estado real de implementacao observado no codigo, nao apenas o estado planejado.

## Stakeholders

### Colaborador

Papel:
- registra ponto
- consulta historico
- solicita ajustes

Principais preocupacoes:
- rapidez no registro
- baixa friccao no uso
- privacidade dos dados biometricos
- confiabilidade em ambientes com internet instavel

### Gestor RH

Papel:
- acompanha registros
- revisa ajustes
- exporta relatorios

Principais preocupacoes:
- visibilidade operacional
- confiabilidade dos registros
- facilidade de auditoria
- filtros e exportacao de dados

### Administrador do sistema

Papel:
- configura o ambiente
- gerencia acessos e integracoes
- acompanha seguranca e operacao

Principais preocupacoes:
- manutenibilidade
- seguranca
- controle de configuracao
- capacidade de evolucao do sistema

### Auditor / Compliance / DPO

Papel:
- valida conformidade
- revisa trilhas de auditoria
- acompanha riscos regulatórios

Principais preocupacoes:
- rastreabilidade
- integridade dos registros
- minimizacao de dados
- aderencia a LGPD e normas trabalhistas

### Area de TI / Operacoes

Papel:
- implanta e monitora a plataforma
- responde a incidentes

Principais preocupacoes:
- observabilidade
- recuperacao de falhas
- previsibilidade operacional
- custo de infraestrutura

### Sistemas externos de ERP / RH / Folha

Papel:
- receber eventos validados

Principais preocupacoes:
- consistencia do payload
- estabilidade dos contratos
- rastreabilidade de lotes e erros

## Matriz resumida

| Stakeholder | Principal interesse | Impacto arquitetural |
|---|---|---|
| Colaborador | experiencia e confiabilidade | UX simples, baixa latencia, suporte offline |
| Gestor RH | operacao e controle | filtros, historico, ajustes, exportacao |
| Admin Sistema | seguranca e evolucao | modularidade, config por ambiente, migrations |
| Auditor / DPO | conformidade e evidencias | logs, trilha imutavel, retencao, consentimento |
| TI / Operacoes | disponibilidade e monitoracao | health checks, logs, metricas, rollback |
| ERP / RH | integracao estavel | OpenAPI, versionamento de contratos, lotes |

## Registro de aprovacao (sign-off)

| Stakeholder | Responsavel | Aprovacao | Data |
|---|---|---|---|
| Colaborador (representacao) | a definir | pendente | — |
| Gestor RH | a definir | pendente | — |
| Administrador do sistema | Eleuterio Fulaho Notico | pendente | — |
| Auditor / Compliance / DPO | a definir | pendente | — |
| TI / Operacoes | a definir | pendente | — |

Este documento e considerado "final" enquanto artefacto de arquitetura (conteudo tecnico fechado). A aprovacao formal por stakeholder de negocio continua pendente de nomeacao de responsaveis e deve ser preenchida antes de qualquer ida a producao com dados reais de colaboradores.

## Restricoes de negocio

- o sistema deve suportar controle de jornada com rastreabilidade
- o uso de biometria deve estar vinculado a finalidade explicita e governanca de consentimento
- o sistema deve permitir auditoria de eventos criticos
- a versao MVP nao inclui calculo de folha de pagamento
- a versao MVP nao inclui gestao avancada de escalas
- o produto deve operar em cenarios com conectividade intermitente

## Restricoes tecnicas

- o backend foi implementado em FastAPI (Python 3.12) para acelerar o MVP — confirmado em codigo, nao apenas planejado
- a persistencia principal e relacional: PostgreSQL 15 em producao/staging, SQLite aceito para desenvolvimento local
- a evolucao do schema e controlada por Alembic (2 revisoes aplicadas ate esta versao)
- o contrato de API e documentado em OpenAPI (`openapi.yaml` + `/docs` gerado pelo FastAPI)
- o sistema usa autenticacao por access/refresh token JWT (HS256) para endpoints protegidos, com fallback de PIN para colaboradores
- a camada biometrica e isolada em `app/services/biometric.py`, com pipeline substituivel em 3 etapas (deteccao OpenCV, alinhamento dlib, embedding FaceNet/facenet-pytorch), permitindo evolucao sem reescrever o dominio central
- a stack biometrica introduz dependencias nativas pesadas (opencv-python, dlib via face-recognition, torch CPU + facenet-pytorch), o que aumenta tempo de build e tamanho de imagem Docker — restricao aceita conscientemente para o MVP

## Restricoes de seguranca e compliance

- dados biometricos devem ser tratados como sensiveis
- segredo de aplicacao nao pode ficar hardcoded fora de ambiente de desenvolvimento
- eventos criticos devem gerar trilha de auditoria (implementado via encadeamento de hash em `audit_chain.py`)
- acesso administrativo deve ser controlado por papel (`require_roles` em `app/deps.py`)
- o sistema deve minimizar persistencia de imagem bruta
- retencao e exclusao de dados devem ser governadas por politica formal

## Restricoes operacionais

- ambiente deve expor health checks (`/health`, `/ready`)
- monitoramento deve existir desde o MVP (`/metrics` implementado)
- schema nao deve ser criado automaticamente em producao — migrations via Alembic
- deploy deve suportar rollback
- seed de dados demo nao deve ocorrer implicitamente em producao (`SEED_DATA_ON_STARTUP=false` por omissao)

## Restricoes de escalabilidade

- o MVP inicia como monolito modular, um unico container `controle-api`
- o desenho deve permitir separar servicos no futuro (biometria como candidato natural a extracao)
- o armazenamento de templates e logs deve suportar crescimento progressivo
- verificacao biometrica deve poder evoluir para servico especializado no futuro

## Decisoes de arquitetura (ADRs de referencia)

Registro leve das decisoes ja tomadas e implementadas, para consulta rapida. Cada uma pode ser expandida para um ADR completo em `docs/adr/` caso o processo formal de ADR seja adotado.

| ID | Decisao | Justificativa | Estado |
|---|---|---|---|
| ADR-001 | Backend em FastAPI + SQLAlchemy | velocidade de desenvolvimento, tipagem via Pydantic, ecossistema Python alinhado ao pipeline biometrico | Implementado |
| ADR-002 | PostgreSQL como banco relacional principal | integridade transacional, suporte a indices e futura extensao vetorial | Implementado (SQLite usado apenas em dev local) |
| ADR-003 | Autenticacao JWT access+refresh, com PIN como fallback | equilibrio entre seguranca e continuidade operacional (RF-13) | Implementado; fallback de PIN com bug conhecido (ver riscos) |
| ADR-004 | Pipeline biometrico modular em 3 etapas (OpenCV, dlib, FaceNet) isolado em servico proprio | permite trocar modelo/etapa sem alterar dominio de negocio | Implementado, com fallback simulado se `facenet-pytorch` indisponivel |
| ADR-005 | Migrations geridas por Alembic, sem criacao automatica de schema em producao | rastreabilidade e reversibilidade de mudancas de schema | Implementado |
| ADR-006 | Deploy como container unico numa rede Docker partilhada (`e258techmozambique`) | simplicidade operacional para o estagio de MVP/piloto | Implementado |
| ADR-007 | Trilha de auditoria com encadeamento de hash | integridade verificavel de eventos criticos sem depender so de controle de acesso | Implementado |

## Capacidade e custos (estimativa MVP/piloto)

Nao existe ainda medicao de producao; os numeros abaixo sao estimativas de dimensionamento para a fase de piloto, a validar com carga real.

| Dimensao | Estimativa MVP/piloto | Observacao |
|---|---|---|
| Topologia de infraestrutura | 1 VPS com Docker Compose, rede partilhada `e258techmozambique` | mesmo padrao usado pelos outros servicos e258tech; sem orquestracao (K8s) nesta fase |
| Banco de dados | 1 instancia PostgreSQL 15 em container, sem replica | risco de ponto unico de falha — aceitavel apenas para piloto, nao para producao critica |
| Capacidade alvo (spec) | ate 500 verificacoes/minuto por no de servico | meta definida em `spec.md` (RNF), ainda nao validada por teste de carga |
| Escalonamento | vertical (mais CPU/RAM no mesmo container) ate limite do VPS; escalonamento horizontal exige extrair o servico biometrico | decisao de escalar horizontalmente deve vir com ADR proprio |
| Custo de infraestrutura | nao orcamentado neste documento | depende do provedor de VPS/cloud escolhido; recomenda-se orcamento formal antes do piloto com dados reais |
| Backup | volume Docker do Postgres (`db_data`), sem politica de backup automatizado documentada | pendencia critica para producao — ver Disaster Recovery |

## Disaster Recovery (plano base)

Alinhado a meta de SLA de 99.9% definida em `spec.md`. Este e um plano base a validar operacionalmente antes de producao com dados reais.

- **RPO alvo:** ate 24h (depende de backup diario do volume `db_data` — ainda nao automatizado, ver pendencias)
- **RTO alvo:** ate 4h para restabelecer o servico `controle-api` a partir de imagem Docker existente e ultimo backup de banco
- **Estrategia de rollback:** reverter para a imagem Docker anterior (tag) + `alembic downgrade` se a migration mais recente for a causa do incidente
- **Cenarios cobertos:**
  - falha do container da API: `restart: unless-stopped` reinicia automaticamente; healthcheck (`/health`) detecta indisponibilidade
  - corrupcao/perda do banco: restaurar do ultimo backup do volume `db_data` (backup automatizado ainda pendente de implementacao)
  - falha da dependencia biometrica (torch/facenet-pytorch): sistema atualmente degrada silenciosamente para embeddings simulados — **isto viola o principio de "falhar de forma visivel"** e deve ser corrigido antes de producao (ver riscos)
- **Nao coberto ainda:** replicacao geografica, failover automatico de banco, runbook formal de incidentes

## Riscos e dividas tecnicas conhecidas

Identificados por revisao de codigo em 2026-07-09, registados aqui para nao se perderem entre a arquitetura planejada e o estado real da implementacao.

| Risco | Impacto | Severidade | Acao recomendada |
|---|---|---|---|
| `verify_pin()` em `app/security.py` referencia `pwd_context`, nunca definido/importado no ficheiro | login por PIN (`POST /auth/login/pin`) falha com erro interno sempre que usado | Alto | corrigir para usar `bcrypt.checkpw`, consistente com o resto do ficheiro |
| `JWT_SECRET_KEY` com valor por omissao (`change-me-in-production`) presente no `.env` local e no `docker-compose.yml` | se replicado em staging/producao, tokens sao forjaveis | Critico (se aplicavel a producao) | garantir segredo forte e unico por ambiente, fora de qualquer valor por omissao versionado |
| `build_embedding()` degrada para embedding aleatorio quando `facenet-pytorch` nao carrega, sem erro visivel | verificacao facial pode aceitar/rejeitar incorretamente sem alarme operacional | Alto | falhar explicitamente (ou alertar) em vez de simular embedding em ambiente que nao seja de teste |
| Ausencia de politica de backup automatizado para o volume `db_data` | perda de dados em caso de falha de disco/host | Alto | automatizar backup periodico + teste de restauracao (criterio ja previsto em `spec.md` secao 17.2) |
| Banco de dados sem replica, unico ponto de falha | indisponibilidade total em caso de falha do container/host do Postgres | Medio (aceitavel para piloto) | reavaliar antes de producao com dados reais de colaboradores |

## Implicacoes arquiteturais

- necessidade de modularidade por dominio
- necessidade de contratos bem definidos entre captura, backend e integracoes
- necessidade de trilhas de auditoria e politicas de seguranca desde a fase inicial
- necessidade de separar decisao de MVP rapido de decisao de escala futura

## Pendencias remanescentes

Itens que dependem de decisao de negocio ou trabalho de engenharia fora do escopo deste documento:

- nomear responsaveis e obter assinatura formal na tabela de sign-off
- corrigir os riscos tecnicos listados acima antes de qualquer producao com dados reais
- orcar formalmente custo de infraestrutura de producao (provedor, dimensionamento, SLA contratado)
- automatizar e testar o processo de backup/restauracao do banco de dados
- avaliar contratacao/definicao de politica de retencao formal junto a juridico/DPO (RF-14, LGPD)

