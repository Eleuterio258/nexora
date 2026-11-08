# Nexora ERP
## Documento de Requisitos de Negócio (BRD)

Versão 0.1 | 14 de outubro de 2026 | E258TECH

Estado: proposta para validação pelos responsáveis de negócio.

Âmbito: plataforma Nexora ERP, incluindo assiduidade, gestão empresarial e gestão escolar.

Base documental: análise do backend de 14/10/2026, código e documentação local do projeto. A existência de código não implica que uma funcionalidade esteja homologada ou operacional em produção.

## 1. Finalidade e controlo do documento

Este BRD estabelece os resultados de negócio esperados, o âmbito funcional, as regras essenciais e os critérios para aceitar o Nexora ERP. Serve de referência comum para direção, responsáveis de área, equipa de produto, desenvolvimento e qualidade. Não substitui a especificação técnica, o contrato comercial ou a validação das obrigações legais aplicáveis.

Os requisitos descrevem o comportamento pretendido. Quando resultam de uma correção identificada na análise, essa ligação é indicada na matriz de rastreabilidade. Prioridades, metas e sequência de entrega são propostas; responsáveis nominais, orçamento e calendário permanecem por definir.

| Campo | Definição |
|---|---|
| Produto | Nexora ERP |
| Organização proponente | E258TECH |
| Patrocinador | A designar pela organização |
| Responsável do produto | A designar |
| Público | Direção, gestores, operação, produto, desenvolvimento e qualidade |
| Fonte principal | docs/analise-backend-2026-10-14.md |
| Fonte complementar | ANALISE-INTEGRACAO-ASSIDUIDADE.md |
| Versão | 0.1 — primeira proposta, sem aprovação registada |

### Convenções

P1 significa obrigatório para os processos incluídos na primeira entrega acordada. P2 significa importante e elegível para entrega seguinte. P3 significa evolução opcional. Esta classificação não obriga a ativar todos os módulos na mesma entrega. A aprovação do âmbito de cada fase determina quais os requisitos que se tornam compromisso de implementação.

## 2. Contexto e necessidade de negócio

O repositório contém um ERP com 33 módulos, orientado à gestão de várias organizações, e integrações com pagamentos, notificações, dispositivos, biometria e assinatura de documentos. Existe ainda uma aplicação de assiduidade e um serviço biométrico separado. Esta base permite organizar processos partilhados e processos específicos de empresas ou instituições de ensino.

Propõe-se que o produto responda à necessidade de consolidar dados e reduzir trabalho repetido entre vendas, compras, stock, finanças e recursos humanos. A frequência atual de retrabalho, erros, atrasos e uso de folhas de cálculo não foi medida; estas hipóteses devem ser confirmadas em entrevistas e num piloto.

Para a direção, a prioridade é dispor de informação coerente para decisão. Para a operação, é executar processos com regras claras e menos reintrodução de dados. Para cada organização cliente, é garantir que os seus dados e autorizações permanecem separados dos de outras organizações.

## 3. Objetivos e indicadores de sucesso

| ID | Objetivo | Indicador e proposta de meta |
|---|---|---|
| OBJ-01 | Reduzir trabalho duplicado | Redução proposta de 30% no tempo de registo de processos selecionados, comparando a linha de base com 90 dias de piloto. |
| OBJ-02 | Tornar os dados financeiros coerentes | 100% dos cenários financeiros homologados conciliados entre documento, pagamento, stock e lançamento aplicável. |
| OBJ-03 | Proteger dados de cada organização | Zero acesso cruzado não autorizado nos cenários de homologação entre duas organizações. |
| OBJ-04 | Melhorar o controlo de assiduidade | 100% das marcações aceites rastreáveis ao colaborador; reenvios de eventos aceites não geram duplicação. |
| OBJ-05 | Tornar decisões e alterações auditáveis | 100% das operações críticas acordadas registadas com ator, organização, data e resultado. |
| OBJ-06 | Assegurar continuidade operacional | Recuperação de uma cópia de segurança demonstrada dentro dos objetivos RPO/RTO acordados. |

As metas são propostas, não resultados alcançados. O responsável do produto deverá definir a linha de base, a amostra, os relatórios de medição e o responsável de cada indicador antes do piloto.

