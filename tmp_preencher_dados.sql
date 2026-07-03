SET search_path TO gestao_escolar, public, auth;
BEGIN;

INSERT INTO school_evaluation_types (tenant_id, codigo, nome, padrao, activo) VALUES
  (5, 'TESTE', 'Teste', true, true),
  (5, 'TRABALHO', 'Trabalho', true, true),
  (5, 'EXAME', 'Exame', true, true)
ON CONFLICT (tenant_id, codigo) DO UPDATE SET nome = EXCLUDED.nome, activo = true;


INSERT INTO school_sanction_types (tenant_id, codigo, nome, gravidade, activo) VALUES
  (5, 'ADVERTENCIA', 'Advertencia', 'leve', true),
  (5, 'SUSPENSAO', 'Suspensao', 'grave', true)
ON CONFLICT (tenant_id, codigo) DO UPDATE SET nome = EXCLUDED.nome, activo = true;


INSERT INTO school_calendar_event_types (tenant_id, codigo, nome, cor, impacto_frequencia, dia_todo, activo) VALUES
  (5, 'REUNIAO', 'Reuniao', '#3B82F6', 'nenhum', false, true),
  (5, 'FERIADO', 'Feriado', '#EF4444', 'nao_contabiliza', true, true),
  (5, 'AULA_CAMPO', 'Aula de Campo', '#10B981', 'nenhum', false, true)
ON CONFLICT (tenant_id, codigo) DO UPDATE SET nome = EXCLUDED.nome, activo = true;


DELETE FROM school_grades WHERE grade_item_id IN (SELECT id FROM school_grade_items WHERE class_id = 145);
DELETE FROM school_grade_items WHERE class_id = 145;
DELETE FROM school_attendance WHERE class_id = 145;
DELETE FROM school_payments WHERE school_fee_id IN (SELECT id FROM school_fees WHERE student_id IN (SELECT student_id FROM school_enrollments WHERE class_id = 145));
DELETE FROM school_fees WHERE student_id IN (SELECT student_id FROM school_enrollments WHERE class_id = 145);
DELETE FROM school_library_loans WHERE student_id IN (SELECT student_id FROM school_enrollments WHERE class_id = 145);
DELETE FROM school_student_sanctions WHERE incident_id IN (SELECT id FROM school_student_incidents WHERE student_id IN (SELECT student_id FROM school_enrollments WHERE class_id = 145));
DELETE FROM school_student_incidents WHERE student_id IN (SELECT student_id FROM school_enrollments WHERE class_id = 145);
DELETE FROM school_calendar_events WHERE tenant_id = 5 AND titulo LIKE 'Evento Teste%';
DELETE FROM school_messages WHERE tenant_id = 5 AND titulo LIKE 'Mensagem Teste%';


WITH disciplinas AS (
  SELECT s.id AS subject_id, s.nome
  FROM school_course_subjects scs
  JOIN school_subjects s ON s.id = scs.subject_id
  WHERE scs.tenant_id = 5 AND scs.course_id = 5 AND scs.series_id = 30 AND scs.componente = '1Semestre'
)
INSERT INTO school_grade_items (tenant_id, class_id, subject_id, term_id, nome, tipo, data_avaliacao, nota_maxima, peso, publicado, created_by)
SELECT 5, 145, d.subject_id, 4, 'Teste 1 - ' || d.nome, 'TESTE', DATE '2026-02-15', 20, 0.5, true, 13
FROM disciplinas d
UNION ALL
SELECT 5, 145, d.subject_id, 4, 'Teste 2 - ' || d.nome, 'TESTE', DATE '2026-03-20', 20, 0.5, true, 13
FROM disciplinas d;


