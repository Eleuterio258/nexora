# Auditoria e Logs — Sistema de Gestão de Assiduidade

## 1. Controlo do documento

| Campo | Valor |
| --- | --- |
| Referência | AUD-ASS-001 |
| Versão | 0.3 |
| Data | 25/09/2026 |
| Estado | Rascunho técnico para validação |
| Responsáveis | Segurança e equipa técnica, com validação de auditoria, operação e responsável de dados — nomes a designar |
| Base documental | BR-14, BR-F-100 a BR-F-102; RF-060, RF-063; RNF-025 a RNF-027; UC-17; [TDD](08-Documento-de-Design-Tecnico-TDD.md) MEC-10, MEC-12 |

| Versão | Data | Alteração |
| --- | --- | --- |
| 0.1 | 25/09/2026 | Auditoria de negócio e logs técnicos em resumo |
| 0.2 | 25/09/2026 | Versão detalhada: catálogo de eventos auditados, estrutura, integridade, falha de auditoria, consulta, logs técnicos e telemetria |
| 0.3 | 25/09/2026 | Terminologia de autorização alinhada com permissões granulares `módulo:acção` e âmbito ([Requisitos Funcionais §3](02-Requisitos-Funcionais.md)) |

## 2. Objectivo, âmbito e convenções

Este documento distingue três tipos de registo com finalidades, acessos e retenções diferentes:

| Tipo | Finalidade | Destinatário | Armazenamento | Retenção |
| --- | --- | --- | --- | --- |
| Auditoria | Evidência de quem fez o quê, sobre que objecto, com que resultado | Auditores e responsáveis autorizados | CNT-10, append-only | CR-05 |
| Logs técnicos | Diagnóstico de falhas | Operação e equipa técnica | CNT-12 | CR-06 |
| Telemetria | Métricas e traces de desempenho e saúde | Operação | CNT-12 | CR-06 |

Um log técnico nunca substitui um evento de auditoria, e a auditoria não é usada para diagnóstico corrente.

Convenções: **EVA-xx** identifica tipos de evento auditado; **AUD-xx** requisitos. **Síncrono** significa gravado na mesma transacção da operação ou em persistência alternativa aprovada, antes de confirmar a operação (MEC-10).

## 3. Catálogo de eventos auditados

| ID | Evento | Dados adicionais mínimos | Síncrono | Origem |
| --- | --- | --- | --- | --- |
| EVA-01 | Autenticação com sucesso ou falhada, de qualquer conta | Método, segundo factor usado, motivo da falha | Sim | RF-060 |
| EVA-02 | Terminação, revogação e bloqueio de sessão ou conta | Motivo, autor | Sim | RF-006 |
| EVA-03 | Recuperação de acesso | Mecanismo, resultado | Sim | RF-006 |
| EVA-04 | Criação, alteração e revogação de papéis e atribuições | Âmbito e vigência anteriores e novos | Sim | RF-007 |
| EVA-05 | Concessão, uso e revogação de autorização de suporte | Finalidade, âmbito, validade; cada acção sob suporte referencia a autorização | Sim | RF-008 |
| EVA-06 | Ciclo de vida do tenant | Estado anterior e novo, motivo | Sim | RF-001 |
| EVA-07 | Alteração de estrutura organizacional e de configuração do tenant | Antes e depois | Sim | RF-003, RF-004 |
| EVA-08 | Criação, alteração, suspensão e término de colaborador; associações e credenciais | Campos alterados | Sim | RF-009 a RF-012 |
| EVA-09 | Importação de colaboradores | Lote, contagens aceites e recusadas | Sim | RF-013 |
| EVA-10 | Criação e activação de versões de horário e política | Versão, vigência, aprovador, motivo | Sim | RF-016 |
| EVA-11 | Registo, activação, revogação e rotação de credencial de dispositivo; publicação de configuração | Versão, destinos | Sim | RF-019, RF-020 |
| EVA-12 | Marcação assistida | Operador, motivo, colaborador | Sim | RF-027 |
| EVA-13 | Resolução de evento pendente (aceitar, rejeitar, classificar como duplicado) | Estado anterior e novo, motivo | Sim | RF-024 |
| EVA-14 | Habilitação e revogação biométrica, consentimento | Modalidade, finalidade, versão da política | Sim | RF-061 |
| EVA-15 | Enrollment, suspensão, substituição e eliminação de referência biométrica; conclusão da propagação | Versões e estado por destino, sem template | Sim | RF-033, RF-036 |
| EVA-16 | Alteração de limiar biométrico | Valor anterior e novo, intervalo aprovado | Sim | RF-035 |
| EVA-17 | Submissão, alteração, decisão e cancelamento de pedidos | Versão do pedido, decisor, motivo | Sim | RF-042 a RF-047 |
| EVA-18 | Aplicação de ajuste | Antes e depois, pedido de origem | Sim | RF-047 |
| EVA-19 | Recálculo manual e decisão de horas elegíveis | Âmbito, motivo, versão resultante | Sim | RF-039, RF-040 |
| EVA-20 | Validação, fecho e reabertura de período | Versão, hash dos resultados, excepções, motivo | Sim | RF-048 a RF-050 |
| EVA-21 | Exportação e entrega de relatório agendado | Finalidade, filtros, campos, destinatários | Sim, antes da entrega | RF-053, RF-055, RN-046 |
| EVA-22 | Configuração, teste, activação de integração; rotação de credencial | Versão, ambiente | Sim | RF-056 |
| EVA-23 | Execução e reprocessamento de integração | Operação, contagens, resultado | Assíncrono | RF-058, RF-059 |
| EVA-24 | Operações de retenção, eliminação e anonimização | Categoria, âmbito, destinos, conclusão | Sim | RF-062 |
| EVA-25 | Cópia de segurança, restauro e reaplicação de decisões | Ponto de recuperação, resultado da validação | Sim | RF-065 |
| EVA-26 | Consulta de dados sob autorização de suporte e consulta de metadados biométricos | Objecto consultado | Sim, antes da entrega | RF-008, RNF-020 |
| EVA-27 | Consulta e exportação da própria auditoria | Filtros | Sim | RF-060 |
| EVA-28 | Falha e recuperação do registo de auditoria | Período afectado, eventos reconciliados | Assíncrono | RNF-026 |