## 4. Partes interessadas e responsabilidades

| Papel | Interesse e responsabilidade proposta |
|---|---|
| Patrocinador / direção | Aprovar objetivos, investimento, prioridades e aceitação final. |
| Responsável do produto | Consolidar necessidades, gerir âmbito e resolver conflitos de prioridade. |
| Administrador da organização | Configurar utilizadores, unidades, perfis e módulos contratados. |
| Comercial / operador de caixa | Validar clientes, vendas, faturação, recebimentos e estornos. |
| Compras / armazém / logística | Validar abastecimento, receção, disponibilidade e circulação de materiais. |
| Financeiro / contabilidade | Validar reconciliação, lançamentos, impostos, moedas e fecho. |
| Recursos humanos / colaboradores | Validar cadastro, horários, ponto, ausências e processamento salarial. |
| Administração escolar | Validar matrícula, turmas, notas, presenças, propinas e portais. |
| Suporte / administração da plataforma | Gerir operação e incidentes com acesso privilegiado controlado. |
| Desenvolvimento / qualidade | Implementar, produzir evidências e corrigir desvios dos requisitos. |

Cada organização deve nomear representantes de homologação. A equipa técnica propõe soluções, mas regras de negócio e aceitação pertencem aos responsáveis funcionais.

## 5. Âmbito

### Incluído

O BRD cobre as áreas abaixo. A ativação depende do tipo de organização, permissões e módulos acordados.

| Área | Módulos identificados no backend |
|---|---|
| Plataforma e identidade | auth, utilizadores, empresas, superadmin, sistema-configuracao |
| Controlo e evidência | seguranca, auditoria, monitoring |
| Relação comercial | gestao-clientes, crm |
| Abastecimento e materiais | gestao-produtos, gestao-stock, compras, logistica |
| Venda e cobrança | modulo-faturacao, pos |
| Gestão financeira | financeiro, tesouraria, contabilidade, impostos, multi-moeda, centros-custo |
| Pessoas e RH | pessoas, recursos-humanos, recrutamento, self-service |
| Ensino | gestao-escolar |
| Processos e comunicação | aprovacoes, tarefas, notifications |
| Documentos e oferta | assinatura-digital, assinaturas |
| Integração com dispositivos | hardware |

### Fora do âmbito desta proposta

A construção de um motor próprio de pagamentos, a substituição integral dos serviços biométricos e a aquisição de equipamentos não são entregas deste BRD. Integrações com sistemas não identificados devem ser objeto de requisito adicional.

Gestão especializada de obras, manutenção de viaturas, produção industrial e contabilidade consolidada de grupo não são assumidas como capacidades homologadas. Podem ser avaliadas como extensões, mesmo quando aparecem em material comercial. Migração histórica completa, novos canais e personalizações por cliente exigem estimativa e aprovação próprias.

## 6. Requisitos de plataforma e dados comuns

| ID / prioridade | Requisito de negócio | Critério de aceitação |
|---|---|---|
| RN-01 / P1 | Separar dados, operações, ficheiros e comunicação de cada organização. | Duas organizações não conseguem consultar ou alterar recursos uma da outra, incluindo chat, relatórios e anexos. |
| RN-02 / P1 | Controlar acesso por identidade, perfil, área e organização selecionada. | Um utilizador com acesso a várias organizações só opera no contexto autorizado; revogação impede novas operações. |
| RN-03 / P1 | Permitir recuperação de acesso com prova válida e uso único. | Um pedido confirmado altera a senha e revoga as sessões aplicáveis; pedidos repetidos ou falhas não produzem sucesso falso. |
| RN-04 / P1 | Gerir empresas, unidades e configuração por organização. | Alterações autorizadas afetam apenas a organização e são refletidas nos processos dependentes. |
| RN-05 / P1 | Manter cadastro coerente de pessoas, clientes, produtos e referências. | Campos obrigatórios e duplicações acordadas são controlados; relações inválidas são rejeitadas. |
| RN-06 / P1 | Registar evidência das operações críticas. | É possível identificar ator, organização, instante, ação e resultado, com consulta restrita a perfis autorizados. |
| RN-07 / P2 | Disponibilizar tarefas, alertas e notificações associadas aos processos. | O destinatário correto recebe ou visualiza o aviso; falhas de entrega ficam identificadas para acompanhamento. |