INSERT INTO school_grades (tenant_id, grade_item_id, student_id, enrollment_id, nota, observacoes, lancado_por)
SELECT 5, gi.id, e.student_id, e.id, ROUND((8 + random() * 10)::numeric, 1), 'Nota de teste', 13
FROM school_grade_items gi
JOIN school_enrollments e ON e.class_id = gi.class_id AND e.status = 'activa'
WHERE gi.class_id = 145;


    INSERT INTO school_attendance (tenant_id, class_id, student_id, attendance_date, estado, observacoes, created_by, subject_id, enrollment_id)
    SELECT 5, e.class_id, e.student_id, '2026-02-03', CASE WHEN random() < 0.9 THEN 'presente' ELSE 'ausente' END, '', 13, NULL, e.id
    FROM school_enrollments e
    WHERE e.class_id = 145 AND e.status = 'activa';
    

    INSERT INTO school_attendance (tenant_id, class_id, student_id, attendance_date, estado, observacoes, created_by, subject_id, enrollment_id)
    SELECT 5, e.class_id, e.student_id, '2026-02-04', CASE WHEN random() < 0.9 THEN 'presente' ELSE 'ausente' END, '', 13, NULL, e.id
    FROM school_enrollments e
    WHERE e.class_id = 145 AND e.status = 'activa';
    

    INSERT INTO school_attendance (tenant_id, class_id, student_id, attendance_date, estado, observacoes, created_by, subject_id, enrollment_id)
    SELECT 5, e.class_id, e.student_id, '2026-02-05', CASE WHEN random() < 0.9 THEN 'presente' ELSE 'ausente' END, '', 13, NULL, e.id
    FROM school_enrollments e
    WHERE e.class_id = 145 AND e.status = 'activa';
    

    INSERT INTO school_attendance (tenant_id, class_id, student_id, attendance_date, estado, observacoes, created_by, subject_id, enrollment_id)
    SELECT 5, e.class_id, e.student_id, '2026-02-06', CASE WHEN random() < 0.9 THEN 'presente' ELSE 'ausente' END, '', 13, NULL, e.id
    FROM school_enrollments e
    WHERE e.class_id = 145 AND e.status = 'activa';
    

    INSERT INTO school_attendance (tenant_id, class_id, student_id, attendance_date, estado, observacoes, created_by, subject_id, enrollment_id)
    SELECT 5, e.class_id, e.student_id, '2026-02-07', CASE WHEN random() < 0.9 THEN 'presente' ELSE 'ausente' END, '', 13, NULL, e.id
    FROM school_enrollments e
    WHERE e.class_id = 145 AND e.status = 'activa';
    

    INSERT INTO school_attendance (tenant_id, class_id, student_id, attendance_date, estado, observacoes, created_by, subject_id, enrollment_id)
    SELECT 5, e.class_id, e.student_id, '2026-02-08', CASE WHEN random() < 0.9 THEN 'presente' ELSE 'ausente' END, '', 13, NULL, e.id
    FROM school_enrollments e
    WHERE e.class_id = 145 AND e.status = 'activa';
    

    INSERT INTO school_attendance (tenant_id, class_id, student_id, attendance_date, estado, observacoes, created_by, subject_id, enrollment_id)
    SELECT 5, e.class_id, e.student_id, '2026-02-09', CASE WHEN random() < 0.9 THEN 'presente' ELSE 'ausente' END, '', 13, NULL, e.id
    FROM school_enrollments e
    WHERE e.class_id = 145 AND e.status = 'activa';
    

    INSERT INTO school_attendance (tenant_id, class_id, student_id, attendance_date, estado, observacoes, created_by, subject_id, enrollment_id)
    SELECT 5, e.class_id, e.student_id, '2026-02-10', CASE WHEN random() < 0.9 THEN 'presente' ELSE 'ausente' END, '', 13, NULL, e.id
    FROM school_enrollments e
    WHERE e.class_id = 145 AND e.status = 'activa';
    

    INSERT INTO school_attendance (tenant_id, class_id, student_id, attendance_date, estado, observacoes, created_by, subject_id, enrollment_id)
    SELECT 5, e.class_id, e.student_id, '2026-02-11', CASE WHEN random() < 0.9 THEN 'presente' ELSE 'ausente' END, '', 13, NULL, e.id
    FROM school_enrollments e
    WHERE e.class_id = 145 AND e.status = 'activa';
    

    INSERT INTO school_attendance (tenant_id, class_id, student_id, attendance_date, estado, observacoes, created_by, subject_id, enrollment_id)
    SELECT 5, e.class_id, e.student_id, '2026-02-12', CASE WHEN random() < 0.9 THEN 'presente' ELSE 'ausente' END, '', 13, NULL, e.id
    FROM school_enrollments e
    WHERE e.class_id = 145 AND e.status = 'activa';
    

    INSERT INTO school_fees (tenant_id, enrollment_id, numero, descricao, mes_referencia, data_vencimento, valor_total, valor_pago, moeda, status, fee_plan_id, student_id)
    SELECT 5, e.id, 'PROP-' || replace('Janeiro 2026',' ','') || '-' || s.codigo, 'Propina Janeiro 2026', 'Janeiro 2026', '2026-01-15', 5000.00, 0, 'MZN', 'pendente', 1, e.student_id
    FROM school_enrollments e
    JOIN school_students s ON s.id = e.student_id
    WHERE e.class_id = 145 AND e.status = 'activa'
    ON CONFLICT DO NOTHING;
    

    INSERT INTO school_fees (tenant_id, enrollment_id, numero, descricao, mes_referencia, data_vencimento, valor_total, valor_pago, moeda, status, fee_plan_id, student_id)
    SELECT 5, e.id, 'PROP-' || replace('Fevereiro 2026',' ','') || '-' || s.codigo, 'Propina Fevereiro 2026', 'Fevereiro 2026', '2026-02-15', 5000.00, 0, 'MZN', 'pendente', 1, e.student_id
    FROM school_enrollments e
    JOIN school_students s ON s.id = e.student_id
    WHERE e.class_id = 145 AND e.status = 'activa'
    ON CONFLICT DO NOTHING;
    

    INSERT INTO school_fees (tenant_id, enrollment_id, numero, descricao, mes_referencia, data_vencimento, valor_total, valor_pago, moeda, status, fee_plan_id, student_id)
    SELECT 5, e.id, 'PROP-' || replace('Marco 2026',' ','') || '-' || s.codigo, 'Propina Marco 2026', 'Marco 2026', '2026-03-15', 5000.00, 0, 'MZN', 'pendente', 1, e.student_id
    FROM school_enrollments e
    JOIN school_students s ON s.id = e.student_id
    WHERE e.class_id = 145 AND e.status = 'activa'
    ON CONFLICT DO NOTHING;
    

