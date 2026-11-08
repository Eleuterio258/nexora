# Gestão Multi-Tenant — Sistema de Gestão de Assiduidade

## 1. Controlo do documento

| Campo | Valor |
| --- | --- |
| Referência | TEN-ASS-001 |
| Versão | 0.3 |
| Data | 25/09/2026 |
| Estado | Rascunho técnico para validação |
| Responsáveis | Equipa técnica e segurança, com validação de negócio, operação e responsável de dados — nomes a designar |
| Base documental | BR-01, BR-F-001 a BR-F-006, BR-NF-006; RF-001 a RF-005, RF-008; RN-001, RN-002; RNF-005, RNF-013, RNF-037; UC-07; [TDD](08-Documento-de-Design-Tecnico-TDD.md) MEC-01 |

| Versão | Data | Alteração |
| --- | --- | --- |
| 0.1 | 25/09/2026 | Princípios de isolamento em resumo |
| 0.2 | 25/09/2026 | Versão detalhada: modelo de tenancy, isolamento por superfície, ciclo de vida, configuração, suporte, equidade de recursos e testes |
| 0.3 | 25/09/2026 | Terminologia de autorização alinhada com permissões granulares `módulo:acção` e âmbito ([Requisitos Funcionais §3](02-Requisitos-Funcionais.md)) |

## 2. Objectivo, âmbito e convenções

O tenant é a fronteira primária de segurança e de dados (FC-03). Este documento especifica como cada organização é isolada das restantes em todas as superfícies do sistema, como é criada, configurada, suspensa e encerrada, e como a administração transversal é limitada.

Convenções: **TEN-xx** identifica requisitos, com prioridade herdada do RF de origem.

## 3. Modelo de tenancy

| Aspecto | Proposta | Decisão |
| --- | --- | --- |
| Base de dados | Partilhada, com `tenant_id` obrigatório em todas as tabelas de negócio | DT-04 |
| Barreira primária | Filtro obrigatório na camada de persistência, a partir do contexto resolvido no servidor (MEC-01) | — |
| Barreira secundária | Row-Level Security na base, activada pelo contexto da sessão de base de dados | DT-04 |
| Ficheiros | Prefixo por tenant e chave de cifragem por tenant ou por classe | DT-10 |
| Biometria | Armazenamento separado (CNT-09), com tenant em cada referência | DF-04 |
| Estrutura interna | Tenant → unidades organizacionais hierárquicas (unidade, local, departamento, equipa) | RF-004 |

Um grupo empresarial com várias organizações pode ser modelado como vários tenants ou como um tenant com várias unidades. A escolha depende de as organizações partilharem políticas, administradores e relatórios; deve ser decidida por cliente no onboarding e não pode ser alterada sem migração.

## 4. Resolução do contexto

| ID | Requisito | Prioridade | Critério de aceitação | Origem |
| --- | --- | --- | --- | --- |
| TEN-01 | Determinar o tenant a partir da credencial validada no servidor (sessão, dispositivo, integração ou tarefa) | E | Um `tenant_id` enviado no corpo ou em cabeçalho não altera o contexto | RF-002, RN-002 |
| TEN-02 | Para contas com acesso a vários tenants, exigir selecção explícita e validá-la contra as vinculações activas da conta | E | Selecção de tenant não atribuído é recusada com `NAO_ENCONTRADO` | RF-007 |
| TEN-03 | Propagar o tenant a mensagens, tarefas e integrações e recusar qualquer processamento sem contexto | E | Mensagem sem tenant vai para erro e gera alerta | MEC-08 |
| TEN-04 | Nunca mudar de tenant a meio de uma operação | E | Teste de pedido com objectos de dois tenants é recusado integralmente | RN-001 |
| TEN-05 | Responder a objectos de outro tenant como inexistentes | E | Identificador válido de outro tenant devolve `NAO_ENCONTRADO`, sem diferença de tempo de resposta significativa | RF-002 |

## 5. Isolamento por superfície

