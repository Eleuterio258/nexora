# Análise de Consistência da Documentação — Sistema de Gestão de Assiduidade

## 1. Controlo do documento

| Campo | Valor |
| --- | --- |
| Referência | ACD-ASS-001 |
| Versão | 0.1 |
| Data | 25/09/2026 |
| Estado | Rascunho para validação |
| Responsáveis | Equipa técnica, com validação dos proprietários de cada documento analisado — nomes a designar |
| Base documental | Documentos 01 a 36 e [índice](README.MD); código do serviço biométrico (este repositório) e da aplicação Android `nexora_assiduidade` |

## 2. Objectivo, âmbito e convenções

Este documento regista o resultado da revisão, documento a documento, da série 01 a 36: pontos fortes, inconsistências internas, inconsistências entre documentos, referências quebradas e divergências entre a especificação e o código existente. Não altera nenhum requisito; cada achado indica o documento que deve ser corrigido.

Convenções:

- **ACH-xx** identifica achados. Identificadores estáveis.
- **Tipo:** `Interno` (contradição dentro do mesmo documento), `Entre documentos`, `Referência` (ligação ou identificador inexistente), `Código` (divergência entre especificação e implementação), `Lacuna` (conteúdo em falta).
- **Gravidade:** `Alta` — impede a aprovação ou induz implementação errada; `Média` — gera ambiguidade que tem de ser resolvida antes da baseline; `Baixa` — redacção, notação ou arrumação.
- Situação observada em 25/09/2026. As afirmações sobre código indicam o ficheiro verificado.

## 3. Síntese

| Indicador | Valor |
| --- | --- |
| Documentos analisados | 36 e o índice |
| Documentos detalhados | 21 (01 a 19, 36 e índice) |
| Documentos-esqueleto | 16 (20 a 35) |
| Achados | 40 (12 de gravidade alta, 19 média, 9 baixa) |
| Referências quebradas | 17 ligações, para 3 ficheiros inexistentes no caminho indicado |

Conclusões principais:

1. Os documentos 01 a 19 e 36 têm qualidade elevada: identificadores estáveis, critérios de aceitação verificáveis e rastreabilidade consistente. Não foi encontrado nenhum código DF, DN, DT ou PN referido sem definição.
2. **O ciclo "corrigir na origem" não foi fechado.** Os documentos 06, 09, 14 e 19 pedem alterações a 02 §6, 05 §3 e 06, que permanecem na versão 0.1 sem essas alterações.
3. **O BRD detalhado não existe**, mas sustenta a rastreabilidade de 02, 03 e 04 e referências em 12, 13, 16 e 17.
4. **O serviço biométrico existente (FaceClock, este repositório) não é mencionado.** Todas as secções "Situação actual" observam apenas o Nexora ERP, embora várias decisões pendentes já estejam, na prática, implementadas neste serviço.
5. Os documentos 20 a 35 são esqueletos sem identificadores nem rastreabilidade, e alguns contradizem os documentos detalhados.

## 4. Achados transversais

| ID | Tipo | Gravidade | Achado | Documentos a corrigir |
| --- | --- | --- | --- | --- |
| ACH-01 | Referência | Alta | `BRD_Sistema_Gestao_Assiduidade.md` (BRD detalhado) não existe. É referido 20 vezes e é a origem de BR-F-xxx, BR-NF-xxx, BR-RN-xxx e das metas 99,5 % / 60 s / 30 s | README, 02 §8, 03 §3.2 e §7, 04 §8, 12 §2, 13, 16, 17 §6.1 |
| ACH-02 | Referência | Média | As ligações `../endpoints_assiduidade_erp.md` e `../nexora_assiduidade/README.md` pressupõem que a pasta está em `factPro/`; está em `factPro/assiduidade_system_backend/`. 17 ligações quebradas | README, 01, 02, 06, 07, 09, 10, 11, 15 — ou mover a pasta |
| ACH-03 | Lacuna | Alta | O serviço biométrico existente não aparece em nenhum documento. Já implementa enrollment e verificação 1:1 e 1:N (`/api/v1/biometric/*`), liveness por desafio (`/api/v1/liveness/*`), impressão digital (`/api/v1/fingerprint/*`), chaves Ed25519 por dispositivo (`/api/v1/admin/devices/*`), credenciais HMAC por tenant, outbox transaccional e auditoria biométrica local | 07 §13, 09 §9, 10 §9, 12 §13, 16 §10, 17 §11, 18 §10 |
| ACH-04 | Entre documentos | Alta | Os pedidos de correcção na origem (DU-01 a DU-07, 09 §6.1, 14 §4 e §6, 19 §6) não foram aplicados: 02 §3 e §6 e 05 §3 continuam sem PRF-09, PRF-10, estado de conflito, devolução/desistência, estados de tenant/dispositivo/conta | 02, 05, 06 |
| ACH-05 | Entre documentos | Alta | Dois contratos `/api/v1` incompatíveis: o proposto em 10 (recursos em português, DT-12) e o já publicado pelo serviço biométrico (recursos em inglês) | 08 DT-12, 10 §2 e §9 |
| ACH-06 | Lacuna | Média | A pasta não está sob controlo de versões (`git status` indica `??`) | — |
| ACH-07 | Entre documentos | Baixa | Versões desalinhadas: 02 a 06 e 36 em 0.1; restantes detalhados em 0.2 com histórico de alterações; 02 a 06 sem tabela de histórico | 02 a 06, 36 |

