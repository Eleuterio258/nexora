# Análise técnica da comunicação entre Nexora ERP e FaceClock

## Contexto da conversa

Diretórios analisados:

- `D:\projecto\e-258tech\2026\factPro\backend`
- `D:\projecto\e-258tech\2026\factPro\assiduidade_system_backend`

Requisito principal:

- Analisar a arquitetura de comunicação entre os dois componentes.
- O segundo backend, FaceClock, não deve possuir login próprio.

## Esclarecimento inicial

Foi selecionada a arquitetura de comunicação entre componentes na qual o segundo sistema não possui login independente.

Isso significa:

- O utilizador autentica-se no Nexora ERP.
- O FaceClock não recebe nem valida passwords.
- O FaceClock não cria uma segunda sessão.
- O FaceClock recebe o token emitido pelo ERP e valida esse token.

Não possuir login próprio não significa permitir chamadas anónimas. Todos os endpoints sensíveis do FaceClock devem exigir uma identidade válida emitida pelo ERP ou uma credencial segura de serviço.

## Conclusão técnica

O `assiduidade_system_backend` está corretamente orientado para não possuir login próprio. A autenticação deve continuar centralizada no Nexora ERP.

Porém, a implementação atual contém uma falha crítica: vários endpoints biométricos aceitam pedidos sem autenticação. Além disso, parte da documentação descreve fluxos de registo de ponto e sincronização que já não existem no código carregado atualmente.

## Arquitetura atualmente implementada

```text
                    ┌──────────────────────────┐
                    │ Aplicação / Frontend     │
                    └────────────┬─────────────┘
                                 │ login/OAuth2
                                 ▼
┌──────────────────────────────────────────────────────────┐
│ Nexora ERP — backend Go                                  │
│                                                          │
│ • Identidade, utilizadores e tenants                      │
│ • OAuth2 / JWT RS256 / JWKS                              │
│ • Funcionários, consentimentos e configuração             │
│ • Eventos e resultados de assiduidade                     │
│ • Terminais REST e MQTT                                   │
└───────────────┬───────────────────────────┬───────────────┘
                │ Bearer JWT                │ X-API-Key
                │ enrollment                │ configuração
                ▼                           ▲
┌──────────────────────────────────────────────────────────┐
│ FaceClock — backend Python/FastAPI                       │
│                                                          │
│ • Templates faciais e digitais                           │
│ • Qualidade da captura e reconhecimento facial            │
│ • Prova de vida                                          │
│ • Verificação local do JWT do ERP via JWKS               │
│ • Proxy de auditoria                                      │
└──────────────────────────────────────────────────────────┘

Terminais físicos ── REST/X-API-Key ou MQTT ──► Nexora ERP
```

## Responsabilidades dos componentes

| Componente | Responsabilidade |
|---|---|
| Nexora ERP | Fonte de verdade de identidade, tenant, RH, consentimento, configuração e assiduidade |
| FaceClock | Motor especializado de biometria e prova de vida |
| PostgreSQL do ERP | Funcionários, dispositivos, eventos e resultados |
| PostgreSQL do FaceClock | Templates biométricos |
| MQTT | Comunicação assíncrona dos terminais físicos com o ERP |
| REST | Comunicação síncrona entre aplicação, ERP e FaceClock |

O ERP encaminha o enrollment facial para o FaceClock, reutilizando o Bearer token do gestor.

O FaceClock consulta a configuração do tenant através de `GET /api/hardware/assiduidade/config`, usando `X-API-Key`.

## Autenticação sem login no segundo backend

O fluxo correto é:

1. A aplicação autentica exclusivamente no ERP.
2. O ERP emite um access token OAuth2 assinado com RS256.
3. A aplicação envia o mesmo Bearer token ao FaceClock.
4. O FaceClock obtém as chaves públicas do ERP em `/oauth/jwks`.
5. O FaceClock valida localmente o token, sem consultar o ERP em cada pedido.

Essa separação é tecnicamente adequada: o FaceClock não precisa conhecer passwords nem emitir sessões próprias.

## Problemas encontrados

### 1. FaceClock aceita pedidos sem autenticação

Atualmente alguém pode chamar um endpoint como:

```text
POST /api/v1/biometric/enroll
```

sem enviar token.

Quando não existe Bearer token nem `X-Auth-User-Id`, o `get_actor()` devolve aproximadamente:

