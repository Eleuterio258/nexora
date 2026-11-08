# Gestão de Utilizadores e Perfis — Sistema de Gestão de Assiduidade

## 1. Controlo do documento

| Campo | Valor |
| --- | --- |
| Referência | UTL-ASS-001 |
| Versão | 0.3 |
| Data | 25/09/2026 |
| Estado | Rascunho técnico para validação |
| Responsáveis | Administração, RH e segurança, com validação do responsável de dados — nomes a designar |
| Base documental | RF-006 a RF-008, RF-011, RF-012; RN-002, RN-005, RN-031, RN-032; RNF-014; UC-08, UC-09; DG-CL-01, DG-UC-04; [Requisitos Funcionais §3](02-Requisitos-Funcionais.md) |

| Versão | Data | Alteração |
| --- | --- | --- |
| 0.1 | 25/09/2026 | Conta, estados e lista de perfis em resumo |
| 0.2 | 25/09/2026 | Versão detalhada: catálogo de perfis PRF, actores técnicos, ciclo de vida da conta, sessões, atribuições, delegação, segregação de funções e revisão de acessos |
| 0.3 | 25/09/2026 | Alinhamento com o modelo de permissões granulares `módulo:acção`: os perfis PRF passam a modelos de cargo propostos e não vinculativos; atribuição por cargo, permissões directas e tipo de utilizador; âmbito próprio, hierárquico ou global; segregação verificada sobre pessoas |

## 2. Objectivo, âmbito e convenções

Este documento especifica quem acede ao sistema e como: contas, sessões, cargos, permissões directas, âmbito, delegação e segregação de funções. O modelo de autorização e o catálogo de permissões `módulo:acção` estão nos [Requisitos Funcionais §3](02-Requisitos-Funcionais.md); a correspondência com os endpoints está na [Matriz de Permissões](15-Matriz-de-Permissoes-e-Acessos.md).

Convenções: **PRF-xx** identifica **modelos de cargo propostos**; **ACT-xx** actores técnicos; **SDF-xx** regras de segregação de funções; **UTL-xx** requisitos. Os identificadores PRF mantêm-se da versão 0.2 por estabilidade, mas deixaram de designar perfis fixos: nenhum requisito, regra ou teste depende de um PRF.

## 3. Princípios

1. **Conta e colaborador são objectos distintos** (RF-011, RN-005). Um colaborador pode marcar num terminal sem conta; uma conta ligada a um colaborador não recebe permissões de gestão por essa ligação.
2. **Autorização granular.** Cada operação exige uma permissão `módulo:acção`. Não existem papéis nem perfis predefinidos no sistema; cada tenant compõe os seus cargos a partir do catálogo, e qualquer combinação é válida.
3. **Permissão e âmbito são independentes.** A permissão diz o que se pode fazer; o âmbito (próprio, hierárquico ou global) diz sobre quem. Ser responsável de uma unidade dá âmbito hierárquico, mas não permissão: decidir um pedido exige também a permissão de decisão.
4. **Menor privilégio.** Cargos e permissões directas atribuem apenas o necessário; permissões de escrita não são concedidas a quem só precisa de consultar.
5. **Ninguém se concede a si próprio** um cargo, uma permissão directa ou uma delegação (SDF-01).

## 4. Origem das permissões e do âmbito

As permissões efectivas de um utilizador, num tenant, são a união de:

| Origem | Descrição | Quem a define |
| --- | --- | --- |
| Cargo | Conjunto de permissões associado à vinculação do utilizador ao tenant | Quem tem `autorizacao:gerir_perfis` |
| Permissões directas | Permissões atribuídas individualmente, que acrescentam às do cargo | Quem tem `autorizacao:gerir_utilizadores` |
| Tipo de utilizador | Permissões por defeito do tipo (por exemplo, o tipo `funcionario` recebe as de self-service) | Plataforma |

Ficam excluídas as permissões de módulos desactivados para o tenant. O tipo `superadmin` é tratado à parte e só acede a dados de negócio com autorização de suporte (RF-008, `seguranca:autorizar_suporte`).

| Âmbito | Como se obtém |
| --- | --- |
| Próprio | A operação incide sobre o próprio utilizador |
| Hierárquico | O utilizador é responsável da unidade do colaborador ou de uma unidade ascendente, ou foi designado aprovador ou delegado com vigência (UTL-13, UTL-14) |
| Global no tenant | O utilizador tem `recursos-humanos:gerir_funcionarios` (consulta: `recursos-humanos:ver_funcionarios`) |

## 5. Modelos de cargo propostos

Os modelos abaixo são pontos de partida que um tenant pode adoptar, alterar ou ignorar. Os códigos de permissão estão no [catálogo dos Requisitos Funcionais §3.2](02-Requisitos-Funcionais.md). Um modelo não confere nada por si: só as permissões atribuídas contam.

