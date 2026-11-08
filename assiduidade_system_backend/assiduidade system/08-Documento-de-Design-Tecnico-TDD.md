# Documento de Design Técnico (TDD) — Sistema de Gestão de Assiduidade

## 1. Controlo do documento

| Campo | Valor |
| --- | --- |
| Referência | TDD-ASS-001 |
| Versão | 0.3 |
| Data | 25/09/2026 |
| Estado | Rascunho técnico para validação |
| Responsáveis | Equipa técnica, com validação de RH, negócio, equipa ERP, operação e responsável de dados — nomes a designar |
| Base documental | Documentos 01 a 06 e documentos técnicos 07 e 09 a 19 |

| Versão | Data | Alteração |
| --- | --- | --- |
| 0.1 | 25/09/2026 | Primeira estrutura, extraída de um TDD único |
| 0.2 | 25/09/2026 | Versão detalhada: princípios, mecanismos transversais, registo de decisões técnicas, riscos e rastreabilidade |
| 0.3 | 25/09/2026 | Terminologia de autorização alinhada com permissões granulares `módulo:acção` e âmbito ([Requisitos Funcionais §3](02-Requisitos-Funcionais.md)) |

## 2. Objectivo, âmbito e convenções

Este documento define as decisões de desenho **transversais** — válidas para mais do que um componente — e serve de baseline aos documentos técnicos especializados. Não descreve a implementação actual; quando a refere, fá-lo como situação observada a reconciliar.

| Documento | Responde a |
| --- | --- |
| [07 — Arquitectura](07-Arquitectura-do-Sistema.md) | Que contentores e componentes existem, como comunicam e onde correm |
| **08 — TDD (este)** | Que mecanismos técnicos comuns todos os componentes aplicam e que decisões técnicas estão pendentes |
| [09 — Modelo de Dados](09-Modelo-de-Dados.md) | Como os dados são estruturados, restringidos e versionados |
| [10 — APIs](10-Especificacao-de-APIs.md) | Que contratos são expostos e com que semântica |
| [11](11-Especificacao-de-Dispositivos-Terminais.md) a [19](19-Fluxos-de-Processos.md) | Especialização por domínio técnico |

Convenções:

- **PD-xx** identifica princípios de desenho; **MEC-xx** mecanismos transversais; **DT-xx** decisões técnicas pendentes; **RT-xx** riscos técnicos. Os identificadores são estáveis.
- **DT-xx são definidos apenas neste documento.** Os códigos DF e DN pertencem aos [Requisitos Funcionais §9](02-Requisitos-Funcionais.md) e aos [Requisitos Não Funcionais §8](03-Requisitos-Nao-Funcionais.md); PN às [Regras de Negócio §7](04-Regras-de-Negocio.md); DU aos [Diagramas UML §12](06-Diagramas-UML.md).
- Em caso de divergência, prevalecem os documentos 02 a 06. Uma divergência encontrada aqui deve ser corrigida na origem, não resolvida silenciosamente no desenho.
- Nomes de componentes seguem DG-CP-01 do documento 06.

## 3. Princípios de desenho

| ID | Princípio | Consequência obrigatória no desenho | Origem |
| --- | --- | --- | --- |
| PD-01 | A evidência de origem nunca é substituída silenciosamente | Eventos, pedidos e fechos são imutáveis após registo; correcções criam ajustes ligados ao original; não existe remoção física de eventos de assiduidade por operação corrente | RN-006 (BRD), RN-012, RN-033, RN-034 |
| PD-02 | A autorização é verificada no serviço executor | O tenant e os identificadores enviados pelo cliente são indicações; o contexto é resolvido no servidor (MEC-01) | RF-002, RN-002, RNF-013 |
| PD-03 | Online e offline são estados distintos | Gravação local nunca é apresentada como aceitação central; respostas distinguem os dois estados | RF-022, RN-014 |
| PD-04 | O processamento é determinístico e versionado | Cada apuramento identifica entradas, políticas, ajustes e versão; repetir com as mesmas entradas produz o mesmo resultado | RN-007, RN-024 |
| PD-05 | A biometria é minimizada e separada | Templates e imagens não circulam no domínio comum, em logs, relatórios ou respostas não autorizadas | RF-037, RN-046, RNF-020 |
| PD-06 | Todas as operações que alteram estado são idempotentes | Reenvios, timeouts e sincronizações repetidas não duplicam efeitos (MEC-02) | RN-010, RN-042, RNF-009 |
| PD-07 | O fecho é uma fronteira de imutabilidade | Resultados fechados não são actualizados; reabertura produz nova versão | RN-038, RN-039 |
| PD-08 | Estados e transições são explícitos | Cada objecto com ciclo de vida tem máquina de estados; transições não desenhadas são recusadas (MEC-09) | RF §6, DG-ES-01 a DG-ES-09 |
| PD-09 | Nenhum parâmetro pendente é preenchido por defeito | Parâmetros PN/DF/DN sem aprovação deixam o resultado dependente em estado pendente de configuração | RN §2, RN-006 |

