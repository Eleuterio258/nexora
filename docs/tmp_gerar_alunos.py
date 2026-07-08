#!/usr/bin/env python3
import random
import datetime

random.seed(42)

nomes_m = [
    "Carlos", "Joao", "Pedro", "Francisco", "Antonio", "Manuel", "Jose", "Mariano",
    "Armando", "Sergio", "Davide", "Lucas", "Mateus", "Samuel", "Ricardo", "Filipe",
    "Paulo", "Daniel", "Tiago", "Bruno"
]
nomes_f = [
    "Maria", "Ana", "Rosa", "Graca", "Esperanca", "Lucilia", "Felicidade", "Isabel",
    "Teresa", "Lucia", "Celia", "Elsa", "Liliana", "Sandra", "Patricia", "Fernanda",
    "Clara", "Joana", "Beatriz", "Diana"
]
apelidos = [
    "Mucavele", "Sitoe", "Mondlane", "Chissano", "Machel", "Mutemba", "Silvestre",
    "Cossa", "Nhacolo", "Macuacua", "Tembe", "Guambe", "Zunguze", "Bila", "Nhabanga",
    "Matsine", "Timane", "Maluana", "Buque", "Mutombene"
]
bairros = [
    "Bairro Central", "Bairro da Polana", "Bairro do Alto Mae", "Bairro da Coop",
    "Bairro do Chamanculo", "Bairro da Mafalala", "Bairro do Munhava", "Bairro do Inhagoia",
    "Bairro da Maxaquene", "Bairro do Laulane"
]
parentescos = ["Pai", "Mae", "Tio", "Tia", "Avo", "Irmao", "Tutor"]

hash_senha = "$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG"
tenant_id = 5
class_id = 145
year_id = 2

sql = []
sql.append("SET search_path TO gestao_escolar, public;")
sql.append("UPDATE gestao_escolar.school_classes SET capacidade = 40 WHERE id = 145;")
sql.append("BEGIN;")
sql.append("SET search_path TO gestao_escolar, public, auth;")
sql.append("DO $$")
sql.append("DECLARE")
sql.append("  v_student_uid bigint;")
sql.append("  v_guardian_uid bigint;")
sql.append("  v_student_id bigint;")
sql.append("  v_guardian_id bigint;")
sql.append("BEGIN")

used_emails = set()
used_nuits = set()
used_docs = set()

def make_phone():
    return f"2588{random.choice(['4','5'])}{random.randint(1000000,9999999)}"

def make_nuit(prefix):
    while True:
        n = f"{prefix}{random.randint(1000000,9999999)}"
        if n not in used_nuits:
            used_nuits.add(n)
            return n

def make_doc():
    while True:
        d = f"BI 110100000{random.randint(100,999)}A"
        if d not in used_docs:
            used_docs.add(d)
            return d

def make_email(tipo, idx):
    return f"{tipo}{idx:02d}.pfa@nexora.test"

def make_name(genero):
    if genero == 'M':
        nome = random.choice(nomes_m)
    else:
        nome = random.choice(nomes_f)
    apelido1 = random.choice(apelidos)
    apelido2 = random.choice(apelidos)
    while apelido2 == apelido1:
        apelido2 = random.choice(apelidos)
    return f"{nome} {apelido1} {apelido2}"

def make_dob():
    start = datetime.date(2010, 1, 1)
    end = datetime.date(2012, 12, 31)
    delta = end - start
    return start + datetime.timedelta(days=random.randint(0, delta.days))

