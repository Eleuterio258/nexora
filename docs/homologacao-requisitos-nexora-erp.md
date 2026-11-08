# Nexora ERP — Homologação dos requisitos integrados

Versão 0.1 | 14 de outubro de 2026 | E258TECH

Estado: proposta para validação funcional. Este documento complementa o [BRD](brd-nexora-erp.md) e o [catálogo dos 33 módulos](requisitos-nexora-erp-modulo-a-modulo.md). Os cenários são especificações de aceitação; não representam testes executados nem funcionalidades homologadas.

## 1. Preparação e evidência

Preparar duas organizações, A e B, com dados distintos; um administrador, um operador autorizado e um utilizador sem a permissão em análise em cada organização. Incluir uma conta com vínculos nas duas organizações para verificar a seleção de contexto. Usar dados fictícios e serviços externos de teste.

Antes de executar, registar versão do produto, ambiente, requisitos incluídos, regras aprovadas e estado inicial. Para cada cenário, conservar passos, resultado esperado, resultado obtido, referências dos documentos/eventos e evidência dos saldos antes e depois. Dados pessoais, credenciais e tokens devem ser omitidos da evidência partilhada.

Estados de execução: não executado, aprovado, reprovado ou bloqueado. Um cenário bloqueado deve identificar a dependência em falta. Um cenário reprovado deve indicar defeito, impacto e responsável. Todos os cenários abaixo começam como não executados.

## 2. F-01 — Venda até à reconciliação

Requisitos: RF-M11-03, RF-M12-02, RF-M15-01 a RF-M15-05, RF-M16-01 a RF-M16-06, RF-M17-02/03, RF-M18-02/03 e RF-M19-02/04.

Pré-condições: artigo ativo, stock disponível, cliente válido, terminal e caixa elegíveis, regras de preço e imposto aprovadas. Definir quais efeitos são obrigatórios no modelo de venda selecionado e o instante em que cada um ocorre.

| Cenário | Ação | Resultado esperado |
|---|---|---|
| HA-F01-01 | Abrir caixa, vender artigo, confirmar documento e receber pagamento. | Totais do documento e pagamento conciliam; stock, obrigação, tesouraria e contabilidade refletem os efeitos configurados uma única vez. |
| HA-F01-02 | Liquidar parcialmente uma venda a crédito elegível. | Saldo em aberto corresponde ao total menos liquidações válidas; a parcela recebida concilia com tesouraria. |
| HA-F01-03 | Repetir callback válido e enviar depois evento antigo de pagamento. | Não há segundo recebimento, movimento ou lançamento; o estado final não regride. |
| HA-F01-04 | Enviar callback sem assinatura válida ou com montante/moeda diferentes da intenção. | Não confirma pagamento nem altera os saldos; resultado permite identificar a rejeição. |
| HA-F01-05 | Simular falha num efeito obrigatório durante confirmação. | Não é apresentado sucesso completo; a operação permanece coerente e a recuperação não duplica efeitos. |
| HA-F01-06 | Efetuar estorno parcial autorizado e tentar exceder o valor/quantidade elegível. | Estorno válido preserva origem e motivo; tentativa excedente é rejeitada e os saldos permanecem corretos. |
| HA-F01-07 | Fechar caixa e reconciliar os recebimentos do período. | Valores esperados, declarados e diferenças são verificáveis por meio de pagamento; conciliação referencia os movimentos incluídos. |

Decisões necessárias: reserva/baixa de stock, venda a crédito, descontos de supervisor, tolerância de caixa, política de estorno e tratamento de eventos contraditórios do gateway.

## 3. F-02 — Compra até ao pagamento

Requisitos: RF-M13-01 a RF-M13-05, RF-M12-02, RF-M17-02/03, RF-M18-02, RF-M19-04 e RF-M28-01 a RF-M28-03.

Pré-condições: fornecedor e artigos elegíveis, armazém autorizado, fluxo de aprovação quando exigido, conta de pagamento ativa. Homologar um exemplo de quantidades, preços e tolerância de receção.

