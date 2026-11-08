# Integrações com Sistemas Externos — Sistema de Gestão de Assiduidade

## 1. Controlo do documento

| Campo | Valor |
| --- | --- |
| Referência | INT-ASS-001 |
| Versão | 0.2 |
| Data | 25/09/2026 |
| Estado | Rascunho técnico para validação |
| Responsáveis | Equipa técnica e equipa ERP, com validação de RH, operação e responsável de dados — nomes a designar |
| Base documental | BR-13, BR-F-090 a BR-F-095; RF-013, RF-054, RF-056 a RF-059; RN-040 a RN-042; RNF-009, RNF-011, RNF-036; UC-05, UC-19; DG-SQ-05, DG-SQ-06, DG-ES-07 |

| Versão | Data | Alteração |
| --- | --- | --- |
| 0.1 | 25/09/2026 | ERP, serviço biométrico e notificações em resumo |
| 0.2 | 25/09/2026 | Versão detalhada: modelo de contrato, fontes de referência, envio de resultados fechados, reconciliação, revisões após reabertura, serviços de apoio e operação |

## 2. Objectivo, âmbito e convenções

Este documento especifica as trocas de dados com os sistemas externos EXT-01 a EXT-06 da [Arquitectura §3](07-Arquitectura-do-Sistema.md). Cada integração é concretizada por um contrato aprovado antes da activação (UC-19).

Convenções: **INT-xx** identifica requisitos. Formatos, periodicidades e fontes de referência dependem de DF-06; nenhum é dado como aprovado.

## 3. Princípios e modelo de contrato

1. **Uma fonte de referência por entidade ou campo** (RN-040). Conflitos bidireccionais nunca se resolvem por sobrescrita silenciosa.
2. **Só resultados fechados são definitivos** (RN-041). Resultados provisórios podem ser consultados, mas nunca enviados como finais.
3. **Transferência não é aplicação.** A confirmação técnica de recepção não prova que o destino aplicou os dados; a reconciliação é que o prova.
4. **Idempotência de ponta a ponta.** Cada operação tem identidade estável (`operacao_uuid`) mantida em reprocessamentos (RN-042).
5. **Dados mínimos.** Cada integração recebe apenas os campos necessários à sua finalidade.

Todo o contrato de integração define:

| Elemento | Conteúdo |
| --- | --- |
| Finalidade e sistemas | Sistema externo, ambiente, responsável de cada lado |
| Dados e direcção | Entidades, campos, fonte de referência por campo |
| Transporte e formato | Protocolo, formato, versão do esquema, codificação de datas e fusos |
| Autenticação | Credencial por tenant e ambiente, rotação |
| Periodicidade | A pedido, agendada ou após evento (ex.: EVD-04) |
| Idempotência | Chave da operação e dos itens |
| Erros | Classificação (recuperável, definitiva, divergência), tentativas e prazos |
| Reconciliação | Níveis de §4.4 e periodicidade |
| Revisões | Tratamento de versões posteriores (substituição ou ajuste) |
| Serviço | Janela, disponibilidade, contactos e escalonamento |

## 4. ERP e sistema de RH (EXT-01, EXT-02)

### 4.1. Fontes de referência

Proposta a decidir em DF-06:

| Entidade | Fonte de referência proposta | Alternativa | Observação |
| --- | --- | --- | --- |
| Colaborador (identificação, vínculo, estado) | ERP / sistema de RH | Assiduidade | O término do vínculo no ERP propaga-se como término na assiduidade (RN-004) |
| Estrutura organizacional | ERP / sistema de RH | Assiduidade | Unidades locais de assiduidade (ex.: locais de terminal) podem ser próprias |
| Horários e turnos | Assiduidade | ERP | Depende de onde RH os gere hoje |
| Tipos de ausência e saldos | ERP / sistema de RH | Assiduidade | RN-027: sem saldo fiável não há aprovação automática |
| Resultados de assiduidade | Assiduidade | — | Enviados após fecho |

### 4.2. Recepção de dados mestre

| ID | Requisito | Prioridade | Critério de aceitação | Origem |
| --- | --- | --- | --- | --- |
| INT-01 | Receber colaboradores, estrutura e saldos por lote (EP-067) ou por execução agendada (EP-068), com resultado por item | E | Lote reporta aplicados, recusados e em conflito com motivo | RF-057 |
| INT-02 | Aplicar apenas campos de que o sistema externo é fonte de referência | E | Campo de fonte local não é alterado pela integração | RN-040 |
| INT-03 | Tratar alterações concorrentes como conflito para resolução autorizada | E | Conflito visível no backoffice; nenhum dos lados é sobrescrito | RF-057 |
| INT-04 | Respeitar vigências: alterações com data futura aplicam-se na data; alterações retroactivas sobre período fechado ficam pendentes | E | Mudança de unidade retroactiva não altera resultado fechado | RN-038, RF-010 |
| INT-05 | Repetir o mesmo lote sem criar duplicados | E | Reenvio do lote produz os mesmos resultados, sem novos registos | RF-013, RNF-009 |

