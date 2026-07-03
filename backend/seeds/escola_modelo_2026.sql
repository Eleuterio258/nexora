-- ==============================================================
-- Escola: ENIGMA SCHOOL
-- Seed: Duplo Currículo (Lei 6/92 e Lei 18/2018)
-- Suporta QUALQUER modelo curricular do SNE moçambicano
--
-- ── CURRÍCULO A – Lei n.º 6/92 (Secundário Geral 8ª-12ª) ─────
--   Manhã  : 8ª A-G(7) + 9ª A-G(7) + 10ª A-F(6) = 20 turmas
--   Tarde  : 11ª A-J(10) + 12ª A-J(10)            = 20 turmas
--   Noite  : 8ª-12ª A-D (4/classe)                 = 20 turmas
--
-- ── CURRÍCULO B – Lei n.º 18/2018 (SNE 2018) ─────────────────
--   Pré-Escolar   : Pequeninos(3a)/Médios(4a)/Grandes(5a)= 3 turmas
--   Primário      : 1ª-3ª Manhã(9) + 4ª-6ª Tarde(9)    = 18 turmas
--   Secundário    : 7ª-9ª Manhã(20) + 10ª-12ª Tarde(20)
--                   + 7ª-12ª Noite(20)                  = 60 turmas
--
-- 30 professores · 20 disciplinas · 1440 atribuições
-- Idempotente – ON CONFLICT DO NOTHING em toda a parte.
-- ==============================================================

SET search_path TO gestao_escolar, public;

DO $$
DECLARE
    p_tid BIGINT;   -- preenchido automaticamente pelo bloco de identificação abaixo

    -- Ano lectivo + trimestres
    _yr BIGINT; _t1 BIGINT; _t2 BIGINT; _t3 BIGINT;

    -- ── Níveis ───────────────────────────────────────────────
    _lv      BIGINT;  -- Secundário Geral (Lei 6/92)
    _lv_pre  BIGINT;  -- Pré-Escolar      (Lei 18/2018)
    _lv_pri  BIGINT;  -- Ensino Primário   (Lei 18/2018)
    _lv_sec  BIGINT;  -- Ensino Secundário (Lei 18/2018)

    -- ── Séries – Lei 6/92 (8ª-12ª) ───────────────────────────
    _s8 BIGINT; _s9 BIGINT; _s10 BIGINT; _s11 BIGINT; _s12 BIGINT;

    -- ── Séries – Pré-Escolar ─────────────────────────────────
    _pe3 BIGINT; _pe4 BIGINT; _pe5 BIGINT;

    -- ── Séries – Primário (1ª-6ª) ───────────────────────────
    _pp1 BIGINT; _pp2 BIGINT; _pp3 BIGINT;
    _pp4 BIGINT; _pp5 BIGINT; _pp6 BIGINT;

    -- ── Séries – Secundário Lei 18/2018 (7ª-12ª) ───────────
    _ns7  BIGINT; _ns8  BIGINT; _ns9  BIGINT;
    _ns10 BIGINT; _ns11 BIGINT; _ns12 BIGINT;

    -- ── Disciplinas comuns (Lei 6/92 + Lei 18/2018) ──────────
    _por BIGINT; _mat BIGINT; _ing BIGINT; _fis BIGINT; _qui BIGINT;
    _bio BIGINT; _geo BIGINT; _his BIGINT; _edf BIGINT; _edv BIGINT;
    _emc BIGINT; _fil BIGINT; _eco BIGINT;

    -- ── Disciplinas novas (Primário e Pré-Escolar) ───────────
    _cn   BIGINT;  -- Ciências Naturais          (Primário)
    _cs   BIGINT;  -- Ciências Sociais            (Primário)
    _eva  BIGINT;  -- Expressão Visual e Artística(Primário + Sec 7ª-9ª)
    _loae BIGINT;  -- Ling. Oral e Abord. Escrita (Pré-Escolar)
    _rmat BIGINT;  -- Raciocínio Lógico-Matemático(Pré-Escolar)
    _emd  BIGINT;  -- Expressão Motora e Desp.    (Pré-Escolar)
    _ecri BIGINT;  -- Expressão Criativa          (Pré-Escolar)

    -- ── Professores (30) ─────────────────────────────────────
    _p01 BIGINT; _p02 BIGINT; _p03 BIGINT; _p04 BIGINT; _p05 BIGINT;
    _p06 BIGINT; _p07 BIGINT; _p08 BIGINT; _p09 BIGINT; _p10 BIGINT;
    _p11 BIGINT; _p12 BIGINT; _p13 BIGINT; _p14 BIGINT; _p15 BIGINT;
    _p16 BIGINT; _p17 BIGINT; _p18 BIGINT; _p19 BIGINT; _p20 BIGINT;
    _p21 BIGINT; _p22 BIGINT; _p23 BIGINT; _p24 BIGINT; _p25 BIGINT;
    _p26 BIGINT; _p27 BIGINT; _p28 BIGINT; _p29 BIGINT; _p30 BIGINT;

    -- ── Arrays Lei 6/92 ──────────────────────────────────────
    _arr_manha   BIGINT[];
    _arr_tarde   BIGINT[];
    _arr_noite   BIGINT[];
    _arr_n8a10   BIGINT[];
    _arr_n1112   BIGINT[];
    _arr_all8a10 BIGINT[];
    _arr_all1112 BIGINT[];

    -- ── Arrays Lei 18/2018 – Secundário (7ª-12ª) ────────────
    _arr_nsm      BIGINT[];  -- manhã 7ª-9ª (20)
    _arr_nst      BIGINT[];  -- tarde 10ª-12ª (20)
    _arr_nsn      BIGINT[];  -- noite todas (20)
    _arr_nsn_7a9  BIGINT[];  -- noite 7ª-9ª (9)
    _arr_nsn_1012 BIGINT[];  -- noite 10ª-12ª (11)
    _arr_ns_7a9   BIGINT[];  -- manhã(20)+noite7-9(9) = 29
    _arr_ns_1012  BIGINT[];  -- tarde(20)+noite10-12(11) = 31

    -- ── Arrays Lei 18/2018 – Primário + Pré-Escolar ─────────
    _arr_pri_all BIGINT[];
    _arr_pre_all BIGINT[];

BEGIN

-- ══════════════════════════════════════════════════════════════
-- 0. ENIGMA SCHOOL – Empresa e Tenant
-- ══════════════════════════════════════════════════════════════
INSERT INTO empresas.companies (codigo, nome, nome_comercial, tipo, status, moeda_base, timezone)
VALUES ('ENIGMA-SCH', 'Enigma School', 'Enigma School', 'organizacao', 'ativa', 'MZN', 'Africa/Maputo')
ON CONFLICT (codigo) DO UPDATE SET nome = EXCLUDED.nome, nome_comercial = EXCLUDED.nome_comercial;

INSERT INTO saas.tenants (codigo, nome, status)
VALUES ('enigma-school', 'Enigma School', 'ativo')
ON CONFLICT (codigo) DO UPDATE SET nome = EXCLUDED.nome;
SELECT id INTO p_tid FROM saas.tenants WHERE codigo = 'enigma-school';

-- Ligar tenant à empresa caso ainda não esteja
UPDATE saas.tenants
SET company_id = (SELECT id FROM empresas.companies WHERE codigo = 'ENIGMA-SCH')
WHERE id = p_tid AND company_id IS NULL;

-- ══════════════════════════════════════════════════════════════
-- 1. NÍVEL – Lei 6/92: Secundário Geral
-- ══════════════════════════════════════════════════════════════
SELECT id INTO _lv FROM school_levels WHERE tenant_id = p_tid AND codigo = 'secundario_geral';
IF _lv IS NULL THEN
    INSERT INTO school_levels (
        tenant_id, codigo, nome, ordem,
        nota_minima_aprovacao, escala_maxima, sistema_avaliacao,
        numero_periodos_padrao, nomenclatura_periodo, nomenclatura_serie
    ) VALUES (
        p_tid, 'secundario_geral', 'Ensino Secundário Geral (Lei 6/92)', 2,
        10, 20, '0-20', 3, 'trimestre', 'classe'
    ) RETURNING id INTO _lv;
END IF;

-- ══════════════════════════════════════════════════════════════
-- 2. SÉRIES – Lei 6/92 (8ª–12ª)
-- ══════════════════════════════════════════════════════════════
INSERT INTO school_series (tenant_id, level_id, codigo, nome, ordem) VALUES
    (p_tid, _lv, '8',  '8ª Classe',  8),
    (p_tid, _lv, '9',  '9ª Classe',  9),
    (p_tid, _lv, '10', '10ª Classe', 10),
    (p_tid, _lv, '11', '11ª Classe', 11),
    (p_tid, _lv, '12', '12ª Classe', 12)
ON CONFLICT (tenant_id, level_id, codigo) DO NOTHING;

