# Requisitos Funcionais — Sistema de Gestão de Assiduidade

## 1. Controlo do documento

| Campo | Valor |
| --- | --- |
| Referência | RF-ASS-001 |
| Versão | 0.6 |
| Data | 25/09/2026 |
| Estado | Rascunho para validação |
| Responsáveis pela validação | RH, responsável de negócio e responsável técnico — nomes a designar |
| Base de negócio | [BRD resumido](01-BRD.md) e [BRD detalhado](BRD_Sistema_Gestao_Assiduidade.md) |

| Versão | Data | Alteração |
| --- | --- | --- |
| 0.1 | 25/09/2026 | Catálogo RF-001 a RF-065, estados, cenários de aceitação e decisões DF |
| 0.2 | 25/09/2026 | Correcções na origem pedidas pelos documentos 06, 09, 14 e 37: actores PRF-09 e PRF-10 (§3); tratamento de reenvio, conflito e duplicado no evento central (DU-02); nova versão de pedido (DU-04); interrupção da validação do período (DU-06); estados de tenant, colaborador, dispositivo e conta (DU-07); referências actualizadas (§10) |
| 0.3 | 25/09/2026 | Nova secção 4.11 com o estado de implementação observado de RF-001 a RF-065, a partir dos documentos 38 e 39 |
| 0.4 | 25/09/2026 | §3 reescrito para o modelo de permissões granulares `módulo:acção`: os actores passam a papéis funcionais, com correspondência às permissões existentes, âmbito global, hierárquico ou próprio e lacunas de granularidade; RF-012 actualizado em 4.11 |
| 0.5 | 25/09/2026 | §3 reorganizado como modelo de autorização, papéis funcionais e catálogo de permissões `módulo:acção` (existentes e novas); a coluna "Actor" do §4 passa a "Permissão" |
| 0.6 | 25/09/2026 | Retirada a tabela de papéis funcionais com permissões fixas, incompatível com permissões granulares; as regras sobre cargos e segregação passam para §3.1; catálogo passa a §3.2 e condições comuns a §3.3; critérios de RF-043, RF-051, RF-054, RF-060, o §6 e CA-09 reescritos em termos de permissão e âmbito |

## 2. Objectivo e convenções

Este documento especifica o comportamento esperado do sistema de assiduidade para orientar desenho, implementação e testes. Os requisitos das secções 4.1 a 4.10 não descrevem a implementação; a secção 4.11 regista, à parte, o estado observado no código em 25/09/2026, sem alterar nenhum requisito. Os identificadores RF são estáveis e devem ser utilizados nos casos de uso, tarefas e evidências de teste.

Cada linha do catálogo define um requisito, a permissão que o autoriza (§3.2), a prioridade proposta e um critério de aceitação mínimo. **E — Essencial**, **D — Desejável** e **O — Opcional** correspondem, respectivamente, a Must, Should e Could no BRD detalhado. A aprovação do âmbito da primeira entrega permanece pendente.

O BRD resumido classifica métodos alternativos como desejáveis; o detalhado exige os métodos activados e uma alternativa autorizada. Esta versão propõe como essencial o procedimento de contingência, mantendo QR Code, NFC, impressão digital e GPS dependentes da selecção de métodos e equipamentos. Essa divergência deve ser resolvida na decisão DF-01 antes da aprovação da primeira entrega.

Valores de tolerância, prazos, limites biométricos e fórmulas pertencem às Regras de Negócio. Metas de desempenho, disponibilidade, cifragem e capacidade pertencem aos Requisitos Não Funcionais. Aqui são definidos os comportamentos observáveis e as funções que suportam esses compromissos.

## 3. Permissões e condições comuns

### 3.1. Modelo de autorização

O sistema não autoriza por actor nem por perfil fixo. Cada operação exige uma **permissão granular** no formato `módulo:acção` (por exemplo `assiduidade:aprovar_correcao`), verificada no servidor em cada pedido, e um **âmbito** que determina sobre que colaboradores a permissão actua.

As permissões efectivas de um utilizador são a união de:

1. as permissões do **cargo** da sua vinculação ao tenant — os cargos são conjuntos de permissões editáveis por cada tenant;
2. as **permissões directas** atribuídas ao utilizador;
3. as **permissões por tipo de utilizador** — o tipo `funcionario` recebe por defeito as permissões de self-service.

Ficam excluídas as permissões de módulos desactivados para o tenant. O tipo `superadmin` é tratado à parte (RF-001, RF-008).

| Âmbito | Regra |
| --- | --- |
| Próprio | A operação incide sobre o próprio utilizador (self-service) |
| Hierárquico | O utilizador é responsável da unidade do colaborador ou de uma unidade ascendente |
| Global no tenant | O utilizador tem `recursos-humanos:gerir_funcionarios` (consulta: `recursos-humanos:ver_funcionarios`) |

Terminais, integrações e o serviço biométrico não são utilizadores: autenticam-se com credencial própria (de dispositivo ou de serviço) e só acedem aos endpoints previstos para essa credencial ([10 §3.1](10-Especificacao-de-APIs.md)).

Não existem papéis nem perfis predefinidos. Cada tenant compõe os seus cargos a partir do catálogo do §3.2, e qualquer combinação de permissões é válida. Por isso:

- nenhum requisito, regra ou teste depende do nome de um cargo; depende apenas da permissão e do âmbito;
- nos casos de uso e diagramas (documentos 05 e 06), designações como "Colaborador", "RH" ou "Chefia" lêem-se como "utilizador com a permissão exigida pelo passo, no âmbito aplicável";
- a segregação de funções (SDF do [documento 14](14-Gestao-de-Utilizadores-e-Perfis.md)) é verificada sobre **pessoas e objectos** — quem pediu, quem decide e sobre quem — e não sobre cargos, porque o mesmo utilizador pode ter permissões de requerente e de decisor.

### 3.2. Catálogo de permissões de assiduidade

**Existente** — o código já é verificado nas rotas do ERP em 25/09/2026. **Nova** — tem de ser criada para separar a operação; enquanto não existir, a operação está coberta pela permissão indicada em "Situação actual". A coluna PERM liga ao [documento 15](15-Matriz-de-Permissoes-e-Acessos.md).