## 4. Mecanismos transversais

Cada mecanismo descreve o problema, o desenho proposto, as regras que a implementação tem de cumprir e a forma de verificação.

### 4.1. MEC-01 — Resolução do contexto de execução

**Problema.** Isolamento e autorização dependem de saber, em cada operação, o tenant, o actor, as suas permissões efectivas `módulo:acção` (cargo, permissões directas e tipo de utilizador) e o âmbito (próprio, hierárquico ou global) — [Requisitos Funcionais §3.1](02-Requisitos-Funcionais.md).

**Desenho.** A Entrada da API resolve o contexto a partir da credencial (sessão de utilizador, credencial de dispositivo ou contexto de tarefa). O contexto é imutável durante o pedido e é propagado aos componentes, à persistência e ao envelope das mensagens (MEC-08).

| Origem da operação | Fonte do tenant | Fonte do actor |
| --- | --- | --- |
| Utilizador do backoffice ou app | Sessão autenticada; em utilizadores multi-tenant, selecção explícita validada no servidor | Conta de utilizador |
| Terminal | Credencial do dispositivo (DT-05) | Dispositivo e, após identificação, colaborador |
| Tarefa agendada ou evento interno | Envelope da tarefa, criado por operação autorizada | Conta técnica da tarefa, com permissões próprias e limitadas |
| Integração | Configuração da integração (UC-19) | Conta técnica da integração |

**Regras.** Mensagens ou tarefas sem tenant são recusadas. Uma operação nunca muda de tenant a meio. Consultas à base aplicam filtro obrigatório de tenant (DT-04).
**Verificação.** Testes negativos de CA-01 em todas as superfícies de RNF-013, incluindo tarefas de fundo.

### 4.2. MEC-02 — Idempotência de comandos

**Problema.** Respostas perdidas, reenvios e retries não podem duplicar efeitos (RN-010, RNF-009).

**Desenho.** Todo o comando que altera estado aceita uma chave de idempotência (`Idempotency-Key` ou identificador estável do evento). O servidor guarda, por `(tenant, âmbito da chave, chave)`, o hash canónico do pedido, o estado de processamento e a resposta.

| Situação | Resposta |
| --- | --- |
| Chave nova | Processa e guarda a resposta |
| Mesma chave, mesmo hash, processamento concluído | Devolve a resposta guardada, sem novo efeito |
| Mesma chave, mesmo hash, processamento em curso | Resposta de conflito temporário com indicação para repetir |
| Mesma chave, hash diferente | Conflito de idempotência; o pedido original é preservado |

**Regras.** A retenção das chaves é superior à janela máxima de reenvio offline (DN-03). O hash é calculado sobre representação canónica. A chave não substitui a validação de negócio de possíveis duplicados entre eventos distintos (RN-011).
**Verificação.** CA-02, CA-07, EX-03; injecção de perda de resposta em cada endpoint de escrita.

### 4.3. MEC-03 — Identificador estável de evento gerado na origem

**Desenho.** O terminal ou aplicação gera um UUID para cada evento no momento da captura, antes de qualquer tentativa de envio. Esse identificador é a chave de idempotência da marcação e acompanha o evento até ao apuramento. A unicidade é garantida por `(tenant, identificador do evento)`.

