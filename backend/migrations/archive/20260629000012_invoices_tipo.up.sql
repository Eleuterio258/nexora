SET search_path TO faturacao, public;

ALTER TABLE invoices ADD COLUMN tipo VARCHAR(20) NOT NULL DEFAULT 'normal'
    CHECK (tipo IN ('normal', 'proforma'));