SELECT id INTO _s8  FROM school_series WHERE tenant_id = p_tid AND level_id = _lv AND codigo = '8';
SELECT id INTO _s9  FROM school_series WHERE tenant_id = p_tid AND level_id = _lv AND codigo = '9';
SELECT id INTO _s10 FROM school_series WHERE tenant_id = p_tid AND level_id = _lv AND codigo = '10';
SELECT id INTO _s11 FROM school_series WHERE tenant_id = p_tid AND level_id = _lv AND codigo = '11';
SELECT id INTO _s12 FROM school_series WHERE tenant_id = p_tid AND level_id = _lv AND codigo = '12';

-- ══════════════════════════════════════════════════════════════
-- 3. ANO LECTIVO 2026 + TRIMESTRES
-- ══════════════════════════════════════════════════════════════
INSERT INTO school_years (tenant_id, codigo, nome, data_inicio, data_fim, status)
VALUES (p_tid, '2026', 'Ano Lectivo 2026', '2026-02-02', '2026-11-27', 'activo')
ON CONFLICT (tenant_id, codigo) DO NOTHING;
SELECT id INTO _yr FROM school_years WHERE tenant_id = p_tid AND codigo = '2026';

INSERT INTO school_terms (tenant_id, school_year_id, codigo, nome, data_inicio, data_fim, peso) VALUES
    (p_tid, _yr, '2026-T1', '1º Trimestre', '2026-02-02', '2026-04-17', 30),
    (p_tid, _yr, '2026-T2', '2º Trimestre', '2026-05-04', '2026-07-24', 30),
    (p_tid, _yr, '2026-T3', '3º Trimestre', '2026-08-10', '2026-11-27', 40)
ON CONFLICT (tenant_id, school_year_id, codigo) DO NOTHING;

SELECT id INTO _t1 FROM school_terms WHERE tenant_id = p_tid AND school_year_id = _yr AND codigo = '2026-T1';
SELECT id INTO _t2 FROM school_terms WHERE tenant_id = p_tid AND school_year_id = _yr AND codigo = '2026-T2';
SELECT id INTO _t3 FROM school_terms WHERE tenant_id = p_tid AND school_year_id = _yr AND codigo = '2026-T3';

-- ══════════════════════════════════════════════════════════════
-- 4. DISCIPLINAS (13 – Lei 6/92)
-- ══════════════════════════════════════════════════════════════
INSERT INTO school_subjects (tenant_id, codigo, nome, carga_horaria, nota_minima) VALUES
    (p_tid, 'POR', 'Português',               5, 10),
    (p_tid, 'MAT', 'Matemática',              5, 10),
    (p_tid, 'ING', 'Inglês',                  4, 10),
    (p_tid, 'FIS', 'Física',                  3, 10),
    (p_tid, 'QUI', 'Química',                 3, 10),
    (p_tid, 'BIO', 'Biologia',                3, 10),
    (p_tid, 'GEO', 'Geografia',               3, 10),
    (p_tid, 'HIS', 'História',                3, 10),
    (p_tid, 'EDF', 'Educação Física',          2, 10),
    (p_tid, 'EDV', 'Educação Visual',          2, 10),
    (p_tid, 'EMC', 'Educação Moral e Cívica',  2, 10),
    (p_tid, 'FIL', 'Filosofia',               3, 10),
    (p_tid, 'ECO', 'Introdução à Economia',    3, 10)
ON CONFLICT (tenant_id, codigo) DO NOTHING;

SELECT id INTO _por FROM school_subjects WHERE tenant_id = p_tid AND codigo = 'POR';
SELECT id INTO _mat FROM school_subjects WHERE tenant_id = p_tid AND codigo = 'MAT';
SELECT id INTO _ing FROM school_subjects WHERE tenant_id = p_tid AND codigo = 'ING';
SELECT id INTO _fis FROM school_subjects WHERE tenant_id = p_tid AND codigo = 'FIS';
SELECT id INTO _qui FROM school_subjects WHERE tenant_id = p_tid AND codigo = 'QUI';
SELECT id INTO _bio FROM school_subjects WHERE tenant_id = p_tid AND codigo = 'BIO';
SELECT id INTO _geo FROM school_subjects WHERE tenant_id = p_tid AND codigo = 'GEO';
SELECT id INTO _his FROM school_subjects WHERE tenant_id = p_tid AND codigo = 'HIS';
SELECT id INTO _edf FROM school_subjects WHERE tenant_id = p_tid AND codigo = 'EDF';
SELECT id INTO _edv FROM school_subjects WHERE tenant_id = p_tid AND codigo = 'EDV';
SELECT id INTO _emc FROM school_subjects WHERE tenant_id = p_tid AND codigo = 'EMC';
SELECT id INTO _fil FROM school_subjects WHERE tenant_id = p_tid AND codigo = 'FIL';
SELECT id INTO _eco FROM school_subjects WHERE tenant_id = p_tid AND codigo = 'ECO';

-- ══════════════════════════════════════════════════════════════
-- 5. PROFESSORES (25 – Lei 6/92 Secundário)
--   POR: 01/02/03   MAT: 04/05/06   ING: 07/08
--   FIS: 09/10      QUI: 11/12      BIO: 13/14
--   GEO: 15/16      HIS: 17/18      EDF: 19/20
--   EDV+EMC: 21/22  FIL+ECO: 23/24  Director: 25
-- ══════════════════════════════════════════════════════════════
INSERT INTO school_teachers (tenant_id, codigo, nome_completo, genero, especialidade, carga_horaria_maxima_semanal, status) VALUES
    (p_tid, 'PROF-01', 'Ana Joaquina Machava',        'F', 'Língua Portuguesa',            25, 'activo'),
    (p_tid, 'PROF-02', 'Carlos António Nhacolo',       'M', 'Língua Portuguesa',            25, 'activo'),
    (p_tid, 'PROF-03', 'Felicidade Arminda Sitoe',     'F', 'Língua Portuguesa',            25, 'activo'),
    (p_tid, 'PROF-04', 'Domingos Henrique Cossa',      'M', 'Matemática',                   25, 'activo'),
    (p_tid, 'PROF-05', 'Maria Luísa Tembe',            'F', 'Matemática',                   25, 'activo'),
    (p_tid, 'PROF-06', 'João Paulo Macuácua',          'M', 'Matemática',                   25, 'activo'),
    (p_tid, 'PROF-07', 'António Fernando Bila',        'M', 'Língua Inglesa',               25, 'activo'),
    (p_tid, 'PROF-08', 'Esperança Celeste Muianga',    'F', 'Língua Inglesa',               25, 'activo'),
    (p_tid, 'PROF-09', 'Rosa Beatriz Chemane',         'F', 'Física',                       25, 'activo'),
    (p_tid, 'PROF-10', 'Hélder Augusto Nhabanga',      'M', 'Física',                       25, 'activo'),
    (p_tid, 'PROF-11', 'Lúcia Manuela Matsine',        'F', 'Química',                      25, 'activo'),
    (p_tid, 'PROF-12', 'Paulo Ernesto Mondlane',       'M', 'Química',                      25, 'activo'),
    (p_tid, 'PROF-13', 'Graça Amélia Timane',          'F', 'Biologia',                     25, 'activo'),
    (p_tid, 'PROF-14', 'Isabel Marta Guambe',          'F', 'Biologia',                     25, 'activo'),
    (p_tid, 'PROF-15', 'Francisco Artur Sitole',       'M', 'Geografia',                    25, 'activo'),
    (p_tid, 'PROF-16', 'Benedito Armando Chissano',    'M', 'Geografia',                    25, 'activo'),
    (p_tid, 'PROF-17', 'Marcelina José Maluana',       'F', 'História',                     25, 'activo'),
    (p_tid, 'PROF-18', 'Estêvão Gabriel Mutemba',      'M', 'História',                     25, 'activo'),
    (p_tid, 'PROF-19', 'Olívia Clara Zunguze',         'F', 'Educação Física',              20, 'activo'),
    (p_tid, 'PROF-20', 'Simão Elias Cumbe',            'M', 'Educação Física',              20, 'activo'),
    (p_tid, 'PROF-21', 'Teresa Anita Macuácua',        'F', 'Educação Visual',              20, 'activo'),
    (p_tid, 'PROF-22', 'Augusto Ricardo Cuambe',       'M', 'Educação Moral e Cívica',      20, 'activo'),
    (p_tid, 'PROF-23', 'Leonor Amália Buque',          'F', 'Filosofia e Ciências Sociais', 25, 'activo'),
    (p_tid, 'PROF-24', 'Horácio Dinis Machel',         'M', 'Filosofia e Ciências Sociais', 25, 'activo'),
    (p_tid, 'PROF-25', 'Salomão Constâncio Mondlane',  'M', 'Gestão Escolar',               0,  'activo')
ON CONFLICT (tenant_id, codigo) DO NOTHING;