| Cenário | Ação | Resultado esperado |
|---|---|---|
| HA-F02-01 | Criar ordem sujeita a aprovação e tentar receber antes da decisão. | O processo não avança sem a autorização exigida; a decisão identifica responsável e versão aprovada. |
| HA-F02-02 | Aprovar e receber a ordem em duas parcelas. | Cada receção atualiza apenas a quantidade aceite; saldo por receber e stock conciliam com a ordem. |
| HA-F02-03 | Reenviar receção e tentar quantidade acima da tolerância. | Reenvio não duplica entrada; excesso não autorizado é rejeitado. |
| HA-F02-04 | Registar fatura e liquidar parte da obrigação. | Referências ligam ordem, receção, fatura e pagamento; saldo a pagar e movimento de tesouraria conciliam. |
| HA-F02-05 | Devolver parte da quantidade elegível e repetir o pedido. | Efeitos de stock e financeiros seguem a política aprovada, preservam origem e não se repetem. |
| HA-F02-06 | Simular falha entre receção e atualização obrigatória de stock. | Não existe receção confirmada com efeito obrigatório perdido; recuperação produz um único resultado coerente. |

Decisões necessárias: aprovação por valor, autoaprovação, tolerâncias, divergências entre receção e fatura, devoluções e tratamento de pagamentos já realizados.

## 4. F-03 — Assiduidade até ao processamento salarial

Requisitos: RF-M05-02, RF-M24-03 a RF-M24-07, RF-M24-09, RF-M26-02 a RF-M26-04 e RF-M33-01 a RF-M33-04 quando forem usados terminais.

Pré-condições: colaborador ativo, vínculo e horário válidos, método de marcação habilitado e regras de apuramento aprovadas. Para biometria, preparar consentimento e inscrição elegíveis. Definir fuso horário, vigência das regras e política para eventos offline.

| Cenário | Ação | Resultado esperado |
|---|---|---|
| HA-F03-01 | Registar entrada e saída pelos métodos habilitados. | Eventos identificam colaborador, organização, método e instantes necessários; o apuramento reproduz o exemplo aprovado. |
| HA-F03-02 | Sincronizar lote offline com item válido, repetido e inválido. | Cada item recebe resultado identificável; itens aceites persistem uma única vez; rejeições indicam motivo. |
| HA-F03-03 | Reenviar o lote depois de perder a resposta. | Eventos já aceites são reconhecidos sem nova marcação; falha de comunicação não exige adivinhar o resultado. |
| HA-F03-04 | Usar método desativado, prova inválida ou credencial de dispositivo revogada. | Não há marcação aceite nem alteração indevida do apuramento. |
| HA-F03-05 | Pedir correção pelo colaborador e aprovar por RH autorizado. | Pedido preserva evento original; decisão e motivo são auditáveis; só a correção aprovada altera o resultado aplicável. |
| HA-F03-06 | Processar salário com assiduidade, ausência e correção homologadas. | Componentes, deduções e recibo reproduzem o exemplo aprovado; reprocessamento não duplica efeitos confirmados. |
| HA-F03-07 | Registar evento atravessando meia-noite ou após mudança de regra. | Dia de trabalho e regra vigente seguem a política aprovada, sem aplicação retroativa implícita. |

Decisões necessárias: turnos noturnos, atrasos, horas adicionais, faltas, prazo offline, período fechado, retroatividade e impacto salarial. Valores legais e salariais devem ser fornecidos e aprovados pelos responsáveis competentes.

## 5. F-04 — Matrícula até à liquidação de propina

Requisitos: RF-M23-01 a RF-M23-03, RF-M27-01/02/05/06, RF-M17-02/03 e RF-M18-02 quando aplicáveis à integração selecionada.

Pré-condições: instituição, ano letivo, turma e aluno elegíveis; plano de cobrança aprovado; relação de encarregado com vigência definida; integração de pagamento de teste.

