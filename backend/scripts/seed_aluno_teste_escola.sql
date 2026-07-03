BEGIN;

DO $$
DECLARE
    v_tenant_id bigint;
    v_student_user_id bigint;
    v_guardian_user_id bigint;
    v_password_hash text;
    v_year_id bigint;
    v_term1_id bigint;
    v_term2_id bigint;
    v_level_id bigint;
    v_series_id bigint;
    v_course_id bigint;
    v_math_id bigint;
    v_geo_id bigint;
    v_env_id bigint;
    v_teacher_math_id bigint;
    v_teacher_geo_id bigint;
    v_class_id bigint;
    v_student_id bigint;
    v_guardian_id bigint;
    v_enrollment_id bigint;
    v_slot1_id bigint;
    v_slot2_id bigint;
    v_slot3_id bigint;
    v_grade_item_math_id bigint;
    v_grade_item_geo_id bigint;
    v_fee_plan_id bigint;
    v_fee_june_id bigint;
    v_fee_july_id bigint;
    v_book_id bigint;
    v_incident_type_id bigint;
    v_event_type_id bigint;
BEGIN
    SELECT id INTO v_tenant_id
      FROM saas.tenants
     WHERE codigo = 'enigma-school'
     ORDER BY id
     LIMIT 1;

    IF v_tenant_id IS NULL THEN
        INSERT INTO saas.tenants (codigo, nome, status, limite_utilizadores, limite_armazenamento_gb, metadata)
        VALUES ('enigma-school', 'Instituto Politecnico de Ciencias da Terra e Ambiente', 'ativo', 200, 50,
                '{"tipo":"escola","seed":"aluno_teste"}'::jsonb)
        RETURNING id INTO v_tenant_id;
    ELSE
        UPDATE saas.tenants
           SET nome = 'Instituto Politecnico de Ciencias da Terra e Ambiente',
               metadata = COALESCE(metadata, '{}'::jsonb) || '{"tipo":"escola","seed":"aluno_teste"}'::jsonb,
               updated_at = NOW()
         WHERE id = v_tenant_id;
    END IF;

    SELECT id, password_hash INTO v_student_user_id, v_password_hash
      FROM auth.users
     WHERE LOWER(email) = LOWER('aluno.teste@nexora.test')
     LIMIT 1;

    IF v_student_user_id IS NULL THEN
        RAISE EXCEPTION 'Utilizador aluno.teste@nexora.test nao existe. Crie o utilizador do aluno antes de executar este seed.';
    END IF;

    INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
    VALUES ('Maria Constantino', 'encarregado.teste@nexora.test', v_password_hash, '258841112222', 'ativo', true, 'encarregado')
    ON CONFLICT (email) DO UPDATE
        SET nome = EXCLUDED.nome,
            telefone = EXCLUDED.telefone,
            estado = 'ativo',
            tipo = 'encarregado',
            updated_at = NOW()
    RETURNING id INTO v_guardian_user_id;

    INSERT INTO gestao_escolar.school_years (tenant_id, codigo, nome, data_inicio, data_fim, status, created_by)
    VALUES (v_tenant_id, '2026', 'Ano Lectivo 2026', DATE '2026-01-15', DATE '2026-12-15', 'activo', v_student_user_id)
    ON CONFLICT (tenant_id, codigo) DO UPDATE
        SET nome = EXCLUDED.nome,
            data_inicio = EXCLUDED.data_inicio,
            data_fim = EXCLUDED.data_fim,
            status = 'activo',
            updated_at = NOW()
    RETURNING id INTO v_year_id;

    INSERT INTO gestao_escolar.school_terms (tenant_id, school_year_id, codigo, nome, data_inicio, data_fim, peso)
    VALUES (v_tenant_id, v_year_id, 'T1', '1o Trimestre', DATE '2026-01-15', DATE '2026-04-30', 1)
    ON CONFLICT (tenant_id, school_year_id, codigo) DO UPDATE
        SET nome = EXCLUDED.nome,
            data_inicio = EXCLUDED.data_inicio,
            data_fim = EXCLUDED.data_fim
    RETURNING id INTO v_term1_id;

    INSERT INTO gestao_escolar.school_terms (tenant_id, school_year_id, codigo, nome, data_inicio, data_fim, peso)
    VALUES (v_tenant_id, v_year_id, 'T2', '2o Trimestre', DATE '2026-05-01', DATE '2026-08-30', 1)
    ON CONFLICT (tenant_id, school_year_id, codigo) DO UPDATE
        SET nome = EXCLUDED.nome,
            data_inicio = EXCLUDED.data_inicio,
            data_fim = EXCLUDED.data_fim
    RETURNING id INTO v_term2_id;

    INSERT INTO gestao_escolar.school_levels
        (tenant_id, codigo, nome, descricao, ordem, nota_minima_aprovacao, escala_maxima, sistema_avaliacao,
         numero_periodos_padrao, nomenclatura_periodo, nomenclatura_serie, idade_minima, idade_maxima)
    VALUES
        (v_tenant_id, 'tecnico_medio_ambiente', 'Ensino Tecnico Medio',
         'Formacao tecnico-profissional em ciencias da terra e ambiente.', 1, 10, 20, '0-20', 3,
         'trimestre', 'ano', 15, 25)
    ON CONFLICT (tenant_id, codigo) DO UPDATE
        SET nome = EXCLUDED.nome,
            descricao = EXCLUDED.descricao,
            updated_at = NOW()
    RETURNING id INTO v_level_id;

    INSERT INTO gestao_escolar.school_series (tenant_id, level_id, codigo, nome, ordem)
    VALUES (v_tenant_id, v_level_id, '1ANO', '1o Ano', 1)
    ON CONFLICT (tenant_id, level_id, codigo) DO UPDATE
        SET nome = EXCLUDED.nome
    RETURNING id INTO v_series_id;

    INSERT INTO gestao_escolar.school_courses
        (tenant_id, level_id, codigo, nome, descricao, duracao_anos, modalidade, grau)
    VALUES
        (v_tenant_id, v_level_id, 'CTA', 'Ciencias da Terra e Ambiente',
         'Curso tecnico medio voltado para ambiente, geologia aplicada e sustentabilidade.', 3, 'presencial', 'Tecnico Medio')
    ON CONFLICT (tenant_id, codigo) DO UPDATE
        SET nome = EXCLUDED.nome,
            descricao = EXCLUDED.descricao,
            updated_at = NOW()
    RETURNING id INTO v_course_id;

    INSERT INTO gestao_escolar.school_subjects (tenant_id, codigo, nome, descricao, carga_horaria, nota_minima, created_by)
    VALUES
        (v_tenant_id, 'MAT-CTA', 'Matematica Aplicada', 'Base quantitativa para ciencias da terra.', 4, 10, v_student_user_id)
    ON CONFLICT (tenant_id, codigo) DO UPDATE
        SET nome = EXCLUDED.nome,
            descricao = EXCLUDED.descricao,
            carga_horaria = EXCLUDED.carga_horaria,
            updated_at = NOW()
    RETURNING id INTO v_math_id;

    INSERT INTO gestao_escolar.school_subjects (tenant_id, codigo, nome, descricao, carga_horaria, nota_minima, created_by)
    VALUES
        (v_tenant_id, 'GEO-CTA', 'Geologia Geral', 'Introducao a processos geologicos e leitura do terreno.', 3, 10, v_student_user_id)
    ON CONFLICT (tenant_id, codigo) DO UPDATE
        SET nome = EXCLUDED.nome,
            descricao = EXCLUDED.descricao,
            carga_horaria = EXCLUDED.carga_horaria,
            updated_at = NOW()
    RETURNING id INTO v_geo_id;

    INSERT INTO gestao_escolar.school_subjects (tenant_id, codigo, nome, descricao, carga_horaria, nota_minima, created_by)
    VALUES
        (v_tenant_id, 'AMB-CTA', 'Gestao Ambiental', 'Fundamentos de avaliacao e gestao ambiental.', 3, 10, v_student_user_id)
    ON CONFLICT (tenant_id, codigo) DO UPDATE
        SET nome = EXCLUDED.nome,
            descricao = EXCLUDED.descricao,
            carga_horaria = EXCLUDED.carga_horaria,
            updated_at = NOW()
    RETURNING id INTO v_env_id;

    INSERT INTO gestao_escolar.school_course_subjects
        (tenant_id, course_id, level_id, series_id, subject_id, obrigatoria, carga_horaria_semanal, componente)
    VALUES
        (v_tenant_id, v_course_id, v_level_id, v_series_id, v_math_id, true, 4, 'teorica'),
        (v_tenant_id, v_course_id, v_level_id, v_series_id, v_geo_id, true, 3, 'teorica'),
        (v_tenant_id, v_course_id, v_level_id, v_series_id, v_env_id, true, 3, 'teorica')
    ON CONFLICT (tenant_id, course_id, series_id, subject_id) DO UPDATE
        SET carga_horaria_semanal = EXCLUDED.carga_horaria_semanal,
            componente = EXCLUDED.componente,
            activo = true;

    INSERT INTO gestao_escolar.school_teachers
        (tenant_id, codigo, nome_completo, genero, telefone, email, documento_identificacao, especialidade, carga_horaria_maxima_semanal, status)
    VALUES
        (v_tenant_id, 'PROF-MAT-001', 'Antonio Silva', 'M', '258842220001', 'professor.matematica@nexora.test', 'BI-MAT-001', 'Matematica Aplicada', 24, 'activo')
    ON CONFLICT (tenant_id, codigo) DO UPDATE
        SET nome_completo = EXCLUDED.nome_completo,
            telefone = EXCLUDED.telefone,
            email = EXCLUDED.email,
            especialidade = EXCLUDED.especialidade,
            status = 'activo',
            updated_at = NOW()
    RETURNING id INTO v_teacher_math_id;

    INSERT INTO gestao_escolar.school_teachers
        (tenant_id, codigo, nome_completo, genero, telefone, email, documento_identificacao, especialidade, carga_horaria_maxima_semanal, status)
    VALUES
        (v_tenant_id, 'PROF-GEO-001', 'Helena Mucavele', 'F', '258842220002', 'professor.geologia@nexora.test', 'BI-GEO-001', 'Geologia e Ambiente', 24, 'activo')
    ON CONFLICT (tenant_id, codigo) DO UPDATE
        SET nome_completo = EXCLUDED.nome_completo,
            telefone = EXCLUDED.telefone,
            email = EXCLUDED.email,
            especialidade = EXCLUDED.especialidade,
            status = 'activo',
            updated_at = NOW()
    RETURNING id INTO v_teacher_geo_id;

    UPDATE gestao_escolar.school_classes
       SET nome = 'Ciencias da Terra e Ambiente - 1o Ano A',
           school_year_id = v_year_id,
           level_id = v_level_id,
           series_id = v_series_id,
           course_id = v_course_id,
           nivel = 'Ensino Tecnico Medio',
           ano_lectivo = '2026',
           turma = 'A',
           turno = 'manha',
           sala = 'Sala 12',
           capacidade = 35,
           director_teacher_id = v_teacher_geo_id,
           activo = true,
           updated_at = NOW()
     WHERE tenant_id = v_tenant_id
       AND codigo = 'CTA-1A-2026'
     RETURNING id INTO v_class_id;

    IF v_class_id IS NULL THEN
        INSERT INTO gestao_escolar.school_classes
            (tenant_id, school_year_id, level_id, series_id, course_id, codigo, nome, nivel, ano_lectivo, turma,
             turno, sala, capacidade, director_teacher_id, horario)
        VALUES
            (v_tenant_id, v_year_id, v_level_id, v_series_id, v_course_id, 'CTA-1A-2026', 'Ciencias da Terra e Ambiente - 1o Ano A',
             'Ensino Tecnico Medio', '2026', 'A', 'manha', 'Sala 12', 35, v_teacher_geo_id, '[]'::jsonb)
        RETURNING id INTO v_class_id;
    END IF;

    UPDATE gestao_escolar.school_students
       SET tenant_id = v_tenant_id,
           user_id = v_student_user_id,
           codigo = 'ALU-TEST-001',
           nome = 'Aluno Teste',
           data_nascimento = DATE '2010-01-15',
           genero = 'M',
           encarregado_nome = 'Maria Constantino',
           encarregado_telefone = '258841112222',
           encarregado_email = 'encarregado.teste@nexora.test',
           estado = 'activo',
           documento_tipo = 'BI',
           documento_numero = '110100000001A',
           nuit = '400000001',
           telefone = '258842345678',
           email = 'aluno.teste@nexora.test',
           endereco = 'Bairro Central, Maputo',
           portal_email = 'aluno.teste@nexora.test',
           portal_ativo = true,
           portal_login_tentativas = 0,
           portal_bloqueado_ate = NULL,
           updated_at = NOW()
     WHERE user_id = v_student_user_id
        OR LOWER(email) = LOWER('aluno.teste@nexora.test')
        OR LOWER(portal_email) = LOWER('aluno.teste@nexora.test')
     RETURNING id INTO v_student_id;

    IF v_student_id IS NULL THEN
        INSERT INTO gestao_escolar.school_students
            (tenant_id, user_id, codigo, nome, data_nascimento, genero, encarregado_nome, encarregado_telefone,
             encarregado_email, estado, documento_tipo, documento_numero, nuit, telefone, email, endereco,
             portal_email, portal_ativo, portal_login_tentativas)
        VALUES
            (v_tenant_id, v_student_user_id, 'ALU-TEST-001', 'Aluno Teste', DATE '2010-01-15', 'M', 'Maria Constantino',
             '258841112222', 'encarregado.teste@nexora.test', 'activo', 'BI', '110100000001A', '400000001',
             '258842345678', 'aluno.teste@nexora.test', 'Bairro Central, Maputo',
             'aluno.teste@nexora.test', true, 0)
        RETURNING id INTO v_student_id;
    END IF;

    INSERT INTO gestao_escolar.school_guardians
        (tenant_id, student_id, nome, parentesco, telefone, email, nuit, endereco, principal, autorizado_recolher,
         user_id, portal_email, portal_ativo, portal_email_verificado, portal_login_tentativas)
    SELECT v_tenant_id, v_student_id, 'Maria Constantino', 'Mae', '258841112222', 'encarregado.teste@nexora.test',
           '500000001', 'Bairro Central, Maputo', true, true, v_guardian_user_id,
           'encarregado.teste@nexora.test', true, true, 0
    WHERE NOT EXISTS (
        SELECT 1 FROM gestao_escolar.school_guardians
         WHERE tenant_id = v_tenant_id AND student_id = v_student_id AND LOWER(email) = LOWER('encarregado.teste@nexora.test')
    )
    RETURNING id INTO v_guardian_id;

    IF v_guardian_id IS NULL THEN
        UPDATE gestao_escolar.school_guardians
           SET nome = 'Maria Constantino',
               parentesco = 'Mae',
               telefone = '258841112222',
               principal = true,
               autorizado_recolher = true,
               user_id = v_guardian_user_id,
               portal_email = 'encarregado.teste@nexora.test',
               portal_ativo = true,
               portal_email_verificado = true
         WHERE tenant_id = v_tenant_id AND student_id = v_student_id AND LOWER(email) = LOWER('encarregado.teste@nexora.test')
         RETURNING id INTO v_guardian_id;
    END IF;

    UPDATE gestao_escolar.school_enrollments
       SET class_id = v_class_id,
           numero = 'MAT-CTA-2026-0001',
           status = 'activa',
           observacoes = 'Matricula de teste completa para validacao do portal do aluno.',
           updated_at = NOW()
     WHERE tenant_id = v_tenant_id
       AND school_year_id = v_year_id
       AND student_id = v_student_id
     RETURNING id INTO v_enrollment_id;

    IF v_enrollment_id IS NULL THEN
        INSERT INTO gestao_escolar.school_enrollments
            (tenant_id, school_year_id, student_id, class_id, numero, data_matricula, status, observacoes, created_by)
        VALUES
            (v_tenant_id, v_year_id, v_student_id, v_class_id, 'MAT-CTA-2026-0001', DATE '2026-01-20', 'activa',
             'Matricula de teste completa para validacao do portal do aluno.', v_student_user_id)
        RETURNING id INTO v_enrollment_id;
    END IF;

    INSERT INTO gestao_escolar.school_time_slots (tenant_id, codigo, nome, hora_inicio, hora_fim, ordem)
    VALUES
        (v_tenant_id, 'm1', '1a Aula', TIME '07:30', TIME '08:15', 1)
    ON CONFLICT (tenant_id, codigo) DO UPDATE
        SET nome = EXCLUDED.nome, hora_inicio = EXCLUDED.hora_inicio, hora_fim = EXCLUDED.hora_fim, ordem = EXCLUDED.ordem
    RETURNING id INTO v_slot1_id;

    INSERT INTO gestao_escolar.school_time_slots (tenant_id, codigo, nome, hora_inicio, hora_fim, ordem)
    VALUES
        (v_tenant_id, 'm2', '2a Aula', TIME '08:20', TIME '09:05', 2)
    ON CONFLICT (tenant_id, codigo) DO UPDATE
        SET nome = EXCLUDED.nome, hora_inicio = EXCLUDED.hora_inicio, hora_fim = EXCLUDED.hora_fim, ordem = EXCLUDED.ordem
    RETURNING id INTO v_slot2_id;

    INSERT INTO gestao_escolar.school_time_slots (tenant_id, codigo, nome, hora_inicio, hora_fim, ordem)
    VALUES
        (v_tenant_id, 'm3', '3a Aula', TIME '09:10', TIME '09:55', 3)
    ON CONFLICT (tenant_id, codigo) DO UPDATE
        SET nome = EXCLUDED.nome, hora_inicio = EXCLUDED.hora_inicio, hora_fim = EXCLUDED.hora_fim, ordem = EXCLUDED.ordem
    RETURNING id INTO v_slot3_id;

    INSERT INTO gestao_escolar.school_timetable_entries
        (tenant_id, school_year_id, class_id, subject_id, teacher_id, time_slot_id, dia_semana, sala, data_inicio, activo)
    VALUES
        (v_tenant_id, v_year_id, v_class_id, v_math_id, v_teacher_math_id, v_slot1_id, 1, 'Sala 12', DATE '2026-01-15', true),
        (v_tenant_id, v_year_id, v_class_id, v_geo_id, v_teacher_geo_id, v_slot2_id, 2, 'Lab Geologia', DATE '2026-01-15', true),
        (v_tenant_id, v_year_id, v_class_id, v_env_id, v_teacher_geo_id, v_slot3_id, 3, 'Sala 12', DATE '2026-01-15', true)
    ON CONFLICT (tenant_id, school_year_id, class_id, dia_semana, time_slot_id) DO UPDATE
        SET subject_id = EXCLUDED.subject_id,
            teacher_id = EXCLUDED.teacher_id,
            sala = EXCLUDED.sala,
            activo = true,
            updated_at = NOW();

    INSERT INTO gestao_escolar.school_teacher_assignments
        (tenant_id, school_year_id, class_id, subject_id, teacher_id, data_inicio, activo)
    SELECT v_tenant_id, v_year_id, v_class_id, x.subject_id, x.teacher_id, DATE '2026-01-15', true
    FROM (VALUES (v_math_id, v_teacher_math_id), (v_geo_id, v_teacher_geo_id), (v_env_id, v_teacher_geo_id)) AS x(subject_id, teacher_id)
    WHERE NOT EXISTS (
        SELECT 1 FROM gestao_escolar.school_teacher_assignments a
        WHERE a.tenant_id = v_tenant_id AND a.school_year_id = v_year_id AND a.class_id = v_class_id
          AND a.subject_id = x.subject_id AND a.teacher_id = x.teacher_id
    );

    INSERT INTO gestao_escolar.school_grade_items
        (tenant_id, class_id, subject_id, term_id, nome, tipo, data_avaliacao, nota_maxima, peso, publicado, created_by)
    SELECT v_tenant_id, v_class_id, v_math_id, v_term1_id, 'Teste 1 - Matematica Aplicada', 'teste', DATE '2026-03-10', 20, 1, true, v_student_user_id
    WHERE NOT EXISTS (
        SELECT 1 FROM gestao_escolar.school_grade_items
        WHERE tenant_id = v_tenant_id AND class_id = v_class_id AND subject_id = v_math_id AND term_id = v_term1_id AND nome = 'Teste 1 - Matematica Aplicada'
    )
    RETURNING id INTO v_grade_item_math_id;

    IF v_grade_item_math_id IS NULL THEN
        SELECT id INTO v_grade_item_math_id FROM gestao_escolar.school_grade_items
        WHERE tenant_id = v_tenant_id AND class_id = v_class_id AND subject_id = v_math_id AND term_id = v_term1_id AND nome = 'Teste 1 - Matematica Aplicada'
        LIMIT 1;
    END IF;

    INSERT INTO gestao_escolar.school_grade_items
        (tenant_id, class_id, subject_id, term_id, nome, tipo, data_avaliacao, nota_maxima, peso, publicado, created_by)
    SELECT v_tenant_id, v_class_id, v_geo_id, v_term1_id, 'Trabalho de Campo - Geologia', 'trabalho', DATE '2026-03-18', 20, 1, true, v_student_user_id
    WHERE NOT EXISTS (
        SELECT 1 FROM gestao_escolar.school_grade_items
        WHERE tenant_id = v_tenant_id AND class_id = v_class_id AND subject_id = v_geo_id AND term_id = v_term1_id AND nome = 'Trabalho de Campo - Geologia'
    )
    RETURNING id INTO v_grade_item_geo_id;

    IF v_grade_item_geo_id IS NULL THEN
        SELECT id INTO v_grade_item_geo_id FROM gestao_escolar.school_grade_items
        WHERE tenant_id = v_tenant_id AND class_id = v_class_id AND subject_id = v_geo_id AND term_id = v_term1_id AND nome = 'Trabalho de Campo - Geologia'
        LIMIT 1;
    END IF;

    INSERT INTO gestao_escolar.school_grades
        (tenant_id, grade_item_id, student_id, enrollment_id, nota, observacoes, lancado_por)
    SELECT v_tenant_id, v_grade_item_math_id, v_student_id, v_enrollment_id, 15.50, 'Bom dominio dos calculos aplicados.', v_student_user_id
    WHERE NOT EXISTS (
        SELECT 1 FROM gestao_escolar.school_grades
        WHERE tenant_id = v_tenant_id AND grade_item_id = v_grade_item_math_id AND student_id = v_student_id
    );

    INSERT INTO gestao_escolar.school_grades
        (tenant_id, grade_item_id, student_id, enrollment_id, nota, observacoes, lancado_por)
    SELECT v_tenant_id, v_grade_item_geo_id, v_student_id, v_enrollment_id, 17.00, 'Excelente participacao no trabalho de campo.', v_student_user_id
    WHERE NOT EXISTS (
        SELECT 1 FROM gestao_escolar.school_grades
        WHERE tenant_id = v_tenant_id AND grade_item_id = v_grade_item_geo_id AND student_id = v_student_id
    );

    INSERT INTO gestao_escolar.school_attendance
        (tenant_id, class_id, student_id, subject_id, enrollment_id, attendance_date, estado, observacoes, created_by)
    SELECT v_tenant_id, v_class_id, v_student_id, v_math_id, v_enrollment_id, DATE '2026-06-24', 'presente', 'Presente na aula de Matematica.', v_student_user_id
    WHERE NOT EXISTS (
        SELECT 1 FROM gestao_escolar.school_attendance
        WHERE tenant_id = v_tenant_id AND student_id = v_student_id AND subject_id = v_math_id AND attendance_date = DATE '2026-06-24'
    );

    INSERT INTO gestao_escolar.school_attendance
        (tenant_id, class_id, student_id, subject_id, enrollment_id, attendance_date, estado, observacoes, created_by)
    SELECT v_tenant_id, v_class_id, v_student_id, v_geo_id, v_enrollment_id, DATE '2026-06-25', 'justificado', 'Falta justificada por consulta medica.', v_student_user_id
    WHERE NOT EXISTS (
        SELECT 1 FROM gestao_escolar.school_attendance
        WHERE tenant_id = v_tenant_id AND student_id = v_student_id AND subject_id = v_geo_id AND attendance_date = DATE '2026-06-25'
    );

    INSERT INTO gestao_escolar.school_fee_plans
        (tenant_id, school_year_id, codigo, nome, tipo, valor, moeda, periodicidade, dia_vencimento, classe_nivel, created_by)
    VALUES
        (v_tenant_id, v_year_id, 'PROP-CTA-2026', 'Propina Mensal - Ciencias da Terra e Ambiente', 'propina', 3500.00, 'MZN', 'mensal', 10, '1o Ano', v_student_user_id)
    ON CONFLICT (tenant_id, codigo) DO UPDATE
        SET nome = EXCLUDED.nome,
            valor = EXCLUDED.valor,
            school_year_id = EXCLUDED.school_year_id,
            updated_at = NOW()
    RETURNING id INTO v_fee_plan_id;

    INSERT INTO gestao_escolar.school_fees
        (tenant_id, enrollment_id, fee_plan_id, student_id, numero, descricao, mes_referencia, data_vencimento,
         valor_total, valor_pago, desconto, moeda, status, entidade, referencia, emitida_em)
    SELECT v_tenant_id, v_enrollment_id, v_fee_plan_id, v_student_id, 'FEE-CTA-2026-06-0001',
           'Propina de Junho 2026', '2026-06', DATE '2026-06-10', 3500.00, 3500.00, 0, 'MZN', 'paga',
           '10001', '900000001', NOW()
    WHERE NOT EXISTS (
        SELECT 1 FROM gestao_escolar.school_fees WHERE tenant_id = v_tenant_id AND numero = 'FEE-CTA-2026-06-0001'
    )
    RETURNING id INTO v_fee_june_id;

    IF v_fee_june_id IS NULL THEN
        SELECT id INTO v_fee_june_id FROM gestao_escolar.school_fees WHERE tenant_id = v_tenant_id AND numero = 'FEE-CTA-2026-06-0001' LIMIT 1;
    END IF;

    INSERT INTO gestao_escolar.school_fees
        (tenant_id, enrollment_id, fee_plan_id, student_id, numero, descricao, mes_referencia, data_vencimento,
         valor_total, valor_pago, desconto, moeda, status, entidade, referencia, emitida_em)
    SELECT v_tenant_id, v_enrollment_id, v_fee_plan_id, v_student_id, 'FEE-CTA-2026-07-0001',
           'Propina de Julho 2026', '2026-07', DATE '2026-07-10', 3500.00, 0, 0, 'MZN', 'emitida',
           '10001', '900000002', NOW()
    WHERE NOT EXISTS (
        SELECT 1 FROM gestao_escolar.school_fees WHERE tenant_id = v_tenant_id AND numero = 'FEE-CTA-2026-07-0001'
    )
    RETURNING id INTO v_fee_july_id;

    IF v_fee_july_id IS NULL THEN
        SELECT id INTO v_fee_july_id FROM gestao_escolar.school_fees WHERE tenant_id = v_tenant_id AND numero = 'FEE-CTA-2026-07-0001' LIMIT 1;
    END IF;

    INSERT INTO gestao_escolar.school_payments
        (tenant_id, school_fee_id, student_id, external_id, metodo, referencia, valor, moeda, status, conciliado, created_by)
    SELECT v_tenant_id, v_fee_june_id, v_student_id, 'PAY-CTA-2026-06-0001', 'mpesa', '900000001', 3500.00, 'MZN', 'confirmado', true, v_student_user_id
    WHERE NOT EXISTS (
        SELECT 1 FROM gestao_escolar.school_payments WHERE tenant_id = v_tenant_id AND external_id = 'PAY-CTA-2026-06-0001'
    );

    INSERT INTO gestao_escolar.school_messages
        (tenant_id, titulo, conteudo, tipo, audience_type, audience_id, status, publicado_em, created_by)
    SELECT v_tenant_id, 'Boas-vindas ao ano lectivo 2026',
           'Caro aluno, seja bem-vindo ao curso de Ciencias da Terra e Ambiente. Consulte o horario e acompanhe as avaliacoes pelo portal.',
           'aviso', 'aluno', v_student_id, 'publicado', NOW(), v_student_user_id
    WHERE NOT EXISTS (
        SELECT 1 FROM gestao_escolar.school_messages
        WHERE tenant_id = v_tenant_id AND titulo = 'Boas-vindas ao ano lectivo 2026' AND audience_type = 'aluno' AND audience_id = v_student_id
    );

    INSERT INTO gestao_escolar.school_calendar_event_types (tenant_id, codigo, nome, cor, impacto_frequencia, dia_todo)
    VALUES (v_tenant_id, 'teste_portal', 'Teste / Avaliacao', '#F59E0B', 'nenhum', true)
    ON CONFLICT (tenant_id, codigo) DO UPDATE
        SET nome = EXCLUDED.nome,
            cor = EXCLUDED.cor,
            impacto_frequencia = EXCLUDED.impacto_frequencia,
            dia_todo = EXCLUDED.dia_todo
    RETURNING id INTO v_event_type_id;

    INSERT INTO gestao_escolar.school_calendar_events
        (tenant_id, school_year_id, event_type_id, titulo, descricao, data_inicio, data_fim, dia_todo, publico_alvo, publico_alvo_id, created_by)
    SELECT v_tenant_id, v_year_id, v_event_type_id, 'Teste de Gestao Ambiental',
           'Avaliacao marcada para a turma CTA 1o Ano A.', CURRENT_DATE + INTERVAL '5 days',
           CURRENT_DATE + INTERVAL '5 days', true, 'turma', v_class_id, v_student_user_id
    WHERE NOT EXISTS (
        SELECT 1 FROM gestao_escolar.school_calendar_events
        WHERE tenant_id = v_tenant_id AND titulo = 'Teste de Gestao Ambiental' AND publico_alvo_id = v_class_id
    );

    INSERT INTO gestao_escolar.school_books
        (tenant_id, isbn, codigo, titulo, autor, editora, ano_publicacao, categoria, exemplares_total, exemplares_disponiveis)
    SELECT v_tenant_id, '978-989-000-001-1', 'BK-GEO-001', 'Introducao a Geologia Ambiental',
           'Departamento de Ciencias da Terra', 'Nexora Educacao', 2024, 'Geologia', 3, 2
    WHERE NOT EXISTS (
        SELECT 1 FROM gestao_escolar.school_books WHERE tenant_id = v_tenant_id AND codigo = 'BK-GEO-001'
    )
    RETURNING id INTO v_book_id;

    IF v_book_id IS NULL THEN
        SELECT id INTO v_book_id FROM gestao_escolar.school_books WHERE tenant_id = v_tenant_id AND codigo = 'BK-GEO-001' LIMIT 1;
    END IF;

    INSERT INTO gestao_escolar.school_library_loans
        (tenant_id, book_id, student_id, borrower_type, borrower_id, emprestado_em, devolucao_prevista, status, observacoes, created_by)
    SELECT v_tenant_id, v_book_id, v_student_id, 'aluno', v_student_id, CURRENT_DATE - INTERVAL '3 days',
           CURRENT_DATE + INTERVAL '12 days', 'emprestado', 'Livro emprestado para apoio ao trabalho de campo.', v_student_user_id
    WHERE NOT EXISTS (
        SELECT 1 FROM gestao_escolar.school_library_loans
        WHERE tenant_id = v_tenant_id AND book_id = v_book_id AND student_id = v_student_id AND status = 'emprestado'
    );

    INSERT INTO gestao_escolar.school_incident_types
        (tenant_id, codigo, nome, gravidade, requer_encarregado)
    VALUES
        (v_tenant_id, 'OBS-PED', 'Observacao Pedagogica', 'leve', false)
    ON CONFLICT (tenant_id, codigo) DO UPDATE
        SET nome = EXCLUDED.nome,
            gravidade = EXCLUDED.gravidade,
            requer_encarregado = EXCLUDED.requer_encarregado
    RETURNING id INTO v_incident_type_id;

    INSERT INTO gestao_escolar.school_student_incidents
        (tenant_id, school_year_id, student_id, enrollment_id, incident_type_id, reported_by,
         data_ocorrencia, hora_ocorrencia, local, descricao, testemunhas, status)
    SELECT v_tenant_id, v_year_id, v_student_id, v_enrollment_id, v_incident_type_id, v_student_user_id,
           CURRENT_DATE - INTERVAL '2 days', TIME '09:00', 'Sala 12',
           'Observacao pedagogica registada para acompanhamento academico.', 'Professor Antonio Silva', 'registada'
    WHERE NOT EXISTS (
        SELECT 1 FROM gestao_escolar.school_student_incidents
        WHERE tenant_id = v_tenant_id AND student_id = v_student_id AND descricao = 'Observacao pedagogica registada para acompanhamento academico.'
    );

    INSERT INTO gestao_escolar.school_student_merits
        (tenant_id, school_year_id, student_id, enrollment_id, titulo, descricao, data_merito, atribuido_por)
    SELECT v_tenant_id, v_year_id, v_student_id, v_enrollment_id, 'Participacao destacada',
           'Participacao destacada na actividade de campo de Geologia Geral.', CURRENT_DATE - INTERVAL '1 day', v_student_user_id
    WHERE NOT EXISTS (
        SELECT 1 FROM gestao_escolar.school_student_merits
        WHERE tenant_id = v_tenant_id AND student_id = v_student_id AND titulo = 'Participacao destacada'
    );

    RAISE NOTICE 'Seed escolar concluido. tenant_id=%, student_id=%, class_id=%, enrollment_id=%',
        v_tenant_id, v_student_id, v_class_id, v_enrollment_id;
END $$;

COMMIT;