## 7. Requisitos comerciais, compras e materiais

| ID / prioridade | Requisito de negócio | Critério de aceitação |
|---|---|---|
| RN-08 / P1 | Gerir clientes e informação comercial. | Um cliente pode ser criado, consultado e atualizado dentro das permissões e regras da organização. |
| RN-09 / P2 | Acompanhar oportunidades e atividades de CRM. | O gestor consulta estado, responsável e histórico das oportunidades no seu âmbito. |
| RN-10 / P1 | Gerir produtos, variantes e disponibilidade por armazém. | Operações válidas atualizam stock e mantêm origem, quantidade, unidade e referência rastreáveis. |
| RN-11 / P1 | Executar pedidos de compra, aprovação e receção. | Uma compra sujeita a aprovação não avança sem decisão; a receção atualiza apenas os materiais e quantidades aceites. |
| RN-12 / P1 | Emitir documentos de faturação coerentes com a operação. | Numeração, cliente, linhas, moeda, impostos e totais correspondem às regras aprovadas; cancelamento mantém histórico. |
| RN-13 / P1 | Operar caixa/POS com controlo de abertura, vendas e fecho. | Uma venda autorizada gera os registos aplicáveis; o fecho permite comparar valores esperados e declarados. |
| RN-14 / P1 | Tratar devoluções e estornos sem perder rastreabilidade. | Uma devolução não excede o elegível e reflete corretamente efeitos em stock, cobrança e documentos associados. |
| RN-15 / P2 | Acompanhar entregas e logística. | Responsáveis consultam origem, destino, estado e referência; alterações ficam no histórico autorizado. |

A homologação deve definir a política de stock negativo, os limites de desconto, as regras de aprovação, os documentos obrigatórios e os efeitos de cada cancelamento. Nenhuma destas decisões é assumida como universal para todos os clientes.

## 8. Requisitos financeiros

| ID / prioridade | Requisito de negócio | Critério de aceitação |
|---|---|---|
| RN-16 / P1 | Acompanhar valores a receber e a pagar por referência de negócio. | É possível consultar vencimentos, pagamentos parciais e saldo remanescente de cada obrigação. |
| RN-17 / P1 | Aceitar confirmações de pagamento apenas de origem autenticada. | Confirmações inválidas não mudam saldos nem estado; repetições não duplicam o efeito financeiro. |
| RN-18 / P1 | Preservar coerência do estado de pagamentos. | Eventos fora de ordem não anulam um pagamento confirmado; estornos seguem autorização e fluxo próprios. |
| RN-19 / P1 | Gerir contas, caixas, movimentos e reconciliações. | Os movimentos aceites refletem o saldo; contas externas à organização ou inativas não podem ser movimentadas. |
| RN-20 / P1 | Produzir lançamentos contabilísticos a partir das operações configuradas. | Os lançamentos homologados estão equilibrados e ligados ao documento de origem, sem duplicação. |
| RN-21 / P1 | Aplicar regras de impostos, moeda e arredondamento aprovadas. | Totais e diferenças correspondem aos exemplos validados pelo financeiro, incluindo pagamentos parciais. |
| RN-22 / P2 | Atribuir e consultar custos por centro de custo. | Custos incluídos no modelo podem ser analisados pelo centro autorizado e conciliados com as referências de origem. |

A moeda base, as taxas, os planos de contas e os procedimentos fiscais devem ser validados pelo responsável financeiro competente. Este BRD não atesta conformidade fiscal ou legal nem fixa taxas regulamentares.

## 9. Requisitos de RH, assiduidade e ensino

