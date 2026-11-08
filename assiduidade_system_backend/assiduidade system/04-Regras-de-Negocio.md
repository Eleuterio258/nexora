# Regras de Negócio — Sistema de Gestão de Assiduidade

## 1. Controlo do documento

| Campo | Valor |
| --- | --- |
| Referência | RN-ASS-001 |
| Versão | 0.1 |
| Data | 25/09/2026 |
| Estado | Rascunho para validação |
| Proprietário | RH / responsável de negócio — a designar |
| Validadores | Negócio, RH, equipa técnica, equipa ERP e responsável de dados |

## 2. Objectivo e aplicação

Este documento define condições, restrições e decisões que governam o tratamento da assiduidade. Complementa os requisitos funcionais (RF) e não representa uma auditoria da implementação existente.

As regras RN são propostas derivadas dos BRDs. Os exemplos servem para validar interpretações; não estabelecem tolerâncias, direitos a férias, taxas salariais ou políticas laborais. Valores dependentes da organização estão identificados na secção 7 e exigem aprovação antes da activação da política correspondente.

Cada regra indica a condição em que se aplica, a decisão esperada e a referência funcional. As políticas configuráveis não podem afastar isolamento entre tenants, autorização, preservação da evidência ou controlo de períodos fechados. Quando faltam parâmetros indispensáveis, o resultado afectado deve permanecer pendente de configuração, sem ser apresentado como definitivo.

## 3. Conceitos e precedência

| Conceito | Significado neste documento |
| --- | --- |
| Evento de origem | Marcação recebida, conservada com identidade, origem e instantes próprios |
| Marcação aceite | Evento validado para utilização no processamento; não significa, por si só, tempo trabalhado ou hora extraordinária aprovada |
| Ocorrência | Classificação ou inconsistência identificada no apuramento |
| Ajuste | Alteração aprovada ligada ao evento ou resultado original, sem o substituir silenciosamente |
| Apuramento | Resultado versionado da aplicação de regras a eventos, ajustes e ausências |
| Jornada | Instância de trabalho associada ao horário/turno aplicável, podendo atravessar dias civis |
| Política | Conjunto versionado de regras, parâmetros, âmbito e vigência |
| Competência | Condição para decidir ou executar uma operação sobre um colaborador: ter a permissão `módulo:acção` exigida **e** o colaborador estar no âmbito do utilizador (próprio, hierárquico por responsabilidade de unidade, designação ou delegação vigente, ou global) — [Requisitos Funcionais §3.1](02-Requisitos-Funcionais.md). Não depende do nome do cargo |

Para determinar a política aplicável, o sistema deve primeiro identificar tenant, colaborador, instante do evento e associações vigentes. A precedência entre regras de tenant, unidade, equipa e colaborador deve ser explicitamente aprovada por categoria; não se presume que a regra mais específica vence sempre. Conflitos não resolvidos impedem o apuramento definitivo do âmbito afectado.

Alterações de política devem indicar data de início, eventual fim de vigência, aprovador e motivo. A utilização de uma política nova em dados históricos exige decisão explícita e, se o período estiver fechado, reabertura autorizada.

## 4. Catálogo de regras

### 4.1. Organização, identidades e políticas

