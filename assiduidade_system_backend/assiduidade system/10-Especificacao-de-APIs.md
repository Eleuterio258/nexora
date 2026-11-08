# Especificação de APIs — Sistema de Gestão de Assiduidade

## 1. Controlo do documento

| Campo | Valor |
| --- | --- |
| Referência | API-ASS-001 |
| Versão | 0.3 |
| Data | 25/09/2026 |
| Estado | Rascunho técnico para validação |
| Responsáveis | Equipa técnica, com validação da equipa ERP, operação e responsável de dados — nomes a designar |
| Base documental | [Casos de Uso](05-Casos-de-Uso.md), [TDD](08-Documento-de-Design-Tecnico-TDD.md), [Modelo de Dados](09-Modelo-de-Dados.md), [Matriz de Permissões](15-Matriz-de-Permissoes-e-Acessos.md) |

| Versão | Data | Alteração |
| --- | --- | --- |
| 0.1 | 25/09/2026 | Convenções, 21 endpoints e códigos de erro |
| 0.2 | 25/09/2026 | Versão detalhada: catálogo completo, contratos críticos, semântica de respostas de marcação, erros corrigidos e reconciliação com os endpoints existentes |
| 0.3 | 25/09/2026 | Autorização por permissões granulares: PERM ligado ao código `módulo:acção`; EP-005, EP-007 e EP-008 passam de papéis a cargos e permissões directas |

## 2. Objectivo, âmbito e convenções

Este documento define os contratos HTTP expostos pela plataforma a backoffice, aplicação Android, terminais e integrações. É a fonte para o contrato OpenAPI versionado, que deve ser gerado a partir dele e publicado com exemplos (RNF-036).

Convenções:

- **EP-xxx** identifica endpoints; **ERR** os códigos de erro de §4; **MOT** os códigos de motivo de §6.3. Identificadores estáveis.
- **Nomes em português**, coerentes com o [Modelo de Dados](09-Modelo-de-Dados.md) (proposta de DT-12). Recursos no plural, em minúsculas e com hífen.
- **Prefixo:** `/api/v1`. A relação com as rotas existentes `/api/rh`, `/api/self-service` e `/api/hardware` depende de DT-01 (§9).
- **Permissões** referem os identificadores PERM do [documento 15](15-Matriz-de-Permissoes-e-Acessos.md), cada um com o código `módulo:acção` que o servidor verifica. A autorização combina a permissão efectiva do utilizador (cargo, permissões directas e tipo de utilizador), o tenant, o âmbito sobre o colaborador (próprio, hierárquico ou global) e o objecto, e é sempre revalidada no serviço executor (MEC-01, [Requisitos Funcionais §3.1](02-Requisitos-Funcionais.md)).
- **Prioridade** herda a do RF correspondente: endpoints de RF Desejáveis (D) ou Opcionais (O) só são implementados se o RF entrar na entrega.

## 3. Convenções transversais

### 3.1. Autenticação

| Tipo de cliente | Mecanismo | Contexto resolvido |
| --- | --- | --- |
| Utilizador (backoffice, app do colaborador) | Sessão com token de acesso de curta duração e token de renovação rotativo (DF-02) | Conta, tenant seleccionado e validado, permissões efectivas e âmbito |
| Dispositivo (modo terminal) | Credencial individual do dispositivo, revogável e com rotação (DT-05) | Dispositivo, tenant e local |
| Integração | Credencial da configuração de integração, guardada em CNT-11 | Configuração de integração e tenant |
| Tarefa interna | Não usa a API pública | — |

Em pedidos de utilizadores com acesso a mais de um tenant, o tenant é seleccionado na sessão e validado no servidor; o cabeçalho `X-Tenant` só escolhe entre tenants já autorizados e nunca concede acesso.

### 3.2. Cabeçalhos

| Cabeçalho | Direcção | Uso |
| --- | --- | --- |
| `Authorization` | Pedido | Credencial de §3.1 |
| `Idempotency-Key` | Pedido | Obrigatório em POST que alteram estado, excepto quando o corpo contém `evento_uuid` (MEC-02, MEC-03) |
| `If-Match` | Pedido | Versão do objecto em transições e decisões (MEC-07) |
| `X-Request-Id` | Pedido e resposta | Gerado pelo cliente ou pelo servidor; sempre devolvido |
| `X-Correlation-Id` | Resposta | Correlação da cadeia de processamento (MEC-12) |
| `Idempotent-Replay: true` | Resposta | Indica resposta repetida a partir de MEC-02 |
| `Retry-After` | Resposta | Em 429, 503 e conflitos temporários |
| `Deprecation`, `Sunset` | Resposta | Endpoints em descontinuação (§3.6) |

### 3.3. Formatos