**Regras.** O identificador nunca é regenerado em reenvios. Eventos criados no backoffice (marcação assistida, importação) recebem identificador no servidor antes da gravação.

### 4.4. MEC-04 — Tratamento do tempo

**Problema.** Turnos nocturnos, terminais offline e relógios desviados exigem distinguir vários instantes (RN-013, RN-017, RNF-012).

| Grandeza | Definição | Fonte |
| --- | --- | --- |
| Instante de origem | Momento da captura, em UTC | Relógio do dispositivo |
| Desvio de origem | Offset e fuso IANA do contexto da captura (ex.: `Africa/Maputo`) | Configuração do local/terminal |
| Desvio de relógio estimado | Diferença entre relógio do dispositivo e referência do servidor na última sincronização | Protocolo de sincronização (DT-09) |
| Instante de recepção | Momento em que o serviço central recebeu o evento | Relógio do servidor |
| Data de referência da jornada | Dia civil a que a jornada pertence, determinado pelo horário aplicável | Apuramento (RN-017) |

**Regras.** Todos os instantes são guardados em UTC com o fuso de referência. A data de referência nunca é derivada apenas da data civil do instante (um turno 22:00–06:00 pertence a uma única jornada). Desvio de relógio acima do limite de PN-06 coloca o evento em pendência (RN-013). A apresentação usa o fuso do contexto do evento, não o do utilizador que consulta (RF-003).

### 4.5. MEC-05 — Versionamento de configuração e políticas

**Desenho.** Horários, calendários, políticas, papéis e configuração de terminais são entidades versionadas: cada versão tem vigência, aprovador, motivo e estado (`rascunho`, `activa`, `substituída`). Uma versão activa nunca é editada; alterar cria nova versão.

**Regras.** Resultados referenciam as versões aplicadas (RN-007, BR-RN-013). Vigências da mesma associação exclusiva não se sobrepõem. Activação com parâmetros pendentes é recusada (PD-09).

### 4.6. MEC-06 — Apuramento determinístico e versionado

**Desenho.** O apuramento de uma jornada ou período recebe um conjunto de entradas (eventos aceites, ajustes aprovados, ausências aprovadas, versões de política) e produz uma versão de resultado. O hash canónico das entradas (`input_snapshot_hash`) identifica a versão: recalcular com o mesmo hash não cria nova versão.

**Regras.** O resultado anterior é conservado e ligado ao novo, com motivo do recálculo (RN-024). Períodos fechados não são recalculados (DG-AC-02). Grandezas indeterminadas por falta de evento são representadas como indeterminadas, nunca como zero (RN §5.2). Projecções derivadas usadas por relatórios são reconstruíveis a partir das entradas e nunca editadas à mão (DT-11).
**Verificação.** EX-01, EX-02, EX-04; regressão com conjunto de referência aprovado por RH (RNF-038).

### 4.7. MEC-07 — Controlo de concorrência

**Desenho.** Objectos sujeitos a decisão (pedidos, períodos, políticas, referências biométricas) têm número de versão. Decisões e transições indicam a versão sobre a qual actuam; o servidor aplica a transição apenas se a versão coincidir (controlo optimista). O fecho de período adquire exclusão sobre o âmbito durante a validação final.

**Regras.** Duas decisões sobre a mesma versão produzem uma decisão efectiva e um conflito (RN-035). Alteração de conteúdo de um pedido em aprovação cria nova versão e invalida decisões pendentes (DG-ES-03, DU-04).
**Verificação.** CA-05, EX-06; testes concorrentes de RNF-010.

### 4.8. MEC-08 — Mensagens assíncronas e outbox transaccional

**Desenho.** Efeitos assíncronos (apuramento, integração, notificação, propagação, retenção) são publicados através de uma tabela de saída gravada na mesma transacção da alteração de negócio e entregue por um processo dedicado (DT-03). O envelope de cada mensagem contém:

