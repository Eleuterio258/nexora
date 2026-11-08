# Casos de Uso — Sistema de Gestão de Assiduidade

## 1. Controlo do documento

| Campo | Valor |
| --- | --- |
| Referência | UC-ASS-001 |
| Versão | 0.2 |
| Data | 25/09/2026 |
| Estado | Rascunho para validação |
| Responsáveis | Negócio, RH e equipa técnica — nomes a designar |

| Versão | Data | Alteração |
| --- | --- | --- |
| 0.1 | 25/09/2026 | 21 casos de uso com fluxos, alternativas e cobertura dos RF |
| 0.2 | 25/09/2026 | Actores lidos como permissões granulares e âmbito (§3), com as permissões exigidas por actor; decisões e atribuições descritas por permissão e âmbito em vez de competência |

## 2. Objectivo, fronteira e convenções

Este documento descreve interacções necessárias à gestão de assiduidade e liga-as aos requisitos funcionais RF-001 a RF-065 e às regras RN-001 a RN-048. Os fluxos são especificações propostas, não evidência de funcionalidades implementadas ou de testes executados.

A fronteira do sistema inclui plataforma central, backoffice, aplicação Android, modo terminal, processamento e conectores. Pessoas e ERP são actores externos. Um serviço biométrico externo, quando adoptado, participa como actor de apoio. Agendamento e eventos internos podem iniciar processamento automático; não são utilizadores com permissões ilimitadas.

Os identificadores **UC-01 a UC-05** preservam os cinco casos prioritários do BRD detalhado. Os restantes decompõem o catálogo funcional. Fluxos alternativos indicam variações permitidas; excepções indicam falha, conflito ou condição que impede o resultado principal. As numerações dos passos são locais a cada caso.

Capacidades desejáveis ou opcionais mantêm a prioridade do respectivo RF. A presença num caso de uso não promove a funcionalidade a obrigatória. Parâmetros PN, decisões DF e DN permanecem pendentes conforme os documentos de origem.

## 3. Actores e garantias comuns

O sistema autoriza por **permissão granular** `módulo:acção` e por **âmbito** (próprio, hierárquico ou global), não por actor ([Requisitos Funcionais §3](02-Requisitos-Funcionais.md)). Os actores humanos abaixo são designações de leitura: em cada caso de uso, "RH", "Chefia" ou "Operador biométrico" significa "utilizador com a permissão exigida pelo passo, no âmbito aplicável". Um mesmo utilizador pode desempenhar vários destes actores, e nenhum caso de uso depende do nome do cargo.

| Actor | Participação | Permissões exigidas (02 §3.2) | Âmbito |
| --- | --- | --- | --- |
| Colaborador | Marcações, consulta própria, ausências e pedidos de correcção | `assiduidade:marcar_ponto`, `ver_assiduidade`, `justificar`, `corrigir_ponto`; `pedido-ferias:submeter_pedido` | Próprio |
| RH | Cadastros, horários, apuramentos, pedidos e fechos | `recursos-humanos:gerir_funcionarios`, `gerir_horarios`; `assiduidade:gerir_configuracao`, `submeter_em_nome`, `marcar_assistido`, `resolver_pendencias`, `recalcular`, `fechar_periodo`, `reabrir_periodo` | Global |
| Chefia / aprovador | Consulta e decisões sobre os colaboradores no âmbito | `assiduidade:aprovar_correcao`, `recursos-humanos:aprovar_ausencias`, `pedido-ferias:aprovar`, `recursos-humanos:ver_funcionarios` | Hierárquico |
| Administrador do tenant | Estrutura, contas, cargos, terminais e configuração | `autorizacao:gerir_utilizadores`, `gerir_perfis`; `sistema-configuracao:editar_configuracoes`; `hardware:gerir_dispositivos` | Global |
| Administrador da plataforma | Ciclo de vida dos tenants e suporte explicitamente autorizado | Tipo `superadmin`; dados de negócio só com `seguranca:autorizar_suporte` concedida pelo tenant | Plataforma |
| Operador biométrico | Enrollment e gestão de referências biométricas | `assiduidade:gerir_biometria` | Global ou hierárquico |
| Auditor | Consulta de evidências sem alteração | `auditoria:ver_logs` | Global |
| Operação | Monitorização e continuidade | `hardware:ver_dispositivos`, `ver_eventos`, `gerir_eventos` | Global |
| Responsável de dados | Habilitação biométrica, retenção e eliminação | `assiduidade:gerir_habilitacao_biometrica`, `configurar_limiar_biometrico`, `gerir_retencao` | Global |
| Administrador de integração | Configuração e execução de integrações | `assiduidade:gerir_integracao`, `executar_integracao` | Global |
| ERP / sistema de RH | Dados mestre e resultados conforme contrato de integração | Credencial de integração | Tenant da credencial |
| Terminal | Captura e sincronização de marcações | Credencial de dispositivo | Tenant e local do dispositivo |

