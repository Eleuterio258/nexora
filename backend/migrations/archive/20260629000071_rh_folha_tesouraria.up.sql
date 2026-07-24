-- ═══════════════════════════════════════════════════════════════
--  RH - Folha Salarial: Integração Tesouraria (Fase 3)
-- ═══════════════════════════════════════════════════════════════
SET search_path TO rh, public;

-- Conta bancária/caixa usada no pagamento da folha
ALTER TABLE folhas_pagamento
    ADD COLUMN IF NOT EXISTS bank_account_id BIGINT REFERENCES tesouraria.bank_accounts(id),
    ADD COLUMN IF NOT EXISTS cash_register_id BIGINT REFERENCES tesouraria.cash_registers(id),
    ADD COLUMN IF NOT EXISTS movement_id BIGINT REFERENCES tesouraria.movements(id);

CREATE INDEX IF NOT EXISTS idx_folhas_pagamento_bank_account
    ON folhas_pagamento (tenant_id, bank_account_id);

CREATE INDEX IF NOT EXISTS idx_folhas_pagamento_cash_register
    ON folhas_pagamento (tenant_id, cash_register_id);

CREATE INDEX IF NOT EXISTS idx_folhas_pagamento_movement
    ON folhas_pagamento (tenant_id, movement_id);
