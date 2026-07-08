SET search_path TO gestao_escolar, public;
UPDATE gestao_escolar.school_classes SET capacidade = 40 WHERE id = 145;
BEGIN;
SET search_path TO gestao_escolar, public, auth;
DO $$
DECLARE
  v_student_uid bigint;
  v_guardian_uid bigint;
  v_student_id bigint;
  v_guardian_id bigint;
BEGIN
  -- Aluno 1
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Francisco Mucavele Nhacolo', 'aluno01.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258844744854', 'ativo', true, 'aluno')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'aluno', updated_at = NOW()
  RETURNING id INTO v_student_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_student_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_students (tenant_id, user_id, codigo, nome, data_nascimento, genero, documento_tipo, documento_numero, nuit, telefone, email, endereco, encarregado_nome, encarregado_telefone, encarregado_email, portal_email, portal_ativo, portal_login_tentativas)
  VALUES (5, v_student_uid, 'ALU-PFA-2026-0001', 'Francisco Mucavele Nhacolo', '2010-06-28', 'M', 'BI', 'BI 110100000242A', '40000002719583', '258844744854', 'aluno01.pfa@nexora.test', 'Bairro do Laulane, Maputo', 'Ana Mucavele Mondlane', '258844903402', 'encarregado01.pfa@nexora.test', 'aluno01.pfa@nexora.test', true, 0)
  ON CONFLICT (tenant_id, codigo) DO UPDATE SET user_id = EXCLUDED.user_id, nome = EXCLUDED.nome, data_nascimento = EXCLUDED.data_nascimento, genero = EXCLUDED.genero, documento_numero = EXCLUDED.documento_numero, nuit = EXCLUDED.nuit, telefone = EXCLUDED.telefone, email = EXCLUDED.email, endereco = EXCLUDED.endereco, encarregado_nome = EXCLUDED.encarregado_nome, encarregado_telefone = EXCLUDED.encarregado_telefone, encarregado_email = EXCLUDED.encarregado_email, portal_email = EXCLUDED.portal_email, portal_ativo = true, updated_at = NOW()
  RETURNING id INTO v_student_id;
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Ana Mucavele Mondlane', 'encarregado01.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258844903402', 'ativo', true, 'encarregado')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'encarregado', updated_at = NOW()
  RETURNING id INTO v_guardian_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_guardian_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_guardians (tenant_id, student_id, nome, parentesco, telefone, email, nuit, endereco, principal, autorizado_recolher, user_id, portal_email, portal_ativo, portal_email_verificado, portal_login_tentativas)
  VALUES (5, v_student_id, 'Ana Mucavele Mondlane', 'Pai', '258844903402', 'encarregado01.pfa@nexora.test', '50000009478454', 'Bairro do Laulane, Maputo', true, true, v_guardian_uid, 'encarregado01.pfa@nexora.test', true, true, 0)
  ON CONFLICT DO NOTHING;
  INSERT INTO gestao_escolar.school_enrollments (tenant_id, school_year_id, student_id, class_id, numero, data_matricula, status, observacoes)
  VALUES (5, 2, v_student_id, 145, 'MAT-PFA-2026-0001', CURRENT_DATE, 'activa', 'Matricula automatica PFA')
  ON CONFLICT (tenant_id, numero) DO UPDATE SET school_year_id = EXCLUDED.school_year_id, student_id = EXCLUDED.student_id, class_id = EXCLUDED.class_id, status = 'activa', observacoes = EXCLUDED.observacoes, updated_at = NOW();
  -- Aluno 2
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Daniel Silvestre Maluana', 'aluno02.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258854698379', 'ativo', true, 'aluno')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'aluno', updated_at = NOW()
  RETURNING id INTO v_student_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_student_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_students (tenant_id, user_id, codigo, nome, data_nascimento, genero, documento_tipo, documento_numero, nuit, telefone, email, endereco, encarregado_nome, encarregado_telefone, encarregado_email, portal_email, portal_ativo, portal_login_tentativas)
  VALUES (5, v_student_uid, 'ALU-PFA-2026-0002', 'Daniel Silvestre Maluana', '2010-01-14', 'M', 'BI', 'BI 110100000559A', '40000005667265', '258854698379', 'aluno02.pfa@nexora.test', 'Bairro do Alto Mae, Maputo', 'Celia Nhacolo Machel', '258846647119', 'encarregado02.pfa@nexora.test', 'aluno02.pfa@nexora.test', true, 0)
  ON CONFLICT (tenant_id, codigo) DO UPDATE SET user_id = EXCLUDED.user_id, nome = EXCLUDED.nome, data_nascimento = EXCLUDED.data_nascimento, genero = EXCLUDED.genero, documento_numero = EXCLUDED.documento_numero, nuit = EXCLUDED.nuit, telefone = EXCLUDED.telefone, email = EXCLUDED.email, endereco = EXCLUDED.endereco, encarregado_nome = EXCLUDED.encarregado_nome, encarregado_telefone = EXCLUDED.encarregado_telefone, encarregado_email = EXCLUDED.encarregado_email, portal_email = EXCLUDED.portal_email, portal_ativo = true, updated_at = NOW()
  RETURNING id INTO v_student_id;
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Celia Nhacolo Machel', 'encarregado02.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258846647119', 'ativo', true, 'encarregado')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'encarregado', updated_at = NOW()
  RETURNING id INTO v_guardian_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_guardian_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_guardians (tenant_id, student_id, nome, parentesco, telefone, email, nuit, endereco, principal, autorizado_recolher, user_id, portal_email, portal_ativo, portal_email_verificado, portal_login_tentativas)
  VALUES (5, v_student_id, 'Celia Nhacolo Machel', 'Tia', '258846647119', 'encarregado02.pfa@nexora.test', '50000002714803', 'Bairro da Polana, Maputo', true, true, v_guardian_uid, 'encarregado02.pfa@nexora.test', true, true, 0)
  ON CONFLICT DO NOTHING;
  INSERT INTO gestao_escolar.school_enrollments (tenant_id, school_year_id, student_id, class_id, numero, data_matricula, status, observacoes)
  VALUES (5, 2, v_student_id, 145, 'MAT-PFA-2026-0002', CURRENT_DATE, 'activa', 'Matricula automatica PFA')
  ON CONFLICT (tenant_id, numero) DO UPDATE SET school_year_id = EXCLUDED.school_year_id, student_id = EXCLUDED.student_id, class_id = EXCLUDED.class_id, status = 'activa', observacoes = EXCLUDED.observacoes, updated_at = NOW();
  -- Aluno 3
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Francisco Guambe Mutombene', 'aluno03.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258851728977', 'ativo', true, 'aluno')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'aluno', updated_at = NOW()
  RETURNING id INTO v_student_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_student_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_students (tenant_id, user_id, codigo, nome, data_nascimento, genero, documento_tipo, documento_numero, nuit, telefone, email, endereco, encarregado_nome, encarregado_telefone, encarregado_email, portal_email, portal_ativo, portal_login_tentativas)
  VALUES (5, v_student_uid, 'ALU-PFA-2026-0003', 'Francisco Guambe Mutombene', '2010-09-13', 'M', 'BI', 'BI 110100000847A', '40000008707870', '258851728977', 'aluno03.pfa@nexora.test', 'Bairro do Munhava, Maputo', 'Daniel Macuacua Mutombene', '258854226067', 'encarregado03.pfa@nexora.test', 'aluno03.pfa@nexora.test', true, 0)
  ON CONFLICT (tenant_id, codigo) DO UPDATE SET user_id = EXCLUDED.user_id, nome = EXCLUDED.nome, data_nascimento = EXCLUDED.data_nascimento, genero = EXCLUDED.genero, documento_numero = EXCLUDED.documento_numero, nuit = EXCLUDED.nuit, telefone = EXCLUDED.telefone, email = EXCLUDED.email, endereco = EXCLUDED.endereco, encarregado_nome = EXCLUDED.encarregado_nome, encarregado_telefone = EXCLUDED.encarregado_telefone, encarregado_email = EXCLUDED.encarregado_email, portal_email = EXCLUDED.portal_email, portal_ativo = true, updated_at = NOW()
  RETURNING id INTO v_student_id;
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Daniel Macuacua Mutombene', 'encarregado03.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258854226067', 'ativo', true, 'encarregado')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'encarregado', updated_at = NOW()
  RETURNING id INTO v_guardian_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_guardian_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_guardians (tenant_id, student_id, nome, parentesco, telefone, email, nuit, endereco, principal, autorizado_recolher, user_id, portal_email, portal_ativo, portal_email_verificado, portal_login_tentativas)
  VALUES (5, v_student_id, 'Daniel Macuacua Mutombene', 'Irmao', '258854226067', 'encarregado03.pfa@nexora.test', '50000002166941', 'Bairro Central, Maputo', true, true, v_guardian_uid, 'encarregado03.pfa@nexora.test', true, true, 0)
  ON CONFLICT DO NOTHING;
  INSERT INTO gestao_escolar.school_enrollments (tenant_id, school_year_id, student_id, class_id, numero, data_matricula, status, observacoes)
  VALUES (5, 2, v_student_id, 145, 'MAT-PFA-2026-0003', CURRENT_DATE, 'activa', 'Matricula automatica PFA')
  ON CONFLICT (tenant_id, numero) DO UPDATE SET school_year_id = EXCLUDED.school_year_id, student_id = EXCLUDED.student_id, class_id = EXCLUDED.class_id, status = 'activa', observacoes = EXCLUDED.observacoes, updated_at = NOW();
  -- Aluno 4
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Mariano Macuacua Mondlane', 'aluno04.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258842694522', 'ativo', true, 'aluno')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'aluno', updated_at = NOW()
  RETURNING id INTO v_student_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_student_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_students (tenant_id, user_id, codigo, nome, data_nascimento, genero, documento_tipo, documento_numero, nuit, telefone, email, endereco, encarregado_nome, encarregado_telefone, encarregado_email, portal_email, portal_ativo, portal_login_tentativas)
  VALUES (5, v_student_uid, 'ALU-PFA-2026-0004', 'Mariano Macuacua Mondlane', '2012-07-17', 'M', 'BI', 'BI 110100000489A', '40000005663623', '258842694522', 'aluno04.pfa@nexora.test', 'Bairro da Mafalala, Maputo', 'Lucas Guambe Silvestre', '258852197935', 'encarregado04.pfa@nexora.test', 'aluno04.pfa@nexora.test', true, 0)
  ON CONFLICT (tenant_id, codigo) DO UPDATE SET user_id = EXCLUDED.user_id, nome = EXCLUDED.nome, data_nascimento = EXCLUDED.data_nascimento, genero = EXCLUDED.genero, documento_numero = EXCLUDED.documento_numero, nuit = EXCLUDED.nuit, telefone = EXCLUDED.telefone, email = EXCLUDED.email, endereco = EXCLUDED.endereco, encarregado_nome = EXCLUDED.encarregado_nome, encarregado_telefone = EXCLUDED.encarregado_telefone, encarregado_email = EXCLUDED.encarregado_email, portal_email = EXCLUDED.portal_email, portal_ativo = true, updated_at = NOW()
  RETURNING id INTO v_student_id;
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Lucas Guambe Silvestre', 'encarregado04.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258852197935', 'ativo', true, 'encarregado')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'encarregado', updated_at = NOW()
  RETURNING id INTO v_guardian_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_guardian_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_guardians (tenant_id, student_id, nome, parentesco, telefone, email, nuit, endereco, principal, autorizado_recolher, user_id, portal_email, portal_ativo, portal_email_verificado, portal_login_tentativas)
  VALUES (5, v_student_id, 'Lucas Guambe Silvestre', 'Irmao', '258852197935', 'encarregado04.pfa@nexora.test', '50000003871230', 'Bairro da Maxaquene, Maputo', true, true, v_guardian_uid, 'encarregado04.pfa@nexora.test', true, true, 0)
  ON CONFLICT DO NOTHING;
  INSERT INTO gestao_escolar.school_enrollments (tenant_id, school_year_id, student_id, class_id, numero, data_matricula, status, observacoes)
  VALUES (5, 2, v_student_id, 145, 'MAT-PFA-2026-0004', CURRENT_DATE, 'activa', 'Matricula automatica PFA')
  ON CONFLICT (tenant_id, numero) DO UPDATE SET school_year_id = EXCLUDED.school_year_id, student_id = EXCLUDED.student_id, class_id = EXCLUDED.class_id, status = 'activa', observacoes = EXCLUDED.observacoes, updated_at = NOW();
  -- Aluno 5
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Mariano Mutemba Nhabanga', 'aluno05.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258855528972', 'ativo', true, 'aluno')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'aluno', updated_at = NOW()
  RETURNING id INTO v_student_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_student_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_students (tenant_id, user_id, codigo, nome, data_nascimento, genero, documento_tipo, documento_numero, nuit, telefone, email, endereco, encarregado_nome, encarregado_telefone, encarregado_email, portal_email, portal_ativo, portal_login_tentativas)
  VALUES (5, v_student_uid, 'ALU-PFA-2026-0005', 'Mariano Mutemba Nhabanga', '2011-10-27', 'M', 'BI', 'BI 110100000755A', '40000004684531', '258855528972', 'aluno05.pfa@nexora.test', 'Bairro Central, Maputo', 'Joao Tembe Zunguze', '258852110460', 'encarregado05.pfa@nexora.test', 'aluno05.pfa@nexora.test', true, 0)
  ON CONFLICT (tenant_id, codigo) DO UPDATE SET user_id = EXCLUDED.user_id, nome = EXCLUDED.nome, data_nascimento = EXCLUDED.data_nascimento, genero = EXCLUDED.genero, documento_numero = EXCLUDED.documento_numero, nuit = EXCLUDED.nuit, telefone = EXCLUDED.telefone, email = EXCLUDED.email, endereco = EXCLUDED.endereco, encarregado_nome = EXCLUDED.encarregado_nome, encarregado_telefone = EXCLUDED.encarregado_telefone, encarregado_email = EXCLUDED.encarregado_email, portal_email = EXCLUDED.portal_email, portal_ativo = true, updated_at = NOW()
  RETURNING id INTO v_student_id;
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Joao Tembe Zunguze', 'encarregado05.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258852110460', 'ativo', true, 'encarregado')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'encarregado', updated_at = NOW()
  RETURNING id INTO v_guardian_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_guardian_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_guardians (tenant_id, student_id, nome, parentesco, telefone, email, nuit, endereco, principal, autorizado_recolher, user_id, portal_email, portal_ativo, portal_email_verificado, portal_login_tentativas)
  VALUES (5, v_student_id, 'Joao Tembe Zunguze', 'Irmao', '258852110460', 'encarregado05.pfa@nexora.test', '50000004539704', 'Bairro do Laulane, Maputo', true, true, v_guardian_uid, 'encarregado05.pfa@nexora.test', true, true, 0)
  ON CONFLICT DO NOTHING;
  INSERT INTO gestao_escolar.school_enrollments (tenant_id, school_year_id, student_id, class_id, numero, data_matricula, status, observacoes)
  VALUES (5, 2, v_student_id, 145, 'MAT-PFA-2026-0005', CURRENT_DATE, 'activa', 'Matricula automatica PFA')
  ON CONFLICT (tenant_id, numero) DO UPDATE SET school_year_id = EXCLUDED.school_year_id, student_id = EXCLUDED.student_id, class_id = EXCLUDED.class_id, status = 'activa', observacoes = EXCLUDED.observacoes, updated_at = NOW();
  -- Aluno 6
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Davide Silvestre Matsine', 'aluno06.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258858698256', 'ativo', true, 'aluno')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'aluno', updated_at = NOW()
  RETURNING id INTO v_student_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_student_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_students (tenant_id, user_id, codigo, nome, data_nascimento, genero, documento_tipo, documento_numero, nuit, telefone, email, endereco, encarregado_nome, encarregado_telefone, encarregado_email, portal_email, portal_ativo, portal_login_tentativas)
  VALUES (5, v_student_uid, 'ALU-PFA-2026-0006', 'Davide Silvestre Matsine', '2010-10-13', 'M', 'BI', 'BI 110100000246A', '40000005443951', '258858698256', 'aluno06.pfa@nexora.test', 'Bairro da Coop, Maputo', 'Beatriz Bila Buque', '258857073292', 'encarregado06.pfa@nexora.test', 'aluno06.pfa@nexora.test', true, 0)
  ON CONFLICT (tenant_id, codigo) DO UPDATE SET user_id = EXCLUDED.user_id, nome = EXCLUDED.nome, data_nascimento = EXCLUDED.data_nascimento, genero = EXCLUDED.genero, documento_numero = EXCLUDED.documento_numero, nuit = EXCLUDED.nuit, telefone = EXCLUDED.telefone, email = EXCLUDED.email, endereco = EXCLUDED.endereco, encarregado_nome = EXCLUDED.encarregado_nome, encarregado_telefone = EXCLUDED.encarregado_telefone, encarregado_email = EXCLUDED.encarregado_email, portal_email = EXCLUDED.portal_email, portal_ativo = true, updated_at = NOW()
  RETURNING id INTO v_student_id;
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Beatriz Bila Buque', 'encarregado06.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258857073292', 'ativo', true, 'encarregado')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'encarregado', updated_at = NOW()
  RETURNING id INTO v_guardian_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_guardian_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_guardians (tenant_id, student_id, nome, parentesco, telefone, email, nuit, endereco, principal, autorizado_recolher, user_id, portal_email, portal_ativo, portal_email_verificado, portal_login_tentativas)
  VALUES (5, v_student_id, 'Beatriz Bila Buque', 'Avo', '258857073292', 'encarregado06.pfa@nexora.test', '50000004679591', 'Bairro do Alto Mae, Maputo', true, true, v_guardian_uid, 'encarregado06.pfa@nexora.test', true, true, 0)
  ON CONFLICT DO NOTHING;
  INSERT INTO gestao_escolar.school_enrollments (tenant_id, school_year_id, student_id, class_id, numero, data_matricula, status, observacoes)
  VALUES (5, 2, v_student_id, 145, 'MAT-PFA-2026-0006', CURRENT_DATE, 'activa', 'Matricula automatica PFA')
  ON CONFLICT (tenant_id, numero) DO UPDATE SET school_year_id = EXCLUDED.school_year_id, student_id = EXCLUDED.student_id, class_id = EXCLUDED.class_id, status = 'activa', observacoes = EXCLUDED.observacoes, updated_at = NOW();
  -- Aluno 7
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Filipe Mondlane Sitoe', 'aluno07.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258843564251', 'ativo', true, 'aluno')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'aluno', updated_at = NOW()
  RETURNING id INTO v_student_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_student_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_students (tenant_id, user_id, codigo, nome, data_nascimento, genero, documento_tipo, documento_numero, nuit, telefone, email, endereco, encarregado_nome, encarregado_telefone, encarregado_email, portal_email, portal_ativo, portal_login_tentativas)
  VALUES (5, v_student_uid, 'ALU-PFA-2026-0007', 'Filipe Mondlane Sitoe', '2012-05-14', 'M', 'BI', 'BI 110100000742A', '40000003684052', '258843564251', 'aluno07.pfa@nexora.test', 'Bairro do Laulane, Maputo', 'Mateus Zunguze Mutombene', '258859877065', 'encarregado07.pfa@nexora.test', 'aluno07.pfa@nexora.test', true, 0)
  ON CONFLICT (tenant_id, codigo) DO UPDATE SET user_id = EXCLUDED.user_id, nome = EXCLUDED.nome, data_nascimento = EXCLUDED.data_nascimento, genero = EXCLUDED.genero, documento_numero = EXCLUDED.documento_numero, nuit = EXCLUDED.nuit, telefone = EXCLUDED.telefone, email = EXCLUDED.email, endereco = EXCLUDED.endereco, encarregado_nome = EXCLUDED.encarregado_nome, encarregado_telefone = EXCLUDED.encarregado_telefone, encarregado_email = EXCLUDED.encarregado_email, portal_email = EXCLUDED.portal_email, portal_ativo = true, updated_at = NOW()
  RETURNING id INTO v_student_id;
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Mateus Zunguze Mutombene', 'encarregado07.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258859877065', 'ativo', true, 'encarregado')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'encarregado', updated_at = NOW()
  RETURNING id INTO v_guardian_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_guardian_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_guardians (tenant_id, student_id, nome, parentesco, telefone, email, nuit, endereco, principal, autorizado_recolher, user_id, portal_email, portal_ativo, portal_email_verificado, portal_login_tentativas)
  VALUES (5, v_student_id, 'Mateus Zunguze Mutombene', 'Tutor', '258859877065', 'encarregado07.pfa@nexora.test', '50000005218028', 'Bairro da Maxaquene, Maputo', true, true, v_guardian_uid, 'encarregado07.pfa@nexora.test', true, true, 0)
  ON CONFLICT DO NOTHING;
  INSERT INTO gestao_escolar.school_enrollments (tenant_id, school_year_id, student_id, class_id, numero, data_matricula, status, observacoes)
  VALUES (5, 2, v_student_id, 145, 'MAT-PFA-2026-0007', CURRENT_DATE, 'activa', 'Matricula automatica PFA')
  ON CONFLICT (tenant_id, numero) DO UPDATE SET school_year_id = EXCLUDED.school_year_id, student_id = EXCLUDED.student_id, class_id = EXCLUDED.class_id, status = 'activa', observacoes = EXCLUDED.observacoes, updated_at = NOW();
  -- Aluno 8
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Carlos Chissano Maluana', 'aluno08.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258856707197', 'ativo', true, 'aluno')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'aluno', updated_at = NOW()
  RETURNING id INTO v_student_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_student_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_students (tenant_id, user_id, codigo, nome, data_nascimento, genero, documento_tipo, documento_numero, nuit, telefone, email, endereco, encarregado_nome, encarregado_telefone, encarregado_email, portal_email, portal_ativo, portal_login_tentativas)
  VALUES (5, v_student_uid, 'ALU-PFA-2026-0008', 'Carlos Chissano Maluana', '2012-06-09', 'M', 'BI', 'BI 110100000214A', '40000005924115', '258856707197', 'aluno08.pfa@nexora.test', 'Bairro do Alto Mae, Maputo', 'Maria Nhacolo Timane', '258849517485', 'encarregado08.pfa@nexora.test', 'aluno08.pfa@nexora.test', true, 0)
  ON CONFLICT (tenant_id, codigo) DO UPDATE SET user_id = EXCLUDED.user_id, nome = EXCLUDED.nome, data_nascimento = EXCLUDED.data_nascimento, genero = EXCLUDED.genero, documento_numero = EXCLUDED.documento_numero, nuit = EXCLUDED.nuit, telefone = EXCLUDED.telefone, email = EXCLUDED.email, endereco = EXCLUDED.endereco, encarregado_nome = EXCLUDED.encarregado_nome, encarregado_telefone = EXCLUDED.encarregado_telefone, encarregado_email = EXCLUDED.encarregado_email, portal_email = EXCLUDED.portal_email, portal_ativo = true, updated_at = NOW()
  RETURNING id INTO v_student_id;
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Maria Nhacolo Timane', 'encarregado08.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258849517485', 'ativo', true, 'encarregado')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'encarregado', updated_at = NOW()
  RETURNING id INTO v_guardian_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_guardian_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_guardians (tenant_id, student_id, nome, parentesco, telefone, email, nuit, endereco, principal, autorizado_recolher, user_id, portal_email, portal_ativo, portal_email_verificado, portal_login_tentativas)
  VALUES (5, v_student_id, 'Maria Nhacolo Timane', 'Tutor', '258849517485', 'encarregado08.pfa@nexora.test', '50000002785277', 'Bairro do Chamanculo, Maputo', true, true, v_guardian_uid, 'encarregado08.pfa@nexora.test', true, true, 0)
  ON CONFLICT DO NOTHING;
  INSERT INTO gestao_escolar.school_enrollments (tenant_id, school_year_id, student_id, class_id, numero, data_matricula, status, observacoes)
  VALUES (5, 2, v_student_id, 145, 'MAT-PFA-2026-0008', CURRENT_DATE, 'activa', 'Matricula automatica PFA')
  ON CONFLICT (tenant_id, numero) DO UPDATE SET school_year_id = EXCLUDED.school_year_id, student_id = EXCLUDED.student_id, class_id = EXCLUDED.class_id, status = 'activa', observacoes = EXCLUDED.observacoes, updated_at = NOW();
  -- Aluno 9
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Paulo Mutombene Silvestre', 'aluno09.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258847273233', 'ativo', true, 'aluno')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'aluno', updated_at = NOW()
  RETURNING id INTO v_student_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_student_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_students (tenant_id, user_id, codigo, nome, data_nascimento, genero, documento_tipo, documento_numero, nuit, telefone, email, endereco, encarregado_nome, encarregado_telefone, encarregado_email, portal_email, portal_ativo, portal_login_tentativas)
  VALUES (5, v_student_uid, 'ALU-PFA-2026-0009', 'Paulo Mutombene Silvestre', '2012-12-22', 'M', 'BI', 'BI 110100000880A', '40000003710343', '258847273233', 'aluno09.pfa@nexora.test', 'Bairro Central, Maputo', 'Fernanda Mucavele Chissano', '258856159230', 'encarregado09.pfa@nexora.test', 'aluno09.pfa@nexora.test', true, 0)
  ON CONFLICT (tenant_id, codigo) DO UPDATE SET user_id = EXCLUDED.user_id, nome = EXCLUDED.nome, data_nascimento = EXCLUDED.data_nascimento, genero = EXCLUDED.genero, documento_numero = EXCLUDED.documento_numero, nuit = EXCLUDED.nuit, telefone = EXCLUDED.telefone, email = EXCLUDED.email, endereco = EXCLUDED.endereco, encarregado_nome = EXCLUDED.encarregado_nome, encarregado_telefone = EXCLUDED.encarregado_telefone, encarregado_email = EXCLUDED.encarregado_email, portal_email = EXCLUDED.portal_email, portal_ativo = true, updated_at = NOW()
  RETURNING id INTO v_student_id;
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Fernanda Mucavele Chissano', 'encarregado09.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258856159230', 'ativo', true, 'encarregado')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'encarregado', updated_at = NOW()
  RETURNING id INTO v_guardian_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_guardian_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_guardians (tenant_id, student_id, nome, parentesco, telefone, email, nuit, endereco, principal, autorizado_recolher, user_id, portal_email, portal_ativo, portal_email_verificado, portal_login_tentativas)
  VALUES (5, v_student_id, 'Fernanda Mucavele Chissano', 'Mae', '258856159230', 'encarregado09.pfa@nexora.test', '50000005017343', 'Bairro Central, Maputo', true, true, v_guardian_uid, 'encarregado09.pfa@nexora.test', true, true, 0)
  ON CONFLICT DO NOTHING;
  INSERT INTO gestao_escolar.school_enrollments (tenant_id, school_year_id, student_id, class_id, numero, data_matricula, status, observacoes)
  VALUES (5, 2, v_student_id, 145, 'MAT-PFA-2026-0009', CURRENT_DATE, 'activa', 'Matricula automatica PFA')
  ON CONFLICT (tenant_id, numero) DO UPDATE SET school_year_id = EXCLUDED.school_year_id, student_id = EXCLUDED.student_id, class_id = EXCLUDED.class_id, status = 'activa', observacoes = EXCLUDED.observacoes, updated_at = NOW();
  -- Aluno 10
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Tiago Mondlane Matsine', 'aluno10.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258849937326', 'ativo', true, 'aluno')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'aluno', updated_at = NOW()
  RETURNING id INTO v_student_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_student_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_students (tenant_id, user_id, codigo, nome, data_nascimento, genero, documento_tipo, documento_numero, nuit, telefone, email, endereco, encarregado_nome, encarregado_telefone, encarregado_email, portal_email, portal_ativo, portal_login_tentativas)
  VALUES (5, v_student_uid, 'ALU-PFA-2026-0010', 'Tiago Mondlane Matsine', '2010-09-20', 'M', 'BI', 'BI 110100000884A', '40000003109911', '258849937326', 'aluno10.pfa@nexora.test', 'Bairro do Inhagoia, Maputo', 'Armando Timane Mutombene', '258854553384', 'encarregado10.pfa@nexora.test', 'aluno10.pfa@nexora.test', true, 0)
  ON CONFLICT (tenant_id, codigo) DO UPDATE SET user_id = EXCLUDED.user_id, nome = EXCLUDED.nome, data_nascimento = EXCLUDED.data_nascimento, genero = EXCLUDED.genero, documento_numero = EXCLUDED.documento_numero, nuit = EXCLUDED.nuit, telefone = EXCLUDED.telefone, email = EXCLUDED.email, endereco = EXCLUDED.endereco, encarregado_nome = EXCLUDED.encarregado_nome, encarregado_telefone = EXCLUDED.encarregado_telefone, encarregado_email = EXCLUDED.encarregado_email, portal_email = EXCLUDED.portal_email, portal_ativo = true, updated_at = NOW()
  RETURNING id INTO v_student_id;
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Armando Timane Mutombene', 'encarregado10.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258854553384', 'ativo', true, 'encarregado')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'encarregado', updated_at = NOW()
  RETURNING id INTO v_guardian_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_guardian_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_guardians (tenant_id, student_id, nome, parentesco, telefone, email, nuit, endereco, principal, autorizado_recolher, user_id, portal_email, portal_ativo, portal_email_verificado, portal_login_tentativas)
  VALUES (5, v_student_id, 'Armando Timane Mutombene', 'Tia', '258854553384', 'encarregado10.pfa@nexora.test', '50000004374754', 'Bairro do Chamanculo, Maputo', true, true, v_guardian_uid, 'encarregado10.pfa@nexora.test', true, true, 0)
  ON CONFLICT DO NOTHING;
  INSERT INTO gestao_escolar.school_enrollments (tenant_id, school_year_id, student_id, class_id, numero, data_matricula, status, observacoes)
  VALUES (5, 2, v_student_id, 145, 'MAT-PFA-2026-0010', CURRENT_DATE, 'activa', 'Matricula automatica PFA')
  ON CONFLICT (tenant_id, numero) DO UPDATE SET school_year_id = EXCLUDED.school_year_id, student_id = EXCLUDED.student_id, class_id = EXCLUDED.class_id, status = 'activa', observacoes = EXCLUDED.observacoes, updated_at = NOW();
  -- Aluno 11
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Lucas Nhabanga Timane', 'aluno11.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258853030113', 'ativo', true, 'aluno')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'aluno', updated_at = NOW()
  RETURNING id INTO v_student_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_student_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_students (tenant_id, user_id, codigo, nome, data_nascimento, genero, documento_tipo, documento_numero, nuit, telefone, email, endereco, encarregado_nome, encarregado_telefone, encarregado_email, portal_email, portal_ativo, portal_login_tentativas)
  VALUES (5, v_student_uid, 'ALU-PFA-2026-0011', 'Lucas Nhabanga Timane', '2010-05-12', 'M', 'BI', 'BI 110100000353A', '40000004769795', '258853030113', 'aluno11.pfa@nexora.test', 'Bairro da Mafalala, Maputo', 'Tiago Maluana Cossa', '258841120642', 'encarregado11.pfa@nexora.test', 'aluno11.pfa@nexora.test', true, 0)
  ON CONFLICT (tenant_id, codigo) DO UPDATE SET user_id = EXCLUDED.user_id, nome = EXCLUDED.nome, data_nascimento = EXCLUDED.data_nascimento, genero = EXCLUDED.genero, documento_numero = EXCLUDED.documento_numero, nuit = EXCLUDED.nuit, telefone = EXCLUDED.telefone, email = EXCLUDED.email, endereco = EXCLUDED.endereco, encarregado_nome = EXCLUDED.encarregado_nome, encarregado_telefone = EXCLUDED.encarregado_telefone, encarregado_email = EXCLUDED.encarregado_email, portal_email = EXCLUDED.portal_email, portal_ativo = true, updated_at = NOW()
  RETURNING id INTO v_student_id;
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Tiago Maluana Cossa', 'encarregado11.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258841120642', 'ativo', true, 'encarregado')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'encarregado', updated_at = NOW()
  RETURNING id INTO v_guardian_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_guardian_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_guardians (tenant_id, student_id, nome, parentesco, telefone, email, nuit, endereco, principal, autorizado_recolher, user_id, portal_email, portal_ativo, portal_email_verificado, portal_login_tentativas)
  VALUES (5, v_student_id, 'Tiago Maluana Cossa', 'Mae', '258841120642', 'encarregado11.pfa@nexora.test', '50000002191066', 'Bairro Central, Maputo', true, true, v_guardian_uid, 'encarregado11.pfa@nexora.test', true, true, 0)
  ON CONFLICT DO NOTHING;
  INSERT INTO gestao_escolar.school_enrollments (tenant_id, school_year_id, student_id, class_id, numero, data_matricula, status, observacoes)
  VALUES (5, 2, v_student_id, 145, 'MAT-PFA-2026-0011', CURRENT_DATE, 'activa', 'Matricula automatica PFA')
  ON CONFLICT (tenant_id, numero) DO UPDATE SET school_year_id = EXCLUDED.school_year_id, student_id = EXCLUDED.student_id, class_id = EXCLUDED.class_id, status = 'activa', observacoes = EXCLUDED.observacoes, updated_at = NOW();
  -- Aluno 12
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Pedro Sitoe Tembe', 'aluno12.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258849626108', 'ativo', true, 'aluno')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'aluno', updated_at = NOW()
  RETURNING id INTO v_student_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_student_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_students (tenant_id, user_id, codigo, nome, data_nascimento, genero, documento_tipo, documento_numero, nuit, telefone, email, endereco, encarregado_nome, encarregado_telefone, encarregado_email, portal_email, portal_ativo, portal_login_tentativas)
  VALUES (5, v_student_uid, 'ALU-PFA-2026-0012', 'Pedro Sitoe Tembe', '2012-09-21', 'M', 'BI', 'BI 110100000343A', '40000005672073', '258849626108', 'aluno12.pfa@nexora.test', 'Bairro da Coop, Maputo', 'Tiago Buque Matsine', '258848935169', 'encarregado12.pfa@nexora.test', 'aluno12.pfa@nexora.test', true, 0)
  ON CONFLICT (tenant_id, codigo) DO UPDATE SET user_id = EXCLUDED.user_id, nome = EXCLUDED.nome, data_nascimento = EXCLUDED.data_nascimento, genero = EXCLUDED.genero, documento_numero = EXCLUDED.documento_numero, nuit = EXCLUDED.nuit, telefone = EXCLUDED.telefone, email = EXCLUDED.email, endereco = EXCLUDED.endereco, encarregado_nome = EXCLUDED.encarregado_nome, encarregado_telefone = EXCLUDED.encarregado_telefone, encarregado_email = EXCLUDED.encarregado_email, portal_email = EXCLUDED.portal_email, portal_ativo = true, updated_at = NOW()
  RETURNING id INTO v_student_id;
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Tiago Buque Matsine', 'encarregado12.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258848935169', 'ativo', true, 'encarregado')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'encarregado', updated_at = NOW()
  RETURNING id INTO v_guardian_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_guardian_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_guardians (tenant_id, student_id, nome, parentesco, telefone, email, nuit, endereco, principal, autorizado_recolher, user_id, portal_email, portal_ativo, portal_email_verificado, portal_login_tentativas)
  VALUES (5, v_student_id, 'Tiago Buque Matsine', 'Pai', '258848935169', 'encarregado12.pfa@nexora.test', '50000007829332', 'Bairro da Coop, Maputo', true, true, v_guardian_uid, 'encarregado12.pfa@nexora.test', true, true, 0)
  ON CONFLICT DO NOTHING;
  INSERT INTO gestao_escolar.school_enrollments (tenant_id, school_year_id, student_id, class_id, numero, data_matricula, status, observacoes)
  VALUES (5, 2, v_student_id, 145, 'MAT-PFA-2026-0012', CURRENT_DATE, 'activa', 'Matricula automatica PFA')
  ON CONFLICT (tenant_id, numero) DO UPDATE SET school_year_id = EXCLUDED.school_year_id, student_id = EXCLUDED.student_id, class_id = EXCLUDED.class_id, status = 'activa', observacoes = EXCLUDED.observacoes, updated_at = NOW();
  -- Aluno 13
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Francisco Bila Guambe', 'aluno13.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258857897151', 'ativo', true, 'aluno')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'aluno', updated_at = NOW()
  RETURNING id INTO v_student_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_student_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_students (tenant_id, user_id, codigo, nome, data_nascimento, genero, documento_tipo, documento_numero, nuit, telefone, email, endereco, encarregado_nome, encarregado_telefone, encarregado_email, portal_email, portal_ativo, portal_login_tentativas)
  VALUES (5, v_student_uid, 'ALU-PFA-2026-0013', 'Francisco Bila Guambe', '2010-07-21', 'M', 'BI', 'BI 110100000578A', '40000001908841', '258857897151', 'aluno13.pfa@nexora.test', 'Bairro Central, Maputo', 'Celia Chissano Cossa', '258844191175', 'encarregado13.pfa@nexora.test', 'aluno13.pfa@nexora.test', true, 0)
  ON CONFLICT (tenant_id, codigo) DO UPDATE SET user_id = EXCLUDED.user_id, nome = EXCLUDED.nome, data_nascimento = EXCLUDED.data_nascimento, genero = EXCLUDED.genero, documento_numero = EXCLUDED.documento_numero, nuit = EXCLUDED.nuit, telefone = EXCLUDED.telefone, email = EXCLUDED.email, endereco = EXCLUDED.endereco, encarregado_nome = EXCLUDED.encarregado_nome, encarregado_telefone = EXCLUDED.encarregado_telefone, encarregado_email = EXCLUDED.encarregado_email, portal_email = EXCLUDED.portal_email, portal_ativo = true, updated_at = NOW()
  RETURNING id INTO v_student_id;
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Celia Chissano Cossa', 'encarregado13.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258844191175', 'ativo', true, 'encarregado')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'encarregado', updated_at = NOW()
  RETURNING id INTO v_guardian_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_guardian_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_guardians (tenant_id, student_id, nome, parentesco, telefone, email, nuit, endereco, principal, autorizado_recolher, user_id, portal_email, portal_ativo, portal_email_verificado, portal_login_tentativas)
  VALUES (5, v_student_id, 'Celia Chissano Cossa', 'Mae', '258844191175', 'encarregado13.pfa@nexora.test', '50000009997381', 'Bairro do Inhagoia, Maputo', true, true, v_guardian_uid, 'encarregado13.pfa@nexora.test', true, true, 0)
  ON CONFLICT DO NOTHING;
  INSERT INTO gestao_escolar.school_enrollments (tenant_id, school_year_id, student_id, class_id, numero, data_matricula, status, observacoes)
  VALUES (5, 2, v_student_id, 145, 'MAT-PFA-2026-0013', CURRENT_DATE, 'activa', 'Matricula automatica PFA')
  ON CONFLICT (tenant_id, numero) DO UPDATE SET school_year_id = EXCLUDED.school_year_id, student_id = EXCLUDED.student_id, class_id = EXCLUDED.class_id, status = 'activa', observacoes = EXCLUDED.observacoes, updated_at = NOW();
  -- Aluno 14
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Samuel Mutemba Nhacolo', 'aluno14.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258855191056', 'ativo', true, 'aluno')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'aluno', updated_at = NOW()
  RETURNING id INTO v_student_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_student_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_students (tenant_id, user_id, codigo, nome, data_nascimento, genero, documento_tipo, documento_numero, nuit, telefone, email, endereco, encarregado_nome, encarregado_telefone, encarregado_email, portal_email, portal_ativo, portal_login_tentativas)
  VALUES (5, v_student_uid, 'ALU-PFA-2026-0014', 'Samuel Mutemba Nhacolo', '2012-06-26', 'M', 'BI', 'BI 110100000995A', '40000002264748', '258855191056', 'aluno14.pfa@nexora.test', 'Bairro da Maxaquene, Maputo', 'Joao Maluana Mucavele', '258844965789', 'encarregado14.pfa@nexora.test', 'aluno14.pfa@nexora.test', true, 0)
  ON CONFLICT (tenant_id, codigo) DO UPDATE SET user_id = EXCLUDED.user_id, nome = EXCLUDED.nome, data_nascimento = EXCLUDED.data_nascimento, genero = EXCLUDED.genero, documento_numero = EXCLUDED.documento_numero, nuit = EXCLUDED.nuit, telefone = EXCLUDED.telefone, email = EXCLUDED.email, endereco = EXCLUDED.endereco, encarregado_nome = EXCLUDED.encarregado_nome, encarregado_telefone = EXCLUDED.encarregado_telefone, encarregado_email = EXCLUDED.encarregado_email, portal_email = EXCLUDED.portal_email, portal_ativo = true, updated_at = NOW()
  RETURNING id INTO v_student_id;
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Joao Maluana Mucavele', 'encarregado14.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258844965789', 'ativo', true, 'encarregado')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'encarregado', updated_at = NOW()
  RETURNING id INTO v_guardian_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_guardian_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_guardians (tenant_id, student_id, nome, parentesco, telefone, email, nuit, endereco, principal, autorizado_recolher, user_id, portal_email, portal_ativo, portal_email_verificado, portal_login_tentativas)
  VALUES (5, v_student_id, 'Joao Maluana Mucavele', 'Tia', '258844965789', 'encarregado14.pfa@nexora.test', '50000003790237', 'Bairro do Munhava, Maputo', true, true, v_guardian_uid, 'encarregado14.pfa@nexora.test', true, true, 0)
  ON CONFLICT DO NOTHING;
  INSERT INTO gestao_escolar.school_enrollments (tenant_id, school_year_id, student_id, class_id, numero, data_matricula, status, observacoes)
  VALUES (5, 2, v_student_id, 145, 'MAT-PFA-2026-0014', CURRENT_DATE, 'activa', 'Matricula automatica PFA')
  ON CONFLICT (tenant_id, numero) DO UPDATE SET school_year_id = EXCLUDED.school_year_id, student_id = EXCLUDED.student_id, class_id = EXCLUDED.class_id, status = 'activa', observacoes = EXCLUDED.observacoes, updated_at = NOW();
  -- Aluno 15
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Filipe Silvestre Zunguze', 'aluno15.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258843762152', 'ativo', true, 'aluno')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'aluno', updated_at = NOW()
  RETURNING id INTO v_student_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_student_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_students (tenant_id, user_id, codigo, nome, data_nascimento, genero, documento_tipo, documento_numero, nuit, telefone, email, endereco, encarregado_nome, encarregado_telefone, encarregado_email, portal_email, portal_ativo, portal_login_tentativas)
  VALUES (5, v_student_uid, 'ALU-PFA-2026-0015', 'Filipe Silvestre Zunguze', '2012-03-10', 'M', 'BI', 'BI 110100000488A', '40000001036161', '258843762152', 'aluno15.pfa@nexora.test', 'Bairro do Chamanculo, Maputo', 'Lucia Bila Maluana', '258853597059', 'encarregado15.pfa@nexora.test', 'aluno15.pfa@nexora.test', true, 0)
  ON CONFLICT (tenant_id, codigo) DO UPDATE SET user_id = EXCLUDED.user_id, nome = EXCLUDED.nome, data_nascimento = EXCLUDED.data_nascimento, genero = EXCLUDED.genero, documento_numero = EXCLUDED.documento_numero, nuit = EXCLUDED.nuit, telefone = EXCLUDED.telefone, email = EXCLUDED.email, endereco = EXCLUDED.endereco, encarregado_nome = EXCLUDED.encarregado_nome, encarregado_telefone = EXCLUDED.encarregado_telefone, encarregado_email = EXCLUDED.encarregado_email, portal_email = EXCLUDED.portal_email, portal_ativo = true, updated_at = NOW()
  RETURNING id INTO v_student_id;
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Lucia Bila Maluana', 'encarregado15.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258853597059', 'ativo', true, 'encarregado')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'encarregado', updated_at = NOW()
  RETURNING id INTO v_guardian_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_guardian_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_guardians (tenant_id, student_id, nome, parentesco, telefone, email, nuit, endereco, principal, autorizado_recolher, user_id, portal_email, portal_ativo, portal_email_verificado, portal_login_tentativas)
  VALUES (5, v_student_id, 'Lucia Bila Maluana', 'Mae', '258853597059', 'encarregado15.pfa@nexora.test', '50000004185957', 'Bairro do Chamanculo, Maputo', true, true, v_guardian_uid, 'encarregado15.pfa@nexora.test', true, true, 0)
  ON CONFLICT DO NOTHING;
  INSERT INTO gestao_escolar.school_enrollments (tenant_id, school_year_id, student_id, class_id, numero, data_matricula, status, observacoes)
  VALUES (5, 2, v_student_id, 145, 'MAT-PFA-2026-0015', CURRENT_DATE, 'activa', 'Matricula automatica PFA')
  ON CONFLICT (tenant_id, numero) DO UPDATE SET school_year_id = EXCLUDED.school_year_id, student_id = EXCLUDED.student_id, class_id = EXCLUDED.class_id, status = 'activa', observacoes = EXCLUDED.observacoes, updated_at = NOW();
  -- Aluno 16
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Ana Buque Maluana', 'aluno16.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258846261415', 'ativo', true, 'aluno')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'aluno', updated_at = NOW()
  RETURNING id INTO v_student_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_student_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_students (tenant_id, user_id, codigo, nome, data_nascimento, genero, documento_tipo, documento_numero, nuit, telefone, email, endereco, encarregado_nome, encarregado_telefone, encarregado_email, portal_email, portal_ativo, portal_login_tentativas)
  VALUES (5, v_student_uid, 'ALU-PFA-2026-0016', 'Ana Buque Maluana', '2012-09-03', 'F', 'BI', 'BI 110100000158A', '40000001841248', '258846261415', 'aluno16.pfa@nexora.test', 'Bairro da Maxaquene, Maputo', 'Joao Timane Mondlane', '258842149597', 'encarregado16.pfa@nexora.test', 'aluno16.pfa@nexora.test', true, 0)
  ON CONFLICT (tenant_id, codigo) DO UPDATE SET user_id = EXCLUDED.user_id, nome = EXCLUDED.nome, data_nascimento = EXCLUDED.data_nascimento, genero = EXCLUDED.genero, documento_numero = EXCLUDED.documento_numero, nuit = EXCLUDED.nuit, telefone = EXCLUDED.telefone, email = EXCLUDED.email, endereco = EXCLUDED.endereco, encarregado_nome = EXCLUDED.encarregado_nome, encarregado_telefone = EXCLUDED.encarregado_telefone, encarregado_email = EXCLUDED.encarregado_email, portal_email = EXCLUDED.portal_email, portal_ativo = true, updated_at = NOW()
  RETURNING id INTO v_student_id;
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Joao Timane Mondlane', 'encarregado16.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258842149597', 'ativo', true, 'encarregado')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'encarregado', updated_at = NOW()
  RETURNING id INTO v_guardian_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_guardian_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_guardians (tenant_id, student_id, nome, parentesco, telefone, email, nuit, endereco, principal, autorizado_recolher, user_id, portal_email, portal_ativo, portal_email_verificado, portal_login_tentativas)
  VALUES (5, v_student_id, 'Joao Timane Mondlane', 'Tia', '258842149597', 'encarregado16.pfa@nexora.test', '50000002140194', 'Bairro da Coop, Maputo', true, true, v_guardian_uid, 'encarregado16.pfa@nexora.test', true, true, 0)
  ON CONFLICT DO NOTHING;
  INSERT INTO gestao_escolar.school_enrollments (tenant_id, school_year_id, student_id, class_id, numero, data_matricula, status, observacoes)
  VALUES (5, 2, v_student_id, 145, 'MAT-PFA-2026-0016', CURRENT_DATE, 'activa', 'Matricula automatica PFA')
  ON CONFLICT (tenant_id, numero) DO UPDATE SET school_year_id = EXCLUDED.school_year_id, student_id = EXCLUDED.student_id, class_id = EXCLUDED.class_id, status = 'activa', observacoes = EXCLUDED.observacoes, updated_at = NOW();
  -- Aluno 17
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Graca Buque Cossa', 'aluno17.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258842375453', 'ativo', true, 'aluno')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'aluno', updated_at = NOW()
  RETURNING id INTO v_student_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_student_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_students (tenant_id, user_id, codigo, nome, data_nascimento, genero, documento_tipo, documento_numero, nuit, telefone, email, endereco, encarregado_nome, encarregado_telefone, encarregado_email, portal_email, portal_ativo, portal_login_tentativas)
  VALUES (5, v_student_uid, 'ALU-PFA-2026-0017', 'Graca Buque Cossa', '2011-10-10', 'F', 'BI', 'BI 110100000529A', '40000009770838', '258842375453', 'aluno17.pfa@nexora.test', 'Bairro do Chamanculo, Maputo', 'Davide Cossa Nhacolo', '258853195773', 'encarregado17.pfa@nexora.test', 'aluno17.pfa@nexora.test', true, 0)
  ON CONFLICT (tenant_id, codigo) DO UPDATE SET user_id = EXCLUDED.user_id, nome = EXCLUDED.nome, data_nascimento = EXCLUDED.data_nascimento, genero = EXCLUDED.genero, documento_numero = EXCLUDED.documento_numero, nuit = EXCLUDED.nuit, telefone = EXCLUDED.telefone, email = EXCLUDED.email, endereco = EXCLUDED.endereco, encarregado_nome = EXCLUDED.encarregado_nome, encarregado_telefone = EXCLUDED.encarregado_telefone, encarregado_email = EXCLUDED.encarregado_email, portal_email = EXCLUDED.portal_email, portal_ativo = true, updated_at = NOW()
  RETURNING id INTO v_student_id;
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Davide Cossa Nhacolo', 'encarregado17.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258853195773', 'ativo', true, 'encarregado')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'encarregado', updated_at = NOW()
  RETURNING id INTO v_guardian_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_guardian_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_guardians (tenant_id, student_id, nome, parentesco, telefone, email, nuit, endereco, principal, autorizado_recolher, user_id, portal_email, portal_ativo, portal_email_verificado, portal_login_tentativas)
  VALUES (5, v_student_id, 'Davide Cossa Nhacolo', 'Tio', '258853195773', 'encarregado17.pfa@nexora.test', '50000006033115', 'Bairro do Inhagoia, Maputo', true, true, v_guardian_uid, 'encarregado17.pfa@nexora.test', true, true, 0)
  ON CONFLICT DO NOTHING;
  INSERT INTO gestao_escolar.school_enrollments (tenant_id, school_year_id, student_id, class_id, numero, data_matricula, status, observacoes)
  VALUES (5, 2, v_student_id, 145, 'MAT-PFA-2026-0017', CURRENT_DATE, 'activa', 'Matricula automatica PFA')
  ON CONFLICT (tenant_id, numero) DO UPDATE SET school_year_id = EXCLUDED.school_year_id, student_id = EXCLUDED.student_id, class_id = EXCLUDED.class_id, status = 'activa', observacoes = EXCLUDED.observacoes, updated_at = NOW();
  -- Aluno 18
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Rosa Mucavele Nhabanga', 'aluno18.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258842229110', 'ativo', true, 'aluno')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'aluno', updated_at = NOW()
  RETURNING id INTO v_student_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_student_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_students (tenant_id, user_id, codigo, nome, data_nascimento, genero, documento_tipo, documento_numero, nuit, telefone, email, endereco, encarregado_nome, encarregado_telefone, encarregado_email, portal_email, portal_ativo, portal_login_tentativas)
  VALUES (5, v_student_uid, 'ALU-PFA-2026-0018', 'Rosa Mucavele Nhabanga', '2012-11-02', 'F', 'BI', 'BI 110100000650A', '40000004576135', '258842229110', 'aluno18.pfa@nexora.test', 'Bairro do Chamanculo, Maputo', 'Lucas Mondlane Cossa', '258855781295', 'encarregado18.pfa@nexora.test', 'aluno18.pfa@nexora.test', true, 0)
  ON CONFLICT (tenant_id, codigo) DO UPDATE SET user_id = EXCLUDED.user_id, nome = EXCLUDED.nome, data_nascimento = EXCLUDED.data_nascimento, genero = EXCLUDED.genero, documento_numero = EXCLUDED.documento_numero, nuit = EXCLUDED.nuit, telefone = EXCLUDED.telefone, email = EXCLUDED.email, endereco = EXCLUDED.endereco, encarregado_nome = EXCLUDED.encarregado_nome, encarregado_telefone = EXCLUDED.encarregado_telefone, encarregado_email = EXCLUDED.encarregado_email, portal_email = EXCLUDED.portal_email, portal_ativo = true, updated_at = NOW()
  RETURNING id INTO v_student_id;
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Lucas Mondlane Cossa', 'encarregado18.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258855781295', 'ativo', true, 'encarregado')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'encarregado', updated_at = NOW()
  RETURNING id INTO v_guardian_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_guardian_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_guardians (tenant_id, student_id, nome, parentesco, telefone, email, nuit, endereco, principal, autorizado_recolher, user_id, portal_email, portal_ativo, portal_email_verificado, portal_login_tentativas)
  VALUES (5, v_student_id, 'Lucas Mondlane Cossa', 'Tutor', '258855781295', 'encarregado18.pfa@nexora.test', '50000003646552', 'Bairro do Inhagoia, Maputo', true, true, v_guardian_uid, 'encarregado18.pfa@nexora.test', true, true, 0)
  ON CONFLICT DO NOTHING;
  INSERT INTO gestao_escolar.school_enrollments (tenant_id, school_year_id, student_id, class_id, numero, data_matricula, status, observacoes)
  VALUES (5, 2, v_student_id, 145, 'MAT-PFA-2026-0018', CURRENT_DATE, 'activa', 'Matricula automatica PFA')
  ON CONFLICT (tenant_id, numero) DO UPDATE SET school_year_id = EXCLUDED.school_year_id, student_id = EXCLUDED.student_id, class_id = EXCLUDED.class_id, status = 'activa', observacoes = EXCLUDED.observacoes, updated_at = NOW();
  -- Aluno 19
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Joana Macuacua Mutombene', 'aluno19.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258846022741', 'ativo', true, 'aluno')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'aluno', updated_at = NOW()
  RETURNING id INTO v_student_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_student_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_students (tenant_id, user_id, codigo, nome, data_nascimento, genero, documento_tipo, documento_numero, nuit, telefone, email, endereco, encarregado_nome, encarregado_telefone, encarregado_email, portal_email, portal_ativo, portal_login_tentativas)
  VALUES (5, v_student_uid, 'ALU-PFA-2026-0019', 'Joana Macuacua Mutombene', '2010-10-03', 'F', 'BI', 'BI 110100000779A', '40000002737893', '258846022741', 'aluno19.pfa@nexora.test', 'Bairro do Chamanculo, Maputo', 'Francisco Maluana Machel', '258855727085', 'encarregado19.pfa@nexora.test', 'aluno19.pfa@nexora.test', true, 0)
  ON CONFLICT (tenant_id, codigo) DO UPDATE SET user_id = EXCLUDED.user_id, nome = EXCLUDED.nome, data_nascimento = EXCLUDED.data_nascimento, genero = EXCLUDED.genero, documento_numero = EXCLUDED.documento_numero, nuit = EXCLUDED.nuit, telefone = EXCLUDED.telefone, email = EXCLUDED.email, endereco = EXCLUDED.endereco, encarregado_nome = EXCLUDED.encarregado_nome, encarregado_telefone = EXCLUDED.encarregado_telefone, encarregado_email = EXCLUDED.encarregado_email, portal_email = EXCLUDED.portal_email, portal_ativo = true, updated_at = NOW()
  RETURNING id INTO v_student_id;
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Francisco Maluana Machel', 'encarregado19.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258855727085', 'ativo', true, 'encarregado')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'encarregado', updated_at = NOW()
  RETURNING id INTO v_guardian_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_guardian_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_guardians (tenant_id, student_id, nome, parentesco, telefone, email, nuit, endereco, principal, autorizado_recolher, user_id, portal_email, portal_ativo, portal_email_verificado, portal_login_tentativas)
  VALUES (5, v_student_id, 'Francisco Maluana Machel', 'Mae', '258855727085', 'encarregado19.pfa@nexora.test', '50000004533779', 'Bairro da Mafalala, Maputo', true, true, v_guardian_uid, 'encarregado19.pfa@nexora.test', true, true, 0)
  ON CONFLICT DO NOTHING;
  INSERT INTO gestao_escolar.school_enrollments (tenant_id, school_year_id, student_id, class_id, numero, data_matricula, status, observacoes)
  VALUES (5, 2, v_student_id, 145, 'MAT-PFA-2026-0019', CURRENT_DATE, 'activa', 'Matricula automatica PFA')
  ON CONFLICT (tenant_id, numero) DO UPDATE SET school_year_id = EXCLUDED.school_year_id, student_id = EXCLUDED.student_id, class_id = EXCLUDED.class_id, status = 'activa', observacoes = EXCLUDED.observacoes, updated_at = NOW();
  -- Aluno 20
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Teresa Timane Matsine', 'aluno20.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258851852264', 'ativo', true, 'aluno')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'aluno', updated_at = NOW()
  RETURNING id INTO v_student_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_student_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_students (tenant_id, user_id, codigo, nome, data_nascimento, genero, documento_tipo, documento_numero, nuit, telefone, email, endereco, encarregado_nome, encarregado_telefone, encarregado_email, portal_email, portal_ativo, portal_login_tentativas)
  VALUES (5, v_student_uid, 'ALU-PFA-2026-0020', 'Teresa Timane Matsine', '2011-07-21', 'F', 'BI', 'BI 110100000194A', '40000008106422', '258851852264', 'aluno20.pfa@nexora.test', 'Bairro Central, Maputo', 'Davide Machel Nhacolo', '258848412769', 'encarregado20.pfa@nexora.test', 'aluno20.pfa@nexora.test', true, 0)
  ON CONFLICT (tenant_id, codigo) DO UPDATE SET user_id = EXCLUDED.user_id, nome = EXCLUDED.nome, data_nascimento = EXCLUDED.data_nascimento, genero = EXCLUDED.genero, documento_numero = EXCLUDED.documento_numero, nuit = EXCLUDED.nuit, telefone = EXCLUDED.telefone, email = EXCLUDED.email, endereco = EXCLUDED.endereco, encarregado_nome = EXCLUDED.encarregado_nome, encarregado_telefone = EXCLUDED.encarregado_telefone, encarregado_email = EXCLUDED.encarregado_email, portal_email = EXCLUDED.portal_email, portal_ativo = true, updated_at = NOW()
  RETURNING id INTO v_student_id;
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Davide Machel Nhacolo', 'encarregado20.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258848412769', 'ativo', true, 'encarregado')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'encarregado', updated_at = NOW()
  RETURNING id INTO v_guardian_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_guardian_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_guardians (tenant_id, student_id, nome, parentesco, telefone, email, nuit, endereco, principal, autorizado_recolher, user_id, portal_email, portal_ativo, portal_email_verificado, portal_login_tentativas)
  VALUES (5, v_student_id, 'Davide Machel Nhacolo', 'Pai', '258848412769', 'encarregado20.pfa@nexora.test', '50000008175395', 'Bairro da Maxaquene, Maputo', true, true, v_guardian_uid, 'encarregado20.pfa@nexora.test', true, true, 0)
  ON CONFLICT DO NOTHING;
  INSERT INTO gestao_escolar.school_enrollments (tenant_id, school_year_id, student_id, class_id, numero, data_matricula, status, observacoes)
  VALUES (5, 2, v_student_id, 145, 'MAT-PFA-2026-0020', CURRENT_DATE, 'activa', 'Matricula automatica PFA')
  ON CONFLICT (tenant_id, numero) DO UPDATE SET school_year_id = EXCLUDED.school_year_id, student_id = EXCLUDED.student_id, class_id = EXCLUDED.class_id, status = 'activa', observacoes = EXCLUDED.observacoes, updated_at = NOW();
  -- Aluno 21
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Graca Mondlane Machel', 'aluno21.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258847194416', 'ativo', true, 'aluno')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'aluno', updated_at = NOW()
  RETURNING id INTO v_student_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_student_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_students (tenant_id, user_id, codigo, nome, data_nascimento, genero, documento_tipo, documento_numero, nuit, telefone, email, endereco, encarregado_nome, encarregado_telefone, encarregado_email, portal_email, portal_ativo, portal_login_tentativas)
  VALUES (5, v_student_uid, 'ALU-PFA-2026-0021', 'Graca Mondlane Machel', '2012-05-30', 'F', 'BI', 'BI 110100000696A', '40000003484601', '258847194416', 'aluno21.pfa@nexora.test', 'Bairro do Alto Mae, Maputo', 'Sergio Guambe Sitoe', '258854524499', 'encarregado21.pfa@nexora.test', 'aluno21.pfa@nexora.test', true, 0)
  ON CONFLICT (tenant_id, codigo) DO UPDATE SET user_id = EXCLUDED.user_id, nome = EXCLUDED.nome, data_nascimento = EXCLUDED.data_nascimento, genero = EXCLUDED.genero, documento_numero = EXCLUDED.documento_numero, nuit = EXCLUDED.nuit, telefone = EXCLUDED.telefone, email = EXCLUDED.email, endereco = EXCLUDED.endereco, encarregado_nome = EXCLUDED.encarregado_nome, encarregado_telefone = EXCLUDED.encarregado_telefone, encarregado_email = EXCLUDED.encarregado_email, portal_email = EXCLUDED.portal_email, portal_ativo = true, updated_at = NOW()
  RETURNING id INTO v_student_id;
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Sergio Guambe Sitoe', 'encarregado21.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258854524499', 'ativo', true, 'encarregado')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'encarregado', updated_at = NOW()
  RETURNING id INTO v_guardian_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_guardian_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_guardians (tenant_id, student_id, nome, parentesco, telefone, email, nuit, endereco, principal, autorizado_recolher, user_id, portal_email, portal_ativo, portal_email_verificado, portal_login_tentativas)
  VALUES (5, v_student_id, 'Sergio Guambe Sitoe', 'Tio', '258854524499', 'encarregado21.pfa@nexora.test', '50000005186414', 'Bairro da Polana, Maputo', true, true, v_guardian_uid, 'encarregado21.pfa@nexora.test', true, true, 0)
  ON CONFLICT DO NOTHING;
  INSERT INTO gestao_escolar.school_enrollments (tenant_id, school_year_id, student_id, class_id, numero, data_matricula, status, observacoes)
  VALUES (5, 2, v_student_id, 145, 'MAT-PFA-2026-0021', CURRENT_DATE, 'activa', 'Matricula automatica PFA')
  ON CONFLICT (tenant_id, numero) DO UPDATE SET school_year_id = EXCLUDED.school_year_id, student_id = EXCLUDED.student_id, class_id = EXCLUDED.class_id, status = 'activa', observacoes = EXCLUDED.observacoes, updated_at = NOW();
  -- Aluno 22
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Joana Bila Mutombene', 'aluno22.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258844971793', 'ativo', true, 'aluno')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'aluno', updated_at = NOW()
  RETURNING id INTO v_student_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_student_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_students (tenant_id, user_id, codigo, nome, data_nascimento, genero, documento_tipo, documento_numero, nuit, telefone, email, endereco, encarregado_nome, encarregado_telefone, encarregado_email, portal_email, portal_ativo, portal_login_tentativas)
  VALUES (5, v_student_uid, 'ALU-PFA-2026-0022', 'Joana Bila Mutombene', '2010-12-29', 'F', 'BI', 'BI 110100000985A', '40000003726327', '258844971793', 'aluno22.pfa@nexora.test', 'Bairro do Munhava, Maputo', 'Manuel Tembe Bila', '258845476257', 'encarregado22.pfa@nexora.test', 'aluno22.pfa@nexora.test', true, 0)
  ON CONFLICT (tenant_id, codigo) DO UPDATE SET user_id = EXCLUDED.user_id, nome = EXCLUDED.nome, data_nascimento = EXCLUDED.data_nascimento, genero = EXCLUDED.genero, documento_numero = EXCLUDED.documento_numero, nuit = EXCLUDED.nuit, telefone = EXCLUDED.telefone, email = EXCLUDED.email, endereco = EXCLUDED.endereco, encarregado_nome = EXCLUDED.encarregado_nome, encarregado_telefone = EXCLUDED.encarregado_telefone, encarregado_email = EXCLUDED.encarregado_email, portal_email = EXCLUDED.portal_email, portal_ativo = true, updated_at = NOW()
  RETURNING id INTO v_student_id;
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Manuel Tembe Bila', 'encarregado22.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258845476257', 'ativo', true, 'encarregado')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'encarregado', updated_at = NOW()
  RETURNING id INTO v_guardian_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_guardian_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_guardians (tenant_id, student_id, nome, parentesco, telefone, email, nuit, endereco, principal, autorizado_recolher, user_id, portal_email, portal_ativo, portal_email_verificado, portal_login_tentativas)
  VALUES (5, v_student_id, 'Manuel Tembe Bila', 'Tia', '258845476257', 'encarregado22.pfa@nexora.test', '50000003670896', 'Bairro da Polana, Maputo', true, true, v_guardian_uid, 'encarregado22.pfa@nexora.test', true, true, 0)
  ON CONFLICT DO NOTHING;
  INSERT INTO gestao_escolar.school_enrollments (tenant_id, school_year_id, student_id, class_id, numero, data_matricula, status, observacoes)
  VALUES (5, 2, v_student_id, 145, 'MAT-PFA-2026-0022', CURRENT_DATE, 'activa', 'Matricula automatica PFA')
  ON CONFLICT (tenant_id, numero) DO UPDATE SET school_year_id = EXCLUDED.school_year_id, student_id = EXCLUDED.student_id, class_id = EXCLUDED.class_id, status = 'activa', observacoes = EXCLUDED.observacoes, updated_at = NOW();
  -- Aluno 23
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Ana Matsine Cossa', 'aluno23.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258848722606', 'ativo', true, 'aluno')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'aluno', updated_at = NOW()
  RETURNING id INTO v_student_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_student_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_students (tenant_id, user_id, codigo, nome, data_nascimento, genero, documento_tipo, documento_numero, nuit, telefone, email, endereco, encarregado_nome, encarregado_telefone, encarregado_email, portal_email, portal_ativo, portal_login_tentativas)
  VALUES (5, v_student_uid, 'ALU-PFA-2026-0023', 'Ana Matsine Cossa', '2011-04-12', 'F', 'BI', 'BI 110100000458A', '40000006120253', '258848722606', 'aluno23.pfa@nexora.test', 'Bairro da Coop, Maputo', 'Jose Zunguze Tembe', '258852164686', 'encarregado23.pfa@nexora.test', 'aluno23.pfa@nexora.test', true, 0)
  ON CONFLICT (tenant_id, codigo) DO UPDATE SET user_id = EXCLUDED.user_id, nome = EXCLUDED.nome, data_nascimento = EXCLUDED.data_nascimento, genero = EXCLUDED.genero, documento_numero = EXCLUDED.documento_numero, nuit = EXCLUDED.nuit, telefone = EXCLUDED.telefone, email = EXCLUDED.email, endereco = EXCLUDED.endereco, encarregado_nome = EXCLUDED.encarregado_nome, encarregado_telefone = EXCLUDED.encarregado_telefone, encarregado_email = EXCLUDED.encarregado_email, portal_email = EXCLUDED.portal_email, portal_ativo = true, updated_at = NOW()
  RETURNING id INTO v_student_id;
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Jose Zunguze Tembe', 'encarregado23.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258852164686', 'ativo', true, 'encarregado')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'encarregado', updated_at = NOW()
  RETURNING id INTO v_guardian_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_guardian_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_guardians (tenant_id, student_id, nome, parentesco, telefone, email, nuit, endereco, principal, autorizado_recolher, user_id, portal_email, portal_ativo, portal_email_verificado, portal_login_tentativas)
  VALUES (5, v_student_id, 'Jose Zunguze Tembe', 'Irmao', '258852164686', 'encarregado23.pfa@nexora.test', '50000005682940', 'Bairro da Mafalala, Maputo', true, true, v_guardian_uid, 'encarregado23.pfa@nexora.test', true, true, 0)
  ON CONFLICT DO NOTHING;
  INSERT INTO gestao_escolar.school_enrollments (tenant_id, school_year_id, student_id, class_id, numero, data_matricula, status, observacoes)
  VALUES (5, 2, v_student_id, 145, 'MAT-PFA-2026-0023', CURRENT_DATE, 'activa', 'Matricula automatica PFA')
  ON CONFLICT (tenant_id, numero) DO UPDATE SET school_year_id = EXCLUDED.school_year_id, student_id = EXCLUDED.student_id, class_id = EXCLUDED.class_id, status = 'activa', observacoes = EXCLUDED.observacoes, updated_at = NOW();
  -- Aluno 24
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Clara Zunguze Maluana', 'aluno24.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258851463060', 'ativo', true, 'aluno')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'aluno', updated_at = NOW()
  RETURNING id INTO v_student_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_student_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_students (tenant_id, user_id, codigo, nome, data_nascimento, genero, documento_tipo, documento_numero, nuit, telefone, email, endereco, encarregado_nome, encarregado_telefone, encarregado_email, portal_email, portal_ativo, portal_login_tentativas)
  VALUES (5, v_student_uid, 'ALU-PFA-2026-0024', 'Clara Zunguze Maluana', '2011-01-01', 'F', 'BI', 'BI 110100000218A', '40000005382463', '258851463060', 'aluno24.pfa@nexora.test', 'Bairro do Laulane, Maputo', 'Ana Chissano Mutombene', '258856799667', 'encarregado24.pfa@nexora.test', 'aluno24.pfa@nexora.test', true, 0)
  ON CONFLICT (tenant_id, codigo) DO UPDATE SET user_id = EXCLUDED.user_id, nome = EXCLUDED.nome, data_nascimento = EXCLUDED.data_nascimento, genero = EXCLUDED.genero, documento_numero = EXCLUDED.documento_numero, nuit = EXCLUDED.nuit, telefone = EXCLUDED.telefone, email = EXCLUDED.email, endereco = EXCLUDED.endereco, encarregado_nome = EXCLUDED.encarregado_nome, encarregado_telefone = EXCLUDED.encarregado_telefone, encarregado_email = EXCLUDED.encarregado_email, portal_email = EXCLUDED.portal_email, portal_ativo = true, updated_at = NOW()
  RETURNING id INTO v_student_id;
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Ana Chissano Mutombene', 'encarregado24.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258856799667', 'ativo', true, 'encarregado')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'encarregado', updated_at = NOW()
  RETURNING id INTO v_guardian_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_guardian_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_guardians (tenant_id, student_id, nome, parentesco, telefone, email, nuit, endereco, principal, autorizado_recolher, user_id, portal_email, portal_ativo, portal_email_verificado, portal_login_tentativas)
  VALUES (5, v_student_id, 'Ana Chissano Mutombene', 'Avo', '258856799667', 'encarregado24.pfa@nexora.test', '50000006262632', 'Bairro do Munhava, Maputo', true, true, v_guardian_uid, 'encarregado24.pfa@nexora.test', true, true, 0)
  ON CONFLICT DO NOTHING;
  INSERT INTO gestao_escolar.school_enrollments (tenant_id, school_year_id, student_id, class_id, numero, data_matricula, status, observacoes)
  VALUES (5, 2, v_student_id, 145, 'MAT-PFA-2026-0024', CURRENT_DATE, 'activa', 'Matricula automatica PFA')
  ON CONFLICT (tenant_id, numero) DO UPDATE SET school_year_id = EXCLUDED.school_year_id, student_id = EXCLUDED.student_id, class_id = EXCLUDED.class_id, status = 'activa', observacoes = EXCLUDED.observacoes, updated_at = NOW();
  -- Aluno 25
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Clara Chissano Zunguze', 'aluno25.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258845273534', 'ativo', true, 'aluno')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'aluno', updated_at = NOW()
  RETURNING id INTO v_student_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_student_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_students (tenant_id, user_id, codigo, nome, data_nascimento, genero, documento_tipo, documento_numero, nuit, telefone, email, endereco, encarregado_nome, encarregado_telefone, encarregado_email, portal_email, portal_ativo, portal_login_tentativas)
  VALUES (5, v_student_uid, 'ALU-PFA-2026-0025', 'Clara Chissano Zunguze', '2010-01-04', 'F', 'BI', 'BI 110100000145A', '40000008315831', '258845273534', 'aluno25.pfa@nexora.test', 'Bairro da Maxaquene, Maputo', 'Lucas Bila Mondlane', '258856266630', 'encarregado25.pfa@nexora.test', 'aluno25.pfa@nexora.test', true, 0)
  ON CONFLICT (tenant_id, codigo) DO UPDATE SET user_id = EXCLUDED.user_id, nome = EXCLUDED.nome, data_nascimento = EXCLUDED.data_nascimento, genero = EXCLUDED.genero, documento_numero = EXCLUDED.documento_numero, nuit = EXCLUDED.nuit, telefone = EXCLUDED.telefone, email = EXCLUDED.email, endereco = EXCLUDED.endereco, encarregado_nome = EXCLUDED.encarregado_nome, encarregado_telefone = EXCLUDED.encarregado_telefone, encarregado_email = EXCLUDED.encarregado_email, portal_email = EXCLUDED.portal_email, portal_ativo = true, updated_at = NOW()
  RETURNING id INTO v_student_id;
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Lucas Bila Mondlane', 'encarregado25.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258856266630', 'ativo', true, 'encarregado')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'encarregado', updated_at = NOW()
  RETURNING id INTO v_guardian_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_guardian_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_guardians (tenant_id, student_id, nome, parentesco, telefone, email, nuit, endereco, principal, autorizado_recolher, user_id, portal_email, portal_ativo, portal_email_verificado, portal_login_tentativas)
  VALUES (5, v_student_id, 'Lucas Bila Mondlane', 'Avo', '258856266630', 'encarregado25.pfa@nexora.test', '50000003090865', 'Bairro do Chamanculo, Maputo', true, true, v_guardian_uid, 'encarregado25.pfa@nexora.test', true, true, 0)
  ON CONFLICT DO NOTHING;
  INSERT INTO gestao_escolar.school_enrollments (tenant_id, school_year_id, student_id, class_id, numero, data_matricula, status, observacoes)
  VALUES (5, 2, v_student_id, 145, 'MAT-PFA-2026-0025', CURRENT_DATE, 'activa', 'Matricula automatica PFA')
  ON CONFLICT (tenant_id, numero) DO UPDATE SET school_year_id = EXCLUDED.school_year_id, student_id = EXCLUDED.student_id, class_id = EXCLUDED.class_id, status = 'activa', observacoes = EXCLUDED.observacoes, updated_at = NOW();
  -- Aluno 26
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Lucia Bila Tembe', 'aluno26.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258855960271', 'ativo', true, 'aluno')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'aluno', updated_at = NOW()
  RETURNING id INTO v_student_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_student_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_students (tenant_id, user_id, codigo, nome, data_nascimento, genero, documento_tipo, documento_numero, nuit, telefone, email, endereco, encarregado_nome, encarregado_telefone, encarregado_email, portal_email, portal_ativo, portal_login_tentativas)
  VALUES (5, v_student_uid, 'ALU-PFA-2026-0026', 'Lucia Bila Tembe', '2011-01-28', 'F', 'BI', 'BI 110100000667A', '40000003135534', '258855960271', 'aluno26.pfa@nexora.test', 'Bairro do Munhava, Maputo', 'Lucilia Mutombene Buque', '258857812810', 'encarregado26.pfa@nexora.test', 'aluno26.pfa@nexora.test', true, 0)
  ON CONFLICT (tenant_id, codigo) DO UPDATE SET user_id = EXCLUDED.user_id, nome = EXCLUDED.nome, data_nascimento = EXCLUDED.data_nascimento, genero = EXCLUDED.genero, documento_numero = EXCLUDED.documento_numero, nuit = EXCLUDED.nuit, telefone = EXCLUDED.telefone, email = EXCLUDED.email, endereco = EXCLUDED.endereco, encarregado_nome = EXCLUDED.encarregado_nome, encarregado_telefone = EXCLUDED.encarregado_telefone, encarregado_email = EXCLUDED.encarregado_email, portal_email = EXCLUDED.portal_email, portal_ativo = true, updated_at = NOW()
  RETURNING id INTO v_student_id;
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Lucilia Mutombene Buque', 'encarregado26.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258857812810', 'ativo', true, 'encarregado')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'encarregado', updated_at = NOW()
  RETURNING id INTO v_guardian_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_guardian_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_guardians (tenant_id, student_id, nome, parentesco, telefone, email, nuit, endereco, principal, autorizado_recolher, user_id, portal_email, portal_ativo, portal_email_verificado, portal_login_tentativas)
  VALUES (5, v_student_id, 'Lucilia Mutombene Buque', 'Tio', '258857812810', 'encarregado26.pfa@nexora.test', '50000001006810', 'Bairro do Chamanculo, Maputo', true, true, v_guardian_uid, 'encarregado26.pfa@nexora.test', true, true, 0)
  ON CONFLICT DO NOTHING;
  INSERT INTO gestao_escolar.school_enrollments (tenant_id, school_year_id, student_id, class_id, numero, data_matricula, status, observacoes)
  VALUES (5, 2, v_student_id, 145, 'MAT-PFA-2026-0026', CURRENT_DATE, 'activa', 'Matricula automatica PFA')
  ON CONFLICT (tenant_id, numero) DO UPDATE SET school_year_id = EXCLUDED.school_year_id, student_id = EXCLUDED.student_id, class_id = EXCLUDED.class_id, status = 'activa', observacoes = EXCLUDED.observacoes, updated_at = NOW();
  -- Aluno 27
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Felicidade Bila Buque', 'aluno27.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258858801207', 'ativo', true, 'aluno')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'aluno', updated_at = NOW()
  RETURNING id INTO v_student_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_student_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_students (tenant_id, user_id, codigo, nome, data_nascimento, genero, documento_tipo, documento_numero, nuit, telefone, email, endereco, encarregado_nome, encarregado_telefone, encarregado_email, portal_email, portal_ativo, portal_login_tentativas)
  VALUES (5, v_student_uid, 'ALU-PFA-2026-0027', 'Felicidade Bila Buque', '2011-03-14', 'F', 'BI', 'BI 110100000552A', '40000008418210', '258858801207', 'aluno27.pfa@nexora.test', 'Bairro da Maxaquene, Maputo', 'Lucilia Mondlane Macuacua', '258852566777', 'encarregado27.pfa@nexora.test', 'aluno27.pfa@nexora.test', true, 0)
  ON CONFLICT (tenant_id, codigo) DO UPDATE SET user_id = EXCLUDED.user_id, nome = EXCLUDED.nome, data_nascimento = EXCLUDED.data_nascimento, genero = EXCLUDED.genero, documento_numero = EXCLUDED.documento_numero, nuit = EXCLUDED.nuit, telefone = EXCLUDED.telefone, email = EXCLUDED.email, endereco = EXCLUDED.endereco, encarregado_nome = EXCLUDED.encarregado_nome, encarregado_telefone = EXCLUDED.encarregado_telefone, encarregado_email = EXCLUDED.encarregado_email, portal_email = EXCLUDED.portal_email, portal_ativo = true, updated_at = NOW()
  RETURNING id INTO v_student_id;
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Lucilia Mondlane Macuacua', 'encarregado27.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258852566777', 'ativo', true, 'encarregado')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'encarregado', updated_at = NOW()
  RETURNING id INTO v_guardian_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_guardian_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_guardians (tenant_id, student_id, nome, parentesco, telefone, email, nuit, endereco, principal, autorizado_recolher, user_id, portal_email, portal_ativo, portal_email_verificado, portal_login_tentativas)
  VALUES (5, v_student_id, 'Lucilia Mondlane Macuacua', 'Mae', '258852566777', 'encarregado27.pfa@nexora.test', '50000004940441', 'Bairro do Chamanculo, Maputo', true, true, v_guardian_uid, 'encarregado27.pfa@nexora.test', true, true, 0)
  ON CONFLICT DO NOTHING;
  INSERT INTO gestao_escolar.school_enrollments (tenant_id, school_year_id, student_id, class_id, numero, data_matricula, status, observacoes)
  VALUES (5, 2, v_student_id, 145, 'MAT-PFA-2026-0027', CURRENT_DATE, 'activa', 'Matricula automatica PFA')
  ON CONFLICT (tenant_id, numero) DO UPDATE SET school_year_id = EXCLUDED.school_year_id, student_id = EXCLUDED.student_id, class_id = EXCLUDED.class_id, status = 'activa', observacoes = EXCLUDED.observacoes, updated_at = NOW();
  -- Aluno 28
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Felicidade Machel Mucavele', 'aluno28.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258845107776', 'ativo', true, 'aluno')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'aluno', updated_at = NOW()
  RETURNING id INTO v_student_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_student_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_students (tenant_id, user_id, codigo, nome, data_nascimento, genero, documento_tipo, documento_numero, nuit, telefone, email, endereco, encarregado_nome, encarregado_telefone, encarregado_email, portal_email, portal_ativo, portal_login_tentativas)
  VALUES (5, v_student_uid, 'ALU-PFA-2026-0028', 'Felicidade Machel Mucavele', '2012-07-21', 'F', 'BI', 'BI 110100000586A', '40000002221854', '258845107776', 'aluno28.pfa@nexora.test', 'Bairro do Munhava, Maputo', 'Mateus Matsine Zunguze', '258843475836', 'encarregado28.pfa@nexora.test', 'aluno28.pfa@nexora.test', true, 0)
  ON CONFLICT (tenant_id, codigo) DO UPDATE SET user_id = EXCLUDED.user_id, nome = EXCLUDED.nome, data_nascimento = EXCLUDED.data_nascimento, genero = EXCLUDED.genero, documento_numero = EXCLUDED.documento_numero, nuit = EXCLUDED.nuit, telefone = EXCLUDED.telefone, email = EXCLUDED.email, endereco = EXCLUDED.endereco, encarregado_nome = EXCLUDED.encarregado_nome, encarregado_telefone = EXCLUDED.encarregado_telefone, encarregado_email = EXCLUDED.encarregado_email, portal_email = EXCLUDED.portal_email, portal_ativo = true, updated_at = NOW()
  RETURNING id INTO v_student_id;
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Mateus Matsine Zunguze', 'encarregado28.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258843475836', 'ativo', true, 'encarregado')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'encarregado', updated_at = NOW()
  RETURNING id INTO v_guardian_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_guardian_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_guardians (tenant_id, student_id, nome, parentesco, telefone, email, nuit, endereco, principal, autorizado_recolher, user_id, portal_email, portal_ativo, portal_email_verificado, portal_login_tentativas)
  VALUES (5, v_student_id, 'Mateus Matsine Zunguze', 'Tutor', '258843475836', 'encarregado28.pfa@nexora.test', '50000001093026', 'Bairro da Polana, Maputo', true, true, v_guardian_uid, 'encarregado28.pfa@nexora.test', true, true, 0)
  ON CONFLICT DO NOTHING;
  INSERT INTO gestao_escolar.school_enrollments (tenant_id, school_year_id, student_id, class_id, numero, data_matricula, status, observacoes)
  VALUES (5, 2, v_student_id, 145, 'MAT-PFA-2026-0028', CURRENT_DATE, 'activa', 'Matricula automatica PFA')
  ON CONFLICT (tenant_id, numero) DO UPDATE SET school_year_id = EXCLUDED.school_year_id, student_id = EXCLUDED.student_id, class_id = EXCLUDED.class_id, status = 'activa', observacoes = EXCLUDED.observacoes, updated_at = NOW();
  -- Aluno 29
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Sandra Cossa Mutemba', 'aluno29.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258851842524', 'ativo', true, 'aluno')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'aluno', updated_at = NOW()
  RETURNING id INTO v_student_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_student_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_students (tenant_id, user_id, codigo, nome, data_nascimento, genero, documento_tipo, documento_numero, nuit, telefone, email, endereco, encarregado_nome, encarregado_telefone, encarregado_email, portal_email, portal_ativo, portal_login_tentativas)
  VALUES (5, v_student_uid, 'ALU-PFA-2026-0029', 'Sandra Cossa Mutemba', '2010-09-06', 'F', 'BI', 'BI 110100000670A', '40000005180853', '258851842524', 'aluno29.pfa@nexora.test', 'Bairro do Inhagoia, Maputo', 'Ricardo Timane Maluana', '258858425149', 'encarregado29.pfa@nexora.test', 'aluno29.pfa@nexora.test', true, 0)
  ON CONFLICT (tenant_id, codigo) DO UPDATE SET user_id = EXCLUDED.user_id, nome = EXCLUDED.nome, data_nascimento = EXCLUDED.data_nascimento, genero = EXCLUDED.genero, documento_numero = EXCLUDED.documento_numero, nuit = EXCLUDED.nuit, telefone = EXCLUDED.telefone, email = EXCLUDED.email, endereco = EXCLUDED.endereco, encarregado_nome = EXCLUDED.encarregado_nome, encarregado_telefone = EXCLUDED.encarregado_telefone, encarregado_email = EXCLUDED.encarregado_email, portal_email = EXCLUDED.portal_email, portal_ativo = true, updated_at = NOW()
  RETURNING id INTO v_student_id;
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Ricardo Timane Maluana', 'encarregado29.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258858425149', 'ativo', true, 'encarregado')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'encarregado', updated_at = NOW()
  RETURNING id INTO v_guardian_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_guardian_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_guardians (tenant_id, student_id, nome, parentesco, telefone, email, nuit, endereco, principal, autorizado_recolher, user_id, portal_email, portal_ativo, portal_email_verificado, portal_login_tentativas)
  VALUES (5, v_student_id, 'Ricardo Timane Maluana', 'Tutor', '258858425149', 'encarregado29.pfa@nexora.test', '50000009468772', 'Bairro do Munhava, Maputo', true, true, v_guardian_uid, 'encarregado29.pfa@nexora.test', true, true, 0)
  ON CONFLICT DO NOTHING;
  INSERT INTO gestao_escolar.school_enrollments (tenant_id, school_year_id, student_id, class_id, numero, data_matricula, status, observacoes)
  VALUES (5, 2, v_student_id, 145, 'MAT-PFA-2026-0029', CURRENT_DATE, 'activa', 'Matricula automatica PFA')
  ON CONFLICT (tenant_id, numero) DO UPDATE SET school_year_id = EXCLUDED.school_year_id, student_id = EXCLUDED.student_id, class_id = EXCLUDED.class_id, status = 'activa', observacoes = EXCLUDED.observacoes, updated_at = NOW();
  -- Aluno 30
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Joana Nhabanga Mutemba', 'aluno30.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258858550917', 'ativo', true, 'aluno')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'aluno', updated_at = NOW()
  RETURNING id INTO v_student_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_student_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_students (tenant_id, user_id, codigo, nome, data_nascimento, genero, documento_tipo, documento_numero, nuit, telefone, email, endereco, encarregado_nome, encarregado_telefone, encarregado_email, portal_email, portal_ativo, portal_login_tentativas)
  VALUES (5, v_student_uid, 'ALU-PFA-2026-0030', 'Joana Nhabanga Mutemba', '2011-07-22', 'F', 'BI', 'BI 110100000365A', '40000005147994', '258858550917', 'aluno30.pfa@nexora.test', 'Bairro da Maxaquene, Maputo', 'Isabel Nhacolo Nhabanga', '258845793722', 'encarregado30.pfa@nexora.test', 'aluno30.pfa@nexora.test', true, 0)
  ON CONFLICT (tenant_id, codigo) DO UPDATE SET user_id = EXCLUDED.user_id, nome = EXCLUDED.nome, data_nascimento = EXCLUDED.data_nascimento, genero = EXCLUDED.genero, documento_numero = EXCLUDED.documento_numero, nuit = EXCLUDED.nuit, telefone = EXCLUDED.telefone, email = EXCLUDED.email, endereco = EXCLUDED.endereco, encarregado_nome = EXCLUDED.encarregado_nome, encarregado_telefone = EXCLUDED.encarregado_telefone, encarregado_email = EXCLUDED.encarregado_email, portal_email = EXCLUDED.portal_email, portal_ativo = true, updated_at = NOW()
  RETURNING id INTO v_student_id;
  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
  VALUES ('Isabel Nhacolo Nhabanga', 'encarregado30.pfa@nexora.test', '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG', '258845793722', 'ativo', true, 'encarregado')
  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'encarregado', updated_at = NOW()
  RETURNING id INTO v_guardian_uid;
  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_guardian_uid, 5, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();
  INSERT INTO gestao_escolar.school_guardians (tenant_id, student_id, nome, parentesco, telefone, email, nuit, endereco, principal, autorizado_recolher, user_id, portal_email, portal_ativo, portal_email_verificado, portal_login_tentativas)
  VALUES (5, v_student_id, 'Isabel Nhacolo Nhabanga', 'Tio', '258845793722', 'encarregado30.pfa@nexora.test', '50000004934149', 'Bairro do Chamanculo, Maputo', true, true, v_guardian_uid, 'encarregado30.pfa@nexora.test', true, true, 0)
  ON CONFLICT DO NOTHING;
  INSERT INTO gestao_escolar.school_enrollments (tenant_id, school_year_id, student_id, class_id, numero, data_matricula, status, observacoes)
  VALUES (5, 2, v_student_id, 145, 'MAT-PFA-2026-0030', CURRENT_DATE, 'activa', 'Matricula automatica PFA')
  ON CONFLICT (tenant_id, numero) DO UPDATE SET school_year_id = EXCLUDED.school_year_id, student_id = EXCLUDED.student_id, class_id = EXCLUDED.class_id, status = 'activa', observacoes = EXCLUDED.observacoes, updated_at = NOW();
END $$;
COMMIT;