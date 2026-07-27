# Permissões do Módulo de Recursos Humanos

## Visão geral

Este documento lista todas as permissões necessárias para usar o módulo de **Recursos Humanos** do Nexora ERP, incluindo:

- Gestão de funcionários
- Contratos
- Ausências e férias
- Assiduidade
- Salários e recibos
- Benefícios e formações
- Avaliações de desempenho
- Cargos, horários e unidades

> As permissões são verificadas pelo middleware `RequirePermission` / `RequirePermissionAny` do ERP Go. O FaceClock (gateway biométrico) não tem permissões — só usa `X-API-Key`.

---

## 1. Permissões do módulo `recursos-humanos`

| Permissão | Descrição | Exemplos de uso |
|-----------|-----------|-----------------|
| `recursos-humanos:ver_funcionarios` | Ver funcionários, unidades, cargos, horários, presenças, documentos | Listar funcionários, ver detalhe, listar unidades, listar cargos |
| `recursos-humanos:gerir_funcionarios` | Criar/editar/eliminar funcionários, unidades, cargos, documentos, contactos de emergência, cadastrar rosto | Criar funcionário, cadastrar rosto, criar unidade, criar cargo |
| `recursos-humanos:ver_recibos` | Ver recibos de vencimento | Listar recibos do funcionário |
| `recursos-humanos:ver_salarios` | Ver salários, histórico salarial, componentes, folhas de pagamento | Ver folha de pagamento, histórico salarial |
| `recursos-humanos:processar_salarios` | Processar salários, criar folhas, componentes, períodos | Criar folha de pagamento, processar salários |
| `recursos-humanos:ver_beneficios` | Ver benefícios | Listar benefícios |
| `recursos-humanos:gerir_beneficios` | Criar/editar/eliminar benefícios | Criar benefício |
| `recursos-humanos:gerir_formacoes` | Gerir formações do funcionário | Criar/editar/eliminar formações |
| `recursos-humanos:gerir_contratos` | Gerir contratos | Criar/editar/renovar/rescindir contratos |
| `recursos-humanos:gerir_avaliacoes` | Gerir avaliações de desempenho e critérios | Criar avaliação, critérios |
| `recursos-humanos:gerir_horarios` | Gerir horários de trabalho | Criar/editar/eliminar horários |
| `recursos-humanos:aprovar_ausencias` | Aprovar/rejeitar ausências | Aprovar férias, criar ausência |
| `recursos-humanos:ver_processos_disciplinares` | Ver processos disciplinares | Listar processos |

---

## 2. Permissões do módulo `assiduidade`

| Permissão | Descrição | Exemplos de uso |
|-----------|-----------|-----------------|
| `assiduidade:ver_assiduidade` | Ver a própria assiduidade (self-service) | Minha assiduidade, resumo, justificações |
| `assiduidade:justificar` | Criar justificações de falta/atraso | Criar justificação |
| `assiduidade:corrigir_ponto` | Criar pedidos de correção de ponto | Criar/listar/cancelar correções |
| `assiduidade:ver_configuracao` | Ver configuração de assiduidade | Listar regras |
| `assiduidade:gerir_configuracao` | Gerir configuração de assiduidade | Criar/editar/eliminar tipos de evento, métodos, regras |
| `assiduidade:aprovar_correcao` | Aprovar/rejeitar correções de ponto | Listar pendentes, aprovar/rejeitar |

---

## 3. Permissões do módulo `pedido-ferias`

| Permissão | Descrição | Exemplos de uso |
|-----------|-----------|-----------------|
| `pedido-ferias:ver_pedidos` | Ver pedidos de férias | Listar meus pedidos, tipos de ausência |
| `pedido-ferias:submeter_pedido` | Submeter/cancelar pedidos de férias | Criar pedido, cancelar |

---

## 4. Permissões do self-service relacionadas

| Permissão | Endpoint | Ação |
|-----------|----------|------|
| `perfil:ver_perfil` | `GET /api/self-service/home` | Home do self-service |
| `perfil:editar_perfil` | `POST /api/self-service/notificacoes/lida` | Marcar notificação como lida |
| `perfil:editar_perfil` | `POST /api/self-service/comunicados/lido` | Marcar comunicado como lido |

---

## 5. Mapeamento completo de endpoints por permissão

### 5.1 Relatórios e presenças

| Método | Endpoint | Permissão |
|--------|----------|-----------|
| GET | `/api/rh/relatorios` | `recursos-humanos:ver_funcionarios` |
| GET | `/api/rh/presencas` | `recursos-humanos:ver_funcionarios` |