SELECT id INTO _p01 FROM school_teachers WHERE tenant_id = p_tid AND codigo = 'PROF-01';
SELECT id INTO _p02 FROM school_teachers WHERE tenant_id = p_tid AND codigo = 'PROF-02';
SELECT id INTO _p03 FROM school_teachers WHERE tenant_id = p_tid AND codigo = 'PROF-03';
SELECT id INTO _p04 FROM school_teachers WHERE tenant_id = p_tid AND codigo = 'PROF-04';
SELECT id INTO _p05 FROM school_teachers WHERE tenant_id = p_tid AND codigo = 'PROF-05';
SELECT id INTO _p06 FROM school_teachers WHERE tenant_id = p_tid AND codigo = 'PROF-06';
SELECT id INTO _p07 FROM school_teachers WHERE tenant_id = p_tid AND codigo = 'PROF-07';
SELECT id INTO _p08 FROM school_teachers WHERE tenant_id = p_tid AND codigo = 'PROF-08';
SELECT id INTO _p09 FROM school_teachers WHERE tenant_id = p_tid AND codigo = 'PROF-09';
SELECT id INTO _p10 FROM school_teachers WHERE tenant_id = p_tid AND codigo = 'PROF-10';
SELECT id INTO _p11 FROM school_teachers WHERE tenant_id = p_tid AND codigo = 'PROF-11';
SELECT id INTO _p12 FROM school_teachers WHERE tenant_id = p_tid AND codigo = 'PROF-12';
SELECT id INTO _p13 FROM school_teachers WHERE tenant_id = p_tid AND codigo = 'PROF-13';
SELECT id INTO _p14 FROM school_teachers WHERE tenant_id = p_tid AND codigo = 'PROF-14';
SELECT id INTO _p15 FROM school_teachers WHERE tenant_id = p_tid AND codigo = 'PROF-15';
SELECT id INTO _p16 FROM school_teachers WHERE tenant_id = p_tid AND codigo = 'PROF-16';
SELECT id INTO _p17 FROM school_teachers WHERE tenant_id = p_tid AND codigo = 'PROF-17';
SELECT id INTO _p18 FROM school_teachers WHERE tenant_id = p_tid AND codigo = 'PROF-18';
SELECT id INTO _p19 FROM school_teachers WHERE tenant_id = p_tid AND codigo = 'PROF-19';
SELECT id INTO _p20 FROM school_teachers WHERE tenant_id = p_tid AND codigo = 'PROF-20';
SELECT id INTO _p21 FROM school_teachers WHERE tenant_id = p_tid AND codigo = 'PROF-21';
SELECT id INTO _p22 FROM school_teachers WHERE tenant_id = p_tid AND codigo = 'PROF-22';
SELECT id INTO _p23 FROM school_teachers WHERE tenant_id = p_tid AND codigo = 'PROF-23';
SELECT id INTO _p24 FROM school_teachers WHERE tenant_id = p_tid AND codigo = 'PROF-24';
SELECT id INTO _p25 FROM school_teachers WHERE tenant_id = p_tid AND codigo = 'PROF-25';

-- ══════════════════════════════════════════════════════════════
-- 6. TURMAS – Lei 6/92 (60 – 20 por turno, 8ª-12ª)
-- ══════════════════════════════════════════════════════════════

-- ── MANHÃ: 8ª A-G(7) · 9ª A-G(7) · 10ª A-F(6) ──────────────
INSERT INTO school_classes
    (tenant_id, school_year_id, level_id, series_id, codigo, nome,
     nivel, ano_lectivo, turma, turno, sala, capacidade, director_teacher_id, activo)
VALUES
    (p_tid,_yr,_lv,_s8, 'M8A', '8ª A – Manhã', '8ª Classe','2026','A','manha','Sala 01',40,_p25,true),
    (p_tid,_yr,_lv,_s8, 'M8B', '8ª B – Manhã', '8ª Classe','2026','B','manha','Sala 02',40,_p25,true),
    (p_tid,_yr,_lv,_s8, 'M8C', '8ª C – Manhã', '8ª Classe','2026','C','manha','Sala 03',40,_p25,true),
    (p_tid,_yr,_lv,_s8, 'M8D', '8ª D – Manhã', '8ª Classe','2026','D','manha','Sala 04',40,_p25,true),
    (p_tid,_yr,_lv,_s8, 'M8E', '8ª E – Manhã', '8ª Classe','2026','E','manha','Sala 05',40,_p25,true),
    (p_tid,_yr,_lv,_s8, 'M8F', '8ª F – Manhã', '8ª Classe','2026','F','manha','Sala 06',40,_p25,true),
    (p_tid,_yr,_lv,_s8, 'M8G', '8ª G – Manhã', '8ª Classe','2026','G','manha','Sala 07',40,_p25,true),
    (p_tid,_yr,_lv,_s9, 'M9A', '9ª A – Manhã', '9ª Classe','2026','A','manha','Sala 08',40,_p25,true),
    (p_tid,_yr,_lv,_s9, 'M9B', '9ª B – Manhã', '9ª Classe','2026','B','manha','Sala 09',40,_p25,true),
    (p_tid,_yr,_lv,_s9, 'M9C', '9ª C – Manhã', '9ª Classe','2026','C','manha','Sala 10',40,_p25,true),
    (p_tid,_yr,_lv,_s9, 'M9D', '9ª D – Manhã', '9ª Classe','2026','D','manha','Sala 11',40,_p25,true),
    (p_tid,_yr,_lv,_s9, 'M9E', '9ª E – Manhã', '9ª Classe','2026','E','manha','Sala 12',40,_p25,true),
    (p_tid,_yr,_lv,_s9, 'M9F', '9ª F – Manhã', '9ª Classe','2026','F','manha','Sala 13',40,_p25,true),
    (p_tid,_yr,_lv,_s9, 'M9G', '9ª G – Manhã', '9ª Classe','2026','G','manha','Sala 14',40,_p25,true),
    (p_tid,_yr,_lv,_s10,'M10A','10ª A – Manhã','10ª Classe','2026','A','manha','Sala 15',40,_p25,true),
    (p_tid,_yr,_lv,_s10,'M10B','10ª B – Manhã','10ª Classe','2026','B','manha','Sala 16',40,_p25,true),
    (p_tid,_yr,_lv,_s10,'M10C','10ª C – Manhã','10ª Classe','2026','C','manha','Sala 17',40,_p25,true),
    (p_tid,_yr,_lv,_s10,'M10D','10ª D – Manhã','10ª Classe','2026','D','manha','Sala 18',40,_p25,true),
    (p_tid,_yr,_lv,_s10,'M10E','10ª E – Manhã','10ª Classe','2026','E','manha','Sala 19',40,_p25,true),
    (p_tid,_yr,_lv,_s10,'M10F','10ª F – Manhã','10ª Classe','2026','F','manha','Sala 20',40,_p25,true)
ON CONFLICT (tenant_id, codigo, ano_lectivo) DO NOTHING;

-- ── TARDE: 11ª A-J(10) · 12ª A-J(10) ────────────────────────
INSERT INTO school_classes
    (tenant_id, school_year_id, level_id, series_id, codigo, nome,
     nivel, ano_lectivo, turma, turno, sala, capacidade, director_teacher_id, activo)
VALUES
    (p_tid,_yr,_lv,_s11,'T11A','11ª A – Tarde','11ª Classe','2026','A','tarde','Sala 01',40,_p25,true),
    (p_tid,_yr,_lv,_s11,'T11B','11ª B – Tarde','11ª Classe','2026','B','tarde','Sala 02',40,_p25,true),
    (p_tid,_yr,_lv,_s11,'T11C','11ª C – Tarde','11ª Classe','2026','C','tarde','Sala 03',40,_p25,true),
    (p_tid,_yr,_lv,_s11,'T11D','11ª D – Tarde','11ª Classe','2026','D','tarde','Sala 04',40,_p25,true),
    (p_tid,_yr,_lv,_s11,'T11E','11ª E – Tarde','11ª Classe','2026','E','tarde','Sala 05',40,_p25,true),
    (p_tid,_yr,_lv,_s11,'T11F','11ª F – Tarde','11ª Classe','2026','F','tarde','Sala 06',40,_p25,true),
    (p_tid,_yr,_lv,_s11,'T11G','11ª G – Tarde','11ª Classe','2026','G','tarde','Sala 07',40,_p25,true),
    (p_tid,_yr,_lv,_s11,'T11H','11ª H – Tarde','11ª Classe','2026','H','tarde','Sala 08',40,_p25,true),
    (p_tid,_yr,_lv,_s11,'T11I','11ª I – Tarde','11ª Classe','2026','I','tarde','Sala 09',40,_p25,true),
    (p_tid,_yr,_lv,_s11,'T11J','11ª J – Tarde','11ª Classe','2026','J','tarde','Sala 10',40,_p25,true),
    (p_tid,_yr,_lv,_s12,'T12A','12ª A – Tarde','12ª Classe','2026','A','tarde','Sala 11',40,_p25,true),
    (p_tid,_yr,_lv,_s12,'T12B','12ª B – Tarde','12ª Classe','2026','B','tarde','Sala 12',40,_p25,true),
    (p_tid,_yr,_lv,_s12,'T12C','12ª C – Tarde','12ª Classe','2026','C','tarde','Sala 13',40,_p25,true),
    (p_tid,_yr,_lv,_s12,'T12D','12ª D – Tarde','12ª Classe','2026','D','tarde','Sala 14',40,_p25,true),
    (p_tid,_yr,_lv,_s12,'T12E','12ª E – Tarde','12ª Classe','2026','E','tarde','Sala 15',40,_p25,true),
    (p_tid,_yr,_lv,_s12,'T12F','12ª F – Tarde','12ª Classe','2026','F','tarde','Sala 16',40,_p25,true),
    (p_tid,_yr,_lv,_s12,'T12G','12ª G – Tarde','12ª Classe','2026','G','tarde','Sala 17',40,_p25,true),
    (p_tid,_yr,_lv,_s12,'T12H','12ª H – Tarde','12ª Classe','2026','H','tarde','Sala 18',40,_p25,true),
    (p_tid,_yr,_lv,_s12,'T12I','12ª I – Tarde','12ª Classe','2026','I','tarde','Sala 19',40,_p25,true),
    (p_tid,_yr,_lv,_s12,'T12J','12ª J – Tarde','12ª Classe','2026','J','tarde','Sala 20',40,_p25,true)
