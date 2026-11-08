# Especificação de Dispositivos/Terminais — Sistema de Gestão de Assiduidade

## 1. Controlo do documento

| Campo | Valor |
| --- | --- |
| Referência | DISP-ASS-001 |
| Versão | 0.3 |
| Data | 25/09/2026 |
| Estado | Rascunho técnico para validação |
| Responsáveis | Equipa técnica e operação, com validação de RH, segurança e responsável de dados — nomes a designar |
| Base documental | RF-019 a RF-031, RNF-007, RNF-008, RNF-030, RNF-032; DG-CP-02, DG-ES-01, DG-ES-08; [TDD](08-Documento-de-Design-Tecnico-TDD.md) |

| Versão | Data | Alteração |
| --- | --- | --- |
| 0.1 | 25/09/2026 | Terminal, ciclo de vida, fila offline e métodos em resumo |
| 0.2 | 25/09/2026 | Versão detalhada: perfis de dispositivo, requisitos DSP, fila offline, métodos, configuração, segurança, monitorização e situação actual |
| 0.3 | 25/09/2026 | Terminologia de autorização alinhada com permissões granulares `módulo:acção` e âmbito ([Requisitos Funcionais §3](02-Requisitos-Funcionais.md)) |

## 2. Objectivo, âmbito e convenções

Este documento especifica os equipamentos e a aplicação Android usados para marcar ponto e para enrollment: requisitos de hardware e sistema, ciclo de vida, fila offline, métodos de identificação, configuração distribuída, segurança local e monitorização. A arquitectura interna da aplicação segue DG-CP-02 do [documento 06](06-Diagramas-UML.md).

Convenções: **DSP-xx** identifica requisitos deste documento, com prioridade herdada do RF de origem (E, D, O). Modelos, versões mínimas e capacidades concretas são decisões de compra (DF-01, DN-08) e aparecem como parâmetros.

## 3. Perfis de dispositivo

| Perfil | Descrição | Credencial | Estado |
| --- | --- | --- | --- |
| Terminal dedicado | Equipamento Android fixo, em modo kiosk, partilhado por colaboradores de um local | Credencial de dispositivo (DT-05) | Previsto (CNT-02) |
| Telemóvel do colaborador | Aplicação instalada no equipamento pessoal ou atribuído ao colaborador | Sessão do utilizador | Condicionado a DF-01 e DU-09 (CNT-03) |
| Estação de enrollment | Equipamento usado por um utilizador autenticado com `assiduidade:gerir_biometria` | Sessão do utilizador | Previsto (UC-04) |
| Leitor de terceiros | Equipamento de fabricante (ex.: leitores de impressão digital) integrado por adaptador | Credencial de dispositivo | Condicionado a DF-01 |

## 4. Ciclo de vida do dispositivo

Estados de base, conforme DG-ES-08: `registado`, `activo`, `revogado`. Enquanto activo, a configuração pode estar `aplicada`, `pendente` ou `falhada` (subestados de DG-ES-08).

| Estado | Entrada | Efeito |
| --- | --- | --- |
| `registado` | EP-023, com tenant e local | Pode receber credencial; não submete marcações aceites |
| `activo` | EP-024 após credencial e métodos habilitados | Submete marcações e recebe configuração |
| `revogado` | EP-024, com motivo | Novas submissões recusadas com `DISPOSITIVO_REVOGADO`; eventos capturados antes seguem RN-015 |

Propostas adicionais, a validar em RF §6 (DU-07):

- `suspenso` — bloqueio temporário reversível, por exemplo durante manutenção ou suspeita de adulteração;
- `retirado` — fim de vida do equipamento, após confirmação de que a fila local está vazia e os dados locais foram eliminados.

Provisionamento: (1) registo no local; (2) instalação da aplicação em modo gerido; (3) emissão da credencial por canal seguro, associada ao identificador do equipamento; (4) obtenção da configuração (EP-027) e confirmação (EP-029); (5) teste de marcação; (6) activação.

## 5. Requisitos de equipamento e sistema