### 5.2 Unidades organizacionais

| Método | Endpoint | Permissão |
|--------|----------|-----------|
| GET | `/api/rh/unidades` | `recursos-humanos:ver_funcionarios` |
| GET | `/api/rh/unidades/{id}` | `recursos-humanos:ver_funcionarios` |
| GET | `/api/rh/unidades/{id}/filhos` | `recursos-humanos:ver_funcionarios` |
| GET | `/api/rh/unidades/{id}/subarvore` | `recursos-humanos:ver_funcionarios` |
| GET | `/api/rh/unidades/{id}/caminho` | `recursos-humanos:ver_funcionarios` |
| GET | `/api/rh/unidades/{id}/funcionarios` | `recursos-humanos:ver_funcionarios` |
| GET | `/api/rh/unidades/{id}/funcionarios/todos` | `recursos-humanos:ver_funcionarios` |
| POST | `/api/rh/unidades` | `recursos-humanos:gerir_funcionarios` |
| PUT | `/api/rh/unidades/{id}` | `recursos-humanos:gerir_funcionarios` |
| DELETE | `/api/rh/unidades/{id}` | `recursos-humanos:gerir_funcionarios` |
| POST | `/api/rh/unidades/{id}/mover` | `recursos-humanos:gerir_funcionarios` |

### 5.3 Configurações RH e IRPS

| Método | Endpoint | Permissão |
|--------|----------|-----------|
| GET | `/api/rh/configuracoes` | `recursos-humanos:ver_funcionarios` |
| GET | `/api/rh/irps-escaloes` | `recursos-humanos:ver_funcionarios` |
| POST | `/api/rh/configuracoes` | `recursos-humanos:gerir_funcionarios` |
| POST | `/api/rh/irps-escaloes` | `recursos-humanos:gerir_funcionarios` |
| POST | `/api/rh/irps-escaloes/seed-mozambique-2024` | `recursos-humanos:gerir_funcionarios` |
| PUT | `/api/rh/irps-escaloes/{id}` | `recursos-humanos:gerir_funcionarios` |
| DELETE | `/api/rh/irps-escaloes/{id}` | `recursos-humanos:gerir_funcionarios` |

### 5.4 Funcionários