- JSON UTF-8. Instantes em ISO 8601 com offset explícito (`2026-09-25T08:01:15+02:00`); o servidor guarda UTC e o fuso IANA do contexto (MEC-04).
- Datas civis em `AAAA-MM-DD`; durações em ISO 8601 (`PT7H30M`). Grandeza indeterminada é `null`, nunca `0` (RN §5.2).
- Campos condicionais distinguem "não aplicável" (campo ausente) de "indisponível" (`null` com `motivo_indisponibilidade`), conforme RF §5.
- Identificadores públicos são UUID (DT-06).

### 3.4. Listas

Listas transaccionais usam paginação por cursor (`cursor`, `limite`, máximo 200), ordenação estável e filtros explícitos. Resultados são sempre limitados ao âmbito do actor; filtros nunca alargam o âmbito. Respostas incluem `proximo_cursor` e não incluem totais caros por defeito.

### 3.5. Limites

Limites por credencial e por tenant (RNF-005, RNF-018): pedidos por minuto, tamanho de corpo, tamanho de lote de sincronização (DT-09) e anexos. Excesso devolve `429 LIMITE_EXCEDIDO` com `Retry-After`; nenhum pedido excedente é aceite parcialmente sem indicação.

### 3.6. Versionamento

Alterações incompatíveis criam `/api/v2`. Na mesma versão só se acrescentam campos opcionais e valores de enumeração documentados como extensíveis. Endpoints descontinuados mantêm-se pelo prazo publicado, com `Deprecation` e `Sunset`. Terminais recebem configuração compatível com a sua versão mínima; configuração incompatível fica pendente e o terminal mantém a anterior (RF-020).

## 4. Erros

### 4.1. Formato

```json
{
  "erro": {
    "codigo": "PERIODO_FECHADO",
    "mensagem": "O período já está fechado. A alteração exige reabertura autorizada.",
    "detalhes": {"periodo_uuid": "3f2c0d1e-..."},
    "campos": [],
    "request_id": "b7e1..."
  }
}
```

`campos` lista erros de validação por campo (`campo`, `codigo`, `mensagem`). Mensagens não revelam dados de terceiros nem a existência de objectos fora do âmbito (MEC-12).

### 4.2. Catálogo

| Código | HTTP | Quando |
| --- | --- | --- |
| `AUTENTICACAO_NECESSARIA` | 401 | Credencial ausente, inválida ou expirada |
| `SEM_PERMISSAO` | 403 | Actor autenticado sem a permissão PERM exigida |
| `TENANT_SUSPENSO` | 403 | Operação de negócio em tenant suspenso (RF-001) |
| `DISPOSITIVO_REVOGADO` | 403 | Credencial de dispositivo revogada ou dispositivo não activo |
| `AUTORIZACAO_OFFLINE_EXPIRADA` | 403 | Lote com autorização local fora da validade aprovada (DF-03) |
| `NAO_ENCONTRADO` | 404 | Objecto inexistente **ou fora do âmbito** do actor |
| `CONFLITO_IDEMPOTENCIA` | 409 | Mesma chave com conteúdo diferente (MEC-02) |
| `PROCESSAMENTO_EM_CURSO` | 409 | Mesma chave ainda em processamento; repetir após `Retry-After` |
| `CONFLITO_VERSAO` | 409 | `If-Match` diferente da versão actual (MEC-07) |
| `TRANSICAO_INVALIDA` | 409 | Transição não permitida no estado actual (MEC-09) |
| `PERIODO_FECHADO` | 409 | Alteração de resultado em período fechado (RN-038) |
| `PENDENCIAS_IMPEDITIVAS` | 409 | Fecho com pendências impeditivas (RN-037) |
| `PARAMETRO_PENDENTE` | 409 | Operação depende de parâmetro não aprovado (PD-09) |
| `SEGREGACAO_FUNCOES` | 409 | Decisor coincide com requerente sem política de auto-aprovação (RN-031) |
| `LOTE_DEMASIADO_GRANDE` | 413 | Lote ou anexo acima do limite |
| `PEDIDO_INVALIDO` | 422 | Validação de formato ou de regras de entrada, com `campos` |
| `LIMITE_EXCEDIDO` | 429 | Limite de §3.5 |
| `AUDITORIA_INDISPONIVEL` | 503 | Evidência não pode ser registada e não há persistência alternativa (RNF-026) |
| `DEPENDENCIA_INDISPONIVEL` | 503 | Componente biométrico ou outra dependência síncrona indisponível |
| `ERRO_INTERNO` | 500 | Falha técnica não classificada |

Resultados de negócio **não são erros HTTP**: uma marcação rejeitada, um reenvio equivalente ou uma falha de correspondência facial são respostas bem-sucedidas com o resultado no corpo (§6). O código `DUPLICATE_EVENT` da versão 0.1 foi retirado, porque um reenvio equivalente devolve o resultado existente (RN-010).

## 5. Catálogo de endpoints

### 5.1. Identidade e acessos (CMP-02)

