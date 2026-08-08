# Fase 4 — Reconhecimento Facial de Produção

**Data:** 2026-08-05  
**Sistema alvo:** FaceClock (`assiduidade_system_backend/`)  
**Estado:** Planeada / Em implementação  

---

## Objetivo

Levar o FaceClock de "pronto para produção em pequena/média escala" para **pronto para produção enterprise**, fechando os gaps de robustez, segurança e escalabilidade remanescentes após as Fases 1–3.

---

## 4.1 Validação de pose e oclusão

### Problema
O pipeline actual rejeita capturas por resolução, nitidez e iluminação, mas não verifica se o rosto está frontal ou se está fortemente ocluso.

### Solução
Usar o `FaceLandmarker` já integrado para estimar:
- **Yaw / pitch / roll** aproximados pelos landmarks 3D.
- **Oclusão** pela ausência ou confiança baixa de landmarks críticos (olhos, nariz, boca).

### Critérios de aceitação
- [ ] Rejeitar capturas com `|yaw| > 25°`, `|pitch| > 20°` ou `|roll| > 15°`.
- [ ] Rejeitar capturas com olhos ou boca fortemente oclusos.
- [ ] Thresholds configuráveis via env vars.
- [ ] Testes unitários para poses frontais e extremas.

### Ficheiros a alterar
- `app/services/biometric.py`
- `app/services/quality.py` (novo ou existente)
- `app/config.py`

---

## 4.2 Liveness passiva com classificador PAD treinado

### Problema
A liveness passiva actual é heurística e pode ser enganada por fotos/vídeos de boa qualidade.

### Solução
Integrar um modelo anti-spoofing leve (ONNX) como primeiro nível, mantendo o desafio ativo como segundo fator.

### Opções de modelo
1. **Silent-Face-Anti-Spoofing** (MobileFaceNet) — pequeno, CPU-friendly.
2. **FAS-SGTD / CDCN** — mais pesado, melhor precisão.
3. Modelo custom treinado internamente.

### Critérios de aceitação
- [ ] Novo `LivenessModel` implementado e registado na factory.
- [ ] Score PAD integrado no fluxo de verify/identify.
- [ ] Métricas `apcer` e `bpcer` recolhidas com modelo real.
- [ ] Testes com amostras de ataque (foto, ecrã, máscara simples).

### Ficheiros a alterar
- `app/services/liveness_models.py`
- `app/services/biometric.py`
- `requirements.txt`

---

## 4.3 Persistência distribuída de liveness challenges

### Problema
O estado dos desafios de liveness está num `dict` em memória, impedindo réplicas horizontais e recuperação após reinício.

### Solução
Mover o estado para Redis, com TTL de 45–60 segundos.

### Critérios de aceitação
- [ ] Implementar `ChallengeStore` com backend em memória (default) e Redis.
- [ ] Seleção via `LIVENESS_CHALLENGE_STORE=redis` + `REDIS_URL`.
- [ ] Mesmo contrato da API actual.
- [ ] Testes de integração com Redis (ou mock).

### Ficheiros a alterar
- `app/services/liveness_challenge.py`
- `app/config.py`

---

## 4.4 Gestão de chaves self-hosted

### Problema
A arquitetura original previa KMS/HSM cloud, mas o deploy e 100% self-hosted.

### Solução
Mantém-se apenas o provedor `environment` (variavel de ambiente), com suporte a
keyring JSON (`BIOMETRIC_ENCRYPTION_KEYS`) para rotacao de chaves sem servicos
externos. A chave e carregada em memoria no arranque e nao e persistida em disco.

### Critérios de aceitação
- [x] Provedor `environment` como unica origem de chave.
- [x] Suporte a keyring JSON para rotacao.
- [x] Rejeicao clara de provedores cloud nao suportados.
- [x] Testes unitarios.

### Ficheiros alterados
- `app/security/key_management.py`
- `tests/test_key_management.py`

---

## 4.5 Rotação de chaves biométricas

### Problema
A chave de encriptação é fixa; não há processo de rotação.

### Solução
Adicionar versionamento de chave no prefixo criptográfico:

```
enc:v2:<key_id_len:1 byte><key_id><nonce:12 bytes><tag:16 bytes><ciphertext>
```

- `key_id` identifica a chave usada.
- Novos templates usam a chave activa.
- Leitura de templates antigos usa a chave correspondente.
- Comando admin para re-encriptar templates com a chave activa.

### Critérios de aceitação
- [ ] Formato `enc:v2` suportado.
- [ ] Múltiplas chaves configuráveis (`BIOMETRIC_ENCRYPTION_KEYS` como JSON).
- [ ] Endpoint admin para re-encriptar todos os templates.
- [ ] Testes de round-trip com chaves antigas e novas.

### Ficheiros a alterar
- `app/security/encryption.py`
- `app/routers/admin.py`

---

## 4.6 Assinatura de payload de imagem

### Problema
A imagem viaja dentro do corpo HMAC, mas não há assinatura específica que prove a proveniência e integridade da captura.

### Solução
Adicionar campo opcional `image_signature` nos requests, assinado pela chave privada do dispositivo (ou pelo ERP no caso de chamadas serviço-a-serviço).

### Critérios de aceitação
- [ ] Suporte a `image_signature` (Base64 da assinatura Ed25519/ECDSA).
- [ ] Validação da assinatura no verify/identify quando fornecida.
- [ ] Configuração para exigir assinatura (`REQUIRE_IMAGE_SIGNATURE=true`).
- [ ] Documentação de geração de chaves no dispositivo.

### Ficheiros a alterar
- `app/schemas/requests.py`
- `app/routers/biometric.py`
- `app/security/image_signature.py` (novo)

---

## 4.7 Matching real de impressões digitais (opcional)

### Problema
O endpoint de impressão digital faz comparação exacta de base64.

### Solução
Integrar biblioteca de extração/minúcias (ex.: SourceAFIS, NBIS) e matching de templates ISO/IEC 19794-2.

### Critérios de aceitação
- [ ] Extração de minúcias de imagem de impressão digital.
- [ ] Matching 1:1 e 1:N.
- [ ] Score de similaridade calibrável.

---

## Ordem recomendada de implementação

1. **4.1 Pose/oclusão** — baixo esforço, alto impacto na qualidade.
2. **4.3 Redis para liveness challenges** — necessário para alta disponibilidade.
3. **4.2 PAD treinado** — maior impacto na segurança anti-spoofing.
4. **4.4 Gestão de chaves self-hosted** — requisito de compliance local.
5. **4.5 Rotação de chaves** — complementa gestão de chaves.
6. **4.6 Assinatura de imagem** — hardening avançado.
7. **4.7 Matching de impressões digitais** — se fingerprint for usar-se em produção.

---

## Estado de implementação

| Item | Estado |
|---|---|
| 4.1 Pose/oclusão | ✅ Implementado |
| 4.2 PAD treinado | ✅ Arquitetura plugável (requer modelo ONNX) |
| 4.3 Redis challenges | ✅ Implementado |
| 4.4 Gestão de chaves self-hosted | ✅ Apenas environment provider + keyring JSON |
| 4.5 Rotação de chaves | ✅ Formato `enc:v2` + endpoint `/admin/biometric/re-encrypt` |
| 4.6 Assinatura de imagem | ✅ Implementado (Ed25519) |
| 4.7 Matching fingerprint | ⏳ Pendente |

---

*Fase 4 criada a partir da análise em `docs/analise-arquitetura-reconhecimento-facial.md`.*
