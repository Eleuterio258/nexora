-- Item 8 do plano-mudancas-backend-paycore-mobile.md: entidade de desconto
-- POS autonoma, aplicavel diretamente numa venda — ate agora so existiam
-- descontos acoplados a produto (produtos.product_discounts) e a cliente
-- (gestao-clientes), sem ligacao entre si nem com o POS.
CREATE TABLE pos.pos_discounts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    nome VARCHAR(120) NOT NULL,
    descricao TEXT,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('percentual', 'valor_fixo')),
    valor NUMERIC(12,2) NOT NULL,
    valor_minimo NUMERIC(12,2),
    valor_maximo NUMERIC(12,2),
    valido_de DATE,
    valido_ate DATE,
    activo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_pos_discounts_tenant ON pos.pos_discounts (tenant_id);