| Método | Endpoint | Permissão |
|--------|----------|-----------|
| GET | `/api/rh/funcionarios` | `recursos-humanos:ver_funcionarios` |
| GET | `/api/rh/funcionarios/proximo-numero` | `recursos-humanos:ver_funcionarios` |
| GET | `/api/rh/funcionarios/{id}` | `recursos-humanos:ver_funcionarios` |
| GET | `/api/rh/funcionarios/{id}/nfc-tags` | `recursos-humanos:ver_funcionarios` |
| POST | `/api/rh/funcionarios` | `recursos-humanos:gerir_funcionarios` |
| PUT | `/api/rh/funcionarios/{id}` | `recursos-humanos:gerir_funcionarios` |
| POST | `/api/rh/funcionarios/{id}/desligar` | `recursos-humanos:gerir_funcionarios` |
| POST | `/api/rh/funcionarios/{id}/nfc-tags` | `recursos-humanos:gerir_funcionarios` |
| DELETE | `/api/rh/nfc-tags/{id}` | `recursos-humanos:gerir_funcionarios` |
| POST | `/api/rh/funcionarios/{id}/biometria/facial/enroll` | `recursos-humanos:gerir_funcionarios` |
| GET | `/api/rh/funcionarios/{id}/recibos-vencimento` | `recursos-humanos:ver_recibos` |
| GET | `/api/rh/funcionarios/{id}/historico-salarial` | `recursos-humanos:ver_salarios` |
| GET | `/api/rh/funcionarios/{id}/componentes-salariais` | `recursos-humanos:ver_salarios` |
| POST | `/api/rh/funcionarios/{id}/historico-salarial` | `recursos-humanos:processar_salarios` |
| POST | `/api/rh/funcionarios/{id}/componentes-salariais` | `recursos-humanos:processar_salarios` |
| DELETE | `/api/rh/funcionarios/{id}/componentes-salariais/{componenteId}` | `recursos-humanos:processar_salarios` |
| GET | `/api/rh/funcionarios/{id}/adiantamentos` | `recursos-humanos:processar_salarios` |
| POST | `/api/rh/funcionarios/{id}/adiantamentos` | `recursos-humanos:processar_salarios` |
| GET | `/api/rh/funcionarios/{id}/emprestimos` | `recursos-humanos:processar_salarios` |
| POST | `/api/rh/funcionarios/{id}/emprestimos` | `recursos-humanos:processar_salarios` |
| POST | `/api/rh/funcionarios/adiantamentos/{id}/cancelar` | `recursos-humanos:processar_salarios` |
| POST | `/api/rh/funcionarios/emprestimos/{id}/cancelar` | `recursos-humanos:processar_salarios` |
| GET | `/api/rh/funcionarios/{id}/beneficios` | `recursos-humanos:ver_beneficios` |
| POST | `/api/rh/funcionarios/{id}/beneficios` | `recursos-humanos:gerir_beneficios` |
| DELETE | `/api/rh/funcionarios/{id}/beneficios/{beneficioId}` | `recursos-humanos:gerir_beneficios` |
| GET | `/api/rh/funcionarios/{id}/presencas` | `recursos-humanos:ver_funcionarios` |
| GET | `/api/rh/funcionarios/{id}/saldos-ausencia` | `recursos-humanos:ver_funcionarios` |
| GET | `/api/rh/funcionarios/{id}/eventos` | `recursos-humanos:ver_funcionarios` |
| GET | `/api/rh/funcionarios/{id}/resultados` | `recursos-humanos:ver_funcionarios` |
| POST | `/api/rh/funcionarios/{id}/presencas` | `recursos-humanos:gerir_funcionarios` |
| DELETE | `/api/rh/funcionarios/{id}/presencas/{presencaId}` | `recursos-humanos:gerir_funcionarios` |
| POST | `/api/rh/funcionarios/{id}/saldos-ausencia` | `recursos-humanos:gerir_funcionarios` |
| POST | `/api/rh/funcionarios/{id}/recalcular` | `recursos-humanos:gerir_funcionarios` |
| GET | `/api/rh/funcionarios/{id}/processos-disciplinares` | `recursos-humanos:ver_processos_disciplinares` |
| POST | `/api/rh/funcionarios/{id}/processos-disciplinares` | `recursos-humanos:gerir_funcionarios` |
| PUT | `/api/rh/funcionarios/{id}/processos-disciplinares/{registoId}` | `recursos-humanos:gerir_funcionarios` |
| DELETE | `/api/rh/funcionarios/{id}/processos-disciplinares/{registoId}` | `recursos-humanos:gerir_funcionarios` |
| GET | `/api/rh/funcionarios/{id}/formacoes` | `recursos-humanos:gerir_formacoes` |
| POST | `/api/rh/funcionarios/{id}/formacoes` | `recursos-humanos:gerir_formacoes` |
| PUT | `/api/rh/funcionarios/{id}/formacoes/{registoId}` | `recursos-humanos:gerir_formacoes` |
| DELETE | `/api/rh/funcionarios/{id}/formacoes/{registoId}` | `recursos-humanos:gerir_formacoes` |
| POST | `/api/rh/funcionarios/{id}/formacoes/{registoId}/upload` | `recursos-humanos:gerir_formacoes` |
| GET | `/api/rh/funcionarios/{id}/formacoes/{registoId}/download` | `recursos-humanos:gerir_formacoes` |

### 5.5 Contratos

| Método | Endpoint | Permissão |
|--------|----------|-----------|
| GET | `/api/rh/contratos` | `recursos-humanos:ver_funcionarios` |
| GET | `/api/rh/contratos/{id}` | `recursos-humanos:ver_funcionarios` |
| GET | `/api/rh/contratos/{id}/download` | `recursos-humanos:ver_funcionarios` |
| GET | `/api/rh/contratos/{id}/pdf` | `recursos-humanos:ver_funcionarios` |
| POST | `/api/rh/contratos` | `recursos-humanos:gerir_contratos` |
| PUT | `/api/rh/contratos/{id}` | `recursos-humanos:gerir_contratos` |
| POST | `/api/rh/contratos/{id}/renovar` | `recursos-humanos:gerir_contratos` |
| POST | `/api/rh/contratos/{id}/rescindir` | `recursos-humanos:gerir_contratos` |
| POST | `/api/rh/contratos/{id}/upload` | `recursos-humanos:gerir_contratos` |
| POST | `/api/rh/contratos/{id}/pdf` | `recursos-humanos:gerir_contratos` |
| POST | `/api/rh/contratos/{id}/enviar-para-assinatura` | `recursos-humanos:gerir_contratos` |

### 5.6 Ausências