| ID | Método e recurso | Finalidade | Permissão | RF / UC |
| --- | --- | --- | --- | --- |
| EP-001 | `POST /sessoes` | Autenticar e criar sessão | — | RF-006 / UC-08 |
| EP-002 | `POST /sessoes/renovacao` | Renovar token com rotação | Sessão válida | RF-006 |
| EP-003 | `DELETE /sessoes/actual` | Terminar sessão | Sessão válida | RF-006 |
| EP-004 | `POST /recuperacoes-acesso` | Iniciar recuperação pelo mecanismo aprovado | — | RF-006, DF-02 |
| EP-005 | `GET /eu` | Identidade, tenants autorizados, cargo, permissões efectivas e âmbito | Sessão válida | RF-007 |
| EP-006 | `GET`, `POST /contas`; `POST /contas/{uuid}/estado` | Gerir contas e o seu estado | PERM-03 | RF-007 |
| EP-007 | `GET`, `POST /cargos`; `PUT /cargos/{uuid}/permissoes` | Compor cargos do tenant a partir do catálogo de permissões | PERM-03 | RF-007 |
| EP-008 | `PUT /contas/{uuid}/cargo`; `POST /contas/{uuid}/permissoes-directas`; `POST /permissoes-directas/{uuid}/revogacao` | Atribuir cargo e atribuir ou revogar permissões directas com vigência | PERM-03 | RF-007 |
| EP-009 | `POST /autorizacoes-suporte`; `POST /autorizacoes-suporte/{uuid}/revogacao` | Conceder e revogar acesso de suporte | PERM-04 | RF-008 |

### 5.2. Organização e colaboradores (CMP-03)

| ID | Método e recurso | Finalidade | Permissão | RF / UC |
| --- | --- | --- | --- | --- |
| EP-010 | `GET`, `POST /tenants`; `POST /tenants/{uuid}/estado` | Ciclo de vida de tenants, com motivo | PERM-01 | RF-001 / UC-07 |
| EP-011 | `GET`, `PATCH /tenant` | Configuração do tenant actual | PERM-02 | RF-003 |
| EP-012 | `GET`, `POST /unidades`; `PATCH /unidades/{uuid}` | Estrutura organizacional com vigência | PERM-02 | RF-004, RF-005 |
| EP-013 | `GET`, `POST /colaboradores`; `GET`, `PATCH /colaboradores/{uuid}` | Cadastro e vínculo | PERM-05 | RF-009 / UC-09 |
| EP-014 | `POST /colaboradores/{uuid}/associacoes` | Unidade, função, equipa e aprovadores com vigência | PERM-05 | RF-010, RF-012 |
| EP-015 | `POST /colaboradores/{uuid}/credenciais`; `POST /credenciais/{uuid}/revogacao` | QR Code, NFC e PIN | PERM-05 | RF-012, RF-028, RF-029 |
| EP-016 | `POST /importacoes/colaboradores`; `GET /importacoes/{uuid}` | Importação em lote com resultado por linha | PERM-06 | RF-013 |

### 5.3. Horários e políticas (CMP-04)

| ID | Método e recurso | Finalidade | Permissão | RF / UC |
| --- | --- | --- | --- | --- |
| EP-017 | `GET`, `POST /calendarios` | Calendários, feriados e excepções | PERM-07 | RF-015 / UC-10 |
| EP-018 | `GET`, `POST /horarios` | Horários fixos, flexíveis e turnos | PERM-07 | RF-014 |
| EP-019 | `POST /associacoes-horario` | Associar horário com vigência | PERM-07 | RF-010, RF-014 |
| EP-020 | `GET`, `POST /politicas/{uuid}/versoes` | Criar versão em rascunho | PERM-07 | RF-016, RF-017 |
| EP-021 | `POST /politicas/{uuid}/versoes/{n}/activacao` | Activar versão aprovada | PERM-08 | RF-016 |
| EP-022 | `POST /politicas/{uuid}/simulacoes` | Simular sem alterar dados oficiais (O) | PERM-07 | RF-018 |

### 5.4. Terminais e configuração (CMP-05)

| ID | Método e recurso | Finalidade | Permissão | RF / UC |
| --- | --- | --- | --- | --- |
| EP-023 | `GET`, `POST /dispositivos` | Registar dispositivo no tenant e local | PERM-09 | RF-019 / UC-11 |
| EP-024 | `POST /dispositivos/{uuid}/activacao`; `POST /dispositivos/{uuid}/revogacao` | Activar e revogar | PERM-09 | RF-019 |
| EP-025 | `POST /dispositivos/{uuid}/credenciais` | Emitir ou rodar credencial de dispositivo | PERM-09 | RF-019, DT-05 |
| EP-026 | `POST /configuracoes` | Publicar versão de configuração para dispositivos | PERM-09 | RF-020 |
| EP-027 | `GET /dispositivo/configuracao` | O dispositivo obtém a configuração e a referência temporal do servidor | Dispositivo | RF-020, MEC-04 |
| EP-028 | `GET /dispositivo/propagacoes` | Alterações pendentes (templates, revogações) para este dispositivo | Dispositivo | RF-036, MEC-11 |
| EP-029 | `POST /dispositivo/confirmacoes` | Confirmar aplicação de configuração e propagações | Dispositivo | RF-020, RF-036 |
| EP-030 | `POST /dispositivo/estado` | Sinal de vida, versão, fila pendente e espaço livre | Dispositivo | RF-063 |