| ID | Requisito | Prioridade | Critério de aceitação | Origem |
| --- | --- | --- | --- | --- |
| DSP-01 | Versão de Android suportada pelo fabricante com actualizações de segurança, igual ou superior ao mínimo aprovado | E | Equipamento consta da matriz de compatibilidade (DN-08) e recebe patches | RNF-032 |
| DSP-02 | Câmara frontal com resolução, focagem e desempenho em baixa luz adequados ao componente biométrico | E | Ensaio biométrico nas condições reais do local aprova o modelo | RF-034, RNF-023 |
| DSP-03 | Armazenamento persistente com cifragem por chave protegida pelo sistema (Android Keystore ou equivalente em hardware) | E | Leitura directa do armazenamento não revela eventos, credenciais ou templates | RNF-016 |
| DSP-04 | Capacidade livre para a fila offline aprovada, com margem | E | Ensaio com o volume de DN-03 sem falha de gravação | RNF-008 |
| DSP-05 | Relógio sincronizável e verificável | E | Desvio medido na sincronização é registado; desvio acima do limite é sinalizado | RN-013 |
| DSP-06 | Conectividade Wi-Fi ou rede móvel conforme o local | E | Terminal mantém operação offline durante falhas de rede | RF-025 |
| DSP-07 | Alimentação contínua e, para terminais fixos, tolerância a cortes de energia | E | Reinício após corte preserva a fila (RNF-007) e retoma em modo kiosk | RNF-007 |
| DSP-08 | Leitor NFC nos terminais onde o método for seleccionado | D | Leitura de credenciais aprovadas no ensaio | RF-029 |
| DSP-09 | Leitor de impressão digital aprovado onde o método for seleccionado | D | Integração com o componente aprovado e ensaio de qualidade | RF-030 |
| DSP-10 | Receptor de localização onde a política o exigir | D | Precisão reportada com cada leitura | RF-031 |

## 6. Fila offline

### 6.1. Estrutura de cada item

| Campo | Descrição |
| --- | --- |
| `evento_uuid` | Gerado na captura; nunca regenerado (MEC-03) |
| Corpo do evento | Conteúdo de EP-031 |
| `hash_conteudo` | Hash canónico, para verificação de integridade local |
| `estado_local` | `pendente`, `enviado`, `confirmado`, `pendente_reenvio` (DG-ES-01) |
| `tentativas`, `ultima_tentativa_em` | Controlo de reenvio com backoff |
| `resultado_central` | Estado e motivo devolvidos, quando confirmado |

### 6.2. Regras

| ID | Requisito | Prioridade | Critério de aceitação | Origem |
| --- | --- | --- | --- | --- |
| DSP-11 | Gravar o evento de forma transaccional antes de apresentar "guardado localmente" | E | Corte de energia após a mensagem não perde o evento; falha de gravação não mostra sucesso | RF-022, RNF-007 |
| DSP-12 | Manter a fila cifrada e persistente após reinício da aplicação ou do equipamento | E | Reinício preserva todos os itens pendentes | RF-025 |
| DSP-13 | Enviar por lotes (EP-032), pela ordem de captura, e reconciliar por item | E | Resposta perdida não duplica eventos; itens sem resposta permanecem para reenvio | RF-026, RN-010 |
| DSP-14 | Retirar da fila todos os itens com resultado individual central, **incluindo rejeitados e pendentes de análise**, e manter só os que não têm resultado ou tiveram erro técnico | E | Após sincronização, a fila contém apenas itens por confirmar; pendências passam a ser tratadas no backoffice | RN-014, DG-ES-01 |
| DSP-15 | Conservar localmente o último resultado de cada item confirmado pelo prazo necessário a consulta no terminal, sem dados sensíveis | D | O colaborador pode confirmar a marcação recente | RF-022 |
| DSP-16 | Respeitar a capacidade máxima e a validade da autorização offline | E | Ao atingir limites, o terminal mostra falha explícita e encaminha para contingência; nenhum item é descartado silenciosamente | RNF-008, DF-03 |
| DSP-17 | Detectar e sinalizar corrupção de itens | E | Item com hash inválido é assinalado à operação e não é enviado como válido | RNF-007 |
| DSP-18 | Trocar referência temporal com o servidor em cada ligação e registar o desvio | E | `desvio_relogio_ms` acompanha os eventos; desvio acima do limite gera pendência central | MEC-04, RN-013 |

A correcção face à versão 0.1 é intencional: manter conflitos e falhas de negócio na fila impediria o esvaziamento e contraria RN-014. Os conflitos passam a ser tratados centralmente (EP-035).

## 7. Métodos de identificação

