# Lacunas de Implementação do Serviço Biométrico — Sistema de Gestão de Assiduidade

## 1. Controlo do documento

| Campo | Valor |
| --- | --- |
| Referência | LAC-ASS-001 |
| Versão | 0.1 |
| Data | 25/09/2026 |
| Estado | Rascunho para validação |
| Responsáveis | Equipa técnica, com validação de segurança e do responsável de dados — nomes a designar |
| Base documental | Documentos 01 a 36; [Análise de Consistência](37-Analise-de-Consistencia.md); código Python do serviço biométrico (este repositório, pasta `app/`) |

## 2. Objectivo, âmbito e convenções

Este documento compara o que a série documental exige ao serviço biométrico com o que o código Python implementa em 25/09/2026, e lista o que falta.

**Âmbito.** O serviço biométrico realiza o componente CMP-07 (Gestão biométrica), o armazenamento CNT-09 e parte de CMP-05 (chaves de dispositivo), sendo o EXT-04 da [Arquitectura](07-Arquitectura-do-Sistema.md). Pedidos e aprovações, apuramento, períodos e fecho, relatórios e envio de resultados ao ERP (CMP-08 a CMP-12) pertencem ao Nexora ERP e **não** são lacunas deste serviço.

**Método.** Leitura do código; os testes não foram executados. As referências a ficheiros são relativas à raiz do repositório.

Convenções:

- **LAC-xx** identifica lacunas. Identificadores estáveis.
- **Prioridade:** `Alta` — viola requisito essencial de segurança, privacidade ou integridade; `Média` — requisito essencial parcialmente cumprido ou risco operacional; `Baixa` — requisito desejável, arrumação ou decisão pendente.

## 3. Síntese

| Indicador | Valor |
| --- | --- |
| Lacunas | 22 (7 de prioridade alta, 11 média, 4 baixa) |
| Requisitos BIO sem cumprimento | BIO-01, BIO-02, BIO-05, BIO-10, BIO-13, BIO-15, BIO-19, BIO-20 a BIO-24, BIO-31, BIO-32 |
| Endpoints do [documento 10](10-Especificacao-de-APIs.md) sem equivalente | EP-037 (habilitação), EP-039 (operações sobre referência), EP-040 (estado da referência), EP-042 (configuração do limiar) |
| Controlos já cumpridos | 13 (secção 6) |

## 4. Lacunas

### 4.1. Prioridade alta

| ID | Requisito | Situação no código | Onde | Correcção proposta |
| --- | --- | --- | --- | --- |
| LAC-01 | BIO-01, RF-061, RN-043 — habilitação e consentimento antes do enrollment | O enrollment não verifica habilitação nem consentimento. `erp_client.validar_consentimento_ativo()` existe mas não é chamada; `face_templates.consent_version` nunca é preenchido | `app/routers/biometric.py` (`_perform_enrollment`), `app/erp_client.py` | Chamar a verificação antes da captura, recusar sem consentimento activo e gravar a versão em `consent_version` |
| LAC-02 | RF-036, BIO-02, BIO-20 a BIO-24, EP-039 — suspender, revogar e eliminar referência facial | Não existe endpoint. Os estados `REVOKED` e `DELETED` estão definidos mas nunca são atribuídos; `revoked_at` nunca é preenchido | `app/schemas/common.py`, `app/routers/admin.py` | Endpoint de operações sobre a referência com motivo, auditoria e evento no outbox para o ERP |
| LAC-03 | BIO-10, RN-045 — substituição ligada à referência anterior | Um novo enrollment facial cria um segundo template `ACTIVE` sem desactivar o anterior; o verify escolhe um deles de forma indeterminada (`db.scalar`). Na impressão digital, o template anterior é sobrescrito | `app/routers/biometric.py` (`_perform_enrollment`, `verify_biometric`), `app/routers/fingerprint.py` | Na mesma transacção, passar o anterior a substituído e guardar a ligação; restrição de um único `ACTIVE` por utilizador e tenant |
| LAC-04 | BIO-05, SDF-05, PERM-15 — enrollment só por operador autorizado, nunca de si próprio | `require_self_or_manager` permite ao colaborador fazer enrollment de si mesmo | `app/deps.py`, `app/routers/biometric.py` | Exigir papel de operador no enrollment e recusar quando o actor é o próprio colaborador |
| LAC-05 | BIO-15, RF-037, PD-05; [12 §7](12-Reconhecimento-Facial-e-Liveness.md) — sem pontuações brutas; não revelar o controlo que falhou | `biometric_audit_logs` guarda `confidence_score` e `liveness_score`; as respostas de verify, identify e liveness devolvem as pontuações e o motivo `liveness_failed` ao cliente | `app/services/audit_log.py`, `app/routers/biometric.py`, `app/routers/liveness.py`, `app/routers/admin.py` (`audit-logs`) | Registar só o resultado categórico (`sucesso`, `sem_correspondencia`, `prova_vida_falhada`, `qualidade_insuficiente`, `componente_indisponivel`); devolver ao cliente uma falha genérica |
| LAC-06 | SEG-10, SEG-14, BIO-31, AM-03 — segurança da imagem recebida | Com `image_url`, o servidor descarrega qualquer URL, sem lista de origens permitidas (risco de pedido forjado do lado do servidor). A assinatura Ed25519 cobre o texto do URL, não o conteúdo, pelo que a imagem pode ser trocada. A mesma imagem é descarregada até três vezes por pedido. `image_url` pressupõe imagens guardadas noutro sistema | `app/services/biometric.py` (`_download_image`, `_resolve_image_bytes`), `app/routers/biometric.py` (`_validate_image_signature`) | Lista de origens permitidas ou remoção de `image_url`; assinar o hash do conteúdo; descarregar uma vez por pedido |
| LAC-07 | RF-060, EVA-11, EVA-15, EVA-16, AUD-01 — auditoria de operações críticas | Nenhum evento de auditoria em `force-re-enroll`, `re-encrypt`, registo e revogação de chave de dispositivo, `export-templates`, `batch-enroll` e em todas as operações de impressão digital (enroll, identify, delete) | `app/routers/admin.py`, `app/routers/fingerprint.py` | Registar evento com actor, tenant, objecto, motivo e resultado em cada uma destas operações |

