# Segurança e Protecção de Dados — Sistema de Gestão de Assiduidade

## 1. Controlo do documento

| Campo | Valor |
| --- | --- |
| Referência | SEG-ASS-001 |
| Versão | 0.3 |
| Data | 25/09/2026 |
| Estado | Rascunho técnico para validação |
| Responsáveis | Segurança e responsável de dados, com validação da equipa técnica e operação — nomes a designar |
| Base documental | BR-15, BR-F-100 a BR-F-105, BR-NF-004, BR-NF-005; RF-060 a RF-062, RF-065; RN-046 a RN-048; RNF-013 a RNF-022, RNF-029; [Arquitectura](07-Arquitectura-do-Sistema.md) §9 |

| Versão | Data | Alteração |
| --- | --- | --- |
| 0.1 | 25/09/2026 | Controlos, protecção de dados e ameaças em resumo |
| 0.2 | 25/09/2026 | Versão detalhada: classificação da informação, controlos SEG, modelo de ameaças, protecção de dados pessoais, vulnerabilidades, restauro seguro, incidentes e situação actual |
| 0.3 | 25/09/2026 | Terminologia de autorização alinhada com permissões granulares `módulo:acção` e âmbito ([Requisitos Funcionais §3](02-Requisitos-Funcionais.md)) |

## 2. Objectivo, âmbito e convenções

Este documento especifica os controlos de segurança e de protecção de dados da solução: plataforma, aplicação Android, terminais, integrações, cópias e ambientes não produtivos. Biometria tem requisitos próprios no [documento 12](12-Reconhecimento-Facial-e-Liveness.md); isolamento entre tenants no [documento 13](13-Gestao-Multi-Tenant.md); auditoria no [documento 16](16-Auditoria-e-Logs.md).

Convenções: **CLS-xx** classes de informação; **SEG-xx** controlos; **AM-xx** ameaças. Este documento não constitui avaliação jurídica.

## 3. Classificação da informação

| ID | Classe | Exemplos | Regras de tratamento |
| --- | --- | --- | --- |
| CLS-1 | Pública | Documentação de APIs para parceiros | Sem restrição de confidencialidade; integridade controlada |
| CLS-2 | Interna | Configurações sem dados pessoais, métricas agregadas | Acesso autenticado |
| CLS-3 | Pessoal | Cadastro, marcações, apuramentos, pedidos, localização | Acesso por âmbito, cifragem em trânsito e em repouso, minimização em logs e exportações |
| CLS-4 | Pessoal sensível | Templates e dados biométricos; anexos de ausência que revelem saúde ou situação familiar | Armazenamento separado ou cifragem com chave própria, acesso restrito a permissões específicas, auditoria de acesso, exclusão de relatórios comuns |
| CLS-5 | Segredos | Credenciais de dispositivo e integração, chaves, tokens | Apenas em CNT-11 ou armazenamento protegido do dispositivo; nunca em logs, código ou artefactos |

Anexos de pedidos de ausência são classificados como CLS-4 por defeito, porque podem conter informação de saúde; o acesso limita-se ao requerente, aos decisores do pedido e ao RH autorizado.

## 4. Controlos técnicos

### 4.1. Comunicação e armazenamento

| ID | Controlo | Prioridade | Critério de aceitação | Origem |
| --- | --- | --- | --- | --- |
| SEG-01 | TLS em todas as comunicações externas e internas entre contentores, com versões e cifras do perfil aprovado | E | Varrimento não encontra protocolos fracos; HTTP recusado | RNF-015 |
| SEG-02 | Validação de certificado em clientes, terminais e integrações | E | Certificado inválido é recusado | RNF-015 |
| SEG-03 | Cifragem em repouso de CNT-06, CNT-08, CNT-09, CNT-10 e cópias, com chaves geridas em CNT-11 | E | Leitura directa do armazenamento não revela conteúdo | RNF-016 |
| SEG-04 | Chaves separadas por classe (CLS-4 com chave própria) e, quando decidido, por tenant | E | Revogação de uma chave não afecta outras classes | DT-10 |
| SEG-05 | Rotação de chaves e de segredos com procedimento ensaiado | E | Exercício de rotação sem perda de acesso aos dados | RNF-016, RNF-017 |

### 4.2. Identidade e acesso