ON CONFLICT (tenant_id, codigo, ano_lectivo) DO NOTHING;

-- ── NOITE: 8ª-12ª A-D (4/classe, Salas 01-20) ───────────────
INSERT INTO school_classes
    (tenant_id, school_year_id, level_id, series_id, codigo, nome,
     nivel, ano_lectivo, turma, turno, sala, capacidade, director_teacher_id, activo)
VALUES
    (p_tid,_yr,_lv,_s8, 'N8A', '8ª A – Noite', '8ª Classe','2026','A','noite','Sala 01',35,_p25,true),
    (p_tid,_yr,_lv,_s8, 'N8B', '8ª B – Noite', '8ª Classe','2026','B','noite','Sala 02',35,_p25,true),
    (p_tid,_yr,_lv,_s8, 'N8C', '8ª C – Noite', '8ª Classe','2026','C','noite','Sala 03',35,_p25,true),
    (p_tid,_yr,_lv,_s8, 'N8D', '8ª D – Noite', '8ª Classe','2026','D','noite','Sala 04',35,_p25,true),
    (p_tid,_yr,_lv,_s9, 'N9A', '9ª A – Noite', '9ª Classe','2026','A','noite','Sala 05',35,_p25,true),
    (p_tid,_yr,_lv,_s9, 'N9B', '9ª B – Noite', '9ª Classe','2026','B','noite','Sala 06',35,_p25,true),
    (p_tid,_yr,_lv,_s9, 'N9C', '9ª C – Noite', '9ª Classe','2026','C','noite','Sala 07',35,_p25,true),
    (p_tid,_yr,_lv,_s9, 'N9D', '9ª D – Noite', '9ª Classe','2026','D','noite','Sala 08',35,_p25,true),
    (p_tid,_yr,_lv,_s10,'N10A','10ª A – Noite','10ª Classe','2026','A','noite','Sala 09',35,_p25,true),
    (p_tid,_yr,_lv,_s10,'N10B','10ª B – Noite','10ª Classe','2026','B','noite','Sala 10',35,_p25,true),
    (p_tid,_yr,_lv,_s10,'N10C','10ª C – Noite','10ª Classe','2026','C','noite','Sala 11',35,_p25,true),
    (p_tid,_yr,_lv,_s10,'N10D','10ª D – Noite','10ª Classe','2026','D','noite','Sala 12',35,_p25,true),
    (p_tid,_yr,_lv,_s11,'N11A','11ª A – Noite','11ª Classe','2026','A','noite','Sala 13',35,_p25,true),
    (p_tid,_yr,_lv,_s11,'N11B','11ª B – Noite','11ª Classe','2026','B','noite','Sala 14',35,_p25,true),
    (p_tid,_yr,_lv,_s11,'N11C','11ª C – Noite','11ª Classe','2026','C','noite','Sala 15',35,_p25,true),
    (p_tid,_yr,_lv,_s11,'N11D','11ª D – Noite','11ª Classe','2026','D','noite','Sala 16',35,_p25,true),
    (p_tid,_yr,_lv,_s12,'N12A','12ª A – Noite','12ª Classe','2026','A','noite','Sala 17',35,_p25,true),
    (p_tid,_yr,_lv,_s12,'N12B','12ª B – Noite','12ª Classe','2026','B','noite','Sala 18',35,_p25,true),
    (p_tid,_yr,_lv,_s12,'N12C','12ª C – Noite','12ª Classe','2026','C','noite','Sala 19',35,_p25,true),
    (p_tid,_yr,_lv,_s12,'N12D','12ª D – Noite','12ª Classe','2026','D','noite','Sala 20',35,_p25,true)
ON CONFLICT (tenant_id, codigo, ano_lectivo) DO NOTHING;

-- ══════════════════════════════════════════════════════════════
-- 7. COLECTAR ARRAYS – Lei 6/92
-- ══════════════════════════════════════════════════════════════
SELECT ARRAY_AGG(id) INTO _arr_manha
    FROM school_classes WHERE tenant_id=p_tid AND school_year_id=_yr AND level_id=_lv AND turno='manha';
SELECT ARRAY_AGG(id) INTO _arr_tarde
    FROM school_classes WHERE tenant_id=p_tid AND school_year_id=_yr AND level_id=_lv AND turno='tarde';
SELECT ARRAY_AGG(id) INTO _arr_noite
    FROM school_classes WHERE tenant_id=p_tid AND school_year_id=_yr AND level_id=_lv AND turno='noite';
SELECT ARRAY_AGG(id) INTO _arr_n8a10
    FROM school_classes WHERE tenant_id=p_tid AND school_year_id=_yr AND level_id=_lv AND turno='noite'
    AND series_id IN (_s8,_s9,_s10);
SELECT ARRAY_AGG(id) INTO _arr_n1112
    FROM school_classes WHERE tenant_id=p_tid AND school_year_id=_yr AND level_id=_lv AND turno='noite'
    AND series_id IN (_s11,_s12);
_arr_all8a10 := _arr_manha || _arr_n8a10;
_arr_all1112 := _arr_tarde || _arr_n1112;

-- ══════════════════════════════════════════════════════════════
-- 8. ATRIBUIÇÕES – Lei 6/92 (660 via unnest)
-- ══════════════════════════════════════════════════════════════

-- POR: PROF-01→manhã · PROF-02→tarde · PROF-03→noite
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_por,_p01,'2026-02-02' FROM unnest(_arr_manha) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_por,_p02,'2026-02-02' FROM unnest(_arr_tarde) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_por,_p03,'2026-02-02' FROM unnest(_arr_noite) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;

-- MAT: PROF-04→manhã · PROF-05→tarde · PROF-06→noite
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_mat,_p04,'2026-02-02' FROM unnest(_arr_manha) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_mat,_p05,'2026-02-02' FROM unnest(_arr_tarde) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_mat,_p06,'2026-02-02' FROM unnest(_arr_noite) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;

-- ING: PROF-07→manhã+noite8-10 · PROF-08→tarde+noite11-12
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_ing,_p07,'2026-02-02' FROM unnest(_arr_manha||_arr_n8a10) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_ing,_p08,'2026-02-02' FROM unnest(_arr_tarde||_arr_n1112) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;

-- FIS: PROF-09→manhã+noite8-10 · PROF-10→tarde+noite11-12
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_fis,_p09,'2026-02-02' FROM unnest(_arr_manha||_arr_n8a10) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_fis,_p10,'2026-02-02' FROM unnest(_arr_tarde||_arr_n1112) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;

-- QUI: PROF-11→manhã+noite8-10 · PROF-12→tarde+noite11-12
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_qui,_p11,'2026-02-02' FROM unnest(_arr_manha||_arr_n8a10) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_qui,_p12,'2026-02-02' FROM unnest(_arr_tarde||_arr_n1112) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;

-- BIO: PROF-13→manhã+noite8-10 · PROF-14→tarde+noite11-12
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_bio,_p13,'2026-02-02' FROM unnest(_arr_manha||_arr_n8a10) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_bio,_p14,'2026-02-02' FROM unnest(_arr_tarde||_arr_n1112) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;

-- GEO: PROF-15→manhã+noite8-10 · PROF-16→tarde+noite11-12
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_geo,_p15,'2026-02-02' FROM unnest(_arr_manha||_arr_n8a10) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_geo,_p16,'2026-02-02' FROM unnest(_arr_tarde||_arr_n1112) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;

-- HIS: PROF-17→manhã+noite8-10 · PROF-18→tarde+noite11-12
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_his,_p17,'2026-02-02' FROM unnest(_arr_manha||_arr_n8a10) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_his,_p18,'2026-02-02' FROM unnest(_arr_tarde||_arr_n1112) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;

-- EDF: PROF-19→manhã+noite · PROF-20→tarde
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_edf,_p19,'2026-02-02' FROM unnest(_arr_manha||_arr_noite) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_edf,_p20,'2026-02-02' FROM unnest(_arr_tarde) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;

-- EDV – PROF-21 (8ª-10ª: 32) | EMC – PROF-22 (8ª-10ª: 32)
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_edv,_p21,'2026-02-02' FROM unnest(_arr_all8a10) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_emc,_p22,'2026-02-02' FROM unnest(_arr_all8a10) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;

-- FIL – PROF-23 (11ª-12ª: 28) | ECO – PROF-24 (11ª-12ª: 28)
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_fil,_p23,'2026-02-02' FROM unnest(_arr_all1112) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_eco,_p24,'2026-02-02' FROM unnest(_arr_all1112) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;

