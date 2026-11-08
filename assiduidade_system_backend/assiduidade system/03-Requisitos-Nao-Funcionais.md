# Requisitos Não Funcionais — Sistema de Gestão de Assiduidade

## 1. Controlo do documento

| Campo | Valor |
| --- | --- |
| Referência | RNF-ASS-001 |
| Versão | 0.1 |
| Data | 25/09/2026 |
| Estado | Rascunho para validação |
| Responsáveis | Negócio, RH, equipa técnica, operação e responsável de dados — nomes a designar |
| Base documental | BRDs e Requisitos Funcionais referenciados na secção 10 |

## 2. Objectivo e convenções

Este documento define as condições de qualidade, segurança e operação esperadas para a plataforma central, aplicação Android, terminais e integrações do sistema de assiduidade. Complementa os requisitos funcionais RF-001 a RF-065 e não comprova que a implementação actual satisfaça estes requisitos.

Cada requisito possui identificador estável, prioridade e evidência mínima de aceitação. **E — Essencial** e **D — Desejável** correspondem a Must e Should do BRD detalhado. As prioridades e os parâmetros ainda precisam de aprovação para a primeira entrega.

Os valores quantitativos apresentados como **propostos** são metas de trabalho, não compromissos de serviço aprovados. Parâmetros assinalados como **a definir** devem ser preenchidos antes do ensaio ou aceite correspondente; a ausência de valor não equivale a aprovação. As condições de execução e as evidências devem acompanhar qualquer resultado de teste.

## 3. Perfil de operação e parâmetros de medição

### 3.1. Volumetria a aprovar

| Parâmetro | Informação necessária | Estado / responsável |
| --- | --- | --- |
| Organizações | Quantidade inicial, crescimento e distribuição por dimensão | A definir — negócio |
| Colaboradores | Total e máximo por tenant | A definir — RH e negócio |
| Dispositivos | Terminais activos e ligações simultâneas | A definir — operação |
| Utilizadores | Sessões concorrentes e mistura de consultas, pedidos e administração | A definir — negócio |
| Eventos | Marcações por segundo no pico e concentração nas mudanças de turno | A definir — RH e equipa técnica |
| Sincronização | Terminais a reconectar em simultâneo e eventos acumulados por terminal | A definir — operação |
| Histórico | Volume de eventos, anexos e anos de retenção por categoria | A definir — RH e responsável de dados |
| Relatórios | Filtros correntes, intervalo máximo, linhas e execuções concorrentes | A definir — RH |
| Rede e equipamentos | Latência, perda, largura de banda e modelos/versões de equipamento | A definir — equipa técnica |
| Crescimento | Horizonte de planeamento, factor de carga e margem de capacidade | A definir — negócio e equipa técnica |

Os testes devem incluir tenants pequenos e grandes, períodos de fecho, relatórios concorrentes e reconexão de terminais. A mistura de operações, duração do ensaio, volume histórico e recursos do ambiente devem ser registados para permitir comparação.

### 3.2. Metas e definições

| Indicador | Definição da medição | Meta / estado |
| --- | --- | --- |
| Disponibilidade central | 100 × (minutos elegíveis − minutos indisponíveis) / minutos elegíveis; medir os percursos críticos acordados | ≥ 99,5% por mês, proposta do BRD detalhado |
| Confirmação online | Desde submissão do evento após identificação até confirmação central apresentada; não inclui tempo de captura facial | P95 a definir |
| Experiência de marcação | Desde início da interacção até resultado apresentado, incluindo identificação | P95 a definir por método/dispositivo |
| Visibilidade no backoffice | Desde aceitação central até evento consultável no backoffice | P95 ≤ 60 segundos, proposta do BRD detalhado; fronteiras de medição propostas nesta versão |
| Relatório operacional | Desde pedido válido até resultado completo disponível nos filtros correntes acordados | P95 ≤ 30 segundos, proposta do BRD detalhado |
| Erros técnicos | Operações que falham tecnicamente / operações tentadas; rejeições de negócio contabilizadas separadamente | Limite e janela a definir |
| Sincronização após reconexão | Desde restabelecimento da ligação até confirmação de todos os eventos do lote de referência | Limite a definir segundo volume e rede |
| Autonomia offline | Intervalo e quantidade de eventos suportados sem ligação central | Duração e capacidade a definir |
| Recuperação | RTO: tempo entre interrupção e serviço recuperado e validado; RPO: distância temporal até ao último dado recuperável | Definir por classe de serviço na secção 6 |