| ID | Modelo de cargo | Finalidade | Permissões propostas | Âmbito típico |
| --- | --- | --- | --- | --- |
| PRF-01 | Administrador da plataforma | Ciclo de vida dos tenants e operação global | Tipo `superadmin`; dados de negócio só com autorização de suporte | Plataforma |
| PRF-02 | Administrador do tenant | Contas, cargos, configuração e terminais | `autorizacao:gerir_utilizadores`, `autorizacao:gerir_perfis`, `sistema-configuracao:editar_configuracoes`, `hardware:gerir_dispositivos` | Global |
| PRF-03 | Gestão de RH | Colaboradores, horários, políticas, apuramento, pedidos, fecho | `recursos-humanos:gerir_funcionarios`, `recursos-humanos:gerir_horarios`, `assiduidade:gerir_configuracao`, `assiduidade:submeter_em_nome`, `assiduidade:marcar_assistido`, `assiduidade:resolver_pendencias`, `assiduidade:recalcular`, `assiduidade:fechar_periodo`, `recursos-humanos:ver_relatorios` | Global |
| PRF-04 | Aprovação | Decisão de pedidos da equipa | `assiduidade:aprovar_correcao`, `recursos-humanos:aprovar_ausencias`, `pedido-ferias:aprovar`, `recursos-humanos:ver_funcionarios` | Hierárquico |
| PRF-05 | Self-service | Marcação, consulta e pedidos próprios | Permissões do tipo `funcionario`: `assiduidade:ver_assiduidade`, `assiduidade:marcar_ponto`, `assiduidade:justificar`, `assiduidade:corrigir_ponto`, `pedido-ferias:ver_pedidos`, `pedido-ferias:submeter_pedido` | Próprio |
| PRF-06 | Operação biométrica | Enrollment e gestão de referências | `assiduidade:gerir_biometria` | Global ou hierárquico |
| PRF-07 | Auditoria | Consulta de evidência | `auditoria:ver_logs` | Global |
| PRF-08 | Operação técnica | Terminais, eventos de dispositivos e reprocessamento | `hardware:ver_dispositivos`, `hardware:ver_eventos`, `hardware:gerir_eventos` | Global |
| PRF-09 | Integração | Configuração e execução de integrações | `assiduidade:gerir_integracao`, `assiduidade:executar_integracao` | Global |
| PRF-10 | Protecção de dados | Habilitação biométrica, limiar, retenção e pedidos dos titulares | `assiduidade:gerir_habilitacao_biometrica`, `assiduidade:configurar_limiar_biometrico`, `assiduidade:gerir_retencao` | Global |

Combinações a evitar no mesmo cargo, por segregação (§9): `assiduidade:submeter_em_nome` com `assiduidade:aprovar_correcao` sem política de auto-aprovação; `assiduidade:fechar_periodo` com `assiduidade:reabrir_periodo`; `assiduidade:gerir_integracao` com `assiduidade:executar_integracao` em produção quando a política exigir dupla validação. O sistema não impede estas combinações; a segregação é verificada em cada operação sobre as pessoas envolvidas.

## 6. Actores técnicos

| ID | Actor | Autenticação | Âmbito | Limites |
| --- | --- | --- | --- | --- |
| ACT-01 | Dispositivo | Credencial de dispositivo (DT-05) | Tenant e local | Só endpoints de dispositivo; nunca consulta dados de negócio além da configuração |
| ACT-02 | Tarefa agendada | Conta técnica interna | Tenant da tarefa | Permissões próprias por tipo de tarefa |
| ACT-03 | Integração | Credencial da configuração de integração | Tenant e ambiente | Só recursos do contrato |
| ACT-04 | Serviço biométrico | Credencial de serviço com permissões `biometric:*`, `liveness:*`, `fingerprint:*`, `audit:read` | Tenant da credencial | Só endpoints do serviço biométrico |

Actores técnicos não iniciam sessões interactivas nem recebem cargos.

## 7. Ciclo de vida da conta

Também em [Requisitos Funcionais §6](02-Requisitos-Funcionais.md) e [Modelo de Dados §6.7](09-Modelo-de-Dados.md).

| Estado | Significado | Transições |
| --- | --- | --- |
| `convidada` | Criada, à espera de activação pelo titular | `activa` (activação dentro do prazo), `terminada` (convite expirado ou anulado) |
| `activa` | Pode autenticar-se | `suspensa`, `bloqueada`, `terminada` |
| `suspensa` | Suspensão administrativa com motivo | `activa`, `terminada` |
| `bloqueada` | Bloqueio automático por tentativas falhadas ou suspeita | `activa` (desbloqueio autorizado ou recuperação), `terminada` |
| `terminada` | Fim definitivo; histórico preservado | — |

