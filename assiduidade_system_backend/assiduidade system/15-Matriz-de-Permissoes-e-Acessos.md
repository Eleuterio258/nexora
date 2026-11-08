# Matriz de Permissões e Acessos — Sistema de Gestão de Assiduidade

## 1. Controlo do documento

| Campo | Valor |
| --- | --- |
| Referência | PERM-ASS-001 |
| Versão | 0.3 |
| Data | 25/09/2026 |
| Estado | Rascunho para validação |
| Proprietário | Responsável de negócio e RH — a designar |
| Validadores | Administração, segurança, responsável de dados e equipa técnica |
| Base documental | [Requisitos Funcionais §3](02-Requisitos-Funcionais.md), [Gestão de Utilizadores e Perfis](14-Gestao-de-Utilizadores-e-Perfis.md), [APIs](10-Especificacao-de-APIs.md), RF-001 a RF-065, UC-01 a UC-21 |

| Versão | Data | Alteração |
| --- | --- | --- |
| 0.1 | 25/09/2026 | Matriz inicial com oito perfis e treze capacidades |
| 0.2 | 25/09/2026 | Versão detalhada: catálogo PERM, matriz por perfil PRF, condições, segregação e correspondência com as permissões existentes |
| 0.3 | 25/09/2026 | Alinhamento com o modelo de permissões granulares: cada PERM-xx passa a ter código `módulo:acção` (existente ou novo); a matriz por perfil passa a proposta de modelos de cargo, não vinculativa; condições reescritas em termos de permissão, âmbito e pessoas |

## 2. Objectivo, âmbito e convenções

Este documento define as permissões do sistema, o seu código `módulo:acção`, os endpoints que protegem e uma proposta de composição de cargos padrão. É a referência para a autorização implementada em cada endpoint (coluna "Permissão" do documento 10) e para os testes de acesso.

O modelo de autorização está nos [Requisitos Funcionais §3.1](02-Requisitos-Funcionais.md): a autorização efectiva combina **permissão** (do cargo, directa ou por tipo de utilizador), **tenant**, **âmbito** (próprio, hierárquico ou global) e as **regras de segregação** (SDF) verificadas sobre as pessoas envolvidas. Não existem perfis fixos no sistema; os modelos PRF do [documento 14 §5](14-Gestao-de-Utilizadores-e-Perfis.md) são propostas de cargo.

Convenções: **PERM-xx** é o identificador documental estável; o **código** é o que o servidor verifica. **Existente** — código já verificado nas rotas do ERP em 25/09/2026; **Novo** — a criar, estando a operação hoje coberta pela permissão indicada em §7.

## 3. Catálogo de permissões

