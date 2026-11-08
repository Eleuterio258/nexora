# Lacunas de Implementação do Módulo de Assiduidade do ERP — Sistema de Gestão de Assiduidade

## 1. Controlo do documento

| Campo | Valor |
| --- | --- |
| Referência | LAE-ASS-001 |
| Versão | 0.1 |
| Data | 25/09/2026 |
| Estado | Rascunho para validação |
| Responsáveis | Equipa técnica do ERP, com validação de RH, segurança e responsável de dados — nomes a designar |
| Base documental | Documentos 01 a 36 (em especial [02](02-Requisitos-Funcionais.md) v0.2, [04](04-Regras-de-Negocio.md), [08](08-Documento-de-Design-Tecnico-TDD.md), [09](09-Modelo-de-Dados.md), [10](10-Especificacao-de-APIs.md)); código Go do Nexora ERP (`factPro/backend`) |

## 2. Objectivo, âmbito e convenções

Este documento compara as regras da série documental com o módulo de assiduidade do Nexora ERP, tal como implementado em 25/09/2026, e lista o que falta ou contraria a especificação. Complementa o [documento 38](38-Lacunas-de-Implementacao-Servico-Biometrico.md), que trata o serviço biométrico.

**Âmbito.** Rotas `/api/rh` (assiduidade, correcções, justificações, ausências, horários, regras, períodos), `/api/self-service/assiduidade`, `/api/hardware`, o serviço `internal/modules/recursos-humanos/service/assiduidade`, o processador `internal/modules/hardware/service` e a tarefa diária em `internal/background/jobs.go`. Corresponde aos componentes CMP-03 a CMP-10 e CMP-14 da [Arquitectura](07-Arquitectura-do-Sistema.md).

**Método.** Leitura do código; os testes não foram executados. Os caminhos são relativos a `factPro/backend/internal/`. Afirmações que dependem de configuração em execução estão marcadas **a confirmar**.

Convenções:

- **LAE-xx** identifica lacunas. Identificadores estáveis.
- **Prioridade:** `Alta` — produz resultados de assiduidade errados ou perda de evidência; `Média` — requisito essencial parcialmente cumprido; `Baixa` — requisito desejável ou decisão pendente.

## 3. Síntese

| Indicador | Valor |
| --- | --- |
| Lacunas | 26 (9 de prioridade alta, 12 média, 5 baixa) |
| Regras de negócio sem cumprimento | RN-010, RN-012, RN-013, RN-016, RN-017, RN-018, RN-019, RN-022, RN-023, RN-024, RN-031, RN-034, RN-037, RN-038, RN-039 |
| Componentes sem implementação | CMP-10 (períodos e fecho de assiduidade), CMP-12 (execuções de integração com reconciliação) |
| Controlos já cumpridos | 12 (secção 6) |

Conclusão principal: o ERP já tem um motor flexível (tipos de evento, métodos, regras com âmbito e vigência, horários com vigência, auditoria transaccional do evento, fila de eventos de hardware com repetição). As lacunas mais graves estão no **cálculo** (correcção que não substitui o evento original, falta automática, turno nocturno, dupla dedução de pausas), na **ausência de fecho de período** e na **falta de recálculo após correcções**.

## 4. Lacunas

### 4.1. Prioridade alta