-- ══════════════════════════════════════════════════════════════
-- 9. PLANOS DE PROPINAS – Lei 6/92
-- ══════════════════════════════════════════════════════════════
INSERT INTO school_fee_plans (tenant_id, school_year_id, codigo, nome, tipo, valor, moeda, periodicidade, dia_vencimento, classe_nivel) VALUES
    (p_tid,_yr,'PROP-MAN-810', 'Propina Manhã 8ª–10ª (Lei 6/92)', 'propina', 450.00,'MZN','mensal',25,'8ª-10ª Manhã'),
    (p_tid,_yr,'PROP-TAR-1112','Propina Tarde 11ª–12ª (Lei 6/92)','propina', 550.00,'MZN','mensal',25,'11ª-12ª Tarde'),
    (p_tid,_yr,'PROP-NOI',     'Propina Turno da Noite (Lei 6/92)','propina', 500.00,'MZN','mensal',25,'8ª-12ª Noite'),
    (p_tid,_yr,'MATR-2026',    'Taxa de Matrícula 2026',           'matricula',200.00,'MZN','anual', 28, NULL)
ON CONFLICT (tenant_id, codigo) DO NOTHING;


-- ╔════════════════════════════════════════════════════════════╗
-- ║  CURRÍCULO B – LEI N.º 18/2018 (SNE 2018)                ║
-- ║  Pré-Escolar · Primário (1ª-6ª) · Secundário (7ª-12ª)   ║
-- ╚════════════════════════════════════════════════════════════╝

-- ══════════════════════════════════════════════════════════════
-- 10. NÍVEIS – Lei 18/2018
-- ══════════════════════════════════════════════════════════════
SELECT id INTO _lv_pre FROM school_levels WHERE tenant_id=p_tid AND codigo='pre_escolar';
IF _lv_pre IS NULL THEN
    INSERT INTO school_levels (tenant_id,codigo,nome,ordem,nota_minima_aprovacao,escala_maxima,
        sistema_avaliacao,numero_periodos_padrao,nomenclatura_periodo,nomenclatura_serie)
    VALUES (p_tid,'pre_escolar','Ensino Pré-Escolar',0,0,5,'descritiva',2,'semestre','grupo')
    RETURNING id INTO _lv_pre;
END IF;

SELECT id INTO _lv_pri FROM school_levels WHERE tenant_id=p_tid AND codigo='primario';
IF _lv_pri IS NULL THEN
    INSERT INTO school_levels (tenant_id,codigo,nome,ordem,nota_minima_aprovacao,escala_maxima,
        sistema_avaliacao,numero_periodos_padrao,nomenclatura_periodo,nomenclatura_serie)
    VALUES (p_tid,'primario','Ensino Primário (Lei 18/2018)',1,10,20,'0-20',3,'trimestre','classe')
    RETURNING id INTO _lv_pri;
END IF;

SELECT id INTO _lv_sec FROM school_levels WHERE tenant_id=p_tid AND codigo='secundario';
IF _lv_sec IS NULL THEN
    INSERT INTO school_levels (tenant_id,codigo,nome,ordem,nota_minima_aprovacao,escala_maxima,
        sistema_avaliacao,numero_periodos_padrao,nomenclatura_periodo,nomenclatura_serie)
    VALUES (p_tid,'secundario','Ensino Secundário (Lei 18/2018)',2,10,20,'0-20',3,'trimestre','classe')
    RETURNING id INTO _lv_sec;
END IF;

-- ══════════════════════════════════════════════════════════════
-- 11. SÉRIES – Lei 18/2018
-- ══════════════════════════════════════════════════════════════

-- Pré-Escolar: 3 grupos (3, 4, 5 anos)
INSERT INTO school_series (tenant_id,level_id,codigo,nome,ordem) VALUES
    (p_tid,_lv_pre,'GRU3','Pequeninos (3 anos)',1),
    (p_tid,_lv_pre,'GRU4','Médios (4 anos)',    2),
    (p_tid,_lv_pre,'GRU5','Grandes (5 anos)',   3)
ON CONFLICT (tenant_id,level_id,codigo) DO NOTHING;
SELECT id INTO _pe3 FROM school_series WHERE tenant_id=p_tid AND level_id=_lv_pre AND codigo='GRU3';
SELECT id INTO _pe4 FROM school_series WHERE tenant_id=p_tid AND level_id=_lv_pre AND codigo='GRU4';
SELECT id INTO _pe5 FROM school_series WHERE tenant_id=p_tid AND level_id=_lv_pre AND codigo='GRU5';

-- Primário: 1ª–6ª Classe
INSERT INTO school_series (tenant_id,level_id,codigo,nome,ordem) VALUES
    (p_tid,_lv_pri,'1','1ª Classe',1),(p_tid,_lv_pri,'2','2ª Classe',2),
    (p_tid,_lv_pri,'3','3ª Classe',3),(p_tid,_lv_pri,'4','4ª Classe',4),
    (p_tid,_lv_pri,'5','5ª Classe',5),(p_tid,_lv_pri,'6','6ª Classe',6)
ON CONFLICT (tenant_id,level_id,codigo) DO NOTHING;
SELECT id INTO _pp1 FROM school_series WHERE tenant_id=p_tid AND level_id=_lv_pri AND codigo='1';
SELECT id INTO _pp2 FROM school_series WHERE tenant_id=p_tid AND level_id=_lv_pri AND codigo='2';
SELECT id INTO _pp3 FROM school_series WHERE tenant_id=p_tid AND level_id=_lv_pri AND codigo='3';
SELECT id INTO _pp4 FROM school_series WHERE tenant_id=p_tid AND level_id=_lv_pri AND codigo='4';
SELECT id INTO _pp5 FROM school_series WHERE tenant_id=p_tid AND level_id=_lv_pri AND codigo='5';
SELECT id INTO _pp6 FROM school_series WHERE tenant_id=p_tid AND level_id=_lv_pri AND codigo='6';

-- Secundário: 7ª–12ª Classe
INSERT INTO school_series (tenant_id,level_id,codigo,nome,ordem) VALUES
    (p_tid,_lv_sec,'7', '7ª Classe', 7),(p_tid,_lv_sec,'8', '8ª Classe', 8),
    (p_tid,_lv_sec,'9', '9ª Classe', 9),(p_tid,_lv_sec,'10','10ª Classe',10),
    (p_tid,_lv_sec,'11','11ª Classe',11),(p_tid,_lv_sec,'12','12ª Classe',12)
ON CONFLICT (tenant_id,level_id,codigo) DO NOTHING;
SELECT id INTO _ns7  FROM school_series WHERE tenant_id=p_tid AND level_id=_lv_sec AND codigo='7';
SELECT id INTO _ns8  FROM school_series WHERE tenant_id=p_tid AND level_id=_lv_sec AND codigo='8';
SELECT id INTO _ns9  FROM school_series WHERE tenant_id=p_tid AND level_id=_lv_sec AND codigo='9';
SELECT id INTO _ns10 FROM school_series WHERE tenant_id=p_tid AND level_id=_lv_sec AND codigo='10';
SELECT id INTO _ns11 FROM school_series WHERE tenant_id=p_tid AND level_id=_lv_sec AND codigo='11';
SELECT id INTO _ns12 FROM school_series WHERE tenant_id=p_tid AND level_id=_lv_sec AND codigo='12';

-- ══════════════════════════════════════════════════════════════
-- 12. DISCIPLINAS – novas (Primário + Pré-Escolar)
-- ══════════════════════════════════════════════════════════════
INSERT INTO school_subjects (tenant_id,codigo,nome,carga_horaria,nota_minima) VALUES
    (p_tid,'CN',  'Ciências Naturais',              4, 10),
    (p_tid,'CS',  'Ciências Sociais',               3, 10),
    (p_tid,'EVA', 'Expressão Visual e Artística',   2, 10),
    (p_tid,'LOAE','Linguagem Oral e Abord. Escrita', 6,  0),
    (p_tid,'RMAT','Raciocínio Lógico-Matemático',   5,  0),
    (p_tid,'EMD', 'Expressão Motora e Desportiva',  3,  0),
    (p_tid,'ECRI','Expressão Criativa',              4,  0)
ON CONFLICT (tenant_id,codigo) DO NOTHING;

SELECT id INTO _cn   FROM school_subjects WHERE tenant_id=p_tid AND codigo='CN';
SELECT id INTO _cs   FROM school_subjects WHERE tenant_id=p_tid AND codigo='CS';
SELECT id INTO _eva  FROM school_subjects WHERE tenant_id=p_tid AND codigo='EVA';
SELECT id INTO _loae FROM school_subjects WHERE tenant_id=p_tid AND codigo='LOAE';
SELECT id INTO _rmat FROM school_subjects WHERE tenant_id=p_tid AND codigo='RMAT';
SELECT id INTO _emd  FROM school_subjects WHERE tenant_id=p_tid AND codigo='EMD';
SELECT id INTO _ecri FROM school_subjects WHERE tenant_id=p_tid AND codigo='ECRI';

