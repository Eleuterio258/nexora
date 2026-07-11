# Especificacao Tecnica: Registro de Ponto com Reconhecimento Facial

| Campo | Detalhe |
|---|---|
| Nome do sistema | FaceClock |
| Versao | 1.0.0 |
| Data | 2026-04-13 |
| Status | Especificacao funcional e tecnica base |
| Idioma | Portugues |

## 1. Objetivo

Desenvolver um sistema de registro de ponto eletronico com reconhecimento facial, capaz de operar em web, mobile e totem, com foco em:

- seguranca contra fraude
- rastreabilidade e auditoria
- conformidade com LGPD e regras trabalhistas aplicaveis
- boa experiencia de uso para colaborador, RH e administracao

## 2. Escopo

### 2.1 Incluido na versao 1

- cadastro biometrico com consentimento explicito
- reconhecimento facial para registro de entrada, pausa, retorno e saida
- deteccao de vivacidade para reduzir spoofing por foto, video ou mascara
- armazenamento de templates biometricos e nao de imagens como dado principal
- dashboard administrativo com filtros, auditoria e exportacao
- operacao offline com sincronizacao posterior
- integracao por API com sistemas de RH, ERP ou folha
- trilha de auditoria de registros, consentimentos e alteracoes
- fluxo de solicitacao de correcao de ponto

### 2.2 Fora do escopo da versao 1

- calculo de folha de pagamento
- gestao avancada de escalas e turnos complexos
- fabricacao de hardware dedicado
- reconhecimento simultaneo de varias pessoas no mesmo frame
- analise comportamental alem da identificacao biometrica

## 3. Perfis de usuario

| Perfil | Descricao | Permissoes principais |
|---|---|---|
| COLABORADOR | Usuario final que registra o ponto | cadastrar biometria, registrar ponto, consultar historico proprio, solicitar ajuste |
| GESTOR_RH | Responsavel por time, unidade ou departamento | visualizar registros da unidade, aprovar excecoes, emitir relatorios |
| ADMIN_SISTEMA | Administracao tecnica e compliance | configurar ambiente, politicas, integracoes, auditoria e retencao |
| AUDITOR | Auditor interno ou externo | acesso somente leitura a trilhas, evidencias e relatorios |

## 4. Casos de uso principais

### UC-01 Cadastro biometrico

1. O colaborador acessa o fluxo de cadastro.
2. O sistema apresenta termo de consentimento e finalidade de uso.
3. O usuario aceita o termo.
4. O sistema solicita capturas em angulos e condicoes minimas de iluminacao.
5. O sistema valida qualidade, liveness inicial e gera o template biometrico.
6. O template e armazenado com referencia ao consentimento.

### UC-02 Registro de ponto online

1. O colaborador posiciona o rosto diante da camera.
2. O sistema detecta rosto e executa liveness.
3. O sistema extrai embedding e compara com template armazenado.
4. Se houver match acima do limiar configurado, registra o evento de ponto.
5. O sistema grava timestamp, dispositivo, confianca e evidencias de auditoria.

### UC-03 Registro de ponto offline

1. O dispositivo detecta indisponibilidade de rede.
2. O evento validado e armazenado em fila local criptografada.
3. Ao reestabelecer conectividade, o sistema sincroniza os eventos.
4. A sincronizacao deve ser idempotente para evitar duplicidade.

### UC-04 Ajuste de ponto

1. O colaborador consulta seu historico.
2. Seleciona um registro e solicita correcao.
3. O gestor ou RH analisa a solicitacao.
4. O sistema registra decisao, responsavel e justificativa.

### UC-05 Exclusao ou revogacao

1. O colaborador ou administracao solicita exclusao quando aplicavel.
2. O sistema verifica base legal e politicas de retencao.
3. Havendo permissao juridica, remove template e atualiza trilha de auditoria.

## 5. Requisitos funcionais