| Permissão | Estado | Operação | Requisitos | PERM | Situação actual |
| --- | --- | --- | --- | --- | --- |
| `autorizacao:gerir_utilizadores` | Existente | Contas, atribuições e estado | RF-007, RF-011 | PERM-03 | — |
| `autorizacao:gerir_perfis` | Existente | Cargos e respectivas permissões | RF-007 | PERM-03 | — |
| `seguranca:autorizar_suporte` | Nova | Conceder e revogar acesso de suporte | RF-008 | PERM-04 | O `superadmin` acede sem autorização |
| `sistema-configuracao:editar_configuracoes` | Existente | Configuração do tenant | RF-003 | PERM-02 | — |
| `recursos-humanos:ver_funcionarios` | Existente | Consulta de colaboradores e resultados no âmbito | RF-051 | PERM-21 | — |
| `recursos-humanos:gerir_funcionarios` | Existente | Cadastro, estrutura, associações e credenciais QR/NFC/PIN | RF-004, RF-005, RF-009 a RF-012, RF-041 | PERM-02, PERM-05 | Cobre hoje também marcação assistida, enrollment, consentimentos e remoção de presenças |
| `recursos-humanos:importar_funcionarios` | Nova | Importação em lote | RF-013 | PERM-06 | Não existe importação |
| `recursos-humanos:gerir_horarios` | Existente | Horários, turnos, calendários e feriados | RF-010, RF-014, RF-015 | PERM-07 | — |
| `recursos-humanos:aprovar_ausencias` | Existente | Decidir ausências | RF-043, RF-045 | PERM-19 | Hoje também cria ausências (contra SDF-02) |
| `recursos-humanos:ver_relatorios` | Existente | Relatórios de RH e assiduidade | RF-052 | PERM-25 | Existe nos cargos; a rota verifica `ver_funcionarios` |
| `assiduidade:ver_assiduidade` | Existente | Consulta própria | RF-051 | PERM-20 | — |
| `assiduidade:marcar_ponto` | Existente | Marcação própria na aplicação | RF-021, RF-028 a RF-031 | PERM-10 | — |
| `assiduidade:justificar` | Existente | Justificação própria | RF-042 | PERM-17 | — |
| `assiduidade:corrigir_ponto` | Existente | Pedido de correcção próprio | RF-046 | PERM-17 | — |
| `pedido-ferias:ver_pedidos`, `pedido-ferias:submeter_pedido` | Existente | Pedidos de férias próprios e cancelamento | RF-042, RF-045 | PERM-17 | — |
| `pedido-ferias:aprovar` | Existente | Decidir pedidos de férias | RF-043 | PERM-19 | — |
| `assiduidade:submeter_em_nome` | Nova | Pedidos de correcção e ausência em nome de colaboradores | RF-042, RF-046 | PERM-18 | `gerir_funcionarios` / `aprovar_ausencias` |
| `assiduidade:aprovar_correcao` | Existente | Decidir correcções e justificações | RF-043, RF-047 | PERM-19 | — |
| `assiduidade:ver_configuracao`, `assiduidade:gerir_configuracao` | Existente | Tipos de evento, métodos, regras e políticas em rascunho | RF-016 a RF-018, RF-032 | PERM-07 | — |
| `assiduidade:activar_politica` | Nova | Activar versão de política | RF-016 | PERM-08 | `gerir_configuracao` |
| `assiduidade:marcar_assistido` | Nova | Marcação assistida com motivo | RF-027 | PERM-12 | `gerir_funcionarios` |
| `assiduidade:resolver_pendencias` | Nova | Aceitar, rejeitar ou classificar eventos pendentes | RF-024 | PERM-13 | Não existe fluxo de pendências |
| `assiduidade:gerir_habilitacao_biometrica` | Nova | Habilitação e consentimento biométrico | RF-061 | PERM-14 | `gerir_funcionarios` |
| `assiduidade:gerir_biometria` | Nova | Enrollment, suspensão, substituição e eliminação de referências | RF-033, RF-036 | PERM-15 | `gerir_funcionarios` |
| `assiduidade:configurar_limiar_biometrico` | Nova | Limiar biométrico | RF-035 | PERM-16 | Variável de ambiente do serviço biométrico |
| `assiduidade:recalcular` | Nova | Recálculo manual com motivo | RF-039 | PERM-22 | `gerir_funcionarios` |
| `assiduidade:aprovar_horas` | Nova | Decidir horas elegíveis e extraordinárias | RF-040 | PERM-22 | Não existe |
| `assiduidade:fechar_periodo` | Nova | Validar e fechar período | RF-048, RF-049 | PERM-23 | Não existe fecho |
| `assiduidade:reabrir_periodo` | Nova | Reabrir período, com autenticação reforçada | RF-050 | PERM-24 | Não existe |
| `assiduidade:exportar` | Nova | Exportação com finalidade e campos | RF-053 | PERM-26 | Não existe |
| `assiduidade:agendar_relatorios` | Nova | Relatórios agendados | RF-055 | PERM-27 | Não existe |
| `assiduidade:gerir_integracao` | Nova | Configurar integrações | RF-056 | PERM-28 | Não existe |
| `assiduidade:executar_integracao` | Nova | Executar, consultar e reprocessar integrações | RF-058, RF-059 | PERM-29 | Não existe |
| `auditoria:ver_logs` | Existente | Consulta de auditoria | RF-060 | PERM-30, PERM-31 | O cargo padrão de auditor inclui também `auditoria:gerir_logs` (escrita) |
| `assiduidade:gerir_retencao` | Nova | Retenção, eliminação e anonimização | RF-062 | PERM-32 | Não existe |
| `hardware:ver_dispositivos`, `hardware:ver_eventos` | Existente | Estado de terminais e eventos | RF-063 | PERM-33 | — |
| `hardware:gerir_dispositivos` | Existente | Registo, activação, revogação e configuração de terminais | RF-019, RF-020 | PERM-09 | — |
| `hardware:gerir_eventos` | Existente | Reprocessamento de eventos de dispositivos | RF-026 | PERM-33 | — |
| `assiduidade:gerir_alertas` | Nova | Regras de alerta operacional | RF-064 | PERM-34 | Não existe |

Credenciais que não são permissões de utilizador: **credencial de dispositivo** (RF-020 a RF-026, RF-028 a RF-030, PERM-11), **credencial de integração** (RF-057) e **credencial de serviço** do serviço biométrico, com as permissões `biometric:*`, `liveness:*`, `fingerprint:*` e `audit:read`.

### 3.3. Condições comuns

Todos os requisitos estão sujeitos às seguintes condições:

- A autorização deve ser verificada no serviço que executa a operação, incluindo pedidos directos à API, relatórios e tarefas automáticas.
- A autorização combina permissão, tenant e âmbito (§3.1). Um identificador recebido do cliente não concede acesso.
- Falhas de validação devem explicar o problema sem expor dados de terceiros e sem produzir alterações parciais não identificadas.
- Operações críticas devem gerar a evidência definida em RF-060; registos de origem não podem ser substituídos silenciosamente.
- Dados mínimos, estados e transições abaixo são propostas funcionais, não contratos definitivos de API ou de base de dados.

## 4. Catálogo de requisitos funcionais

### 4.1. Organizações, identidade e acessos