Todos os casos aplicam as seguintes garantias, incluindo fluxos alternativos:

- Revalidar autorização no serviço executor, por tenant, permissão, âmbito e objecto; pedidos directos à API seguem os mesmos controlos.
- Verificar a segregação de funções sobre as pessoas envolvidas (quem pediu, quem decide, sobre quem), não sobre cargos.
- Preservar evidência de origem, versões e autoria nas operações críticas; falha de auditoria segue RNF-026.
- Apresentar falhas e pendências sem confirmar sucesso inexistente nem divulgar dados de terceiros.
- Não alterar resultados fechados sem UC-15; conflitos concorrentes exigem revalidação.
- Não executar automaticamente uma decisão de negócio cujo parâmetro obrigatório ainda não esteja aprovado.
- Aplicar os RNFs transversais de isolamento, segurança, integridade, desempenho e acessibilidade. As referências específicas abaixo complementam estas garantias.

## 4. Casos de uso detalhados

### UC-01 — Registar entrada, saída ou pausa

**Actor principal:** Colaborador. **Apoio:** componente de identificação aprovado.  
**Gatilho:** O colaborador inicia uma marcação.  
**Pré-condições:** Dispositivo habilitado, colaborador elegível e pelo menos um método autorizado.  
**Rastreabilidade:** RF-021 a RF-024, RF-027 a RF-032, RF-034, RF-035, RF-037; RN-008 a RN-013, RN-022, RN-043 a RN-045; RNF-001, RNF-023, RNF-024, RNF-030.

**Fluxo principal:**

1. O colaborador selecciona ou confirma o evento: entrada, saída, início ou fim de pausa.
2. O sistema apresenta o método autorizado e as instruções necessárias.
3. O colaborador identifica-se; no método facial, o sistema valida correspondência e prova de vida.
4. O sistema cria um identificador estável e regista instante, origem, método e contexto.
5. A plataforma valida habilitação, tenant, dados e eventual duplicação.
6. O evento é aceite e disponibilizado para processamento no UC-13.
7. O colaborador recebe confirmação de aceitação central.

**Alternativas e excepções:** No passo 2, QR Code, NFC, impressão digital ou localização só são usados quando seleccionados para a entrega e activados. Falha de identificação encaminha para alternativa autorizada ou pedido assistido; não cria falta automática. Sem ligação, executar UC-06. Reenvio equivalente devolve resultado existente; conteúdo divergente com o mesmo identificador gera conflito. Sequência incompleta, hora suspeita ou período fechado produz pendência com motivo.

**Pós-condição de sucesso:** Um evento efectivo rastreável, sem implicar aprovação de horas extraordinárias. **Garantia em falha:** Nenhum sucesso falso; tentativas e pendências seguem a política de evidência.  
**Aceitação:** Marcação válida fica consultável; reenvio não duplica; falha facial oferece contingência e não conclui ausência.

### UC-02 — Solicitar e decidir correcção de ponto

**Actor principal:** Colaborador ou RH. **Apoio:** Aprovador.  
**Gatilho:** Identificação de marcação em falta ou resultado incorrecto.  
**Pré-condições:** Registo ou jornada acessível e fluxo de aprovação configurado.  
**Rastreabilidade:** RF-046, RF-047; RN-031 a RN-036; RNF-010, RNF-025.

**Fluxo principal:**

1. O requerente selecciona a jornada ou registo e informa valor proposto e motivo.
2. O sistema valida dados, âmbito e estado do período e apresenta a alteração proposta.
3. O requerente submete o pedido; o original permanece inalterado.
4. O sistema encaminha o pedido a quem tem permissão de decisão e âmbito sobre o colaborador (responsável de unidade, aprovador designado ou delegado).
5. O aprovador consulta evidências e decide sobre a versão submetida.
6. Após aprovação, o sistema cria ajuste ligado ao original e executa UC-13.
7. O sistema conserva antes/depois, autoria, decisão e estado final.

**Alternativas e excepções:** Inclusão de marcação em falta é um ajuste identificado. Rejeição exige motivo e não aplica alteração. Período fechado exige UC-15 antes de aplicar. Conteúdo alterado ou decisão concorrente exige nova validação. Delegação segue política aprovada; auto-aprovação não definida fica bloqueada.

**Pós-condição de sucesso:** Ajuste aprovado aplicado uma vez e resultado versionado. **Garantia em falha:** Original preservado e pedido com estado explícito.  
**Aceitação:** Correcção sem motivo é recusada; duas decisões concorrentes não produzem dois ajustes.

### UC-03 — Validar e fechar período

