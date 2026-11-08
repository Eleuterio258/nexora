# Business Requirements Document (BRD)

## 1. Identificação do documento

| Campo | Valor |
| --- | --- |
| Projecto | Sistema de Gestão de Assiduidade integrado com o ERP |
| Referência | BRD-ASS-001 |
| Versão | 0.1 |
| Data | 25/09/2026 |
| Estado | Rascunho para validação |
| Responsável de negócio | A designar |
| Aprovação | Pendente |

Este documento define as necessidades de negócio e os resultados esperados do sistema de assiduidade. Os requisitos representam uma proposta de âmbito; não constituem uma declaração de funcionalidades já implementadas. Prioridades, metas, orçamento e calendário devem ser confirmados pelos responsáveis do projecto.

## 2. Contexto e oportunidade

O projecto prevê a gestão de assiduidade com aplicação Android, terminais de marcação, reconhecimento facial, API, integração com ERP e suporte a múltiplas organizações (multi-tenancy).

Pretende-se centralizar os registos de presença e transformar as marcações em informação utilizável pelos colaboradores, chefias e Recursos Humanos (RH). A hipótese de negócio a validar é que a centralização reduzirá o trabalho manual, as divergências nos apuramentos e o tempo necessário para fechar cada período.

## 3. Objectivos de negócio

| ID | Objectivo | Indicador de resultado | Meta |
| --- | --- | --- | --- |
| OBJ-01 | Reduzir o esforço administrativo no apuramento da assiduidade | Horas de trabalho de RH por período | Definir após medição inicial |
| OBJ-02 | Melhorar a qualidade dos registos | Percentagem de marcações que exigem correcção | Definir no piloto |
| OBJ-03 | Acelerar o fecho dos períodos | Tempo entre fim do período e aprovação do fecho | Definir com RH |
| OBJ-04 | Dar visibilidade aos colaboradores e chefias | Percentagem de colaboradores com acesso ao próprio histórico | Definir no piloto |
| OBJ-05 | Disponibilizar informação consistente ao ERP | Percentagem de períodos exportados e reconciliados sem divergências | Definir com a equipa ERP |
| OBJ-06 | Garantir rastreabilidade e separação entre organizações | Ocorrências de acesso indevido e alterações sem autoria | Zero nos cenários de aceitação |

RH e a gestão do projecto devem recolher a situação inicial antes do piloto e comparar os resultados no seu encerramento.

## 4. Partes interessadas

| Parte interessada | Necessidade / responsabilidade |
| --- | --- |
| Direcção / patrocinador | Validar objectivos, âmbito, investimento e entrada em produção |
| Recursos Humanos | Definir políticas de assiduidade, tratar excepções e validar apuramentos |
| Chefias | Acompanhar equipas e decidir pedidos dentro das suas competências |
| Colaboradores | Marcar ponto, consultar resultados e solicitar justificações ou correcções |
| Administração da organização | Configurar utilizadores, acessos, locais e dispositivos autorizados |
| Equipa técnica e suporte | Assegurar integração, disponibilidade, recuperação e suporte |
| Responsável pela protecção de dados | Validar políticas de tratamento, acesso e retenção de dados pessoais |
| Equipa ERP / processamento salarial | Definir dados de integração e reconciliar os resultados recebidos |

Os nomes dos responsáveis e os limites de aprovação serão definidos antes do piloto.

## 5. Âmbito proposto

### 5.1. Incluído

- Organizações, estabelecimentos, departamentos, colaboradores e perfis de acesso.
- Horários, turnos, calendários, tolerâncias e pausas configuráveis.
- Marcações de entrada e saída através de aplicação Android e terminais autorizados.
- Reconhecimento facial, incluindo registo biométrico e prova de vida, sujeito a validação técnica e das políticas de dados.
- Métodos alternativos de marcação, a seleccionar entre QR Code, NFC, impressão digital e marcação com localização, conforme dispositivos e contexto operacional.
- Apuramento de presenças, atrasos, faltas, pausas e horas extraordinárias.
- Gestão de férias, ausências justificadas e pedidos de correcção.
- Aprovações, fecho de período, relatórios e integração com ERP.
- Isolamento entre organizações, auditoria e gestão do ciclo de vida dos dados.
- Continuidade das marcações perante falhas de conectividade, com regras de sincronização a detalhar.

