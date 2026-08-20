-- ============================================================
-- SEEDS: Divisão Administrativa de Moçambique
-- ============================================================
-- Este script insere dados iniciais de Moçambique no schema
-- territorial.divisao_administrativa.
--
-- Estrutura:
--   País (Moçambique)
--   └── Províncias (10 + Cidade de Maputo)
--       └── Cidades / Municípios / Distritos
--           └── Postos administrativos, localidades, bairros, etc.
--
-- NOTA: As geometrias devem ser importadas posteriormente a partir
-- de fontes oficiais (INE, cartografia municipal, shapefiles).
-- ============================================================

-- Limpar dados existentes (opcional — usar com cuidado)
-- TRUNCATE TABLE territorial.divisao_administrativa CASCADE;

-- ------------------------------------------------------------
-- 1. PAÍS
-- ------------------------------------------------------------
INSERT INTO territorial.divisao_administrativa (tipo, codigo, nome, nome_normalizado, nivel_hierarquico, zona_urbana, metadados)
VALUES ('pais', 'MZ', 'Moçambique', 'mocambique', 0, NULL, '{"fonte":"INE / Governo de Moçambique"}'::jsonb)
ON CONFLICT (codigo) DO NOTHING;

-- Guardar ID do país para usar nos inserts seguintes
DO $$
DECLARE
    v_pais_id UUID;
BEGIN
    SELECT id INTO v_pais_id FROM territorial.divisao_administrativa WHERE codigo = 'MZ';

-- ------------------------------------------------------------
-- 2. PROVÍNCIAS
-- ------------------------------------------------------------
INSERT INTO territorial.divisao_administrativa (parent_id, tipo, codigo, nome, nome_normalizado, nivel_hierarquico, zona_urbana, metadados)
SELECT v_pais_id, 'provincia', codigo, nome, nome_normalizado, 1, NULL, metadados
FROM (VALUES
    ('MZ_CDM', 'Cidade de Maputo', 'cidade de maputo', '{"capital":"Maputo"}'::jsonb),
    ('MZ_MAP', 'Província de Maputo', 'provincia de maputo', '{"capital":"Matola"}'::jsonb),
    ('MZ_GAZ', 'Província de Gaza', 'provincia de gaza', '{"capital":"Xai-Xai"}'::jsonb),
    ('MZ_INH', 'Província de Inhambane', 'provincia de inhambane', '{"capital":"Inhambane"}'::jsonb),
    ('MZ_SOF', 'Província de Sofala', 'provincia de sofala', '{"capital":"Beira"}'::jsonb),
    ('MZ_MAN', 'Província de Manica', 'provincia de manica', '{"capital":"Chimoio"}'::jsonb),
    ('MZ_TET', 'Província de Tete', 'provincia de tete', '{"capital":"Tete"}'::jsonb),
    ('MZ_ZAM', 'Província da Zambézia', 'provincia da zambezia', '{"capital":"Quelimane"}'::jsonb),
    ('MZ_NAM', 'Província de Nampula', 'provincia de nampula', '{"capital":"Nampula"}'::jsonb),
    ('MZ_CAB', 'Província de Cabo Delgado', 'provincia de cabo delgado', '{"capital":"Pemba"}'::jsonb),
    ('MZ_NIA', 'Província de Niassa', 'provincia de niassa', '{"capital":"Lichinga"}'::jsonb)
) AS p(codigo, nome, nome_normalizado, metadados)
ON CONFLICT (codigo) DO NOTHING;

-- ------------------------------------------------------------
-- 3. CIDADES / MUNICÍPIOS / DISTRITOS
-- ------------------------------------------------------------