## 5. Análise por documento

### 5.1. Negócio e requisitos

#### 01 — BRD resumido

**Pontos fortes:** objectivos com indicador, âmbito incluído e excluído, 16 requisitos BR com evidência de aceitação, riscos e decisões DEC.

| ID | Tipo | Gravidade | Achado |
| --- | --- | --- | --- |
| ACH-08 | Entre documentos | Média | §5.1 lista "marcação com localização" como método alternativo; 11 §7 define a localização como contexto e não como método |
| ACH-09 | Entre documentos | Média | BR-05 (métodos alternativos) é "Desejável"; segundo 02 §2, o BRD detalhado exige-os. Divergência remetida para DF-01 sem resolução |
| ACH-10 | Entre documentos | Baixa | O glossário (§16) sobrepõe-se ao documento 34 |

#### 02 — Requisitos Funcionais

**Pontos fortes:** 65 RF com actor, prioridade e critério de aceitação testável; estados e transições; cenários CA-01 a CA-09.

| ID | Tipo | Gravidade | Achado |
| --- | --- | --- | --- |
| ACH-11 | Entre documentos | Alta | §6 sem estado de conflito para o evento central (DU-02), sem devolução/desistência (DU-03) e sem estados de tenant, dispositivo e conta (DU-07) — ver ACH-04 |
| ACH-12 | Entre documentos | Média | §3 sem os actores Administrador de integração (PRF-09) e Responsável de dados (PRF-10) |
| ACH-13 | Interno | Baixa | §10 anuncia como "próximos documentos" documentos que já existem |

#### 03 — Requisitos Não Funcionais

**Pontos fortes:** fórmula de disponibilidade, definição de P95, separação entre erros técnicos e rejeições de negócio, classes de recuperação, regra de que parâmetro sem valor não equivale a aprovação.

| ID | Tipo | Gravidade | Achado |
| --- | --- | --- | --- |
| ACH-14 | Referência | Média | As únicas metas quantitativas (§3.2) têm origem no BRD detalhado inexistente (ACH-01) |
| ACH-15 | Entre documentos | Média | As classes de recuperação do §6 (dados centrais, identidades, auditoria, biométricos, integrações, terminal) diferem das do documento 24 (crítica, operacional, relatórios, integração); 07 §10 segue o 03 |

#### 04 — Regras de Negócio

**Pontos fortes:** tabela de recepção com ordem normativa; fórmula `T_observado = duração(P) − duração(P ∩ B)` sem dupla contagem; "indeterminado nunca é zero"; exemplos EX-01 a EX-10 verificados (EX-01: 8 h de presença e 7 h 30 líquidas; EX-02: 8 h).

| ID | Tipo | Gravidade | Achado |
| --- | --- | --- | --- |
| ACH-16 | Lacuna | Média | Os 12 parâmetros PN estão pendentes; nenhuma regra de cálculo é executável. O documento não refere o motor de regras de assiduidade já existente no ERP, que deve ser inventariado como situação actual |

#### 05 — Casos de Uso

**Pontos fortes:** 21 casos com fluxo, alternativas, pós-condição, garantia em falha e aceitação; índice de cobertura dos 65 RF.