| ID | Permissão | Requisito funcional | Prioridade | Critério de aceitação |
| --- | --- | --- | --- | --- |
| RF-001 | Tipo `superadmin` | Criar, activar, suspender e desactivar tenants, registando motivo e data das mudanças de estado. | E | Tenant suspenso não admite novas operações de negócio; histórico permanece disponível a quem tenha permissão de consulta. Eventos previamente capturados seguem RF-026. |
| RF-002 | Transversal | Restringir leitura, escrita, pesquisa, anexos, exportações e tarefas ao tenant autorizado. | E | Utilizador ou dispositivo do tenant A não consegue consultar nem alterar um objecto do tenant B, mesmo indicando directamente o seu identificador. |
| RF-003 | `sistema-configuracao:editar_configuracoes` | Configurar identificação, idioma, fuso horário e parâmetros operacionais da organização. | E | Valores inválidos são recusados; consultas apresentam datas no fuso configurado e preservam o instante original. |
| RF-004 | `recursos-humanos:gerir_funcionarios` | Gerir unidades, locais, departamentos e equipas, associando colaboradores, terminais e políticas. | E | Relação com outra organização ou hierarquia circular é recusada; desactivação preserva referências históricas. |
| RF-005 | `recursos-humanos:gerir_funcionarios` | Agendar mudanças de estrutura e conservar as respectivas vigências. | D | Consulta de uma data anterior mantém a associação que vigorava nessa data. |
| RF-006 | Sessão autenticada | Autenticar-se, terminar sessão e recuperar acesso pelo mecanismo aprovado. | E | Credenciais inválidas não abrem sessão; sessão terminada ou conta suspensa não permite nova operação autenticada. O método de recuperação depende de DF-02. |
| RF-007 | `autorizacao:gerir_utilizadores`, `autorizacao:gerir_perfis` | Compor cargos a partir do catálogo de permissões, atribuir e revogar cargos e permissões directas, e definir o âmbito de equipa ou unidade. | E | Após revogação, uma nova tentativa de operação protegida é recusada, incluindo acesso directo pela API. |
| RF-008 | `seguranca:autorizar_suporte` | Registar acessos de suporte a um tenant com finalidade, âmbito e validade explícitos. | E | Fora da autorização válida, o suporte não consulta dados de negócio; acesso permitido identifica operador, tenant e motivo em auditoria. |

### 4.2. Colaboradores e identificadores

| ID | Permissão | Requisito funcional | Prioridade | Critério de aceitação |
| --- | --- | --- | --- | --- |
| RF-009 | `recursos-humanos:gerir_funcionarios` | Criar, consultar, actualizar, suspender e terminar o vínculo de um colaborador, com identificador único no tenant. | E | Duplicação do identificador no mesmo tenant é recusada; término do vínculo não elimina marcações anteriores. |
| RF-010 | `recursos-humanos:gerir_funcionarios`, `recursos-humanos:gerir_horarios` | Manter unidade, departamento, equipa, função, horário, estado e respectivas vigências relevantes ao cálculo. | E | Alteração de horário não modifica silenciosamente a associação utilizada num período já fechado. |
| RF-011 | `recursos-humanos:gerir_funcionarios`, `autorizacao:gerir_utilizadores` | Distinguir cadastro do colaborador de conta de acesso e associá-los quando necessário. | E | Colaborador sem acesso ao backoffice pode marcar num terminal autorizado; conta comum não obtém permissões de RH por estar ligada ao cadastro. |
| RF-012 | `recursos-humanos:gerir_funcionarios` | Associar e revogar métodos de identificação e designar responsáveis de unidade e aprovadores. | E | Credencial revogada deixa de identificar o colaborador após aplicação da revogação; pedido é encaminhado ao aprovador vigente no seu âmbito. |
| RF-013 | `recursos-humanos:importar_funcionarios`; credencial de integração | Importar colaboradores com validação prévia e resultado por linha. | E | Importação informa aceites e erros com motivo; repetição do mesmo lote não cria colaboradores duplicados. |

### 4.3. Calendários, horários e regras

| ID | Permissão | Requisito funcional | Prioridade | Critério de aceitação |
| --- | --- | --- | --- | --- |
| RF-014 | `recursos-humanos:gerir_horarios` | Configurar horários fixos, flexíveis e escalas por turnos, incluindo turnos que atravessam a meia-noite. | E | Entrada às 22:00 e saída às 06:00 são associadas ao turno correcto, sem falta artificial na mudança de dia. |
| RF-015 | `recursos-humanos:gerir_horarios` | Definir calendários, dias úteis, feriados e excepções por âmbito organizacional. | E | Feriado local afecta apenas os colaboradores abrangidos; conflito de calendários exige precedência explícita. |
| RF-016 | `assiduidade:gerir_configuracao`, `assiduidade:activar_politica` | Versionar períodos de trabalho, pausas, tolerâncias e regras de atrasos, faltas, saídas antecipadas e horas extraordinárias. | E | Um apuramento identifica a versão aplicada; configuração inválida é recusada antes da activação. |
| RF-017 | `assiduidade:gerir_configuracao` | Configurar arredondamento autorizado e agendar alterações futuras de horários ou políticas. | D | A nova versão só se aplica na vigência indicada e não altera resultados fechados. |
| RF-018 | `assiduidade:gerir_configuracao` | Simular uma política com dados seleccionados antes de a activar. | O | Simulação mostra diferenças face à política vigente sem alterar marcações, apuramentos oficiais ou exportações. |

### 4.4. Terminais e marcações

| ID | Permissão | Requisito funcional | Prioridade | Critério de aceitação |
| --- | --- | --- | --- | --- |
| RF-019 | `hardware:gerir_dispositivos` | Registar, associar a local, activar e revogar terminais e credenciais de dispositivo. | E | Dispositivo desconhecido ou revogado não cria marcações aceites pelo serviço central. |
| RF-020 | `hardware:gerir_dispositivos`; credencial de dispositivo | Distribuir configuração autorizada de métodos e políticas e apresentar a versão aplicada no terminal. | E | Terminal confirma a aplicação da versão; falha mantém a versão anterior identificada e gera pendência visível. |
| RF-021 | `assiduidade:marcar_ponto` ou credencial de dispositivo | Registar entrada, saída, início de pausa e fim de pausa com identidade validada pelo método autorizado. | E | Evento válido conserva os dados mínimos da secção 5 e fica consultável; colaborador inactivo não gera marcação aceite automática. |
| RF-022 | `assiduidade:marcar_ponto` ou credencial de dispositivo | Apresentar resultado de marcação aceite, rejeitada ou guardada localmente à espera de sincronização. | E | Sem ligação, a mensagem indica pendência; falha ao guardar localmente não apresenta confirmação de sucesso. |
| RF-023 | Sistema | Detectar reenvios do mesmo evento e possíveis duplicações dentro da janela configurada. | E | Reenvio do mesmo identificador devolve o resultado existente; eventos distintos próximos são sinalizados segundo a regra, sem apagar a evidência. |
| RF-024 | Sistema; `assiduidade:resolver_pendencias` | Identificar sequência incompleta, eventos fora de ordem e diferenças de hora suspeitas. | E | Saída sem entrada e hora fora do limite acordado geram ocorrência com motivo; horas de origem e recepção permanecem distintas. |
| RF-025 | Credencial de dispositivo | Manter fila local de eventos durante indisponibilidade e retomá-la após reinício. | E | Após interrupção e reinício, eventos guardados permanecem pendentes; limite de capacidade produz indicação de falha, sem descartar eventos silenciosamente. |
| RF-026 | Credencial de dispositivo | Sincronizar com resultado individual, reenvio controlado e reconciliação de conflitos. | E | Perda de resposta após recepção não duplica o evento no reenvio; apenas itens confirmados saem da fila pendente. Eventos anteriores a suspensão ou revogação ficam sujeitos à decisão DF-03. |
| RF-027 | `assiduidade:marcar_assistido` | Disponibilizar procedimento alternativo quando o método primário falha ou não está autorizado. | E | Falha facial encaminha para alternativa autorizada ou pedido assistido auditado, sem marcar automaticamente falta nem contornar validação de identidade. |
| RF-028 | `assiduidade:marcar_ponto` ou credencial de dispositivo | Identificar por QR Code quando seleccionado e activado para o contexto. | D | Código válido identifica apenas o colaborador e âmbito autorizados; código expirado, revogado ou reutilizado contra a política é recusado. |
| RF-029 | `assiduidade:marcar_ponto` ou credencial de dispositivo | Identificar por NFC quando seleccionado, permitindo associar e revogar a credencial. | D | Credencial activa funciona apenas no âmbito autorizado; credencial revogada é recusada após aplicação da revogação. |
| RF-030 | Credencial de dispositivo | Identificar por impressão digital nos equipamentos aprovados. | D | Identificação válida produz evento com o método correcto; falha do leitor encaminha para RF-027. |
| RF-031 | `assiduidade:marcar_ponto` | Recolher localização no momento da marcação quando a política a exigir. | D | Registo inclui instante e precisão disponíveis; localização indisponível ou fora da área segue rejeição ou análise configurada, sem recolha contínua. |