| ID / prioridade | Requisito de negócio | Critério de aceitação |
|---|---|---|
| RN-23 / P1 | Gerir colaboradores, vínculos, horários e dados necessários a RH. | Alterações autorizadas ficam rastreáveis e são usadas pelos processos de RH aplicáveis. |
| RN-24 / P1 | Registar ponto com os métodos autorizados para cada organização. | Identidade, permissão, método e prova aplicável são validados antes de aceitar a marcação. |
| RN-25 / P1 | Sincronizar marcações offline elegíveis com resultado individual. | Reenvio não duplica eventos; cada marcação indica aceitação, duplicação ou rejeição e respetivo motivo. |
| RN-26 / P1 | Tratar faltas, justificações, férias e correções aprovadas. | Decisões autorizadas alteram o resultado aplicável e preservam motivo, intervenientes e histórico. |
| RN-27 / P1 | Processar componentes salariais e emitir evidência de cálculo. | Os casos de cálculo aprovados por RH/financeiro são reproduzidos; alterações após validação seguem controlo acordado. |
| RN-28 / P2 | Gerir candidaturas e evolução do recrutamento. | Uma candidatura pode ser acompanhada por perfis autorizados, com acesso restrito a documentos pessoais. |
| RN-29 / P1 | Gerir alunos, turmas, matrículas, presenças e notas em instituições de ensino. | Os registos respeitam o ano e a estrutura académica aprovados, com acesso apenas aos intervenientes autorizados. |
| RN-30 / P1 | Gerir propinas e pagamentos associados ao aluno. | Pagamentos válidos atualizam a obrigação correta; duplicações não alteram novamente o saldo. |
| RN-31 / P2 | Disponibilizar portais de aluno, encarregado e professor. | Cada perfil consulta apenas alunos, turmas e ações que lhe foram atribuídos. |

No âmbito escolar, P1 só se aplica às fases destinadas a instituições de ensino. Para uma empresa sem ensino, RN-29 a RN-31 não são condição de entrada em produção.

## 10. Documentos, aprovações e integrações

| ID / prioridade | Requisito de negócio | Critério de aceitação |
|---|---|---|
| RN-32 / P1 | Executar aprovações segundo responsabilidades e limites acordados. | Um processo pendente não é considerado aprovado sem decisão válida e rastreável. |
| RN-33 / P2 | Enviar documentos para assinatura e conservar a evidência. | É possível associar documento, versão, signatário, decisão e evidência; versões assinadas não são substituídas silenciosamente. |
| RN-34 / P1 | Controlar integrações com gateways, biometria e dispositivos. | Apenas integrações autorizadas produzem efeitos; indisponibilidade gera resultado claro e possibilidade de recuperação. |
| RN-35 / P1 | Disponibilizar relatórios com filtros e acesso coerentes. | Dados apresentados correspondem ao período, organização e perfil selecionados e conciliam com a origem nos casos homologados. |
| RN-36 / P2 | Ativar módulos e serviços segundo a oferta contratada. | Uma organização só acede às funcionalidades habilitadas, independentemente de conhecer a ligação ou endereço do recurso. |

## 11. Fluxos de negócio principais

### F-01 — Venda até à reconciliação

Selecionar cliente e artigos → validar preço, imposto e stock → confirmar venda/documento → iniciar ou registar pagamento → validar confirmação → atualizar a obrigação e os efeitos configurados → reconciliar. Rejeições preservam o estado anterior. Devoluções usam fluxo autorizado associado à venda original.

### F-02 — Compra até ao pagamento

Criar pedido → submeter para aprovação quando exigida → aprovar ou rejeitar → receber materiais → registar documento do fornecedor → reconhecer a obrigação → pagar e reconciliar. Aprovação e receção não se substituem; divergências de quantidade ou valor ficam registadas.

### F-03 — Assiduidade até ao processamento salarial

Configurar colaborador, horário e métodos → recolher marcação e prova aplicável → validar e registar evento → sincronizar pendências elegíveis → apurar assiduidade → analisar exceções e justificações → aprovar resultados → usar no processamento salarial conforme regras homologadas.

### F-04 — Matrícula até à liquidação de propina

Registar aluno → matricular na estrutura académica → gerar obrigação de propina → iniciar cobrança → validar pagamento → atualizar saldo → disponibilizar informação no portal autorizado. Uma confirmação repetida não cria um segundo pagamento.

### F-05 — Documento até à assinatura

