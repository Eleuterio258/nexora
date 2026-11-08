# Integração da assiduidade: ERP, FaceClock e app Android

Estado em 2026-09-26. Esta versão corrige uma análise anterior, que tinha três afirmações desactualizadas: o PIN já passar pelo self-service, a prova de vida por omissão ser passiva, e ser preciso criar de raiz um endpoint de lote. Também inclui as alterações feitas a 2026-09-26.

| Componente | Pasta | Tecnologia | Papel |
|---|---|---|---|
| **Nexora ERP** | [backend](backend) | Go (chi, pgx, PostgreSQL) | Fonte da verdade: identidade, tenants, funcionários, eventos de ponto (`rh.eventos_assiduidade`), regras e cálculo diário, consentimentos. Único ponto de entrada da app. |
| **FaceClock** | [assiduidade_system_backend](assiduidade_system_backend) | Python (FastAPI, ONNX, OpenCV) | Motor biométrico. Não guarda funcionários nem eventos de ponto; guarda `face_templates`, `fingerprint_templates`, `device_public_keys`, `api_credentials`, `biometric_audit_logs` e `outbox_events`. |
| **Nexora Assiduidade** | [nexora_assiduidade](nexora_assiduidade) | Kotlin (CameraX, MediaPipe, Retrofit, Room) | App do colaborador (marcar ponto, histórico, justificações) e do gestor (enrolment facial, relatórios, configuração). |

## 1. Quem fala com quem

```
App Android ──JWT (OAuth2)──▶ ERP ──HMAC X-Nexora-*──▶ FaceClock
                              ▲  ◀── outbox (re-enrolment) ──┘
Terminais físicos ──X-API-Key──┘   (RequireDeviceAuth, /api/hardware/*)
```

- **App → ERP**: só JWT. Desde 2026-09-26 a app **não chama nenhuma rota `/api/hardware/*`** e já não inclui a `DEVICE_API_KEY`.
- **ERP → FaceClock**: HMAC-SHA256 sobre método, caminho, query, timestamp, nonce e hash do corpo. O nonce fica em Redis (`SET NX EX 300`), o que impede reenviar o mesmo pedido.
- **FaceClock → ERP**: consultas com a chave de dispositivo (`erp_client.py`); o aviso de re-enrolment segue pela outbox transaccional, com retry.
- **Terminais físicos → ERP**: `/api/hardware/events*` com a chave de dispositivo registada em `hardware.devices`.

## 2. Marcação de ponto

Todas as marcações da app vão para `POST /api/self-service/assiduidade/ponto` ([ponto.go](backend/internal/modules/self-service/handlers/ponto.go)). O ERP identifica o funcionário pelo JWT, confirma que o método está activo no tenant e **verifica a prova na mesma transacção** em que grava o evento.

| Método | Ecrã | Prova verificada pelo ERP | Offline? |
|---|---|---|---|
| Facial | `LivenessChallengeFragment` (desafio activo; é o que o cartão "Facial" abre) | Comprovativo JWT do FaceClock, de uso único (`jti` consumido em `rh.facial_verification_uses`), com confiança ≥ 0.85 e liveness ≥ 0.68 | Não |
| QR Code | `QrCodeAttendanceFragment` | `ValidarEUsarQRToken`: token do terminal, de uso único | Não |
| NFC | `NfcAttendanceFragment` | Tag activa em `rh.nfc_tags` do próprio funcionário | Não |
| Selfie + GPS | `SelfieGpsAttendanceFragment` | Coordenadas e foto obrigatórias | Não |
| PIN | `PinAttendanceFragment` | bcrypt contra `auth.user_auth_codes`. **Mudou a 2026-09-26**: antes eram um login por PIN mais um registo pela rota de hardware | Sim |
| Impressão digital | `FingerprintAttendanceFragment` | Nenhuma do lado do servidor (o `BiometricPrompt` só desbloqueia o telemóvel). **Mudou a 2026-09-26**: antes ia pela rota de hardware | Sim |
| Manual | — | Só gestor: `POST /api/rh/assiduidade/ponto`. O ecrã morto da app foi removido | — |

### Sincronização offline (novo a 2026-09-26)

`POST /api/self-service/assiduidade/ponto/batch` ([ponto_lote.go](backend/internal/modules/self-service/handlers/ponto_lote.go)), usado pelo `SyncAttendanceWorker`:

- aceita até 100 marcações, **só PIN e impressão digital**, porque as outras provas expiram antes de a rede voltar;
- a hora do telemóvel é aceite até **72h** no passado e nunca no futuro (com 5 min de folga). O evento fica com `offline | registado_no_dispositivo=… | sincronizado_em=…` nas observações, para o RH poder rever;
- o PIN é verificado no momento da sincronização. Guarda-se cifrado com o Android Keystore enquanto espera e apaga-se a seguir. Depois de um PIN errado, os restantes PINs do lote são rejeitados sem verificação; a rota tem rate limit de 10/min. Isto impede usar um lote para tentar vários PINs;
- idempotência por `idempotency_key` em `rh.marcacoes_offline_sincronizadas` (migração `20260926120000`): reenviar um lote nunca duplica pontos, e os eventos que ficaram em `SYNCING` também são reenviados;
- a resposta é dada por marcação (`registado`, `duplicado` ou `rejeitado`). As rejeitadas ficam `REJECTED` na app, com o motivo, e não voltam a ser enviadas;
- só são enviadas as marcações do utilizador com sessão iniciada.

## 3. Enrolment facial (gestor)

`POST /api/rh/funcionarios/biometria/facial/enroll` exige a permissão `recursos-humanos.gerir_funcionarios`, um funcionário activo do mesmo tenant, consentimento biométrico activo e o método facial activo. O ERP envia as capturas ao FaceClock por HMAC, e o FaceClock gera e guarda o template.

## 4. O que continua em aberto

| Ponto | Situação | Risco |
|---|---|---|
| **Assinatura das capturas faciais** | `REQUIRE_IMAGE_SIGNATURE=false` e a app não assina. O FaceClock já verifica Ed25519 com uma chave pública registada por dispositivo | Ver secção 5: assinar sem atestação do dispositivo não impede a injecção de imagens |
| **Modelo anti-spoofing** | `LIVENESS_MODEL=heuristic` por omissão. O `anti_spoofing.onnx` (MiniFASNetV2) não recorta o rosto nem normaliza como o modelo espera | Não activar sem calibrar com imagens reais |
| **Desafio activo** | Os limiares de piscar e sorriso foram calibrados a olho; o desafio nunca foi testado em dispositivo real | Falsas rejeições ou falsas aceitações |
| **Cache de configuração no FaceClock** | Por confirmar se `attendance_validation.py` separa a cache por tenant | Um tenant pode herdar a configuração de outro |
| **Impressão digital** | Nenhuma prova do lado do servidor, online ou offline | Equivale a "tem sessão iniciada neste telemóvel" |
| **Entrada/saída offline** | A inferência conta os eventos do dia inteiro, não os anteriores ao instante da marcação | Se chegar uma marcação offline depois de marcações online posteriores do mesmo dia, o tipo pode sair trocado; fica assinalada como offline para revisão |
| **Chave de dispositivo nos APKs antigos** | As versões anteriores da app têm a `DEVICE_API_KEY` embutida | Rodar a chave em `hardware.devices` só depois de toda a gente actualizar a app, senão as marcações dessas versões falham |

## 5. Assinatura de imagens: porque ficou por fazer

A app pode assinar cada captura com uma chave do Android Keystore, e o FaceClock já sabe verificar. Mas isso só prova que *uma instalação com aquela chave* enviou os bytes:

- uma câmara virtual, ou uma app modificada num telemóvel com root, entrega frames falsos ao CameraX, e a app assina-os;
- se a chave pública for registada pelo próprio utilizador (TOFU), quem tiver o JWT regista a sua própria chave e assina o que quiser a partir de um script.

Para a assinatura ter valor, é preciso ancorá-la num destes mecanismos:

1. **Registo da chave num momento de confiança**: por exemplo, o gestor aprova o telemóvel durante o enrolment, e a chave fica ligada ao funcionário e ao dispositivo. Isto trava os scripts com JWT roubado, mas não as câmaras virtuais.
2. **Key Attestation do Android**: o ERP valida a cadeia de certificados da Google e confirma que a chave é de hardware e pertence à app com a nossa assinatura. É mais robusto, mas implica fazer parsing de ASN.1 no ERP.
3. **Play Integrity API**: o token de integridade leva como nonce o hash da imagem, e o ERP valida-o junto da Google. É o mais prático contra apps modificadas e emuladores, mas exige um projecto Google Cloud e uma conta de serviço.

É uma decisão de produto e de infraestrutura. A recomendação é a opção 3, combinada com a 1.