### 5.5. Marcações (CMP-06)

| ID | Método e recurso | Finalidade | Permissão | RF / UC |
| --- | --- | --- | --- | --- |
| EP-031 | `POST /eventos` | Marcação online (§6.1) | PERM-10 ou PERM-11 | RF-021 a RF-024 / UC-01 |
| EP-032 | `POST /eventos/lotes` | Sincronização offline com resposta por item (§6.2) | PERM-11 | RF-025, RF-026 / UC-06 |
| EP-033 | `POST /eventos/assistidos` | Marcação assistida no backoffice, com motivo | PERM-12 | RF-027 |
| EP-034 | `GET /eventos`; `GET /eventos/{uuid}` | Consulta de eventos, recepções e estado | PERM-20 ou PERM-21 | RF-051 |
| EP-035 | `GET /eventos/pendentes`; `POST /eventos/{uuid}/resolucao` | Analisar pendências: aceitar, rejeitar ou classificar como duplicado | PERM-13 | RF-024, RN-011, RN-015 |
| EP-036 | `POST /tentativas-identificacao` | Registar tentativas falhadas sem evento | PERM-11 | RF-037 |

### 5.6. Biometria (CMP-07)

| ID | Método e recurso | Finalidade | Permissão | RF / UC |
| --- | --- | --- | --- | --- |
| EP-037 | `GET`, `POST /colaboradores/{uuid}/habilitacoes-biometricas`; `POST /habilitacoes-biometricas/{uuid}/revogacao` | Habilitação, finalidade e consentimento | PERM-14 | RF-061 |
| EP-038 | `POST /enrollments`; `POST /enrollments/{uuid}/capturas`; `POST /enrollments/{uuid}/conclusao` | Enrollment guiado (§6.4) | PERM-15 | RF-033 / UC-04 |
| EP-039 | `POST /referencias-biometricas/{uuid}/operacoes` | Suspender, substituir ou eliminar, com motivo | PERM-15 | RF-036 / UC-12 |
| EP-040 | `GET /referencias-biometricas/{uuid}` | Estado e propagação por destino, sem template | PERM-15 | RF-036, RF-037 |
| EP-041 | `POST /verificacoes-faciais` | Matching e prova de vida centrais — **só se DF-04 escolher processamento central** | PERM-11 | RF-034 |
| EP-042 | `GET`, `PUT /configuracao-biometrica` | Limiar dentro dos limites aprovados | PERM-16 | RF-035 |

### 5.7. Pedidos e aprovações (CMP-08)

| ID | Método e recurso | Finalidade | Permissão | RF / UC |
| --- | --- | --- | --- | --- |
| EP-043 | `POST /pedidos/correccoes` | Pedido de correcção ou inclusão de marcação (§6.3) | PERM-17 ou PERM-18 | RF-046 / UC-02 |
| EP-044 | `POST /pedidos/ausencias` | Férias, ausência ou justificação | PERM-17 ou PERM-18 | RF-042 / UC-14 |
| EP-045 | `POST /pedidos/{uuid}/cancelamentos` | Cancelamento de pedido aprovado (D) | PERM-17 ou PERM-18 | RF-045 |
| EP-046 | `GET /pedidos`; `GET /pedidos/{uuid}` | Consulta de pedidos, versões e decisões | PERM-20 ou PERM-21 | RF-051 |
| EP-047 | `PATCH /pedidos/{uuid}` | Alterar conteúdo: cria nova versão | Requerente | RF §6, DU-04 |
| EP-048 | `POST /pedidos/{uuid}/submissao` | Submeter rascunho | Requerente | RF-042, RF-046 |
| EP-049 | `POST /pedidos/{uuid}/decisoes` | Aprovar ou rejeitar uma versão (`If-Match`) | PERM-19 | RF-043, RF-047 |
| EP-050 | `POST /pedidos/{uuid}/anexos` | Anexar documento autorizado | Requerente | RF-042 |
| EP-051 | `GET`, `POST /tipos-ausencia` | Tipos, unidades e documentos exigidos | PERM-07 | RF-041 |
| EP-052 | `GET /colaboradores/{uuid}/saldos` | Saldos com origem e referência de actualização | PERM-20 ou PERM-21 | RF-041, RF-044 |