| Método | Requisitos no terminal | Prioridade | Dados tratados | Origem |
| --- | --- | --- | --- | --- |
| Facial | DSP-02; prova de vida; componente aprovado | E | Imagem transitória para comparação; nunca conservada por defeito | RF-032 a RF-035, [12](12-Reconhecimento-Facial-e-Liveness.md) |
| Impressão digital | DSP-09 | D | Amostra transitória; template conforme [12 §8](12-Reconhecimento-Facial-e-Liveness.md) | RF-030 |
| QR Code | Câmara; validação de assinatura e validade do código | D | Código da credencial, sem dados pessoais legíveis | RF-028 |
| NFC | DSP-08 | D | Identificador da credencial | RF-029 |
| PIN | Teclado no ecrã com protecção contra observação | Condicionado a DF-01 | Segredo verificado sem armazenamento em claro | DF-01 |
| Assistido | Operador autenticado no backoffice | E | Motivo e identidade do operador | RF-027 |

**Localização é contexto, não método.** A localização acompanha a marcação quando a política o exige (RF-031, DG-CL-02) e não identifica o colaborador. O [BRD resumido](01-BRD.md) refere "marcação com localização" como método alternativo; essa formulação deve ser alinhada na resolução de DF-01. Regras de localização:

| ID | Requisito | Prioridade | Critério de aceitação | Origem |
| --- | --- | --- | --- | --- |
| DSP-19 | Recolher localização apenas no instante da marcação, com precisão | D | Nenhuma recolha em segundo plano; permissão pedida só quando a política o exige | RF-031, RNF-020 |
| DSP-20 | Validar a área configurada e enviar o resultado com a leitura | D | Fora da área segue a política: rejeição ou análise (`LOCALIZACAO_FORA_DA_AREA`) | RF-031 |

| ID | Requisito | Prioridade | Critério de aceitação | Origem |
| --- | --- | --- | --- | --- |
| DSP-21 | Oferecer método alternativo autorizado quando o primário falhar, sem concluir falta | E | Falha facial repetida (limite de PN-11) apresenta alternativa ou pedido assistido | RF-027, RN-044 |
| DSP-22 | Registar tentativas falhadas (EP-036) sem imagens nem pontuações | E | Tentativas consultáveis pela operação; nenhuma imagem em disco | RF-037 |

## 8. Configuração distribuída e propagação

| ID | Requisito | Prioridade | Critério de aceitação | Origem |
| --- | --- | --- | --- | --- |
| DSP-23 | Obter a configuração versionada (EP-027) e aplicá-la de forma atómica | E | Falha a meio mantém a versão anterior e reporta `falhada` | RF-020 |
| DSP-24 | Confirmar a versão aplicada (EP-029) e mostrá-la no ecrã de manutenção | E | Backoffice mostra a versão confirmada por terminal | RF-020, UC-11 |
| DSP-25 | Obter e aplicar propagações pendentes (EP-028): suspensão, eliminação de templates e revogações | E | Após aplicação, o template suspenso não é usado; confirmação enviada | RF-036, MEC-11 |
| DSP-26 | Aplicar a validade offline das autorizações e dos templates distribuídos | E | Após o prazo sem sincronização, métodos dependentes ficam indisponíveis e o terminal mostra contingência | DF-03, RN-045 |

A configuração contém: métodos activos por local, área de localização, limites da fila, validade offline, versão mínima da aplicação, mensagens e, quando DF-04 o aprovar, os templates distribuídos com a respectiva versão.

## 9. Segurança local

| ID | Requisito | Prioridade | Critério de aceitação | Origem |
| --- | --- | --- | --- | --- |
| DSP-27 | Modo kiosk em terminais dedicados, com acesso de manutenção separado e autenticado | E | Colaborador não sai da aplicação nem acede a definições | FC-02 |
| DSP-28 | Credencial individual guardada no armazenamento protegido do sistema; revogação remota efectiva na ligação seguinte | E | Credencial não é extraível por cópia de ficheiros; após revogação, submissões são recusadas | DT-05, RNF-014 |
| DSP-29 | Comunicação só por HTTPS com validação de certificado; tráfego em claro proibido | E | Configuração de rede da aplicação recusa HTTP e certificados inválidos | RNF-015 |
| DSP-30 | Cópia de segurança do sistema e extracção de dados da aplicação desactivadas | E | Dados locais não aparecem em cópias do equipamento | RNF-016, RNF-021 |
| DSP-31 | Detecção de equipamento comprometido ou modificado, conforme perfil aprovado | D | Equipamento sinalizado é reportado à operação | DN-04 |
| DSP-32 | Logs locais sem dados pessoais, imagens, templates ou segredos | E | Inspecção dos logs não encontra estes dados | RNF-020, RNF-027 |
| DSP-33 | Eliminação dos dados locais ao revogar ou retirar o dispositivo, após reconciliação da fila | E | Estado final confirma fila vazia e armazenamento limpo | RF-062 |