| ID | Requisito | Prioridade |
|---|---|---|
| RF-01 | Permitir cadastro biometrico com multiplos frames e verificacao de qualidade | Alta |
| RF-02 | Registrar consentimento com versao do termo, hash e timestamp | Alta |
| RF-03 | Realizar verificacao facial em ate 2 segundos por operacao | Alta |
| RF-04 | Executar liveness antes de aceitar o registro | Alta |
| RF-05 | Registrar tipos de evento: entrada, pausa, retorno, saida | Alta |
| RF-06 | Associar cada evento a usuario, dispositivo, unidade e horario oficial | Alta |
| RF-07 | Funcionar offline com fila local criptografada e sincronizacao automatica | Alta |
| RF-08 | Disponibilizar historico individual de registros ao colaborador | Media |
| RF-09 | Disponibilizar dashboard com filtros, exportacao e indicadores para RH | Alta |
| RF-10 | Permitir solicitacao e aprovacao de ajustes de ponto | Media |
| RF-11 | Expor API para integracao com ERP, RH e folha | Alta |
| RF-12 | Manter logs de auditoria imutaveis para eventos criticos | Alta |
| RF-13 | Permitir desativacao de biometria e alternativa operacional quando necessario | Alta |
| RF-14 | Permitir gestao de retencao e exclusao de dados sensiveis | Alta |

## 6. Requisitos nao funcionais

| Categoria | Requisito |
|---|---|
| Desempenho | latencia fim a fim menor ou igual a 2s em p95 |
| Escalabilidade | suportar ao menos 500 verificacoes por minuto por no de servico |
| Disponibilidade | meta de SLA de 99.9 por cento |
| Seguranca | TLS em transito, criptografia forte em repouso e segregacao de acesso |
| Privacidade | armazenar preferencialmente templates biometricos, evitando guardar imagem bruta como dado persistente principal |
| Auditoria | trilhas de eventos criticos com encadeamento de hash ou mecanismo equivalente |
| Resiliencia | fila offline com retencao minima de 7 dias no dispositivo ou gateway local |
| Acessibilidade | alternativa por PIN, QR Code ou validacao manual para excecoes justificadas |
| Observabilidade | metricas, logs estruturados e tracing dos fluxos criticos |

## 7. Regras de negocio

- cada registro de ponto deve possuir origem rastreavel
- o horario utilizado para persistencia deve ser padronizado e auditavel
- um registro nao pode ser perdido em falha de rede
- o sistema nao deve aceitar registro sem validacao biometrica ou fallback autorizado
- cada ajuste de ponto deve manter historico de solicitacao, decisao e justificativa
- a revogacao de consentimento deve acionar fluxo administrativo e juridico, nao apenas exclusao cega
- o sistema deve impedir duplicacao de evento durante sincronizacao offline

## 8. Arquitetura proposta

### 8.1 Componentes

- frontend web para administracao, consulta e operacao assistida
- aplicativo mobile ou cliente de captura para validacao local
- totem ou kiosk para pontos em unidade fisica
- API Gateway para autenticacao, rate limit e roteamento
- servico de autenticacao e identidade para perfis administrativos
- servico de ponto para regras de negocio e persistencia de eventos
- servico biometrico para enrollment, matching e liveness
- servico de relatorios para agregacao e exportacao
- banco relacional para dados transacionais e auditoria
- armazenamento temporario para artefatos controlados
- cache e fila para desempenho e sincronizacao

### 8.2 Visao logica

```text
Cliente Web/Mobile/Totem
        |
        v
   API Gateway
        |
        +--> Servico de Autenticacao
        +--> Servico de Ponto
        |         |
        |         +--> Banco Transacional
        |         +--> Fila/Eventos
        |
        +--> Servico Biometrico
        |         |
        |         +--> Vetores/Templates
        |         +--> Motor de Liveness
        |
        +--> Servico de Relatorios
                  |
                  +--> Exportacao / Dashboard / Auditoria
```

### 8.3 Tecnologias sugeridas

- backend: FastAPI ou NestJS
- banco: PostgreSQL com suporte a extensao vetorial quando aplicavel
- cache/fila: Redis
- armazenamento de objetos: S3 ou MinIO
- observabilidade: Prometheus, Grafana e logs estruturados
- infraestrutura: Docker e Kubernetes

## 9. Fluxo tecnico de verificacao

1. Capturar frame da camera.
2. Detectar rosto.
3. Validar qualidade minima da captura.
4. Executar liveness.
5. Alinhar face e extrair embedding.
6. Buscar template do usuario ou candidatos conforme estrategia de identificacao.
7. Comparar vetores por similaridade.
8. Validar threshold configurado.
9. Registrar evento de ponto com metadados.
10. Publicar evento para auditoria, integracao e relatorios.

## 10. Modelo de dados conceitual

### 10.1 Entidades principais

- `users`
- `devices`
- `face_templates`
- `clock_records`
- `consents`
- `adjustment_requests`
- `audit_logs`
- `sync_queue`

### 10.2 Campos minimos recomendados

#### users

- id
- employee_code
- full_name
- unit_id
- status
- created_at
- updated_at

#### face_templates