### 5.8. Apuramento e períodos (CMP-09, CMP-10)

| ID | Método e recurso | Finalidade | Permissão | RF / UC |
| --- | --- | --- | --- | --- |
| EP-053 | `GET /jornadas` | Jornadas, eventos considerados e ocorrências | PERM-20 ou PERM-21 | RF-038, RF-051 |
| EP-054 | `GET /apuramentos/{uuid}`; `GET /apuramentos/{uuid}/versoes` | Resultado e versões anteriores | PERM-21 | RF-039 |
| EP-055 | `POST /apuramentos/recalculos` | Recalcular âmbito aberto, com motivo | PERM-22 | RF-039 / UC-13 |
| EP-056 | `POST /ocorrencias/{uuid}/decisoes` | Decidir horas elegíveis aprovadas | PERM-22 | RF-040 |
| EP-057 | `GET`, `POST /periodos` | Consultar e criar períodos | PERM-23 | RF-048 |
| EP-058 | `POST /periodos/{uuid}/validacao` | Iniciar validação; devolve pendências (§6.5) | PERM-23 | RF-048 / UC-03 |
| EP-059 | `POST /periodos/{uuid}/fechos` | Fechar a versão validada (`If-Match`) | PERM-23 | RF-049 |
| EP-060 | `POST /periodos/{uuid}/reaberturas` | Reabrir com motivo | PERM-24 | RF-050 / UC-15 |
| EP-061 | `GET /periodos/{uuid}/fechos` | Versões de fecho e envios associados | PERM-21 | RF-049, RF-050 |

### 5.9. Relatórios (CMP-11)

| ID | Método e recurso | Finalidade | Permissão | RF / UC |
| --- | --- | --- | --- | --- |
| EP-062 | `GET /relatorios/{tipo}` | Relatórios de horas, atrasos, faltas, pausas, extraordinárias e excepções | PERM-25 | RF-052 / UC-16 |
| EP-063 | `POST /exportacoes`; `GET /exportacoes/{uuid}` | Exportação assíncrona com finalidade e campos (D) | PERM-26 | RF-053 |
| EP-064 | `GET`, `POST /agendamentos-relatorio` | Relatórios agendados (O) | PERM-27 | RF-055 |

### 5.10. Integração (CMP-12)

| ID | Método e recurso | Finalidade | Permissão | RF / UC |
| --- | --- | --- | --- | --- |
| EP-065 | `GET`, `POST /integracoes`; `PATCH /integracoes/{uuid}` | Configurar destino, contrato, mapeamentos e fonte de referência | PERM-28 | RF-056 / UC-19 |
| EP-066 | `POST /integracoes/{uuid}/testes`; `POST /integracoes/{uuid}/activacao` | Testar e activar versão da configuração | PERM-28 | RF-056 |
| EP-067 | `POST /integracoes/{uuid}/lotes-entrada` | Recepção de dados mestre enviados pelo sistema externo | Integração | RF-057 |
| EP-068 | `POST /integracoes/{uuid}/execucoes` | Executar envio ou sincronização | PERM-29 | RF-057, RF-058 / UC-05 |
| EP-069 | `GET /execucoes-integracao/{uuid}`; `GET /execucoes-integracao/{uuid}/itens` | Estado por execução e item | PERM-29 | RF-059 |
| EP-070 | `POST /execucoes-integracao/{uuid}/reprocessamentos` | Reprocessar itens com a mesma identidade | PERM-29 | RF-059 |
| EP-071 | `GET /execucoes-integracao/{uuid}/reconciliacao` | Quantidades, totais e divergências | PERM-29 | RF-059 |

### 5.11. Auditoria, retenção e operação (CMP-13 a CMP-16)

| ID | Método e recurso | Finalidade | Permissão | RF / UC |
| --- | --- | --- | --- | --- |
| EP-072 | `GET /auditoria/eventos` | Pesquisa por actor, objecto, acção e intervalo | PERM-30 ou PERM-31 | RF-060 / UC-17 |
| EP-073 | `GET /auditoria/objectos/{tipo}/{uuid}` | Cadeia de evidência de um objecto | PERM-30 | RF-060 |
| EP-074 | `GET`, `POST /politicas-retencao` | Prazos por categoria e âmbito | PERM-32 | RF-062 / UC-18 |
| EP-075 | `POST /operacoes-ciclo-vida`; `GET /operacoes-ciclo-vida/{uuid}` | Eliminar ou anonimizar e acompanhar destinos | PERM-32 | RF-062 |
| EP-076 | `GET /operacao/estado` | Serviços, filas, integrações e terminais | PERM-33 | RF-063 / UC-20 |
| EP-077 | `GET`, `POST /operacao/regras-alerta` | Limiares, destinatários e canais (D) | PERM-34 | RF-064 |
| EP-078 | `GET /notificacoes` | Notificações do próprio utilizador | Sessão válida | RF-054 |
| EP-079 | `GET /saude` | Sondas de vida e prontidão, sem dados de negócio | — | RNF-027 |

