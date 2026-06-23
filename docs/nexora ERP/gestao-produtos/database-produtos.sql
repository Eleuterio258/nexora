-- Modulo de Gestao de Produtos para PostgreSQL

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
    descricao TEXT,
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
    stock_minimo_padrao NUMERIC(18,2) NOT NULL DEFAULT 0 CHECK (stock_minimo_padrao >= 0),
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
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
    tipo VARCHAR(30) NOT NULL DEFAULT 'simples' CHECK (tipo IN ('simples', 'variavel', 'kit', 'servico')),
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

CREATE TABLE IF NOT EXISTS product_images (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id BIGINT NOT NULL,
    ficheiro_url TEXT NOT NULL,
    principal BOOLEAN NOT NULL DEFAULT FALSE,
    ordem INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_product_images_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS product_prices (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id BIGINT NOT NULL,
    product_variant_id BIGINT,
    tipo_preco VARCHAR(30) NOT NULL DEFAULT 'venda' CHECK (tipo_preco IN ('custo', 'venda', 'atacado', 'promocional')),
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    valor NUMERIC(18,2) NOT NULL CHECK (valor >= 0),
    inicia_em TIMESTAMPTZ,
    fim_em TIMESTAMPTZ,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_product_prices_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    CONSTRAINT fk_product_prices_variant FOREIGN KEY (product_variant_id) REFERENCES product_variants(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS product_discounts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id BIGINT NOT NULL,
    product_variant_id BIGINT,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('percentual', 'valor_fixo')),
    valor NUMERIC(18,2) NOT NULL CHECK (valor >= 0),
    motivo VARCHAR(150),
    inicia_em TIMESTAMPTZ,
    fim_em TIMESTAMPTZ,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_product_discounts_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    CONSTRAINT fk_product_discounts_variant FOREIGN KEY (product_variant_id) REFERENCES product_variants(id) ON DELETE CASCADE
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
    CONSTRAINT fk_product_barcodes_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    CONSTRAINT fk_product_barcodes_variant FOREIGN KEY (product_variant_id) REFERENCES product_variants(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS product_tags (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(50),
    nome VARCHAR(100) NOT NULL,
    cor VARCHAR(20),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_product_tags UNIQUE NULLS NOT DISTINCT (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS product_tag_links (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id BIGINT NOT NULL,
    product_tag_id BIGINT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_product_tag_links UNIQUE (product_id, product_tag_id),
    CONSTRAINT fk_product_tag_links_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    CONSTRAINT fk_product_tag_links_tag FOREIGN KEY (product_tag_id) REFERENCES product_tags(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS product_attributes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(50),
    nome VARCHAR(100) NOT NULL,
    tipo VARCHAR(30) NOT NULL DEFAULT 'texto' CHECK (tipo IN ('texto', 'numero', 'lista', 'booleano', 'cor')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_product_attributes UNIQUE NULLS NOT DISTINCT (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS product_attribute_values (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_attribute_id BIGINT NOT NULL,
    product_id BIGINT,
    product_variant_id BIGINT,
    valor VARCHAR(150) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_product_attribute_values_attribute FOREIGN KEY (product_attribute_id) REFERENCES product_attributes(id) ON DELETE CASCADE,
    CONSTRAINT fk_product_attribute_values_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    CONSTRAINT fk_product_attribute_values_variant FOREIGN KEY (product_variant_id) REFERENCES product_variants(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS product_kits (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id BIGINT NOT NULL,
    codigo VARCHAR(50),
    nome VARCHAR(150) NOT NULL,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_product_kits UNIQUE NULLS NOT DISTINCT (product_id, codigo),
    CONSTRAINT fk_product_kits_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS product_kit_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_kit_id BIGINT NOT NULL,
    item_product_id BIGINT NOT NULL,
    item_variant_id BIGINT,
    quantidade NUMERIC(18,2) NOT NULL CHECK (quantidade > 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_product_kit_items_kit FOREIGN KEY (product_kit_id) REFERENCES product_kits(id) ON DELETE CASCADE,
    CONSTRAINT fk_product_kit_items_product FOREIGN KEY (item_product_id) REFERENCES products(id) ON DELETE RESTRICT,
    CONSTRAINT fk_product_kit_items_variant FOREIGN KEY (item_variant_id) REFERENCES product_variants(id) ON DELETE RESTRICT
);

-- Nota: niveis de stock sao geridos exclusivamente pelo modulo gestao-stock (tabela stock_items).

CREATE INDEX IF NOT EXISTS idx_product_categories_tenant_id ON product_categories (tenant_id);
CREATE INDEX IF NOT EXISTS idx_product_subcategories_category_id ON product_subcategories (product_category_id);
CREATE INDEX IF NOT EXISTS idx_product_brands_tenant_id ON product_brands (tenant_id);
CREATE INDEX IF NOT EXISTS idx_product_units_tenant_id ON product_units (tenant_id);
CREATE INDEX IF NOT EXISTS idx_warehouses_tenant_id ON warehouses (tenant_id);
CREATE INDEX IF NOT EXISTS idx_products_tenant_id ON products (tenant_id);
CREATE INDEX IF NOT EXISTS idx_product_variants_product_id ON product_variants (product_id);
CREATE INDEX IF NOT EXISTS idx_product_images_product_id ON product_images (product_id);
CREATE INDEX IF NOT EXISTS idx_product_prices_product_id ON product_prices (product_id);
CREATE INDEX IF NOT EXISTS idx_product_discounts_product_id ON product_discounts (product_id);
CREATE INDEX IF NOT EXISTS idx_product_barcodes_product_id ON product_barcodes (product_id);
CREATE INDEX IF NOT EXISTS idx_product_tag_links_product_id ON product_tag_links (product_id);
CREATE INDEX IF NOT EXISTS idx_product_attribute_values_product_id ON product_attribute_values (product_id);
CREATE INDEX IF NOT EXISTS idx_product_kits_product_id ON product_kits (product_id);
CREATE INDEX IF NOT EXISTS idx_product_kit_items_kit_id ON product_kit_items (product_kit_id);
