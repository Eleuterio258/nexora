# Análise do Banco de Dados `nexora_erp`

**Data:** 2026-06-28  
**Host:** 127.0.0.1:5432 (Docker container `pg`)  
**Base de dados:** `nexora_erp`  
**Utilizador:** `postgres`  
**Escopo:** Módulo Gestão Escolar + Permissões

---

## 1. Resumo Executivo

O banco `nexora_erp` **está funcional e completo** em termos de schema. Possui:

- **30 schemas**
- **Todas as tabelas do Nexora ERP**, incluindo `gestao_escolar.*` e `auth.*`
- **Tenant `enigma-school` (id=5)** criado e ativo
- **Utilizador `admin@enigmaschool.mz` (id=13)** com tipo `tenant_admin`
- **Módulo Gestão Escolar ativo** para o tenant enigma-school
- **Dados escolares populados**: 141 turmas, 30 professores, 20 disciplinas, 1 ano letivo

**Problemas identificados:**

1. ❌ **Permissões de cargos não alinhadas com o router**: Professor, Secretaria e Tesoureiro têm ações como `frequencia`, `notas`, `matriculas`, `propinas`, mas o router exige `gerir_presencas`, `lancar_notas`, `gerir_matriculas`, `gerir_propinas`.
2. ⚠️ **Dados escolares incompletos**: 0 alunos, 0 matrículas, 0 notas, 0 ocorrências. O módulo tem estrutura mas pouco conteúdo operacional.
3. ⚠️ **Bug confirmado no dashboard**: coluna correta é `status`, não `estado`.

---

## 2. Estrutura do Banco

### Schemas (30)

```
assinaturas, auditoria, auth, autorizacao, centros_custo, clientes, compras,
contabilidade, crm, empresa, empresas, faturacao, financeiro, gestao_escolar,
impostos, logistica, multi_moeda, notifications, pg_toast, pos, produtos, public,
recrutamento, rh, saas, seguranca, sistema_configuracao, stock, tesouraria,
utilizadores
```

### Tabelas do módulo Gestão Escolar (43 tabelas)

| Categoria | Tabelas |
|---|---|
| Estrutura académica | `school_academic_config`, `school_levels`, `school_cycles`, `school_series`, `school_courses`, `school_course_subjects`, `school_subjects`, `school_evaluation_types`, `school_grade_formulas` |
| Ano letivo | `school_years`, `school_terms` |
| Turmas | `school_classes`, `school_teacher_assignments` |
| Pessoas | `school_students`, `school_guardians`, `school_teachers`, `school_student_roles`, `school_teacher_roles` |
| Matrículas | `school_enrollments` |
| Frequências | `school_attendance` |
| Notas | `school_grade_items`, `school_grades`, `school_academic_transcripts`, `school_transcript_subjects` |
| Financeiro escolar | `school_fee_plans`, `school_fees`, `school_payments`, `school_fee_generations`, `school_student_fee_discounts`, `school_financial_config` |
| Horários | `school_time_slots`, `school_timetable_entries` |
| Calendário | `school_calendar_event_types`, `school_calendar_events` |
| Ocorrências | `school_incident_types`, `school_student_incidents`, `school_sanction_types`, `school_student_sanctions`, `school_student_merits` |
| Biblioteca | `school_books`, `school_library_loans` |
| Comunicação | `school_messages` |
| Portal | `portal_sessions` |

---

## 3. Tenant e Utilizador

### Tenants existentes

| id | código | nome | status | plano_id |
|---|---|---|---|---|
| 1 | NXR-001 | Nexora Demo Lda | ativo | 3 |
| 2 | NEXDEMO | Nexora Demo Lda | ativo | 3 |
| 5 | enigma-school | Enigma School | ativo | (null) |

### Utilizador Enigma School

| Campo | Valor |
|---|---|
| id | 13 |
| email | `admin@enigmaschool.mz` |
| nome | Admin Enigma School |
| tipo | `tenant_admin` |
| estado | `ativo` |
| membership | tenant_id=5, cargo_id=2 |

### Módulos ativos para `enigma-school`

```
assinaturas, auditoria, clientes, faturacao, financeiro, gestao-escolar,
notificacoes, recrutamento, recursos-humanos, seguranca, sistema-configuracao,
tesouraria
```

---

## 4. Permissões — Análise Crítica

### Cargos do tenant `enigma-school`

| id | Nome do cargo |
|---|---|
| 2 | Administrador Escolar |
| 3 | Director Pedagógico |
| 4 | Secretaria |
| 5 | Professor |
| 6 | Tesoureiro |

### Permissões atuais vs ações exigidas pelo router

#### Ações exigidas pelo `internal/router/router.go`

```
ver, relatorios, gerir_turmas, gerir_alunos, gerir_matriculas,
gerir_presencas, lancar_notas, gerir_propinas, gerir_biblioteca,
gerir_comunicacao, gerir_horarios, gerir_calendario, gerir_ocorrencias,
portal_aluno
```

#### Permissões por cargo no banco