| ID | Código | Estado | Permissão | Endpoints | RF |
| --- | --- | --- | --- | --- | --- |
| PERM-01 | Tipo `superadmin` | Existente | Gerir ciclo de vida de tenants | EP-010 | RF-001 |
| PERM-02 | `sistema-configuracao:editar_configuracoes`; estrutura: `recursos-humanos:gerir_funcionarios` | Existente | Configurar tenant e estrutura organizacional | EP-011, EP-012 | RF-003 a RF-005 |
| PERM-03 | `autorizacao:gerir_utilizadores`, `autorizacao:gerir_perfis` | Existente | Gerir contas, cargos e atribuições | EP-006 a EP-008 | RF-007 |
| PERM-04 | `seguranca:autorizar_suporte` | Novo | Conceder e revogar autorização de suporte | EP-009 | RF-008 |
| PERM-05 | `recursos-humanos:gerir_funcionarios` | Existente | Gerir colaboradores, associações e credenciais de identificação | EP-013 a EP-015 | RF-009 a RF-012 |
| PERM-06 | `recursos-humanos:importar_funcionarios` | Novo | Importar colaboradores | EP-016 | RF-013 |
| PERM-07 | `recursos-humanos:gerir_horarios`; `assiduidade:gerir_configuracao` | Existente | Gerir calendários, horários, versões de política em rascunho e tipos de ausência | EP-017 a EP-020, EP-022, EP-051 | RF-014 a RF-018, RF-041 |
| PERM-08 | `assiduidade:activar_politica` | Novo | Activar versão de política | EP-021 | RF-016 |
| PERM-09 | `hardware:gerir_dispositivos` | Existente | Gerir terminais e configuração distribuída | EP-023 a EP-026 | RF-019, RF-020 |
| PERM-10 | `assiduidade:marcar_ponto` | Existente | Marcar ponto próprio na aplicação | EP-031 | RF-021 |
| PERM-11 | Credencial de dispositivo | — | Submeter eventos e tentativas como dispositivo | EP-027 a EP-032, EP-036, EP-041 | RF-020 a RF-026, RF-037 |
| PERM-12 | `assiduidade:marcar_assistido` | Novo | Registar marcação assistida | EP-033 | RF-027 |
| PERM-13 | `assiduidade:resolver_pendencias` | Novo | Analisar e resolver eventos pendentes | EP-035 | RF-024 |
| PERM-14 | `assiduidade:gerir_habilitacao_biometrica` | Novo | Gerir habilitação biométrica e consentimento | EP-037 | RF-061 |
| PERM-15 | `assiduidade:gerir_biometria` | Novo | Executar enrollment e gerir referências biométricas | EP-038 a EP-040 | RF-033, RF-036 |
| PERM-16 | `assiduidade:configurar_limiar_biometrico` | Novo | Configurar limiar biométrico | EP-042 | RF-035 |
| PERM-17 | `assiduidade:justificar`, `assiduidade:corrigir_ponto`, `pedido-ferias:submeter_pedido` | Existente | Submeter pedidos próprios | EP-043 a EP-045, EP-047, EP-048, EP-050 | RF-042, RF-045, RF-046 |
| PERM-18 | `assiduidade:submeter_em_nome` | Novo | Submeter pedidos em nome de colaboradores | EP-043 a EP-045, EP-047, EP-048, EP-050 | RF-042, RF-046 |
| PERM-19 | `assiduidade:aprovar_correcao`, `recursos-humanos:aprovar_ausencias`, `pedido-ferias:aprovar` | Existente | Decidir pedidos | EP-049 | RF-043, RF-047 |
| PERM-20 | `assiduidade:ver_assiduidade`, `pedido-ferias:ver_pedidos` | Existente | Consultar dados próprios | EP-034, EP-046, EP-052, EP-053 | RF-051 |
| PERM-21 | `recursos-humanos:ver_funcionarios` | Existente | Consultar dados de colaboradores no âmbito | EP-034, EP-046, EP-052 a EP-054, EP-061 | RF-051 |
| PERM-22 | `assiduidade:recalcular`; decisão de horas: `assiduidade:aprovar_horas` | Novo | Recalcular e decidir horas elegíveis | EP-055, EP-056 | RF-039, RF-040 |
| PERM-23 | `assiduidade:fechar_periodo` | Novo | Validar e fechar período | EP-057 a EP-059 | RF-048, RF-049 |
| PERM-24 | `assiduidade:reabrir_periodo` | Novo | Reabrir período | EP-060 | RF-050 |
| PERM-25 | `recursos-humanos:ver_relatorios` | Existente | Gerar relatórios | EP-062 | RF-052 |
| PERM-26 | `assiduidade:exportar` | Novo | Exportar dados | EP-063 | RF-053 |
| PERM-27 | `assiduidade:agendar_relatorios` | Novo | Agendar relatórios | EP-064 | RF-055 |
| PERM-28 | `assiduidade:gerir_integracao` | Novo | Configurar integrações | EP-065, EP-066 | RF-056 |
| PERM-29 | `assiduidade:executar_integracao` | Novo | Executar, consultar e reprocessar integrações | EP-068 a EP-071 | RF-057 a RF-059 |
| PERM-30 | `auditoria:ver_logs` | Existente | Consultar auditoria de negócio | EP-072, EP-073 | RF-060 |
| PERM-31 | `auditoria:ver_logs` | Existente | Consultar auditoria técnica e operacional | EP-072 | RF-060, RF-063 |
| PERM-32 | `assiduidade:gerir_retencao` | Novo | Gerir retenção, eliminação e anonimização | EP-074, EP-075 | RF-062 |
| PERM-33 | `hardware:ver_dispositivos`, `hardware:ver_eventos`; reprocessamento: `hardware:gerir_eventos` | Existente | Consultar estado operacional | EP-076 | RF-063 |
| PERM-34 | `assiduidade:gerir_alertas` | Novo | Configurar alertas | EP-077 | RF-064 |
| PERM-35 | Procedimento operacional | — | Executar cópias de segurança e restauro | Procedimento de UC-21 | RF-065 |