```text
id = vazio
role = SYSTEM
tenant_id = vazio
```

Consequências possíveis:

- enrollment facial chamado anonimamente;
- verificação facial sem isolamento por tenant;
- impressão digital registada, identificada ou removida anonimamente;
- dados criados com `tenant_id` vazio;
- consultas sem filtro de empresa.

O comportamento correto deve ser:

```text
Sem token ou credencial válida → HTTP 401 Não autorizado
```

### 2. Um funcionário pode cadastrar biometria de outra pessoa

Um funcionário autenticado pode enviar um pedido semelhante a:

```json
{
  "user_id": "123",
  "captures": []
}
```

mesmo que o ID do próprio funcionário seja `456`.

O FaceClock não confirma sempre se:

```text
utilizador autenticado = utilizador indicado no pedido
```

O comportamento correto deve ser:

- funcionário comum cadastra apenas a própria biometria;
- gestor de RH pode cadastrar biometria de funcionários do seu tenant;
- qualquer outra situação recebe `403 Proibido`.

### 3. Consentimento biométrico pode ser ignorado

O ERP verifica se o funcionário autorizou o uso dos dados biométricos antes de encaminhar o enrollment.

O fluxo abaixo possui a verificação do ERP:

```text
Aplicação → ERP → FaceClock
```

Entretanto, uma chamada direta pode ignorar essa verificação:

```text
Aplicação → FaceClock
```

O próprio código do FaceClock possui um `TODO` para validar o consentimento antes do enrollment.

### 4. Templates biométricos não estão cifrados pela aplicação

O FaceClock armazena:

- embedding facial em bytes;
- template da impressão digital em Base64 textual.

Não foi identificada cifragem de campo antes da gravação.

Se alguém obtiver acesso à base de dados, poderá copiar os templates. Esses dados devem ser cifrados com gestão segura e rotação de chaves.

### 5. Configuração de assiduidade não é verdadeiramente multitenant

O FaceClock utiliza uma única `ERP_API_KEY`, associada a um dispositivo e tenant no ERP.

O cache de configuração também é global, sem ser indexado pelo `tenant_id`.

Exemplo do problema:

```text
Empresa A: reconhecimento facial ativo
Empresa B: reconhecimento facial desativado
```

Uma instância compartilhada do FaceClock pode consultar a configuração da Empresa A ao processar um utilizador da Empresa B.

### 6. Quando o ERP está indisponível, o FaceClock permite a operação

Quando o FaceClock não consegue consultar a configuração no ERP, a política atual é falhar aberto:

```text
ERP indisponível → permitir método biométrico
```

Isso melhora a disponibilidade, mas pode permitir um método desativado pela empresa.

Recomendação:

- enrollment e operações administrativas: falhar fechado;
- marcação offline: permitir apenas quando existir uma política offline explícita;
- operações liberadas offline devem ser auditadas e sincronizadas posteriormente.

### 7. O issuer do JWT não é validado

A validação atual confirma a assinatura RS256, a expiração e a audience, mas não impõe explicitamente o issuer esperado.

O FaceClock deve validar:

- assinatura RS256;
- `iss`;
- `aud`;
- `exp`;
- `nbf`, quando utilizado;
- `sub`;
- `tid`;
- scopes necessários.

### 8. O FaceClock não regista atualmente o ponto no ERP

O FaceClock responde ao reconhecimento com um resultado semelhante a:

```json
{
  "match": true
}
```

Isso confirma apenas que o rosto corresponde ao template.

No conjunto de routers atualmente carregado, o FaceClock não envia automaticamente o evento de entrada ou saída ao ERP. Outro componente precisa realizar esse registo.

### 9. Documentação e código não estão sincronizados

Parte da documentação menciona endpoints como:

- `/clock/register`;
- `/clock/register/batch`;
- endpoints QR;
- endpoints NFC;
- consentimentos;
- sincronização de funcionários;
- login proxy.

Porém, o runtime atual do FaceClock carrega somente:

- biometria;
- liveness;
- fingerprint;
- proxy de auditoria;
- health;
- readiness;
- métricas.

## Explicação simples dos problemas

O desenho geral está correto:

```text
ERP = login, funcionários, permissões e assiduidade
FaceClock = reconhecimento facial e prova de vida
```

Os quatro problemas mais importantes são:

1. O FaceClock deve rejeitar pedidos sem token.
2. Um funcionário não pode cadastrar biometria de outra pessoa.
3. O consentimento deve ser obrigatório.
4. Depois de reconhecer o rosto, o evento de ponto precisa ser enviado e confirmado pelo ERP.

## Arquitetura recomendada

```text
Autenticação:
App ── OAuth2/PKCE ──► ERP
App ── Bearer ERP ──► FaceClock
FaceClock ── JWKS cache ──► ERP

Enrollment administrativo:
Gestor ── Bearer ──► ERP
ERP ── Bearer + contexto validado ──► FaceClock

Verificação e marcação:
App ── imagem + Bearer ──► FaceClock
FaceClock ── resultado biométrico ──► ERP /api/hardware/events
ERP ── evento confirmado ──► App

Terminais:
Terminal ── X-API-Key/REST ou MQTT ──► ERP
```

## Fluxo recomendado de marcação

1. O utilizador faz login no ERP.
2. O ERP devolve um access token OAuth2.
3. A aplicação envia a fotografia e o token ao FaceClock.
4. O FaceClock valida o token através das chaves JWKS do ERP.
5. O FaceClock confirma identidade, tenant, qualidade e prova de vida.
6. O FaceClock verifica se o método está autorizado para o tenant.
7. O FaceClock envia o evento validado ao ERP.
8. O ERP valida o dispositivo/serviço, funcionário, tenant e regras de assiduidade.
9. O ERP grava oficialmente a entrada ou saída.
10. A aplicação recebe a confirmação do ERP.

## Matriz de credenciais

| Comunicação | Credencial recomendada |
|---|---|
| Aplicação → ERP | OAuth2 Authorization Code com PKCE |
| Aplicação → FaceClock | Bearer token RS256 emitido pelo ERP |
| ERP → FaceClock em nome do gestor | Bearer token do gestor com scope necessário |
| FaceClock → ERP para configuração/eventos | OAuth2 Client Credentials ou API Key de dispositivo por tenant |
| Terminal → ERP REST | API Key individual do dispositivo |
| Terminal → broker MQTT | Credencial MQTT individual e ACL por tópico |

## Prioridades de correção

### Prioridade 0 — segurança imediata

1. Fazer `get_actor()` responder `401` quando não existir identidade válida.
2. Exigir autenticação em todos os endpoints biométricos.
3. Impedir consultas sem `tenant_id`.
4. Exigir vínculo entre `actor.id` e `payload.user_id`.

### Prioridade 1 — autorização e proteção biométrica

1. Validar consentimento antes do enrollment.
2. Aplicar scopes de gestor e colaborador.
3. Cifrar templates biométricos em repouso.
4. Criar auditoria para enrollment, revogação e remoção.

### Prioridade 2 — comunicação multitenant

1. Substituir a única API Key global por credenciais por tenant.
2. Indexar o cache por `tenant_id`.
3. Validar `issuer` do JWT.
4. Implementar envio confiável do evento ao ERP.

### Prioridade 3 — confiabilidade

1. Definir timeouts e retries controlados.
2. Usar idempotency key nos eventos de assiduidade.
3. Criar fila de reenvio para operação offline.
4. Implementar métricas por tenant sem expor dados sensíveis.
5. Atualizar documentação e OpenAPI.

## Testes recomendados

- pedido anónimo deve retornar `401`;
- token expirado deve retornar `401`;
- token com issuer incorreto deve retornar `401`;
- colaborador tentando enrollment de outro utilizador deve retornar `403`;
- utilizador de um tenant não pode acessar template de outro tenant;
- consentimento ausente ou revogado deve bloquear enrollment;
- método desativado deve bloquear verificação;
- ERP indisponível deve seguir a política definida para cada operação;
- evento repetido com a mesma idempotency key não pode gerar dois pontos;
- API Key de um tenant não pode consultar configuração de outro.

## Resultado final da análise

A separação entre ERP e FaceClock é adequada, desde que:

- o ERP continue como único provedor de login e identidade;
- o FaceClock exija sempre token ou credencial de serviço;
- o ERP seja a fonte oficial dos eventos de assiduidade;
- o FaceClock persista somente os dados estritamente necessários à biometria;
- o isolamento por tenant seja obrigatório em todas as operações;
- o consentimento e a proteção criptográfica dos dados biométricos sejam tratados como requisitos centrais.

