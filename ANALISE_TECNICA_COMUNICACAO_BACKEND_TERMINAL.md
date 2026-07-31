# Análise técnica da comunicação entre Nexora ERP e o Terminal de Assiduidade

## Contexto

Diretórios analisados:

- `D:\projecto\e-258tech\2026\factPro\backend` (Nexora ERP, Go)
- `D:\projecto\e-258tech\2026\factPro\terminal` (Terminal de assiduidade, Java/Swing — PIN, QR, NFC, digital)

O terminal é um kiosk físico (ecrã táctil pequeno, ver `screen.width`/`screen.height` em `AppConfig`) que regista marcações de ponto localmente (SQLite) e as encaminha para o ERP. É um cliente "device" do ERP, não um utilizador humano com login próprio — modelo equivalente ao do FaceClock analisado em `ANALISE_TECNICA_COMUNICACAO_BACKENDS.md`, mas aqui a implementação está bastante mais madura.

## Arquitetura implementada

```text
┌──────────────────────────────────────────────────────────┐
│ Terminal (Java/Swing) — kiosk físico                      │
│                                                            │
│ • SQLite local: funcionários, PIN/QR/NFC/digital, registos │
│ • PIN/QR/NFC/digital nunca saem do terminal                │
│ • UI: PIN, QR, NFC (PC/SC), Digital (simulada), Admin      │
└───────────────┬────────────────────────────┬───────────────┘
                │ GET funcionários            │ POST evento
                │ X-API-Key                   │ X-API-Key
                ▼                            ▼
┌──────────────────────────────────────────────────────────┐
│ Nexora ERP — backend Go                                   │
│                                                            │
│ • hardware.devices — API Key por dispositivo, por tenant   │
│ • hardware.device_events — idempotência por event_hash     │
│ • hardware.device_users — mapeamento employee_no → pessoa  │
│ • rh.eventos_assiduidade — fonte de verdade da assiduidade  │
└──────────────────────────────────────────────────────────┘
```

Fluxo:

1. Admin sincroniza funcionários: `GET /api/hardware/assiduidade/funcionarios` → `ErpSyncService.sincronizarFuncionarios()` cria/actualiza nome, número e estado activo localmente (`ErpApiClient.java:46`, `assiduidade_integracao.go:83`).
2. Colaborador marca ponto por PIN/QR/NFC/digital — validado 100% localmente contra a SQLite do terminal (`AuthService`, `PontoService`).
3. `PontoService.registarMarcacao` grava local e chama `ErpSyncService.enviarEventoAsync` numa thread separada, best-effort (`PontoService.java:57`).
4. `ErpApiClient.enviarEvento` faz `POST /api/hardware/events/generic`, contrato `adapters.GenericPayload` (`ErpApiClient.java:60`).
5. No ERP, `receberEventoComAdapter` → `Processor.Process` grava em `hardware.device_events` (idempotente por `event_hash`) e, se o `employee_no` estiver mapeado e o método activo para o tenant, regista o evento em `rh.eventos_assiduidade` (`processor.go:43-153`).

## Autenticação

`RequireDeviceAuth` (`device_auth.go:37`) valida `X-API-Key` contra `hardware.devices.api_key_hash`, **por tenant** (`tenant_id` vem do próprio dispositivo, não de um valor global) — corretamente isolado, ao contrário do `ERP_API_KEY` único que a análise ERP↔FaceClock tinha identificado como problema. Suporta ainda restrição opcional por IP (`ip_permitido`, CIDR ou IP exacto).

O `api.device.key` do terminal fica em `application.properties`/`ConfiguracaoDao` (BD local), vazio por omissão — não há chave real commitada no repositório.

## Pontos fortes identificados

1. **Idempotência correta** — `event_hash` com `ON CONFLICT DO NOTHING` evita duplicar marcações num retry de rede (`processor.go:43-74`), coisa que o design antigo (comentado no código) não garantia.
2. **Contrato `processed`/`error` bem tratado no cliente** — o ERP pode responder `200 {"processed": false, "error": "..."}` quando aceita o evento mas não consegue transformá-lo numa marcação (funcionário não mapeado, inactivo, método desligado). `ErpApiClient.garantirProcessado` (linha 91) trata isto como falha, com um comentário explícito a documentar um bug histórico corrigido (olhar só para o código HTTP 2xx escondia marcações perdidas). Boa prática mantida.
3. **Separação clara de responsabilidades** — PIN/QR/NFC/digital ficam só no terminal; o ERP é autoritativo para identidade (nome/número/activo), não para credenciais biométricas (`ErpSyncService.java:16-19`).
4. **Vocabulário de eventos documentado com o porquê** — os comentários em `EventoGenerico` explicam decisões não óbvias (ex.: por que `"in"/"out"` foi trocado por `"entry"/"exit"`, por que `"qr"` precisa de mapeamento explícito em `credencial()`), o que reduz risco de regressão silenciosa.

