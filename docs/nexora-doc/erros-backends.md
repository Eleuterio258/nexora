# Análise de Erros — Backends Nexora ERP e FaceClock

> Análise técnica do código de `backend/` (Go) e `assiduidade_system_backend/` (Python/FastAPI).
> Nenhum arquivo foi modificado. `go build ./...` e `python -m compileall` passaram sem erros de compilação.

---

## Backend Go (`D:/projecto/e-258tech/2026/factPro/backend`)

### Críticos

| # | Arquivo | Linha | Problema | Impacto |
|---|---------|-------|----------|---------|
| 1 | `internal/modules/hardware/adapters/generic_rest.go` | 111–112 | `ParseEvent` consome o body antes do HMAC; depois `ValidateAuth` tenta relê-lo, obtendo EOF. A validação de assinatura é quebrada. | Webhooks podem ser aceitos sem assinatura válida; eventos de hardware podem ser falsificados. |
| 2 | `config/config.go` | 188–199 | Connection string e password do PostgreSQL hardcoded (`postgres/admin` em IP público). | Vazamento de credenciais de produção no repositório. |
| 3 | `config/config.go` | 143–148, 266 | Segredos default versionados: `JWT_SECRET`, `JWT_REFRESH_SECRET`, `MINIO_ACCESS_KEY`, `MINIO_SECRET_KEY`, `FACIAL_VERIFICATION_SECRET`. | Tokens podem ser forjados se as envs não forem sobrescritas. |

### Altos

| # | Arquivo | Linha | Problema | Impacto |
|---|---------|-------|----------|---------|
| 4 | `config/config.go` | 214 | `IDHashSalt` reutiliza o `JWT_SECRET` default. | IDs ofuscados em URLs públicas podem ser desofuscados por quem conhecer o secret. |
| 5 | `internal/modules/self-service/handlers/ponto.go` | 415–425 | `verificarPIN` trata qualquer erro de DB como “PIN não configurado” (HTTP 412). | Mascara falhas operacionais e pode permitir enumerar se um utilizador tem PIN. |
| 6 | `internal/modules/self-service/handlers/ponto.go` | 234–246 | Ausência de rate-limit no endpoint de PIN. | Permite brute-force de PIN de 6 dígitos sem contramedidas. |

### Médios

| # | Arquivo | Linha | Problema | Impacto |
|---|---------|-------|----------|---------|
| 7 | `internal/ws/client.go` | 80–81 | Type assertions `claims["sub"].(float64)` sem verificação `ok`. | Panic no WebSocket ao receber token malformado. |
| 8 | `internal/modules/self-service/handlers/perfil.go`, `chat.go`, `aprovacoes/handlers/requests.go`, `gestao-produtos/handlers/produtos.go` | várias | Erros de `Exec`/`QueryRow` ignorados em updates críticos. | Cliente recebe sucesso enquanto a operação falhou (password, sessão, aprovação, etc.). |
| 9 | `internal/modules/recrutamento/handlers/contratar.go` | 91 | Comparação de erro por string literal `"EOF"`. | Body inválido pode passar; comportamento instável com erros wrapped. |
| 10 | `internal/ws/client.go` | 119–122, 259 | Goroutines do WebSocket lançadas sem WaitGroup ou recovery. | Instabilidade no chat/notificações; dificuldade de diagnóstico. |

### Outros pontos

- `rows, _ := h.db.Query(...)` seguido de `defer rows.Close()` pode dar panic se `rows` for `nil` (`produtos.go` e outros handlers).
- `parseDuration` retorna `15m` para qualquer string inválida, mascarando erros de configuração.

---

## Backend Python (`D:/projecto/e-258tech/2026/factPro/assiduidade_system_backend`)

### Altos

| # | Arquivo | Linha | Problema | Impacto |
|---|---------|-------|----------|---------|
| 1 | `app/main.py` | 74–81 | CORS configurado com `allow_origins=["*"]` e `allow_credentials=True` simultaneamente. | Qualquer site pode enviar requests autenticados; facilita CSRF/clickjacking. |
| 2 | `app/services/biometric.py` | 391–414 | `estimate_liveness` é puramente heurístico (FFT, variância de gradiente/cor). | Fácilmente burlado por foto de boa qualidade, tela ou vídeo; `/biometric/verify` não exige desafio de liveness. |
| 3 | `app/main.py` | 105–121 | `general_exception_handler` captura `Exception` e retorna `error_type` no corpo. | Vaza detalhes internos e pode mascarar erros críticos. |
| 4 | `app/config.py` | 8–10 | Segredos default versionados: `JWT_SECRET_KEY`, `BIOMETRIC_ENCRYPTION_KEY`, `FACIAL_VERIFICATION_SECRET`. | Chaves fracas/públicas se envs não forem configuradas. |
| 5 | `app/security/encryption.py` | 41–47, 62–63 | Chave curta é derivada por SHA-256 e truncada; modo legado devolve dados em claro. | Reduz entropia e permite armazenamento acidental de templates sem cifra. |

### Médios