| ID | Regra | Situação no código | Onde | Correcção proposta |
| --- | --- | --- | --- | --- |
| LAE-01 | RN-033, RN-034, PD-01 — o ajuste aplica-se uma vez, ligado ao original | Ao aprovar uma correcção, é criado um evento novo em estado `corrigido`, mas **o evento original continua em `valido`**. O cálculo inclui os estados `valido`, `aprovado` e `corrigido`, pelo que os dois eventos entram no apuramento. Na formação de pares, um segundo `inicio` substitui o primeiro, por isso o resultado depende da ordem das horas: a correcção pode ser ignorada ou somada | `modules/recursos-humanos/handlers/correcoes_evento.go` (`AprovarCorrecaoEvento`), `service/assiduidade/calculo.go` (`carregarEventosDoDia`), `service/assiduidade/pairing.go` | Na mesma transacção da aprovação, marcar o original como substituído (sem o apagar) e excluí-lo do cálculo |
| LAE-02 | RN-022 — ausência de eventos não é, por si só, falta | Um dia com horário e sem eventos passa automaticamente a `falta_injustificada`, sem verificar ausências aprovadas em `rh.ausencias`, feriados, eventos em análise (`fora_localizacao`, `em_analise`) nem falhas técnicas | `service/assiduidade/calculo.go` (`RecalcularDia`, bloco final) | Aplicar a ordem de ALG-10 do [documento 36](36-Algebra-Relacional.md): ausências aprovadas, eventos pendentes e calendário antes de concluir falta candidata |
| LAE-03 | RN-017, MEC-04 — turno que atravessa a meia-noite é uma única jornada | `data_referencia` é, por defeito, a data civil do instante, e o cálculo agrupa por `data_referencia`. Um turno 22:00–06:00 fica dividido em dois dias, com entrada sem saída num e saída sem entrada no outro. O campo `eh_nocturno` de `rh.horarios_dias` é carregado mas não usado | `service/assiduidade/eventos.go` (`registarEvento`), `service/assiduidade/calculo.go` | Atribuir a jornada pelo intervalo previsto do horário (ALG-05), não pelo dia civil |
| LAE-04 | RN-018, RN-019, RN §5.2 — sem dupla contagem nem dupla dedução | Horas trabalhadas = soma dos pares de trabalho − soma dos pares de intervalo − soma dos não contabilizados, **sem interseccionar**. Uma pausa fora dos intervalos de trabalho (caso EX-02) é deduzida na mesma. Pares de trabalho sobrepostos são somados duas vezes | `service/assiduidade/calculo.go` | Implementar `T_observado = duração(P) − duração(P ∩ B)` do [documento 04 §5.2](04-Regras-de-Negocio.md) |
| LAE-05 | RN-012, RN-018, RN §5.2 — sequência incompleta gera ocorrência; indeterminado não é zero | Um `fim` sem `inicio` e um `inicio` sem `fim` são ignorados em silêncio. O resultado fica com 0 horas (campos a nulo quando zero), sem ocorrência de sequência incompleta, e é indistinguível de um dia sem trabalho | `service/assiduidade/pairing.go` (`agruparPorTipoPar`), `service/assiduidade/calculo.go` (`setDuration`) | Registar ocorrência `sequencia_incompleta` e marcar a grandeza como indeterminada |
| LAE-06 | RN-038, PD-07, RF-049, RF-050 — período fechado é imutável; reabertura versionada | Não existe fecho de período de assiduidade. `rh.periodos_avaliacao` só tem `aberto`/`encerrado`, é gerido com a permissão `processar_salarios` e nada o consulta antes de recalcular, corrigir ou aceitar eventos | `modules/recursos-humanos/handlers/rh.go` (`CriarPeriodo`), `service/assiduidade/calculo.go` | Implementar CMP-10: validação, fecho com hash, reabertura com motivo (EP-057 a EP-061) e bloqueio de escrita em período fechado |
| LAE-07 | RN-024, MEC-06, PD-04 — resultado versionado e conservado | `rh.resultados_diarios` é actualizado no lugar (`ON CONFLICT … DO UPDATE`); `versao_regra` é só um contador. Não há hash das entradas, versão anterior, motivo do recálculo nem versões de regra aplicadas | `service/assiduidade/calculo.go` (`gravarResultadoDiario`) | Guardar cada versão com hash das entradas e regras aplicadas (ENT-36 do [documento 09](09-Modelo-de-Dados.md)) |
| LAE-08 | EVD-01, EVD-03, RF-039, RF-047 — recálculo após evento ou decisão | O recálculo só acontece na tarefa diária (dia anterior) e no endpoint manual. Aprovar uma correcção, aprovar uma ausência ou receber um evento sincronizado com atraso **não recalcula** o dia afectado | `background/jobs.go` (`recalcularResultadosAssiduidade`), `handlers/correcoes_evento.go`, `handlers/rh.go` (`AprovarAusencia`) | Publicar o evento de domínio e recalcular o âmbito afectado (outbox, MEC-08) |
| LAE-09 | RN-010, MEC-03, RF-023 — identificador estável gerado na origem | Não existe `evento_uuid`. A deduplicação usa um hash do conteúdo (funcionário, tipo, origem, dispositivo, instante). Na marcação por self-service, o instante é a hora do servidor, pelo que repetir o pedido após perder a resposta cria um **segundo evento**. Não é possível distinguir reenvio de conteúdo divergente | `service/assiduidade/eventos.go` (`hashEventoAssiduidade`), `modules/self-service/handlers/ponto.go` (`MarcarPonto`) | Aceitar `evento_uuid` do cliente, com unicidade por tenant, e registar as recepções (ENT-21) |

### 4.2. Prioridade média