A versão 0.1 auditava apenas "login privilegiado"; EVA-01 cobre todas as autenticações, como exige RF-060. Marcações correntes aceites não geram evento de auditoria próprio: a evidência está no próprio `evento_assiduidade` e nas suas recepções, que são imutáveis (PD-01).

## 4. Estrutura do evento

Campos de ENT-45 no [Modelo de Dados §5.10](09-Modelo-de-Dados.md): identificador, tenant, tipo e identificador do actor, acção, tipo e identificador do objecto, resultado, motivo, instante do servidor, `correlation_id`, `request_id`, origem técnica quando permitida, dados adicionais do catálogo, `hash_anterior` e `hash`.

| ID | Requisito | Prioridade | Critério de aceitação | Origem |
| --- | --- | --- | --- | --- |
| AUD-01 | Gravar os eventos EVA-01 a EVA-28 com os campos acima | E | Amostra de cada tipo contém todos os campos | RF-060, BR-F-101 |
| AUD-02 | Nunca incluir templates, imagens, tokens, palavras-passe, segredos ou conteúdo de anexos | E | Pesquisa automática por padrões sensíveis não encontra ocorrências | RF-060, RNF-020 |
| AUD-03 | Registar alterações como antes/depois apenas dos campos alterados, com mascaramento de dados pessoais não necessários | E | Revisão por amostragem confirma minimização | RNF-020 |
| AUD-04 | Usar o relógio do servidor, sincronizado com fonte de tempo fiável | E | Desvio do servidor monitorizado | RNF-012 |

## 5. Integridade e protecção

| ID | Requisito | Prioridade | Critério de aceitação | Origem |
| --- | --- | --- | --- | --- |
| AUD-05 | Armazenamento append-only: a conta da aplicação não pode actualizar nem remover eventos | E | Tentativa de alteração é recusada pela base | RNF-025, RI-06 |
| AUD-06 | Encadeamento por hash por tenant, com verificação periódica automática | E | Alteração simulada de um evento é detectada na verificação seguinte | RNF-025, DT-07 |
| AUD-07 | Cópia periódica para destino imutável ou fora do controlo dos administradores correntes | D | Cópia verificável contra a cadeia principal | DT-07 |
| AUD-08 | Acesso administrativo ao armazenamento de auditoria separado do acesso aos dados de negócio e ele próprio auditado | E | Contas com acesso a CNT-10 constam da revisão de acessos | RNF-016 |

## 6. Falha de auditoria

| ID | Requisito | Prioridade | Critério de aceitação | Origem |
| --- | --- | --- | --- | --- |
| AUD-09 | Se o evento síncrono não puder ser gravado nem desviado para a persistência alternativa aprovada, a operação crítica é recusada com `AUDITORIA_INDISPONIVEL` | E | Teste com CNT-10 indisponível não produz alteração sem evidência | RNF-026 |
| AUD-10 | A persistência alternativa é durável, protegida e reconciliada com CNT-10 na recuperação, com EVA-28 | E | Após recuperação, não há lacunas na cadeia nem eventos duplicados | RNF-026 |
| AUD-11 | Falha de auditoria gera alerta imediato à operação | E | Alerta no prazo aprovado (DN-09) | RNF-028 |

A escolha entre bloqueio e persistência alternativa, por tipo de operação, é a decisão DN-09.

## 7. Consulta de auditoria