| Cargo | Permissão escolar atual | Resultado no router |
|---|---|---|
| **Administrador Escolar** | `gestao-escolar \| *` | ✅ Funciona (wildcard) |
| **Director Pedagógico** | `gestao-escolar \| *` | ✅ Funciona (wildcard) |
| **Secretaria** | `gestao-escolar \| matriculas` | ❌ Não funciona (deveria ser `gerir_matriculas`) |
| **Secretaria** | `gestao-escolar \| propinas` | ❌ Não funciona (deveria ser `gerir_propinas`) |
| **Professor** | `gestao-escolar \| frequencia` | ❌ Não funciona (deveria ser `gerir_presencas`) |
| **Professor** | `gestao-escolar \| notas` | ❌ Não funciona (deveria ser `lancar_notas`) |
| **Professor** | `gestao-escolar \| turmas-ver` | ❌ Não funciona (deveria ser `ver`) |
| **Tesoureiro** | `gestao-escolar \| propinas` | ❌ Não funciona (deveria ser `gerir_propinas`) |

### Conclusão sobre permissões

- ✅ **admin@enigmaschool.mz funciona** porque tem wildcard no cargo.
- ❌ **Professor, Secretaria e Tesoureiro não conseguem aceder** às respetivas funcionalidades porque as ações no banco não coincidem com as ações do router.
- A inconsistência está confirmada no lado da **seed de permissões** (migration 066 ou dados de seed).

---

## 5. Dados do Módulo Escolar

### Quantidade de registos no tenant `enigma-school`

| Entidade | Total | Observação |
|---|---|---|
| Anos letivos | 1 | Estrutura base criada |
| Turmas | 141 | ✅ Bem populado |
| Professores | 30 | ✅ Bem populado |
| Disciplinas | 20 | ✅ Criadas |
| Alunos | 0 | ⚠️ Nenhum aluno |
| Matrículas | 0 | ⚠️ Nenhuma matrícula |
| Notas | 0 | ⚠️ Nenhuma nota |
| Ocorrências | 0 | ⚠️ Nenhuma ocorrência |
| Encarregados | 0 | ⚠️ Nenhum encarregado |
| Config financeira | ? | A verificar |

### Estado operacional

O módulo tem **estrutura académica pronta** (turmas, professores, disciplinas), mas ainda **não tem operação real** porque faltam alunos, matrículas, notas e ocorrências.

---

## 6. Bugs Confirmados

### 6.1 Dashboard escolar (`estado` → `status`)

No ficheiro `internal/modules/gestao-escolar/handlers/comunicacao.go`, a query do dashboard usa:

```sql
COUNT(*) FROM school_student_incidents WHERE ... estado='aberto'
```

A coluna correta na tabela `gestao_escolar.school_student_incidents` é:

```sql
status VARCHAR(20) CHECK (status IN ('registada', 'em_analise', 'resolvida', 'arquivada'))
```

**Impacto:** erro em runtime ao carregar o dashboard escolar.

---

## 7. Verificação do Schema vs Migrations

### Estado geral

- ✅ O schema do banco está **alinhado com as migrações do backend Go**.
- ✅ Todas as tabelas do módulo escolar existem.
- ✅ Tabelas de auth (`auth.users`, `auth.sessions`, `auth.cargos`, `auth.memberships`, etc.) existem.
- ✅ Schema `saas` com tenants, planos e módulos ativos existe.

### Nota sobre `auth.users.tenant_id`

A migration `049_link_tenants.sql` assume que `auth.users` tem `tenant_id`, mas na prática a ligação user-tenant é feita pela tabela `auth.memberships`. O backend Go atual (rbac.go) usa `auth.memberships`, pelo que o schema do banco está correto para a versão atual do código.

---

## 8. Recomendações

### Imediatas

1. **Corrigir as permissões dos cargos** para alinhar com as ações do router:
   - `matriculas` → `gerir_matriculas`
   - `propinas` → `gerir_propinas`
   - `frequencia` → `gerir_presencas`
   - `notas` → `lancar_notas`
   - `turmas-ver` → `ver` (ou adicionar `gerir_turmas` se necessário)

2. **Corrigir o bug do dashboard** (`estado` → `status`).

3. **Verificar se o utilizador admin@enigmaschool.mz consegue fazer login** (tipo `tenant_admin` + wildcard deve funcionar).

### Médio prazo

4. **Popular alunos e matrículas** para tornar o módulo operacional.
5. **Revisar a configuração financeira escolar** (`school_financial_config`).
6. **Adicionar testes de integração** ao login e às rotas escolares.

---

## 9. Veredicto Final

| Aspecto | Estado |
|---|---|
| Schema do banco | ✅ Completo e alinhado |
| Tenant enigma-school | ✅ Existe e ativo |
| Utilizador admin@enigmaschool.mz | ✅ Existe e funcional |
| Módulo escolar ativo | ✅ Ativo |
| Permissões do admin | ✅ Wildcard funciona |
| Permissões de outros cargos | ❌ Inconsistentes com router |
| Dados operacionais | ⚠️ Estrutura ok, faltam alunos/matriculas/notas |
| Bugs de runtime | ❌ Dashboard com coluna errada |

**Conclusão:** O banco `nexora_erp` está pronto para uso. O utilizador `admin@enigmaschool.mz` deve conseguir aceder ao módulo Gestão Escolar, mas outros cargos (Professor, Secretaria, Tesoureiro) precisam de correção nas permissões.