**Actor principal:** RH autorizado.  
**Gatilho:** Início do fecho de um intervalo de assiduidade.  
**Pré-condições:** Período aberto ou reaberto, âmbito definido e critérios de fecho aprovados.  
**Rastreabilidade:** RF-048, RF-049; RN-037, RN-038; RNF-010, RNF-025.

**Fluxo principal:**

1. RH selecciona período e âmbito organizacional.
2. O sistema apresenta pedidos, marcações pendentes, conflitos e resultados por validar.
3. RH resolve pendências ou regista excepções permitidas com justificação.
4. O sistema valida novamente o conjunto de dados e as condições impeditivas.
5. RH confirma o fecho.
6. O sistema fecha a versão validada e regista autor, data, âmbito e regras aplicadas.
7. Os resultados ficam disponíveis como definitivos para consulta e UC-05.

**Alternativas e excepções:** Pendência impeditiva bloqueia o passo 5. Alteração concorrente ao conjunto validado exige nova validação antes de fechar. Evento tardio posterior não altera a versão fechada.

**Pós-condição de sucesso:** Período fechado com evidência e resultados protegidos. **Garantia em falha:** Não apresentar fecho parcial como concluído.  
**Aceitação:** API, importação e sincronização não alteram os resultados após o fecho.

### UC-04 — Efectuar enrollment facial

**Actor principal:** Operador biométrico. **Apoio:** Colaborador e componente biométrico.  
**Gatilho:** Habilitação inicial ou substituição de referência facial.  
**Pré-condições:** Operador autorizado, identidade confirmável e política de tratamento aprovada.  
**Rastreabilidade:** RF-032, RF-033, RF-035, RF-037, RF-061; RN-043 a RN-045; RNF-020, RNF-023.

**Fluxo principal:**

1. O operador autentica-se e selecciona o colaborador no tenant correcto.
2. O sistema verifica habilitação ao tratamento e registos exigidos, incluindo consentimento quando aplicável.
3. O operador confirma identidade e inicia captura guiada.
4. O componente valida qualidade e prova de vida conforme política de enrollment.
5. O sistema cria a referência com versão de enrollment, algoritmo, operador e data.
6. O template é activado e a distribuição autorizada fica identificada por destino.

**Alternativas e excepções:** Captura incompleta ou qualidade insuficiente permite repetir sem activar template inválido. Substituição conserva relação com a versão anterior. Falha de distribuição mantém destino pendente. Sem habilitação, oferecer o procedimento alternativo, sem recolher biometria.

**Pós-condição de sucesso:** Referência válida, versionada e com estado de distribuição visível. **Garantia em falha:** Nenhum template incompleto activo.  
**Aceitação:** Identificar a versão usada numa marcação sem expor o template em consultas comuns.

### UC-05 — Sincronizar e reconciliar com o ERP

**Actor principal:** ERP / operador de integração; execução também iniciada por agendamento.  
**Gatilho:** Lote recebido, sincronização programada ou envio de período fechado.  
**Pré-condições:** Conexão, fonte de referência, mapeamentos e contrato aprovados no UC-19.  
**Rastreabilidade:** RF-057 a RF-059; RN-040 a RN-042; RNF-009, RNF-011, RNF-036.

**Fluxo principal:**

1. O sistema identifica tenant, ambiente, direcção e entidade ou versão do período.
2. Valida contrato, autorização, identificadores e chave da operação.
3. Aplica dados mestre conforme fonte de referência ou envia resultados fechados.
4. Regista resultado individual, confirmações e falhas.
5. Reconcilia quantidades, totais e versões com o destino.
6. Disponibiliza o estado e os itens que exigem intervenção.

**Alternativas e excepções:** Falha parcial permite reprocessar itens necessários. Timeout após recepção exige consulta ou reenvio idempotente. Conflito de dados mestre não é sobrescrito silenciosamente. Versão revista segue ajuste ou substituição contratados, nunca novo total não reconciliado. Período aberto não é enviado como definitivo.

**Pós-condição de sucesso:** Operação aplicada e reconciliada, ligada às confirmações externas. **Garantia em falha:** Estado parcial/falhado explícito, sem duplicar efeitos.  
**Aceitação:** Perda de resposta e reprocessamento preservam uma única aplicação efectiva.

### UC-06 — Registar offline e sincronizar marcações

**Actor principal:** Colaborador; sincronização automática após recuperação da ligação.  
**Gatilho:** Marcação sem acesso ao serviço central.  
**Pré-condições:** Política offline aprovada, autorização local válida e armazenamento disponível.  
**Rastreabilidade:** RF-025, RF-026; RN-009, RN-010, RN-013 a RN-016; RNF-007 a RNF-009.

**Fluxo principal:**