| ID | Requisito | Prioridade | Critério de aceitação | Origem |
| --- | --- | --- | --- | --- |
| AUD-12 | Pesquisar por intervalo, actor, acção, objecto, resultado e correlação, limitado ao âmbito (PERM-30, PERM-31) | E | Utilizador com permissão de consulta de auditoria num tenant não vê eventos de outro | RF-060, UC-17 |
| AUD-13 | Reconstituir a cadeia de um objecto: pedido, decisão, ajuste, recálculo, fecho, envio | E | EP-073 devolve a cadeia ordenada e correlacionada | UC-17 |
| AUD-14 | Assinalar lacunas conhecidas e dados fora da retenção, sem os fabricar | E | Consulta sobre período expurgado indica a expiração | UC-17 |
| AUD-15 | Exportar evidência para auditoria, com EVA-27 | D | Exportação inclui verificação de integridade da cadeia | RF-053 |
| AUD-16 | Permitir ao tenant consultar os acessos de suporte que lhe foram feitos | D | Filtro por EVA-05 e EVA-26 | TEN-17 |

## 8. Logs técnicos

| ID | Requisito | Prioridade | Critério de aceitação | Origem |
| --- | --- | --- | --- | --- |
| AUD-17 | Logs estruturados em JSON com instante, nível, serviço, versão, ambiente, `request_id`, `correlation_id`, tenant (como identificador técnico), duração, resultado e erro normalizado | E | Operador segue uma marcação de teste do terminal até à integração pela correlação | RNF-027 |
| AUD-18 | Campos pessoais por lista de permissão: só são registados campos explicitamente aprovados; os restantes são omitidos ou mascarados | E | Inspecção de logs não encontra nomes, documentos, localizações ou dados biométricos | RNF-020 |
| AUD-19 | Nunca registar corpos de pedido completos em produção | E | Configuração de produção verificada | RNF-020 |
| AUD-20 | Acesso aos logs limitado a operação e equipa técnica, com retenção CR-06 | E | Logs não são usados para contornar a autorização de negócio | RNF-027 |
| AUD-21 | Logs dos terminais seguem as mesmas regras e são enviados apenas com a telemetria aprovada | E | DSP-32 verificado | DSP-32 |

## 9. Telemetria

Métricas mínimas: latência por endpoint e percentil; erros técnicos separados de rejeições de negócio; tamanho e idade das filas (outbox, erro, pendências de análise); terminais sem comunicação e tamanho das filas locais; falhas de identificação por terminal; execuções de integração por estado; atraso de propagação por destino; falhas de auditoria; tarefas de retenção pendentes. Traces distribuídos seguem o `correlation_id`. Métricas não contêm dados pessoais e usam o tenant apenas como etiqueta técnica (TEN §5).

## 10. Situação actual

No Nexora ERP observado em 25/09/2026 existe `rh.auditoria_assiduidade` e o endpoint `GET /api/hardware/audit-logs`, acessível por credencial de dispositivo. Não foi verificado encadeamento nem protecção contra alteração. A consulta de auditoria por dispositivos não está prevista nesta especificação (ver [10 §9](10-Especificacao-de-APIs.md)).

## 11. Rastreabilidade

| Elementos | RF | RNF | Casos de uso |
| --- | --- | --- | --- |
| EVA-01 a EVA-28, AUD-01 a AUD-04 | RF-060 e RF de cada linha | RNF-020, RNF-025 | UC-17 |
| AUD-05 a AUD-08 | RF-060 | RNF-016, RNF-025 | UC-17, UC-21 |
| AUD-09 a AUD-11 | RF-060 | RNF-026, RNF-028 | UC-20 |
| AUD-12 a AUD-16 | RF-060, RF-008 | RNF-013 | UC-17 |
| AUD-17 a AUD-21, §9 | RF-063 | RNF-020, RNF-027 | UC-20 |

## 12. Decisões pendentes

| Decisão | Efeito |
| --- | --- |
| DT-07 | Implementação do armazenamento e da cópia imutável |
| DN-09 | Bloqueio ou persistência alternativa por operação; prazos de alerta |
| DF-08, DN-06 | Prazos de CR-05 e CR-06 |
| DN-04 | Origem técnica registada (IP, dispositivo) face à política de privacidade |

## 13. Aprovação e referências

Segurança e auditoria validam §3 a §7; a operação valida §8 e §9; o responsável de dados valida a minimização. Cada aprovação deve identificar nome, versão e data. Estado de aprovação desta versão: **pendente**.

- [Índice da documentação](README.MD).
- [TDD](08-Documento-de-Design-Tecnico-TDD.md) MEC-10 e MEC-12; [Modelo de Dados](09-Modelo-de-Dados.md) ENT-45; [Segurança e Protecção de Dados](17-Seguranca-e-Proteccao-de-Dados.md).