### 4.5. Reconhecimento facial e biometria

| ID | Permissão | Requisito funcional | Prioridade | Critério de aceitação |
| --- | --- | --- | --- | --- |
| RF-032 | `assiduidade:gerir_configuracao` | Activar reconhecimento facial por tenant, local, terminal e colaborador habilitado. | E | Método desactivado num dos âmbitos aplicáveis não autoriza uma nova marcação facial nesse contexto. |
| RF-033 | `assiduidade:gerir_biometria` | Executar enrollment com autenticação do operador, confirmação de identidade e validação de qualidade. | E | Falha de captura ou qualidade não activa template incompleto; sucesso regista colaborador, operador, versão e data. |
| RF-034 | Sistema (serviço biométrico) | Validar correspondência facial e prova de vida de acordo com o componente e a política aprovados. | E | Falha de correspondência, prova de vida ou indisponibilidade não aceita automaticamente a marcação; ensaios utilizam critérios biométricos acordados em DF-04. |
| RF-035 | `assiduidade:configurar_limiar_biometrico` | Configurar limiar de reconhecimento dentro dos limites aprovados e registar a versão aplicada. | E | Valor fora do intervalo aprovado é recusado; evento permite identificar a versão da configuração e do algoritmo usados. |
| RF-036 | `assiduidade:gerir_biometria` | Suspender, substituir e eliminar templates, acompanhando a propagação aos dispositivos autorizados. | E | Template suspenso não é utilizado onde a alteração já foi aplicada; eliminação não é apresentada como concluída enquanto houver destinos pendentes. |
| RF-037 | Sistema | Registar o resultado necessário ao reconhecimento e encaminhar falhas repetidas para alternativa. | E | Histórico normal não expõe templates ou imagens; falhas são rastreáveis e oferecem RF-027. Imagens só são conservadas mediante finalidade e política aprovadas. |

### 4.6. Apuramento, férias e ausências

| ID | Permissão | Requisito funcional | Prioridade | Critério de aceitação |
| --- | --- | --- | --- | --- |
| RF-038 | Sistema | Calcular tempo trabalhado e classificar atrasos, faltas, saídas antecipadas, pausas e horas extraordinárias. | E | Resultados coincidem com exemplos aprovados por RH, incluindo feriados, turnos nocturnos e dados incompletos; cada resultado identifica eventos e regras utilizados. |
| RF-039 | Sistema; `assiduidade:recalcular` | Recalcular períodos abertos afectados por alterações válidas, conservando versões anteriores. | E | Repetir o cálculo com as mesmas entradas não acumula horas; versão anterior e motivo do recálculo permanecem consultáveis. |
| RF-040 | `assiduidade:aprovar_horas` | Distinguir ocorrências calculadas, justificadas, corrigidas e aprovadas, incluindo horas extraordinárias. | E | Horas calculadas e horas aprovadas são apresentadas separadamente e a decisão identifica aprovador e data. |
| RF-041 | `recursos-humanos:gerir_funcionarios` | Configurar tipos de ausência, documentação exigida e regras de saldo ou origem externa. | E | Pedido sem documento obrigatório não é submetido; saldo indica sistema de origem e referência de actualização. |
| RF-042 | `pedido-ferias:submeter_pedido`, `assiduidade:justificar`; em nome de outrem `assiduidade:submeter_em_nome` | Submeter férias, ausências e justificações por período com motivo e anexos autorizados. | E | Datas inválidas são recusadas; pedido válido fica pendente e só é consultável pelos intervenientes autorizados. |
| RF-043 | `recursos-humanos:aprovar_ausencias`, `pedido-ferias:aprovar`, `assiduidade:aprovar_correcao` | Aprovar ou rejeitar pedidos segundo a hierarquia e segregação de funções configuradas. | E | Utilizador sem a permissão de decisão ou fora do âmbito do colaborador não decide; decisões concorrentes não aplicam duas vezes o mesmo pedido; rejeição exige motivo. |
| RF-044 | Sistema | Aplicar ausências aprovadas ao apuramento e reflectir os efeitos nos saldos, conforme sistema responsável. | E | Aprovação afecta apenas o período aplicável; reprocessamento não debita novamente o saldo; integração pendente permanece identificada. |
| RF-045 | `pedido-ferias:submeter_pedido`; decisão `recursos-humanos:aprovar_ausencias` | Solicitar e decidir cancelamentos, preservando histórico e validando sobreposições incompatíveis. | D | Cancelamento autorizado reverte os efeitos uma única vez; sobreposição exige resolução explícita e não altera um período fechado. |

### 4.7. Correcções e fecho de períodos

| ID | Permissão | Requisito funcional | Prioridade | Critério de aceitação |
| --- | --- | --- | --- | --- |
| RF-046 | `assiduidade:corrigir_ponto`; em nome de outrem `assiduidade:submeter_em_nome` | Solicitar inclusão ou correcção de marcação ou resultado, indicando valor proposto e motivo. | E | Pedido sem motivo é recusado; submissão não modifica o evento original nem aplica automaticamente o ajuste. |
| RF-047 | `assiduidade:aprovar_correcao` | Decidir e aplicar correcções autorizadas como ajustes ligados ao registo original. | E | Aprovação conserva antes/depois, solicitante, decisor e motivo; decisão sobre versão já alterada exige nova validação e não sobrescreve o resultado. |
| RF-048 | `assiduidade:fechar_periodo` | Apresentar pendências e validar o âmbito antes de fechar um período. | E | Marcações pendentes, pedidos e conflitos aparecem na validação; pendência impeditiva bloqueia o fecho e excepção permitida exige justificação. |
| RF-049 | `assiduidade:fechar_periodo` | Fechar período e gerar evidência com âmbito, autor, data, versão dos resultados e regras aplicadas. | E | Tentativa de alteração posterior por interface, API ou sincronização não muda o resultado fechado; evento tardio fica pendente de tratamento. |
| RF-050 | `assiduidade:reabrir_periodo` | Reabrir período com motivo, recalcular e efectuar novo fecho com versão distinta. | E | Sem permissão ou motivo a reabertura é recusada; resultado anteriormente enviado ao ERP fica identificado como necessitando reconciliação, sem duplicar o envio efectivo. |

### 4.8. Consultas, relatórios e notificações