-- Cidade de Maputo
WITH prov AS (SELECT id FROM territorial.divisao_administrativa WHERE codigo = 'MZ_CDM')
INSERT INTO territorial.divisao_administrativa (parent_id, tipo, codigo, nome, nome_normalizado, nivel_hierarquico, zona_urbana)
SELECT prov.id, 'distrito_municipal', 'CDM_' || codigo, nome, nome_normalizado, 2, TRUE
FROM prov, (VALUES
    ('KAMPFUMO', 'Distrito Municipal KaMpfumo', 'distrito municipal kampfumo'),
    ('NHAMMAVO', 'Distrito Municipal Nhlamankulo', 'distrito municipal nhlamankulo'),
    ('Kamaxakeni', 'Distrito Municipal KaMaxakeni', 'distrito municipal kamaxakeni'),
    ('KAMAVOTA', 'Distrito Municipal KaMavota', 'distrito municipal kamavota'),
    ('KAMUBUKWANA', 'Distrito Municipal KaMubukwana', 'distrito municipal kamubukwana'),
    ('KATEMBE', 'Distrito Municipal Katembe', 'distrito municipal katembe'),
    ('KANYAKA', 'Distrito Municipal Kanyaka', 'distrito municipal kanyaka')
) AS d(codigo, nome, nome_normalizado)
ON CONFLICT (codigo) DO NOTHING;

-- Província de Maputo
WITH prov AS (SELECT id FROM territorial.divisao_administrativa WHERE codigo = 'MZ_MAP')
INSERT INTO territorial.divisao_administrativa (parent_id, tipo, codigo, nome, nome_normalizado, nivel_hierarquico, zona_urbana)
SELECT prov.id, t, 'MAP_' || codigo, nome, nome_normalizado, 2, zu
FROM prov, (VALUES
    ('MATOLA', 'Matola', 'matola', 'municipio', TRUE),
    ('BOANE', 'Boane', 'boane', 'distrito', FALSE),
    ('MARRACUENE', 'Marracuene', 'marracuene', 'distrito', FALSE),
    ('MANHICA', 'Manhiça', 'manhica', 'distrito', FALSE),
    ('MOAMBA', 'Moamba', 'moamba', 'distrito', FALSE),
    ('NAMAACHA', 'Namaacha', 'namaacha', 'distrito', FALSE),
    ('MAGUDE', 'Magude', 'magude', 'distrito', FALSE)
) AS d(codigo, nome, nome_normalizado, t, zu)
ON CONFLICT (codigo) DO NOTHING;

-- Província de Gaza
WITH prov AS (SELECT id FROM territorial.divisao_administrativa WHERE codigo = 'MZ_GAZ')
INSERT INTO territorial.divisao_administrativa (parent_id, tipo, codigo, nome, nome_normalizado, nivel_hierarquico, zona_urbana)
SELECT prov.id, t, 'GAZ_' || codigo, nome, nome_normalizado, 2, zu
FROM prov, (VALUES
    ('XAIXAI', 'Xai-Xai', 'xai-xai', 'cidade', TRUE),
    ('CHIBUTO', 'Chibuto', 'chibuto', 'distrito', FALSE),
    ('CHOKWE', 'Chókwè', 'chokwe', 'distrito', FALSE),
    ('GUIJA', 'Guijá', 'guija', 'distrito', FALSE),
    ('MASSINGIR', 'Massingir', 'massingir', 'distrito', FALSE),
    ('MASSINGA', 'Massinga', 'massinga', 'distrito', FALSE),
    ('BILENE', 'Bilene', 'bilene', 'distrito', FALSE)
) AS d(codigo, nome, nome_normalizado, t, zu)
ON CONFLICT (codigo) DO NOTHING;