## Problemas / lacunas encontradas

### 1. Sem fila de reenvio para eventos falhados

`enviarEventoAsync` (`ErpSyncService.java:59-73`) é *fire-and-forget*: se o ERP estiver em baixo ou a rede falhar, o registo fica com `sincronizado = 0` na SQLite local, mas **nada volta a tentar reenviá-lo** — não há job periódico nem qualquer código que consulte `sincronizado = 0` (confirmado por busca no código). Um corte de rede de alguns minutos apaga permanentemente a sincronização dessas marcações com o ERP, a não ser que alguém note e resolva manualmente.

### 2. Sincronização de funcionários é 100% manual

Não há nenhum agendamento (`Timer`/`ScheduledExecutor`) a chamar `sincronizarFuncionarios()` periodicamente — só corre quando o admin clica em "Sincronizar ERP" (`EmployeeManagementPanel.java:246-268`). Se um funcionário for desactivado no ERP a meio do dia, o terminal continua a aceitar as suas marcações localmente até alguém sincronizar manualmente.

### 3. Sem protecção contra força bruta no PIN

`PinAuthPanel` não tem qualquer limite de tentativas, atraso progressivo ou bloqueio temporário. Combinado com o PIN mínimo de 4 dígitos (`definirPin` em `EmployeeManagementPanel.java:142`) e o PIN de admin por omissão `0000` (documentado como "MUDAR em produção", mas sem enforcement no código), um kiosk fisicamente acessível é vulnerável a tentativa exaustiva de PIN.

### 4. `credential_type` desconhecido falha aberto

`metodoAssiduidadeActivo` (`processor.go:183-192`) devolve `true` (permite) quando o `credential_type` não está no mapa `credentialTypeToMetodo` — decisão documentada no código como deliberada, mas significa que desligar um método de assiduidade no ecrã de configuração do tenant só tem efeito garantido para os 7 tipos mapeados; qualquer adapter novo que envie um `credential_type` diferente ignora silenciosamente essa configuração.

### 5. Timeout curto sem retry/backoff

`ErpApiClient` usa timeout fixo de 10s (`requestBuilder`) sem retry nem backoff exponencial. Combinado com o ponto 1 (sem fila de reenvio), uma rede instável no local do kiosk (comum em ambientes com Wi-Fi fraco) tem impacto maior do que teria com uma retry policy simples.

### 6. Sem auditoria de acesso ao painel de admin

`AdminLoginDialog`/`goToAdminGated` não regista tentativas de acesso (sucesso ou falha) a nenhum lado — nem localmente nem no ERP. Se o PIN de admin for comprometido, não há rasto de quem entrou no painel de gestão de funcionários do terminal.

## Prioridades de correção sugeridas

### Prioridade 0 — fiabilidade da assiduidade

1. Fila de reenvio: job periódico (`Timer`/`ScheduledExecutor`) que consulta `registo_ponto WHERE sincronizado = 0` e tenta reenviar com backoff.
2. Sincronização periódica de funcionários (ex.: a cada N minutos, além do botão manual).

### Prioridade 1 — segurança do kiosk físico

1. Limite de tentativas + bloqueio temporário no `PinAuthPanel` (local, sem depender do ERP).
2. Forçar troca do `admin.pin` por omissão no primeiro arranque, em vez de aceitar `0000` indefinidamente.
3. Registo local (e idealmente envio ao ERP) de tentativas de acesso ao painel de admin.

### Prioridade 2 — robustez de rede

1. Retry com backoff exponencial em `ErpApiClient.enviar`.
2. Rever a lista `credentialTypeToMetodo` para decidir explicitamente se tipos desconhecidos devem falhar fechado em vez de aberto — pelo menos registar um aviso quando isso acontece, hoje é silencioso.

## Resultado final da análise

A integração backend↔terminal está bem desenhada nos pontos estruturais mais difíceis de acertar (idempotência, isolamento por tenant no device auth, contrato `processed` tratado correctamente do lado do cliente). As lacunas encontradas são principalmente de **robustez operacional** (sem retry, sem sincronização periódica) e de **segurança do kiosk físico** (PIN sem protecção contra força bruta, PIN de admin fraco por omissão), não falhas estruturais de arquitectura como as identificadas na análise ERP↔FaceClock.