| # | Arquivo | Linha | Problema | Impacto |
|---|---------|-------|----------|---------|
| 6 | `app/services/liveness_challenge.py` | 110 | `_challenges` é um dicionário global em memória. | Não funciona com múltiplas réplicas; permite replay se o tráfego cair noutra instância. |
| 7 | `app/services/attendance_validation.py` | 18–19, 81–82 | Cache de configuração ERP em memória + fail-open se ERP indisponível. | Configuração desatualizada entre réplicas; métodos desativados passam silenciosamente. |
| 8 | `app/routers/fingerprint.py` | 150–162 | `identify_fingerprint` compara templates byte-a-byte como strings. | Não é matching biométrico real; bypass trivial. |
| 9 | `app/main.py` | 31, 108–113 | Logs incluem `DATABASE_URL` e detalhes de exceções não tratadas. | Vazamento de credenciais e informação de debugging em logs operacionais. |
| 10 | `tests/test_api.py` | 177–179 | Monkeypatch no router não funciona; funções são importadas como nomes locais. | Testes usam pipeline real ou falham silenciosamente. |

### Outros pontos

- Estado em memória incompatível com múltiplas réplicas: limiter, métricas biométricas e métricas HTTP.
- `ready` probe em `app/main.py:133–140` não fecha a sessão do DB em caso de erro.
- `biometric.py` e `fingerprint.py` fazem `db.commit()` sem `try/except/rollback` explícito.
- Se `GATEWAY_SHARED_SECRET` estiver vazio (default em dev), qualquer chamador pode forjar `X-Auth-User-Role: ADMIN_SISTEMA`.
- `config.py` estica chaves curtas repetindo-as, o que não aumenta entropia real.

---

## Nota sobre a migração para multipart + MinIO (biometria facial)

A arquitectura foi alterada para que a app Android envie fotos em `multipart/form-data` ao ERP, o ERP faça upload para MinIO e envie `image_url` ao FaceClock. Esta mudança resolve gargalos de base64 para 10 000+ utilizadores, mas introduz novos riscos:

| # | Localização | Risco | Impacto |
|---|-------------|-------|---------|
| 1 | `backend/internal/modules/recursos-humanos/handlers/funcionarios_biometria.go:165` | `ParseMultipartForm(30 MB)` lê tudo em memória; sem stream para MinIO. | Picos de memória com muitos enrollments simultâneos. |
| 2 | `backend/internal/modules/self-service/handlers/biometria.go:115` | `ParseMultipartForm(10 MB)` para a selfie de verificação. | Limite baixo se a câmara enviar PNG de alta resolução. |
| 3 | `funcionarios_biometria.go` e `biometria.go` | Nenhuma lifecycle policy implementada no bucket MinIO. | Fotos biométricas acumulam-se indefinidamente, violando LGPD. |
| 4 | `assiduidade_system_backend/app/services/biometric.py` (download de URL) | FaceClock confia na URL pública do MinIO; se o ERP usar hostname interno, o FaceClock pode não conseguir aceder. | Falha de verificação ou necessidade de presigned URLs. |
| 5 | `assiduidade_system_backend/app/config.py` | `IMAGE_DOWNLOAD_TIMEOUT_SECONDS` e `IMAGE_DOWNLOAD_MAX_BYTES` têm defaults, mas não há validação de content-type nem rate-limit por URL. | Possibilidade de SSRF/reflection se a URL for controlada. |
| 6 | `backend/internal/storage` (presumido) | Uploads para MinIO sem nome de ficheiro normalizado ou sanitização do `device_id` usado na chave. | Risco reduzido de path traversal, mas deve ser auditado. |
| 7 | Android `ErpApiService.kt` | Obrigatório `MultipartBody` pode falhar em proxies antigos ou com compressão automática. | Menor interoperabilidade, mas ganho de performance é grande. |

### Recomendações específicas da migração

1. **Implementar lifecycle policy** no bucket `nexoraerp` para apagar objetos sob `uploads/*/biometria/` após 90 dias.
2. **Usar presigned URLs** se o FaceClock não tiver acesso à URL pública do MinIO.
3. **Adicionar rate-limit** por `user_id`/`device_id` nos endpoints multipart para evitar spam de imagens.
4. **Fazer stream** do multipart diretamente para MinIO (ou usar buffer temporário em disco) para reduzir memória.
5. **Validar content-type e extensão** no ERP antes do upload; rejeitar ficheiros que não sejam JPEG/PNG.
6. **Sanitizar `device_id` e `funcionario_id`** usados nas chaves MinIO para evitar caracteres especiais.
7. **Remover endpoints JSON legacy** após todas as apps estarem actualizadas, para reduzir superfície de ataque.

---

## Conclusão

Os riscos mais graves estão no **backend Go**: validação HMAC de webhook quebrada, credenciais e segredos default hardcoded. No **backend Python**, o maior problema é a **falta de liveness real** e o **CORS permissivo com credenciais**. Em ambos, há segredos default versionados e gestão de erros deficiente em caminhos críticos.

### Recomendações imediatas

1. Corrigir a leitura do body em `generic_rest.go` antes de validar HMAC.
2. Remover todos os defaults de segredos e credenciais do código; exigir envs em todos os ambientes.
3. Exigir desafio de liveness real ou desativar verificação facial puramente heurística.
4. Adicionar rate-limit e bloqueio por tentativas no PIN.
5. Fechar corretamente recursos (DB, rows) em todos os caminhos de erro.
6. Tratar e logar erros de `Exec`/`Query` em vez de ignorá-los.
7. Remover informação sensível dos logs.
8. Usar Redis (ou equivalente) para estado de liveness/cache em ambientes multi-réplica.

---

*Actualizado em: 2026-08-03 — adicionada análise da migração multipart + MinIO*