PERM-30 e PERM-31 partilham hoje o mesmo código; separá-los (por exemplo `auditoria:ver_logs_negocio` e `auditoria:ver_logs_tecnicos`) depende de DN-09. A recepção de lotes de integração (EP-067) usa a credencial de integração (ACT-03).

## 4. Proposta de modelos de cargo

A matriz abaixo cruza os modelos de cargo do [documento 14 §5](14-Gestao-de-Utilizadores-e-Perfis.md) com as permissões. **Não é vinculativa**: cada tenant compõe os seus cargos, e a autorização depende apenas das permissões efectivamente atribuídas.

Legenda: **X** — permissão incluída no modelo; **—** — não incluída. O âmbito sobre colaboradores resulta de §3.1 dos Requisitos Funcionais, não da matriz: **P** indica permissão incluída mas aplicada só ao próprio; **H** indica permissão incluída e aplicada no âmbito hierárquico.

| Permissão | PRF-01 | PRF-02 | PRF-03 | PRF-04 | PRF-05 | PRF-06 | PRF-07 | PRF-08 | PRF-09 | PRF-10 |
| --- | :-: | :-: | :-: | :-: | :-: | :-: | :-: | :-: | :-: | :-: |
| PERM-01 Tenants | X | — | — | — | — | — | — | — | — | — |
| PERM-02 Estrutura | — | X | — | — | — | — | — | — | — | — |
| PERM-03 Contas e cargos | — | X | — | — | — | — | — | — | — | — |
| PERM-04 Autorizar suporte | — | X | — | — | — | — | — | — | — | — |
| PERM-05 Colaboradores | — | X | X | — | — | — | — | — | — | — |
| PERM-06 Importação | — | X | X | — | — | — | — | — | — | — |
| PERM-07 Horários e políticas | — | — | X | — | — | — | — | — | — | — |
| PERM-08 Activar política | — | — | X | — | — | — | — | — | — | — |
| PERM-09 Terminais | — | X | — | — | — | — | — | — | — | — |
| PERM-10 Marcar ponto na app | — | — | — | — | P | — | — | — | — | — |
| PERM-12 Marcação assistida | — | — | X | — | — | — | — | — | — | — |
| PERM-13 Eventos pendentes | — | — | X | — | — | — | — | — | — | — |
| PERM-14 Habilitação biométrica | — | — | — | — | — | — | — | — | — | X |
| PERM-15 Enrollment | — | — | — | — | — | X | — | — | — | — |
| PERM-16 Limiar biométrico | — | — | — | — | — | — | — | — | — | X |
| PERM-17 Pedidos próprios | — | — | — | — | P | — | — | — | — | — |
| PERM-18 Pedidos em nome de outrem | — | — | X | — | — | — | — | — | — | — |
| PERM-19 Decidir pedidos | — | — | — | H | — | — | — | — | — | — |
| PERM-20 Dados próprios | — | — | — | — | P | — | — | — | — | — |
| PERM-21 Dados no âmbito | — | — | X | H | — | — | — | — | — | — |
| PERM-22 Recalcular | — | — | X | — | — | — | — | — | — | — |
| PERM-23 Validar e fechar | — | — | X | — | — | — | — | — | — | — |
| PERM-24 Reabrir | — | — | — | — | — | — | — | — | — | — |
| PERM-25 Relatórios | — | — | X | H | — | — | — | — | — | — |
| PERM-26 Exportar | — | — | — | — | — | — | X | — | — | — |
| PERM-27 Agendar relatórios | — | — | X | — | — | — | — | — | — | — |
| PERM-28 Configurar integração | — | — | — | — | — | — | — | — | X | — |
| PERM-29 Operar integração | — | — | — | — | — | — | — | X | X | — |
| PERM-30 Auditoria de negócio | — | — | — | — | — | — | X | — | — | — |
| PERM-31 Auditoria técnica | — | — | — | — | — | — | X | X | — | — |
| PERM-32 Retenção e eliminação | — | — | — | — | — | — | — | — | — | X |
| PERM-33 Estado operacional | — | — | — | — | — | — | — | X | — | — |
| PERM-34 Alertas | — | — | — | — | — | — | — | X | — | — |