1. O sistema valida as condições locais e guarda o evento com identificador estável.
2. Apresenta confirmação de gravação local pendente de sincronização.
3. Mantém a fila persistente, incluindo após reinício.
4. Ao recuperar a ligação, envia eventos com horas de origem e recepção distintas.
5. A plataforma devolve resultado individual, incluindo conflitos ou rejeições.
6. O terminal reconcilia confirmações e actualiza o estado dos eventos.

**Alternativas e excepções:** Falta de espaço ou gravação falhada não confirma sucesso. Autorização expirada encaminha para contingência. Resposta perdida mantém reenvio pendente com o mesmo identificador. Revogação posterior à captura, relógio suspeito e evento de período fechado seguem análise definida nas regras.

**Pós-condição de sucesso:** Eventos reconciliados sem perda nem duplicação no cenário aprovado. **Garantia em falha:** Fila pendente identificada; não prometer recuperação de dispositivo fisicamente perdido.  
**Aceitação:** Reiniciar após captura e perder a primeira confirmação não elimina nem duplica o evento.

### UC-07 — Administrar tenants e estrutura organizacional

**Actor principal:** Administrador da plataforma ou do tenant, conforme operação.  
**Gatilho:** Criação de organização ou alteração da estrutura.  
**Pré-condições:** Permissão administrativa correspondente.  
**Rastreabilidade:** RF-001 a RF-005; RN-001, RN-002, RN-006, RN-007.

**Fluxo principal:**

1. O administrador da plataforma cria ou selecciona o tenant.
2. O administrador autorizado configura identificação, idioma e fuso.
3. Define unidades, locais, departamentos e equipas.
4. Associa utilizadores, colaboradores, dispositivos e políticas aos âmbitos correctos.
5. O sistema valida relações e grava a configuração auditada.

**Alternativas e excepções:** Suspensão/desactivação exige motivo e preserva histórico. Vigência futura da estrutura depende da entrega desejável RF-005. Hierarquia circular e relação entre tenants são recusadas. Eventos anteriores à suspensão seguem RN-015.

**Pós-condição de sucesso:** Organização e estrutura coerentes e rastreáveis. **Garantia em falha:** Configuração inválida não substitui a activa.  
**Aceitação:** Administrador de um tenant não altera estrutura de outro.

### UC-08 — Gerir acesso e suporte autorizado

**Actor principal:** Utilizador ou administrador.  
**Gatilho:** Acesso, recuperação de conta ou alteração de permissões.  
**Pré-condições:** Mecanismo de identidade e matriz de acessos definidos.  
**Rastreabilidade:** RF-006 a RF-008; RN-002, RN-005, RN-031, RN-032; RNF-014, RNF-017.

**Fluxo principal:**

1. O utilizador autentica-se pelo mecanismo aprovado.
2. O sistema determina tenant, permissões efectivas (cargo, directas e tipo de utilizador) e âmbito, e disponibiliza apenas as funções autorizadas.
3. Um utilizador com `autorizacao:gerir_utilizadores` ou `autorizacao:gerir_perfis` atribui ou revoga cargos e permissões directas, nunca a si próprio.
4. O sistema aplica as alterações a novas operações e regista auditoria.
5. O utilizador termina a sessão.

**Alternativas e excepções:** Recuperação de acesso valida identidade sem revelar segredos. Suporte transversal exige finalidade, âmbito e validade explícitos. Credencial inválida, sessão terminada ou conta suspensa impede operação; revogação não é contornada por pedido directo à API.

**Pós-condição de sucesso:** Sessão e permissões correspondem à autorização vigente. **Garantia em falha:** Nenhum acesso adicional concedido.  
**Aceitação:** Acesso anteriormente permitido deixa de funcionar após revogação central.

### UC-09 — Gerir colaboradores e identificadores

**Actor principal:** RH / administrador autorizado.  
**Gatilho:** Admissão, mudança, importação ou término de vínculo.  
**Pré-condições:** Estrutura organizacional e fonte de referência definidas.  
**Rastreabilidade:** RF-009 a RF-013; RN-003 a RN-006, RN-009, RN-040.

**Fluxo principal:**

1. RH cria ou selecciona o cadastro do colaborador.
2. Informa identificador, estado, vínculo e associações com vigência.
3. Associa métodos autorizados, gestor e aprovador.
4. Se aplicável, associa uma conta de acesso sem conferir privilégios administrativos implícitos.
5. O sistema valida unicidade e grava o histórico das alterações.

**Alternativas e excepções:** Importação apresenta validação e resultado por linha e não duplica cadastros no reenvio. Suspensão/término mantém histórico. Identificador repetido ou conflito com fonte externa exige resolução. Revogação de método informa pendências de distribuição aplicáveis.

**Pós-condição de sucesso:** Cadastro válido com associações e vigências explícitas. **Garantia em falha:** Não fundir históricos automaticamente.  
**Aceitação:** Colaborador pode existir sem conta de backoffice; importação repetida não duplica cadastro.