| ID | Permissão | Requisito funcional | Prioridade | Critério de aceitação |
| --- | --- | --- | --- | --- |
| RF-051 | `assiduidade:ver_assiduidade` (próprio); `recursos-humanos:ver_funcionarios` (âmbito) | Consultar presenças diárias, semanais e mensais, histórico próprio ou da equipa e estado dos pedidos. | E | Com âmbito próprio, o utilizador vê apenas os seus dados; com âmbito hierárquico, apenas os colaboradores das unidades de que é responsável; em ambos os casos com distinção entre resultado provisório e fechado. |
| RF-052 | `recursos-humanos:ver_relatorios` | Gerar relatórios de horas, atrasos, faltas, pausas, horas extraordinárias e excepções com filtros organizacionais e temporais. | E | Totais coincidem com o apuramento seleccionado; relatório identifica geração, filtros, âmbito e versão/origem dos resultados. |
| RF-053 | `assiduidade:exportar` | Exportar relatórios nos formatos aprovados e limitar os campos à finalidade seleccionada. | D | Ficheiro respeita filtros e permissões, não inclui biometria e gera auditoria; formatos definitivos dependem de DF-07. |
| RF-054 | Sistema | Notificar pedidos pendentes, decisões e falhas operacionais por canais autorizados. | D | Destinatário sem permissão ou fora do âmbito do colaborador não recebe dados do pedido; falha de entrega fica registada e reenvio não repete a decisão de negócio. |
| RF-055 | `assiduidade:agendar_relatorios` | Agendar relatórios para destinatários autorizados. | O | No momento de execução, permissões e destinatários são revalidados; revogação impede entrega futura. |

### 4.9. Integração com ERP

| ID | Permissão | Requisito funcional | Prioridade | Critério de aceitação |
| --- | --- | --- | --- | --- |
| RF-056 | `assiduidade:gerir_integracao` | Configurar conexão por tenant e ambiente, mapeamentos e fonte de referência por entidade, com contrato documentado. | E | Configuração não apresenta segredos em consultas ou logs; teste identifica ambiente e tenant correctos e reporta falha de ligação. |
| RF-057 | Credencial de integração | Sincronizar colaboradores, estruturas e horários respeitando a fonte de referência e vigência. | E | Alteração concorrente gera conflito segundo a política acordada; lote mostra itens aplicados e recusados, sem sobrescrever dados silenciosamente. |
| RF-058 | `assiduidade:executar_integracao` | Enviar resultados aprovados e fechados, identificando tenant, período e versão. | E | Período aberto não é enviado como definitivo; confirmação externa fica ligada à versão enviada. |
| RF-059 | `assiduidade:executar_integracao` | Consultar execuções e reconciliar sucessos, falhas e atrasos, permitindo reprocessamento idempotente. | E | Falha parcial permite repetir apenas itens necessários; timeout após recepção no ERP não causa duplicação; reconciliação mostra quantidades, totais e divergências. |

### 4.10. Auditoria, dados pessoais e operação

| ID | Permissão | Requisito funcional | Prioridade | Critério de aceitação |
| --- | --- | --- | --- | --- |
| RF-060 | `auditoria:ver_logs` | Registar e consultar autenticações, configurações, acessos sensíveis, aprovações, correcções, fechos, exportações e integrações. | E | Evidência contém actor, instante, tenant quando identificável, acção, objecto, resultado e origem; quem tem permissão de consulta de auditoria pesquisa por filtros e ninguém altera a evidência. Segredos e templates não integram o registo. |
| RF-061 | `assiduidade:gerir_habilitacao_biometrica` | Registar a habilitação ao tratamento biométrico e o consentimento quando aplicável, incluindo finalidade, versão e revogação. | E | Revogação bloqueia novos usos abrangidos após aplicação e desencadeia tratamento dos templates segundo política, preservando a opção de marcação alternativa. |
| RF-062 | `assiduidade:gerir_retencao` | Executar retenção, eliminação ou anonimização por categoria e âmbito, com acompanhamento das cópias distribuídas. | E | Dados elegíveis são tratados segundo política; impedimentos e destinos pendentes são visíveis; conclusão gera evidência sem conservar o conteúdo eliminado. |
| RF-063 | `hardware:ver_dispositivos`, `hardware:ver_eventos` | Consultar saúde dos serviços, ligação e versão dos terminais, filas pendentes e estado das integrações. | E | Interrupção simulada altera o estado e apresenta última comunicação e quantidade pendente disponível, sem expor dados pessoais desnecessários. |
| RF-064 | `assiduidade:gerir_alertas` | Emitir alertas por limiares de indisponibilidade, falhas de sincronização e crescimento de erros. | D | Ultrapassar um limiar configurado gera alerta ao destinatário autorizado; recuperação actualiza o estado do incidente. |
| RF-065 | Procedimento operacional (fora da API) | Executar e consultar cópias de segurança e restaurações segundo o plano aprovado. | E | Exercício de restauro demonstra recuperação e reconciliação de registos, isolamento dos tenants e reaplicação das eliminações/revogações posteriores à cópia antes da retoma. |

### 4.11. Estado de implementação observado

Situação observada em 25/09/2026 por leitura do código do Nexora ERP (`factPro/backend`, Go) e do serviço biométrico (este repositório, Python); os testes não foram executados. Esta tabela não altera nenhum requisito e deve migrar para a [Matriz de Rastreabilidade](33-Matriz-de-Rastreabilidade-de-Requisitos-RTM.md) quando esta for desenvolvida.

Legenda: **Implementado** — o comportamento existe e não foi encontrada lacuna face ao critério de aceitação; **Parcial** — existe, mas falha parte do critério; **Em falta** — não foi identificada implementação; **A confirmar** — depende de configuração ou de código não analisado; **Não aplicável** — o requisito não se aplica à arquitectura actual. As lacunas LAC-xx estão no [documento 38](38-Lacunas-de-Implementacao-Servico-Biometrico.md) e as LAE-xx no [documento 39](39-Lacunas-de-Implementacao-ERP-Assiduidade.md).