Preparar versão → selecionar signatários → enviar convite → autenticar a ação de assinatura → executar e verificar resultado → conservar evidência → disponibilizar verificação autorizada. Uma falha não deve apresentar o documento como assinado.

## 12. Regras de negócio e limitações conhecidas

| ID | Regra proposta ou limite identificado |
|---|---|
| RB-01 | A organização e a identidade do ator devem ser determinadas a partir de contexto autorizado; IDs fornecidos pelo utilizador não conferem acesso. |
| RB-02 | Operações financeiras e alterações críticas só apresentam sucesso depois de persistidos todos os efeitos obrigatórios. |
| RB-03 | Repetir um evento aceite não deve duplicar o seu efeito. Uma alteração exige ação explícita e autorização própria. |
| RB-04 | Cancelamentos, correções e estornos preservam referência à operação original e motivo da decisão. |
| RB-05 | Os dados pessoais e biométricos têm finalidade, acesso e retenção aprovados antes da ativação do processo. |
| RB-06 | No fluxo offline identificado, apenas PIN e impressão digital são elegíveis; não se promete reconhecimento facial offline. |
| RB-07 | O fluxo offline identificado aceita até 100 marcações por lote, até 72 horas no passado e com tolerância de cinco minutos no futuro. Mudanças destes limites requerem validação de RH e produto. |
| RB-08 | A impressão digital local do telemóvel não constitui, no fluxo atual documentado, uma prova biométrica verificada pelo servidor. A organização deve aprovar o seu uso ou exigir outro método. |
| RB-09 | Marcações tardias ou inconsistentes podem exigir revisão de RH; não se presume apuramento correto de todos os cenários offline sem homologação. |
| RB-10 | O acesso de suporte a dados de clientes deve ter finalidade autorizada e registo de auditoria; o perfil privilegiado não elimina esse controlo. |

RB-06 a RB-09 derivam da documentação de integração existente e precisam de confirmação funcional nos dispositivos e ambientes utilizados. Não são alegações de desempenho biométrico ou garantias de resistência a fraude.

## 13. Requisitos não funcionais

| ID / prioridade | Requisito | Evidência de aceitação proposta |
|---|---|---|
| RNF-01 / P1 | Segurança: proteger acesso, segredos, canais e tentativas de autenticação. | Casos de acesso indevido, revogação e tentativas excessivas são rejeitados; não existem credenciais de produção incorporadas nos artefactos entregues. |
| RNF-02 / P1 | Integridade: preservar operações sob repetição, falha e concorrência. | Testes demonstram ausência de duplicação, atualização parcial e regressão indevida nos fluxos críticos incluídos. |
| RNF-03 / P1 | Privacidade: definir finalidade, retenção, acesso e tratamento de pedidos sobre dados pessoais. | Política aprovada e cenários de consulta, exportação e eliminação/retenção executados conforme essa política. |
| RNF-04 / P1 | Recuperação: manter cópias e procedimentos de restauro. | Restauro num ambiente isolado comprovado. Proposta inicial: RPO de 24 horas e RTO de quatro horas, sujeitos a aprovação. |
| RNF-05 / P1 | Desempenho: responder aos processos interativos com capacidade acordada. | Proposta: percentil 95 até dois segundos nas operações simples, excluindo serviços externos, com volume e concorrência definidos antes do teste. |
| RNF-06 / P1 | Disponibilidade: monitorizar o serviço e dependências essenciais. | Proposta de 99,5% mensal, excluindo manutenção previamente acordada; medição e processo de incidente definidos. Não é SLA contratado. |
| RNF-07 / P1 | Usabilidade: apresentar estados, erros e recuperação compreensíveis em português. | Utilizadores do piloto completam os cenários sem interpretar mensagens técnicas; formatos de data e moeda são aprovados. |
| RNF-08 / P1 | Operação: entregar configuração, monitorização e diagnóstico utilizáveis. | API, jobs e integrações necessárias iniciam no ambiente homologado; falhas são detetadas e não ficam ocultas. |
| RNF-09 / P2 | Evolução: permitir alteração de módulos com regressão controlada. | Alterações mantêm os cenários críticos aprovados e têm instruções de atualização e reversão aplicáveis. |