| ID | Condição | Regra / decisão | Referências |
| --- | --- | --- | --- |
| RN-001 | Recepção ou criação de dados de assiduidade | Cada registo pertence a exactamente um tenant; dados sem associação válida não entram no apuramento e ficam rejeitados ou em excepção controlada. | RF-001, RF-002 |
| RN-002 | Consulta, alteração, decisão ou exportação | A operação exige tenant, permissão e âmbito organizacional válidos; conhecer um identificador não concede autorização. | RF-002, RF-007, RF-008 |
| RN-003 | Criação ou sincronização de colaborador | O identificador do colaborador é único dentro do tenant; possível duplicação deve ser resolvida sem fundir históricos automaticamente. | RF-009, RF-013 |
| RN-004 | Vínculo suspenso ou terminado | O histórico permanece preservado; eventos novos não são automaticamente aceites fora da vigência autorizada. Eventos anteriores recebidos depois seguem RN-015. | RF-009, RF-010, RF-026 |
| RN-005 | Cadastro e conta de acesso associados | A condição de colaborador não concede acesso administrativo; permissões de utilizador são atribuídas separadamente. | RF-006, RF-007, RF-011 |
| RN-006 | Determinação de horário ou política | Aplicar associações válidas no instante do evento e no fuso definido para o contexto; conflitos de vigência ou precedência geram pendência. | RF-003, RF-010, RF-014 a RF-017 |
| RN-007 | Activação ou alteração de política | Parâmetros devem estar aprovados, versionados e com vigência; não substituir a versão que fundamentou um resultado anterior. | RF-016 a RF-018, RF-039 |

### 4.2. Marcações, dispositivos e sincronização

| ID | Condição | Regra / decisão | Referências |
| --- | --- | --- | --- |
| RN-008 | Marcação submetida | Exigir identificação do tenant, colaborador ou excepção controlada, tipo, instante, origem e método; excepção de identidade não conta como presença até resolução autorizada. | RF-021, RF-024 |
| RN-009 | Marcação por terminal ou aplicação | Método, dispositivo e colaborador devem estar habilitados no âmbito aplicável; a autorização local offline tem validade limitada pela política. | RF-012, RF-019 a RF-021, RF-032 |
| RN-010 | Recepção do mesmo identificador de evento | Reenvio com conteúdo equivalente mantém o resultado existente e não gera nova presença; conteúdo divergente com o mesmo identificador gera conflito, sem sobrescrever o original. | RF-023, RF-026 |
| RN-011 | Eventos distintos próximos no tempo | Comparar colaborador, tipo, origem e janela de duplicação aprovada; sinalizar possível repetição sem eliminar automaticamente eventos legítimos de tipos diferentes. | RF-023, RF-024 |
| RN-012 | Registo inválido ou incompleto | Rejeitar com motivo ou encaminhar para análise; não eliminar silenciosamente, não inventar entrada/saída e não considerar presença completa. | RF-022, RF-024, RF-038 |
| RN-013 | Evento offline | Conservar hora de origem, referência de fuso/desvio e hora de recepção; a hora de sincronização não substitui a de realização. Desvio suspeito gera pendência. | RF-024 a RF-026 |
| RN-014 | Confirmação ao colaborador | Distinguir guardado localmente, aceite centralmente e rejeitado; só remover da fila pendente após confirmação individual reconciliada. | RF-022, RF-025, RF-026 |
| RN-015 | Evento chega após suspensão, revogação ou expiração da autorização | Avaliar vigência à captura, validade das evidências e política de recepção tardia; enquanto essa política não estiver aprovada, encaminhar para análise, sem aceitação automática. | RF-001, RF-012, RF-019, RF-026 |
| RN-016 | Evento chega fora de ordem ou após fecho | Associar à jornada de origem quando determinável; não alterar período fechado. Evento tardio mantém pendência até decisão compatível com RN-038 e RN-039. | RF-024, RF-049, RF-050 |

### 4.3. Horários, pausas e apuramento

