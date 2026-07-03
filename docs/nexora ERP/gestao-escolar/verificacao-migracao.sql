-- ============================================================
-- Script de verificação pós-migração do módulo Gestão Escolar
-- Executar após aplicar as migrations 062-067.
-- ============================================================

SET search_path TO gestao_escolar, public;

-- 1. Professores em atribuições sem registo em school_teachers
SELECT 'teacher_assignment_orphan' AS problema, ta.id, ta.teacher_id
FROM school_teacher_assignments ta
LEFT JOIN school_teachers t ON t.id = ta.teacher_id
WHERE ta.teacher_id IS NOT NULL AND t.id IS NULL;

-- 2. Turmas com capacidade excedida
SELECT 'class_over_capacity' AS problema, c.id, c.nome, c.capacidade, COUNT(e.id) AS alunos
FROM school_classes c
LEFT JOIN school_enrollments e ON e.class_id = c.id AND e.status = 'activa'
WHERE c.capacidade > 0
GROUP BY c.id, c.nome, c.capacidade
HAVING COUNT(e.id) > c.capacidade;

-- 3. Alunos com matrículas duplas activas no mesmo ano
SELECT 'duplicate_enrollment' AS problema, tenant_id, school_year_id, student_id, COUNT(*) AS total
FROM school_enrollments
WHERE status = 'activa'
GROUP BY tenant_id, school_year_id, student_id
HAVING COUNT(*) > 1;

-- 4. Matrículas sem school_year_id
SELECT 'enrollment_missing_year' AS problema, id, numero
FROM school_enrollments
WHERE school_year_id IS NULL;

-- 5. Cobranças com status inconsistente
SELECT 'fee_status_inconsistent' AS problema, id, numero, valor_total, valor_pago, desconto, status
FROM school_fees
WHERE status NOT IN ('pendente','emitida','parcial','paga','cancelada')
   OR (status = 'paga' AND (valor_total - desconto) > valor_pago)
   OR (status = 'pendente' AND valor_pago > 0);

-- 6. Professores com carga horária excedida
SELECT 'teacher_overloaded' AS problema, t.id, t.nome_completo, t.carga_horaria_maxima_semanal, workload.total
FROM school_teachers t
JOIN (
    SELECT te.teacher_id, COALESCE(SUM(Extract(EPOCH FROM (ts.hora_fim - ts.hora_inicio)) / 3600), 0)::int AS total
    FROM school_timetable_entries te
    JOIN school_time_slots ts ON ts.id = te.time_slot_id
    WHERE te.activo
    GROUP BY te.teacher_id
) workload ON workload.teacher_id = t.id
WHERE workload.total > t.carga_horaria_maxima_semanal;

-- 7. Horários com conflitos de professor
SELECT 'teacher_schedule_conflict' AS problema, te1.id AS entry_1, te2.id AS entry_2, te1.teacher_id, te1.dia_semana, te1.time_slot_id
FROM school_timetable_entries te1
JOIN school_timetable_entries te2 ON te1.teacher_id = te2.teacher_id
  AND te1.dia_semana = te2.dia_semana
  AND te1.time_slot_id = te2.time_slot_id
  AND te1.school_year_id = te2.school_year_id
  AND te1.id < te2.id
WHERE te1.activo AND te2.activo;

-- 8. Níveis de ensino sem configuração académica
SELECT 'missing_academic_config' AS problema, t.id AS tenant_id, t.nome
FROM saas.tenants t
LEFT JOIN school_academic_config c ON c.tenant_id = t.id
WHERE c.id IS NULL;