PERM-11 (dispositivo) e PERM-35 (procedimento) não são atribuíveis a cargos. PERM-24 não está em nenhum modelo: deve ser atribuída como permissão directa a pessoas designadas, separada de PERM-23 (SDF-04). Um utilizador que seja também colaborador recebe PERM-10, PERM-17 e PERM-20 pelo tipo de utilizador, independentemente do cargo.

## 5. Condições e restrições

As condições aplicam-se a quem tenha a permissão, qualquer que seja o cargo.

| Permissão | Condição adicional | Origem |
| --- | --- | --- |
| PERM-03 | Ninguém atribui a si próprio cargos, permissões directas ou delegações (SDF-01) | RN-031 |
| PERM-19 | Só sobre colaboradores no âmbito (hierárquico, designação ou delegação vigente); nunca sobre pedido próprio ou de que é colaborador abrangido (SDF-02) | RN-031, RN-032 |
| PERM-12 | Exige motivo; a mesma pessoa não aprova a correcção associada (SDF-03) | RF-027 |
| PERM-08 | A activação regista aprovador e motivo; quando a política exigir, o autor da versão não a activa | RN-007 |
| PERM-24 | Autenticação reforçada; separada de PERM-23 (SDF-04) | RF-050 |
| PERM-05 | Correcções de ponto **não** são feitas por edição directa: seguem pedido (PERM-18) e decisão (PERM-19) | RF-046, RF-047 |
| PERM-15 | Ninguém executa enrollment de si próprio (SDF-05); só com habilitação activa do colaborador | RF-033, BIO-01 |
| PERM-01 | Acesso a dados de negócio só dentro de autorização de suporte válida; não decide pedidos nem fecha períodos (SDF-07) | RF-008 |
| PERM-21, PERM-25, PERM-26 | Resultados e ficheiros limitados ao âmbito de quem pede | RF-051 |
| PERM-26 | Exportação com finalidade registada e auditada | RN-046 |
| PERM-28 | Activação em produção sujeita a dupla validação quando a política o exigir (SDF-06) | RF-056 |
| PERM-16 | Valor dentro do intervalo aprovado no ensaio biométrico | RF-035, BIO-13 |
| Permissões sensíveis | Segundo factor para as permissões listadas no [documento 14](14-Gestao-de-Utilizadores-e-Perfis.md) UTL-07 | RNF-014 |

## 6. Verificação

Os testes são feitos **por permissão e por âmbito**, não por cargo: para cada endpoint do documento 10, um utilizador sem a permissão é recusado, e um utilizador com a permissão é aceite dentro do âmbito e recusado fora dele, sempre com dois tenants ([13 §10](13-Gestao-Multi-Tenant.md)). Testes específicos obrigatórios: revogação de permissão directa e de cargo seguida de pedido directo à API; alteração do responsável de uma unidade; delegação expirada; decisão sobre pedido próprio; suporte fora da validade; relatório agendado após revogação (CA-09).

## 7. Correspondência com as permissões existentes

Permissões observadas no Nexora ERP em 25/09/2026 ([inventário](../endpoints_assiduidade_erp.md)):