| ID | Prior. | Estado | Onde existe | Lacunas e observações |
| --- | :-: | --- | --- | --- |
| RF-001 | E | Parcial | ERP: suspensão e activação de tenant (superadmin) | Registo de motivo e bloqueio de marcações de tenant suspenso a confirmar |
| RF-002 | E | Parcial | ERP: tenant resolvido a partir do utilizador autenticado; serviço biométrico: filtro por tenant | LAC-14 (`tenant_id` opcional), LAC-15; Row-Level Security não verificada |
| RF-003 | E | Parcial | ERP: configuração do tenant | O fuso do tenant não é usado no cálculo de atrasos (LAE-16) |
| RF-004 | E | Parcial | ERP: `rh.unidades_organizacionais` com hierarquia e subárvore | Recusa de hierarquia circular a confirmar |
| RF-005 | D | Em falta | — | Estrutura sem vigência; o cargo e a unidade do funcionário são só os actuais |
| RF-006 | E | Parcial | ERP: sessão JWT com renovação; PIN de marcação | Recuperação de acesso e segundo factor para perfis privilegiados a confirmar |
| RF-007 | E | Parcial | ERP: permissões por módulo e acção; `podeGerirFuncionario` | Permissões demasiado agregadas ([15 §7](15-Matriz-de-Permissoes-e-Acessos.md)); âmbito por unidade parcial |
| RF-008 | E | Em falta | — | Não existe autorização de suporte com finalidade, âmbito e validade |
| RF-009 | E | Implementado | ERP: cadastro de funcionários | — |
| RF-010 | E | Parcial | ERP: `rh.funcionario_horarios` com vigência | Unidade e cargo sem vigência; alteração não protege períodos fechados (LAE-06) |
| RF-011 | E | Implementado | ERP: modelo de pessoa central, com conta e cargos distintos do cadastro | — |
| RF-012 | E | Parcial | ERP: credenciais QR, NFC e PIN; aprovação pela hierarquia (responsável da unidade ou de unidade ascendente) | Sem designação explícita de aprovador por colaborador nem delegação |
| RF-013 | E | Em falta | — | Importação de colaboradores com resultado por linha não identificada (existe apenas `batch-enroll` biométrico) |
| RF-014 | E | Parcial | ERP: horários fixos, flexíveis e por turnos, por dia da semana ou data | Turno que atravessa a meia-noite fica dividido em dois dias (LAE-03) |
| RF-015 | E | Em falta | — | Não existem calendários nem feriados |
| RF-016 | E | Parcial | ERP: regras com âmbito, vigência e prioridade | Sem versão nem aprovação; o resultado não identifica a versão aplicada (LAE-07, LAE-17) |
| RF-017 | D | Parcial | ERP: vigência futura de regras e horários | Arredondamento em falta (LAE-26) |
| RF-018 | O | Em falta | — | — |
| RF-019 | E | Parcial | ERP: registo, activação e desactivação de dispositivos, nova chave por dispositivo; serviço biométrico: chaves Ed25519 revogáveis | Reactivação de chave revogada sem registo (LAC-16); DT-05 por decidir |
| RF-020 | E | Parcial | ERP: configurações por dispositivo | Sem versão publicada nem confirmação de aplicação pelo terminal |
| RF-021 | E | Parcial | ERP: entrada, saída e pausas por tipos de evento; recusa de funcionário inactivo | Direcção inferida por paridade quando o dispositivo não a indica (LAE-23); rejeição não fica no histórico do colaborador (LAE-19) |
| RF-022 | E | A confirmar | Aplicação Android | Comportamento da aplicação não analisado nesta revisão |
| RF-023 | E | Parcial | ERP: deduplicação por hash de conteúdo; hardware com `event_hash` único | Sem identificador gerado na origem; reenvio no self-service cria segundo evento (LAE-09) |
| RF-024 | E | Parcial | ERP: estado `fora_localizacao` | Sequência incompleta ignorada (LAE-05); sem instante de recepção nem desvio de relógio (LAE-15); sem fluxo de pendências (LAE-14) |
| RF-025 | E | A confirmar | Aplicação Android | Fila local não analisada nesta revisão |
| RF-026 | E | Parcial | ERP: `POST /api/hardware/events/batch`; fila de eventos de hardware com repetição | Resultado por item sem identificador de origem (LAE-09); eventos após revogação sem tratamento próprio (LAE-19) |
| RF-027 | E | Parcial | ERP: marcação pelo gestor (`/api/rh/assiduidade/ponto`, `/api/rh/eventos`) | Motivo e origem assistida não obrigatórios ([10 §9](10-Especificacao-de-APIs.md)) |
| RF-028 | D | Implementado | ERP: QR pessoal e de dispositivo, com validação | Reutilização contra a política a confirmar |
| RF-029 | D | Parcial | ERP: etiquetas NFC associadas ao funcionário | Revogação e âmbito a confirmar |
| RF-030 | D | Parcial | Serviço biométrico: enrollment, identificação e remoção de impressão digital | Sem qualidade nem anti-spoofing; remoção física (LAC-10, LAC-11) |
| RF-031 | D | Implementado | ERP: validação de geofence no momento da marcação | Evento fora da área fica sem fluxo de decisão (LAE-14) |
| RF-032 | E | Parcial | ERP e serviço biométrico: método activo por tenant | Falha aberta (LAE-22, LAC-15); sem activação por local, terminal e colaborador |
| RF-033 | E | Parcial | Serviço biométrico: três capturas, qualidade e prova de vida | Sem verificação de habilitação; auto-enrollment permitido; enrollment repetido duplica templates (LAC-01, LAC-03, LAC-04) |
| RF-034 | E | Parcial | Serviço biométrico: comparação 1:1 e 1:N, desafio de prova de vida | Prova de vida heurística por defeito, sem ensaio (LAC-17) |
| RF-035 | E | Parcial | Serviço biométrico: limiares por variável de ambiente, calibração | Sem intervalo aprovado nem versão registada no evento (LAC-08) |
| RF-036 | E | Em falta | — | Sem suspensão, substituição nem eliminação de referência facial (LAC-02) |
| RF-037 | E | Parcial | Serviço biométrico: auditoria de tentativas | Pontuações guardadas e devolvidas; imagem da selfie guardada no ERP (LAC-05, LAE-20) |
| RF-038 | E | Parcial | ERP: motor de cálculo diário (horas, atrasos, extra, nocturnas) | Correcção não substitui o original, falta automática, dupla dedução de pausas (LAE-01 a LAE-05) |
| RF-039 | E | Parcial | ERP: recálculo diário e por pedido | Resultado sobrescrito sem versão; decisões não disparam recálculo (LAE-07, LAE-08) |
| RF-040 | E | Em falta | — | Sem separação entre horas observadas, elegíveis e aprovadas (LAE-18) |
| RF-041 | E | Parcial | ERP: tipos de ausência com indicação de saldo; saldos por funcionário | Documentos obrigatórios e origem do saldo a confirmar |
| RF-042 | E | Parcial | ERP: pedido de férias e justificações pelo colaborador | Em `/api/rh/ausencias` o colaborador não submete o próprio pedido ([10 §9](10-Especificacao-de-APIs.md)) |
| RF-043 | E | Parcial | ERP: aprovação e rejeição de ausências, correcções e justificações | Sem verificação de segregação nem versão do pedido (LAE-11, LAE-12) |
| RF-044 | E | Parcial | ERP: débito de saldo na aprovação | A aprovação não recalcula o apuramento (LAE-08) |
| RF-045 | D | Parcial | ERP: cancelamento de ausências e de pedidos de correcção | Reversão única dos efeitos a confirmar |
| RF-046 | E | Parcial | ERP: pedido de correcção com motivo, sem alterar o original | Dois modelos em paralelo (LAE-21) |
| RF-047 | E | Parcial | ERP: aprovação gera evento corrigido ligado ao original | Original continua a contar; operação não atómica; auditoria sem garantia (LAE-01, LAE-12, LAE-13) |
| RF-048 | E | Em falta | — | Sem validação de pendências antes do fecho (LAE-06) |
| RF-049 | E | Em falta | — | Sem fecho de período de assiduidade (LAE-06) |
| RF-050 | E | Em falta | — | Sem reabertura versionada (LAE-06) |
| RF-051 | E | Parcial | ERP: consulta própria (self-service) e por funcionário (RH) | Distinção entre resultado provisório e fechado inexistente (LAE-06) |
| RF-052 | E | Parcial | ERP: relatórios de RH | Totais não identificam versão dos resultados (LAE-07) |
| RF-053 | D | Parcial | ERP: exportação CSV de auditoria e de processamento salarial | Exportação de assiduidade com finalidade e campos não identificada |
| RF-054 | D | Parcial | ERP: notificações push | Notificação de pedidos pendentes e decisões de assiduidade a confirmar |
| RF-055 | O | Em falta | — | — |
| RF-056 | E | Em falta | — | Sem configuração de integração por tenant e ambiente (interna ao ERP) |
| RF-057 | E | Não aplicável | — | Assiduidade e RH partilham a base do ERP; revalidar se houver fonte externa (DF-06) |
| RF-058 | E | Em falta | — | Sem envio de períodos fechados identificados por versão (LAE-25) |
| RF-059 | E | Em falta | — | Sem execuções com reconciliação (LAE-25) |
| RF-060 | E | Parcial | ERP: auditoria de assiduidade e auditoria da plataforma com verificação de integridade; serviço biométrico: auditoria biométrica | Operações de administração biométrica sem auditoria; auditoria biométrica sem encadeamento (LAC-07, LAC-18) |
| RF-061 | E | Parcial | ERP: consentimentos (LGPD) | O enrollment não verifica o consentimento (LAC-01) |
| RF-062 | E | Em falta | — | Sem tarefas de retenção, eliminação ou anonimização (LAC-19) |
| RF-063 | E | Parcial | ERP: `ping` de dispositivos e fila de eventos de hardware; serviço biométrico: `/health`, `/ready`, `/metrics` | Painel de terminais com última comunicação e fila pendente a confirmar |
| RF-064 | D | Em falta | — | Sem regras de alerta configuráveis |
| RF-065 | E | A confirmar | Cópias de base de dados existentes no repositório do ERP | Sem procedimento de restauro com reaplicação de revogações e eliminações |