| ID | Condição | Regra / decisão | Referências |
| --- | --- | --- | --- |
| RN-017 | Turno atravessa a meia-noite | Tratar o turno como jornada contínua, preservando os dias civis e a atribuição de feriados segundo a política aprovada; a mudança de dia não cria falta por si só. | RF-014, RF-015, RF-038 |
| RN-018 | Formação de intervalos de trabalho | Usar pares coerentes de entrada/saída e pausas; sequência ambígua gera ocorrência. Intervalos sobrepostos não podem contar o mesmo tempo duas vezes. | RF-021, RF-024, RF-038 |
| RN-019 | Dedução ou remuneração de pausas | Aplicar classificação aprovada de pausa e método de cálculo; pausa já excluída dos intervalos não volta a ser deduzida. | RF-016, RF-038 |
| RN-020 | Avaliação de atraso ou saída antecipada | Comparar instante efectivo com referência do horário e tolerância aplicável. A política deve distinguir tolerância para classificar da eventual redução dos minutos contabilizados. | RF-014, RF-016, RF-038 |
| RN-021 | Arredondamento configurado | Preservar instantes originais e identificar regra, etapa e resultado arredondado; não aplicar arredondamentos cumulativos sem previsão explícita. | RF-017, RF-038, RF-039 |
| RN-022 | Ausência de eventos numa jornada prevista | Verificar calendário, vínculo, ausências aprovadas e marcações pendentes antes de concluir falta. Falha técnica ou biométrica isolada não prova ausência. | RF-024, RF-027, RF-038, RF-044 |
| RN-023 | Tempo além do horário ou em dia não previsto | Apurar como ocorrência candidata segundo política; distinguir tempo observado, elegível e aprovado. Presença fora do horário não constitui aprovação automática de horas extraordinárias. | RF-038, RF-040 |
| RN-024 | Recálculo de período aberto | Usar entradas e política identificadas, conservar versão anterior e motivo; repetir cálculo equivalente não acumula horas nem ajusta saldos novamente. | RF-039, RF-044 |

### 4.4. Férias, ausências e saldos

| ID | Condição | Regra / decisão | Referências |
| --- | --- | --- | --- |
| RN-025 | Submissão de ausência ou férias | Exigir tipo, intervalo válido, motivo e documentos previstos; distinguir dias, horas ou fracções conforme unidade aprovada, sem presumir conversão fixa. | RF-041, RF-042 |
| RN-026 | Pedido submetido | Encaminhar ao aprovador competente; submissão ou anexo por si só não significa aprovação nem alteração definitiva do apuramento. | RF-042, RF-043 |
| RN-027 | Pedido depende de saldo | Utilizar a fonte de referência e o estado de actualização definidos; reserva, débito e saldo negativo obedecem a política explícita. Sem saldo fiável, não aprovar automaticamente. | RF-041, RF-044 |
| RN-028 | Períodos de ausência sobrepostos ou ausência sobre tempo trabalhado | Sinalizar conflito e exigir resolução autorizada; não contabilizar simultaneamente o mesmo intervalo em categorias incompatíveis. | RF-038, RF-044, RF-045 |
| RN-029 | Ausência aprovada | Aplicar apenas o intervalo e efeitos autorizados; justificação de ausência não implica equivalência automática a tempo trabalhado ou pago. | RF-040, RF-043, RF-044 |
| RN-030 | Cancelamento de ausência aprovada | Exigir decisão competente e reverter os efeitos uma única vez; se afectar período fechado, aplicar primeiro o procedimento de reabertura. | RF-045, RF-050 |

### 4.5. Aprovações e correcções

| ID | Condição | Regra / decisão | Referências |
| --- | --- | --- | --- |
| RN-031 | Decisão sobre pedido | Validar competência e segregação de funções no momento da decisão; auto-aprovação depende de política explícita e permanece bloqueada enquanto não definida. | RF-007, RF-043, RF-047 |
| RN-032 | Aprovador ausente ou sem competência vigente | Encaminhar por delegação ou escalonamento autorizado, com âmbito e validade registados; a ausência do aprovador não autoriza outro utilizador automaticamente. | RF-012, RF-043, RF-054 |
| RN-033 | Correcção solicitada | Exigir motivo, alvo, valor anterior quando existente e valor proposto; a submissão não altera o registo de origem. Inclusão de marcação em falta deve estar identificada como ajuste. | RF-046, RF-047 |
| RN-034 | Correcção aprovada | Criar ajuste rastreável e recalcular apenas o âmbito permitido; conservar solicitante, decisor, data e relação com a evidência original. | RF-039, RF-047, RF-060 |
| RN-035 | Decisões concorrentes ou conteúdo alterado | Aplicar uma única decisão efectiva sobre a mesma versão; alteração posterior de conteúdo exige nova validação, não reutiliza aprovação anterior. | RF-043, RF-047 |
| RN-036 | Rejeição, devolução ou desistência | Registar estado, autor e motivo aplicável; não aplicar os efeitos solicitados. Desistência de pedido já aprovado segue cancelamento, não simples eliminação. | RF-043, RF-045, RF-047 |