### 5.2. Fora do âmbito desta proposta

- Cálculo integral de salários, descontos e pagamentos bancários.
- Substituição dos restantes módulos do ERP.
- Desenvolvimento ou fabrico de equipamento biométrico.
- Vigilância contínua ou acompanhamento da localização fora dos eventos de marcação autorizados.
- Definição de políticas laborais pela equipa de desenvolvimento.

Novas necessidades devem ser avaliadas quanto a benefício, custo, prazo e impacto antes de integrarem o âmbito.

## 6. Processo de negócio pretendido

1. A administração configura a organização, os locais, os utilizadores e os dispositivos.
2. RH associa colaboradores a horários, turnos e regras com datas de vigência.
3. O colaborador recebe acesso e é habilitado aos métodos de marcação aplicáveis.
4. O colaborador regista entradas, saídas e pausas; recebe confirmação ou indicação de pendência.
5. O sistema apura a assiduidade e apresenta inconsistências para tratamento.
6. O colaborador ou RH apresenta uma justificação ou pedido de correcção.
7. A chefia ou RH decide o pedido, preservando o histórico da decisão.
8. RH verifica as pendências e fecha o período segundo as regras aprovadas.
9. Os resultados aprovados são disponibilizados ao ERP e reconciliados.

## 7. Requisitos de negócio

As prioridades abaixo são propostas: **Essencial** significa necessário para aceitar a primeira entrega; **Desejável** depende da validação do piloto e da capacidade de entrega.

| ID | Requisito | Prioridade | Evidência de aceitação |
| --- | --- | --- | --- |
| BR-01 | Cada organização deve gerir apenas os seus dados e operações autorizadas | Essencial | Utilizadores e dispositivos de uma organização não acedem aos dados de outra nos cenários de teste |
| BR-02 | RH deve configurar horários, turnos, calendários e tolerâncias por contexto aplicável | Essencial | Apuramento de um conjunto de referência corresponde aos resultados aprovados por RH |
| BR-03 | Cada marcação deve identificar colaborador, organização, instante, origem e método | Essencial | Histórico permite consultar a origem e o estado de cada registo |
| BR-04 | O sistema deve suportar marcação facial com prova de vida e tratamento de falhas de reconhecimento | Essencial | Piloto valida reconhecimento, rejeição de tentativas simuladas e alternativa autorizada |
| BR-05 | A organização deve seleccionar os métodos alternativos adequados à sua operação | Desejável | Métodos seleccionados são demonstrados nos dispositivos aprovados |
| BR-06 | Falhas de ligação devem permitir continuidade controlada e posterior reconciliação | Essencial | Marcações pendentes são sincronizadas sem perda nem duplicação no cenário de interrupção acordado |
| BR-07 | RH deve obter apuramentos de presenças, atrasos, faltas, pausas e horas extraordinárias | Essencial | Cenários de referência, incluindo turnos que atravessam a meia-noite, são aprovados por RH |
| BR-08 | Colaboradores devem solicitar férias, ausências e justificações e acompanhar a decisão | Essencial | Pedido percorre os estados aplicáveis com autoria e motivo da decisão |
| BR-09 | Correcções devem exigir justificação e decisão de um utilizador com permissão de decisão sobre o colaborador | Essencial | Registo original, alteração, autor, aprovador e motivo permanecem consultáveis |
| BR-10 | RH deve fechar períodos e controlar a sua eventual reabertura | Essencial | Alterações a períodos fechados exigem reabertura autorizada e auditada |
| BR-11 | Colaboradores e chefias devem consultar informação dentro do seu âmbito de acesso | Essencial | Colaborador consulta o próprio histórico e chefia apenas as equipas autorizadas |
| BR-12 | RH deve produzir relatórios por período, colaborador e estrutura organizacional | Essencial | Totais apresentados coincidem com os apuramentos e filtros seleccionados |
| BR-13 | Resultados aprovados devem ser disponibilizados ao ERP com reconciliação | Essencial | Reenvio não duplica resultados e falhas ficam identificadas para tratamento |
| BR-14 | Acções críticas devem ser rastreáveis | Essencial | Auditoria identifica actor, data, organização, acção e objecto afectado |
| BR-15 | Dados pessoais e biométricos devem seguir políticas aprovadas de acesso, retenção e eliminação | Essencial | Responsável designado valida os cenários de acesso e ciclo de vida dos dados |
| BR-16 | A operação deve permitir identificar falhas e recuperar o serviço e os dados | Essencial | Equipa de suporte demonstra detecção de falha e recuperação em exercício acordado |