| ID | Regra | Situação no código | Onde | Correcção proposta |
| --- | --- | --- | --- | --- |
| LAE-10 | PD-01, RF-046 — sem remoção física de assiduidade | `DELETE /api/rh/funcionarios/{id}/presencas/{presencaId}` apaga a linha de `rh.presencas` sem motivo nem auditoria | `handlers/presencas.go` (`RemoverPresenca`) | Retirar o endpoint ou substituí-lo por pedido de correcção |
| LAE-11 | RN-031, SDF-02 — o decisor não é o requerente nem o colaborador abrangido | Aprovação de correcções e de ausências verifica apenas `podeGerirFuncionario`; não compara o decisor com quem pediu nem com o funcionário. A mesma permissão (`aprovar_ausencias`) cria e aprova ausências | `handlers/correcoes_evento.go`, `handlers/rh.go` (`CriarAusencia`, `AprovarAusencia`) | Recusar com `SEGREGACAO_FUNCOES` quando o decisor coincide com o requerente ou com o colaborador |
| LAE-12 | RN-035, MEC-07, RNF-010 — decisão atómica sobre uma versão | Na aprovação de correcção, o evento corrigido é gravado numa transacção e o pedido é actualizado noutra. Se a segunda falhar, fica um evento sem pedido aprovado. Os pedidos não têm versão nem `If-Match` | `handlers/correcoes_evento.go` | Uma única transacção; versão do pedido |
| LAE-13 | RNF-026, MEC-10 — sem operação crítica sem evidência | A auditoria da aprovação e rejeição de correcções ignora o erro (`_ = RegistarAuditoria(...)`) e corre fora da transacção | `handlers/correcoes_evento.go` | Gravar a auditoria na mesma transacção e falhar se não puder ser registada |
| LAE-14 | RN-012, FP-03, EP-035 — eventos em análise têm fluxo de decisão | Eventos gravados como `fora_localizacao` ficam fora do cálculo e não há endpoint para os aceitar, rejeitar ou classificar. O mesmo para `em_analise`, `pendente` e `duplicado` | `service/assiduidade/eventos.go`, `handlers/eventos_assiduidade.go` | Fila de pendências com decisão auditada (EP-035) |
| LAE-15 | RN-013, MEC-04, PN-06 — desvio de relógio e instante de recepção | Não há `instante_recepcao` distinto de `created_at`, nem fuso de origem, nem desvio de relógio. Instantes vindos de dispositivos são aceites sem limite de desvio | `models/assiduidade.go`, `service/assiduidade/eventos.go`, `modules/hardware/service/processor.go` | Campos de ENT-20; pendência quando o desvio excede o limite aprovado |
| LAE-16 | MEC-04, RF-003 — cálculo no fuso do contexto | Atrasos e saídas antecipadas comparam a hora do evento com o horário usando o fuso do objecto `time` devolvido pela base (`tempoDoDia`), não o fuso do tenant ou do local. **A confirmar:** com o processo em UTC e o tenant em `Africa/Maputo`, os atrasos ficam desviados duas horas | `service/assiduidade/calculo.go` (`tempoDoDia`) | Converter para o fuso configurado do tenant ou local antes de comparar |
| LAE-17 | RN-020, RF-016 — tolerância única e versionada | A tolerância só é aplicada se existir a regra `tolerancia_atraso`; as colunas `tolerancia_atraso` e `tolerancia_saida_antecipada` de `rh.horarios_dias` são carregadas mas ignoradas. As regras não têm estado de aprovação nem versão (só vigência e prioridade) | `service/assiduidade/calculo.go`, `service/assiduidade/regras.go` | Uma única fonte de tolerância; versões de política com aprovação (MEC-05) |
| LAE-18 | RN-023, RF-040 — horas observadas, elegíveis e aprovadas separadas | Horas extra são calculadas e limitadas por `max_horas_extra`, mas não há separação entre observado, elegível e aprovado nem decisão de aprovação | `service/assiduidade/calculo.go`, `models/assiduidade.go` (`ResultadoDiario`) | Ocorrência `extraordinaria_candidata` com os três valores (ENT-37) e decisão (EP-056) |
| LAE-19 | RN-015, RF-019, RF-026 — eventos após revogação ou suspensão | O processador de hardware rejeita funcionário inactivo e método desactivado com erro técnico em `hardware.device_events`, mas não cria o evento em estado `rejeitado` nem `pendente_analise` com motivo; a marcação não aparece no histórico do colaborador | `modules/hardware/service/processor.go` (`processEntity`) | Registar o evento com estado e código de motivo (10 §6.3) |
| LAE-20 | BIO-31, PD-05 — sem imagens por defeito | A marcação por selfie grava a fotografia e guarda `foto_url` em `rh.eventos_assiduidade` | `modules/self-service/handlers/ponto.go` (`prepararFotoSelfie`), `models/assiduidade.go` | Deixar de guardar a imagem, salvo finalidade e prazo aprovados |
| LAE-21 | Dois modelos em paralelo ([10 §9](10-Especificacao-de-APIs.md)) | Coexistem `rh.presencas` (legado) e `rh.eventos_assiduidade`; `/api/rh/correcoes-ponto` (antigo) e `/api/rh/correcoes` (novo); `/api/rh/justificacoes` e `rh.ausencias` | `handlers/presencas.go`, `handlers/correcoes_ponto.go`, `handlers/correcoes_evento.go`, `handlers/justificacoes.go` | Plano de descontinuação no [documento 28](28-Plano-de-Migracao-de-Dados.md) |