| ID | Tipo | Gravidade | Achado |
| --- | --- | --- | --- |
| ACH-17 | Lacuna | Alta | Não existe caso de uso para o enrollment de impressão digital. RF-030 aponta para UC-01 e UC-04, mas UC-04 é "enrollment facial"; BIO-17 exige enrollment e ciclo de vida para a impressão digital |
| ACH-18 | Entre documentos | Média | UC-04 passo 6 activa o template directamente; BIO-08 e EP-038 exigem conclusão explícita |

#### 06 — Diagramas UML

**Pontos fortes:** 33 diagramas coerentes com 02 a 05; secção 12 regista as lacunas encontradas na modelação.

| ID | Tipo | Gravidade | Achado |
| --- | --- | --- | --- |
| ACH-19 | Entre documentos | Alta | DG-ES-02: a transição `Recebido → Duplicado` com a legenda "mesmo identificador, conteúdo equivalente" contradiz 09 §6.1, 10 §6.1 e 19 §6 — um reenvio não cria evento; `duplicado` aplica-se só a eventos distintos |
| ACH-20 | Entre documentos | Alta | DG-SQ-03 recusa a submissão de correcção em período fechado; UC-02, FP-05 e EP-049 permitem submeter e decidir, adiando só a aplicação do ajuste |
| ACH-21 | Código | Baixa | DG-UC-01, DG-CP-01 e DG-DP-01 marcam o serviço biométrico como "se adoptado" (ver ACH-03) |

### 5.2. Arquitectura e desenho técnico

#### 07 — Arquitectura do Sistema

**Pontos fortes:** vistas C4, 16 componentes com proprietário único dos dados, dependências sem ciclos, eventos de domínio EVD, fronteiras de confiança FC, ordem de recuperação.

| ID | Tipo | Gravidade | Achado |
| --- | --- | --- | --- |
| ACH-22 | Código | Alta | O §13 não inclui o serviço biométrico, que na prática realiza CNT-09 (tabela `face_templates` com pgvector) e EXT-04, com outbox, auditoria e credenciais próprios |

#### 08 — Documento de Design Técnico

**Pontos fortes:** princípios PD-01 a PD-09 e mecanismos MEC-01 a MEC-13 bem especificados; registo de decisões DT com proposta; riscos RT.

| ID | Tipo | Gravidade | Achado |
| --- | --- | --- | --- |
| ACH-23 | Referência | Baixa | PD-01 cita "RN-006 (BRD)", ambíguo com a RN-006 do documento 04 (horários); deve ser BR-RN-006 |
| ACH-24 | Interno | Baixa | DT-12 propõe nomes em português, mas o envelope de MEC-08 usa nomes em inglês (`message_id`, `occurred_at`, `schema_version`) |
| ACH-25 | Código | Média | Decisões apresentadas como pendentes já têm implementação no serviço biométrico: DT-03 (outbox em PostgreSQL com worker — `app/models.py`, `OutboxEvent`), DT-05 (chave Ed25519 por dispositivo, revogável — `DevicePublicKey`), DT-10 (keyring e fornecedor de chaves biométricas — `app/config.py`). RT-02 está parcialmente mitigado |

#### 09 — Modelo de Dados

**Pontos fortes:** 50 entidades, dicionário das críticas, RI-01 a RI-14 implementáveis, índices, particionamento, categorias de retenção, lacunas concretas do esquema `rh`.

| ID | Tipo | Gravidade | Achado |
| --- | --- | --- | --- |
| ACH-26 | Interno | Média | `apuramento.estado` inclui `fechado` e `substituido`, o que obriga a actualizar versões que PD-04 e RI-14 tornam imutáveis. A versão actual deve ser derivada (como em ALG-11 do documento 36) e o fecho registado em `fecho`/`FechoApur` |
| ACH-27 | Código | Média | §9 associa os templates faciais a `rh.facial_verification_uses`; os templates estão em `face_templates` no serviço biométrico. As tabelas `face_templates`, `fingerprint_templates`, `device_public_keys`, `api_credentials`, `outbox_events` e `biometric_audit_logs` não estão mapeadas para ENT-25, ENT-17, ENT-50 e ENT-45 |

#### 10 — Especificação de APIs

**Pontos fortes:** 79 endpoints com permissão e RF; semântica das respostas de marcação (201, 200 com `Idempotent-Replay`, 409); lote com resposta por item; catálogo de erros e códigos de motivo; reconciliação com o ERP.

| ID | Tipo | Gravidade | Achado |
| --- | --- | --- | --- |
| ACH-28 | Código | Média | EP-041 é condicional a DF-04, mas já existe como `/api/v1/biometric/verify` e `/api/v1/biometric/identify`. Não há equivalente no catálogo para `/api/v1/liveness/challenge` e `/api/v1/liveness/verify`, para o enrollment de impressão digital nem para o registo e revogação de chaves de dispositivo |