## 8. Políticas de negócio a detalhar

- Horários, tolerâncias, feriados e regras de cálculo devem ter âmbito e vigência explícitos.
- Marcações incompletas ou inconsistentes devem gerar pendências para análise.
- Horas extraordinárias apuradas devem distinguir-se das horas aprovadas para processamento.
- Pedidos devem obedecer a uma cadeia de aprovação; a política de auto-aprovação deve ser definida por RH.
- Correcções e reaberturas devem conservar histórico e motivo.
- Eventos repetidos durante sincronização ou integração não devem produzir resultados duplicados.
- O tratamento de diferenças entre a hora do dispositivo e a hora de referência deve ser definido antes do piloto.
- Falhas biométricas devem permitir um procedimento alternativo autorizado e auditável.
- A recolha de localização deve estar associada à finalidade de marcação e à política aprovada.
- Os critérios de utilização de biometria, os registos de consentimento quando aplicáveis e os prazos de retenção precisam de validação pelos responsáveis competentes.

Os valores concretos e as excepções serão documentados no documento de Regras de Negócio.

## 9. Dados e integrações

| Domínio | Necessidade de negócio | Decisão pendente |
| --- | --- | --- |
| Colaboradores e estrutura organizacional | Identificação consistente entre assiduidade e ERP | Fonte principal, identificadores e frequência de actualização |
| Marcações e apuramentos | Manter origem, estado e ligação ao período | Regras de reconciliação e retenção |
| Ausências e saldos | Evitar divergências entre pedidos, aprovações e saldos | Sistema responsável pelos saldos |
| Resultados para processamento | Disponibilizar apenas a versão aprovada do período | Formato, periodicidade e tratamento de reaberturas |
| Biometria e dispositivos | Controlar habilitação, acesso e revogação | Equipamentos, armazenamento e ciclo de vida |

A especificação de APIs deverá detalhar contratos, autenticação, erros e reenvios a partir destes requisitos.

## 10. Qualidade e continuidade do serviço

O sistema deve apresentar confirmações claras de marcação, distinguir registos pendentes de registos aceites, proteger os acessos e permitir recuperação de dados. Os compromissos quantitativos serão definidos antes da aceitação técnica.

| Aspecto | Parâmetro a acordar | Responsável pela validação |
| --- | --- | --- |
| Capacidade | Organizações, colaboradores, terminais e marcações no pico | Negócio e equipa técnica |
| Desempenho | Tempo aceitável de confirmação e consulta | RH e equipa técnica |
| Disponibilidade | Janela de serviço e indisponibilidade tolerada | Direcção e operação |
| Recuperação | Tempo de recuperação (RTO) e perda de dados tolerada (RPO) | Direcção e operação |
| Operação sem ligação | Duração suportada, capacidade local e prazo de sincronização | Operação e equipa técnica |
| Biometria | Limites de falsa aceitação/rejeição e condições de avaliação | Negócio e equipa técnica |

## 11. Pressupostos, dependências e restrições

- RH disponibilizará políticas e exemplos de cálculo para validação.
- A organização designará responsáveis por configuração, aprovações e fecho.
- A integração depende de acesso aos ambientes e contratos do ERP.
- Os equipamentos Android e periféricos serão seleccionados e testados antes da generalização.
- O cadastro de colaboradores deverá ser reconciliado antes da migração.
- Orçamento, equipa, volumes, datas e requisitos específicos de cada organização estão por confirmar.
- A documentação existente serve de referência; a compatibilidade e cobertura da implementação exigem análise técnica própria.

## 12. Riscos de negócio