| ID | Requisito | Prioridade | Critério de aceitação | Origem |
| --- | --- | --- | --- | --- |
| UTL-01 | Criar conta por convite com prazo, associando opcionalmente um colaborador | E | Convite expirado não activa; associação não concede permissões de gestão | RF-011, RN-005 |
| UTL-02 | Suspender, bloquear e terminar com efeito na operação seguinte, incluindo sessões abertas | E | Após a transição, pedidos com a sessão existente são recusados | RF-006, RNF-014 |
| UTL-03 | Terminar a conta quando termina o vínculo do colaborador associado, salvo decisão explícita | E | Término do vínculo gera tarefa de revisão da conta | RF-009 |
| UTL-04 | Preservar o histórico e a autoria das contas terminadas | E | Auditoria continua a identificar o autor | RF-060 |

## 8. Autenticação e sessões

| ID | Requisito | Prioridade | Critério de aceitação | Origem |
| --- | --- | --- | --- | --- |
| UTL-05 | Autenticar pelo mecanismo aprovado (interno ou fornecedor de identidade) | E | Credenciais inválidas não abrem sessão; mensagens não revelam se a conta existe | RF-006, DF-02 |
| UTL-06 | Sessões com token de acesso curto, renovação rotativa e revogação central | E | Token de renovação reutilizado invalida a cadeia; revogação é efectiva na operação seguinte | RNF-014 |
| UTL-07 | Autenticação reforçada (segundo factor) para quem tenha permissões sensíveis — `autorizacao:*`, `assiduidade:reabrir_periodo`, `assiduidade:gerir_biometria`, `assiduidade:gerir_habilitacao_biometrica`, `assiduidade:configurar_limiar_biometrico`, `assiduidade:gerir_retencao`, `assiduidade:gerir_integracao` — e para o tipo `superadmin` | E | Operação que exige uma destas permissões, sem segundo factor, é recusada quando a política o exigir | RNF-014, DN-04 |
| UTL-08 | Bloqueio progressivo após tentativas falhadas e protecção contra enumeração | E | Limite de tentativas aplicado por conta e por origem | RNF-018 |
| UTL-09 | Recuperação de acesso sem revelar segredos, com validação do segundo factor quando aplicável | E | Recuperação não permite contornar o segundo factor | RF-006, DF-02 |
| UTL-10 | Terminar sessão e listar/terminar sessões activas da própria conta | E | Sessão terminada deixa de funcionar imediatamente | RF-006 |

Prazos de sessão, requisitos de palavra-passe e mecanismos de segundo factor dependem de DF-02 e DN-04.

## 9. Atribuições, âmbito, delegação e escalonamento

| ID | Requisito | Prioridade | Critério de aceitação | Origem |
| --- | --- | --- | --- | --- |
| UTL-11 | Compor cargos a partir do catálogo de permissões e atribuir cargos e permissões directas, com autor e, quando aplicável, vigência | E | A permissão só produz efeito na vigência; alteração de um cargo aplica-se a todos os utilizadores com esse cargo na operação seguinte | RF-007 |
| UTL-12 | Revogar cargos e permissões directas com efeito na operação seguinte, incluindo pedidos directos à API | E | CA-09 e teste directo de API após revogação | RF-007 |
| UTL-13 | Manter responsáveis de unidade e, quando necessário, designar aprovadores por colaborador ou unidade, com vigência | E | Pedido é encaminhado ao responsável ou aprovador vigente; alteração de responsável muda o âmbito hierárquico na operação seguinte | RF-012 |
| UTL-14 | Delegar âmbito de aprovação com validade, registada e auditada; o delegado tem de ter a permissão de decisão | D | Delegado decide dentro do âmbito e validade; fora disso é recusado | RN-032, DF-02 |
| UTL-15 | Escalonar pedidos sem decisão no prazo configurado para o responsável da unidade ascendente | D | Pedido escalonado indica o motivo; a ausência do aprovador não autoriza outro utilizador automaticamente | RN-032, PN-08 |

## 10. Segregação de funções

A segregação é verificada em cada operação sobre as **pessoas e objectos** envolvidos, não sobre cargos, porque o mesmo utilizador pode ter permissões de requerente e de decisor.