| ID | Controlo | Prioridade | Critério de aceitação | Origem |
| --- | --- | --- | --- | --- |
| SEG-06 | Autenticação, sessões e segundo factor conforme [documento 14 §8](14-Gestao-de-Utilizadores-e-Perfis.md) | E | UTL-05 a UTL-10 verificados | RNF-014 |
| SEG-07 | Autorização por permissão granular `módulo:acção`, âmbito e objecto em cada operação ([Requisitos Funcionais §3](02-Requisitos-Funcionais.md), [documento 15](15-Matriz-de-Permissoes-e-Acessos.md)) | E | Matriz de testes negativos aprovada | RF-002, RF-007 |
| SEG-08 | Credencial individual por dispositivo, revogável e com rotação | E | DSP-28 verificado | DT-05 |
| SEG-09 | Credenciais de integração por tenant e ambiente, com menor privilégio | E | Credencial de validação não funciona em produção | RF-056 |

### 4.3. Protecção da API e da aplicação

| ID | Controlo | Prioridade | Critério de aceitação | Origem |
| --- | --- | --- | --- | --- |
| SEG-10 | Validação de esquema e de tipos em todas as entradas, com rejeição de campos desconhecidos em comandos | E | Testes com conteúdos inválidos produzem `PEDIDO_INVALIDO` | RNF-018 |
| SEG-11 | Limites de frequência, de tamanho e de lote por credencial e tenant | E | TEN-18 verificado | RNF-005, RNF-018 |
| SEG-12 | Protecção contra repetição por idempotência e validade temporal das credenciais | E | Reenvio de pedido antigo não produz novo efeito | MEC-02 |
| SEG-13 | Anexos: lista de tipos permitidos, verificação do conteúdo real, limite de tamanho, análise de malware e descarga por URL assinada de curta duração | E | Ficheiro executável disfarçado é recusado | RNF-018 |
| SEG-14 | Consultas parametrizadas e codificação de saída; nenhum dado de utilizador interpretado como código | E | Testes de injecção sem sucesso | RNF-019 |
| SEG-15 | Cabeçalhos de segurança no backoffice e protecção contra pedidos forjados entre sítios | E | Varrimento de configuração sem falhas altas | RNF-019 |
| SEG-16 | Respostas de erro sem detalhes internos nem dados de terceiros | E | MEC-12 verificado | RNF-018 |

## 5. Modelo de ameaças

| ID | Ameaça | Alvo | Controlos | Verificação |
| --- | --- | --- | --- | --- |
| AM-01 | Acesso a dados de outro tenant | Todas as superfícies | TEN-01 a TEN-07, DT-04 | TEN §10, CA-01 |
| AM-02 | Roubo ou clonagem de credencial de dispositivo | Terminal | SEG-08, DSP-27, DSP-28, monitorização de origem | Credencial copiada para outro equipamento é detectada ou recusada |
| AM-03 | Marcação por outra pessoa (fraude de ponto) | Identificação | Prova de vida (BIO-11), credenciais revogáveis, localização quando aprovada | Ensaio de §11 do documento 12 |
| AM-04 | Adulteração do relógio do terminal | Instante de origem | MEC-04, DSP-18 | Evento com relógio alterado fica pendente |
| AM-05 | Repetição de pedidos ou lotes | API | SEG-12, MEC-02 | CA-02 |
| AM-06 | Alteração indevida de registos por utilizador interno | Eventos, resultados | PD-01, ajustes com decisão, SDF-02 a SDF-04, auditoria | Tentativa de edição directa recusada |
| AM-07 | Abuso de acesso de suporte | Dados de negócio | TEN-14 a TEN-17, EVA-05, EVA-26 | Acesso fora da autorização recusado |
| AM-08 | Exportação excessiva de dados pessoais | Relatórios | Finalidade e campos por exportação, EVA-21, PERM-26 restrita | Exportação sem finalidade recusada |
| AM-09 | Fuga de dados biométricos | CNT-09, terminais | BIO-30 a BIO-32, SEG-03, SEG-04 | Inspecção de armazenamento e logs |
| AM-10 | Integração falsificada ou mensagens duplicadas | CMP-12 | SEG-09, idempotência, reconciliação | CA-07 |
| AM-11 | Anexo malicioso | CNT-08 | SEG-13 | Teste com ficheiros maliciosos conhecidos |
| AM-12 | Restauro que reactiva dados eliminados ou acessos revogados | Cópias | §8 | EX-10 |
| AM-13 | Dependência de terceiros vulnerável | Código | §7 | Análise de dependências no CI |
| AM-14 | Perda ou roubo de terminal com fila local | Terminal | DSP-03, DSP-30, revogação remota | Equipamento roubado não permite leitura da fila |