| Superfície | Controlo | Verificação |
| --- | --- | --- |
| Base transaccional | Filtro obrigatório e Row-Level Security (DT-04); chaves estrangeiras compostas (RI-01) | CA-01 por endpoint; consulta sem contexto devolve zero linhas |
| Caches | Chave de cache inclui o tenant; nenhuma cache partilhada guarda dados de negócio sem tenant | Teste com dois tenants e o mesmo identificador lógico |
| Ficheiros (anexos, exportações) | Prefixo e chave por tenant; URLs de descarga assinadas, curtas e ligadas ao actor | URL de um tenant não funciona noutra sessão |
| Filas e tarefas | Tenant no envelope (MEC-08); consumidores validam contexto | Mensagem manipulada com outro tenant é recusada |
| Relatórios e exportações | Âmbito revalidado na execução, incluindo agendados (RF-055) | CA-09 |
| Pesquisa e listas | Filtros nunca alargam o âmbito | Filtro por `tenant` em pedido é ignorado ou recusado |
| Métricas e logs | Tenant como etiqueta técnica; sem dados de negócio | Painel de um tenant não mostra dados de outro |
| Auditoria | Consulta limitada ao tenant do auditor, excepto auditoria da plataforma | Auditor de tenant A não vê eventos de B |
| Terminais | Credencial ligada a um tenant e local | Terminal de A não submete eventos para colaboradores de B |
| Integrações | Credencial e configuração por tenant e ambiente | Execução não lê nem escreve noutro tenant |
| Biometria | Referência e template com tenant; comparação 1:N limitada ao tenant e local | Template de B nunca é candidato em A |
| Cópias e restauros | Restauro selectivo por tenant não mistura dados; reaplicação de decisões (RN-048) | Exercício de restauro com dois tenants |

| ID | Requisito | Prioridade | Critério de aceitação | Origem |
| --- | --- | --- | --- | --- |
| TEN-06 | Aplicar os controlos da tabela acima a todas as superfícies | E | Matriz de testes negativos aprovada por superfície | RNF-013 |
| TEN-07 | Tornar a falta de contexto de tenant numa falha fechada, nunca numa consulta global | E | Revisão de código e testes automáticos verificam cada consulta nova | RT-04 |

## 6. Ciclo de vida do tenant

Estados de DG-ES-09: `criado`, `activo`, `suspenso`, `desactivado`.

| ID | Requisito | Prioridade | Critério de aceitação | Origem |
| --- | --- | --- | --- | --- |
| TEN-08 | Criar tenant com identificação, fuso, idioma, administrador inicial e parâmetros mínimos; activar só depois de configurado | E | Tenant `criado` não aceita marcações | RF-001, RF-003 |
| TEN-09 | Suspender com motivo: bloqueia novas operações de negócio, preserva histórico e mantém acesso de consulta e recuperação autorizados | E | Marcações e pedidos devolvem `TENANT_SUSPENSO`; eventos capturados antes seguem RN-015 | RF-001 |
| TEN-10 | Reactivar tenant suspenso com motivo | E | Operações retomam; auditoria regista a reactivação | DG-ES-09 |
| TEN-11 | Desactivar com motivo, após exportação dos dados autorizados e plano de retenção | E | Tenant desactivado não autentica utilizadores nem dispositivos; retenção aplica-se aos dados | RF-001, RF-062 |
| TEN-12 | Exportar os dados autorizados do tenant num formato documentado | D | Exportação reconcilia contagens e totais com a origem | RNF-037 |
| TEN-13 | Revogar credenciais de dispositivos e integrações ao suspender ou desactivar, conforme a política | E | Terminais recebem a revogação (MEC-11) | RF-019 |

## 7. Configuração por tenant

| Configuração | Âmbito possível | Referência |
| --- | --- | --- |
| Fuso horário e idioma | Tenant, local | RF-003, MEC-04 |
| Calendários e feriados | Tenant, unidade, grupo | RF-015 |
| Horários e políticas | Tenant, unidade, equipa, colaborador — com precedência aprovada | RF-014 a RF-017, PN-01 |
| Métodos de marcação | Tenant, local, terminal, colaborador | RF-032, DF-01 |
| Validade offline e limites da fila | Tenant, terminal | DF-03 |
| Retenção | Tenant, categoria | RF-062, DF-08 |
| Integrações | Tenant, ambiente | RF-056 |
| Limites de utilização | Tenant | §9 |

A configuração de um tenant nunca afasta controlos de plataforma: isolamento, auditoria, segregação de funções e preservação da evidência (RN §2).

## 8. Administração da plataforma e suporte

