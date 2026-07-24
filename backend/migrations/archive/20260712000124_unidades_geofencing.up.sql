-- Geofencing para unidades organizacionais: coordenadas de referência + raio
-- permitido, usados para validar a localização de um colaborador ao bater o
-- ponto (GET /api/hardware/assiduidade/geofence/validar). Nulos = sem
-- geofencing configurado para essa unidade (validação permissiva).

SET search_path TO rh, public;

ALTER TABLE unidades_organizacionais
    ADD COLUMN IF NOT EXISTS latitude    NUMERIC(10,7),
    ADD COLUMN IF NOT EXISTS longitude   NUMERIC(10,7),
    ADD COLUMN IF NOT EXISTS raio_metros NUMERIC(6,1);