#### 11 — Especificação de Dispositivos/Terminais

**Pontos fortes:** 33 requisitos DSP, estrutura da fila offline, correcção fundamentada de DSP-14. As observações do §13 foram confirmadas: `android:usesCleartextTraffic="true"` em `nexora_assiduidade/app/src/main/AndroidManifest.xml` e `minSdk = 24`.

| ID | Tipo | Gravidade | Achado |
| --- | --- | --- | --- |
| ACH-29 | Código | Baixa | §13 não refere que a aplicação já usa chaves Ed25519 e tem ecrã de desafio de liveness |
| ACH-30 | Referência | Baixa | §10 remete ecrãs e textos para o documento 20, que não os contém |

#### 12 — Reconhecimento Facial e Liveness

**Pontos fortes:** opções de processamento A a D, habilitação distinta de consentimento, eliminação só após confirmação de todos os destinos, métricas FAR/FRR e APCER/BPCER.

| ID | Tipo | Gravidade | Achado |
| --- | --- | --- | --- |
| ACH-31 | Código | Alta | BIO-15 proíbe pontuações brutas nos registos de tentativa; `biometric_audit_logs` guarda `confidence_score` e `liveness_score` (`app/models.py`, `BiometricAuditLog`) |
| ACH-32 | Código | Alta | Ciclo de vida divergente: o código usa `ACTIVE`, `REVOKED`, `DELETED`, `PENDING_REENROLL` (`app/schemas/common.py`); o §9 exige `em_preparacao`, `activo`, `suspenso`, `substituido`, `eliminacao_pendente`, `eliminado` |
| ACH-33 | Código | Média | BIO-10 exige ligar a nova referência à anterior; o re-enroll de impressão digital sobrescreve o template existente (`app/routers/fingerprint.py`) |
| ACH-34 | Lacuna | Média | §13 pede o inventário do pipeline; os dados já estão em `app/config.py`: modelo `facenet`, limiares de correspondência 0.85, liveness 0.68, qualidade 0.55, continuidade 0.75, liveness `heuristic` por defeito |

#### 13 — Gestão Multi-Tenant

**Pontos fortes:** isolamento em 12 superfícies, falha fechada sem contexto, resposta "não encontrado" sem diferença de tempo, equidade de recursos.

| ID | Tipo | Gravidade | Achado |
| --- | --- | --- | --- |
| ACH-35 | Código | Média | `tenant_id` é opcional em `face_templates`, `fingerprint_templates`, `device_public_keys` e `biometric_audit_logs`, contra §3 ("tenant em cada referência"). §11 também deixa por verificar Row-Level Security e a resolução do tenant por chave de API |

#### 14 — Gestão de Utilizadores e Perfis

**Pontos fortes:** perfis PRF-01 a PRF-10, actores técnicos, segregação de funções SDF, estados da conta, segundo factor para perfis privilegiados.

Achados: ACH-04 e ACH-12 (alterações pedidas ao 02 e 05 não aplicadas). Sem achados próprios.

#### 15 — Matriz de Permissões e Acessos

**Pontos fortes:** 35 permissões, legenda sem ambiguidade, condições por célula, correspondência com as permissões actuais do ERP.

| ID | Tipo | Gravidade | Achado |
| --- | --- | --- | --- |
| ACH-36 | Interno | Baixa | §5 declara PERM-17 e PERM-20 disponíveis a "todos" os perfis que sejam colaboradores, mas a coluna PRF-01 tem "—". PERM-11 está omitida da matriz sem nota na tabela |

#### 16 — Auditoria e Logs

**Pontos fortes:** catálogo EVA-01 a EVA-28, separação entre auditoria, logs e telemetria, bloqueio perante falha de auditoria, logs por lista de campos permitidos.

| ID | Tipo | Gravidade | Achado |
| --- | --- | --- | --- |
| ACH-37 | Código | Média | `biometric_audit_logs` não é append-only nem encadeado por hash (AUD-05, AUD-06) e contém pontuações (ver ACH-31) |

#### 17 — Segurança e Protecção de Dados

**Pontos fortes:** classes de informação, controlos SEG-01 a SEG-33, modelo de ameaças, restauro seguro, anexos de saúde como pessoais sensíveis.

