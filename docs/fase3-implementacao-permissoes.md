# Fase 3 — Implementação de Granularidade de Permissões

> Data: 2026-07-27

## Resumo

Esta fase corrige mapeamentos errados de permissões no `router.go`, introduz
permissões granulares novas em módulos críticos e reforça a regra de
propriedade/escopo no módulo `recursos-humanos`.

## Alterações realizadas

### 1. Schema — `rh.funcionarios.criado_por`

Migration `backend/migrations/20260727110000_rh_funcionarios_criado_por.up.sql`:

- Adiciona a coluna `criado_por` (bigint) à tabela `rh.funcionarios`.
- Cria índice `idx_funcionarios_criado_por`.
- Faz backfill do campo a partir de `user_id` quando disponível.

A coluna é preenchida automaticamente pelo handler `CriarFuncionario`.

### 2. Novas permissões e backfill

Migration `backend/migrations/20260727120000_permissoes_granulares_fase3.up.sql`:

| Módulo | Permissões novas | Cargos com a permissão |
|---|---|---|
| `crm` | `ver_atividades` | Administrador, Director Comercial, Gestor de Conta, Técnico Comercial |
| `crm` | `eliminar_oportunidades` | Administrador, Director Comercial |
| `faturacao` | `cancelar_documentos` | Administrador, Director Financeiro, Responsável de Faturação |
| `compras` | `receber_mercadoria` | Administrador |
| `compras` | `gerir_devolucoes` | Administrador |
| `compras` | `faturar_compras` | Administrador, Director Financeiro |
| `compras` | `gerir_pagamentos` | Administrador, Director Financeiro |
| `contabilidade` | `estornar_lancamentos` | Administrador, Director Financeiro, Contabilista |
| `contabilidade` | `reabrir_periodo` | Administrador, Director Financeiro |
| `contabilidade` | `fechar_ano_fiscal` | Administrador, Director Financeiro |
| `tesouraria` | `gerir_contas` | Administrador, Director Financeiro, Tesoureiro |
| `recursos-humanos` | `desligar_funcionarios` | Administrador, Director de RH, Gestor de RH |

A migration também cria a função auxiliar
`auth.adicionar_permissoes_granulares_fase3(p_tenant_id)` para manter
futuros tenants sincronizados e aplica o backfill a todos os tenants
existentes.

### 3. `router.go` — mapeamentos corrigidos

- `DELETE /api/crm/oportunidades/{id}` → `crm:eliminar_oportunidades`
- `GET /api/crm/atividades` e `GET /{id}` → `crm:ver_atividades`
- `POST /api/faturacao/orders/{id}/cancelar` → `faturacao:cancelar_documentos`
- `POST /api/faturacao/invoices/{id}/cancelar` → `faturacao:cancelar_documentos`
- `POST /api/tesouraria/contas-bancarias` e `POST /api/tesouraria/caixas` → `tesouraria:gerir_contas`
- `POST /api/tesouraria/movimentos` mantém `tesouraria:gerir_movimentos`
- Compras: rotas de recepção, devolução, faturação e pagamento separadas nas
  novas permissões; `aprovar_pedidos` fica apenas com envio para assinatura.
- Contabilidade:
  - `DELETE /api/contabilidade/journal-entries/{id}` (estorno) → `contabilidade:estornar_lancamentos`
  - `POST /api/contabilidade/fiscal-years/{id}/fechar` → `contabilidade:fechar_ano_fiscal`
  - `POST /api/contabilidade/period-closings/{id}/reabrir` → `contabilidade:reabrir_periodo`

### 4. `recursos-humanos` — regra `podeGerirFuncionario`

Ficheiro `backend/internal/modules/recursos-humanos/handlers/hierarquia.go`:

A regra passou a permitir a gestão de um funcionário quando:

1. O utilizador é `superadmin`; ou
2. O utilizador tem a permissão `recursos-humanos:gerir_funcionarios`; ou
3. O utilizador é o criador do registo (`rh.funcionarios.criado_por`); ou
4. O utilizador é responsável hierárquico (direto ou em unidade ancestral).

Foi adicionada a helper `verificarPodeGerirFuncionario` que valida o URL
param, converte para int64 e responde com erro adequado.

### 5. Handlers de mutação do RH com verificação

A verificação foi aplicada nos handlers que alteram dados de um funcionário
específico:

- `ActualizarFuncionario`
- `DesligarFuncionario`
- `CriarNFCTag`
- `EnrollFacial`
- `CriarConsentimentoFuncionario`
- `CriarPresenca` / `RemoverPresenca`
- `DefinirSaldoAusencia`
- `CriarProcessoDisciplinarFuncionario` / `Actualizar...` / `Remover...`
- `AdicionarFormacaoFuncionario` / `Actualizar...` / `Remover...`
- `CriarAlteracaoSalarial`
- `AdicionarComponenteFuncionario` / `Remover...`
- `CriarAdiantamento` / `CriarEmprestimo`
- `AdicionarBeneficioFuncionario` / `Remover...`
- `CriarContactoEmergencia`
- `CriarDocumento`
- `RecalcularResultadoFuncionario` (já verificava, mantido)

O handler `CriarFuncionario` passou a preencher `criado_por` com o ID do
utilizador autenticado.

## Validação

```bash
cd backend && go build ./...
cd backend && go test ./...
```

Ambos os comandos terminaram com sucesso.

## Notas para futuras fases

- Outras permissões sugeridas na análise (logística, POS, gestão escolar,
  folha de pagamento) permanecem pendentes e podem ser abordadas numa Fase 3b
  ou Fase 4.
- A função `auth.criar_cargos_padrao()` não foi reescrita na íntegra; em vez
disso, a migration cria `auth.adicionar_permissoes_granulares_fase3()` para
sincronização futura. Se se quiser integrar diretamente na criação de cargos,
recomenda-se chamar essa função no final de `auth.criar_cargos_padrao()`.