Cada ameaça tem responsável e teste no [Plano de Testes](21-Plano-de-Testes.md). O modelo é revisto a cada mudança de arquitectura e após cada incidente.

## 6. Protecção de dados pessoais

### 6.1. Enquadramento

A jurisdição principal e o enquadramento legal aplicável (legislação laboral e de protecção de dados pessoais em vigor na jurisdição de operação) devem ser identificados pelo responsável de dados antes do piloto (BRD detalhado §17, questão 1). As referências a normas europeias no BRD detalhado servem como boa prática, não como enquadramento aplicável presumido. Até essa identificação, aplicam-se os princípios de §6.2 como requisito de desenho.

### 6.2. Princípios aplicados

| Princípio | Aplicação |
| --- | --- |
| Finalidade | Dados usados apenas para gestão de assiduidade e processos associados; biometria só para identificação na marcação (BIO-34) |
| Minimização | Localização só no instante da marcação (DSP-19); sem imagens por defeito (BIO-31); exportações por finalidade (RN-046) |
| Exactidão | Correcções por pedido e decisão, preservando o original (RF-046, RF-047) |
| Limitação da conservação | Categorias CR-01 a CR-07 e CMP-13 |
| Integridade e confidencialidade | Controlos de §4 |
| Responsabilidade | Auditoria (documento 16) e registo das actividades de tratamento |

### 6.3. Requisitos

| ID | Requisito | Prioridade | Critério de aceitação | Origem |
| --- | --- | --- | --- | --- |
| SEG-17 | Manter registo das actividades de tratamento: finalidade, categorias de dados e titulares, destinatários, prazos, medidas de segurança | E | Registo aprovado pelo responsável de dados | BR-15 |
| SEG-18 | Realizar avaliação de impacto antes de activar biometria e localização em produção | E | Avaliação aprovada e medidas incorporadas | BR-F-040, DF-04 |
| SEG-19 | Informar os titulares no momento da recolha (aplicação, terminal, enrollment) sobre finalidade, base, prazos e direitos | E | Aviso visível e versionado; versão aceite fica registada quando aplicável | RF-061 |
| SEG-20 | Tratar pedidos dos titulares — acesso, rectificação, limitação e eliminação — por quem tenha `assiduidade:gerir_retencao`, com prazos definidos | E | Pedido de acesso produz exportação dos dados próprios; eliminação respeita impedimentos de retenção e auditoria | RF-062, RN-047 |
| SEG-21 | Contratar subcontratantes (fornecedor biométrico, alojamento, notificações) com cláusulas de protecção de dados, localização e eliminação | E | Contratos aprovados antes da utilização | BIO-35 |
| SEG-22 | Não usar dados de assiduidade para finalidades não aprovadas (avaliação de desempenho, vigilância contínua) sem nova decisão | E | Finalidades novas exigem revisão de SEG-17 e SEG-18 | BRD §4.2 |

## 7. Gestão de vulnerabilidades

| ID | Controlo | Prioridade | Critério de aceitação | Origem |
| --- | --- | --- | --- | --- |
| SEG-23 | Análise estática, análise de dependências e de segredos em cada alteração, no pipeline | E | Pipeline falha com vulnerabilidade de severidade impeditiva | RNF-019 |
| SEG-24 | Teste de intrusão independente antes do piloto e antes de cada alteração arquitectural relevante | E | Relatório sem falhas impeditivas abertas | RNF-019 |
| SEG-25 | Classificação de severidade, prazos de correcção e aceitação formal de riscos residuais | E | Registo de vulnerabilidades com responsável e prazo | RNF-019 |
| SEG-26 | Actualizações de segurança do sistema dos terminais e da aplicação Android | E | Terminais fora da versão mínima são sinalizados (documento 11 §12) | DSP-01 |

## 8. Cópias e restauro seguros