| Método | Endpoint | Permissão |
|--------|----------|-----------|
| GET | `/api/rh/ausencias` | `recursos-humanos:ver_funcionarios` |
| POST | `/api/rh/ausencias` | `recursos-humanos:aprovar_ausencias` |
| POST | `/api/rh/ausencias/{id}/aprovar` | `recursos-humanos:aprovar_ausencias` |
| POST | `/api/rh/ausencias/{id}/rejeitar` | `recursos-humanos:aprovar_ausencias` |
| POST | `/api/rh/ausencias/{id}/gozar` | `recursos-humanos:aprovar_ausencias` |
| POST | `/api/rh/ausencias/{id}/cancelar` | `recursos-humanos:aprovar_ausencias` |

### 5.7 Correções de ponto

| Método | Endpoint | Permissão |
|--------|----------|-----------|
| GET | `/api/rh/correcoes-ponto` | `assiduidade:aprovar_correcao` |
| POST | `/api/rh/correcoes-ponto/{id}/aprovar` | `assiduidade:aprovar_correcao` |
| POST | `/api/rh/correcoes-ponto/{id}/rejeitar` | `assiduidade:aprovar_correcao` |

### 5.8 Configuração de assiduidade

| Método | Endpoint | Permissão |
|--------|----------|-----------|
| GET | `/api/rh/tipos-evento` | `recursos-humanos:ver_funcionarios` |
| POST | `/api/rh/tipos-evento` | `assiduidade:gerir_configuracao` |
| PUT | `/api/rh/tipos-evento/{id}` | `assiduidade:gerir_configuracao` |
| DELETE | `/api/rh/tipos-evento/{id}` | `assiduidade:gerir_configuracao` |
| GET | `/api/rh/metodos-marcacao` | `recursos-humanos:ver_funcionarios` |
| POST | `/api/rh/metodos-marcacao` | `assiduidade:gerir_configuracao` |
| PUT | `/api/rh/metodos-marcacao/{id}` | `assiduidade:gerir_configuracao` |
| DELETE | `/api/rh/metodos-marcacao/{id}` | `assiduidade:gerir_configuracao` |
| GET | `/api/rh/tipos-regra` | `recursos-humanos:ver_funcionarios` |
| GET | `/api/rh/regras` | `assiduidade:ver_configuracao` |
| POST | `/api/rh/regras` | `assiduidade:gerir_configuracao` |
| PUT | `/api/rh/regras/{id}` | `assiduidade:gerir_configuracao` |
| DELETE | `/api/rh/regras/{id}` | `assiduidade:gerir_configuracao` |
| POST | `/api/rh/eventos` | `recursos-humanos:gerir_funcionarios` |
| POST | `/api/rh/assiduidade/qr/gerar` | `recursos-humanos:ver_funcionarios` |
| POST | `/api/rh/correcoes` | `recursos-humanos:gerir_funcionarios` |
| GET | `/api/rh/correcoes` | `assiduidade:aprovar_correcao` |
| POST | `/api/rh/correcoes/{id}/aprovar` | `assiduidade:aprovar_correcao` |
| POST | `/api/rh/correcoes/{id}/rejeitar` | `assiduidade:aprovar_correcao` |

### 5.9 Tipos de ausência

| Método | Endpoint | Permissão |
|--------|----------|-----------|
| GET | `/api/rh/tipos-ausencia` | `recursos-humanos:ver_funcionarios` |
| POST | `/api/rh/tipos-ausencia` | `recursos-humanos:gerir_funcionarios` |
| PUT | `/api/rh/tipos-ausencia/{id}` | `recursos-humanos:gerir_funcionarios` |
| DELETE | `/api/rh/tipos-ausencia/{id}` | `recursos-humanos:gerir_funcionarios` |

### 5.10 Avaliações de desempenho

| Método | Endpoint | Permissão |
|--------|----------|-----------|
| GET | `/api/rh/avaliacoes` | `recursos-humanos:ver_funcionarios` |
| POST | `/api/rh/avaliacoes` | `recursos-humanos:gerir_avaliacoes` |
| POST | `/api/rh/avaliacoes/{id}/submeter` | `recursos-humanos:gerir_avaliacoes` |
| POST | `/api/rh/avaliacoes/{id}/aprovar` | `recursos-humanos:gerir_avaliacoes` |
| GET | `/api/rh/criterios-avaliacao` | `recursos-humanos:ver_funcionarios` |
| POST | `/api/rh/criterios-avaliacao` | `recursos-humanos:gerir_avaliacoes` |
| PUT | `/api/rh/criterios-avaliacao/{id}` | `recursos-humanos:gerir_avaliacoes` |
| DELETE | `/api/rh/criterios-avaliacao/{id}` | `recursos-humanos:gerir_avaliacoes` |