Cópias de segurança e restauro (RF-065, UC-21) são executados por procedimento operacional, não pela API pública.

## 6. Contratos críticos

### 6.1. EP-031 — Marcação online

Pedido:

```json
{
  "evento_uuid": "6a4c2f0e-8d51-4a3b-9c1e-2b7f5d0a9e11",
  "tipo_evento": "entrada",
  "instante_origem": "2026-09-25T08:01:15+02:00",
  "fuso_origem": "Africa/Maputo",
  "desvio_relogio_ms": 420,
  "metodo_identificacao": "facial",
  "colaborador_uuid": "c1d2...",
  "identificacao": {"tentativa_uuid": "9f01...", "referencia_biometrica_versao": "enr-3/alg-2.1"},
  "configuracao_versao": 17,
  "localizacao": {"latitude": -25.9692, "longitude": 32.5732, "precisao_m": 12}
}
```

`localizacao` só é enviada quando a configuração a exige (RF-031). O terminal nunca envia imagens nem templates.

Semântica das respostas:

| Situação | HTTP | Corpo |
| --- | --- | --- |
| Primeira recepção, evento aceite | 201 | `estado: aceite` |
| Primeira recepção, evento registado em pendência | 201 | `estado: pendente_analise`, `motivo_codigo` (§6.3) |
| Primeira recepção, evento registado como rejeitado | 201 | `estado: rejeitado`, `motivo_codigo` — o evento fica preservado (RN-012) |
| Reenvio com o mesmo `evento_uuid` e conteúdo equivalente | 200 | Resultado original, com `Idempotent-Replay: true` |
| Mesmo `evento_uuid` com conteúdo diferente | 409 | `CONFLITO_IDEMPOTENCIA`; recepção registada para análise (09 §6.1) |
| Pedido mal formado | 422 | `PEDIDO_INVALIDO`; nenhum evento criado |
| Dispositivo revogado ou tenant suspenso | 403 | Nenhum evento aceite (RF-001, RF-019) |

Resposta de sucesso:

```json
{
  "evento_uuid": "6a4c2f0e-8d51-4a3b-9c1e-2b7f5d0a9e11",
  "estado": "aceite",
  "motivo_codigo": null,
  "instante_recepcao": "2026-09-25T06:01:16Z",
  "mensagem_colaborador": "Entrada registada às 08:01."
}
```

A decisão de recepção é síncrona; o apuramento é assíncrono (EVD-01). `202 Accepted` não é usado para marcações, para não confundir recepção técnica com aceitação (PD-03).

### 6.2. EP-032 — Sincronização offline

Pedido: `lote_uuid`, `dispositivo_instante_envio`, `referencia_temporal` (último instante do servidor conhecido) e `eventos` (lista de corpos de EP-031, com tamanho máximo definido em DT-09).

Resposta `200` com um resultado por evento, pela ordem recebida:

```json
{
  "lote_uuid": "d0e4...",
  "instante_servidor": "2026-09-25T09:30:02Z",
  "resultados": [
    {"evento_uuid": "6a4c...", "estado": "aceite", "replay": false},
    {"evento_uuid": "71b0...", "estado": "pendente_analise", "motivo_codigo": "RELOGIO_SUSPEITO", "replay": false},
    {"evento_uuid": "8e22...", "estado": "aceite", "replay": true},
    {"evento_uuid": "90af...", "erro": {"codigo": "PEDIDO_INVALIDO", "campos": [{"campo": "tipo_evento"}]}}
  ]
}
```

Regras: cada item é processado de forma independente e idempotente; um item inválido não invalida os restantes; o terminal remove da fila todos os itens com `estado` (incluindo `rejeitado` e `pendente_analise`, que passam a ser tratados centralmente) e mantém apenas os itens com `erro` técnico ou sem resposta (RN-014, DG-ES-01). Autorização local expirada devolve o item com `AUTORIZACAO_OFFLINE_EXPIRADA`, sem aceitação automática (RN-015).

### 6.3. Códigos de motivo de marcação

| Código | Estado resultante | Origem |
| --- | --- | --- |
| `COLABORADOR_INACTIVO` | rejeitado | RF-021, RN-004 |
| `METODO_NAO_HABILITADO` | rejeitado | RN-009 |
| `DISPOSITIVO_NAO_AUTORIZADO_NO_LOCAL` | rejeitado | RF-019 |
| `IDENTIDADE_POR_RESOLVER` | pendente_analise | RN-008 |
| `AUTORIZACAO_HISTORICA` | pendente_analise | RN-015 |
| `RELOGIO_SUSPEITO` | pendente_analise | RN-013 |
| `PERIODO_FECHADO` | pendente_analise | RN-016 |
| `SEQUENCIA_AMBIGUA` | pendente_analise | RN-018 |
| `POSSIVEL_REPETICAO` | pendente_analise | RN-011 |
| `LOCALIZACAO_FORA_DA_AREA` | rejeitado ou pendente_analise, conforme política | RF-031 |
| `CONTEUDO_DIVERGENTE` | pendência sobre a recepção | RN-010 |