| Campo | Finalidade |
| --- | --- |
| `message_id` | Identificador único da mensagem; permite deduplicação no consumidor |
| `tenant_id` | Contexto obrigatório (MEC-01) |
| `correlation_id` | Liga a mensagem ao pedido ou tarefa de origem |
| `occurred_at` | Instante do facto de negócio |
| `schema_version` | Versão do contrato da mensagem |
| `idempotency_key` | Chave do efeito de negócio no consumidor |
| `type` | Tipo de evento de domínio (07 §7) |

**Regras.** Consumidores são idempotentes. Tentativas têm limite e backoff exponencial com variação aleatória; após o limite, a mensagem passa a estado de erro visível à operação (RF-063). Timeout nunca é convertido em sucesso (RNF-011). A ordem só é garantida por chave de partição (tenant e colaborador ou terminal).

### 4.9. MEC-09 — Máquinas de estado

**Desenho.** Cada objecto com ciclo de vida implementa uma tabela de transições permitidas, alinhada com RF §6 e DG-ES-01 a DG-ES-09. A transição valida estado de origem, permissão, pré-condições e versão (MEC-07), regista evidência (MEC-10) e publica o evento de domínio correspondente.

**Regras.** Estados só existem se estiverem na origem funcional; estados técnicos adicionais (ex.: processamento em curso) ficam em campos separados e não alteram o estado de negócio. Divergências conhecidas estão em DU-02 a DU-07 e no [Modelo de Dados §6](09-Modelo-de-Dados.md).

### 4.10. MEC-10 — Evidência de operações críticas

**Desenho.** Operações críticas (catálogo do [documento 16](16-Auditoria-e-Logs.md)) gravam o evento de auditoria na mesma transacção da alteração, ou numa persistência durável alternativa aprovada (DN-09). Auditoria de leitura sensível (consultas de suporte, exportações) é gravada antes da entrega do resultado.

**Regras.** Falha de gravação da evidência impede a operação crítica ou desvia-a para a persistência alternativa; nunca aceita a alteração sem evidência recuperável (RNF-026).

### 4.11. MEC-11 — Propagação a destinos com estado por destino

**Desenho.** Alterações que têm de chegar a terminais ou sistemas externos (configuração, revogações, suspensão e eliminação de templates) criam um registo por destino com estado `pendente`, `confirmado` ou `falhado`. A operação global só é dada como concluída quando todos os destinos aplicáveis confirmarem.

**Regras.** Destinos offline permanecem pendentes e sujeitos à validade offline aprovada (RN-045, DF-03). Não existe conclusão por excepção administrativa sem política aprovada (RF-036).

### 4.12. MEC-12 — Erros normalizados e correlação

**Desenho.** Todos os erros seguem o formato do [documento 10 §4](10-Especificacao-de-APIs.md). Cada pedido recebe `request_id`; cada cadeia de processamento transporta `correlation_id` (pedido → mensagens → integrações → auditoria).

**Regras.** Mensagens de erro não revelam dados de terceiros nem a existência de objectos fora do âmbito (resposta equivalente a "não encontrado"). Rejeições de negócio distinguem-se de falhas técnicas nas métricas (RNF-027).

### 4.13. MEC-13 — Protecção de dados por desenho

**Desenho.** Dados biométricos ficam em armazenamento lógico separado, acessível apenas à Gestão biométrica (07 CMP-07). Logs e métricas aplicam lista de campos permitidos, não lista de campos proibidos. Exportações aplicam projecção por finalidade (RN-046).

## 5. Tratamento de falhas

