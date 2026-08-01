# Fase 3 — Conformidade Legal (Moçambique)

**Objetivo:** Garantir que a contratação respeite a legislação laboral de Moçambique.

## Ficheiros alterados

- `internal/modules/recrutamento/handlers/contratar.go`

## Regras implementadas

1. **Idade mínima legal**
   - Apenas candidatos com 18 anos ou mais podem ser contratados.
   - Menores de 18 anos são rejeitados (o fluxo não suporta autorização de representante legal).

2. **Trabalhadores estrangeiros**
   - Nacionalidade diferente de moçambicana exige:
     - `autorizacao_trabalho` preenchida;
     - `data_validade_autorizacao` futura (não expirada).

3. **Proibição de exames HIV/SIDA**
   - Ficheiros cujo nome contenha `hiv`, `sida`, `aids`, `vih` são rejeitados.
   - Imediatamente retorna `422 Unprocessable Entity`.

4. **Auditoria**
   - Após a contratação é registado um log em `auditoria.audit_logs`:
     - `modulo = 'recrutamento'`
     - `entidade = 'candidatura_contratacao'`
     - `acao = 'contratar'`
     - Detalhes em JSON (candidatura, funcionário, contrato, utilizador).

## Campos legais adicionados ao funcionário

- `nacionalidade`
- `tipo_documento`
- `numero_documento`