Achados: ACH-01 (jurisdição remetida para o BRD detalhado inexistente; a lei aplicável em Moçambique não é identificada) e ACH-03 (controlos já existentes no serviço biométrico — templates canceláveis, assinatura de imagem, rotação de chaves — não inventariados).

#### 18 — Integrações com Sistemas Externos

**Pontos fortes:** modelo de contrato, "transferência não é aplicação", reconciliação em quatro níveis, revisões após reabertura.

| ID | Tipo | Gravidade | Achado |
| --- | --- | --- | --- |
| ACH-38 | Lacuna | Alta | A integração entre o serviço biométrico e o ERP não está documentada, embora exista (`app/erp_client.py`, `app/erp_proxy.py`, outbox para o ERP, credenciais HMAC por tenant). §5 trata o serviço biométrico como hipotético |

#### 19 — Fluxos de Processos

**Pontos fortes:** 12 fluxos com componentes, endpoints e eventos; §6 já assinala ACH-19 e ACH-20.

| ID | Tipo | Gravidade | Achado |
| --- | --- | --- | --- |
| ACH-39 | Entre documentos | Média | FP-09 regista terminais e executa marcações de teste (passos 5 a 7) antes de activar o tenant (passo 8); TEN-08 determina que um tenant `criado` não aceita marcações |

#### 36 — Álgebra Relacional

**Pontos fortes:** expressões como oráculo de testes, restrições RIA que devem produzir o conjunto vazio, SQL equivalente, fecho transitivo por ponto fixo.

| ID | Tipo | Gravidade | Achado |
| --- | --- | --- | --- |
| ACH-40 | Interno | Média | ALG-14 projecta `π data_ref(Dia)` e perde o âmbito: com feriado local, um dia pode ser útil numa unidade e não noutra (RF-015). ALG-10 usa o estado actual do colaborador em vez do vínculo vigente na data da jornada. ALG-10 refere `EvJ.jornada`, não definido em ALG-05. O SQL de ALG-14 usa `presenca_dia` e `dias_uteis_q` sem os definir |

### 5.3. Documentos-esqueleto (20 a 35)

Padrão comum: 1,4 a 2,3 KB, "Autor: Manus AI", sem tabela de controlo, sem identificadores, sem rastreabilidade e com a mesma frase final genérica. O cabeçalho indica que "complementam os documentos 7 a 19", omitindo 01 a 06 e 36.

| Documento | Achado específico | Gravidade |
| --- | --- | --- |
| 20 Protótipos/UI/UX | Não contém os ecrãs e textos para que o 11 §10 remete | Média |
| 21 Plano de Testes | Não usa CA, EX, ALG nem RIA; ignora os testes existentes em `tests/` | Média |
| 22 Deployment | Diagrama com "Fila durável" separada, contra a proposta de DT-03 (outbox em PostgreSQL sem broker) | Baixa |
| 23 Escalabilidade | Particionamento "por tenant e período", contra 09 §8.3 (partição mensal, tenant como primeira coluna dos índices) | Baixa |
| 24 SLA | Classes de serviço diferentes das de 03 §6 e 07 §10 (ACH-15) | Média |
| 25 Manual Técnico | Componentes com nomes ("IAM", "workflow") diferentes de CMP-01 a CMP-16 | Baixa |
| 26 Manual do Utilizador | "Datas no fuso da organização", contra MEC-04 (fuso do contexto do evento) | Baixa |
| 27 Manual do Administrador | Atribui ao administrador do tenant a configuração de integrações e políticas, que a matriz 15 lhe nega (PERM-28 só PRF-09; PERM-07 só leitura para PRF-02); não inclui activação do tenant nem enrollment | Média |
| 28 Migração de Dados | Não refere a migração já executada de `rh.presencas` para `rh.eventos_assiduidade`, os dois modelos de correcção nem os templates do serviço biométrico | Média |
| 29 Implementação | Genérico; sem achados específicos | — |
| 30 Operação e Manutenção | Genérico; sem achados específicos | — |
| 31 Gestão de Incidentes | Coerente com 17 §9; sem achados específicos | — |
| 32 Versões e Change Management | Genérico; sem achados específicos | — |
| 33 RTM | Cobre 7 dos 16 BR; usa identificadores de teste (A-001, B-001, …) não definidos em nenhum documento | Alta |
| 34 Glossário | Termos em inglês; "Event sourcing" descreve um desenho não adoptado (versões persistidas); faltam Jornada, Ajuste, Ocorrência, Marcação, Enrollment e Outbox | Baixa |
| 35 Documentação para Parceiros | Genérico; sem achados específicos | — |