-- ══════════════════════════════════════════════════════════════
-- 13. PROFESSORES adicionais (PROF-26 a PROF-30 – Primário/Pré)
-- ══════════════════════════════════════════════════════════════
INSERT INTO school_teachers (tenant_id,codigo,nome_completo,genero,especialidade,carga_horaria_maxima_semanal,status) VALUES
    (p_tid,'PROF-26','Delfina Clara Mutombene',   'F','Português (Primário)',     28,'activo'),
    (p_tid,'PROF-27','Tomás Artur Chivambo',      'M','Matemática (Primário)',    28,'activo'),
    (p_tid,'PROF-28','Lurdes Fátima Zimba',        'F','Ciências Naturais (Prim).',28,'activo'),
    (p_tid,'PROF-29','Abílio Neves Nhantumbo',    'M','Ciências Sociais (Prim.)', 28,'activo'),
    (p_tid,'PROF-30','Celina Amélia Manhiça',      'F','Pré-Escolar e Artes',     28,'activo')
ON CONFLICT (tenant_id,codigo) DO NOTHING;

SELECT id INTO _p26 FROM school_teachers WHERE tenant_id=p_tid AND codigo='PROF-26';
SELECT id INTO _p27 FROM school_teachers WHERE tenant_id=p_tid AND codigo='PROF-27';
SELECT id INTO _p28 FROM school_teachers WHERE tenant_id=p_tid AND codigo='PROF-28';
SELECT id INTO _p29 FROM school_teachers WHERE tenant_id=p_tid AND codigo='PROF-29';
SELECT id INTO _p30 FROM school_teachers WHERE tenant_id=p_tid AND codigo='PROF-30';

-- ══════════════════════════════════════════════════════════════
-- 14. TURMAS – Pré-Escolar (3 grupos, Manhã)
-- ══════════════════════════════════════════════════════════════
INSERT INTO school_classes
    (tenant_id,school_year_id,level_id,series_id,codigo,nome,
     nivel,ano_lectivo,turma,turno,sala,capacidade,director_teacher_id,activo)
VALUES
    (p_tid,_yr,_lv_pre,_pe3,'PE3','Pequeninos – 3 anos','Pré-Escolar','2026','A','manha','Sala PE-01',20,_p30,true),
    (p_tid,_yr,_lv_pre,_pe4,'PE4','Médios – 4 anos',    'Pré-Escolar','2026','A','manha','Sala PE-02',20,_p30,true),
    (p_tid,_yr,_lv_pre,_pe5,'PE5','Grandes – 5 anos',   'Pré-Escolar','2026','A','manha','Sala PE-03',20,_p30,true)
ON CONFLICT (tenant_id, codigo, ano_lectivo) DO NOTHING;

-- ══════════════════════════════════════════════════════════════
-- 15. TURMAS – Primário (18: 1ª-3ª Manhã + 4ª-6ª Tarde)
-- ══════════════════════════════════════════════════════════════
INSERT INTO school_classes
    (tenant_id,school_year_id,level_id,series_id,codigo,nome,
     nivel,ano_lectivo,turma,turno,sala,capacidade,director_teacher_id,activo)
VALUES
    (p_tid,_yr,_lv_pri,_pp1,'P1A','1ª A – Manhã','1ª Classe','2026','A','manha','Sala P-01',40,_p26,true),
    (p_tid,_yr,_lv_pri,_pp1,'P1B','1ª B – Manhã','1ª Classe','2026','B','manha','Sala P-02',40,_p26,true),
    (p_tid,_yr,_lv_pri,_pp1,'P1C','1ª C – Manhã','1ª Classe','2026','C','manha','Sala P-03',40,_p26,true),
    (p_tid,_yr,_lv_pri,_pp2,'P2A','2ª A – Manhã','2ª Classe','2026','A','manha','Sala P-04',40,_p26,true),
    (p_tid,_yr,_lv_pri,_pp2,'P2B','2ª B – Manhã','2ª Classe','2026','B','manha','Sala P-05',40,_p26,true),
    (p_tid,_yr,_lv_pri,_pp2,'P2C','2ª C – Manhã','2ª Classe','2026','C','manha','Sala P-06',40,_p26,true),
    (p_tid,_yr,_lv_pri,_pp3,'P3A','3ª A – Manhã','3ª Classe','2026','A','manha','Sala P-07',40,_p27,true),
    (p_tid,_yr,_lv_pri,_pp3,'P3B','3ª B – Manhã','3ª Classe','2026','B','manha','Sala P-08',40,_p27,true),
    (p_tid,_yr,_lv_pri,_pp3,'P3C','3ª C – Manhã','3ª Classe','2026','C','manha','Sala P-09',40,_p27,true),
    (p_tid,_yr,_lv_pri,_pp4,'P4A','4ª A – Tarde','4ª Classe','2026','A','tarde','Sala P-01',40,_p28,true),
    (p_tid,_yr,_lv_pri,_pp4,'P4B','4ª B – Tarde','4ª Classe','2026','B','tarde','Sala P-02',40,_p28,true),
    (p_tid,_yr,_lv_pri,_pp4,'P4C','4ª C – Tarde','4ª Classe','2026','C','tarde','Sala P-03',40,_p28,true),
    (p_tid,_yr,_lv_pri,_pp5,'P5A','5ª A – Tarde','5ª Classe','2026','A','tarde','Sala P-04',40,_p28,true),
    (p_tid,_yr,_lv_pri,_pp5,'P5B','5ª B – Tarde','5ª Classe','2026','B','tarde','Sala P-05',40,_p28,true),
    (p_tid,_yr,_lv_pri,_pp5,'P5C','5ª C – Tarde','5ª Classe','2026','C','tarde','Sala P-06',40,_p29,true),
    (p_tid,_yr,_lv_pri,_pp6,'P6A','6ª A – Tarde','6ª Classe','2026','A','tarde','Sala P-07',40,_p29,true),
    (p_tid,_yr,_lv_pri,_pp6,'P6B','6ª B – Tarde','6ª Classe','2026','B','tarde','Sala P-08',40,_p29,true),
    (p_tid,_yr,_lv_pri,_pp6,'P6C','6ª C – Tarde','6ª Classe','2026','C','tarde','Sala P-09',40,_p29,true)
ON CONFLICT (tenant_id, codigo, ano_lectivo) DO NOTHING;

-- ══════════════════════════════════════════════════════════════
-- 16. TURMAS – Secundário Lei 18/2018 (60: 7ª-12ª, 20/turno)
--   Manhã : 7ª A-G(7) + 8ª A-G(7) + 9ª A-F(6) = 20
--   Tarde : 10ª A-G(7) + 11ª A-G(7) + 12ª A-F(6) = 20
--   Noite : 7ªA-C(3)+8ªA-C(3)+9ªA-C(3)+10ªA-D(4)+11ªA-D(4)+12ªA-C(3) = 20
-- ══════════════════════════════════════════════════════════════

-- ── MANHÃ (7ª-9ª) ────────────────────────────────────────────
INSERT INTO school_classes
    (tenant_id,school_year_id,level_id,series_id,codigo,nome,
     nivel,ano_lectivo,turma,turno,sala,capacidade,director_teacher_id,activo)
VALUES
    (p_tid,_yr,_lv_sec,_ns7, '7MA','7ª A – Manhã', '7ª Classe','2026','A','manha','Sala 01',40,_p25,true),
    (p_tid,_yr,_lv_sec,_ns7, '7MB','7ª B – Manhã', '7ª Classe','2026','B','manha','Sala 02',40,_p25,true),
    (p_tid,_yr,_lv_sec,_ns7, '7MC','7ª C – Manhã', '7ª Classe','2026','C','manha','Sala 03',40,_p25,true),
    (p_tid,_yr,_lv_sec,_ns7, '7MD','7ª D – Manhã', '7ª Classe','2026','D','manha','Sala 04',40,_p25,true),
    (p_tid,_yr,_lv_sec,_ns7, '7ME','7ª E – Manhã', '7ª Classe','2026','E','manha','Sala 05',40,_p25,true),
    (p_tid,_yr,_lv_sec,_ns7, '7MF','7ª F – Manhã', '7ª Classe','2026','F','manha','Sala 06',40,_p25,true),
    (p_tid,_yr,_lv_sec,_ns7, '7MG','7ª G – Manhã', '7ª Classe','2026','G','manha','Sala 07',40,_p25,true),
    (p_tid,_yr,_lv_sec,_ns8, '8MA','8ª A – Manhã', '8ª Classe','2026','A','manha','Sala 08',40,_p25,true),
    (p_tid,_yr,_lv_sec,_ns8, '8MB','8ª B – Manhã', '8ª Classe','2026','B','manha','Sala 09',40,_p25,true),
    (p_tid,_yr,_lv_sec,_ns8, '8MC','8ª C – Manhã', '8ª Classe','2026','C','manha','Sala 10',40,_p25,true),
    (p_tid,_yr,_lv_sec,_ns8, '8MD','8ª D – Manhã', '8ª Classe','2026','D','manha','Sala 11',40,_p25,true),
    (p_tid,_yr,_lv_sec,_ns8, '8ME','8ª E – Manhã', '8ª Classe','2026','E','manha','Sala 12',40,_p25,true),
    (p_tid,_yr,_lv_sec,_ns8, '8MF','8ª F – Manhã', '8ª Classe','2026','F','manha','Sala 13',40,_p25,true),
    (p_tid,_yr,_lv_sec,_ns8, '8MG','8ª G – Manhã', '8ª Classe','2026','G','manha','Sala 14',40,_p25,true),
    (p_tid,_yr,_lv_sec,_ns9, '9MA','9ª A – Manhã', '9ª Classe','2026','A','manha','Sala 15',40,_p25,true),
    (p_tid,_yr,_lv_sec,_ns9, '9MB','9ª B – Manhã', '9ª Classe','2026','B','manha','Sala 16',40,_p25,true),
    (p_tid,_yr,_lv_sec,_ns9, '9MC','9ª C – Manhã', '9ª Classe','2026','C','manha','Sala 17',40,_p25,true),
    (p_tid,_yr,_lv_sec,_ns9, '9MD','9ª D – Manhã', '9ª Classe','2026','D','manha','Sala 18',40,_p25,true),
    (p_tid,_yr,_lv_sec,_ns9, '9ME','9ª E – Manhã', '9ª Classe','2026','E','manha','Sala 19',40,_p25,true),
    (p_tid,_yr,_lv_sec,_ns9, '9MF','9ª F – Manhã', '9ª Classe','2026','F','manha','Sala 20',40,_p25,true)