| Cenário | Comportamento exigido | Mecanismos | Referências |
| --- | --- | --- | --- |
| Resposta perdida após gravação central | Reenvio devolve o resultado existente | MEC-02, MEC-03 | CA-02, EX-03 |
| Terminal reinicia com fila pendente | Fila persiste; reenvio com os mesmos identificadores | MEC-03, [11 §6](11-Especificacao-de-Dispositivos-Terminais.md) | RNF-007 |
| Relógio do terminal desviado | Evento aceite em pendência com motivo | MEC-04 | RN-013, PN-06 |
| Duas decisões concorrentes | Uma efectiva, outra em conflito | MEC-07 | CA-05, EX-06 |
| ERP indisponível ou timeout | Execução em erro visível; consulta antes de reenviar | MEC-08, [18](18-Integracoes-com-Sistemas-Externos.md) | CA-07, RNF-011 |
| Evento tardio sobre período fechado | Evento preservado em pendência; resultado fechado inalterado | MEC-09 | CA-06, EX-07 |
| Componente biométrico indisponível | Sem aceitação automática; alternativa autorizada | [12 §7](12-Reconhecimento-Facial-e-Liveness.md) | CA-04, RN-044 |
| Destino de auditoria indisponível | Bloqueio ou persistência alternativa | MEC-10 | RNF-026 |
| Terminal offline durante revogação | Destino pendente; validade offline limita utilização | MEC-11 | CA-08 |
| Restauro de cópia antiga | Reaplicação de revogações e eliminações antes da retoma | [17 §8](17-Seguranca-e-Proteccao-de-Dados.md) | EX-10, RN-048 |

## 6. Estratégia de testes técnicos

| Mecanismo / área | Tipo de teste | Cenários de referência |
| --- | --- | --- |
| MEC-01, isolamento | Testes negativos por superfície, incluindo tarefas de fundo | CA-01, CA-09 |
| MEC-02, MEC-03 | Injecção de falhas de rede e reenvio | CA-02, CA-07, EX-03 |
| MEC-04 | Unitários de tempo: meia-noite, mudança de fuso, desvio de relógio | CA-03, EX-01 |
| MEC-05, MEC-06 | Regressão determinística com conjunto de referência de RH | EX-01, EX-02, EX-04, EX-05 |
| MEC-07 | Concorrência (decisões e fecho simultâneos) | CA-05, EX-06 |
| MEC-08 | Contrato de mensagens, consumidores repetidos, fila de erro | CA-07, EX-08 |
| MEC-09 | Tabela de transições: todas as transições não desenhadas são recusadas | DG-ES-01 a DG-ES-09 |
| MEC-10 | Falha do destino de auditoria | RNF-026 |
| MEC-11 | Propagação com destino offline e restauro | CA-08, EX-10 |
| Carga | Pico de mudança de turno, reconexão em massa, relatórios concorrentes | RNF-001 a RNF-005, DN-01 |

Os identificadores CA pertencem ao [documento 02 §7](02-Requisitos-Funcionais.md) e EX ao [documento 04 §6.3](04-Regras-de-Negocio.md). O [Plano de Testes](21-Plano-de-Testes.md) deve atribuir identificadores de teste próprios e ligá-los a estes cenários.

## 7. Registo de decisões técnicas pendentes

As propostas abaixo orientam o desenho, mas só se tornam decisões quando aprovadas pelo responsável técnico e, quando indicado, pelos restantes validadores. Até lá, o desenho deve funcionar com qualquer das opções ou identificar explicitamente a dependência.