### 4.2. Prioridade média

| ID | Requisito | Situação no código | Onde | Correcção proposta |
| --- | --- | --- | --- | --- |
| LAC-08 | RF-035, BIO-12, BIO-13, EP-042 — limiar configurável, dentro do intervalo aprovado e versionado | Os limiares só são definidos por variáveis de ambiente, globais e sem versão; `calibrate-threshold` calcula mas não aplica; a auditoria não regista a versão do modelo nem da configuração usada | `app/config.py`, `app/routers/admin.py` | Configuração por tenant com intervalo aprovado, versão e auditoria (EVA-16); versão do modelo em cada tentativa |
| LAC-09 | MEC-02, PD-06, RNF-009 — idempotência das escritas | Nenhum endpoint aceita `Idempotency-Key`; repetir um enrollment cria outro template (agrava LAC-03) | `app/routers/*.py` | Chave de idempotência nas escritas, com hash do pedido e resposta guardada |
| LAC-10 | BIO-17, BIO-19 — impressão digital com as mesmas regras da facial | Sem verificação de qualidade nem anti-spoofing; não valida se o método está activo para o tenant; não regista actividade suspeita; a identificação decifra todos os templates do tenant em memória | `app/routers/fingerprint.py`, `app/services/fingerprint_matching.py` | Aplicar a validação de método, qualidade, actividade suspeita e auditoria; avaliar limite de volume para a comparação 1:N |
| LAC-11 | RF-062, RN-047, BIO-22 — eliminação com evidência | `DELETE /fingerprint/enroll/{user_id}` apaga fisicamente o registo, sem motivo, auditoria nem aviso ao ERP | `app/routers/fingerprint.py` | Eliminação com motivo, estado intermédio, auditoria e evento no outbox |
| LAC-12 | SEG-16, MEC-12 — erros sem detalhes internos | `identify` devolve o texto da excepção ao cliente (`Erro na busca por similaridade: {exc}`) | `app/routers/biometric.py` | Mensagem normalizada; detalhe apenas no log técnico |
| LAC-13 | RF-032, BIO-03, PERM-11 — validação do método e da actividade suspeita no 1:N | `identify` não chama `validar_metodo_assiduidade` nem regista falhas para actividade suspeita, ao contrário de `verify` | `app/routers/biometric.py` | Aplicar as mesmas verificações de `verify` |
| LAC-14 | [13 §3](13-Gestao-Multi-Tenant.md), TEN-01, TEN-07 — tenant obrigatório em cada referência | `tenant_id` é opcional em `face_templates`, `fingerprint_templates`, `device_public_keys` e `biometric_audit_logs` | `app/models.py` | Tornar a coluna obrigatória após migração dos registos existentes |
| LAC-15 | TEN-01, RF-032 — configuração de métodos por tenant | A configuração de métodos obtida do ERP fica numa cache global de 60 s, sem chave de tenant; **a confirmar** se corresponde ao tenant do actor. Com o ERP indisponível, a validação deixa passar | `app/services/attendance_validation.py`, `app/erp_client.py` (`get_attendance_config`) | Cache por tenant; decidir e documentar a política de falha (aberta ou fechada) |
| LAC-16 | DSP-28, SEG-08, RF-019 — revogação efectiva da credencial de dispositivo | Registar de novo a chave de um dispositivo revogado reactiva-a sem registo nem motivo. `REQUIRE_IMAGE_SIGNATURE` é `false` por defeito | `app/services/device_registry.py`, `app/config.py` | Reactivação só por operação própria, auditada; assinatura obrigatória em produção |
| LAC-17 | BIO-11, RNF-023, BIO-25 a BIO-28 — prova de vida ensaiada | O modelo por defeito é a heurística de textura, frequência e cor; o modelo ONNX exige um ficheiro não incluído. Não existe relatório de ensaio FAR/FRR/APCER com amostra aprovada | `app/services/liveness_models.py`, `app/config.py` | Ensaio segundo DN-05 antes do piloto; modelo aprovado registado na configuração |
| LAC-18 | AUD-05, AUD-06, RNF-025 — auditoria protegida | `biometric_audit_logs` não é só de acrescento nem tem encadeamento de hash | `app/models.py` | Restrição de escrita na base e encadeamento por tenant (DT-07) |