## 10. Experiência no terminal

O terminal distingue sempre quatro resultados: **aceite centralmente**, **guardado localmente e pendente de sincronização**, **registado com pendência ou rejeitado** (com instrução ao colaborador) e **falha sem registo**. Nenhuma falha é comunicada como sucesso (RNF-030). As mensagens não revelam dados de terceiros nem detalhes biométricos. Ecrãs e textos estão no [documento 20](20-Prototipos-UI-UX.md).

## 11. Monitorização

O terminal reporta periodicamente (EP-030): versão da aplicação e da configuração, instante da última sincronização, tamanho da fila pendente, idade do item mais antigo, espaço livre, desvio de relógio, estado dos periféricos e nível de bateria quando aplicável. A operação vê terminais sem comunicação, com fila a crescer ou com configuração pendente (RF-063, RF-064).

## 12. Actualização da aplicação

Actualizações são distribuídas por canal gerido, com activação faseada por tenant ou local e versão mínima publicada na configuração. Uma actualização nunca apaga a fila local: a migração do formato local é testada com filas cheias antes da distribuição (RNF-035). Terminais abaixo da versão mínima mantêm a última configuração compatível e são sinalizados.

## 13. Situação actual

Situação observada em 25/09/2026, a reconciliar (DT-01):

| Elemento | Observado | Lacuna |
| --- | --- | --- |
| Aplicação Android ([nexora_assiduidade](../nexora_assiduidade/README.md)) | Kotlin, SDK mínimo 24, alvo 36; permissões de câmara, localização e NFC; Security Crypto | `usesCleartextTraffic="true"` contraria DSP-29; confirmar versão mínima face a DSP-01 |
| Autenticação de dispositivos | Chave de API em `/api/hardware/*` | DSP-28 e DT-05 |
| Integração de fabricantes | Adaptador ZKTeco em `/api/hardware/events/zkteco` | Converter para o contrato de EP-031 com identificador de origem |
| Métodos | QR, NFC, geofence e PIN existentes no ERP | PIN depende de DF-01; geofence passa a contexto (§7) |

## 14. Rastreabilidade

| Requisitos | RF | RNF / RN | Casos de uso e diagramas |
| --- | --- | --- | --- |
| DSP-01 a DSP-10 | RF-019, RF-029 a RF-031, RF-034 | RNF-007, RNF-016, RNF-032 | UC-11; DG-DP-01 |
| DSP-11 a DSP-18 | RF-022, RF-025, RF-026 | RN-010, RN-013, RN-014; RNF-007, RNF-008 | UC-06; DG-SQ-02, DG-ES-01 |
| DSP-19 a DSP-22 | RF-027 a RF-031, RF-037 | RN-044; RNF-020 | UC-01; DG-SQ-01 |
| DSP-23 a DSP-26 | RF-020, RF-036 | RN-045 | UC-11, UC-12; DG-ES-08, DG-SQ-07 |
| DSP-27 a DSP-33 | RF-019, RF-062 | RNF-014 a RNF-016, RNF-020 | UC-11 |

## 15. Decisões pendentes

| Decisão | Efeito |
| --- | --- |
| DF-01 | Métodos por local, perfil "telemóvel do colaborador" e PIN |
| DF-03, DN-03 | Capacidade da fila, validade offline e tratamento após revogação |
| DF-04 | Templates no terminal e matching local |
| DN-08 | Matriz de compatibilidade e modelos |
| DT-05 | Mecanismo de credencial |
| DT-09 | Tamanho de lote e troca de referência temporal |
| DU-07 | Estados `suspenso` e `retirado` |
| PN-06, PN-11 | Limite de desvio de relógio e número de tentativas antes da alternativa |

## 16. Aprovação e referências

A equipa técnica valida DSP-11 a DSP-33; a operação valida provisionamento, monitorização e actualização; RH valida a experiência no terminal e a contingência; segurança valida §9; o responsável de dados valida métodos e localização. Cada aprovação deve identificar nome, versão e data. Estado de aprovação desta versão: **pendente**.

- [Índice da documentação](README.MD).
- [Diagramas UML](06-Diagramas-UML.md): DG-CP-02, DG-SQ-02, DG-ES-01, DG-ES-08.
- [APIs](10-Especificacao-de-APIs.md): EP-023 a EP-036.
- [Reconhecimento Facial e Liveness](12-Reconhecimento-Facial-e-Liveness.md).
