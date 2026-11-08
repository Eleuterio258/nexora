# Reconhecimento Facial e Liveness — Sistema de Gestão de Assiduidade

## 1. Controlo do documento

| Campo | Valor |
| --- | --- |
| Referência | BIO-ASS-001 |
| Versão | 0.3 |
| Data | 25/09/2026 |
| Estado | Rascunho técnico para validação |
| Responsáveis | Equipa técnica e responsável de dados, com validação de RH, segurança e negócio — nomes a designar |
| Base documental | RF-027, RF-032 a RF-037, RF-061, RF-062; RN-043 a RN-048; RNF-020 a RNF-024; UC-04, UC-12; DG-SQ-04, DG-SQ-07, DG-ES-06 |

| Versão | Data | Alteração |
| --- | --- | --- |
| 0.1 | 25/09/2026 | Enrollment, matching, anti-spoofing e propagação em resumo |
| 0.2 | 25/09/2026 | Versão detalhada: opções de processamento, habilitação, requisitos BIO, falhas, impressão digital, ciclo de vida alinhado com DG-ES-06, avaliação e protecção de dados |
| 0.3 | 25/09/2026 | Terminologia de autorização alinhada com permissões granulares `módulo:acção` e âmbito ([Requisitos Funcionais §3](02-Requisitos-Funcionais.md)) |

## 2. Objectivo, âmbito e convenções

Este documento especifica o tratamento biométrico usado para identificar colaboradores na marcação: habilitação, enrollment, comparação, prova de vida, anti-spoofing, ciclo de vida dos templates, avaliação de desempenho e protecção dos dados. Abrange a modalidade facial e a impressão digital, quando seleccionada (RF-030).

Convenções: **BIO-xx** identifica requisitos, com prioridade herdada do RF de origem. Nenhum limiar, taxa ou número de tentativas é fixado aqui: dependem de DF-04, DN-05 e PN-11.

Enquadramento: os dados biométricos são tratados como categoria de risco elevado. A base jurídica, a necessidade e proporcionalidade e o regime de consentimento aplicáveis na jurisdição de operação devem ser confirmados pelo responsável de dados antes do piloto (BRD detalhado §12, DF-08). Este documento não constitui avaliação jurídica.

## 3. Opções de processamento (DF-04)

| Opção | Onde ocorre a comparação | Vantagens | Riscos e exigências |
| --- | --- | --- | --- |
| A — No terminal | Aplicação Android, com templates distribuídos | Funciona offline; latência baixa | Templates em muitos destinos; propagação e eliminação por terminal (MEC-11); protecção local reforçada |
| B — Central | CMP-07, na plataforma | Templates num único local; eliminação simples | Sem marcação facial offline; latência de rede; disponibilidade central crítica |
| C — Fornecedor externo | EXT-04 | Algoritmo e prova de vida especializados | Transferência para terceiro, residência dos dados, contrato de retenção e eliminação |
| D — Híbrida | Terminal com fallback central | Resiliência | Complexidade e duas superfícies de ataque |

A escolha define: a existência de EP-041, o conteúdo das propagações de EP-028, a necessidade de DSP-26 e a lista de destinos em `propagacao_destino`. Os requisitos abaixo aplicam-se a todas as opções, salvo indicação.

## 4. Habilitação e consentimento

| ID | Requisito | Prioridade | Critério de aceitação | Origem |
| --- | --- | --- | --- | --- |
| BIO-01 | Registar a habilitação ao tratamento biométrico por colaborador e modalidade, com finalidade, versão da política, consentimento quando aplicável e vigência | E | Enrollment e matching sem habilitação activa são recusados | RF-061, RN-043 |
| BIO-02 | Revogar a habilitação com efeito em novas utilizações e desencadear o tratamento dos templates segundo a política | E | Após revogação aplicada, o colaborador não é identificado biometricamente; marcação alternativa continua disponível | RF-061, RN-047 |
| BIO-03 | Activar a modalidade por tenant, local, terminal e colaborador | E | Desactivação em qualquer âmbito impede nova marcação biométrica nesse contexto | RF-032 |
| BIO-04 | Garantir método alternativo a quem não esteja habilitado ou recuse o tratamento, sem desvantagem no registo de assiduidade | E | Colaborador sem habilitação marca por método alternativo ou assistido | RF-027, RN-044 |

A habilitação é registada por quem tenha `assiduidade:gerir_habilitacao_biometrica` (PERM-14). O registo de consentimentos directamente a partir de um terminal só é admissível se a finalidade e o procedimento forem aprovados pelo responsável de dados (ver [10 §9](10-Especificacao-de-APIs.md)).