### 4.3. Prioridade baixa

| ID | Requisito | Situação no código | Onde | Correcção proposta |
| --- | --- | --- | --- | --- |
| LAC-19 | RF-062, CMP-13, CR-04, CR-05 — retenção | Não há tarefa de retenção ou expurgo para auditoria biométrica nem para templates revogados | — | Tarefa periódica segundo as categorias do [Modelo de Dados §8.4](09-Modelo-de-Dados.md), após DF-08 |
| LAC-20 | BIO-32, EVA-21, RN-046 — exportação | `export-templates` exporta templates cifrados sem finalidade nem auditoria | `app/routers/admin.py` | Exigir finalidade e registar a exportação |
| LAC-21 | SEG-15, RNF-015 — configuração segura por defeito | `CORS_ORIGINS` é `*` por defeito | `app/main.py` | Lista explícita de origens em produção |
| LAC-22 | MEC-11, EP-028, DF-04 — propagação aos terminais | Não existe, e não é necessária enquanto o reconhecimento for central (sem templates nos terminais) | — | Registar formalmente a escolha da opção B (central) em DF-04 |

## 5. Divergências de modelo a resolver

| Tema | Documentação | Código | Decisão necessária |
| --- | --- | --- | --- |
| Estados da referência biométrica | `em_preparacao`, `activo`, `suspenso`, `substituido`, `eliminacao_pendente`, `eliminado` ([12 §9](12-Reconhecimento-Facial-e-Liveness.md), DG-ES-06) | `ACTIVE`, `REVOKED`, `DELETED`, `PENDING_REENROLL` | Alinhar o enumerado ou actualizar DG-ES-06; `PENDING_REENROLL` (mudança de modelo) não existe na documentação |
| Nomes e contratos | `/api/v1` com recursos em português (DT-12, [documento 10](10-Especificacao-de-APIs.md)) | `/api/v1` com recursos em inglês | DT-01 e DT-12 |
| Registo de tentativas | Entidade `tentativa_identificacao` sem pontuações ([09 §5.3](09-Modelo-de-Dados.md)) | `biometric_audit_logs` mistura tentativas e auditoria, com pontuações | Separar tentativas de auditoria ou ajustar ENT-22 e ENT-45 |
| Habilitação | Entidade própria `habilitacao_biometrica` (ENT-23) no serviço | Consentimento mantido no ERP (`lgpd.consentimentos`) e consultado por HTTP | Confirmar o ERP como proprietário e documentar a consulta |

## 6. Requisitos já cumpridos

| Requisito | Implementação |
| --- | --- |
| RNF-016, SEG-03, SEG-04 — cifragem em repouso com chave própria | AES-GCM com conjunto de chaves e identificador de chave activa (`app/security/encryption.py`) |
| SEG-05 — rotação de chaves | `POST /admin/biometric/re-encrypt` |
| PD-05, BIO-30 — protecção do template | Transformação cancelável (`app/security/cancelable_transform.py`); vector de pesquisa só guardado com a transformação activa |
| BIO-14, TEN §5 — 1:N limitado ao tenant | Pesquisa pgvector filtrada por `tenant_id`, estado e versão do modelo |
| BIO-11 — prova de vida por desafio | `/liveness/challenge` e `/liveness/verify` com protecção contra repetição (`app/services/challenge_store.py`) e continuidade de identidade |
| BIO-07 — qualidade mínima por captura | Avaliação de qualidade e mínimo de três capturas válidas no enrollment |
| BIO-28 — mudança de modelo | Verificação da versão do modelo; template passa a `PENDING_REENROLL` |
| MEC-08, DT-03 — outbox transaccional | `outbox_events` com chave de deduplicação e worker (`app/workers/outbox.py`) |
| DT-05, SEG-08 — credencial por dispositivo | Chaves Ed25519 registadas e revogáveis (`device_public_keys`) |
| ACT-03, SEG-09 — credencial de integração por tenant | Credenciais HMAC com permissões, expiração e revogação (`api_credentials`) |
| RNF-005, SEG-11 — limites de utilização | Limites por minuto e por hora (`slowapi`) |
| MEC-12, AUD-17 — correlação | `x-request-id` gerado ou propagado e registado em logs estruturados |
| RNF-027, RF-063 — observabilidade | `/health`, `/ready`, `/metrics` e painel com FAR, FRR, APCER e BPCER |