| Código existente | Uso observado | PERM | Observação |
| --- | --- | --- | --- |
| `recursos-humanos:ver_funcionarios` | Consultas de RH, leitura de catálogos e relatórios | PERM-21, PERM-25 | A rota de relatórios verifica esta permissão em vez de `recursos-humanos:ver_relatorios` |
| `recursos-humanos:gerir_funcionarios` | Colaboradores, estrutura, marcação assistida, enrollment facial e de impressão digital, consentimentos, correcções em nome de outrem, tipos de ausência, recálculo, remoção de presenças | PERM-02, PERM-05 | Cobre operações dos novos PERM-12, PERM-14, PERM-15, PERM-18 e PERM-22; a remoção física de presenças deve ser retirada |
| `recursos-humanos:gerir_horarios` | Horários | PERM-07 | — |
| `recursos-humanos:aprovar_ausencias` | Criar, aprovar, rejeitar, cancelar e marcar ausências como gozadas | PERM-19 | Criar e decidir com o mesmo código impede a segregação SDF-02; criar deve passar a PERM-18 |
| `assiduidade:aprovar_correcao` | Correcções e justificações | PERM-19 | — |
| `assiduidade:gerir_configuracao`, `assiduidade:ver_configuracao` | Tipos de evento, métodos, regras | PERM-07 | Falta PERM-08 para activação |
| `assiduidade:ver_assiduidade` | Self-service e verificação facial | PERM-20 | A verificação facial não deve depender de permissão de consulta |
| `assiduidade:marcar_ponto` | Marcação no self-service | PERM-10 | — |
| `assiduidade:justificar`, `assiduidade:corrigir_ponto` | Pedidos no self-service | PERM-17 | — |
| `pedido-ferias:ver_pedidos`, `submeter_pedido`, `aprovar` | Pedidos de férias | PERM-17, PERM-19, PERM-20 | — |
| `hardware:*` | Dispositivos e eventos | PERM-09, PERM-33 | — |
| `auditoria:ver_logs`, `auditoria:gerir_logs` | Auditoria da plataforma | PERM-30, PERM-31 | `gerir_logs` permite escrita; não deve integrar o modelo PRF-07 |
| `autorizacao:gerir_utilizadores`, `autorizacao:gerir_perfis` | Utilizadores e cargos | PERM-03 | — |
| Chave de API de dispositivo | `/api/hardware/*` | PERM-11 | Credencial individual (DT-05) |

## 8. Rastreabilidade

| Permissões | Modelos de cargo | Casos de uso | Requisitos |
| --- | --- | --- | --- |
| PERM-01 a PERM-04 | PRF-01, PRF-02 | UC-07, UC-08 | RF-001 a RF-008 |
| PERM-05 a PERM-09 | PRF-02, PRF-03 | UC-09 a UC-11 | RF-009 a RF-020 |
| PERM-10 a PERM-16 | PRF-03, PRF-05, PRF-06, PRF-10 | UC-01, UC-04, UC-06, UC-12 | RF-021 a RF-037, RF-061 |
| PERM-17 a PERM-24 | PRF-03 a PRF-05 | UC-02, UC-03, UC-13 a UC-15 | RF-038 a RF-050 |
| PERM-25 a PERM-27 | PRF-03, PRF-04, PRF-07 | UC-16 | RF-051 a RF-055 |
| PERM-28, PERM-29 | PRF-08, PRF-09 | UC-05, UC-19 | RF-056 a RF-059 |
| PERM-30 a PERM-35 | PRF-01, PRF-07, PRF-08, PRF-10 | UC-17, UC-18, UC-20, UC-21 | RF-060 a RF-065 |

## 9. Decisões pendentes

| Decisão | Efeito |
| --- | --- |
| DF-02 | Delegação, auto-aprovação e modelos de cargo propostos |
| PN-08 | Aprovadores e escalonamento |
| PN-09 | Quem recebe PERM-24 |
| DN-09 | Separação de PERM-30 e PERM-31 |
| — | Códigos das permissões novas, a confirmar pela equipa técnica antes da implementação |

## 10. Aprovação e referências

O proprietário do processo aprova o catálogo e os modelos de cargo; segurança valida §5 e §6; o responsável de dados valida PERM-14, PERM-16, PERM-26 e PERM-32. Cada aprovação deve identificar nome, versão e data. Estado de aprovação desta versão: **pendente**.

- [Índice da documentação](README.MD).
- [Requisitos Funcionais §3](02-Requisitos-Funcionais.md), [Gestão de Utilizadores e Perfis](14-Gestao-de-Utilizadores-e-Perfis.md), [APIs](10-Especificacao-de-APIs.md), [Gestão Multi-Tenant](13-Gestao-Multi-Tenant.md).