### 4.6. Fecho e integração

| ID | Condição | Regra / decisão | Referências |
| --- | --- | --- | --- |
| RN-037 | Preparação do fecho | Validar pendências de marcações, pedidos, cálculos e integrações relevantes; pendência impeditiva bloqueia fecho. Excepções permitidas exigem competência e justificação. | RF-048, RF-049 |
| RN-038 | Período fechado | Bloquear alterações aos resultados por qualquer origem, incluindo API, importação, mudança de política e sincronização tardia; preservar versão, âmbito, autor e regras do fecho. | RF-049, RF-060 |
| RN-039 | Reabertura requerida | Exigir permissão e motivo, conservar fecho anterior e produzir nova versão no fecho seguinte; sinalizar versões já enviadas ao ERP para reconciliação. | RF-050, RF-058, RF-059 |
| RN-040 | Sincronização de dados mestre | Respeitar a fonte de referência por entidade ou campo; conflitos bidireccionais não se resolvem por sobrescrita silenciosa. | RF-013, RF-056, RF-057 |
| RN-041 | Envio de resultados definitivos ao ERP | Enviar somente âmbito fechado e aprovado, identificando tenant, período e versão; transferência técnica não equivale a confirmação de aplicação no destino. | RF-058, RF-059 |
| RN-042 | Reenvio, falha parcial ou revisão de resultado enviado | Repetir a mesma operação sem duplicar efeitos; versão revista usa referência própria e mecanismo acordado de substituição ou ajuste. Não reenviar como novo total sem reconciliação. | RF-050, RF-059 |

### 4.7. Biometria, dados e evidências

| ID | Condição | Regra / decisão | Referências |
| --- | --- | --- | --- |
| RN-043 | Enrollment ou utilização facial | Exigir habilitação nos âmbitos aplicáveis, identidade confirmada e política de tratamento aprovada; falha de qualidade não activa template incompleto. | RF-032, RF-033, RF-061 |
| RN-044 | Reconhecimento ou prova de vida falha | Não aceitar automaticamente a marcação e não concluir falta; oferecer método alternativo autorizado ou pedido assistido auditável. | RF-027, RF-034, RF-037 |
| RN-045 | Template activado, substituído, suspenso ou revogado | Identificar versão de enrollment, algoritmo, estado e vigência; propagação pendente a terminais deve ser visível e obedecer à validade offline aprovada. | RF-035, RF-036, RF-061 |
| RN-046 | Consulta, relatório ou exportação | Limitar dados ao âmbito e finalidade, indicar filtros e versão dos resultados, distinguir provisório de fechado e auditar exportações; excluir templates e imagens dos relatórios comuns. | RF-051 a RF-055, RF-060 |
| RN-047 | Retenção expira ou eliminação é solicitada | Avaliar categoria, política e impedimentos formalmente registados; acompanhar destinos pendentes. Revogação de utilização e eliminação são decisões distintas. | RF-036, RF-061, RF-062 |
| RN-048 | Restauro de cópia ou recuperação de serviço | Reaplicar revogações, eliminações e decisões posteriores à cópia antes da retoma, reconciliando marcações e integrações; não reactivar dados eliminados como consequência automática do restauro. | RF-059, RF-062, RF-065 |

## 5. Modelo de cálculo proposto

### 5.1. Ordem de avaliação

