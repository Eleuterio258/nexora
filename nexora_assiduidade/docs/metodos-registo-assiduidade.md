# Métodos de registo de assiduidade — como funcionam

Documenta os métodos de registo de presença do funcionário (`ui/funcionario/attendance/*Fragment.kt`) e o pipeline comum que todos partilham no backend.

## Pipeline comum (estado em 2026-09-26)

Todos os métodos marcam ponto no Nexora ERP **com o JWT do colaborador**, em `POST /api/self-service/assiduidade/ponto` ([ponto.go](../../backend/internal/modules/self-service/handlers/ponto.go)). A app já não chama `/api/hardware/*` e não traz nenhuma API Key de device (`DEVICE_API_KEY` removida do `build.gradle.kts`).

```
Ecrã do método
  → POST /api/self-service/assiduidade/ponto  { metodo, pin?, dados{...} }
  → MarcarPonto (ERP):
      1. funcionário resolvido pelo JWT (nunca pelo cliente) e tem de estar activo
      2. método activo na configuração do tenant (rh.assiduidade.configuracao.metodos)
      3. prova do método verificada NA MESMA transacção que grava o evento
      4. entrada/saída inferida pela paridade do dia quando o cliente não a indica
      5. INSERT em rh.eventos_assiduidade
```

**Sem rede** (só PIN e impressão digital, via [AttendanceRepository.kt](../app/src/main/java/tech/e258tech/nexora_assiduidade/data/repository/AttendanceRepository.kt)): a marcação fica em Room (`PendingEventEntity`, campos cifrados com o Android Keystore, incluindo o PIN) e o [SyncAttendanceWorker.kt](../app/src/main/java/tech/e258tech/nexora_assiduidade/work/SyncAttendanceWorker.kt) envia-a depois em lote para `POST /api/self-service/assiduidade/ponto/batch` ([ponto_lote.go](../../backend/internal/modules/self-service/handlers/ponto_lote.go)):

- a hora enviada é a do telemóvel no momento da marcação; o ERP aceita-a até **72h** no passado (nunca no futuro, com 5 min de folga) e escreve `offline | registado_no_dispositivo=… | sincronizado_em=…` nas observações do evento para o RH poder rever;
- o PIN é verificado na sincronização; um PIN errado faz rejeitar os restantes PINs do mesmo lote (impede tentar vários PINs num pedido) e a rota tem rate limit;
- cada marcação tem uma `idempotency_key` guardada em `rh.marcacoes_offline_sincronizadas`: reenviar o lote nunca duplica pontos;
- a resposta é por marcação: `registado`/`duplicado` apagam o evento local; `rejeitado` fica como `REJECTED` com o motivo e não volta a ser enviado;
- só são enviadas as marcações do utilizador com sessão iniciada — as de outra pessoa que usou o mesmo telemóvel esperam que essa pessoa volte a entrar.

Facial, QR e NFC dependem de provas de uso único com validade curta e **não** podem ser feitos offline.

## O que cada método prova

| Método | Prova capturada | Onde é validada | `origem` no evento |
|---|---|---|---|
| **Facial** | Desafio de prova de vida activo ([LivenessChallengeFragment.kt](../app/src/main/java/tech/e258tech/nexora_assiduidade/ui/funcionario/attendance/LivenessChallengeFragment.kt)) | FaceClock emite um comprovativo assinado e de uso único; o ERP valida-o e consome o `jti` em `rh.facial_verification_uses` | `reconhecimento_facial` |
| **Impressão digital** | `BiometricPrompt` local — só confirma "é o dono do telemóvel" | Nenhuma do lado do servidor (a API nunca expõe o template) | `impressao_digital` |
| **QR Code** | Token do terminal lido por câmara | `ValidarEUsarQRToken` — uso único, expira no mesmo pedido | `qr` |
| **NFC** | UID do cartão | Tem de existir activo em `rh.nfc_tags` para o próprio funcionário | `nfc` |
| **PIN** | 4-6 dígitos | bcrypt contra `auth.user_auth_codes` no mesmo pedido (ou na sincronização, se offline) | `app` |
| **Selfie + GPS** | Foto + coordenadas | Coordenadas e foto obrigatórias; foto guardada no storage | `selfie` |
| **Manual** | — | Não existe na app do funcionário (ecrã removido em 2026-09-26); é operação de gestor em `POST /api/rh/assiduidade/ponto` | `manual` |

> As secções seguintes são histórico: descrevem o tempo em que os métodos convergiam em `POST /api/hardware/events/generic`.

## ✅ Resolvido: "Configurar Métodos" agora vale para os 7 métodos

Originalmente, o ecrã de gestor **"Configurar Métodos"** ([ConfigAssiduidadeFragment.kt](../app/src/main/java/tech/e258tech/nexora_assiduidade/ui/gestor/configuracao/ConfigAssiduidadeFragment.kt)) só tinha efeito real sobre o **Facial** — o único método que passava por `validar_metodo_assiduidade` (dentro do `/biometric/verify` do FaceClock) antes de registar. Os outros 6 falavam directamente com o ERP Go (`/api/hardware/events/generic`, `/qr/validar`, `/nfc/validar`, `/authcode/pin/validate`), sem nenhum handler a consultar o catálogo de features.

Corrigido adicionando `Processor.metodoAssiduidadeActivo` a [processor.go](../../backend/internal/modules/hardware/service/processor.go) — chamado no início de `processEntity`, antes até do mapeamento `employee_no`, para todos os eventos que chegam a `POST /api/hardware/events/generic` (ou seja, os 7 métodos, já que todos convergem nesse endpoint no passo final do pipeline). Traduz `event.CredentialType` (`face`, `fingerprint`, `qr`, `nfc`, `pin`, `geolocation`, `manual`) para a chave de `rh.assiduidade.configuracao.metodos` (`facial`, `fingerprint`, `qr_code`, `nfc`, `pin`, `geolocation`, `manual`) e consulta a mesma configuração que o ecrã de gestor edita — falha aberta (permite) em qualquer caso ambíguo, espelhando `validar_metodo_assiduidade` no FaceClock.

Se o método estiver desligado, o evento continua a ser gravado em `hardware.device_events` (auditoria), mas fica `processed=false` com `error_message="Método de assiduidade '<metodo>' não permitido para este tenant."`.

Isto só ficou visível ao funcionário depois de corrigir também [AttendanceRepository.kt](../app/src/main/java/tech/e258tech/nexora_assiduidade/data/repository/AttendanceRepository.kt): `registerClock()` tratava **qualquer** HTTP 2xx como sucesso, sem olhar para `processed`/`error` no corpo — o mesmo bug haveria para "employee_no não mapeado" ou qualquer outra falha silenciosa de `processEntity`. Agora só é `RegisterResult.Success` quando `processed=true`; caso contrário é `RegisterResult.Error(body.error)`, e o funcionário vê a mensagem real em vez de "Registo realizado com sucesso."