-- Província de Inhambane
WITH prov AS (SELECT id FROM territorial.divisao_administrativa WHERE codigo = 'MZ_INH')
INSERT INTO territorial.divisao_administrativa (parent_id, tipo, codigo, nome, nome_normalizado, nivel_hierarquico, zona_urbana)
SELECT prov.id, t, 'INH_' || codigo, nome, nome_normalizado, 2, zu
FROM prov, (VALUES
    ('INHAMBANE', 'Inhambane', 'inhambane', 'cidade', TRUE),
    ('MAXIXE', 'Maxixe', 'maxixe', 'cidade', TRUE),
    ('VILANCULOS', 'Vilanculos', 'vilanculos', 'distrito', FALSE),
    ('MABOTE', 'Mabote', 'mabote', 'distrito', FALSE),
    ('FUNHALOURO', 'Funhalouro', 'funhalouro', 'distrito', FALSE),
    ('HOMOINE', 'Homoíne', 'homoine', 'distrito', FALSE),
    ('JANGAMO', 'Jangamo', 'jangamo', 'distrito', FALSE)
) AS d(codigo, nome, nome_normalizado, t, zu)
ON CONFLICT (codigo) DO NOTHING;

-- Província de Sofala
WITH prov AS (SELECT id FROM territorial.divisao_administrativa WHERE codigo = 'MZ_SOF')
INSERT INTO territorial.divisao_administrativa (parent_id, tipo, codigo, nome, nome_normalizado, nivel_hierarquico, zona_urbana)
SELECT prov.id, t, 'SOF_' || codigo, nome, nome_normalizado, 2, zu
FROM prov, (VALUES
    ('BEIRA', 'Beira', 'beira', 'cidade', TRUE),
    ('DONDO', 'Dondo', 'dondo', 'distrito', FALSE),
    ('NOVA_MAMORE', 'Maringué', 'maringue', 'distrito', FALSE),
    ('CAIA', 'Caia', 'caia', 'distrito', FALSE),
    ('CHEMBA', 'Chemba', 'chemba', 'distrito', FALSE),
    ('CHERINGOMA', 'Cheringoma', 'cheringoma', 'distrito', FALSE),
    ('GORONGOSA', 'Gorongosa', 'gorongosa', 'distrito', FALSE)
) AS d(codigo, nome, nome_normalizado, t, zu)
ON CONFLICT (codigo) DO NOTHING;

-- Província de Manica
WITH prov AS (SELECT id FROM territorial.divisao_administrativa WHERE codigo = 'MZ_MAN')
INSERT INTO territorial.divisao_administrativa (parent_id, tipo, codigo, nome, nome_normalizado, nivel_hierarquico, zona_urbana)
SELECT prov.id, t, 'MAN_' || codigo, nome, nome_normalizado, 2, zu
FROM prov, (VALUES
    ('CHIMOIO', 'Chimoio', 'chimoio', 'cidade', TRUE),
    ('MANICA', 'Manica', 'manica', 'distrito', FALSE),
    ('GONDOLA', 'Gondola', 'gondola', 'distrito', FALSE),
    ('MACATE', 'Macate', 'macate', 'distrito', FALSE),
    ('VANDUZI', 'Vanduzi', 'vanduzi', 'distrito', FALSE),
    ('SUSSUNDENGA', 'Sussundenga', 'sussundenga', 'distrito', FALSE),
    ('BARUE', 'Barué', 'barue', 'distrito', FALSE)
) AS d(codigo, nome, nome_normalizado, t, zu)
ON CONFLICT (codigo) DO NOTHING;

-- Província de Tete
WITH prov AS (SELECT id FROM territorial.divisao_administrativa WHERE codigo = 'MZ_TET')
INSERT INTO territorial.divisao_administrativa (parent_id, tipo, codigo, nome, nome_normalizado, nivel_hierarquico, zona_urbana)
SELECT prov.id, t, 'TET_' || codigo, nome, nome_normalizado, 2, zu
FROM prov, (VALUES
    ('TETE', 'Tete', 'tete', 'cidade', TRUE),
    ('MOATIZE', 'Moatize', 'moatize', 'distrito', FALSE),
    ('CHANGARA', 'Changara', 'changara', 'distrito', FALSE),
    ('TSANGANO', 'Tsangano', 'tsangano', 'distrito', FALSE),
    ('ANGONIA', 'Angónia', 'angonia', 'distrito', FALSE),
    ('MARARA', 'Marara', 'marara', 'distrito', FALSE),
    ('MAGOE', 'Magoe', 'magoe', 'distrito', FALSE)
) AS d(codigo, nome, nome_normalizado, t, zu)
ON CONFLICT (codigo) DO NOTHING;