## 6. Plano de correcção proposto

| Prioridade | Acção | Achados | Documentos |
| --- | --- | --- | --- |
| 1 | Criar o BRD detalhado ou retirar as referências e reescrever a rastreabilidade para o BRD resumido | ACH-01, ACH-14 | README, 02, 03, 04, 12, 13, 16, 17 |
| 2 | Corrigir a localização da pasta ou as ligações relativas; colocar a pasta sob controlo de versões | ACH-02, ACH-06 | Todos |
| 3 | Aplicar na origem as correcções pendentes: estados em 02 §6, actores em 02 §3 e 05 §3, DG-ES-02 e DG-SQ-03 | ACH-04, ACH-11, ACH-12, ACH-19, ACH-20 | 02, 05, 06 |
| 4 | Acrescentar o serviço biométrico às secções "Situação actual" e reclassificar DF-04, DT-03, DT-05 e DT-10 | ACH-03, ACH-21, ACH-22, ACH-25, ACH-27 a ACH-29, ACH-34, ACH-38 | 06, 07, 08, 09, 10, 11, 12, 16, 17, 18 |
| 5 | Decidir DT-01 e DT-12, incluindo o prefixo e a língua dos contratos `/api/v1` | ACH-05, ACH-24 | 08, 10 |
| 6 | Corrigir o código do serviço biométrico ou registar excepção aprovada: pontuações na auditoria, estados do template, histórico no re-enroll de impressão digital, `tenant_id` obrigatório | ACH-31 a ACH-33, ACH-35, ACH-37 | Código; 12, 13, 16 |
| 7 | Corrigir as inconsistências internas do 09, 19 e 36 | ACH-26, ACH-39, ACH-40 | 09, 19, 36 |
| 8 | Acrescentar UC de enrollment de impressão digital e alinhar UC-04 com BIO-08 | ACH-17, ACH-18 | 05, 06 |
| 9 | Desenvolver os esqueletos 20 a 35 no formato da série, começando por 33 (RTM), 21 (Testes), 24 (SLA) e 28 (Migração) | §5.3 | 20 a 35 |

## 7. Rastreabilidade

| Achados | Documentos analisados | Requisitos, regras e identificadores afectados |
| --- | --- | --- |
| ACH-01, ACH-14 | 02, 03, 04, 12, 13, 16, 17 | BR-F, BR-NF, BR-RN; RNF-001 a RNF-006 |
| ACH-03, ACH-21, ACH-22, ACH-25, ACH-27 a ACH-29, ACH-34, ACH-38 | 06 a 12, 16 a 18 | DF-04, DT-03, DT-05, DT-10; EXT-04, CNT-09; EP-038 a EP-042; ENT-17, ENT-24, ENT-25, ENT-45, ENT-50 |
| ACH-04, ACH-11, ACH-12, ACH-19, ACH-20 | 02, 05, 06, 09, 14, 19 | DU-01 a DU-07; RF §6; UC-02; DG-ES-02, DG-SQ-03 |
| ACH-05, ACH-24 | 08, 10 | DT-01, DT-12; MEC-08 |
| ACH-17, ACH-18 | 05, 12 | RF-030, RF-033; BIO-08, BIO-17 |
| ACH-26, ACH-40 | 09, 36 | PD-04, RI-14; RF-015, RN-022; ALG-05, ALG-10, ALG-11, ALG-14 |
| ACH-31 a ACH-33, ACH-35, ACH-37 | 12, 13, 16 | BIO-10, BIO-15; §9 do 12; TEN §3; AUD-05, AUD-06 |
| ACH-39 | 13, 19 | TEN-08; FP-09 |

## 8. Aprovação e referências

Cada proprietário de documento valida os achados que lhe dizem respeito e indica, para cada um, se é aceite, rejeitado com motivo ou adiado. A equipa técnica valida os achados de tipo `Código`. Cada aprovação deve identificar nome, versão e data. Estado de aprovação desta versão: **pendente**.

- [Índice da documentação](README.MD).
- Código verificado: `../app/models.py`, `../app/config.py`, `../app/schemas/common.py`, `../app/routers/fingerprint.py`, `../app/main.py`; `nexora_assiduidade/app/src/main/AndroidManifest.xml` e `nexora_assiduidade/app/build.gradle.kts`.