### 5.11 Períodos

| Método | Endpoint | Permissão |
|--------|----------|-----------|
| GET | `/api/rh/periodos` | `recursos-humanos:ver_funcionarios` |
| POST | `/api/rh/periodos` | `recursos-humanos:processar_salarios` |
| PUT | `/api/rh/periodos/{id}` | `recursos-humanos:processar_salarios` |

### 5.12 Cargos

| Método | Endpoint | Permissão |
|--------|----------|-----------|
| GET | `/api/rh/cargos` | `recursos-humanos:ver_funcionarios` **OU** `recrutamento:gerir_vagas` |
| POST | `/api/rh/cargos` | `recursos-humanos:gerir_funcionarios` |
| PUT | `/api/rh/cargos/{id}` | `recursos-humanos:gerir_funcionarios` |
| DELETE | `/api/rh/cargos/{id}` | `recursos-humanos:gerir_funcionarios` |

### 5.13 Horários

| Método | Endpoint | Permissão |
|--------|----------|-----------|
| GET | `/api/rh/horarios` | `recursos-humanos:ver_funcionarios` |
| POST | `/api/rh/horarios` | `recursos-humanos:gerir_horarios` |
| PUT | `/api/rh/horarios/{id}` | `recursos-humanos:gerir_horarios` |
| DELETE | `/api/rh/horarios/{id}` | `recursos-humanos:gerir_horarios` |

### 5.14 Componentes salariais

| Método | Endpoint | Permissão |
|--------|----------|-----------|
| GET | `/api/rh/componentes-salariais` | `recursos-humanos:ver_funcionarios` |
| POST | `/api/rh/componentes-salariais` | `recursos-humanos:processar_salarios` |
| PUT | `/api/rh/componentes-salariais/{id}` | `recursos-humanos:processar_salarios` |
| DELETE | `/api/rh/componentes-salariais/{id}` | `recursos-humanos:processar_salarios` |

### 5.15 Benefícios

| Método | Endpoint | Permissão |
|--------|----------|-----------|
| GET | `/api/rh/beneficios` | `recursos-humanos:ver_beneficios` |
| POST | `/api/rh/beneficios` | `recursos-humanos:gerir_beneficios` |
| PUT | `/api/rh/beneficios/{id}` | `recursos-humanos:gerir_beneficios` |
| DELETE | `/api/rh/beneficios/{id}` | `recursos-humanos:gerir_beneficios` |

### 5.16 Formações

| Método | Endpoint | Permissão |
|--------|----------|-----------|
| GET | `/api/rh/formacoes` | `recursos-humanos:ver_funcionarios` |
| POST | `/api/rh/formacoes` | `recursos-humanos:gerir_formacoes` |
| PUT | `/api/rh/formacoes/{id}` | `recursos-humanos:gerir_formacoes` |
| DELETE | `/api/rh/formacoes/{id}` | `recursos-humanos:gerir_formacoes` |

### 5.17 Folhas de pagamento

| Método | Endpoint | Permissão |
|--------|----------|-----------|
| GET | `/api/rh/folhas-pagamento` | `recursos-humanos:ver_salarios` |
| GET | `/api/rh/folhas-pagamento/{id}` | `recursos-humanos:ver_salarios` |
| POST | `/api/rh/folhas-pagamento` | `recursos-humanos:processar_salarios` |
| POST | `/api/rh/folhas-pagamento/{id}/processar` | `recursos-humanos:processar_salarios` |
| POST | `/api/rh/folhas-pagamento/{id}/pagar` | `recursos-humanos:processar_salarios` |
| POST | `/api/rh/folhas-pagamento/{id}/cancelar` | `recursos-humanos:processar_salarios` |

### 5.18 Recibos de vencimento

| Método | Endpoint | Permissão |
|--------|----------|-----------|
| GET | `/api/rh/recibos-vencimento/{id}` | `recursos-humanos:ver_recibos` |
| GET | `/api/rh/recibos-vencimento/{id}/pdf` | `recursos-humanos:ver_recibos` |
| POST | `/api/rh/recibos-vencimento/{id}/pdf` | `recursos-humanos:ver_recibos` |

### 5.19 Contactos de emergência