Os valores quantitativos desta secção são propostas. Dependem de infraestrutura, volumes, janelas de operação e custo; devem ser acordados antes de serem usados como condições contratuais.

## 14. Dados, migração e dependências

As categorias centrais incluem organizações, memberships, pessoas, clientes, produtos, documentos, movimentos, pagamentos, colaboradores, marcações e dados escolares. Dados de autenticação, biometria, contactos pessoais e documentos de recrutamento exigem acesso especialmente restrito.

O plano de migração deverá identificar fontes, responsáveis, campos obrigatórios, tratamento de duplicados, saldos de abertura e reconciliação. A aceitação exige amostras verificadas, contagem de registos, saldos conferidos e possibilidade de restaurar o estado anterior. Os volumes, fontes legadas e período histórico ainda não estão definidos.

Dependências identificadas: gateway Nexora Pay; FaceClock e dispositivos; armazenamento de ficheiros; serviços de email, SMS e notificações push; certificados/provedor de assinatura; base de dados e infraestrutura de execução. Cada dependência requer responsável, credenciais, ambiente de teste e procedimento de indisponibilidade. A presença de uma integração no código não confirma contrato ativo com o fornecedor.

## 15. Riscos e decisões pendentes

| ID | Risco ou decisão | Tratamento / responsável proposto |
|---|---|---|
| R-01 | Fragilidades de autenticação financeira e reposição de senha identificadas na análise. | Corrigir e comprovar RN-03, RN-17 e RNF-01 antes da ativação dos respetivos fluxos. Produto, desenvolvimento e qualidade. |
| R-02 | Isolamento e concorrência do chat insuficientes. | Corrigir antes de disponibilizar comunicação entre utilizadores; comprovar RN-01 e RNF-02. |
| R-03 | Jobs separados podem não iniciar com a configuração atual. | Homologar configuração e despacho/reconciliação necessários à fase. Operação e desenvolvimento. |
| R-04 | Métodos biométricos e operação offline podem ser interpretados como garantia de identidade. | Aprovar política de métodos e testar equipamentos reais. RH e produto. |
| R-05 | Regras fiscais, salariais e académicas não foram aprovadas neste trabalho. | Obter exemplos, regras e validação dos especialistas funcionais antes da homologação. |
| R-06 | Qualidade e volume dos dados históricos desconhecidos. | Executar levantamento e migração piloto antes de fixar prazo/custo. |
| D-01 | Organizações, módulos e perfis da primeira entrega. | Decisão do patrocinador e responsável do produto. |
| D-02 | Metas de desempenho, disponibilidade, RPO/RTO e retenção. | Decisão conjunta de negócio e operação, com estimativa de custo. |
| D-03 | Orçamento, calendário, equipa e responsáveis nominais. | Definir após âmbito e estimativas; não há compromisso registado neste BRD. |
| D-04 | Política de stock, descontos, aprovações e dados biométricos. | Aprovar por área e organização antes da parametrização. |

## 16. Homologação e rastreabilidade

| Cenário | Requisitos relacionados | Resultado obrigatório |
|---|---|---|
| H-01 — Separação entre organizações | RN-01, RN-02, RN-06, RNF-01 | Recursos e presença do chat não são divulgados a outra organização; tentativas são rejeitadas e auditáveis. |
| H-02 — Recuperação de acesso | RN-03, RNF-02 | Token usado uma vez; corrida entre dois pedidos não aceita ambos; falha de gravação não apresenta sucesso. |
| H-03 — Venda e recebimento | RN-10, RN-12, RN-13, RN-16 a RN-21 | Documento, stock, obrigação e pagamento conciliam segundo a configuração aprovada. |
| H-04 — Callback repetido e fora de ordem | RN-17, RN-18, RNF-02 | Origem inválida não altera dados; reenvio não duplica; evento tardio não faz regredir estado final. |
| H-05 — Compra e devolução | RN-11, RN-14, RN-19, RN-20, RN-32 | Aprovação, receção e efeitos financeiros respeitam o processo e o limite elegível. |
| H-06 — Ponto e sincronização | RN-23 a RN-27, RN-34 | Eventos aceites ficam no colaborador certo, sem duplicação; rejeições e correções são rastreáveis. |
| H-07 — Matrícula e propina | RN-29 a RN-31 | Portal mostra apenas dados autorizados; cobrança atualiza a obrigação correta uma única vez. |
| H-08 — Assinatura e evidência | RN-33, RN-34, RNF-02 | Falha não gera assinatura fictícia; versão e evidência permanecem associadas e protegidas. |
| H-09 — Continuidade e operação | RNF-04 a RNF-08 | Restauro e monitorização demonstrados; jobs necessários funcionam no ambiente de homologação. |