ON CONFLICT (tenant_id, codigo, ano_lectivo) DO NOTHING;

-- ── TARDE (10ª-12ª) ──────────────────────────────────────────
INSERT INTO school_classes
    (tenant_id,school_year_id,level_id,series_id,codigo,nome,
     nivel,ano_lectivo,turma,turno,sala,capacidade,director_teacher_id,activo)
VALUES
    (p_tid,_yr,_lv_sec,_ns10,'10TA','10ª A – Tarde','10ª Classe','2026','A','tarde','Sala 01',40,_p25,true),
    (p_tid,_yr,_lv_sec,_ns10,'10TB','10ª B – Tarde','10ª Classe','2026','B','tarde','Sala 02',40,_p25,true),
    (p_tid,_yr,_lv_sec,_ns10,'10TC','10ª C – Tarde','10ª Classe','2026','C','tarde','Sala 03',40,_p25,true),
    (p_tid,_yr,_lv_sec,_ns10,'10TD','10ª D – Tarde','10ª Classe','2026','D','tarde','Sala 04',40,_p25,true),
    (p_tid,_yr,_lv_sec,_ns10,'10TE','10ª E – Tarde','10ª Classe','2026','E','tarde','Sala 05',40,_p25,true),
    (p_tid,_yr,_lv_sec,_ns10,'10TF','10ª F – Tarde','10ª Classe','2026','F','tarde','Sala 06',40,_p25,true),
    (p_tid,_yr,_lv_sec,_ns10,'10TG','10ª G – Tarde','10ª Classe','2026','G','tarde','Sala 07',40,_p25,true),
    (p_tid,_yr,_lv_sec,_ns11,'11TA','11ª A – Tarde','11ª Classe','2026','A','tarde','Sala 08',40,_p25,true),
    (p_tid,_yr,_lv_sec,_ns11,'11TB','11ª B – Tarde','11ª Classe','2026','B','tarde','Sala 09',40,_p25,true),
    (p_tid,_yr,_lv_sec,_ns11,'11TC','11ª C – Tarde','11ª Classe','2026','C','tarde','Sala 10',40,_p25,true),
    (p_tid,_yr,_lv_sec,_ns11,'11TD','11ª D – Tarde','11ª Classe','2026','D','tarde','Sala 11',40,_p25,true),
    (p_tid,_yr,_lv_sec,_ns11,'11TE','11ª E – Tarde','11ª Classe','2026','E','tarde','Sala 12',40,_p25,true),
    (p_tid,_yr,_lv_sec,_ns11,'11TF','11ª F – Tarde','11ª Classe','2026','F','tarde','Sala 13',40,_p25,true),
    (p_tid,_yr,_lv_sec,_ns11,'11TG','11ª G – Tarde','11ª Classe','2026','G','tarde','Sala 14',40,_p25,true),
    (p_tid,_yr,_lv_sec,_ns12,'12TA','12ª A – Tarde','12ª Classe','2026','A','tarde','Sala 15',40,_p25,true),
    (p_tid,_yr,_lv_sec,_ns12,'12TB','12ª B – Tarde','12ª Classe','2026','B','tarde','Sala 16',40,_p25,true),
    (p_tid,_yr,_lv_sec,_ns12,'12TC','12ª C – Tarde','12ª Classe','2026','C','tarde','Sala 17',40,_p25,true),
    (p_tid,_yr,_lv_sec,_ns12,'12TD','12ª D – Tarde','12ª Classe','2026','D','tarde','Sala 18',40,_p25,true),
    (p_tid,_yr,_lv_sec,_ns12,'12TE','12ª E – Tarde','12ª Classe','2026','E','tarde','Sala 19',40,_p25,true),
    (p_tid,_yr,_lv_sec,_ns12,'12TF','12ª F – Tarde','12ª Classe','2026','F','tarde','Sala 20',40,_p25,true)
ON CONFLICT (tenant_id, codigo, ano_lectivo) DO NOTHING;

-- ── NOITE (7ª-12ª misto) ─────────────────────────────────────
INSERT INTO school_classes
    (tenant_id,school_year_id,level_id,series_id,codigo,nome,
     nivel,ano_lectivo,turma,turno,sala,capacidade,director_teacher_id,activo)
VALUES
    (p_tid,_yr,_lv_sec,_ns7, '7NA','7ª A – Noite', '7ª Classe','2026','A','noite','Sala 01',35,_p25,true),
    (p_tid,_yr,_lv_sec,_ns7, '7NB','7ª B – Noite', '7ª Classe','2026','B','noite','Sala 02',35,_p25,true),
    (p_tid,_yr,_lv_sec,_ns7, '7NC','7ª C – Noite', '7ª Classe','2026','C','noite','Sala 03',35,_p25,true),
    (p_tid,_yr,_lv_sec,_ns8, '8NA','8ª A – Noite', '8ª Classe','2026','A','noite','Sala 04',35,_p25,true),
    (p_tid,_yr,_lv_sec,_ns8, '8NB','8ª B – Noite', '8ª Classe','2026','B','noite','Sala 05',35,_p25,true),
    (p_tid,_yr,_lv_sec,_ns8, '8NC','8ª C – Noite', '8ª Classe','2026','C','noite','Sala 06',35,_p25,true),
    (p_tid,_yr,_lv_sec,_ns9, '9NA','9ª A – Noite', '9ª Classe','2026','A','noite','Sala 07',35,_p25,true),
    (p_tid,_yr,_lv_sec,_ns9, '9NB','9ª B – Noite', '9ª Classe','2026','B','noite','Sala 08',35,_p25,true),
    (p_tid,_yr,_lv_sec,_ns9, '9NC','9ª C – Noite', '9ª Classe','2026','C','noite','Sala 09',35,_p25,true),
    (p_tid,_yr,_lv_sec,_ns10,'10NA','10ª A – Noite','10ª Classe','2026','A','noite','Sala 10',35,_p25,true),
    (p_tid,_yr,_lv_sec,_ns10,'10NB','10ª B – Noite','10ª Classe','2026','B','noite','Sala 11',35,_p25,true),
    (p_tid,_yr,_lv_sec,_ns10,'10NC','10ª C – Noite','10ª Classe','2026','C','noite','Sala 12',35,_p25,true),
    (p_tid,_yr,_lv_sec,_ns10,'10ND','10ª D – Noite','10ª Classe','2026','D','noite','Sala 13',35,_p25,true),
    (p_tid,_yr,_lv_sec,_ns11,'11NA','11ª A – Noite','11ª Classe','2026','A','noite','Sala 14',35,_p25,true),
    (p_tid,_yr,_lv_sec,_ns11,'11NB','11ª B – Noite','11ª Classe','2026','B','noite','Sala 15',35,_p25,true),
    (p_tid,_yr,_lv_sec,_ns11,'11NC','11ª C – Noite','11ª Classe','2026','C','noite','Sala 16',35,_p25,true),
    (p_tid,_yr,_lv_sec,_ns11,'11ND','11ª D – Noite','11ª Classe','2026','D','noite','Sala 17',35,_p25,true),
    (p_tid,_yr,_lv_sec,_ns12,'12NA','12ª A – Noite','12ª Classe','2026','A','noite','Sala 18',35,_p25,true),
    (p_tid,_yr,_lv_sec,_ns12,'12NB','12ª B – Noite','12ª Classe','2026','B','noite','Sala 19',35,_p25,true),
    (p_tid,_yr,_lv_sec,_ns12,'12NC','12ª C – Noite','12ª Classe','2026','C','noite','Sala 20',35,_p25,true)
ON CONFLICT (tenant_id, codigo, ano_lectivo) DO NOTHING;

-- ══════════════════════════════════════════════════════════════
-- 17. COLECTAR ARRAYS – Lei 18/2018
-- ══════════════════════════════════════════════════════════════
SELECT ARRAY_AGG(id) INTO _arr_nsm
    FROM school_classes WHERE tenant_id=p_tid AND school_year_id=_yr AND level_id=_lv_sec AND turno='manha';