1. Validar tenant, identidade, origem e admissibilidade do evento.
2. Resolver reenvios, conflitos e instantes suspeitos.
3. Determinar vínculo, jornada, calendário e versões de política aplicáveis.
4. Aplicar ajustes aprovados sem substituir a evidência original.
5. Construir intervalos coerentes de presença e pausas; sinalizar lacunas.
6. Aplicar ausências aprovadas e resolver sobreposições incompatíveis.
7. Calcular tempos e classificar ocorrências conforme parâmetros aprovados.
8. Separar resultados calculados de decisões e horas aprovadas.
9. Publicar versão provisória ou manter pendência; fecho segue RN-037 a RN-039.

### 5.2. Grandezas e limites das fórmulas

Para intervalos de presença válidos, `P` representa a união desses intervalos. `B` representa a união das pausas que a política manda deduzir e que ainda estejam incluídas em `P`. O tempo líquido observado pode ser representado por:

`T_observado = duração(P) − duração(P ∩ B)`

Esta formulação evita dupla contagem de intervalos sobrepostos e dupla dedução de pausas. Não determina, por si só, tempo remunerado, saldo contratual ou horas extraordinárias.

Para horário fixo com referências de entrada e saída definidas:

- `Atraso_bruto = máximo(0, entrada_efectiva − entrada_prevista)`.
- `Saída_antecipada_bruta = máximo(0, saída_prevista − saída_efectiva)`.

Estas fórmulas exigem eventos válidos associados à mesma jornada. Horários flexíveis e jornadas com múltiplos períodos precisam de referências próprias. Se faltar um evento, a grandeza dependente permanece indeterminada, não é substituída por zero.

Tolerância pode afectar apenas a classificação ou também o tempo contabilizado; essa escolha pertence a PN-03. Também dependem de aprovação o tratamento de presença fora do horário, pausas pagas, feriados, arredondamento e horas extraordinárias. Nenhuma fórmula deste documento calcula salário ou aplica taxas legais.

## 6. Tabelas de decisão e exemplos de validação

### 6.1. Recepção de eventos

Avaliar pela ordem indicada; a primeira condição aplicável determina o tratamento inicial.

| Ordem | Condição | Tratamento |
| --- | --- | --- |
| 1 | Tenant/origem não autorizado ou informação obrigatória inválida | Rejeitar com motivo ou encaminhar para excepção autorizada; não apurar presença |
| 2 | Mesmo identificador e conteúdo divergente | Registar conflito, preservar original |
| 3 | Mesmo identificador e conteúdo equivalente | Devolver resultado existente, sem novo efeito |
| 4 | Evento depende de autorização histórica ou relógio suspeito não resolvido | Manter pendente de análise |
| 5 | Evento afecta período fechado | Preservar evento como pendente de tratamento, sem alterar resultado fechado |
| 6 | Sequência ambígua ou possível duplicação entre eventos distintos | Registar ocorrência segundo política e impedir resultado definitivo afectado |
| 7 | Dados e contexto válidos em período aberto | Aceitar para processamento; não presumir aprovação de horas extraordinárias |

### 6.2. Exemplo de tolerância — valores exclusivamente ilustrativos

Considere entrada prevista às 08:00 e tolerância hipotética de 5 minutos, com fronteira inclusiva aprovada apenas para este exemplo.

| Entrada | Atraso bruto | Classificação ilustrativa | Minutos a contabilizar |
| --- | --- | --- | --- |
| 08:00 | 0 min | Sem atraso | 0 |
| 08:04 | 4 min | Dentro da tolerância | Depende de PN-03 |
| 08:05 | 5 min | Dentro da tolerância | Depende de PN-03 |
| 08:06 | 6 min | Fora da tolerância | Pode ser 6 ou 1, conforme política aprovada; não escolher implicitamente |
| Sem entrada válida | Indeterminado | Marcação incompleta | Pendente de resolução |

### 6.3. Exemplos de integridade e cálculo