| Risco | Impacto | Resposta proposta | Responsável |
| --- | --- | --- | --- |
| Cadastros ou horários incorrectos | Apuramentos inconsistentes | Reconciliar dados e validar amostras antes do piloto | RH |
| Falhas de conectividade | Marcações pendentes e atraso no fecho | Validar continuidade e reconciliação | Equipa técnica |
| Falhas ou uso indevido de biometria | Recusa de marcações ou registos indevidos | Testar condições reais, prova de vida e método alternativo | Equipa técnica e RH |
| Acesso indevido a dados | Exposição de informação pessoal | Validar isolamento, permissões e auditoria | Segurança / administração |
| Divergência com ERP | Processamento com dados inconsistentes | Reconciliar resultados e controlar reenvios | Equipa ERP e RH |
| Baixa adopção pelos utilizadores | Dependência de processos manuais | Formação, piloto acompanhado e suporte | Gestão do projecto |
| Alterações frequentes de âmbito | Atrasos e aumento de custo | Registar pedidos e aprovar impactos | Patrocinador |

## 13. Entrega e aceitação

### 13.1. Etapas propostas

1. **Validação de negócio:** confirmar âmbito, responsáveis, políticas e metas.
2. **Especificação:** detalhar requisitos, processos, dados, integrações e critérios de teste.
3. **Piloto:** operar com uma organização e um grupo representativo de colaboradores, horários e dispositivos.
4. **Avaliação:** comparar resultados com os apuramentos de referência e tratar desvios.
5. **Entrada em produção:** migrar dados validados, formar utilizadores e activar suporte.
6. **Acompanhamento:** medir os indicadores e priorizar melhorias.

Datas, custos e responsáveis nominais serão definidos no Plano de Implementação.

### 13.2. Condições de aceitação do negócio

- Todos os requisitos essenciais têm evidência de validação e responsável pelo aceite.
- RH aprova os resultados dos cenários representativos de horários, ausências, correcções e fecho.
- A integração com o ERP é reconciliada, incluindo falha e reenvio.
- O isolamento entre organizações e a matriz de acessos são validados.
- O piloto demonstra o funcionamento dos métodos de marcação seleccionados e a continuidade acordada.
- As políticas de dados pessoais e biométricos estão aprovadas pelos responsáveis designados.
- Formação, suporte, recuperação e procedimento de contingência estão preparados.
- Não existem defeitos classificados como impeditivos de produção segundo a classificação acordada.

## 14. Decisões pendentes e aprovação

| ID | Decisão | Responsável proposto |
| --- | --- | --- |
| DEC-01 | Confirmar patrocinador e responsável de negócio | Direcção |
| DEC-02 | Aprovar prioridades, primeira entrega e grupo piloto | Patrocinador e RH |
| DEC-03 | Definir regras de cálculo e cadeia de aprovação | RH |
| DEC-04 | Seleccionar dispositivos e métodos de marcação | Negócio e equipa técnica |
| DEC-05 | Aprovar políticas de dados e utilização da biometria | Responsável pela protecção de dados |
| DEC-06 | Definir fonte dos cadastros e contratos de integração | Equipa ERP e RH |
| DEC-07 | Fixar metas, capacidade e compromissos de serviço | Direcção e operação |
| DEC-08 | Aprovar orçamento e calendário | Patrocinador |

| Papel | Nome | Decisão / data |
| --- | --- | --- |
| Patrocinador | A designar | Pendente |
| Responsável de RH | A designar | Pendente |
| Responsável técnico | A designar | Pendente |
| Responsável ERP | A designar | Pendente |

Após aprovação, alterações ao BRD devem identificar requisitos afectados, motivo, impacto, aprovador e nova versão.

## 15. Referências e rastreabilidade

- [Estrutura documental do projecto](README.MD).
- [Inventário de endpoints de assiduidade do ERP](../endpoints_assiduidade_erp.md).
- [Documentação da aplicação Android de assiduidade](../nexora_assiduidade/README.md).

Os identificadores BR-01 a BR-16 devem ser ligados aos futuros requisitos funcionais, regras de negócio, casos de uso e testes através da Matriz de Rastreabilidade de Requisitos (RTM).

## 16. Glossário

| Termo | Significado |
| --- | --- |
| BRD | Documento de requisitos de negócio |
| Marcação | Registo de um evento de assiduidade, como entrada ou saída |
| Apuramento | Resultado da aplicação das regras de assiduidade às marcações e ausências |
| Fecho de período | Validação e bloqueio controlado dos resultados de um intervalo |
| Tenant | Organização cujos dados e acessos são isolados dos das restantes |
| Enrollment | Registo inicial da referência biométrica do colaborador |
| Prova de vida | Verificação destinada a distinguir uma pessoa presente de uma tentativa de simulação |
| ERP | Sistema integrado de gestão empresarial |