| ID | Controlo | Prioridade | Critério de aceitação | Origem |
| --- | --- | --- | --- | --- |
| SEG-27 | Cópias cifradas, em localização separada, com acesso distinto do de produção | E | Conta de produção não apaga nem altera cópias | RNF-016, RNF-029 |
| SEG-28 | Registo das decisões posteriores a cada cópia que têm de ser reaplicadas: revogações de acesso e de dispositivos, suspensões e eliminações biométricas, eliminações de retenção | E | Lista de reaplicação disponível para qualquer ponto de recuperação | RN-048 |
| SEG-29 | No restauro: congelar operações sensíveis, restaurar, reaplicar SEG-28, reconciliar eventos e integrações, validar isolamento e só então retomar | E | Exercício de restauro não reactiva dados eliminados nem acessos revogados | RN-048, EX-10, UC-21 |
| SEG-30 | Exercícios de restauro periódicos com medição de RPO e RTO por classe | E | Relatório do exercício com tempos e divergências | RNF-029, DN-07 |

## 9. Resposta a incidentes

Incidentes de segurança e de dados seguem o [documento 31](31-Gestao-de-Incidentes.md). Em incidente com dados pessoais, o responsável de dados avalia a obrigação e o prazo de notificação a autoridades e titulares segundo o enquadramento de §6.1. Evidências (logs, auditoria, cópias) são preservadas antes de qualquer correcção; credenciais comprometidas são revogadas de imediato (TEN-13, SEG-08).

## 10. Ambientes não produtivos

| ID | Controlo | Prioridade | Critério de aceitação | Origem |
| --- | --- | --- | --- | --- |
| SEG-31 | Dados sintéticos por defeito; dados reais só com autorização específica, anonimização e prazo | E | Inventário de conjuntos de teste com origem e autorização | RNF-022 |
| SEG-32 | Nenhum dado biométrico real fora de produção, salvo ensaio biométrico autorizado em ambiente controlado | E | Varrimento de ambientes não encontra templates reais | RNF-022, BIO-31 |
| SEG-33 | Credenciais, chaves e integrações distintas por ambiente | E | Credencial de um ambiente não funciona noutro | RNF-017 |

## 11. Situação actual

Observado em 25/09/2026 no Nexora ERP e na aplicação Android, a tratar antes do piloto:

| Observação | Controlo afectado |
| --- | --- |
| Aplicação Android com `usesCleartextTraffic="true"` | SEG-01, DSP-29 |
| Dispositivos autenticados por chave de API | SEG-08, DT-05 |
| `foto_url` em `rh.eventos_assiduidade` | BIO-31, §6.2 |
| Remoção física de presenças por endpoint | PD-01, AM-06 |
| Consentimentos registáveis a partir de dispositivos | SEG-19, BIO-01 |

## 12. Rastreabilidade

| Elementos | RF | RN / RNF |
| --- | --- | --- |
| CLS-1 a CLS-5 | RF-037, RF-053 | RN-046; RNF-020 |
| SEG-01 a SEG-05 | — | RNF-015 a RNF-017 |
| SEG-06 a SEG-09 | RF-002, RF-006 a RF-008, RF-019, RF-056 | RNF-013, RNF-014 |
| SEG-10 a SEG-16 | — | RNF-018, RNF-019 |
| AM-01 a AM-14 | RF-002, RF-021, RF-036, RF-053 | RNF-013 a RNF-019 |
| SEG-17 a SEG-22 | RF-061, RF-062 | RN-047; RNF-020, RNF-021 |
| SEG-23 a SEG-26 | — | RNF-019 |
| SEG-27 a SEG-30 | RF-065 | RN-048; RNF-029 |
| SEG-31 a SEG-33 | — | RNF-017, RNF-022 |

## 13. Decisões pendentes

| Decisão | Efeito |
| --- | --- |
| DN-04 | Perfil de segurança: protocolos, sessões, segundo factor, severidades |
| DT-05, DT-10 | Credenciais de dispositivo e gestão de chaves |
| DF-08, DN-06 | Retenção, direitos dos titulares e tratamento de cópias |
| DN-07 | RPO, RTO e frequência dos exercícios |
| BRD detalhado §17, questão 1 | Jurisdição e enquadramento legal |

## 14. Aprovação e referências

Segurança valida §3 a §5, §7, §8 e §10; o responsável de dados valida §3, §6 e §9; a operação valida §8. Cada aprovação deve identificar nome, versão e data. Estado de aprovação desta versão: **pendente**.

- [Índice da documentação](README.MD).
- [Reconhecimento Facial e Liveness](12-Reconhecimento-Facial-e-Liveness.md), [Gestão Multi-Tenant](13-Gestao-Multi-Tenant.md), [Auditoria e Logs](16-Auditoria-e-Logs.md), [Gestão de Incidentes](31-Gestao-de-Incidentes.md).