for i in range(1, 31):
    genero = 'M' if i <= 15 else 'F'
    aluno_nome = make_name(genero)
    aluno_email = make_email("aluno", i)
    aluno_tel = make_phone()
    aluno_doc = make_doc()
    aluno_nuit = make_nuit("4000000")
    aluno_dob = make_dob()
    aluno_endereco = f"{random.choice(bairros)}, Maputo"

    guardian_genero = 'M' if random.choice([True, False]) else 'F'
    guardian_nome = make_name(guardian_genero)
    guardian_email = make_email("encarregado", i)
    guardian_tel = make_phone()
    guardian_nuit = make_nuit("5000000")
    guardian_endereco = f"{random.choice(bairros)}, Maputo"
    parentesco = random.choice(parentescos)
    matricula_num = f"MAT-PFA-2026-{i:04d}"
    aluno_codigo = f"ALU-PFA-2026-{i:04d}"

    sql.append(f"  -- Aluno {i}")
    sql.append(f"  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)")
    sql.append(f"  VALUES ('{aluno_nome}', '{aluno_email}', '{hash_senha}', '{aluno_tel}', 'ativo', true, 'aluno')")
    sql.append(f"  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'aluno', updated_at = NOW()")
    sql.append(f"  RETURNING id INTO v_student_uid;")
    sql.append(f"  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_student_uid, {tenant_id}, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();")
    sql.append(f"  INSERT INTO gestao_escolar.school_students (tenant_id, user_id, codigo, nome, data_nascimento, genero, documento_tipo, documento_numero, nuit, telefone, email, endereco, encarregado_nome, encarregado_telefone, encarregado_email, portal_email, portal_ativo, portal_login_tentativas)")
    sql.append(f"  VALUES ({tenant_id}, v_student_uid, '{aluno_codigo}', '{aluno_nome}', '{aluno_dob}', '{genero}', 'BI', '{aluno_doc}', '{aluno_nuit}', '{aluno_tel}', '{aluno_email}', '{aluno_endereco}', '{guardian_nome}', '{guardian_tel}', '{guardian_email}', '{aluno_email}', true, 0)")
    sql.append(f"  ON CONFLICT (tenant_id, codigo) DO UPDATE SET user_id = EXCLUDED.user_id, nome = EXCLUDED.nome, data_nascimento = EXCLUDED.data_nascimento, genero = EXCLUDED.genero, documento_numero = EXCLUDED.documento_numero, nuit = EXCLUDED.nuit, telefone = EXCLUDED.telefone, email = EXCLUDED.email, endereco = EXCLUDED.endereco, encarregado_nome = EXCLUDED.encarregado_nome, encarregado_telefone = EXCLUDED.encarregado_telefone, encarregado_email = EXCLUDED.encarregado_email, portal_email = EXCLUDED.portal_email, portal_ativo = true, updated_at = NOW()")
    sql.append(f"  RETURNING id INTO v_student_id;")
    sql.append(f"  INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)")
    sql.append(f"  VALUES ('{guardian_nome}', '{guardian_email}', '{hash_senha}', '{guardian_tel}', 'ativo', true, 'encarregado')")
    sql.append(f"  ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, telefone = EXCLUDED.telefone, estado = 'ativo', tipo = 'encarregado', updated_at = NOW()")
    sql.append(f"  RETURNING id INTO v_guardian_uid;")
    sql.append(f"  INSERT INTO auth.memberships (user_id, tenant_id, ativo, escopo) VALUES (v_guardian_uid, {tenant_id}, true, 'escola') ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, ativo = true, escopo = 'escola', updated_at = NOW();")
    sql.append(f"  INSERT INTO gestao_escolar.school_guardians (tenant_id, student_id, nome, parentesco, telefone, email, nuit, endereco, principal, autorizado_recolher, user_id, portal_email, portal_ativo, portal_email_verificado, portal_login_tentativas)")
    sql.append(f"  VALUES ({tenant_id}, v_student_id, '{guardian_nome}', '{parentesco}', '{guardian_tel}', '{guardian_email}', '{guardian_nuit}', '{guardian_endereco}', true, true, v_guardian_uid, '{guardian_email}', true, true, 0)")
    sql.append(f"  ON CONFLICT DO NOTHING;")
    sql.append(f"  INSERT INTO gestao_escolar.school_enrollments (tenant_id, school_year_id, student_id, class_id, numero, data_matricula, status, observacoes)")
    sql.append(f"  VALUES ({tenant_id}, {year_id}, v_student_id, {class_id}, '{matricula_num}', CURRENT_DATE, 'activa', 'Matricula automatica PFA')")
    sql.append(f"  ON CONFLICT (tenant_id, numero) DO UPDATE SET school_year_id = EXCLUDED.school_year_id, student_id = EXCLUDED.student_id, class_id = EXCLUDED.class_id, status = 'activa', observacoes = EXCLUDED.observacoes, updated_at = NOW();")

sql.append("END $$;")
sql.append("COMMIT;")

with open("tmp_alunos_encarregados.sql", "w", encoding="utf-8") as f:
    f.write("\n".join(sql))

print("Gerado tmp_alunos_encarregados.sql")