- user_id
- embedding
- model_version
- quality_score
- consent_id
- status
- created_at

#### clock_records

- id
- user_id
- event_type
- recorded_at
- source_type
- device_id
- confidence_score
- liveness_score
- geo_lat
- geo_lng
- sync_status
- created_at

#### consents

- id
- user_id
- term_version
- consent_hash
- accepted_at
- revoked_at
- legal_basis

#### audit_logs

- id
- actor_type
- actor_id
- action
- entity_type
- entity_id
- payload_hash
- previous_hash
- created_at

## 11. API minima recomendada

| Metodo | Rota | Finalidade |
|---|---|---|
| POST | /api/v1/auth/login | autenticacao administrativa |
| POST | /api/v1/biometric/enroll | cadastro biometrico |
| POST | /api/v1/biometric/verify | verificacao facial |
| POST | /api/v1/clock/register | persistencia de ponto |
| GET | /api/v1/clock/me | historico do colaborador |
| POST | /api/v1/clock/adjustments | solicitar ajuste |
| GET | /api/v1/admin/clock-records | consulta administrativa |
| GET | /api/v1/admin/reports/export | exportacao de relatorios |
| POST | /api/v1/integrations/payroll/push | envio para sistemas externos |
| GET | /api/v1/audit/logs | consulta de auditoria |

### 11.1 Exemplo de resposta de verificacao

```json
{
  "match": true,
  "user_id": "3c1b8f77-0e96-4d0f-9e1e-4d6760f1b234",
  "confidence_score": 0.91,
  "liveness_score": 0.97,
  "device_id": "totem-mz-01",
  "timestamp": "2026-04-13T08:00:14Z"
}
```

## 12. Biometria e processamento de visao

### 12.1 Pipeline sugerido

- deteccao facial com modelo leve e robusto
- alinhamento facial antes da extracao do embedding
- embedding padronizado por modelo versionado
- comparacao por similaridade de cosseno
- threshold calibrado empiricamente em ambiente de validacao

### 12.2 Requisitos tecnicos do motor biometrico

- suportar multiplas condicoes de iluminacao
- rejeitar capturas sem qualidade minima
- possuir versao de modelo auditavel
- permitir recalibracao de threshold sem migracao estrutural do sistema
- registrar metricas de FAR, FRR e taxa de falha operacional

### 12.3 Liveness

O modulo de vivacidade deve combinar:

- classificacao anti-spoofing por textura ou modelo dedicado
- sinais dinamicos, como micro movimentos ou piscar, quando suportado
- politica de reintento com limite configuravel
- fallback operacional apos falha recorrente, com trilha de auditoria

## 13. Seguranca e privacidade

### 13.1 Controles minimos

- criptografia em transito e em repouso
- segregacao de papeis e privilegios
- armazenamento de segredos em cofre apropriado
- rotacao de credenciais e chaves
- mascara ou minimizacao de dados sensiveis em logs
- rate limiting para APIs expostas
- trilha de auditoria para acoes administrativas e operacoes sensiveis

### 13.2 Diretrizes LGPD

- explicitar base legal e finalidade
- limitar a coleta ao minimo necessario
- prover acesso, correcao e eventual exclusao quando juridicamente cabivel
- manter politica de retencao documentada
- envolver DPO e avaliacao de impacto antes da operacao produtiva

### 13.3 Retencao sugerida

- templates biometricos: durante o vinculo ativo e conforme politica aprovada
- registros de ponto e auditoria: conforme exigencias legais e trabalhistas aplicaveis
- imagens temporarias: descarte rapido, preferencialmente imediato ou em prazo tecnico curto e controlado

## 14. Conformidade e auditoria

O sistema deve ser projetado para suportar:

- controle de jornada com integridade e rastreabilidade
- evidencias de consentimento e de uso de biometria
- trilha imutavel para registros criticos
- exportacao de evidencias para auditoria interna ou externa
- politicas de retencao e descarte formalmente aprovadas

## 15. Integracoes

| Sistema | Tipo | Objetivo |
|---|---|---|
| ERP/RH | REST API ou webhook | envio de registros consolidados |
| SSO corporativo | OIDC ou SAML | autenticacao de administradores |
| Monitoramento | metricas e logs | observabilidade operacional |
| Notificacao | email, SMS ou push | alertas de falha, excecao e aprovacao |

## 16. Estrategia de testes

### 16.1 Testes funcionais

- cadastro biometrico com sucesso
- rejeicao de captura sem qualidade
- rejeicao de tentativa sem liveness
- registro de ponto online
- registro de ponto offline e sincronizacao posterior
- solicitacao e aprovacao de ajuste