### 6.4. EP-038 — Enrollment

1. `POST /enrollments` com `colaborador_uuid` e `modalidade`: valida habilitação (RN-043); devolve `enrollment_uuid` em `em_preparacao` ou `SEM_PERMISSAO`/`PARAMETRO_PENDENTE`.
2. `POST /enrollments/{uuid}/capturas`: envia a captura ao componente biométrico; devolve apenas `qualidade_suficiente`, `prova_vida` e instruções. A captura não é guardada fora de CNT-09 (PD-05).
3. `POST /enrollments/{uuid}/conclusao`: activa a referência, liga à anterior em substituição e inicia a propagação (MEC-11). Devolve `referencia_uuid`, versões e estado por destino.

Um enrollment sem conclusão não produz referência activa (RF-033). O conteúdo destes pedidos depende de DF-04 (processamento no terminal ou central).

### 6.5. EP-058 e EP-059 — Validação e fecho

`POST /periodos/{uuid}/validacao` passa o período a `em_validacao` e devolve `pendencias` agrupadas (marcações pendentes, pedidos em aberto, conflitos, integrações), cada uma com `impeditiva: true|false`, e a `versao` do período. `POST /periodos/{uuid}/fechos` exige `If-Match` com essa versão e, para excepções não impeditivas, `justificacoes`. Se o conjunto validado mudou, devolve `CONFLITO_VERSAO`; se houver pendência impeditiva, `PENDENCIAS_IMPEDITIVAS`. Sucesso devolve `201` com o `fecho` (número de versão, hash dos resultados, regras aplicadas).

### 6.6. EP-049 — Decisão sobre pedido

Corpo: `resultado` (`aprovado` ou `rejeitado`), `motivo` (obrigatório na rejeição) e `If-Match` com a versão do pedido. O servidor verifica competência e segregação no momento (RN-031). Duas decisões sobre a mesma versão produzem uma decisão e um `CONFLITO_VERSAO` (RN-035). A aprovação de correcção cria o ajuste e desencadeia o recálculo (EVD-03); se o período estiver fechado, o ajuste fica pendente até reabertura (UC-02, UC-15).

## 7. Eventos expostos a terceiros

A plataforma não expõe webhooks na primeira entrega. Sistemas externos obtêm resultados através das execuções de integração (EP-068 a EP-071) ou pela entrega definida no contrato do [documento 18](18-Integracoes-com-Sistemas-Externos.md). A introdução de webhooks exige decisão própria e contrato versionado.

## 8. Segurança da API

Controlos obrigatórios em todos os endpoints: TLS, autenticação de §3.1, autorização por PERM, âmbito e objecto, validação de esquema, limites de tamanho e de frequência, protecção contra repetição por MEC-02 e registo de auditoria das operações críticas (catálogo do [documento 16](16-Auditoria-e-Logs.md)). Endpoints de dispositivo (EP-027 a EP-032, EP-036, EP-041) aceitam apenas credenciais de dispositivo. Detalhe no [documento 17](17-Seguranca-e-Proteccao-de-Dados.md).

## 9. Reconciliação com os endpoints existentes

Endpoints do [inventário do ERP](../endpoints_assiduidade_erp.md) observados em 25/09/2026, mapeados para este catálogo. O tratamento de cada lacuna depende de DT-01.

