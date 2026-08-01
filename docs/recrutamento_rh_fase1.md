# Fase 1 — Contratação Atómica Recrutamento → RH

**Objetivo:** Criar o endpoint e o fluxo base que transforma um candidato aprovado num funcionário RH, garantindo atomicidade.

## Endpoints

- `POST /api/recrutamento/candidaturas/{id}/contratar`

## Ficheiros alterados

- `internal/modules/recrutamento/handlers/contratar.go`
- `migrations/20260705000002_recrutamento_contratacao_rh.up.sql`
- `migrations/20260705000002_recrutamento_contratacao_rh.down.sql`

## Funcionalidades

1. Validação da candidatura (`estado = 'aprovada'`).
2. Verificação do consentimento de dados do candidato.
3. Resolução/criação da conta em `auth.users`.
4. Geração do número de funcionário segundo configuração do tenant (`rh.prefixo_funcionario`, etc.).
5. Inserção do funcionário em `rh.funcionarios`.
6. Criação do contrato em `rh.contratos`.
7. Marcação da candidatura como `contratado` e ligação via `rh_funcionario_id`.
8. Todo o processo corre dentro de uma transação pgx.

## Migration

- Adiciona o estado `contratado` ao `CHECK` de `recrutamento.candidaturas.estado`.
- Adiciona a coluna `rh_funcionario_id` com FK para `rh.funcionarios(id)`.
- Adiciona `consentimento_dados` e `data_consentimento`.
