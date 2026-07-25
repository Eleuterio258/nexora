# Métodos de registo de assiduidade — como funcionam

Documenta os 7 métodos de registo de presença do funcionário (`ui/funcionario/attendance/*Fragment.kt`) e o pipeline comum que todos partilham no backend.

## Pipeline comum (depois da prova de identidade validada)

Todos os métodos convergem no mesmo caminho final:

```
ClockRegisterRequest
  → AttendanceRepository.registerClock()
  → POST /api/hardware/events/generic  (Nexora ERP, autenticado por X-API-Key de device)
  → processor.go:
      1. Dedup por hash (device_id+employee_no+event_time+raw)
      2. INSERT em hardware.device_events (log bruto)
      3. Mapeamento hardware.device_users(device_id, employee_no) → rh.funcionarios.id
      4. inferirTipoEventoCodigo decide entrada/saída sozinho (Constants.EVENT_AUTO)
      5. INSERT em rh.eventos_assiduidade
```

Se não houver rede: o evento é guardado em Room local (`PendingEventEntity`) e sincronizado depois pelo `SyncAttendanceWorker`.

Ficheiros-chave:
- [AttendanceRepository.kt](../app/src/main/java/tech/e258tech/nexora_assiduidade/data/repository/AttendanceRepository.kt)
- [processor.go](../../backend/internal/modules/hardware/service/processor.go)
- [generic_rest.go](../../backend/internal/modules/hardware/adapters/generic_rest.go)

## O que cada método valida *antes* de chegar a esse pipeline

| Método | Prova capturada | Onde é validada | Fica registado como |
|---|---|---|---|
| **Manual** | Nenhuma — só a sessão JWT já autenticada | Não há validação nenhuma | `source=MANUAL` |
| **Facial** | Foto (auto-capturada por MediaPipe on-device) | `POST /biometric/verify` (FaceClock) — embedding + cosine similarity contra `FaceTemplate` + liveness score | `source=FACIAL`, só se `match=true` |
| **Impressão Digital** | Nada enviado ao servidor — `BiometricPrompt` local do Android só confirma "é o dono do telemóvel" | Nenhuma verificação servidor-side (a API BiometricPrompt nunca expõe o template) | `source=FINGERPRINT`, `confidence_score` fixo em `1.0` |
| **QR Code** | Token lido por câmara (ZXing) | `POST /api/hardware/assiduidade/qr/validar` — token de uso único, TTL 60-300s, gerado à parte por `qr/gerar` | `source=QR_CODE` |
| **NFC** | UID do cartão lido por foreground dispatch | `GET /api/hardware/assiduidade/nfc/validar?tag_uid=` — contra `rh.nfc_tags`, pré-registado por funcionário via admin | `source=NFC` |
| **PIN** | 4+ dígitos | `POST /api/authcode/pin/validate` — devolve um login completo (tokens+utilizador), a sessão é actualizada antes de registar | `source=PIN` |
| **Selfie + GPS** | Foto (câmara nativa do sistema) + última localização conhecida | Nenhuma — o endpoint de geofence existe (`/geofence/validar`) mas exige `unidade_id` que este ecrã não recolhe | `source=GEOLOCATION` (não `SELFIE_GPS`) |

## ✅ Resolvido: "Configurar Métodos" agora vale para os 7 métodos

Originalmente, o ecrã de gestor **"Configurar Métodos"** ([ConfigAssiduidadeFragment.kt](../app/src/main/java/tech/e258tech/nexora_assiduidade/ui/gestor/configuracao/ConfigAssiduidadeFragment.kt)) só tinha efeito real sobre o **Facial** — o único método que passava por `validar_metodo_assiduidade` (dentro do `/biometric/verify` do FaceClock) antes de registar. Os outros 6 falavam directamente com o ERP Go (`/api/hardware/events/generic`, `/qr/validar`, `/nfc/validar`, `/authcode/pin/validate`), sem nenhum handler a consultar o catálogo de features.

Corrigido adicionando `Processor.metodoAssiduidadeActivo` a [processor.go](../../backend/internal/modules/hardware/service/processor.go) — chamado no início de `processEntity`, antes até do mapeamento `employee_no`, para todos os eventos que chegam a `POST /api/hardware/events/generic` (ou seja, os 7 métodos, já que todos convergem nesse endpoint no passo final do pipeline). Traduz `event.CredentialType` (`face`, `fingerprint`, `qr`, `nfc`, `pin`, `geolocation`, `manual`) para a chave de `rh.assiduidade.configuracao.metodos` (`facial`, `fingerprint`, `qr_code`, `nfc`, `pin`, `geolocation`, `manual`) e consulta a mesma configuração que o ecrã de gestor edita — falha aberta (permite) em qualquer caso ambíguo, espelhando `validar_metodo_assiduidade` no FaceClock.

Se o método estiver desligado, o evento continua a ser gravado em `hardware.device_events` (auditoria), mas fica `processed=false` com `error_message="Método de assiduidade '<metodo>' não permitido para este tenant."`.

Isto só ficou visível ao funcionário depois de corrigir também [AttendanceRepository.kt](../app/src/main/java/tech/e258tech/nexora_assiduidade/data/repository/AttendanceRepository.kt): `registerClock()` tratava **qualquer** HTTP 2xx como sucesso, sem olhar para `processed`/`error` no corpo — o mesmo bug haveria para "employee_no não mapeado" ou qualquer outra falha silenciosa de `processEntity`. Agora só é `RegisterResult.Success` quando `processed=true`; caso contrário é `RegisterResult.Error(body.error)`, e o funcionário vê a mensagem real em vez de "Registo realizado com sucesso."