### 16.2 Testes tecnicos

- unitarios para regras de negocio
- integracao entre API, banco e servico biometrico
- carga e concorrencia
- resiliencia com perda de rede
- seguranca, incluindo autenticacao, autorizacao e revisao de superficie de ataque
- validacao de vies e desempenho por subgrupos relevantes

### 16.3 Criterios de aceite sugeridos

- cobertura de testes dos modulos criticos maior ou igual a 85 por cento
- latencia p95 menor ou igual a 1.8s em ambiente de referencia
- erro operacional menor que 0.1 por cento sob carga prevista
- sincronizacao offline sem duplicidade

## 17. Implantacao e operacao

### 17.1 Ambientes

- desenvolvimento
- homologacao
- staging
- producao

### 17.2 Requisitos operacionais

- health checks de aplicacao e dependencias
- dashboards de operacao e biometria
- backup periodico e teste de restauracao
- deploy com estrategia de baixo risco, como blue-green ou canary
- plano de rollback documentado

### 17.3 Metricas recomendadas

- tempo medio de verificacao
- taxa de match
- taxa de falha de liveness
- tamanho da fila offline
- tempo medio de sincronizacao
- erros por endpoint
- disponibilidade por servico

## 18. Riscos principais

| Risco | Impacto | Mitigacao |
|---|---|---|
| falso negativo em ambiente real | medio/alto | calibracao de threshold, melhor captura e fallback |
| spoofing sofisticado | alto | liveness multicamada e revisoes periodicas |
| rejeicao de usuarios | medio | transparencia, treinamento e alternativa operacional |
| vazamento de dados sensiveis | critico | criptografia, minimo privilegio e auditoria |
| mudanca regulatoria | alto | revisao juridica periodica e governanca com DPO |

## 19. Planejamento por sprint

### Sprint 1 - Fundacao tecnica

Objetivo:
Estabelecer a base do produto para desenvolvimento seguro e rastreavel.

Escopo:

- configuracao do backend
- estrutura inicial de banco
- autenticacao administrativa
- registro de consentimento

Entregas esperadas:

- API sobe com health check
- schema inicial definido
- login administrativo funcional
- consentimento armazenado e vinculado ao usuario

### Sprint 2 - Biometria MVP

Objetivo:
Entregar o fluxo basico de cadastro e verificacao facial.

Escopo:

- enrollment biometrico
- validacao de qualidade de captura
- liveness
- verificacao facial por threshold

Entregas esperadas:

- usuario pode cadastrar biometria
- sistema rejeita captura invalida
- verify retorna match, confianca e score de liveness

### Sprint 3 - Registro operacional

Objetivo:
Colocar o controle de ponto para funcionar em cenarios online e offline.

Escopo:

- registro de entrada, pausa, retorno e saida
- idempotencia
- fila offline
- sincronizacao posterior

Entregas esperadas:

- eventos de ponto persistidos
- duplicidade evitada em reenvio
- fluxo offline com reprocessamento

### Sprint 4 - Fluxo do colaborador e RH

Objetivo:
Entregar autoatendimento do colaborador e operacao basica do RH.

Escopo:

- historico proprio
- solicitacao de ajuste
- aprovacao ou rejeicao de ajuste
- consulta administrativa com filtros

Entregas esperadas:

- colaborador consulta seus pontos
- ajuste entra em fluxo de analise
- RH consegue filtrar registros e revisar solicitacoes

### Sprint 5 - Fechamento do MVP

Objetivo:
Fechar governanca, observabilidade e integracao minima do produto.

Escopo:

- exportacao de relatorios
- auditoria de eventos criticos
- integracao com sistema externo
- metricas e monitoramento

Entregas esperadas:

- exportacao CSV funcional
- logs de auditoria consultaveis
- integracao inicial operacional
- metricas basicas disponiveis

### Pos-MVP

- piloto controlado
- medicao de FAR e FRR com base real
- testes de carga e seguranca avancados
- deploy piloto e treinamento operacional

## 20. Criterios de prontidao para producao

- parecer juridico e de privacidade aprovados
- termo de consentimento implementado e versionado
- liveness validado em ambiente representativo
- monitoramento e alertas ativos
- fila offline validada
- relatorios e trilha de auditoria exportaveis
- plano de rollback testado

## 21. Historico de versoes

| Versao | Data | Alteracao |
|---|---|---|
| 1.0.0 | 2026-04-13 | criacao inicial consolidada de especificacao |