### 4.3. Envio de resultados fechados

Conteúdo mínimo proposto por item (colaborador × período), a validar com a equipa ERP:

| Campo | Descrição |
| --- | --- |
| Identificador do colaborador na fonte de referência | Chave de correspondência |
| Período e versão do fecho | Identifica exactamente o que é enviado |
| Tempo normal trabalhado | Tempo líquido observado dentro do horário |
| Horas extraordinárias **aprovadas** | Nunca as candidatas (RN-023, RF-040) |
| Ausências por tipo e unidade | Dias, horas ou fracções |
| Faltas e atrasos classificados | Conforme política aprovada |
| Indicadores de pendência justificada | Excepções aceites no fecho |

O envio não calcula valores salariais nem aplica taxas: esse cálculo pertence ao ERP (BRD §5.2).

| ID | Requisito | Prioridade | Critério de aceitação | Origem |
| --- | --- | --- | --- | --- |
| INT-06 | Enviar apenas períodos fechados, identificando tenant, período, versão do fecho, lote, contagens, totais e hash | E | Período aberto nunca é enviado como definitivo | RF-058, RN-041 |
| INT-07 | Registar confirmação por item e ligá-la à versão enviada | E | Consulta mostra que versão o ERP confirmou | RF-058 |
| INT-08 | Em timeout, consultar o estado no destino antes de reenviar; reenviar com a mesma identidade | E | CA-07: nenhuma duplicação | RF-059, RNF-011 |
| INT-09 | Reprocessar apenas os itens falhados, mantendo a identidade da operação | E | Falha parcial não reenvia itens confirmados | RF-059 |
| INT-10 | Após reabertura e novo fecho, enviar a versão N+1 como substituição ou ajuste, conforme o contrato, com referência própria e ligação à N | E | EX-08: total do período não é duplicado | RN-039, RN-042 |
| INT-11 | Se o destino não suportar revisões, manter a pendência de reconciliação explícita e não reenviar totais | E | Pendência visível até resolução manual registada | UC-15 |

### 4.4. Reconciliação

| Nível | Comparação | Periodicidade proposta |
| --- | --- | --- |
| Operação | Contagem de itens enviados, confirmados e falhados | Em cada execução |
| Totais | Soma de horas, faltas e ausências por período entre origem e destino | Em cada execução |
| Item | Valores por colaborador e período | A pedido ou por amostragem |
| Versão | Versão aplicada no destino igual à última versão fechada | Após cada reabertura |

| ID | Requisito | Prioridade | Critério de aceitação | Origem |
| --- | --- | --- | --- | --- |
| INT-12 | Produzir relatório de reconciliação por execução com quantidades, totais e divergências (EP-071) | E | Divergência injectada é identificada ao nível do item | RF-059 |
| INT-13 | Impedir que um período com reconciliação pendente seja apresentado como integrado | E | Estado do fecho mostra "envio pendente de reconciliação" | RF-059 |

## 5. Serviço biométrico (EXT-04)

Aplica-se apenas se DF-04 escolher fornecedor externo ou processamento híbrido.

| ID | Requisito | Prioridade | Critério de aceitação | Origem |
| --- | --- | --- | --- | --- |
| INT-14 | Enviar apenas a amostra e o identificador protegido necessários; nunca dados de RH ou de assiduidade | E | Revisão do contrato e do tráfego | BIO-35, PD-05 |
| INT-15 | Contrato define latência, disponibilidade, localização do processamento, retenção, subcontratantes, versões do algoritmo e eliminação verificável | E | Contrato aprovado pelo responsável de dados | BIO-35 |
| INT-16 | Indisponibilidade do serviço encaminha para contingência, nunca para aceitação | E | Teste com o serviço indisponível | RF-034, RN-044 |
| INT-17 | Mudança de versão do algoritmo pelo fornecedor exige aviso prévio e novo ensaio (BIO-28) | E | Versão usada registada em cada tentativa | RF-035 |

## 6. Notificações (EXT-05)

| Evento | Destinatário | Conteúdo máximo | Prioridade |
| --- | --- | --- | --- |
| Pedido pendente de decisão | Aprovador designado | Tipo de pedido e ligação para consulta autorizada | D |
| Decisão sobre pedido | Requerente | Resultado e ligação | D |
| Pedido perto do prazo ou escalonado | Aprovador seguinte | Tipo e prazo | D |
| Marcação em pendência que requer acção | Colaborador ou RH | Data e ligação | D |
| Falha operacional (terminal sem comunicação, integração falhada, auditoria) | Operação | Componente e gravidade | D |