## 7. Ordem de correcção proposta

| Passo | Lacunas | Justificação |
| --- | --- | --- |
| 1 | LAC-03, LAC-09 | Corrigem um comportamento incorrecto actual (templates activos em duplicado) |
| 2 | LAC-01, LAC-04 | Condições prévias ao tratamento biométrico no piloto |
| 3 | LAC-05, LAC-06, LAC-12 | Exposição de dados e superfície de ataque |
| 4 | LAC-07, LAC-18 | Evidência das operações críticas |
| 5 | LAC-02, LAC-11 e estados da secção 5 | Ciclo de vida completo da referência |
| 6 | LAC-08, LAC-10, LAC-13 a LAC-16 | Configuração, impressão digital e isolamento |
| 7 | LAC-17 | Ensaio biométrico antes da entrada em produção |
| 8 | LAC-19 a LAC-22 | Retenção, exportação e configuração por defeito |

## 8. Rastreabilidade

| Lacunas | Requisitos | Documentos |
| --- | --- | --- |
| LAC-01, LAC-04 | RF-033, RF-061; RN-043; BIO-01, BIO-05; SDF-05 | [05](05-Casos-de-Uso.md) UC-04, [12](12-Reconhecimento-Facial-e-Liveness.md), [14](14-Gestao-de-Utilizadores-e-Perfis.md), [15](15-Matriz-de-Permissoes-e-Acessos.md) |
| LAC-02, LAC-03, LAC-11 | RF-036, RF-062; RN-045, RN-047; BIO-10, BIO-20 a BIO-24 | [05](05-Casos-de-Uso.md) UC-12, [06](06-Diagramas-UML.md) DG-ES-06, [09](09-Modelo-de-Dados.md), [12](12-Reconhecimento-Facial-e-Liveness.md) |
| LAC-05, LAC-06, LAC-12 | RF-037; BIO-15, BIO-31; SEG-10, SEG-14, SEG-16 | [12](12-Reconhecimento-Facial-e-Liveness.md), [17](17-Seguranca-e-Proteccao-de-Dados.md) |
| LAC-07, LAC-18, LAC-20 | RF-060; EVA-11, EVA-15, EVA-16, EVA-21; AUD-01, AUD-05, AUD-06 | [16](16-Auditoria-e-Logs.md) |
| LAC-08, LAC-17 | RF-034, RF-035; RNF-023; BIO-11 a BIO-13, BIO-25 a BIO-28 | [03](03-Requisitos-Nao-Funcionais.md), [12](12-Reconhecimento-Facial-e-Liveness.md) |
| LAC-09 | RNF-009; MEC-02 | [08](08-Documento-de-Design-Tecnico-TDD.md) |
| LAC-10, LAC-13 | RF-030, RF-032; BIO-03, BIO-17, BIO-19 | [11](11-Especificacao-de-Dispositivos-Terminais.md), [12](12-Reconhecimento-Facial-e-Liveness.md) |
| LAC-14, LAC-15 | RF-002; TEN-01, TEN-07 | [13](13-Gestao-Multi-Tenant.md) |
| LAC-16, LAC-21 | RF-019; DSP-28; SEG-08, SEG-15 | [11](11-Especificacao-de-Dispositivos-Terminais.md), [17](17-Seguranca-e-Proteccao-de-Dados.md) |
| LAC-19, LAC-22 | RF-036, RF-062; MEC-11 | [08](08-Documento-de-Design-Tecnico-TDD.md), [09](09-Modelo-de-Dados.md) |

## 9. Aprovação e referências

A equipa técnica valida as lacunas e a ordem de correcção; segurança valida LAC-05, LAC-06, LAC-12, LAC-16 e LAC-21; o responsável de dados valida LAC-01, LAC-02, LAC-05, LAC-11, LAC-19 e LAC-20. Cada aprovação deve identificar nome, versão e data. Estado de aprovação desta versão: **pendente**.

- [Índice da documentação](README.MD).
- [Análise de Consistência da Documentação](37-Analise-de-Consistencia.md), em especial ACH-03 e ACH-31 a ACH-38.
