# Fase 3 — Análise de Granularidade de Permissões

> Data: 2026-07-27  
> Baseado em: `backend/internal/router/router.go`

## Resumo executivo

O `router.go` já sofreu uma primeira fase de refinação (ações finas como `emitir_faturas`, `gerir_movimentos`, etc.), mas ainda acumula **mapeamentos errados, permissões genéricas demais e ausência de verificação de propriedade/escopo** em módulos críticos.

## 1. Mapeamentos errados de permissões

| Módulo | Ficheiro/linha | Problema | Prioridade |
|---|---|---|---|
| **CRM / Oportunidades** | `router.go:1669` | `DELETE /api/crm/oportunidades/{id}` usa `crm:eliminar_leads` em vez de `crm:eliminar_oportunidades`. | **Alta** |
| **CRM / Atividades** | `router.go:1676` | `GET /api/crm/atividades` e `GET /{id}` exigem `crm:ver_leads`. | Média |
| **Empresa / Utilizadores** | `router.go:423` | Adicionar/remover utilizadores da empresa usa `empresa:editar_empresa` em vez de `autorizacao:gerir_utilizadores`. | Média |
| **Empresa / Documentos** | `router.go:430` | Enviar documento para assinatura exige `empresa:editar_empresa`. | Média |

## 2. Módulos com apenas uma permissão genérica

### 2.1 Compras — prioridade Alta
`compras:aprovar_pedidos` concentra receber mercadoria, devolver, faturar, pagar e assinar.

Sugestões:
- `compras:receber_mercadoria`
- `compras:gerir_devolucoes`
- `compras:faturar_compras`
- `compras:gerir_pagamentos` / `tesouraria:gerir_movimentos`

### 2.2 Faturação — prioridade Alta
`faturacao:emitir_faturas` concentra criar rascunho, adicionar itens, emitir, **cancelar** e enviar para assinatura.

Sugestão:
- `faturacao:cancelar_documentos` para cancelamentos.

### 2.3 Logística — prioridade Média
Apenas `ver_logistica` / `gerir_entregas`. Separar em motoristas, viaturas, rotas, envios, tracking.

### 2.4 POS — prioridade Média
`pos:operar_pos` cobre venda, abertura/fecho de sessão e cancelamento de vendas. Sugerir `pos:cancelar_vendas`.

### 2.5 Gestão Escolar — estrutura académica — prioridade Média
`gestao-escolar:gerir_turmas` concentra toda a estrutura académica. Sugerir `gerir_estrutura_academica` e `gerir_professores`.

## 3. Endpoints destrutivos/sensíveis com permissão genérica

| Módulo | Endpoint | Permissão atual | Sugestão |
|---|---|---|---|
| **Contabilidade** | Estornar lançamento | `contabilidade:gerir_lancamentos` | `contabilidade:estornar_lancamentos` |
| **Contabilidade** | Reabrir período | `contabilidade:fechar_periodo` | `contabilidade:reabrir_periodo` |
| **Contabilidade** | Fechar ano fiscal | `contabilidade:gerir_periodos` | `contabilidade:fechar_ano_fiscal` |
| **RH** | Processar/pagar/cancelar folha | `recursos-humanos:processar_salarios` | separar ações |
| **RH** | Desligar funcionário | `recursos-humanos:gerir_funcionarios` | `recursos-humanos:desligar_funcionarios` |
| **Faturação** | Cancelar fatura | `faturacao:emitir_faturas` | `faturacao:cancelar_documentos` |
| **Escolar** | Cancelar cobrança | `gestao-escolar:gerir_propinas` | `gestao-escolar:cancelar_cobrancas` |

## 4. Módulo `recursos-humanos` — `podeGerirFuncionario`

A regra atual em `hierarquia.go` verifica superadmin ou responsável hierárquico. **Não inclui** "quem criou o funcionário".

Handlers de mutação por funcionário que não usam `podeGerirFuncionario`:
- desligar, editar ficha, nfc-tags
- histórico salarial, componentes salariais, adiantamentos, empréstimos
- benefícios, presenças, saldos-ausencia
- processos disciplinares, formações
- eventos e correções de assiduidade

## 5. Módulo `tesouraria`

`gerir_movimentos` atualmente permite criar contas bancárias e caixas. Sugerir:
- `tesouraria:gerir_contas` para contas bancárias e caixas.
- `tesouraria:gerir_movimentos` apenas para movimentos.

## 6. Permissões referenciadas mas inexistentes no router

- `faturacao:relatorios`
- `vendas:*`
- `recursos-humanos:ver_relatorios`

## 7. Lista consolidada de permissões novas sugeridas

| Módulo | Novas permissões |
|---|---|
| `crm` | `eliminar_oportunidades`, `ver_atividades` |
| `compras` | `receber_mercadoria`, `gerir_devolucoes`, `faturar_compras`, `gerir_pagamentos` |
| `faturacao` | `cancelar_documentos` |
| `logistica` | `gerir_motoristas`, `gerir_viaturas`, `gerir_rotas`, `gerir_envios`, `gerir_tracking` |
| `pos` | `cancelar_vendas`, `fechar_sessao` |
| `contabilidade` | `estornar_lancamentos`, `reabrir_periodo`, `fechar_ano_fiscal`, `processar_amortizacoes` |
| `tesouraria` | `gerir_contas` |
| `recursos-humanos` | `desligar_funcionarios`, `processar_folha_pagamento`, `pagar_folha_pagamento`, `cancelar_folha_pagamento` |
| `gestao-escolar` | `gerir_estrutura_academica`, `gerir_professores`, `cancelar_cobrancas`, `fechar_ano_lectivo` |

## Notas

- A correção mais urgente é **CRM `eliminar_leads` → `eliminar_oportunidades`** e **separação de permissões em compras e faturação**.
- A maior complexidade está em **RH**: atualizar `podeGerirFuncionario` para incluir "criado por" e aplicá-lo em dezenas de handlers.
