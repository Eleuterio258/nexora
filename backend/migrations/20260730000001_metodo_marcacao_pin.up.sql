-- Código 'pin' em rh.metodos_marcacao
--
-- O processador de eventos de hardware (hardware/service/processor.go)
-- traduz credential_type = "pin" para metodo_codigo = "pin", mas esse código
-- nunca foi semeado no catálogo: a lista original veio de
-- migrations/archive/20260721000001_rh_assiduidade_eventos.up.sql e tem 14
-- códigos (biometria, impressao_digital, reconhecimento_facial, rfid, nfc, qr,
-- app, web, gps, geofence, selfie, manual, importacao, api) — nenhum deles
-- 'pin'. Consequência: resolverMetodoID (assiduidade/eventos.go) devolve
-- ErrNoRows, RegistarEvento aborta e o evento é descartado com
-- error_message, apesar de metodoAssiduidadeActivo o ter deixado passar por o
-- tenant ter pin.ativo = true na configuração de rh.assiduidade.
--
-- 'pin' fica como código próprio em vez de reaproveitar 'biometria': o PIN é
-- justamente o método de recurso NÃO biométrico, e metodo_id é a coluna que os
-- relatórios usam para agrupar (join em handlers/eventos_assiduidade.go).
-- Colapsá-lo em 'biometria' seria irreversível — deixava de haver forma de
-- separar marcações biométricas reais de marcações por PIN.
--
-- requer_dispositivo = FALSE porque o PIN não depende de leitor biométrico
-- (pode vir do terminal ZKTeco ou da app); requer_localizacao /
-- requer_selfie = FALSE porque o PIN por si só não implica GPS nem foto.
--
-- Semeia apenas nos tenants que já têm catálogo, para não inventar linhas em
-- tenants sem assiduidade configurada. NOTA: continua a não existir
-- provisionamento automático deste catálogo para tenants novos — um tenant
-- criado depois desta migração fica sem nenhum método e falha em todos, não só
-- no PIN. Fica fora do âmbito desta correcção.

INSERT INTO rh.metodos_marcacao (tenant_id, codigo, nome, requer_dispositivo, requer_localizacao, requer_selfie)
SELECT DISTINCT m.tenant_id, 'pin', 'Código PIN', FALSE, FALSE, FALSE
  FROM rh.metodos_marcacao m
ON CONFLICT (tenant_id, codigo) DO NOTHING;