P95 é o valor abaixo do qual se encontram 95% das durações observadas. Cada medição deve publicar quantidade de amostras, percentis, erros e timeouts; operações falhadas não podem ser removidas silenciosamente para melhorar os resultados. Consultas, marcações e relatórios devem ser medidos separadamente.

Minutos elegíveis excluem apenas manutenção previamente comunicada e aprovada segundo a política de serviço. Manutenção excedida e interrupções não planeadas contam como indisponibilidade. Devem ser publicados também os minutos totais de interrupção e de manutenção, para não ocultar o impacto real. Os percursos críticos e as dependências incluídas precisam de definição em DN-02; um health check isolado não comprova disponibilidade de negócio.

## 4. Catálogo de requisitos não funcionais

### 4.1. Desempenho, capacidade e escalabilidade

| ID | Requisito | Prioridade | Evidência mínima de aceitação |
| --- | --- | --- | --- |
| RNF-001 | A confirmação online e a interacção completa de marcação devem cumprir os limites aprovados, medidos separadamente por método. | E | Ensaio no perfil aprovado apresenta P95, erros e timeouts por método e equipamento, dentro dos limites de DN-01. |
| RNF-002 | Marcações aceites devem ficar consultáveis dentro do prazo de visibilidade aprovado. | E | Comparação de instantes de aceitação e consulta confirma a meta da secção 3.2, com relógios de medição alinhados. |
| RNF-003 | Relatórios operacionais devem cumprir a meta aprovada sem impedir marcações concorrentes. | E | Relatórios com histórico e filtros de referência cumprem o limite e as marcações mantêm os seus próprios critérios de latência e erro. |
| RNF-004 | O sistema deve suportar a volumetria aprovada e permitir crescimento de capacidade sem alteração das regras ou dos contratos de negócio. | E | Teste de carga no volume inicial e no cenário de crescimento acordado comprova capacidade; relatório identifica recursos adicionados, custo estimado e limites observados. |
| RNF-005 | Picos, reconexões e consumo excessivo de um tenant devem ser controlados para evitar saturação dos restantes. | E | Teste de sobrecarga mostra limites, filas ou rejeições explícitas; tenants dentro da sua carga contratada mantêm os objectivos acordados e não há perda silenciosa. |

### 4.2. Disponibilidade, resiliência e integridade

| ID | Requisito | Prioridade | Evidência mínima de aceitação |
| --- | --- | --- | --- |
| RNF-006 | Os percursos críticos centrais devem cumprir a disponibilidade mensal aprovada. | E | Monitorização dos percursos e relatório mensal usam a fórmula, exclusões e dependências acordadas; antes de produção, exercício de falha valida a medição, sem alegar cumprimento mensal antecipado. |
| RNF-007 | Eventos apresentados como guardados localmente devem persistir perante reinício da aplicação ou do terminal. | E | Interrupção após confirmação local e antes da sincronização preserva todos os eventos do lote; corrupção ou falta de espaço é sinalizada sem confirmação falsa. |
| RNF-008 | A operação offline deve respeitar capacidade, duração e validade das autorizações locais aprovadas. | E | Ensaio até aos limites de DN-03 comprova persistência e comportamento explícito ao excedê-los; autorização desactualizada segue contingência e não é prolongada silenciosamente. |
| RNF-009 | Reenvios, respostas perdidas e mensagens fora de ordem não devem criar efeitos de negócio duplicados. | E | Injecção destas falhas não duplica presenças, saldos, ajustes nem resultados externos; cada tentativa permanece reconciliável. |
| RNF-010 | Aprovações, correcções e fechos concorrentes devem preservar consistência e o histórico. | E | Testes concorrentes não produzem dupla decisão efectiva, ajustes parciais ou alteração de resultado fechado; conflito é devolvido ao interveniente. |
| RNF-011 | Indisponibilidade de dependências deve ter timeouts e tentativas limitados e não originar sucesso falso ou bloqueio indefinido. | E | Falhas simuladas no ERP, biometria e notificações produzem estado recuperável ou rejeição explícita; tentativas respeitam limites e não amplificam a falha. |
| RNF-012 | Eventos devem preservar o instante e a referência temporal de origem, distinguindo-os da recepção e do apuramento. | E | Ensaios com turnos nocturnos, mudança de fuso e desvio de relógio preservam origem e ordem verificável; desvios acima do limite são sinalizados. |