| ID | Decisão | Opções | Proposta para avaliação | Documentos afectados |
| --- | --- | --- | --- | --- |
| DT-01 | Relação desta especificação com o módulo de assiduidade existente do Nexora ERP (`/api/rh`, `/api/self-service`, `/api/hardware`, esquema `rh`) | (a) evoluir o módulo existente para cumprir a especificação; (b) novo serviço com migração; (c) contrato novo como fachada sobre o existente | (a), com contrato versionado publicado; exige plano de lacunas (07 §13, 09 §9, 10 §9) | 07, 09, 10, 11, 12, 28 |
| DT-02 | Forma de implantação | Monólito modular com processos de trabalho separados; serviços independentes | Monólito modular: os componentes de DG-CP-01 são módulos com fronteiras de dados, implantados em processos de API e de trabalho | 07, 22, 23 |
| DT-03 | Mensageria | Outbox em PostgreSQL com processo de entrega; broker dedicado | Outbox em PostgreSQL na primeira entrega; broker só se DN-01 o justificar | 07, 18, 23 |
| DT-04 | Mecanismo de isolamento de dados | Filtro aplicacional obrigatório; Row-Level Security; esquemas por tenant | Filtro obrigatório na camada de persistência mais Row-Level Security como segunda barreira | 09, 13 |
| DT-05 | Credencial de dispositivo | Chave de API estática (situação actual); token assinado por dispositivo com rotação; certificado de cliente | Credencial por dispositivo, revogável e com rotação; chave estática partilhada não é aceitável em produção | 10, 11, 17 |
| DT-06 | Identificadores | Inteiro sequencial; UUID; ambos | Inteiro interno mais UUID público exposto na API; o identificador de evento é sempre UUID gerado na origem (MEC-03) | 09, 10 |
| DT-07 | Armazenamento de auditoria | Tabela append-only com encadeamento de hash; serviço externo imutável; ambos | Tabela append-only com encadeamento de hash e cópia periódica para destino imutável | 09, 16 |
| DT-08 | Persistência de resultados versionados | Tabela de versões por apuramento e fecho; recálculo a pedido | Versões persistidas; projecções derivadas reconstruíveis | 09 |
| DT-09 | Protocolo de sincronização offline | Tamanho de lote, ordem, compressão, resposta por item, sincronização de relógio | Lotes limitados com resposta por item e troca de referência temporal em cada ligação | 10, 11 |
| DT-10 | Gestão de chaves e segredos | Gestor de segredos dedicado; cofre do fornecedor de infraestrutura; variáveis de ambiente | Gestor de segredos com acesso auditado e chaves de cifragem separadas por classe de dados | 17, 22 |
| DT-11 | Modelo de leitura para relatórios | Réplica de leitura; projecções derivadas; ambos | Projecções derivadas reconstruíveis a partir das entradas, com réplica quando DN-01 o exigir | 09, 23 |
| DT-12 | Convenção de nomes em APIs e tabelas | Português, coerente com o ERP existente; inglês, como na versão 0.1 do 09 e 10 | Português, coerente com o ERP existente e com os documentos 02 a 06 | 09, 10 |

Decisões funcionais e não funcionais com impacto directo no desenho técnico:

| Tema técnico | Decisões de origem | Impacto |
| --- | --- | --- |
| Métodos de marcação obrigatórios e alternativos por contexto | DF-01 | Hardware, UX e privacidade |
| Mecanismo de identidade, recuperação de conta e autenticação reforçada | DF-02, DN-04 | IAM e suporte |
| Operação offline e eventos capturados antes de suspensão/revogação | DF-03, DN-03 | Integridade e contencioso |
| Componente biométrico, local de processamento e limiares | DF-04, DN-05 | Segurança, desempenho e custos |
| Fonte de referência de colaboradores, horários e saldos | DF-06 | Integração e reconciliação |
| Contrato ERP, formato, periodicidade e reaberturas | DF-06, DN-10 | Fecho e processamento salarial |
| Volumetria, P95 e crescimento | DN-01 | Infraestrutura e testes |
| Percursos críticos e definição de disponibilidade | DN-02 | SLA e monitorização |
| RTO/RPO e classes de serviço | DN-07 | Backup e continuidade |
| Política de retenção e eliminação por categoria | DF-08, DN-06 | Protecção de dados |
| Critérios quantitativos de FAR/FRR e anti-spoofing | DN-05 | Aceitação biométrica |
| Modelos de terminal Android e periféricos | DF-01, DN-08 | Procurement e rollout |

## 8. Riscos técnicos

| ID | Risco | Impacto | Resposta proposta | Relacionado |
| --- | --- | --- | --- | --- |
| RT-01 | O módulo existente tem remoção física e ausência de versões (ver 09 §9) | Perda de evidência e resultados não reprodutíveis | Plano de lacunas antes do piloto; bloquear remoções físicas | DT-01, PD-01 |
| RT-02 | Credencial de dispositivo partilhada ou estática | Marcações fraudulentas em nome de terminais | DT-05 antes do piloto | RNF-014, [17](17-Seguranca-e-Proteccao-de-Dados.md) |
| RT-03 | Desvio de relógio em terminais sem sincronização | Classificação errada de atrasos | MEC-04 e limites PN-06 | RN-013 |
| RT-04 | Filtro de tenant esquecido numa consulta nova | Fuga entre tenants | DT-04 com segunda barreira e testes CA-01 automáticos | RNF-013 |
| RT-05 | Recálculo não determinístico (ordem, arredondamentos, fuso) | Resultados divergentes entre execuções | MEC-06 e regressão de referência | RN-024 |
| RT-06 | Pico de reconexão após falha de rede de um local | Saturação e atraso de visibilidade | Limites por tenant e lote (DT-09), filas com contrapressão | RNF-005 |
| RT-07 | Dependência de um fornecedor biométrico sem métricas verificáveis | Aceitação biométrica sem evidência | Ensaio independente antes da adopção | DF-04, DN-05 |
| RT-08 | Parâmetros de RH por aprovar no início da construção | Implementação com valores presumidos | PD-09 e estado pendente de configuração | PN-01 a PN-12 |