## 5. Enrollment

Fluxo em DG-SQ-04 e EP-038.

| ID | Requisito | Prioridade | Critério de aceitação | Origem |
| --- | --- | --- | --- | --- |
| BIO-05 | Exigir operador autenticado com PERM-15 e colaborador seleccionado no tenant correcto | E | Operador sem permissão ou colaborador de outro tenant é recusado | RF-033 |
| BIO-06 | Confirmar a identidade do colaborador por procedimento aprovado antes da captura | E | O registo indica o método de confirmação usado | RF-033 |
| BIO-07 | Validar qualidade mínima e prova de vida em cada captura, com instruções ao colaborador | E | Captura abaixo da qualidade não é aceite; instruções orientam a repetição | RF-033, RNF-024 |
| BIO-08 | Criar a referência apenas após captura válida e conclusão explícita | E | Enrollment interrompido não deixa referência activa | RF-033, RN-043 |
| BIO-09 | Registar versão do enrollment, do algoritmo, operador, data e qualidade agregada, sem guardar a imagem por defeito | E | Metadados consultáveis; nenhuma imagem persistida fora da política | RF-033, RF-037 |
| BIO-10 | Em substituição, ligar a nova referência à anterior e passar esta a `substituido` | E | Histórico mostra a cadeia de versões | RN-045 |

## 6. Comparação e prova de vida

Sequência: captura → verificação de qualidade → prova de vida → comparação → decisão pelo limiar → registo da tentativa → submissão do evento (DG-SQ-01).

| ID | Requisito | Prioridade | Critério de aceitação | Origem |
| --- | --- | --- | --- | --- |
| BIO-11 | Executar prova de vida antes de aceitar uma comparação | E | Ataques de apresentação do ensaio (§11) são rejeitados nas taxas aprovadas | RF-034, RNF-023 |
| BIO-12 | Decidir pela comparação com o limiar aprovado e registar a versão da configuração e do algoritmo | E | Evento aceite indica a referência e as versões usadas | RF-035 |
| BIO-13 | Recusar limiares fora do intervalo aprovado | E | Configuração fora do intervalo é rejeitada com `PEDIDO_INVALIDO` | RF-035 |
| BIO-14 | Usar verificação 1:1 quando o colaborador se identifica previamente e identificação 1:N apenas quando aprovada para o contexto | E | O modo usado fica registado; o limiar é definido por modo | DF-04 |
| BIO-15 | Registar apenas o resultado necessário: sucesso, sem correspondência, prova de vida falhada, qualidade insuficiente ou componente indisponível | E | Tentativas não contêm imagem, template nem pontuação bruta | RF-037, PD-05 |
| BIO-16 | Cumprir os limites de latência aprovados para a interacção completa | E | P95 medido por modelo de terminal dentro de DN-01 | RNF-001 |

## 7. Falhas e contingência

| Situação | Comportamento obrigatório | Origem |
| --- | --- | --- |
| Sem correspondência | Permitir nova tentativa até ao limite de PN-11; depois oferecer alternativa | RN-044, DSP-21 |
| Prova de vida falhada | Tratar como falha de identificação; registar tentativa; não indicar ao utilizador qual o controlo que falhou | RN-044, RNF-024 |
| Qualidade insuficiente | Instruções de posicionamento e iluminação | RNF-024 |
| Componente indisponível | Sem aceitação automática; oferecer alternativa | RF-034 |
| Referência suspensa, revogada ou fora da validade offline | Não comparar; oferecer alternativa | RN-045, DSP-26 |
| Falhas repetidas no mesmo terminal | Alerta à operação | RF-064 |

Em nenhum caso a falha biométrica conclui falta (RN-022, RN-044) ou aceita a marcação automaticamente (RNF-024). O método alternativo pode ser QR Code, NFC ou impressão digital, quando seleccionados em DF-01, ou o pedido assistido, que é sempre essencial.

## 8. Impressão digital

A impressão digital é também dado biométrico e segue as mesmas regras da modalidade facial, com as diferenças abaixo.

| ID | Requisito | Prioridade | Critério de aceitação | Origem |
| --- | --- | --- | --- | --- |
| BIO-17 | Aplicar habilitação (BIO-01, BIO-02), enrollment (BIO-05 a BIO-10) e ciclo de vida (§9) à impressão digital | D | A modalidade `impressao_digital` usa as mesmas entidades ENT-23 e ENT-24 | RF-030, RF-061 |
| BIO-18 | Guardar templates de leitores de terceiros apenas no formato e local aprovados, cifrados e fora do domínio comum | D | Templates não aparecem em tabelas de negócio nem em logs | PD-05, RNF-016 |
| BIO-19 | Avaliar desempenho e ataques de apresentação do leitor aprovado (§10, §11) | D | Relatório de ensaio aprovado antes da activação | RNF-023 |