### UC-10 — Configurar horários e políticas

**Actor principal:** RH autorizado.  
**Gatilho:** Nova escala, calendário ou alteração de política.  
**Pré-condições:** Parâmetros e precedências aprovados para a configuração.  
**Rastreabilidade:** RF-014 a RF-018; RN-006, RN-007, RN-017 a RN-023.

**Fluxo principal:**

1. RH define âmbito, calendário e horário fixo, flexível ou por turnos.
2. Configura pausas, tolerâncias e classificações aprovadas.
3. Informa vigência e associa colaboradores ou grupos.
4. O sistema verifica coerência, conflitos e efeito sobre períodos fechados.
5. RH activa a versão autorizada e o sistema conserva a anterior.

**Alternativas e excepções:** Arredondamento e agendamento futuro dependem de RF-017. Simulação opcional RF-018 compara resultados sem alterar dados oficiais. Parâmetro ausente, precedência ambígua ou alteração retroactiva não autorizada impede activação aplicável.

**Pós-condição de sucesso:** Política versionada com âmbito e vigência. **Garantia em falha:** Resultados existentes não são alterados silenciosamente.  
**Aceitação:** Turno nocturno é representável e a política aplicada a cada resultado é identificável.

### UC-11 — Gerir terminais e configuração distribuída

**Actor principal:** Administrador do tenant.  
**Gatilho:** Instalação, alteração de configuração ou retirada de equipamento.  
**Pré-condições:** Dispositivo e métodos seleccionados para o ambiente.  
**Rastreabilidade:** RF-019, RF-020; RN-009, RN-015; RNF-008, RNF-032.

**Fluxo principal:**

1. O administrador regista o dispositivo no tenant e local autorizados.
2. Habilita credencial e métodos aplicáveis.
3. Publica a versão de configuração.
4. O dispositivo aplica e confirma a versão recebida.
5. O backoffice apresenta estado, versão aplicada e eventuais pendências.

**Alternativas e excepções:** Falha de aplicação mantém a versão anterior identificada. Revogação bloqueia novas aceitações centrais; eventos já capturados seguem RN-015. Dispositivo offline permanece pendente e sujeito à validade local, sem confirmação fictícia de revogação aplicada.

**Pós-condição de sucesso:** Terminal autorizado com configuração confirmada. **Garantia em falha:** Estado pendente explícito.  
**Aceitação:** Terminal revogado não cria nova marcação aceite automaticamente no serviço central.

### UC-12 — Suspender, substituir ou eliminar biometria

**Actor principal:** Operador biométrico / responsável autorizado.  
**Gatilho:** Alteração de habilitação, substituição ou pedido de eliminação.  
**Pré-condições:** Referência existente e política de tratamento definida.  
**Rastreabilidade:** RF-036, RF-061; RN-043, RN-045, RN-047; RNF-021.

**Fluxo principal:**

1. O actor selecciona colaborador, referência e operação, informando motivo.
2. O sistema valida permissão, habilitação e impedimentos aplicáveis.
3. Regista suspensão/revogação de uso e a operação de ciclo de vida correspondente.
4. Distribui a alteração aos destinos autorizados.
5. Recolhe confirmações e apresenta destinos pendentes.

**Alternativas e excepções:** Substituição executa UC-04 com nova versão. Eliminação segue também UC-18. Impedimento de eliminação não é confundido com autorização de utilização. Terminal offline mantém pendência e segue prazo de validade aprovado.

**Pós-condição de sucesso:** Estado actualizado e propagação confirmada ou explicitamente pendente. **Garantia em falha:** Não apresentar eliminação global como concluída sem confirmação dos destinos aplicáveis.  
**Aceitação:** Template suspenso deixa de ser usado onde a alteração foi aplicada; os restantes destinos são identificáveis.

### UC-13 — Apurar e recalcular assiduidade

**Actor principal:** RH; execução também automática após evento válido.  
**Gatilho:** Novos dados ou alteração autorizada em período aberto.  
**Pré-condições:** Jornada identificável e políticas aplicáveis disponíveis.  
**Rastreabilidade:** RF-038 a RF-040; RN-017 a RN-024, RN-028, RN-029.

**Fluxo principal:**

1. O sistema selecciona eventos, ajustes, ausências e versões de política.
2. Forma intervalos válidos de presença e pausas.
3. Calcula tempos e classifica atrasos, faltas e ocorrências.
4. Distingue valores observados, candidatos e aprovados.
5. Um utilizador com `assiduidade:aprovar_horas` valida ocorrências ou decide horas elegíveis dentro do seu âmbito.
6. O sistema publica nova versão, preservando anteriores e motivo do recálculo.