## 9. Critérios de aprovação do TDD

O TDD pode ser promovido a baseline quando:

- DT-01 a DT-06 estiverem decididos, por condicionarem modelo de dados, APIs e segurança;
- RH aprovar as regras e os exemplos de cálculo de referência (PN-01 a PN-09);
- o responsável de dados aprovar finalidade, retenção e tratamento biométrico (DF-04, DF-08, DN-06);
- a equipa ERP aprovar contratos e reconciliação (DF-06);
- a equipa técnica aprovar volumetria e metas (DN-01), e a operação aprovar disponibilidade, cópias, recuperação e suporte (DN-02, DN-07).

A primeira entrega só deve ser aceite quando os requisitos essenciais tiverem evidência de teste, o isolamento entre tenants tiver sido validado, os casos de falha offline e de integração forem reconciliáveis, o fecho for imutável sem reabertura autorizada e não existirem defeitos impeditivos de produção.

## 10. Rastreabilidade

| Elemento | Requisitos funcionais | Regras | Requisitos não funcionais |
| --- | --- | --- | --- |
| PD-01, MEC-10 | RF-046, RF-047, RF-060 | RN-012, RN-033, RN-034 | RNF-025, RNF-026 |
| PD-02, MEC-01 | RF-002, RF-007, RF-008 | RN-001, RN-002 | RNF-013, RNF-014 |
| PD-03, MEC-03 | RF-022, RF-025, RF-026 | RN-013, RN-014 | RNF-007, RNF-008 |
| PD-04, MEC-05, MEC-06 | RF-016, RF-038, RF-039 | RN-007, RN-024 | RNF-038 |
| PD-05, MEC-13 | RF-037, RF-053, RF-061 | RN-046 | RNF-020, RNF-021 |
| PD-06, MEC-02, MEC-08 | RF-023, RF-026, RF-059 | RN-010, RN-042 | RNF-009, RNF-011 |
| PD-07 | RF-049, RF-050 | RN-038, RN-039 | RNF-010 |
| PD-08, MEC-09 | RF §6 | RN-035 | RNF-010 |
| MEC-04 | RF-003, RF-024 | RN-013, RN-017 | RNF-012, RNF-033 |
| MEC-07 | RF-043, RF-047, RF-049 | RN-035 | RNF-010 |
| MEC-11 | RF-020, RF-036 | RN-045, RN-048 | RNF-021 |
| MEC-12 | RF-060, RF-063 | — | RNF-027 |

## 11. Aprovação e referências

A equipa técnica valida princípios, mecanismos e decisões DT; RH valida MEC-04 e MEC-06 face aos exemplos de cálculo; a equipa ERP valida MEC-02 e MEC-08 aplicados à integração; o responsável de dados valida MEC-13 e MEC-11. Cada aprovação deve identificar nome, versão e data. Estado de aprovação desta versão: **pendente**.

- [Índice da documentação](README.MD).
- [Requisitos Funcionais](02-Requisitos-Funcionais.md), [Requisitos Não Funcionais](03-Requisitos-Nao-Funcionais.md), [Regras de Negócio](04-Regras-de-Negocio.md), [Casos de Uso](05-Casos-de-Uso.md), [Diagramas UML](06-Diagramas-UML.md).
- [Arquitectura](07-Arquitectura-do-Sistema.md), [Modelo de Dados](09-Modelo-de-Dados.md), [APIs](10-Especificacao-de-APIs.md).