| ID | Regra | Aplicação | Origem |
| --- | --- | --- | --- |
| SDF-01 | Ninguém atribui cargos, permissões directas ou delegações a si próprio | EP-008 recusa quando o autor coincide com o destinatário | Princípio 5 |
| SDF-02 | O decisor de um pedido não pode ser o requerente nem o colaborador abrangido, salvo política de auto-aprovação aprovada | EP-049 devolve `SEGREGACAO_FUNCOES` | RN-031 |
| SDF-03 | Quem introduz uma marcação assistida não a pode aprovar como correcção | Verificação no pedido associado | RN-031 |
| SDF-04 | Reabrir um período exige `assiduidade:reabrir_periodo`, distinta de `assiduidade:fechar_periodo`, e autenticação reforçada; quem fechou a versão não a reabre sozinho quando a política o exigir | EP-060 | RF-050 |
| SDF-05 | Ninguém executa enrollment biométrico de si próprio | EP-038 | RF-033 |
| SDF-06 | Quem configura uma integração não aprova a sua activação em produção quando a política exigir dupla validação | EP-066 | RF-056 |
| SDF-07 | Acesso de suporte da plataforma não decide pedidos nem fecha períodos do tenant | [Matriz 15](15-Matriz-de-Permissoes-e-Acessos.md) | RF-008 |

## 11. Revisão de acessos

| ID | Requisito | Prioridade | Critério de aceitação | Origem |
| --- | --- | --- | --- | --- |
| UTL-16 | Disponibilizar relatório de contas, cargos, permissões directas, âmbito hierárquico, delegações e último acesso por tenant | E | Relatório exportável para a revisão periódica | RF-007 |
| UTL-17 | Registar a revisão periódica de quem tem permissões sensíveis (UTL-07), com resultado e responsável | D | Evidência da última revisão por tenant | RNF-014 |
| UTL-18 | Assinalar contas inactivas, permissões directas sem vigência final e cargos com combinações a evitar (§5) | D | Lista de excepções na revisão | RNF-014 |

## 12. Situação actual

Observado no Nexora ERP em 25/09/2026:

- As permissões efectivas são a união do cargo da vinculação, das permissões directas e das permissões por tipo de utilizador, excluídos os módulos desactivados para o tenant; `superadmin` tem acesso total sem autorização de suporte.
- Cada tenant recebe cargos padrão editáveis (Administrador, Director de RH, Gestor de TI, Auditor Interno, …). O cargo padrão de auditor inclui `auditoria:gerir_logs` (escrita), contra PRF-07.
- O âmbito sobre um colaborador é concedido por `recursos-humanos:gerir_funcionarios`, por ser responsável da unidade ou de uma unidade ascendente, ou por ter criado o funcionário. Esta última via não tem correspondência nesta especificação e deve ser revista.
- `recursos-humanos:gerir_funcionarios` agrega operações que o catálogo separa (marcação assistida, enrollment, consentimentos, remoção de presenças). As permissões novas estão marcadas no [catálogo §3.2](02-Requisitos-Funcionais.md).
- Não existe verificação de segregação (SDF-02) nas decisões de correcções e ausências ([documento 39](39-Lacunas-de-Implementacao-ERP-Assiduidade.md), LAE-11).

## 13. Rastreabilidade

| Elementos | RF | RN / RNF | Casos de uso e diagramas |
| --- | --- | --- | --- |
| §4, PRF-01 a PRF-10 | RF-007, RF-008 | RN-002 | UC-08; DG-CL-01, DG-UC-04 |
| UTL-01 a UTL-04 | RF-006, RF-009, RF-011 | RN-005 | UC-08, UC-09 |
| UTL-05 a UTL-10 | RF-006 | RNF-014, RNF-018 | UC-08 |
| UTL-11 a UTL-15 | RF-007, RF-012 | RN-031, RN-032 | UC-08, UC-09; DG-CL-01 |
| SDF-01 a SDF-07 | RF-008, RF-033, RF-043, RF-047, RF-050, RF-056 | RN-031 | UC-02, UC-04, UC-14, UC-15, UC-19 |
| UTL-16 a UTL-18 | RF-007 | RNF-014 | UC-08 |

## 14. Decisões pendentes

| Decisão | Efeito |
| --- | --- |
| DF-02 | Mecanismo de identidade, recuperação, delegação, auto-aprovação e cargos padrão propostos |
| DN-04 | Segundo factor, prazos de sessão e bloqueio |
| PN-08 | Prazos de escalonamento e desistência |
| — | Manter ou retirar o âmbito concedido a quem criou o funcionário (§12) |

## 15. Aprovação e referências

A administração e RH validam modelos de cargo, delegação e segregação; segurança valida §8 e §11; o responsável de dados valida PRF-06 e PRF-10. Cada aprovação deve identificar nome, versão e data. Estado de aprovação desta versão: **pendente**.

- [Índice da documentação](README.MD).
- [Requisitos Funcionais §3](02-Requisitos-Funcionais.md), [Matriz de Permissões e Acessos](15-Matriz-de-Permissoes-e-Acessos.md), [Gestão Multi-Tenant](13-Gestao-Multi-Tenant.md), [APIs](10-Especificacao-de-APIs.md) EP-001 a EP-009.
