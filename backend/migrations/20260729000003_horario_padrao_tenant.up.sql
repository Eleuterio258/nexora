-- Horário de trabalho padrão do tenant.
--
-- Até aqui o horário era exclusivamente uma propriedade do funcionário
-- (rh.funcionarios.horario_id, opcional). Consequência: quem fosse admitido sem
-- se escolher horário no formulário ficava sem horário nenhum, e como o job de
-- faltas faz JOIN por f.horario_id, a assiduidade dessa pessoa nunca chegava a
-- ser processada — nem faltas, nem cálculo. Aconteceu com 2 dos 37
-- funcionários (Ana Paulo Machava e Bento Muianga), sem qualquer sinal de erro.
--
-- O horário é uma regra da empresa, não de cada pessoa: a esmagadora maioria
-- dos trabalhadores cumpre o horário normal do tenant, e o horário individual
-- é a excepção (turnos, tempo parcial). Passa por isso a existir um horário
-- padrão por tenant, e a resolução fica:
--
--     horário efectivo = COALESCE(funcionario.horario_id, horário padrão do tenant)
--
-- rh.funcionarios.horario_id mantém-se e continua a ganhar sempre que estiver
-- preenchido — é a excepção individual, não desaparece.

BEGIN;

ALTER TABLE rh.horarios_trabalho
    ADD COLUMN IF NOT EXISTS padrao boolean NOT NULL DEFAULT false;

-- No máximo um horário padrão por tenant.
CREATE UNIQUE INDEX IF NOT EXISTS uq_horarios_trabalho_padrao_por_tenant
    ON rh.horarios_trabalho (tenant_id)
    WHERE padrao;

-- Backfill: onde o tenant tem exactamente um horário activo, esse passa a ser o
-- padrão — é de facto o que já estava a ser usado por toda a gente. Tenants com
-- vários horários ficam sem padrão definido, para não escolher por eles.
UPDATE rh.horarios_trabalho h
   SET padrao = true, updated_at = NOW()
 WHERE h.ativo
   AND NOT EXISTS (SELECT 1 FROM rh.horarios_trabalho p WHERE p.tenant_id = h.tenant_id AND p.padrao)
   AND (SELECT count(*) FROM rh.horarios_trabalho x WHERE x.tenant_id = h.tenant_id AND x.ativo) = 1;

COMMENT ON COLUMN rh.horarios_trabalho.padrao IS
    'Horário aplicado aos funcionários do tenant que não tenham horario_id próprio. '
    'Máximo um por tenant (uq_horarios_trabalho_padrao_por_tenant). Ver 20260729000003.';

COMMIT;