### 4.3. Segurança e isolamento

| ID | Requisito | Prioridade | Evidência mínima de aceitação |
| --- | --- | --- | --- |
| RNF-013 | O isolamento entre tenants deve abranger armazenamento, consultas, caches, ficheiros, filas, relatórios, exportações e tarefas automáticas. | E | Testes negativos em cada superfície não revelam nem alteram dados de outro tenant, incluindo identificadores manipulados e tarefas executadas em segundo plano. |
| RNF-014 | Autenticação e autorização devem aplicar menor privilégio e controlar o ciclo de vida de sessões, contas e credenciais de dispositivos. | E | Revogação e expiração são verificadas em novas operações centrais; acessos privilegiados seguem autenticação reforçada aprovada; terminais offline obedecem ao prazo específico de DN-03. |
| RNF-015 | Comunicações com dados pessoais, credenciais ou eventos devem ser cifradas e validar a identidade do destino. | E | Captura de tráfego não expõe conteúdo sensível; certificados inválidos são recusados; protocolos e configurações aceites constam do perfil de segurança aprovado. |
| RNF-016 | Dados sensíveis em servidores, terminais e cópias de segurança devem ser protegidos em repouso, com acesso às chaves separado do acesso corrente aos dados. | E | Inspecção de armazenamento e cópias não permite leitura directa sem autorização; exercício de rotação e recuperação de chaves segue procedimento registado. |
| RNF-017 | Segredos devem ser geridos por ambiente e ter rotação e revogação controladas. | E | Inspecção de código, artefactos, respostas e logs não encontra segredos expostos; rotação comprova que a credencial antiga deixa de autorizar acesso. |
| RNF-018 | Entradas, anexos, importações e pedidos devem ser validados e sujeitos a limites contra abuso. | E | Testes com conteúdos inválidos, tamanhos excessivos e tentativas repetidas produzem rejeição controlada, sem execução indevida, fuga de dados ou indisponibilidade fora dos limites acordados. |
| RNF-019 | A entrega deve ser avaliada quanto a vulnerabilidades segundo critérios de severidade e tratamento aprovados. | E | Revisão de código, dependências e testes de segurança produz evidências e responsáveis; não permanecem falhas classificadas como impeditivas de produção. |

### 4.4. Privacidade e qualidade biométrica

| ID | Requisito | Prioridade | Evidência mínima de aceitação |
| --- | --- | --- | --- |
| RNF-020 | A recolha e exposição de dados devem limitar-se à finalidade e aos campos aprovados para cada fluxo. | E | Revisão de ecrãs, tráfego, relatórios, telemetria e armazenamento confirma minimização; templates e imagens não aparecem em logs ou relatórios comuns e GPS não é recolhido continuamente. |
| RNF-021 | Retenção e eliminação devem abranger bases, ficheiros, caches, terminais e cópias segundo política por categoria. | E | Execução com dados de teste comprova prazos e impedimentos; destinos indisponíveis ficam pendentes, e cópias imutáveis seguem expiração controlada e reaplicação de eliminações no restauro. |
| RNF-022 | Dados de desenvolvimento e teste devem ser sintéticos ou tratados segundo autorização específica e controlos aprovados. | E | Inventário dos conjuntos de teste identifica origem e autorização aplicável; acesso e ciclo de vida são verificáveis. |
| RNF-023 | Reconhecimento e prova de vida devem cumprir limites de qualidade definidos para as condições reais de utilização. | E | Ensaio separado de falsas aceitações, falsas rejeições e ataques simulados reporta amostra, condições, método de comparação e incerteza; critérios quantitativos são aprovados em DN-05 antes do teste. |
| RNF-024 | Falhas, incerteza ou indisponibilidade biométrica não devem resultar em aceitação automática nem obrigar a recolha excessiva. | E | Casos de falha encaminham para alternativa autorizada; teste cobre iluminação, posicionamento, equipamento e condições representativas sem conservar imagens além da política. |

### 4.5. Auditoria, observabilidade e recuperação