### 4.3. Prioridade baixa

| ID | Regra | Situação no código | Onde | Correcção proposta |
| --- | --- | --- | --- | --- |
| LAE-22 | RF-032 — política de falha da validação de método | `MetodoActivo` permite a marcação sempre que a configuração não existe, não é legível ou o método não tem entrada (falha aberta) | `service/assiduidade/eventos.go` (`MetodoActivo`) | Decidir e documentar a política em DF-01 |
| LAE-23 | RF-021 — direcção da marcação | Quando o dispositivo não indica a direcção, `InferirEntradaOuSaida` alterna pela paridade do dia civil; com turno nocturno (LAE-03) ou uma marcação perdida, todas as seguintes ficam invertidas | `service/assiduidade/eventos.go` | Inferir pela jornada e sinalizar ambiguidade (`SEQUENCIA_AMBIGUA`) |
| LAE-24 | DT-05, SEG-08 — credencial individual de dispositivo | `/api/hardware/*` autentica com chave de API; a revogação individual depende do registo de dispositivos. (Risco aceite na aplicação Android; mantido aqui só como referência à decisão DT-05) | `router/router.go` (`/api/hardware`) | Decisão DT-05 |
| LAE-25 | CMP-12, RF-058, RF-059 — envio de resultados fechados com reconciliação | Não existe execução de integração entre assiduidade e processamento salarial com identidade da operação, versão do fecho e reconciliação | `handlers/processamento_salarial.go` | Depende de LAE-06; contrato do [documento 18 §4.3](18-Integracoes-com-Sistemas-Externos.md) |
| LAE-26 | RN-021, RF-017 — arredondamento | Não existe regra de arredondamento | `service/assiduidade/regras.go` | Após PN-04 |

## 5. Divergências de modelo a resolver

| Tema | Documentação | Código | Decisão necessária |
| --- | --- | --- | --- |
| Estados do evento | `recebido`, `aceite`, `rejeitado`, `pendente_analise`, `duplicado` ([02 §6](02-Requisitos-Funcionais.md) v0.2) | 12 estados que misturam recepção e classificação (`valido`, `corrigido`, `incompleto`, `fora_horario`, `fora_localizacao`, `manual`, `importado`, …) | Separar estado de recepção de classificação do apuramento ([09 §9](09-Modelo-de-Dados.md)) |
| Jornada | Entidade `jornada` com intervalo previsto e data de referência | Dia civil (`data_referencia`) | LAE-03 |
| Pedido | Supertipo `pedido` com versões e decisões separadas | `correcoes_evento`, `pedidos_correcao_ponto`, `ausencias`, `justificacoes`, com decisão na própria linha | DT-01 |
| Ocorrência | Entidade `ocorrencia` com observado, elegível e aprovado | Colunas agregadas em `resultados_diarios` | LAE-18 |
| Identificadores | Inteiro interno e UUID público (DT-06) | Só inteiros | DT-06 |

## 6. Requisitos já cumpridos

| Requisito | Implementação |
| --- | --- |
| RF-014, RF-016 (parcial) — horários e regras configuráveis | Tipos de evento, métodos de marcação, horários por dia e por data, associação funcionário–horário com vigência, regras com âmbito, vigência e prioridade (`service/assiduidade/regras.go`) |
| RF-010, RN-006 — horário vigente na data | `carregarHorarioVigente` usa a vigência da associação |
| PD-01 (parcial) — evento nunca sobrescrito | `RegistarEvento` só insere; correcções geram novo evento ligado por `evento_pai_id` |
| MEC-10 (parcial) — evento e auditoria atómicos | `registarEvento` grava evento e `rh.auditoria_assiduidade` na mesma transacção |
| RNF-009 (parcial) — deduplicação de hardware | `hardware.device_events` com `event_hash` único e `ON CONFLICT DO NOTHING` |
| RNF-011 — repetição controlada | Fila de eventos de hardware com lease, tentativas e backoff (`processor.go`) |
| RF-031, DSP-20 — geofence no momento da marcação | `validarGeofence` com Haversine; fora da área vai para análise quando a regra o exige |
| RF-032 — método activo por tenant | `MetodoActivo`, aplicado a hardware e self-service |
| RF-021 — colaborador inactivo | Hardware recusa funcionário inactivo |
| RF-038 (parcial) — horas nocturnas | `calcularHorasNocturnas` trata janelas que atravessam a meia-noite |
| RNF-025, AUD-06 (plataforma) — auditoria com verificação de integridade | `/api/audit-events/verificar-integridade` |
| RF-002, TEN-01 — tenant resolvido no servidor | Handlers usam o tenant do utilizador autenticado; `RequireFeature(rh.assiduidade)` |