| ID | Situação | Resultado esperado | Regras |
| --- | --- | --- | --- |
| EX-01 | Entrada 22:00, saída 06:00 do dia seguinte, pausa válida 02:00–02:30 incluída na presença e configurada como dedutível | 8 h de presença bruta e 7 h 30 min de tempo líquido observado; sem falta artificial à meia-noite | RN-017 a RN-019 |
| EX-02 | Presença já representada por 08:00–12:00 e 13:00–17:00, com pausa 12:00–13:00 | 8 h observadas; a pausa fora dos intervalos não é deduzida novamente | RN-018, RN-019 |
| EX-03 | Terminal reenvia evento após perda da confirmação central | Uma única marcação efectiva, com tentativas reconciliáveis | RN-010, RN-014 |
| EX-04 | Colaborador regista 10 h num dia cuja jornada prevista é de 8 h | Diferença pode originar ocorrência candidata; nenhuma aprovação automática de 2 h extraordinárias | RN-023 |
| EX-05 | Ausência aprovada cobre intervalo em que existem marcações | Conflito a resolver segundo política; não contar o intervalo em categorias incompatíveis | RN-028, RN-029 |
| EX-06 | Correcção aprovada após alteração concorrente do mesmo registo | Revalidar a versão; não sobrescrever silenciosamente a alteração anterior | RN-033 a RN-035 |
| EX-07 | Evento de ontem chega hoje, mas ontem pertence a período fechado | Preservar evento e pendência; alterar resultado apenas após reabertura autorizada | RN-016, RN-038, RN-039 |
| EX-08 | ERP confirmou versão 1 e RH fecha versão 2 após correcção | Reconciliar substituição ou ajuste conforme contrato; não duplicar o total do período | RN-039, RN-041, RN-042 |
| EX-09 | Reconhecimento facial falha três vezes | Encaminhar para alternativa conforme limite aprovado; três tentativas são exemplo, não parâmetro estabelecido; falha não gera falta automática | RN-022, RN-044 |
| EX-10 | Restauro contém template eliminado após a data da cópia | Reaplicar eliminação antes de retomar a utilização, mantendo evidência da reconciliação | RN-047, RN-048 |

Os exemplos são cenários para o futuro Plano de Testes e não testes executados nesta versão.

## 7. Parâmetros e decisões pendentes

| ID | Parâmetro / decisão | Responsável proposto | Regras afectadas |
| --- | --- | --- | --- |
| PN-01 | Precedência por categoria, fuso de referência, vigências e tratamento de sobreposição de políticas | RH | RN-006, RN-007, RN-017 |
| PN-02 | Referências de horários fixos/flexíveis, associação à jornada e atribuição de feriados em turnos nocturnos | RH | RN-017, RN-018, RN-020 |
| PN-03 | Tolerâncias, fronteiras inclusivas/exclusivas e efeito sobre classificação e minutos contabilizados | RH | RN-020 |
| PN-04 | Pausas pagas/dedutíveis, limites, arredondamentos e sequência de aplicação | RH | RN-019, RN-021 |
| PN-05 | Elegibilidade, limites e aprovação de horas extraordinárias e trabalho fora do horário | RH e negócio | RN-023 |
| PN-06 | Janela de duplicação, validade offline, desvio de relógio, recepção tardia e revogação | RH e equipa técnica | RN-009 a RN-016; DF-03 e DN-03 |
| PN-07 | Tipos de ausência, unidades, documentos, contagem de dias, fonte de saldos, reservas e saldo negativo | RH e equipa ERP | RN-025 a RN-030 |
| PN-08 | Aprovadores, delegações, auto-aprovação, prazos de pedido/decisão e desistência | RH e administração | RN-026, RN-031 a RN-036; DF-02 |
| PN-09 | Âmbito e calendário de fecho, pendências impeditivas, excepções e poderes de reabertura | RH | RN-037 a RN-039 |
| PN-10 | Fonte de referência por entidade/campo, conflitos e substituição/ajuste de resultados no ERP | Equipa ERP e RH | RN-040 a RN-042; DF-06 |
| PN-11 | Métodos por contexto, habilitação biométrica, prova de vida, limiares e alternativa de contingência | Negócio, equipa técnica e responsável de dados | RN-009, RN-043 a RN-045; DF-01, DF-04 e DN-05 |
| PN-12 | Finalidades, destinatários, retenção por categoria, impedimentos, propagação e restauro | Responsável de dados e operação | RN-046 a RN-048; DF-07, DF-08 e DN-06 |