| ID | Requisito | Prioridade | Critério de aceitação | Origem |
| --- | --- | --- | --- | --- |
| TEN-14 | O administrador da plataforma gere o ciclo de vida dos tenants sem acesso automático aos dados de negócio | E | Conta de plataforma sem autorização de suporte não lê colaboradores nem eventos | RF-008 |
| TEN-15 | Acesso de suporte exige autorização com finalidade, âmbito, validade e operador, concedida por quem tenha `seguranca:autorizar_suporte` no tenant ou por procedimento aprovado | E | Fora da autorização, o acesso é recusado; dentro, cada acção é auditada com a referência da autorização | RF-008 |
| TEN-16 | Autorizações de suporte expiram automaticamente e podem ser revogadas | E | Após expiração, a sessão de suporte perde o acesso na operação seguinte | RF-008 |
| TEN-17 | O tenant pode consultar os acessos de suporte que lhe foram feitos | D | Relatório de acessos de suporte por período | RF-060 |

## 9. Equidade de recursos

| ID | Requisito | Prioridade | Critério de aceitação | Origem |
| --- | --- | --- | --- | --- |
| TEN-18 | Limites de pedidos, de lotes e de exportações por tenant | E | Um tenant acima do limite recebe `LIMITE_EXCEDIDO`; os restantes mantêm os objectivos | RNF-005 |
| TEN-19 | Filas de processamento com partição ou prioridade que impeça um tenant de bloquear os outros | E | Teste de sobrecarga de um tenant não aumenta a latência dos restantes acima do aprovado | RNF-005 |
| TEN-20 | Tarefas pesadas (relatórios, recálculos em massa) em janelas ou filas próprias | E | Recálculo de um tenant grande não atrasa marcações de outro | RNF-003 |

## 10. Testes de isolamento

A validação mínima usa pelo menos dois tenants com identificadores lógicos coincidentes (mesmo número de colaborador, mesmo nome de unidade) e cobre: cada endpoint do [documento 10](10-Especificacao-de-APIs.md) com identificadores do outro tenant; listas e filtros; ficheiros e URLs assinadas; mensagens manipuladas; tarefas agendadas; relatórios agendados após revogação (CA-09); comparação biométrica 1:N; restauro. Os resultados alimentam a RTM para BR-01 e RNF-013.

## 11. Situação actual

No Nexora ERP observado em 25/09/2026, as tabelas de assiduidade têm `tenant_id` e as rotas `/api/rh` exigem a funcionalidade `rh.assiduidade` activa para o tenant. Não foi verificado se existe Row-Level Security activa nem como é resolvido o tenant nos pedidos de dispositivos por chave de API. Ambos devem ser confirmados no âmbito de DT-01, DT-04 e DT-05.

## 12. Rastreabilidade

| Requisitos | RF | RN / RNF | Casos de uso |
| --- | --- | --- | --- |
| TEN-01 a TEN-07 | RF-002, RF-007 | RN-001, RN-002; RNF-013 | Todos |
| TEN-08 a TEN-13 | RF-001, RF-003, RF-019, RF-062 | RN-015; RNF-037 | UC-07 |
| TEN-14 a TEN-17 | RF-008, RF-060 | RN-002 | UC-08, UC-17 |
| TEN-18 a TEN-20 | — | RNF-003, RNF-005 | UC-20 |

## 13. Decisões pendentes

| Decisão | Efeito |
| --- | --- |
| DT-04 | Mecanismo de isolamento na base |
| DT-10 | Chaves por tenant ou por classe de dados |
| DF-02 | Contas com acesso a vários tenants e selecção |
| DF-03 | Tratamento de eventos após suspensão |
| DF-08 | Retenção após desactivação |
| DN-01 | Limites e quotas por tenant |

## 14. Aprovação e referências

Segurança valida §3 a §5 e §8; negócio e operação validam §6, §7 e §9; o responsável de dados valida exportação, desactivação e suporte. Cada aprovação deve identificar nome, versão e data. Estado de aprovação desta versão: **pendente**.

- [Índice da documentação](README.MD).
- [TDD](08-Documento-de-Design-Tecnico-TDD.md) MEC-01; [Arquitectura](07-Arquitectura-do-Sistema.md) FC-03 e FC-06; [Modelo de Dados](09-Modelo-de-Dados.md) RI-01.