| ID | Requisito | Prioridade | Critério de aceitação | Origem |
| --- | --- | --- | --- | --- |
| INT-18 | Notificações contêm o mínimo de dados e remetem para consulta autenticada; nunca incluem biometria, anexos ou dados de terceiros | D | Revisão das mensagens | RF-054, RNF-020 |
| INT-19 | Falha de entrega fica registada com reenvio limitado e não reverte nem repete decisões de negócio | D | Canal indisponível não altera o pedido | RF-054 |
| INT-20 | Destinatário é revalidado no momento do envio | D | Aprovador revogado não recebe a notificação | RF-054 |

Canais (email, push, SMS) e informação permitida por canal dependem de DF-07.

## 7. Serviço de identidade (EXT-03)

Quando a autenticação for delegada num fornecedor de identidade (DF-02), a plataforma recebe apenas a identidade autenticada e atributos mínimos; papéis, âmbitos e permissões continuam a ser geridos pela plataforma (CMP-02). A desactivação no fornecedor deve reflectir-se na operação seguinte.

## 8. Serviço de localização (EXT-06)

Se aprovado, recebe apenas coordenadas e a área a validar, sem identificação do colaborador. A validação preferencial ocorre no próprio terminal com a área distribuída na configuração (DSP-20), dispensando o envio a terceiros.

## 9. Operação das integrações

| ID | Requisito | Prioridade | Critério de aceitação | Origem |
| --- | --- | --- | --- | --- |
| INT-21 | Configuração versionada por tenant e ambiente, com teste antes da activação e credenciais em CNT-11 | E | Teste falhado mantém a versão anterior activa | RF-056 |
| INT-22 | Monitorizar execuções, atrasos, falhas e divergências, com alertas | E | Falha injectada gera alerta (RF-064) | RF-063 |
| INT-23 | Registar cada operação com conteúdo técnico mínimo: identidade, contagens, estado, erros normalizados; sem dados pessoais nos logs | E | EVA-22, EVA-23; AUD-18 | BR-F-094 |
| INT-24 | Testes de contrato para cada versão suportada, incluindo erros, reenvios e campos novos | E | Pipeline executa os testes antes da entrega | RNF-036 |

## 10. Situação actual

No Nexora ERP observado em 25/09/2026, assiduidade, RH e processamento salarial são módulos do mesmo produto e partilham a base de dados. Não foi identificado registo de execuções com reconciliação entre o fecho de assiduidade e o processamento salarial. Mesmo sendo internas, estas trocas devem seguir o contrato de §4.3 (fecho versionado, identidade da operação e reconciliação), para que reaberturas não dupliquem valores (DT-01).

## 11. Rastreabilidade

| Requisitos | RF | RN / RNF | Casos de uso e diagramas |
| --- | --- | --- | --- |
| INT-01 a INT-05 | RF-013, RF-057 | RN-040; RNF-009 | UC-05, UC-09 |
| INT-06 a INT-13 | RF-058, RF-059 | RN-039, RN-041, RN-042; RNF-011 | UC-05, UC-15; DG-SQ-05, DG-SQ-06, DG-ES-07 |
| INT-14 a INT-17 | RF-034, RF-035 | RN-044 | UC-01, UC-04 |
| INT-18 a INT-20 | RF-054 | RNF-020 | UC-20 |
| INT-21 a INT-24 | RF-056, RF-063, RF-064 | RNF-036 | UC-19, UC-20 |

## 12. Decisões pendentes

| Decisão | Efeito |
| --- | --- |
| DF-06 | Fontes de referência, formatos, periodicidade e tratamento de revisões |
| DF-04 | Existência de §5 |
| DF-07 | Canais e conteúdo das notificações |
| DF-02 | Existência de §7 |
| DN-10 | Política de compatibilidade dos contratos |
| DT-01, DT-03 | Forma das integrações internas ao ERP e mensageria |

## 13. Aprovação e referências

A equipa ERP valida §3 e §4; RH valida o conteúdo de §4.3; o responsável de dados valida §5, §6 e §8; a operação valida §9. Cada aprovação deve identificar nome, versão e data. Estado de aprovação desta versão: **pendente**.

- [Índice da documentação](README.MD).
- [APIs](10-Especificacao-de-APIs.md) EP-065 a EP-071; [Modelo de Dados](09-Modelo-de-Dados.md) ENT-41 a ENT-44; [TDD](08-Documento-de-Design-Tecnico-TDD.md) MEC-02 e MEC-08.