**Alternativas e excepções:** Eventos incompletos e conflitos ficam pendentes, sem duração inventada. Ausência sobreposta exige resolução. Período fechado segue UC-15. Falha biométrica não é suficiente para concluir falta.

**Pós-condição de sucesso:** Resultado rastreável às entradas e regras. **Garantia em falha:** Resultado incompleto não é apresentado como definitivo.  
**Aceitação:** Repetir cálculo equivalente não acumula tempo; pausas e intervalos sobrepostos não são deduzidos ou contados duas vezes.

### UC-14 — Gerir férias, ausências e justificações

**Actor principal:** Colaborador / RH. **Apoio:** Aprovador e sistema de saldos.  
**Gatilho:** Pedido ou recepção de ausência.  
**Pré-condições:** Tipos, documentos, unidades, origem de saldos e aprovação configurados.  
**Rastreabilidade:** RF-041 a RF-045; RN-025 a RN-032, RN-035, RN-036.

**Fluxo principal:**

1. O requerente selecciona tipo, intervalo e unidade e fornece motivo e anexos exigidos.
2. O sistema verifica dados, saldo aplicável e incompatibilidades.
3. Submete o pedido a quem tem permissão de decisão e âmbito sobre o colaborador.
4. O aprovador analisa e aprova ou rejeita com motivo aplicável.
5. Uma aprovação reflecte os efeitos autorizados no apuramento e nos saldos.
6. O requerente consulta decisão e estado de integração, quando necessário.

**Alternativas e excepções:** RH configura tipos e documentos antes da utilização. Saldo desactualizado ou conflito impede aprovação automática. Cancelamento desejável RF-045 exige decisão e reverte efeitos uma vez; período fechado exige UC-15. Justificação não implica automaticamente tempo remunerado.

**Pós-condição de sucesso:** Pedido decidido, efeitos aplicados ou integração pendente identificada. **Garantia em falha:** Submissão não equivale a aprovação.  
**Aceitação:** Aprovação repetida não debita duas vezes o saldo; anexos respeitam âmbito de acesso.

### UC-15 — Reabrir e voltar a fechar período

**Actor principal:** RH com permissão de reabertura.  
**Gatilho:** Correcção necessária após fecho.  
**Pré-condições:** Período fechado e motivo documentado.  
**Rastreabilidade:** RF-050; RN-016, RN-030, RN-038, RN-039, RN-042.

**Fluxo principal:**

1. RH selecciona período e informa motivo da reabertura.
2. O sistema valida `assiduidade:reabrir_periodo` e autenticação reforçada e apresenta versão fechada e envios existentes.
3. Reabre o âmbito autorizado, conservando a evidência anterior.
4. RH resolve eventos ou ajustes e executa UC-13.
5. UC-03 gera um novo fecho e versão.
6. O sistema identifica necessidade de reconciliação no UC-05.

**Alternativas e excepções:** Sem permissão ou motivo, recusar. Se o ERP não suportar a revisão acordada, manter pendência explícita, sem reenviar um total duplicado.

**Pós-condição de sucesso:** Nova versão fechada, ligada à anterior e à reconciliação. **Garantia em falha:** Fecho anterior preservado.  
**Aceitação:** Consulta distingue versões e confirmação externa não é atribuída à versão errada.

### UC-16 — Consultar, exportar e agendar relatórios

**Actor principal:** Colaborador, chefia ou RH autorizado.  
**Gatilho:** Consulta do histórico ou necessidade de relatório.  
**Pré-condições:** Dados acessíveis ao âmbito do actor.  
**Rastreabilidade:** RF-051 a RF-053, RF-055; RN-002, RN-046; RNF-003, RNF-031, RNF-037.

**Fluxo principal:**

1. O actor escolhe consulta ou relatório e filtros autorizados.
2. O sistema limita dados ao âmbito e versão aplicáveis.
3. Apresenta presenças, horas, ocorrências ou pedidos, distinguindo provisório de fechado.
4. Identifica filtros, data de geração e origem dos resultados.

**Alternativas e excepções:** Exportação desejável valida formato e campos e gera auditoria. Agendamento opcional revalida destinatários e permissões na execução. Falha de geração não disponibiliza ficheiro parcial como completo. Dados biométricos não integram relatórios comuns.

**Pós-condição de sucesso:** Informação consistente e restrita ao actor/destinatário autorizado. **Garantia em falha:** Nenhuma fuga de dados por filtro ou exportação.  
**Aceitação:** Totais reconciliam com a versão seleccionada e permissão revogada impede entrega agendada futura.

### UC-17 — Consultar auditoria

**Actor principal:** Auditor autorizado.  
**Gatilho:** Investigação ou revisão de uma operação.  
**Pré-condições:** Permissão de consulta e evidências dentro da retenção aplicável.  
**Rastreabilidade:** RF-060; RN-002, RN-034, RN-038, RN-046; RNF-025 a RNF-027.