| Endpoint existente | Equivalente | Lacuna ou conflito |
| --- | --- | --- |
| `DELETE /api/rh/funcionarios/{id}/presencas/{presencaId}` | — | **Remoção física de assiduidade, contrária a PD-01.** Substituir por pedido de correcção (EP-043) e decisão |
| `POST /api/rh/funcionarios/{id}/presencas` | EP-033 | Criação directa sem motivo nem estado de origem assistida |
| `POST /api/rh/eventos`, `POST /api/rh/assiduidade/ponto` | EP-033 | Marcação pelo gestor: exigir motivo e origem `backoffice_assistido` |
| `POST /api/self-service/assiduidade/ponto` | EP-031 | Sem identificador de origem nem semântica de reenvio |
| `POST /api/hardware/events`, `/events/generic`, `/events/zkteco` | EP-031 | Adaptadores por fabricante devem converter para o contrato de EP-031 |
| `POST /api/hardware/events/batch` | EP-032 | Resposta por item e idempotência a confirmar |
| Autenticação por chave de API em `/api/hardware/*` | §3.1 | Credencial individual e rotativa (DT-05) |
| `POST /api/rh/ausencias` com permissão `aprovar_ausencias` | EP-044 | O colaborador não pode submeter o próprio pedido por esta rota (RF-042) |
| `POST /api/rh/ausencias/{id}/aprovar`, `/rejeitar` | EP-049 | Sem versão de pedido nem controlo de concorrência |
| `/api/rh/correcoes-ponto` (modelo antigo) e `/api/rh/correcoes` (novo) | EP-043, EP-049 | Dois modelos em paralelo; descontinuar o antigo |
| `/api/rh/justificacoes`, `/api/self-service/assiduidade/justificacoes` | EP-044 | Unificar em pedidos de ausência/justificação |
| `POST /api/rh/funcionarios/{id}/recalcular` | EP-055 | Sem motivo nem versão do resultado |
| `POST /api/rh/funcionarios/biometria/facial/enroll` | EP-038 | Sem habilitação prévia nem estados do template |
| `POST /api/self-service/assiduidade/biometria/facial/verificar` | EP-041 | Condicional a DF-04 |
| `POST /api/hardware/assiduidade/consentimentos`, `/revogar` | EP-037 | Um dispositivo registar ou revogar consentimentos exige decisão explícita de finalidade (RF-061) |
| `GET /api/hardware/assiduidade/geofence/validar` | EP-027 | Área incluída na configuração do dispositivo |
| `GET /api/hardware/assiduidade/funcionarios` | EP-028 | Lista de colaboradores distribuída ao terminal deve ser mínima e propagada com MEC-11 |
| `GET /api/hardware/audit-logs` | EP-072 | Consulta de auditoria por credencial de dispositivo não é prevista |
| — | EP-057 a EP-061 | Fecho e reabertura de períodos de assiduidade não existem |
| — | EP-068 a EP-071 | Execuções de integração com reconciliação não existem |

## 10. Rastreabilidade

| Endpoints | Casos de uso | Requisitos | Diagramas |
| --- | --- | --- | --- |
| EP-001 a EP-009 | UC-08 | RF-006 a RF-008 | DG-UC-04 |
| EP-010 a EP-016 | UC-07, UC-09 | RF-001 a RF-005, RF-009 a RF-013 | DG-CL-01 |
| EP-017 a EP-022 | UC-10 | RF-014 a RF-018 | DG-CL-03 |
| EP-023 a EP-030 | UC-11 | RF-019, RF-020, RF-036, RF-063 | DG-ES-08 |
| EP-031 a EP-036 | UC-01, UC-06 | RF-021 a RF-031, RF-037 | DG-SQ-01, DG-SQ-02, DG-AC-01 |
| EP-037 a EP-042 | UC-04, UC-12 | RF-032 a RF-037, RF-061 | DG-SQ-04, DG-SQ-07 |
| EP-043 a EP-052 | UC-02, UC-14 | RF-041 a RF-047 | DG-SQ-03, DG-AC-03 |
| EP-053 a EP-061 | UC-03, UC-13, UC-15 | RF-038 a RF-040, RF-048 a RF-050 | DG-SQ-05, DG-SQ-06 |
| EP-062 a EP-064 | UC-16 | RF-051 a RF-053, RF-055 | — |
| EP-065 a EP-071 | UC-05, UC-19 | RF-056 a RF-059 | DG-SQ-05, DG-ES-07 |
| EP-072 a EP-079 | UC-17, UC-18, UC-20 | RF-054, RF-060, RF-062 a RF-064 | DG-AC-04 |

## 11. Decisões pendentes

| Decisão | Efeito nesta especificação |
| --- | --- |
| DT-01 | Prefixo definitivo e plano de §9 |
| DT-05 | Mecanismo de credencial de dispositivo |
| DT-09 | Tamanho de lote e troca de referência temporal |
| DT-12 | Nomes definitivos de recursos e campos |
| DF-02 | Mecanismo de sessão e recuperação (EP-001 a EP-004) |
| DF-04 | Existência de EP-041 e conteúdo de EP-038 |
| DF-07 | Tipos de relatório e formatos de EP-062 e EP-063 |
| DN-10 | Política de compatibilidade e prazos de descontinuação |

## 12. Aprovação e referências

A equipa técnica valida contratos e semântica; a equipa ERP valida EP-065 a EP-071; a operação valida EP-076 a EP-079; o responsável de dados valida EP-037 a EP-042 e EP-063. Cada aprovação deve identificar nome, versão e data. Estado de aprovação desta versão: **pendente**.

- [Índice da documentação](README.MD).
- [TDD](08-Documento-de-Design-Tecnico-TDD.md), [Modelo de Dados](09-Modelo-de-Dados.md), [Matriz de Permissões](15-Matriz-de-Permissoes-e-Acessos.md), [Auditoria](16-Auditoria-e-Logs.md).
- [Inventário de endpoints de assiduidade do ERP](../endpoints_assiduidade_erp.md).