| ID | Requisito | Prioridade | Evidência mínima de aceitação |
| --- | --- | --- | --- |
| RNF-025 | Evidências críticas devem estar protegidas contra alteração ou remoção não autorizada e permitir reconstruir a operação. | E | Amostra de correcções, aprovações, fechos e integrações contém actor, tenant, instantes, resultado e correlação; tentativas de alteração são recusadas ou detectadas pelo controlo aprovado. |
| RNF-026 | Falhas de gravação de auditoria não devem permitir operações críticas sem evidência recuperável. | E | Indisponibilidade do destino de auditoria provoca bloqueio ou persistência durável alternativa segundo política; recuperação reconcilia os eventos sem lacunas silenciosas. |
| RNF-027 | Métricas e logs devem permitir localizar erros, latência, atrasos, filas e estado de dispositivos sem expor dados sensíveis desnecessários. | E | Operador autorizado segue uma marcação de teste até integração usando correlação; consegue identificar componente com falha sem aceder a templates ou segredos. |
| RNF-028 | Alertas operacionais devem ter limiar, destinatário, prazo de detecção e procedimento de resposta definidos. | D | Falha injectada gera alerta dentro do prazo aprovado, com estado de recuperação e sem repetição descontrolada; contactos são testados no exercício. |
| RNF-029 | Cópias e restaurações devem atingir RPO e RTO por classe de serviço, incluindo validação de integridade. | E | Restauro em ambiente controlado mede perda temporal e tempo total até serviço validado, reconcilia dados e reaplica revogações e eliminações antes da retoma. |

### 4.6. Usabilidade, acessibilidade e compatibilidade

| ID | Requisito | Prioridade | Evidência mínima de aceitação |
| --- | --- | --- | --- |
| RNF-030 | A marcação deve apresentar instruções e resultados compreensíveis, distinguindo aceitação central, pendência local e falha. | E | Teste com utilizadores representativos mede conclusão sem ajuda, erros e interpretação dos estados segundo metas aprovadas; nenhuma falha é comunicada como sucesso. |
| RNF-031 | As interfaces devem permitir utilização segundo as necessidades de acessibilidade acordadas para cada canal. | D | Verificação inclui navegação por teclado no backoffice, foco visível, rótulos, leitor de ecrã, ampliação de texto e estados não dependentes apenas de cor; terminais têm alternativa operacional aplicável. |
| RNF-032 | A solução deve funcionar na matriz aprovada de Android, dispositivos, periféricos e navegadores. | E | Percursos críticos passam em cada combinação suportada; combinação incompatível é identificada e não cria registos falsamente confirmados. |
| RNF-033 | Datas, horas, idioma e formatos devem ser consistentes com a configuração e não introduzir ambiguidade no processamento. | E | Interface e exportação distinguem fuso e datas ambíguas; importações rejeitam valores cuja interpretação não corresponda ao formato contratado. |

### 4.7. Manutenção, entrega e portabilidade

| ID | Requisito | Prioridade | Evidência mínima de aceitação |
| --- | --- | --- | --- |
| RNF-034 | Configurações, regras e integrações correntes devem poder ser alteradas por interfaces autorizadas, sem edição directa da base de produção. | E | Alteração de referência é validada, versionada e auditada; uma configuração inválida não substitui a versão activa. |
| RNF-035 | Instalações, actualizações e migrações devem ser reproduzíveis e possuir estratégia de recuperação. | E | Ensaio de entrega e reversão ou correcção progressiva preserva eventos, contratos compatíveis e histórico; migração irreversível possui restauro ensaiado e procedimento explícito. |
| RNF-036 | Contratos de integração e formatos de dados devem ser documentados e versionados com política de compatibilidade. | E | Testes de contrato cobrem versão suportada, erros, reenvios e evolução de campos; alteração incompatível não é aplicada sem tratamento dos consumidores afectados. |
| RNF-037 | Dados autorizados de um tenant devem ser exportáveis num formato documentado e interpretável fora da aplicação. | D | Exportação de referência inclui campos, tipos, fuso, versões e relações necessárias à interpretação; contagens e totais reconciliam com a origem, respeitando retenção e permissões. |
| RNF-038 | Componentes e regras críticas devem ser verificáveis de forma repetível com dados de teste controlados. | E | Execução de regressão reproduz apuramentos, isolamento, concorrência e idempotência; evidência identifica versão do software, configuração e dados utilizados. |

## 5. Verificação e condições de aceitação