-- Província da Zambézia
WITH prov AS (SELECT id FROM territorial.divisao_administrativa WHERE codigo = 'MZ_ZAM')
INSERT INTO territorial.divisao_administrativa (parent_id, tipo, codigo, nome, nome_normalizado, nivel_hierarquico, zona_urbana)
SELECT prov.id, t, 'ZAM_' || codigo, nome, nome_normalizado, 2, zu
FROM prov, (VALUES
    ('QUELIMANE', 'Quelimane', 'quelimane', 'cidade', TRUE),
    ('ALTO_MOLOCUE', 'Alto Molócue', 'alto molocue', 'distrito', FALSE),
    ('GURUE', 'Gurué', 'gurue', 'distrito', FALSE),
    ('NAMARROI', 'Namarroi', 'namarroi', 'distrito', FALSE),
    ('MOCUBA', 'Mocuba', 'mocuba', 'distrito', FALSE),
    ('MILANGE', 'Milange', 'milange', 'distrito', FALSE),
    ('NICODALA', 'Nicoadala', 'nicoadala', 'distrito', FALSE)
) AS d(codigo, nome, nome_normalizado, t, zu)
ON CONFLICT (codigo) DO NOTHING;

-- Província de Nampula
WITH prov AS (SELECT id FROM territorial.divisao_administrativa WHERE codigo = 'MZ_NAM')
INSERT INTO territorial.divisao_administrativa (parent_id, tipo, codigo, nome, nome_normalizado, nivel_hierarquico, zona_urbana)
SELECT prov.id, t, 'NAM_' || codigo, nome, nome_normalizado, 2, zu
FROM prov, (VALUES
    ('NAMPULA', 'Nampula', 'nampula', 'cidade', TRUE),
    ('NACALA', 'Nacala', 'nacala', 'cidade', TRUE),
    ('MONAPO', 'Monapo', 'monapo', 'distrito', FALSE),
    ('ANGOCHE', 'Angoche', 'angoche', 'distrito', FALSE),
    ('MECUBURI', 'Mecubúri', 'mecuburi', 'distrito', FALSE),
    ('MURRUPULA', 'Murrupula', 'murrupula', 'distrito', FALSE),
    ('RAPALE', 'Rapale', 'rapale', 'distrito', FALSE)
) AS d(codigo, nome, nome_normalizado, t, zu)
ON CONFLICT (codigo) DO NOTHING;

-- Província de Cabo Delgado
WITH prov AS (SELECT id FROM territorial.divisao_administrativa WHERE codigo = 'MZ_CAB')
INSERT INTO territorial.divisao_administrativa (parent_id, tipo, codigo, nome, nome_normalizado, nivel_hierarquico, zona_urbana)
SELECT prov.id, t, 'CAB_' || codigo, nome, nome_normalizado, 2, zu
FROM prov, (VALUES
    ('PEMBA', 'Pemba', 'pemba', 'cidade', TRUE),
    ('MONTepUEZ', 'Montepuez', 'montepuez', 'distrito', FALSE),
    ('MUIDUMBE', 'Muidumbe', 'muidumbe', 'distrito', FALSE),
    ('MACOMIA', 'Macomia', 'macomia', 'distrito', FALSE),
    ('ANCUABE', 'Ancuabe', 'ancuabe', 'distrito', FALSE),
    ('CHIURE', 'Chiúre', 'chiure', 'distrito', FALSE),
    ('BALAMA', 'Balama', 'balama', 'distrito', FALSE)
) AS d(codigo, nome, nome_normalizado, t, zu)
ON CONFLICT (codigo) DO NOTHING;

