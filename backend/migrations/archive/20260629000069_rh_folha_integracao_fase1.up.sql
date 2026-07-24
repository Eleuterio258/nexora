-- ═══════════════════════════════════════════════════════════════
--  RH - Folha Salarial: Integração Fase 1
--  Adiciona centro de custo aos funcionários e recibos para
--  suportar alocação salarial por centro de custo (Fase 4).
-- ═══════════════════════════════════════════════════════════════
SET search_path TO rh, public;

-- Centro de custo no funcionário
ALTER TABLE funcionarios
    ADD COLUMN IF NOT EXISTS centro_custo_id BIGINT REFERENCES centros_custo.cost_centers(id);

CREATE INDEX IF NOT EXISTS idx_funcionarios_centro_custo
    ON funcionarios (tenant_id, centro_custo_id);

-- Centro de custo no recibo (snapshot do funcionário no momento do processamento)
ALTER TABLE recibos_vencimento
    ADD COLUMN IF NOT EXISTS centro_custo_id BIGINT;

CREATE INDEX IF NOT EXISTS idx_recibos_centro_custo
    ON recibos_vencimento (tenant_id, centro_custo_id);