**Resumo:** dos 65 requisitos, 4 estão implementados, 41 parciais, 16 em falta, 3 a confirmar e 1 não aplicável. Dos 16 em falta, 12 são essenciais: RF-008, RF-013, RF-015, RF-036, RF-040, RF-048, RF-049, RF-050, RF-056, RF-058, RF-059 e RF-062.

## 5. Informação funcional mínima

| Objecto | Informação necessária |
| --- | --- |
| Marcação | Identificador estável, tenant, colaborador, tipo de evento, hora de origem e respectivo fuso/desvio, hora de recepção, origem, método, dispositivo/local quando aplicável, estado e motivo de rejeição ou pendência |
| Apuramento | Colaborador, intervalo, eventos e ajustes considerados, versão das regras, tempos e ocorrências, estado e versão do resultado |
| Pedido | Tipo, requerente, colaborador abrangido, período, motivo, anexos autorizados, estado, responsáveis e decisões |
| Ajuste | Referência ao pedido e registo afectado, antes/depois, motivo, autor, aprovador e instante de aplicação |
| Fecho | Tenant e âmbito organizacional, intervalo, versão dos resultados, regras, pendências resolvidas ou justificadas, autor e data |
| Referência biométrica | Colaborador, identificador protegido do template, versão do algoritmo/enrollment, estado, operador, vigência e estado de propagação; não incluir o template nos relatórios comuns |
| Execução de integração | Tenant, ambiente, direcção, entidade/período/versão, identificador de operação, estado por item, tentativas, confirmação externa e divergências |

Os campos condicionais devem distinguir “não aplicável” de “indisponível”. O modelo de dados e a especificação de APIs detalharão tipos, obrigatoriedade e contratos.

## 6. Estados e transições propostas

| Objecto | Transições permitidas | Controlo obrigatório |
| --- | --- | --- |
| Evento local | Pendente → enviado → confirmado; enviado sem resposta → pendente de reenvio | Não confundir envio com aceitação; manter evento até confirmação individual |
| Evento central | Recebido → aceite, rejeitado ou pendente de análise; pendente de análise → aceite, rejeitado ou duplicado | Motivo nas excepções; evento original preservado; `duplicado` só se aplica a um evento **distinto** classificado como repetição de um evento efectivo, que referencia |
| Recepção de evento | Cada recepção fica registada como primeira recepção, reenvio equivalente ou conteúdo divergente | Reenvio com o mesmo identificador e conteúdo equivalente não cria evento e devolve o resultado existente; conteúdo divergente cria pendência de análise ligada à recepção, sem alterar o evento original |
| Pedido | Rascunho → submetido → em aprovação → aprovado ou rejeitado; em aprovação → submetido quando o conteúdo é alterado; aprovado → cancelado pelo fluxo de cancelamento | Alterar conteúdo cria nova versão, invalida decisões pendentes e exige nova validação; decisão exige permissão de decisão e âmbito sobre o colaborador |
| Cancelamento | Solicitado → aprovado ou rejeitado; aprovação coloca pedido original em cancelado | Efeitos revertidos uma única vez e sujeitos ao estado do período |
| Período | Aberto → em validação → fechado; em validação → aberto quando a validação é interrompida; fechado → reaberto → em validação → fechado | Reabertura com motivo e permissão; novo fecho cria nova versão; a interrupção da validação regista autor e motivo |
| Template | Em preparação → activo → suspenso ou substituído; activo/suspenso/substituído → eliminação pendente → eliminado | Não activar captura incompleta; concluir eliminação após confirmação dos destinos aplicáveis; sem reactivação de suspenso enquanto DU-05 não for decidido |
| Integração | Pendente → em processamento → confirmada, parcialmente concluída ou falhada; falhada/parcial → em reprocessamento | Repetição mantém identidade da operação; nova versão do resultado exige nova referência e reconciliação |
| Tenant | Criado → activo; activo ↔ suspenso; activo/suspenso → desactivado | Mudanças com motivo; tenant criado ou suspenso não aceita operações de negócio (RF-001) |
| Colaborador | Activo ↔ suspenso; activo/suspenso → terminado | Colaborador suspenso ou terminado não gera marcação aceite automática (RF-021) |
| Dispositivo | Registado → activo; registado/activo → revogado | Dispositivo registado ou revogado não cria marcações aceites (RF-019); estados `suspenso` e `retirado` propostos no [documento 11 §4](11-Especificacao-de-Dispositivos-Terminais.md) aguardam decisão |
| Conta | Convidada → activa ou terminada; activa → suspensa, bloqueada ou terminada; suspensa/bloqueada → activa ou terminada | Transição efectiva na operação seguinte, incluindo sessões abertas (RF-006, RF-007) |

O estado de um tenant, colaborador, dispositivo ou conta não elimina o seu histórico. O tratamento de eventos capturados antes da suspensão e recebidos depois deve ser configurado conforme DF-03.

A devolução de um pedido ao requerente e a desistência antes da decisão (RN-036) não têm estado próprio nesta versão; dependem de PN-08. A desistência de um pedido já aprovado segue o cancelamento.

## 7. Cenários de aceitação transversais

Estes cenários complementam os critérios individuais e servirão de base ao futuro Plano de Testes; ainda não representam testes executados.