| Grupo de ensaios | Condições mínimas | Evidência esperada |
| --- | --- | --- |
| Carga e desempenho | Perfil da secção 3 aprovado, histórico representativo, marcações e relatórios concorrentes | Percentis, amostras, erros, timeouts, recursos e limites observados |
| Continuidade offline | Interrupção, reinício, disco cheio, reconexão em massa e autorização expirada | Reconciliação por identificador, estados de fila e comportamento nos limites |
| Concorrência e integridade | Decisões simultâneas, fecho durante correcção, evento tardio e reenvio ERP | Ausência de efeitos duplicados ou alterações silenciosas; histórico preservado |
| Segurança e isolamento | Pelo menos dois tenants, utilizadores com combinações distintas de permissões e âmbitos, e tarefas de fundo | Matriz de tentativas permitidas/negadas e evidência por superfície |
| Biometria | Métodos, equipamentos, condições ambientais e amostra previamente definidos | Métricas separadas de reconhecimento e prova de vida; limitações e incerteza |
| Recuperação | Cópia realista, perda simulada, restauro e revogações posteriores à cópia | RTO/RPO medidos, contagens, totais e validação dos acessos |
| Usabilidade e compatibilidade | Utilizadores representativos e matriz de canais/dispositivos | Taxa de conclusão, erros, barreiras de utilização e resultados por combinação |
| Entrega e interoperabilidade | Migração, consumidores suportados e falha durante actualização | Recuperação demonstrada e contratos de integração validados |

Estes ensaios estão especificados, não executados. O aceite exige parâmetros resolvidos, evidência rastreável por RNF e tratamento dos desvios impeditivos. Requisitos desejáveis adiados devem ter decisão explícita de âmbito. Excepções aceites devem indicar motivo, impacto, responsável e prazo de revisão, sem serem apresentadas como requisito cumprido.

## 6. Continuidade e classes de recuperação

| Classe | Conteúdo / dependências | RPO | RTO | Validação antes da retoma |
| --- | --- | --- | --- | --- |
| Dados centrais | Marcações aceites, pedidos, ajustes, apuramentos e fechos | A definir | A definir | Reconciliar eventos e resultados; preservar períodos fechados |
| Identidades e políticas | Contas, permissões, credenciais, configurações e regras | A definir | A definir | Aplicar revogações e confirmar versões e isolamento |
| Auditoria | Evidências de operações críticas e correlações | A definir | A definir | Verificar integridade e reconciliar persistência alternativa |
| Dados biométricos | Templates autorizados e estados do seu ciclo de vida | A definir | A definir | Reaplicar eliminações/suspensões e confirmar destinos |
| Integrações | Filas, confirmações e estado de reconciliação com ERP | A definir | A definir | Retomar sem duplicação ou perda de confirmações |
| Terminal local | Eventos ainda não confirmados centralmente | A definir para perda física | A definir | Recuperar fila disponível e reconciliar com o servidor |

A persistência perante reinício não equivale a recuperação após perda física do terminal. A tolerância à perda de eventos ainda não sincronizados deve ser decidida separadamente. Eventos confirmados no servidor também estão sujeitos ao RPO aprovado para desastre; não se presume perda zero sem arquitectura e ensaio que a sustentem.

O plano de continuidade deve definir ordem de recuperação, responsáveis, dependências, acesso às chaves e procedimento de contingência durante a indisponibilidade.

## 7. Rastreabilidade

Os códigos BR-NF referem-se ao BRD detalhado. A associação indica cobertura documental, não conformidade comprovada.

| Origem | Requisitos derivados | Funções relacionadas |
| --- | --- | --- |
| BR-NF-001 — Disponibilidade | RNF-006, RNF-011 | RF-021, RF-063 |
| BR-NF-002 — Desempenho | RNF-001 a RNF-003 | RF-021, RF-022, RF-051, RF-052 |
| BR-NF-003 — Escalabilidade | RNF-004, RNF-005 | RF-025, RF-026, RF-052, RF-059 |
| BR-NF-004 — Segurança | RNF-014 a RNF-019 | RF-006 a RF-008, RF-019, RF-056 |
| BR-NF-005 — Privacidade | RNF-020 a RNF-022 | RF-036, RF-037, RF-061, RF-062 |
| BR-NF-006 — Isolamento | RNF-013 | RF-002, RF-007, RF-053, RF-055 |
| BR-NF-007 — Auditabilidade | RNF-025, RNF-026 | RF-047, RF-049, RF-050, RF-060 |
| BR-NF-008 — Resiliência | RNF-007 a RNF-012 | RF-024 a RF-026, RF-043, RF-047, RF-059 |
| BR-NF-009 — Recuperação | RNF-029 | RF-065 |
| BR-NF-010 — Compatibilidade | RNF-032, RNF-033 | RF-003, RF-020, RF-028 a RF-031 |
| BR-NF-011 — Usabilidade | RNF-030 | RF-022, RF-027, RF-051 |
| BR-NF-012 — Acessibilidade | RNF-031 | RF-022, RF-027, RF-051 |
| BR-NF-013 — Manutenibilidade | RNF-034, RNF-035, RNF-038 | RF-016 a RF-020, RF-056 |
| BR-NF-014 — Observabilidade | RNF-027, RNF-028 | RF-060, RF-063, RF-064 |
| BR-NF-015 — Portabilidade | RNF-036, RNF-037 | RF-053, RF-056 a RF-059 |
| BRD resumido BR-04 e BR-15; BRD detalhado secções 7.5 e 12 | RNF-023, RNF-024 | RF-027, RF-032 a RF-037 |