A análise de 14/10/2026 liga diretamente os problemas de callbacks a RN-17/RN-18; passwords a RN-03; chat a RN-01/RNF-02; arranque do worker a RNF-08; e idempotência a RNF-02. Os restantes requisitos traduzem capacidades e necessidades propostas e requerem validação funcional própria.

Para cada cenário, qualidade deverá registar ambiente, massa de dados, passos, resultado esperado, resultado observado, defeitos e decisão do responsável funcional. Testes técnicos aprovados não substituem homologação de negócio. A análise anterior registou testes do módulo principal e análise estática aprovados, testes PostgreSQL não executados e falhas na suite própria da biblioteca PDF modificada.

## 17. Entrega, aprovação e gestão de alterações

### Sequência proposta

Fase 1 — Validar organizações e processos prioritários, regras, indicadores, dados e responsáveis. Resolver as decisões que afetam a primeira entrega.

Fase 2 — Estabilizar identidade, isolamento, pagamentos, integridade e operação. Executar homologação dos controlos críticos antes de disponibilizar os fluxos associados.

Fase 3 — Entregar os módulos empresariais selecionados, migrar os dados acordados e realizar piloto com utilizadores representativos. Para instituições de ensino, incluir os processos escolares aprovados.

Fase 4 — Expandir módulos e integrações a partir dos resultados do piloto, medir os objetivos e formalizar suporte. Não existem datas ou duração aprovadas para estas fases.

### Condições de aceitação

A entrega é aceite quando o âmbito da fase está aprovado, os requisitos obrigatórios incluídos têm evidência de homologação, não existem defeitos críticos ou altos abertos nesses fluxos, os dados migrados conciliam e os responsáveis recebem formação e instruções operacionais. Desvios de menor impacto exigem decisão documentada com responsável e prazo de resolução.

### Registo de aprovação

| Aprovação | Responsável | Estado |
|---|---|---|
| Objetivos, âmbito e investimento | Patrocinador | Pendente |
| Requisitos e prioridades | Responsável do produto | Pendente |
| Regras e homologação funcional | Responsáveis das áreas incluídas | Pendente |
| Segurança, privacidade e operação | Responsável designado | Pendente |
| Aceitação da fase entregue | Patrocinador e representantes funcionais | Pendente |

Uma alteração deve indicar motivo, requisitos afetados, impacto em dados, custo, prazo, testes e operação. O responsável do produto avalia e o patrocinador decide quando houver mudança de âmbito, investimento ou risco aceite. A nova versão deve conservar o histórico da decisão e atualizar a matriz de homologação.

## 18. Glossário e fontes

BRD: documento de requisitos de negócio. ERP: sistema integrado de gestão. Organização/tenant: contexto isolado de um cliente. Membership: vínculo de acesso de um utilizador a uma organização. POS: ponto de venda. Idempotência: repetir uma operação sem duplicar o efeito. RPO: perda máxima de dados admissível medida em tempo. RTO: tempo máximo acordado para recuperar o serviço.

Fontes locais consultadas: docs/analise-backend-2026-10-14.md; ANALISE-INTEGRACAO-ASSIDUIDADE.md; backend/internal/router/router.go; backend/internal/shared/contracts/erp_ports.go; backend/internal/modules/recursos-humanos/service/assiduidade/regras.go. A carta comercial em docs/cartas foi usada apenas como contexto e não como prova de capacidades homologadas.

Este documento foi elaborado a partir das fontes disponíveis em 14/10/2026. Não foram realizadas entrevistas com responsáveis de negócio nem registadas aprovações nesta versão.