-- Província de Niassa
WITH prov AS (SELECT id FROM territorial.divisao_administrativa WHERE codigo = 'MZ_NIA')
INSERT INTO territorial.divisao_administrativa (parent_id, tipo, codigo, nome, nome_normalizado, nivel_hierarquico, zona_urbana)
SELECT prov.id, t, 'NIA_' || codigo, nome, nome_normalizado, 2, zu
FROM prov, (VALUES
    ('LICHINGA', 'Lichinga', 'lichigna', 'cidade', TRUE),
    ('CUAMBA', 'Cuamba', 'cuamba', 'distrito', FALSE),
    ('MANDIMBA', 'Mandimba', 'mandimba', 'distrito', FALSE),
    ('LUNGO', 'Lungo', 'lungo', 'distrito', FALSE),
    ('MAUA', 'Maua', 'maua', 'distrito', FALSE),
    ('NGAUMA', 'Ngauma', 'ngauma', 'distrito', FALSE),
    ('LUPILO', 'Lupilho', 'lupilho', 'distrito', FALSE)
) AS d(codigo, nome, nome_normalizado, t, zu)
ON CONFLICT (codigo) DO NOTHING;

-- ------------------------------------------------------------
-- 4. EXEMPLOS DE POSTOS ADMINISTRATIVOS E BAIRROS
-- ------------------------------------------------------------

-- Exemplo: Postos administrativos do Distrito de Marracuene
WITH dist AS (SELECT id FROM territorial.divisao_administrativa WHERE codigo = 'MAP_MARRACUENE')
INSERT INTO territorial.divisao_administrativa (parent_id, tipo, codigo, nome, nome_normalizado, nivel_hierarquico, zona_urbana)
SELECT dist.id, 'posto_administrativo', 'MAP_MARRACUENE_' || codigo, nome, nome_normalizado, 3, FALSE
FROM dist, (VALUES
    ('MACHUBO', 'Posto Administrativo de Machubo', 'posto administrativo de machubo'),
    ('OLIFANTSFONTEIN', 'Posto Administrativo de Olifantsfontein', 'posto administrativo de olifantsfontein')
) AS p(codigo, nome, nome_normalizado)
ON CONFLICT (codigo) DO NOTHING;

-- Exemplo: Bairros do Distrito Municipal KaMpfumo
WITH dist AS (SELECT id FROM territorial.divisao_administrativa WHERE codigo = 'CDM_KAMPFUMO')
INSERT INTO territorial.divisao_administrativa (parent_id, tipo, codigo, nome, nome_normalizado, nivel_hierarquico, zona_urbana)
SELECT dist.id, 'bairro', 'CDM_KAMPFUMO_' || codigo, nome, nome_normalizado, 3, TRUE
FROM dist, (VALUES
    ('CENTRAL', 'Bairro Central', 'bairro central'),
    ('COOP', 'Bairro Coop', 'bairro coop'),
    ('MALhangalene', 'Bairro Malhangalene', 'bairro malhangalene'),
    ('POLANA_CANICO', 'Bairro Polana Caniço', 'bairro polana canico')
) AS b(codigo, nome, nome_normalizado)
ON CONFLICT (codigo) DO NOTHING;

-- Exemplo: Quarteirões do Bairro Central
WITH bairro AS (SELECT id FROM territorial.divisao_administrativa WHERE codigo = 'CDM_KAMPFUMO_CENTRAL')
INSERT INTO territorial.divisao_administrativa (parent_id, tipo, codigo, nome, nome_normalizado, nivel_hierarquico, zona_urbana)
SELECT bairro.id, 'quarteirao', 'CDM_KAMPFUMO_CENTRAL_Q' || codigo, 'Quarteirão ' || codigo, 'quarteirao ' || codigo, 4, TRUE
FROM bairro, generate_series(1, 5) AS codigo
ON CONFLICT (codigo) DO NOTHING;

END $$;

-- ------------------------------------------------------------
-- 5. VERIFICAÇÃO DOS DADOS INSERIDOS
-- ------------------------------------------------------------
SELECT
    d.tipo,
    COUNT(*) AS total
FROM territorial.divisao_administrativa d
GROUP BY d.tipo
ORDER BY total DESC;