| Método | Endpoint | Permissão |
|--------|----------|-----------|
| POST | `/api/rh/contactos-emergencia` | `recursos-humanos:gerir_funcionarios` |
| DELETE | `/api/rh/contactos-emergencia/{id}` | `recursos-humanos:gerir_funcionarios` |

### 5.20 Documentos

| Método | Endpoint | Permissão |
|--------|----------|-----------|
| GET | `/api/rh/documentos/{id}/download` | `recursos-humanos:ver_funcionarios` |
| POST | `/api/rh/documentos` | `recursos-humanos:gerir_funcionarios` |
| POST | `/api/rh/documentos/{id}/upload` | `recursos-humanos:gerir_funcionarios` |
| DELETE | `/api/rh/documentos/{id}` | `recursos-humanos:gerir_funcionarios` |

### 5.21 Self-service / Assiduidade

| Método | Endpoint | Permissão |
|--------|----------|-----------|
| GET | `/api/self-service/assiduidade` | `assiduidade:ver_assiduidade` |
| GET | `/api/self-service/assiduidade/resumo` | `assiduidade:ver_assiduidade` |
| GET | `/api/self-service/assiduidade/justificacoes` | `assiduidade:ver_assiduidade` |
| GET | `/api/self-service/assiduidade/qr/me` | `assiduidade:ver_assiduidade` |
| POST | `/api/self-service/assiduidade/justificacoes` | `assiduidade:justificar` |
| POST | `/api/self-service/assiduidade/correcoes` | `assiduidade:corrigir_ponto` |
| GET | `/api/self-service/assiduidade/correcoes` | `assiduidade:corrigir_ponto` |
| POST | `/api/self-service/assiduidade/correcoes/{id}/cancelar` | `assiduidade:corrigir_ponto` |

### 5.22 Pedido de férias

| Método | Endpoint | Permissão |
|--------|----------|-----------|
| GET | `/api/pedido-ferias` | `pedido-ferias:ver_pedidos` |
| GET | `/api/pedido-ferias/tipos` | `pedido-ferias:ver_pedidos` |
| POST | `/api/pedido-ferias` | `pedido-ferias:submeter_pedido` |
| POST | `/api/pedido-ferias/{id}/cancelar` | `pedido-ferias:submeter_pedido` |

---

## 6. Recomendação de roles

### 6.1 Gestor de RH (tudo)

```text
recursos-humanos:ver_funcionarios
recursos-humanos:gerir_funcionarios
recursos-humanos:ver_recibos
recursos-humanos:ver_salarios
recursos-humanos:processar_salarios
recursos-humanos:ver_beneficios
recursos-humanos:gerir_beneficios
recursos-humanos:gerir_formacoes
recursos-humanos:gerir_contratos
recursos-humanos:gerir_avaliacoes
recursos-humanos:gerir_horarios
recursos-humanos:aprovar_ausencias
recursos-humanos:ver_processos_disciplinares
assiduidade:ver_configuracao
assiduidade:gerir_configuracao
assiduidade:aprovar_correcao
```

### 6.2 Funcionário (self-service)

```text
assiduidade:ver_assiduidade
assiduidade:justificar
assiduidade:corrigir_ponto
pedido-ferias:ver_pedidos
pedido-ferias:submeter_pedido
perfil:ver_perfil
perfil:editar_perfil
```

### 6.3 Técnico de Payroll

```text
recursos-humanos:ver_funcionarios
recursos-humanos:ver_salarios
recursos-humanos:processar_salarios
recursos-humanos:ver_recibos
recursos-humanos:ver_beneficios
```

---

## 7. Verificar permissões de um utilizador

Podes usar a seguinte query SQL para listar as permissões de um utilizador:

```sql
SELECT DISTINCT p.recurso, p.acao
FROM auth.users u
JOIN autorizacao.user_roles ur ON ur.user_id = u.id
JOIN autorizacao.roles r ON r.id = ur.role_id
JOIN autorizacao.role_permissions rp ON rp.role_id = r.id
JOIN autorizacao.permissions p ON p.id = rp.permission_id
WHERE u.email = LOWER('eleuterio.notico@e258tech.tech')
ORDER BY p.recurso, p.acao;
```

Ou verificar permissões do cargo:

```sql
SELECT modulo, acao
FROM auth.permissoes_cargo
WHERE cargo_id = 102
ORDER BY modulo, acao;
```

---

## 8. Referências

- [Permissões de Assiduidade: ERP vs FaceClock](./permissoes-assiduidade-erp-faceclock.md)
- [Collection Postman RH](../nexora_rh_funcionarios.postman_collection.json)
