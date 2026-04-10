CREATE TABLE IF NOT EXISTS product_categories (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(50),
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_product_categories UNIQUE NULLS NOT DISTINCT (tenant_id, codigo)
);
CREATE TABLE IF NOT EXISTS product_subcategories (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    product_category_id BIGINT NOT NULL,
    codigo VARCHAR(50),
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_product_subcategories UNIQUE NULLS NOT DISTINCT (tenant_id, codigo),
    CONSTRAINT fk_product_subcategories_category FOREIGN KEY (product_category_id) REFERENCES product_categories(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS product_brands (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(50),
    nome VARCHAR(100) NOT NULL,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_product_brands UNIQUE NULLS NOT DISTINCT (tenant_id, codigo)
);
CREATE TABLE IF NOT EXISTS product_units (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(80) NOT NULL,
    simbolo VARCHAR(20),
    casas_decimais INTEGER NOT NULL DEFAULT 2,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_product_units UNIQUE (tenant_id, codigo)
);
CREATE TABLE IF NOT EXISTS warehouses (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    localizacao VARCHAR(255),
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_warehouses UNIQUE (tenant_id, codigo)
);
CREATE TABLE IF NOT EXISTS products (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    product_category_id BIGINT,
    product_subcategory_id BIGINT,
    product_brand_id BIGINT,
    product_unit_id BIGINT,
    warehouse_default_id BIGINT,
    codigo VARCHAR(50) NOT NULL,
    nome VARCHAR(150) NOT NULL,
    descricao TEXT,
    tipo VARCHAR(30) NOT NULL DEFAULT 'simples' CHECK (tipo IN ('simples','variavel','kit','servico')),
    iva_percentual NUMERIC(5,2) NOT NULL DEFAULT 17.00 CHECK (iva_percentual >= 0),
    stock_minimo NUMERIC(18,2) NOT NULL DEFAULT 0 CHECK (stock_minimo >= 0),
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_products UNIQUE (tenant_id, codigo),
    CONSTRAINT fk_products_category FOREIGN KEY (product_category_id) REFERENCES product_categories(id) ON DELETE SET NULL,
    CONSTRAINT fk_products_subcategory FOREIGN KEY (product_subcategory_id) REFERENCES product_subcategories(id) ON DELETE SET NULL,
    CONSTRAINT fk_products_brand FOREIGN KEY (product_brand_id) REFERENCES product_brands(id) ON DELETE SET NULL,
    CONSTRAINT fk_products_unit FOREIGN KEY (product_unit_id) REFERENCES product_units(id) ON DELETE SET NULL,
    CONSTRAINT fk_products_warehouse FOREIGN KEY (warehouse_default_id) REFERENCES warehouses(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS product_variants (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id BIGINT NOT NULL,
    codigo VARCHAR(50),
    nome VARCHAR(150) NOT NULL,
    sku VARCHAR(80),
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_product_variants UNIQUE NULLS NOT DISTINCT (product_id, codigo),
    CONSTRAINT fk_product_variants_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS product_prices (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id BIGINT NOT NULL,
    product_variant_id BIGINT,
    tipo_preco VARCHAR(30) NOT NULL DEFAULT 'venda' CHECK (tipo_preco IN ('custo','venda','atacado','promocional')),
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    valor NUMERIC(18,2) NOT NULL CHECK (valor >= 0),
    inicia_em TIMESTAMPTZ,
    fim_em TIMESTAMPTZ,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_product_prices_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    CONSTRAINT fk_product_prices_variant FOREIGN KEY (product_variant_id) REFERENCES product_variants(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS product_barcodes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id BIGINT NOT NULL,
    product_variant_id BIGINT,
    barcode VARCHAR(100) NOT NULL,
    tipo VARCHAR(30),
    principal BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_product_barcodes UNIQUE (barcode),
    CONSTRAINT fk_product_barcodes_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_product_categories_tenant ON product_categories (tenant_id);
CREATE INDEX IF NOT EXISTS idx_product_brands_tenant ON product_brands (tenant_id);
CREATE INDEX IF NOT EXISTS idx_product_units_tenant ON product_units (tenant_id);
CREATE INDEX IF NOT EXISTS idx_warehouses_tenant ON warehouses (tenant_id);
CREATE INDEX IF NOT EXISTS idx_products_tenant ON products (tenant_id);
CREATE INDEX IF NOT EXISTS idx_product_variants_product ON product_variants (product_id);
CREATE INDEX IF NOT EXISTS idx_product_prices_product ON product_prices (product_id);
CREATE INDEX IF NOT EXISTS idx_product_barcodes_product ON product_barcodes (product_id);