**Fluxo principal:**

1. O auditor define âmbito, intervalo, actor ou objecto.
2. O sistema valida acesso e pesquisa evidências.
3. Apresenta acção, resultado, origem, instantes e correlações.
4. O auditor acompanha a cadeia entre pedido, decisão, ajuste, fecho e integração.

**Alternativas e excepções:** Dados fora de retenção ou lacunas conhecidas são identificados, não fabricados. Tentativa de alteração da evidência é recusada. Exportação permitida segue UC-16 e a política própria.

**Pós-condição de sucesso:** Operação reconstruída com evidências autorizadas. **Garantia em falha:** Consulta não modifica histórico nem revela segredos.  
**Aceitação:** Um ajuste pode ser ligado ao original e ao aprovador sem expor templates.

### UC-18 — Aplicar retenção, eliminação e anonimização

**Actor principal:** Responsável de dados autorizado; execução também por agendamento.  
**Gatilho:** Pedido validado ou expiração da retenção.  
**Pré-condições:** Política por categoria, âmbito e impedimentos definidos.  
**Rastreabilidade:** RF-062; RN-047, RN-048; RNF-020 a RNF-022.

**Fluxo principal:**

1. O sistema identifica dados elegíveis, cópias e destinos abrangidos.
2. Verifica impedimentos formalmente registados e operação autorizada.
3. Executa eliminação ou anonimização nos destinos elegíveis.
4. Acompanha confirmações, pendências e expiração de cópias segundo política.
5. Regista evidência de conclusão sem conservar o conteúdo eliminado.

**Alternativas e excepções:** Impedimento mantém retenção identificada e sujeita a revisão. Destino offline permanece pendente. Cópia imutável segue expiração controlada e reaplicação no restauro, sem alegação de eliminação imediata inexistente.

**Pós-condição de sucesso:** Ciclo de vida concluído ou pendências explicitamente justificadas. **Garantia em falha:** Não ocultar dados ainda existentes.  
**Aceitação:** Restauro posterior não reactiva dados eliminados antes de reaplicar decisões.

### UC-19 — Configurar integração

**Actor principal:** Administrador de integração autorizado.  
**Gatilho:** Nova ligação ou alteração de contrato/ambiente.  
**Pré-condições:** Fonte de referência, mapeamentos e consumidor definidos.  
**Rastreabilidade:** RF-056; RN-040 a RN-042; RNF-017, RNF-036.

**Fluxo principal:**

1. O actor selecciona tenant, ambiente e sistema externo.
2. Configura destino, credenciais protegidas e mapeamentos.
3. Define direcção, versão, fonte de referência e resolução de conflitos.
4. Executa teste autorizado de ligação e contrato.
5. Activa a configuração versionada para UC-05.

**Alternativas e excepções:** Teste falhado mantém configuração inactiva ou anterior válida. Rotação revoga credencial antiga. Credenciais nunca são devolvidas em claro nas consultas ou logs.

**Pós-condição de sucesso:** Conexão válida e rastreável no ambiente correcto. **Garantia em falha:** Teste de ligação não é confundido com reconciliação concluída.  
**Aceitação:** A configuração de um tenant não autoriza operações noutro.

### UC-20 — Acompanhar operação e notificações

**Actor principal:** Operação; aprovadores recebem notificações dentro do seu âmbito.  
**Gatilho:** Consulta operacional, falha detectada ou pedido/decisão a notificar.  
**Pré-condições:** Acessos, métricas e, para alertas, limiares e canais configurados.  
**Rastreabilidade:** RF-054, RF-063, RF-064; RN-002, RN-032; RNF-027, RNF-028.

**Fluxo principal:**

1. O sistema recolhe estado de serviços, versões, ligações, filas e integrações.
2. O operador consulta última comunicação e pendências.
3. Quando a capacidade desejável está activa, uma condição configurada gera notificação ou alerta para destinatário autorizado.
4. O sistema regista entrega, falha e recuperação ou decisão relacionada.

**Alternativas e excepções:** Canal indisponível conserva estado de falha e reenvio controlado. Destinatário sem autorização não recebe dados. Repetir notificação não repete aprovação, correcção ou envio de negócio.

**Pós-condição de sucesso:** Estado operacional e comunicação rastreáveis. **Garantia em falha:** Ausência de confirmação de entrega não é apresentada como entrega concluída.  
**Aceitação:** Falha simulada é localizável e recuperação actualiza o estado.

### UC-21 — Executar backup e recuperar serviço

**Actor principal:** Operação autorizada.  
**Gatilho:** Rotina de cópia, exercício ou incidente.  
**Pré-condições:** Plano, acesso às chaves e RPO/RTO por classe aprovados para o ensaio/retoma.  
**Rastreabilidade:** RF-065; RN-048; RNF-016, RNF-029, RNF-035.