## 9. Ciclo de vida do template

Estados de DG-ES-06, também usados no [Modelo de Dados §6.5](09-Modelo-de-Dados.md): `em_preparacao`, `activo`, `suspenso`, `substituido`, `eliminacao_pendente`, `eliminado`. O estado de distribuição a cada terminal é registado por destino em `propagacao_destino` (MEC-11), não no template.

| ID | Requisito | Prioridade | Critério de aceitação | Origem |
| --- | --- | --- | --- | --- |
| BIO-20 | Propagar activação, suspensão e eliminação a todos os destinos autorizados e acompanhar a confirmação por destino | E | Backoffice mostra destinos confirmados e pendentes | RF-036 |
| BIO-21 | Suspensão tem efeito imediato onde a propagação já foi aplicada; destinos pendentes ficam sujeitos à validade offline | E | Terminal que confirmou a suspensão deixa de usar o template | RF-036, RN-045 |
| BIO-22 | Concluir a eliminação (`eliminado`) **apenas** após confirmação de todos os destinos aplicáveis, incluindo a expiração controlada de cópias | E | Enquanto houver destino pendente, o estado permanece `eliminacao_pendente` | RF-036, RN-047 |
| BIO-23 | Distinguir revogação de utilização e eliminação | E | Um impedimento formal à eliminação não reactiva a utilização | RN-047 |
| BIO-24 | Reaplicar suspensões e eliminações posteriores à cópia antes de retomar o serviço após restauro | E | Exercício de restauro não reactiva templates eliminados | RN-048, EX-10 |

A versão 0.1 admitia concluir a eliminação mediante "excepção formal". Essa possibilidade foi retirada por contrariar RF-036 e RN-047. Um destino definitivamente inacessível (por exemplo, terminal perdido) exige decisão em DF-08 sobre a sua invalidação criptográfica, e não uma declaração de eliminação concluída.

Enrollment abandonado e reactivação de referência suspensa não estão definidos (DU-05); até decisão, não existe reactivação e um enrollment abandonado fica em `em_preparacao` sem efeito, sendo limpo pelo processo de retenção.

## 10. Avaliação de desempenho

| ID | Requisito | Prioridade | Critério de aceitação | Origem |
| --- | --- | --- | --- | --- |
| BIO-25 | Definir, antes do ensaio, as métricas, a amostra, as condições e os critérios de aceitação | E | Plano de ensaio aprovado em DN-05 | RNF-023 |
| BIO-26 | Medir separadamente falsas aceitações e falsas rejeições (FAR/FRR, ou FMR/FNMR ao nível da comparação) e ataques de apresentação (APCER/BPCER) | E | Relatório apresenta cada métrica com amostra e intervalo de confiança | RNF-023 |
| BIO-27 | Ensaiar nas condições reais: iluminação, posicionamento, equipamento, diversidade da população e uso de acessórios | E | Condições documentadas; resultados por subgrupo relevante | RNF-024 |
| BIO-28 | Repetir o ensaio a cada mudança de algoritmo, modelo, limiar ou equipamento | E | Nenhuma alteração entra em produção sem relatório | RNF-035 |
| BIO-29 | Monitorizar em produção a taxa de falhas de identificação por terminal e por período | D | Desvio face ao ensaio gera alerta | RF-064 |

## 11. Anti-spoofing

Classes de ataque de apresentação a ensaiar, conforme a capacidade do equipamento: fotografia impressa; fotografia ou vídeo em ecrã; máscara de papel ou tridimensional; reprodução com recorte de olhos ou boca. Para impressão digital: moldes de materiais comuns. O resultado do ensaio indica que classes são detectadas e com que taxas; classes não detectadas são riscos aceites explicitamente ou impedem a activação.

## 12. Protecção dos dados biométricos