## 7. Ordem de correcção proposta

| Passo | Lacunas | Justificação |
| --- | --- | --- |
| 1 | LAE-01, LAE-08 | Correcções aprovadas produzem hoje resultados errados ou desactualizados |
| 2 | LAE-02, LAE-05 | Faltas atribuídas indevidamente |
| 3 | LAE-03, LAE-04, LAE-16 | Cálculo de turnos nocturnos, pausas e fuso |
| 4 | LAE-09, LAE-15 | Idempotência e tempo na recepção |
| 5 | LAE-11, LAE-12, LAE-13, LAE-10 | Segregação, atomicidade e evidência |
| 6 | LAE-06, LAE-07 | Fecho de período e versões de resultado |
| 7 | LAE-14, LAE-19, LAE-18, LAE-17, LAE-20 | Pendências, rejeições, horas extra, tolerâncias e imagens |
| 8 | LAE-21 a LAE-26 | Descontinuação de modelos antigos e decisões pendentes |

## 8. Rastreabilidade

| Lacunas | Regras e requisitos | Documentos |
| --- | --- | --- |
| LAE-01, LAE-11, LAE-12, LAE-13 | RF-046, RF-047; RN-031, RN-033 a RN-035; SDF-02; MEC-07, MEC-10 | [04](04-Regras-de-Negocio.md), [05](05-Casos-de-Uso.md) UC-02, [14](14-Gestao-de-Utilizadores-e-Perfis.md), [16](16-Auditoria-e-Logs.md) |
| LAE-02 a LAE-05, LAE-16 a LAE-18, LAE-23, LAE-26 | RF-014 a RF-017, RF-038, RF-040; RN-017 a RN-023; MEC-04 | [04](04-Regras-de-Negocio.md) §5 e §6, [36](36-Algebra-Relacional.md) ALG-05, ALG-10 |
| LAE-06, LAE-07, LAE-08, LAE-25 | RF-039, RF-048 a RF-050, RF-058, RF-059; RN-024, RN-037 a RN-039; MEC-06 | [07](07-Arquitectura-do-Sistema.md) CMP-09, CMP-10, CMP-12; [09](09-Modelo-de-Dados.md); [18](18-Integracoes-com-Sistemas-Externos.md) |
| LAE-09, LAE-14, LAE-15, LAE-19 | RF-021 a RF-026; RN-010 a RN-016; MEC-02 a MEC-04 | [10](10-Especificacao-de-APIs.md) EP-031, EP-032, EP-035; [19](19-Fluxos-de-Processos.md) FP-01 a FP-03 |
| LAE-10, LAE-20, LAE-21 | PD-01, PD-05; BIO-31 | [08](08-Documento-de-Design-Tecnico-TDD.md), [12](12-Reconhecimento-Facial-e-Liveness.md), [28](28-Plano-de-Migracao-de-Dados.md) |
| LAE-22, LAE-24 | RF-019, RF-032; DT-05 | [11](11-Especificacao-de-Dispositivos-Terminais.md), [17](17-Seguranca-e-Proteccao-de-Dados.md) |

## 9. Aprovação e referências

A equipa técnica do ERP valida as lacunas e a ordem de correcção; RH valida LAE-01 a LAE-05, LAE-17 e LAE-18 com casos de cálculo de referência; segurança valida LAE-10 a LAE-13 e LAE-24; o responsável de dados valida LAE-20. Cada aprovação deve identificar nome, versão e data. Estado de aprovação desta versão: **pendente**.

- [Índice da documentação](README.MD).
- [Lacunas de Implementação do Serviço Biométrico](38-Lacunas-de-Implementacao-Servico-Biometrico.md).
- [Análise de Consistência da Documentação](37-Analise-de-Consistencia.md).