| ID | Cenário | Resultado esperado | Requisitos principais |
| --- | --- | --- | --- |
| CA-01 | Utilizador do tenant A tenta consultar, alterar e exportar dados do tenant B por identificador directo | Todas as operações são recusadas, sem divulgação dos dados | RF-002, RF-007, RF-053 |
| CA-02 | Terminal perde ligação, regista eventos, reinicia e reenvia após perder a primeira confirmação | Eventos persistem e cada evento origina uma única marcação efectiva | RF-022 a RF-026 |
| CA-03 | Turno das 22:00 às 06:00 tem pausa, saída recebida antes da entrada e feriado local | Sistema associa eventos e calendário correctos e reproduz o resultado de referência aprovado por RH | RF-014 a RF-016, RF-024, RF-038 |
| CA-04 | Reconhecimento ou prova de vida falha; colaborador usa procedimento alternativo | Nenhuma aceitação facial automática; alternativa validada produz evento rastreável | RF-027, RF-034, RF-037 |
| CA-05 | Dois aprovadores tentam decidir o mesmo pedido; período é entretanto fechado | Pedido não é aplicado duas vezes e resultado fechado não sofre alteração | RF-043, RF-047, RF-049 |
| CA-06 | Marcação atrasada chega após fecho e envio ao ERP | Resultado fechado mantém-se; reabertura autorizada produz nova versão e reconciliação externa | RF-049, RF-050, RF-058, RF-059 |
| CA-07 | ERP aceita lote mas a resposta perde-se; depois um item falha no reprocessamento | Não há duplicação; estado parcial identifica o item e permite reconciliação | RF-058, RF-059 |
| CA-08 | Template é revogado com um terminal offline e uma cópia antiga é restaurada | Destino offline fica pendente; política limita utilização desactualizada; restauro reaplica revogações antes da retoma | RF-036, RF-061, RF-062, RF-065 |
| CA-09 | A permissão ou o âmbito hierárquico de um utilizador é revogado antes de executar um relatório agendado | Execução revalida acesso e não entrega informação que deixou de estar autorizada | RF-007, RF-052, RF-055 |

## 8. Rastreabilidade para os BRDs

Os códigos BR-xx referem-se ao BRD resumido; BR-F-xxx referem-se ao detalhado. Intervalos incluem todos os identificadores entre os limites. As ligações indicam decomposição funcional, não evidência de implementação.

| Origem no BRD resumido | Origem no BRD detalhado | Requisitos derivados |
| --- | --- | --- |
| BR-01 | BR-F-001 a BR-F-006; secções 5 e 12 | RF-001 a RF-008 |
| BR-02, BR-03, BR-11 | BR-F-010 a BR-F-017 | RF-009 a RF-013 |
| BR-02 | BR-F-020 a BR-F-028 | RF-014 a RF-018, RF-049 |
| BR-03, BR-05 | BR-F-030 a BR-F-033, BR-F-036 a BR-F-038; secção 4.1 | RF-019 a RF-024, RF-027 a RF-031 |
| BR-06 | BR-F-034, BR-F-035 | RF-024 a RF-026 |
| BR-04, BR-15 | BR-F-040 a BR-F-048 | RF-027, RF-032 a RF-037, RF-061 |
| BR-07 | BR-F-050 a BR-F-054, BR-F-057 | RF-038 a RF-040, RF-048 |
| BR-08 | BR-F-053, BR-F-060 a BR-F-064 | RF-041 a RF-045 |
| BR-09 | BR-F-070 a BR-F-072 | RF-046, RF-047 |
| BR-10 | BR-F-055, BR-F-056, BR-F-074, BR-F-075 | RF-048 a RF-050 |
| BR-11, BR-12 | BR-F-080 a BR-F-086 | RF-051 a RF-053, RF-055 |
| BR-08, BR-09 | BR-F-073 | RF-054 |
| BR-13 | BR-F-090 a BR-F-095 | RF-013, RF-056 a RF-059 |
| BR-14 | BR-F-100 a BR-F-102 | RF-060 |
| BR-15 | Secções 9 e 12 | RF-036, RF-061, RF-062 |
| BR-16 | BR-F-103 a BR-F-105 | RF-063 a RF-065 |

## 9. Decisões funcionais pendentes

| ID | Decisão necessária | Responsável proposto | Requisitos afectados |
| --- | --- | --- | --- |
| DF-01 | Métodos obrigatórios por local, equipamento e primeira entrega; resolver prioridade divergente dos BRDs | Negócio e equipa técnica | RF-019 a RF-021, RF-027 a RF-031 |
| DF-02 | Mecanismo de identidade, recuperação, cargos padrão propostos aos tenants, hierarquias, delegação e auto-aprovação | Administração e RH | RF-006 a RF-008, RF-012, RF-043, RF-047 |
| DF-03 | Operação offline: validade das autorizações locais, prazo de sincronização, capacidade, divergência de relógio e eventos anteriores à revogação | RH e equipa técnica | RF-001, RF-012, RF-019, RF-024 a RF-026, RF-036 |
| DF-04 | Componente biométrico, local de processamento, prova de vida, limiares, qualidade e política de imagens | Equipa técnica e responsável de dados | RF-032 a RF-037 |
| DF-05 | Fórmulas, tolerâncias, precedência de calendários, arredondamentos, saldos e condições impeditivas do fecho | RH | RF-014 a RF-018, RF-038 a RF-050 |
| DF-06 | Fonte de referência por entidade, contratos, mapeamentos e tratamento de revisões já enviadas | Equipa ERP e RH | RF-013, RF-044, RF-050, RF-056 a RF-059 |
| DF-07 | Relatórios, campos, formatos, canais, destinatários e prazos de notificação | RH e negócio | RF-052 a RF-055 |
| DF-08 | Habilitação biométrica, retenção por categoria, impedimentos à eliminação e propagação a cópias/restauros | Responsável de dados e operação | RF-036, RF-060 a RF-062, RF-065 |
| DF-09 | Limiares operacionais, responsáveis por alertas e procedimentos de recuperação | Operação | RF-063 a RF-065 |

Até à resolução destas decisões, as configurações dependentes permanecem propostas e não devem ser tratadas como valores aprovados.

## 10. Validação e documentos relacionados

RH valida cálculos, pedidos e fechos; o responsável de negócio confirma prioridades e âmbito; a equipa técnica valida viabilidade e integrações; o responsável de dados valida o ciclo de vida dos dados. A aprovação deve identificar versão, responsável e data, e alterações posteriores devem conservar rastreabilidade.

- [Índice da documentação](README.MD).
- [Business Requirements Document resumido](01-BRD.md).
- [Business Requirements Document detalhado](BRD_Sistema_Gestao_Assiduidade.md).
- [Inventário de endpoints de assiduidade do ERP](../endpoints_assiduidade_erp.md), como referência técnica a reconciliar na especificação de APIs.

Os documentos 03 a 36 detalham este catálogo e mantêm os seus identificadores. As alterações da versão 0.2 resultam de [Diagramas UML §12](06-Diagramas-UML.md), [Modelo de Dados §6](09-Modelo-de-Dados.md), [Gestão de Utilizadores e Perfis §4 e §6](14-Gestao-de-Utilizadores-e-Perfis.md) e [Análise de Consistência](37-Analise-de-Consistencia.md) (ACH-11 a ACH-13).