| ID | Requisito | Prioridade | Critério de aceitação | Origem |
| --- | --- | --- | --- | --- |
| BIO-30 | Guardar templates apenas em CNT-09, cifrados com chaves próprias, acessíveis só a CMP-07 | E | Nenhum outro componente lê templates; chaves separadas do acesso corrente | RNF-016, FC-04 |
| BIO-31 | Não conservar imagens por defeito; conservação excepcional exige finalidade, prazo e acesso aprovados | E | Inspecção do armazenamento, ficheiros e logs não encontra imagens fora da política | RF-037, RNF-020 |
| BIO-32 | Excluir templates, imagens e pontuações de logs, relatórios, exportações e respostas não biométricas | E | Revisão de tráfego e ficheiros confirma a exclusão | RN-046, RNF-020 |
| BIO-33 | Auditar enrollment, alterações de estado, alterações de limiar e acessos a dados biométricos | E | Eventos do [documento 16](16-Auditoria-e-Logs.md) presentes, sem o template | RF-060 |
| BIO-34 | Não usar dados biométricos para finalidade diferente da assiduidade | E | Não existem interfaces de pesquisa biométrica fora de CMP-07 | BRD detalhado §4.2 |
| BIO-35 | Com fornecedor externo, contratar localização, retenção, subcontratantes, eliminação verificável e notificação de incidentes | E | Contrato aprovado pelo responsável de dados | [18 §5](18-Integracoes-com-Sistemas-Externos.md) |

## 13. Situação actual

Observado em 25/09/2026 no Nexora ERP, a reconciliar (DT-01):

| Elemento | Observado | Lacuna |
| --- | --- | --- |
| Enrollment facial | `POST /api/rh/funcionarios/biometria/facial/enroll` | Sem habilitação prévia verificada (BIO-01) nem estados de §9 |
| Verificação facial | `POST /api/self-service/assiduidade/biometria/facial/verificar`; tabela `rh.facial_verification_uses` | Confirmar local de processamento (DF-04) e o que é registado (BIO-15) |
| Imagens | Campo `foto_url` em `rh.eventos_assiduidade` | Contraria BIO-31 salvo finalidade aprovada |
| Impressão digital | `hardware.fingerprint_templates` | Verificar cifragem e separação (BIO-18) |
| Consentimentos | `lgpd.consentimentos` e endpoints de consentimento em `/api/hardware` | Ligar à habilitação por modalidade e finalidade (BIO-01) |

Antes do ensaio de §10 deve ser inventariado o pipeline existente: modelo usado, pré-processamento, método de prova de vida e local onde os templates são guardados.

## 14. Rastreabilidade

| Requisitos | RF | RN / RNF | Casos de uso e diagramas |
| --- | --- | --- | --- |
| BIO-01 a BIO-04 | RF-027, RF-032, RF-061 | RN-043, RN-044, RN-047 | UC-04, UC-12 |
| BIO-05 a BIO-10 | RF-033, RF-037 | RN-043, RN-045 | UC-04; DG-SQ-04 |
| BIO-11 a BIO-16 | RF-034, RF-035, RF-037 | RN-044; RNF-001, RNF-023, RNF-024 | UC-01; DG-SQ-01 |
| BIO-17 a BIO-19 | RF-030, RF-061 | RNF-016, RNF-023 | UC-01, UC-04 |
| BIO-20 a BIO-24 | RF-036, RF-062, RF-065 | RN-045, RN-047, RN-048 | UC-12, UC-18, UC-21; DG-SQ-07, DG-ES-06 |
| BIO-25 a BIO-29 | RF-034, RF-064 | RNF-023, RNF-024, RNF-035 | — |
| BIO-30 a BIO-35 | RF-037, RF-060 | RN-046; RNF-016, RNF-020 | UC-17 |

## 15. Decisões pendentes

| Decisão | Efeito |
| --- | --- |
| DF-04 | Opção de processamento de §3, fornecedor e local dos templates |
| DF-08, DN-06 | Retenção, invalidação de destinos inacessíveis e tratamento em restauro |
| DN-05 | Métricas, amostra e critérios de aceitação |
| PN-11 | Número de tentativas e métodos de contingência |
| DU-05 | Reactivação e enrollment abandonado |
| DF-01 | Activação da impressão digital |

## 16. Aprovação e referências

O responsável de dados valida §2, §4, §9 e §12; a equipa técnica valida §3, §5, §6 e §10; segurança valida §11; RH valida a contingência de §7. Cada aprovação deve identificar nome, versão e data. Estado de aprovação desta versão: **pendente**.

- [Índice da documentação](README.MD).
- [Especificação de Dispositivos](11-Especificacao-de-Dispositivos-Terminais.md), [Modelo de Dados](09-Modelo-de-Dados.md), [APIs](10-Especificacao-de-APIs.md) EP-037 a EP-042.
- [Segurança e Protecção de Dados](17-Seguranca-e-Proteccao-de-Dados.md).