DF identifica decisões do documento funcional e DN decisões do documento não funcional. Nenhum valor pendente deve ser preenchido pela equipa de implementação com uma política de negócio presumida.

## 8. Rastreabilidade

| Regra do BRD detalhado | Regras deste documento |
| --- | --- |
| BR-RN-001 — Identidade e tenant da marcação | RN-001, RN-003, RN-008 |
| BR-RN-002 — Horário e fuso vigentes | RN-006, RN-007, RN-017 |
| BR-RN-003 — Hora de origem e sincronização | RN-013, RN-015 |
| BR-RN-004 — Duplicação | RN-010, RN-011, RN-042 |
| BR-RN-005 — Evento inválido | RN-008, RN-012, RN-016 |
| BR-RN-006 — Correcção auditável | RN-033 a RN-036 |
| BR-RN-007 — Período fechado | RN-037 a RN-039 |
| BR-RN-008 — Utilização facial autorizada | RN-009, RN-043 |
| BR-RN-009 — Alternativa biométrica | RN-022, RN-044 |
| BR-RN-010 — Versão e validade biométrica | RN-045 |
| BR-RN-011 — Âmbito de acesso | RN-002, RN-005, RN-031, RN-032 |
| BR-RN-012 — Exportação limitada e auditada | RN-046 |
| BR-RN-013 — Versão do cálculo | RN-007, RN-024, RN-038 |
| BR-RN-014 — Fonte de referência | RN-027, RN-040 a RN-042 |
| BR-RN-015 — Retenção e eliminação | RN-047, RN-048 |

As regras adicionais de apuramento e ausências decompõem BR-02, BR-07 e BR-08 do BRD resumido e as secções 7.3, 7.6 e 7.7 do BRD detalhado. RN-004 e RN-014 detalham o ciclo de vida do colaborador e a continuidade descritos nas secções 7.2 e 7.4 desse BRD. As referências RF no catálogo permitem ligar cada regra aos futuros casos de uso e testes.

## 9. Validação e gestão de alterações

| Papel | Validação necessária | Estado |
| --- | --- | --- |
| RH / responsável de negócio | Políticas, parâmetros, cálculos, ausências e aprovações | Pendente |
| Administração | Âmbitos e delegações | Pendente |
| Equipa técnica | Viabilidade, estados, integridade e excepções | Pendente |
| Equipa ERP | Fontes de referência, reconciliação e revisões | Pendente |
| Responsável de dados / operação | Biometria, retenção, eliminação e restauro | Pendente |

A validação deve identificar nome, versão, data e parâmetros aprovados. Mudanças posteriores devem registar motivo, regras afectadas, âmbito, vigência, impacto nos resultados históricos e necessidade de reabertura ou reconciliação. A aprovação de uma política não autoriza a aplicação retroactiva sem essa decisão explícita.

## 10. Referências

- [Índice da documentação](README.MD).
- [BRD resumido](01-BRD.md).
- [BRD detalhado](BRD_Sistema_Gestao_Assiduidade.md).
- [Requisitos Funcionais](02-Requisitos-Funcionais.md).
- [Requisitos Não Funcionais](03-Requisitos-Nao-Funcionais.md).

Os Casos de Uso e o Plano de Testes devem referenciar os identificadores RN e os parâmetros PN, mantendo separadas a regra aprovada, a configuração aplicada e a evidência de execução.