**Fluxo principal:**

1. O operador executa ou verifica cópia e regista resultado e ponto recuperável.
2. Selecciona o ponto de recuperação e prepara ambiente controlado.
3. Restaura dados e dependências na ordem do plano.
4. Reaplica revogações, eliminações e alterações de acesso posteriores à cópia.
5. Reconcilia eventos, fechos, auditoria e integrações.
6. Valida isolamento e serviço, mede RPO/RTO e autoriza retoma segundo o plano.

**Alternativas e excepções:** Cópia inválida ou chave indisponível impede conclusão e activa contingência. Perda física de terminal pode afectar eventos não sincronizados conforme política específica. Divergência impede declarar recuperação integral.

**Pós-condição de sucesso:** Serviço recuperado e validado, com limites de perda documentados. **Garantia em falha:** Não reactivar dados revogados ou apresentar simples arranque como recuperação completa.  
**Aceitação:** Exercício comprova integridade e reaplicação das decisões posteriores à cópia.

## 5. Índice de cobertura funcional

Esta matriz permite verificar cobertura documental; não substitui a futura matriz de testes nem comprova implementação.

| Requisitos funcionais | Casos de uso |
| --- | --- |
| RF-001 a RF-005 | UC-07 |
| RF-006 a RF-008 | UC-08 |
| RF-009 a RF-013 | UC-09 |
| RF-014 a RF-018 | UC-10 |
| RF-019, RF-020 | UC-11 |
| RF-021 a RF-024 | UC-01 |
| RF-025, RF-026 | UC-06 |
| RF-027 a RF-032 | UC-01, UC-04 |
| RF-033 | UC-04 |
| RF-034 | UC-01 |
| RF-035 | UC-01, UC-04 |
| RF-036 | UC-12 |
| RF-037 | UC-01, UC-04 |
| RF-038 a RF-040 | UC-13 |
| RF-041 a RF-045 | UC-14 |
| RF-046, RF-047 | UC-02 |
| RF-048, RF-049 | UC-03 |
| RF-050 | UC-15 |
| RF-051 a RF-053 | UC-16 |
| RF-054 | UC-20 |
| RF-055 | UC-16 |
| RF-056 | UC-19 |
| RF-057 a RF-059 | UC-05 |
| RF-060 | UC-17; garantia comum a operações críticas |
| RF-061 | UC-04, UC-12 |
| RF-062 | UC-18 |
| RF-063, RF-064 | UC-20 |
| RF-065 | UC-21 |

## 6. Dependências e ordem de validação

Configuração de organização, acesso, colaboradores, políticas e terminais (UC-07 a UC-11) prepara a marcação. Enrollment (UC-04) é necessário apenas para quem utilizar biometria habilitada. Marcações (UC-01 e UC-06), pedidos (UC-02 e UC-14) e apuramento (UC-13) alimentam o fecho (UC-03). Integração configurada (UC-19) permite UC-05; alterações posteriores ao fecho seguem UC-15.

Recomenda-se validar primeiro um percurso completo: configurar um tenant, habilitar colaborador, registar online e offline, corrigir uma ocorrência, apurar, fechar e reconciliar com ERP. Depois, validar isolamento, concorrência, revogações, retenção e recuperação. Alternativas desejáveis e opcionais são incluídas conforme âmbito aprovado.

As decisões pendentes DF-01 a DF-09, DN-01 a DN-10 e PN-01 a PN-12 mantêm-se nos documentos de origem. Não se fixam neste documento tempos de tolerância, saldos, limiares biométricos ou prazos de recuperação.

## 7. Aprovação e manutenção

RH e negócio validam sequências, resultados e excepções; equipa técnica e ERP validam integrações e condições de falha; responsável de dados e operação validam biometria, retenção e recuperação. Cada aprovação deve identificar nome, versão e data. Estado de aprovação desta versão: **pendente**.

Alterações devem preservar identificadores UC e indicar requisitos/regras afectados. O Plano de Testes deverá atribuir identificadores próprios aos cenários, relacionando-os com passos, alternativas, critérios de aceitação e evidências executadas. Os futuros diagramas UML devem usar os mesmos actores e nomes de casos, sem substituir os fluxos textuais.

## 8. Referências

- [Índice da documentação](README.MD).
- [BRD resumido](01-BRD.md).
- [BRD detalhado](BRD_Sistema_Gestao_Assiduidade.md), secção 10: origem de UC-01 a UC-05.
- [Requisitos Funcionais](02-Requisitos-Funcionais.md).
- [Requisitos Não Funcionais](03-Requisitos-Nao-Funcionais.md).
- [Regras de Negócio](04-Regras-de-Negocio.md).