## 8. Decisões pendentes

| ID | Decisão | Responsável proposto | Dependências |
| --- | --- | --- | --- |
| DN-01 | Aprovar volumetria, ambiente de referência, duração dos ensaios, latências e limite de erros | Negócio, RH e equipa técnica | RNF-001 a RNF-005 |
| DN-02 | Confirmar disponibilidade, percursos críticos, dependências, manutenção e janela de medição | Direcção e operação | RNF-006, RNF-011 |
| DN-03 | Definir autonomia offline, capacidade local, validade de autorizações, limites de relógio e prazo de sincronização | RH e equipa técnica | RNF-007 a RNF-012; DF-03 dos RF |
| DN-04 | Aprovar perfil de segurança, sessões, autenticação reforçada, chaves e critérios de vulnerabilidade | Segurança e equipa técnica | RNF-013 a RNF-019 |
| DN-05 | Aprovar componente biométrico, modo de comparação, amostra, métricas e limiares de aceitação | Negócio, equipa técnica e responsável de dados | RNF-023, RNF-024; DF-04 dos RF |
| DN-06 | Definir finalidades, campos, retenção, impedimentos e tratamento de cópias/restauros | Responsável de dados e operação | RNF-020 a RNF-022; DF-08 dos RF |
| DN-07 | Aprovar RPO/RTO por classe, contingência, frequência de exercícios e tolerância à perda física de terminal | Direcção e operação | RNF-029; secção 6 |
| DN-08 | Definir matriz de compatibilidade, critérios de usabilidade e acessibilidade por canal | Produto, RH e equipa técnica | RNF-030 a RNF-033 |
| DN-09 | Definir política de auditoria em falha, métricas, limiares e prazos de alerta | Segurança e operação | RNF-025 a RNF-028; DF-09 dos RF |
| DN-10 | Aprovar compatibilidade de contratos, estratégia de entrega e formato de portabilidade | Equipa técnica, equipa ERP e negócio | RNF-034 a RNF-038 |

## 9. Aprovação e alterações

| Papel | Âmbito de validação | Estado |
| --- | --- | --- |
| Responsável de negócio | Prioridades, metas, capacidade e impacto operacional | Pendente |
| RH | Cenários de uso, integridade dos apuramentos e contingência | Pendente |
| Responsável técnico | Viabilidade, medição, integração e evidências | Pendente |
| Operação / segurança | Serviço, acessos, observabilidade e recuperação | Pendente |
| Responsável de dados | Minimização, biometria e ciclo de vida dos dados | Pendente |

Cada aprovação deve indicar nome, versão e data. Alterações posteriores devem identificar RNFs afectados, motivo, impacto, aprovador e evidências que precisam de ser repetidas.

## 10. Referências e próximos documentos

- [Índice da documentação](README.MD).
- [BRD resumido](01-BRD.md), especialmente objectivos, qualidade e continuidade.
- [BRD detalhado](BRD_Sistema_Gestao_Assiduidade.md), especialmente indicadores propostos e BR-NF-001 a BR-NF-015.
- [Requisitos Funcionais](02-Requisitos-Funcionais.md), incluindo estados, cenários de aceitação e decisões DF-01 a DF-09.

O Plano de Testes deverá transformar estes critérios em ensaios executáveis. Arquitectura, Segurança, Biometria, SLA, Deployment e Plano de Continuidade deverão detalhar os mecanismos e parâmetros aprovados, mantendo os identificadores RNF. Este documento não declara certificação nem conformidade com uma norma externa.