INSERT INTO school_payments (tenant_id, school_fee_id, student_id, external_id, metodo, referencia, valor, moeda, status, conciliado, pago_em, created_by)
SELECT 5, f.id, f.student_id, 'PAY-' || f.numero, 'MPesa', 'REF-' || f.numero, f.valor_total, 'MZN', 'confirmado', true, NOW(), 13
FROM school_fees f
JOIN school_students s ON s.id = f.student_id
WHERE f.mes_referencia IN ('Janeiro 2026', 'Fevereiro 2026')
  AND s.codigo IN (
    SELECT codigo FROM school_students WHERE tenant_id = 5 AND codigo LIKE 'ALU-PFA-2026-%' ORDER BY codigo LIMIT 20
  )
ON CONFLICT DO NOTHING;

UPDATE school_fees f
SET status = 'paga', valor_pago = f.valor_total
WHERE f.id IN (SELECT school_fee_id FROM school_payments WHERE status = 'confirmado');


INSERT INTO school_books (tenant_id, isbn, codigo, titulo, autor, editora, ano_publicacao, categoria, exemplares_total, exemplares_disponiveis, activo)
VALUES
  (5, '978-0000000001', 'LIV-001', 'Matematica Aplicada', 'J. Pedro', 'Editora Alfa', 2020, 'Ciencias', 5, 5, true),
  (5, '978-0000000002', 'LIV-002', 'Geologia Geral', 'A. Silva', 'Editora Beta', 2019, 'Ciencias', 4, 4, true),
  (5, '978-0000000003', 'LIV-003', 'Gestao Ambiental', 'M. Costa', 'Editora Gamma', 2021, 'Ambiente', 3, 3, true),
  (5, '978-0000000004', 'LIV-004', 'Cartografia e SIG', 'R. Santos', 'Editora Delta', 2022, 'Tecnologia', 6, 6, true),
  (5, '978-0000000005', 'LIV-005', 'Topografia Basica', 'L. Ferreira', 'Editora Epsilon', 2018, 'Tecnologia', 4, 4, true),
  (5, '978-0000000006', 'LIV-006', 'Ecologia Geral', 'S. Mendes', 'Editora Zeta', 2020, 'Ambiente', 5, 5, true),
  (5, '978-0000000007', 'LIV-007', 'Direito Ambiental', 'P. Ribeiro', 'Editora Eta', 2021, 'Direito', 3, 3, true),
  (5, '978-0000000008', 'LIV-008', 'Climatologia', 'T. Oliveira', 'Editora Theta', 2019, 'Ciencias', 4, 4, true),
  (5, '978-0000000009', 'LIV-009', 'Hidrologia', 'C. Martins', 'Editora Iota', 2020, 'Ciencias', 3, 3, true),
  (5, '978-0000000010', 'LIV-010', 'Planeamento Urbano', 'F. Sousa', 'Editora Kappa', 2022, 'Planeamento', 5, 5, true)
