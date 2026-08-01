# Fase 4 — Integração com Gestão Escolar (Professores)

**Objetivo:** Quando um candidato aprovado for contratado para função docente, criar automaticamente o registo de professor.

## Ficheiros alterados

- `internal/modules/recrutamento/handlers/contratar.go`

## Funcionalidades

1. **Flag opcional** no body do endpoint:
   ```json
   {
     "criar_professor": true
   }
   ```

2. **Criação do professor** em `gestao_escolar.school_teachers`:
   - Código gerado automaticamente: `PROF-{numero_funcionario}`.
   - Vinculado ao `user_id` do candidato.
   - Referência ao funcionário RH via `rh_employee_id`.
   - Especialidade preenchida com a área da vaga.
   - Carga horária semanal padrão: 40 horas.

3. **Ajuste de escopo**
   - A `auth.memberships` do utilizador é atualizada para `portal_professor`.

## Retorno

- O campo `teacher_id` é incluído na resposta JSON quando um professor é criado.