SELECT ARRAY_AGG(id) INTO _arr_nst
    FROM school_classes WHERE tenant_id=p_tid AND school_year_id=_yr AND level_id=_lv_sec AND turno='tarde';
SELECT ARRAY_AGG(id) INTO _arr_nsn
    FROM school_classes WHERE tenant_id=p_tid AND school_year_id=_yr AND level_id=_lv_sec AND turno='noite';
SELECT ARRAY_AGG(id) INTO _arr_nsn_7a9
    FROM school_classes WHERE tenant_id=p_tid AND school_year_id=_yr AND level_id=_lv_sec AND turno='noite'
    AND series_id IN (_ns7,_ns8,_ns9);
SELECT ARRAY_AGG(id) INTO _arr_nsn_1012
    FROM school_classes WHERE tenant_id=p_tid AND school_year_id=_yr AND level_id=_lv_sec AND turno='noite'
    AND series_id IN (_ns10,_ns11,_ns12);
_arr_ns_7a9  := _arr_nsm || _arr_nsn_7a9;    -- manhã(20) + noite7-9(9)   = 29
_arr_ns_1012 := _arr_nst || _arr_nsn_1012;   -- tarde(20) + noite10-12(11) = 31

SELECT ARRAY_AGG(id) INTO _arr_pri_all
    FROM school_classes WHERE tenant_id=p_tid AND school_year_id=_yr AND level_id=_lv_pri;
SELECT ARRAY_AGG(id) INTO _arr_pre_all
    FROM school_classes WHERE tenant_id=p_tid AND school_year_id=_yr AND level_id=_lv_pre;

-- ══════════════════════════════════════════════════════════════
-- 18. ATRIBUIÇÕES – Lei 18/2018 (780 via unnest)
-- ══════════════════════════════════════════════════════════════

-- ── Secundário 7ª-9ª (11 disc × 29 turmas = 319) ─────────────
-- POR-01→7ª-9ª · MAT-04 · ING-07 · FIS-09 · QUI-11 · BIO-13
-- GEO-15 · HIS-17 · EDF-19(+noite) · EDV-21 · EMC-22
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_por,_p01,'2026-02-02' FROM unnest(_arr_ns_7a9) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_mat,_p04,'2026-02-02' FROM unnest(_arr_ns_7a9) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_ing,_p07,'2026-02-02' FROM unnest(_arr_ns_7a9) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_fis,_p09,'2026-02-02' FROM unnest(_arr_ns_7a9) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_qui,_p11,'2026-02-02' FROM unnest(_arr_ns_7a9) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_bio,_p13,'2026-02-02' FROM unnest(_arr_ns_7a9) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_geo,_p15,'2026-02-02' FROM unnest(_arr_ns_7a9) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_his,_p17,'2026-02-02' FROM unnest(_arr_ns_7a9) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_edv,_p21,'2026-02-02' FROM unnest(_arr_ns_7a9) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_emc,_p22,'2026-02-02' FROM unnest(_arr_ns_7a9) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;
-- EDF: PROF-19→manhã+noite · PROF-20→tarde (para 7ª-9ª manhã já cobre unnest acima com _arr_nsm)
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_edf,_p19,'2026-02-02' FROM unnest(_arr_nsm||_arr_nsn) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;

-- ── Secundário 10ª-12ª (11 disc × 31 turmas = 341) ───────────
-- POR-02 · MAT-05 · ING-08 · FIS-10 · QUI-12 · BIO-14
-- GEO-16 · HIS-18 · EDF-20 · FIL-23 · ECO-24
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_por,_p02,'2026-02-02' FROM unnest(_arr_ns_1012) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_mat,_p05,'2026-02-02' FROM unnest(_arr_ns_1012) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_ing,_p08,'2026-02-02' FROM unnest(_arr_ns_1012) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_fis,_p10,'2026-02-02' FROM unnest(_arr_ns_1012) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_qui,_p12,'2026-02-02' FROM unnest(_arr_ns_1012) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_bio,_p14,'2026-02-02' FROM unnest(_arr_ns_1012) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_geo,_p16,'2026-02-02' FROM unnest(_arr_ns_1012) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_his,_p18,'2026-02-02' FROM unnest(_arr_ns_1012) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_edf,_p20,'2026-02-02' FROM unnest(_arr_nst) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_fil,_p23,'2026-02-02' FROM unnest(_arr_ns_1012) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_eco,_p24,'2026-02-02' FROM unnest(_arr_ns_1012) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;

-- ── Primário (6 disc × 18 turmas = 108) ──────────────────────
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_por,_p26,'2026-02-02' FROM unnest(_arr_pri_all) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_mat,_p27,'2026-02-02' FROM unnest(_arr_pri_all) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_cn,_p28,'2026-02-02' FROM unnest(_arr_pri_all) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_cs,_p29,'2026-02-02' FROM unnest(_arr_pri_all) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_eva,_p30,'2026-02-02' FROM unnest(_arr_pri_all) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_edf,_p19,'2026-02-02' FROM unnest(_arr_pri_all) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;

-- ── Pré-Escolar (4 disc × 3 grupos = 12) ─────────────────────
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_loae,_p30,'2026-02-02' FROM unnest(_arr_pre_all) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_rmat,_p30,'2026-02-02' FROM unnest(_arr_pre_all) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_emd,_p30,'2026-02-02' FROM unnest(_arr_pre_all) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;
INSERT INTO school_teacher_assignments (tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio)
SELECT p_tid,_yr,c,_ecri,_p30,'2026-02-02' FROM unnest(_arr_pre_all) AS c
ON CONFLICT (tenant_id,class_id,subject_id,teacher_id,data_inicio) DO NOTHING;

-- ══════════════════════════════════════════════════════════════
-- 19. PLANOS DE PROPINAS – Lei 18/2018
-- ══════════════════════════════════════════════════════════════
INSERT INTO school_fee_plans (tenant_id, school_year_id, codigo, nome, tipo, valor, moeda, periodicidade, dia_vencimento, classe_nivel) VALUES
    (p_tid,_yr,'PROP-PRE',      'Propina Pré-Escolar',               'propina', 300.00,'MZN','mensal',25,'Pré-Escolar'),
    (p_tid,_yr,'PROP-PRI-13',   'Propina Primário 1ª–3ª Classe',     'propina', 200.00,'MZN','mensal',25,'1ª-3ª Manhã'),
    (p_tid,_yr,'PROP-PRI-46',   'Propina Primário 4ª–6ª Classe',     'propina', 250.00,'MZN','mensal',25,'4ª-6ª Tarde'),
    (p_tid,_yr,'PROP-SEC-79M',  'Propina Sec. 7ª–9ª Manhã',         'propina', 450.00,'MZN','mensal',25,'7ª-9ª Manhã'),
    (p_tid,_yr,'PROP-SEC-1012T','Propina Sec. 10ª–12ª Tarde',       'propina', 550.00,'MZN','mensal',25,'10ª-12ª Tarde'),
    (p_tid,_yr,'PROP-SEC-N',    'Propina Sec. Noite (Lei 18/2018)',  'propina', 500.00,'MZN','mensal',25,'7ª-12ª Noite'),
    (p_tid,_yr,'MATR-PRE-2026', 'Matrícula Pré-Escolar 2026',       'matricula',100.00,'MZN','anual', 28, NULL),
    (p_tid,_yr,'MATR-PRI-2026', 'Matrícula Primário 2026',          'matricula',150.00,'MZN','anual', 28, NULL)
ON CONFLICT (tenant_id, codigo) DO NOTHING;

-- ══════════════════════════════════════════════════════════════
RAISE NOTICE '════════════════════════════════════════════════════════════';
RAISE NOTICE 'Seed concluído – Enigma School | Ano Lectivo 2026';
RAISE NOTICE '  Tenant ID : %', p_tid;
RAISE NOTICE '────────────────────────────────────────────────────────────';
RAISE NOTICE 'Lei n.º 6/92  – Secundário Geral (ID %)', _lv;
RAISE NOTICE '  Turmas  : 60 (20 manhã 8ª-10ª · 20 tarde 11ª-12ª · 20 noite)';
RAISE NOTICE '  Atribuições: 660';
RAISE NOTICE '────────────────────────────────────────────────────────────';
RAISE NOTICE 'Lei n.º 18/2018 – SNE 2018';
RAISE NOTICE '  Pré-Escolar (ID %) : 3 grupos', _lv_pre;
RAISE NOTICE '  Primário    (ID %) : 18 turmas (1ª-6ª)', _lv_pri;
RAISE NOTICE '  Secundário  (ID %) : 60 turmas (7ª-12ª, 20/turno)', _lv_sec;
RAISE NOTICE '  Atribuições: 780 (660 sec + 108 prim + 12 pré)';
RAISE NOTICE '────────────────────────────────────────────────────────────';
RAISE NOTICE 'Total: 141 turmas · 30 professores · 20 disciplinas · 1440 atribuições';
RAISE NOTICE '════════════════════════════════════════════════════════════';

END $$;