ON CONFLICT (tenant_id, codigo) DO UPDATE SET titulo = EXCLUDED.titulo, exemplares_total = EXCLUDED.exemplares_total, exemplares_disponiveis = EXCLUDED.exemplares_disponiveis, activo = true;


INSERT INTO school_library_loans (tenant_id, book_id, student_id, borrower_type, borrower_id, emprestado_em, devolucao_prevista, status, observacoes, created_by)
SELECT 5, b.id, s.id, 'aluno', s.id, '2026-02-01', '2026-02-15', 'emprestado', 'Emprestimo de teste', 13
FROM (
  SELECT id FROM school_students WHERE tenant_id = 5 AND codigo LIKE 'ALU-PFA-2026-%' ORDER BY codigo LIMIT 10
) s
CROSS JOIN (
  SELECT id FROM school_books WHERE tenant_id = 5 ORDER BY codigo LIMIT 1
) b
ON CONFLICT DO NOTHING;


WITH alunos_inc AS (
  SELECT e.student_id, e.id AS enrollment_id FROM school_enrollments e WHERE e.class_id = 145 AND e.status = 'activa' ORDER BY e.student_id LIMIT 5
)
INSERT INTO school_student_incidents (tenant_id, school_year_id, student_id, enrollment_id, incident_type_id, reported_by, data_ocorrencia, hora_ocorrencia, local, descricao, testemunhas, status)
SELECT 5, 2, a.student_id, a.enrollment_id, 10, 13, '2026-02-10', '10:00', 'Sala de aula', 'Discusao durante a aula', 'Nenhuma', 'registada'
FROM alunos_inc a
ON CONFLICT DO NOTHING;


INSERT INTO school_student_sanctions (tenant_id, incident_id, sanction_type_id, aplicado_por, data_inicio, data_fim, descricao, cumprida)
SELECT 5, i.id, (SELECT id FROM school_sanction_types WHERE tenant_id = 5 AND codigo = 'ADVERTENCIA' LIMIT 1), 13, '2026-02-11', '2026-02-11', 'Advertencia verbal', true
FROM school_student_incidents i
WHERE i.tenant_id = 5 AND i.student_id IN (SELECT student_id FROM school_enrollments WHERE class_id = 145)
ON CONFLICT DO NOTHING;


INSERT INTO school_calendar_events (tenant_id, school_year_id, event_type_id, titulo, descricao, data_inicio, data_fim, hora_inicio, hora_fim, dia_todo, publico_alvo, publico_alvo_id, created_by)
VALUES
  (5, 2, (SELECT id FROM school_calendar_event_types WHERE tenant_id = 5 AND codigo = 'FERIADO'), 'Evento Teste - Dia da Paz', 'Comemoracao do dia da paz', '2026-10-04', '2026-10-04', NULL, NULL, true, 'todos', NULL, 13),
  (5, 2, (SELECT id FROM school_calendar_event_types WHERE tenant_id = 5 AND codigo = 'AULA_CAMPO'), 'Evento Teste - Aula de Campo', 'Visita de estudo', '2026-03-15', '2026-03-15', '08:00', '12:00', false, 'turma', 145, 13),
  (5, 2, (SELECT id FROM school_calendar_event_types WHERE tenant_id = 5 AND codigo = 'REUNIAO'), 'Evento Teste - Reuniao de Pais', 'Reuniao com encarregados', '2026-02-20', '2026-02-20', '18:00', '20:00', false, 'turma', 145, 13)
ON CONFLICT DO NOTHING;


INSERT INTO school_messages (tenant_id, titulo, conteudo, tipo, audience_type, audience_id, status, publicado_em, created_by)
VALUES
  (5, 'Mensagem Teste - Boas-vindas', 'Bem-vindos ao novo ano lectivo 2026.', 'geral', 'turma', 145, 'publicado', NOW(), 13),
  (5, 'Mensagem Teste - Reuniao', 'Reuniao de pais marcada para 20 de Fevereiro.', 'aviso', 'turma', 145, 'publicado', NOW(), 13),
  (5, 'Mensagem Teste - Propinas', 'Recordamos o pagamento pontual das propinas.', 'financeiro', 'turma', 145, 'publicado', NOW(), 13)
ON CONFLICT DO NOTHING;

COMMIT;