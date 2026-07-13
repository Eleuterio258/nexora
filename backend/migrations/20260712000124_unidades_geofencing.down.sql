ALTER TABLE rh.unidades_organizacionais
    DROP COLUMN IF EXISTS latitude,
    DROP COLUMN IF EXISTS longitude,
    DROP COLUMN IF EXISTS raio_metros;