| Cenário | Ação | Resultado esperado |
|---|---|---|
| HA-F04-01 | Matricular aluno e gerar cobranças do plano aprovado. | Matrícula e cobranças referenciam aluno, instituição e período corretos; montantes e vencimentos reproduzem o plano. |
| HA-F04-02 | Repetir a geração para o mesmo período e matrícula. | Não surgem obrigações duplicadas para a mesma ocorrência de cobrança. |
| HA-F04-03 | Liquidar uma parcela e repetir a confirmação autenticada. | Saldo reduz apenas pelo valor aceite; recibo e referências conciliam; repetição não duplica pagamento. |
| HA-F04-04 | Consultar pelo aluno, encarregado elegível e encarregado de relação terminada. | Cada perfil recebe apenas os dados autorizados pelas relações e vigência; relação terminada não mantém acesso indevido. |
| HA-F04-05 | Cancelar matrícula com cobranças abertas e já pagas. | Aplica-se a política homologada de cancelamento e devolução; histórico e valores anteriores são preservados. |

Decisões necessárias: descontos, bolsas, multas, vencimentos, cancelamento de matrícula, devoluções e alcance do acesso financeiro do encarregado.

## 6. F-05 — Documento até à assinatura

Requisitos: RF-M31-01 a RF-M31-06, RF-M30-02/03 e RF-M28-04 quando existir aprovação prévia.

Pré-condições: documento e versão definidos, signatários autorizados, aprovação quando exigida, provedor de teste e canais configurados.

| Cenário | Ação | Resultado esperado |
|---|---|---|
| HA-F05-01 | Enviar versão aprovada e concluir assinatura com prova válida. | Evidência liga signatário, versão e resultado; documento final e validação correspondem ao conteúdo enviado. |
| HA-F05-02 | Usar convite expirado, prova inválida ou código já consumido. | Assinatura é rejeitada sem alteração do documento protegido. |
| HA-F05-03 | Repetir callback e simular indisponibilidade do provedor. | Repetição não cria segunda assinatura; indisponibilidade não apresenta conclusão e permite acompanhamento da falha. |
| HA-F05-04 | Concorrer assinatura com cancelamento ou alteração de versão. | Resultado respeita a transição homologada; não existe assinatura atribuída silenciosamente a outra versão. |
| HA-F05-05 | Recusar assinatura e consultar original, versões e evidências. | Recusa conserva ator e motivo aplicáveis; ficheiros protegidos permanecem disponíveis aos perfis autorizados. |

Decisões necessárias: ordem de assinatura, prazos, recusa/cancelamento, alterações após envio, nível de assinatura e regras de verificação pública. Validação funcional não constitui parecer sobre validade jurídica.

## 7. Cenários transversais

Aplicar os cenários seguintes a cada fluxo incluído na fase, com referência às regras RT-01 a RT-06 do catálogo.

| Cenário | Ação | Resultado esperado |
|---|---|---|
| HA-TR-01 | Substituir IDs de documentos, contas, artigos, colaboradores e anexos por IDs da organização B. | Não há consulta, alteração, descarga ou efeito cruzado não autorizado. |
| HA-TR-02 | Executar ação restrita sem permissão e depois da sua revogação. | A ação é impedida segundo a política de revogação aprovada, incluindo sessões existentes. |
| HA-TR-03 | Mudar o contexto de uma conta com vínculos em A e B. | Operações e resultados respeitam a organização selecionada; o vínculo adicional não mistura recursos. |
| HA-TR-04 | Concorrer duas confirmações sobre a mesma operação. | Estado final é único e coerente; documentos, movimentos e evidências não se duplicam. |
| HA-TR-05 | Consultar auditoria após confirmação, rejeição e correção críticas. | Evidências identificam ator, organização, instante, ação, referência e resultado sem divulgar segredos. |
| HA-TR-06 | Falhar envio de notificação depois da confirmação do processo. | Processo mantém estado coerente; falha de entrega é visível e reprocessamento segue a política aprovada. |

## 8. Decisões e conclusão de homologação

Cada decisão pendente deve ter identificador, fluxo/requisito afetado, pergunta, responsável funcional, resposta aprovada, data e versão. A ausência de resposta bloqueia os cenários que dependem dessa regra, sem transformar uma escolha técnica em aprovação de negócio.

Uma fase só pode ser proposta para aceitação após delimitar os requisitos incluídos, executar os cenários aplicáveis, reconciliar os efeitos integrados e documentar defeitos e dependências. Exclusões precisam de justificação e responsável; aprovação deve indicar versão, ambiente e evidências consultadas. Os critérios não funcionais permanecem no BRD e exigem validação própria.
