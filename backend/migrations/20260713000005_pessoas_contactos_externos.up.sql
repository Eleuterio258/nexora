-- Migration: extensão do modelo Pessoa central a contactos externos.
-- Ver plano em C:\Users\Eleuterio\.claude\plans\fizzy-napping-sifakis.md.
--
-- Objectivo: assinatura_digital.signatarios, empresas.company_contacts,
-- clientes.customer_contacts e clientes.customers guardam nome/email/
-- telefone/NUIT de pessoas — mas de contrapartes externas (sem auth.users).
-- Puramente aditivo: nenhuma coluna/tabela existente é alterada ou removida.

ALTER TABLE assinatura_digital.signatarios
    ADD COLUMN IF NOT EXISTS pessoa_id BIGINT REFERENCES pessoas.pessoas(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_signatarios_pessoa ON assinatura_digital.signatarios(pessoa_id);

ALTER TABLE empresas.company_contacts
    ADD COLUMN IF NOT EXISTS pessoa_id BIGINT REFERENCES pessoas.pessoas(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_company_contacts_pessoa ON empresas.company_contacts(pessoa_id);

ALTER TABLE clientes.customer_contacts
    ADD COLUMN IF NOT EXISTS pessoa_id BIGINT REFERENCES pessoas.pessoas(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_customer_contacts_pessoa ON clientes.customer_contacts(pessoa_id);

ALTER TABLE clientes.customers
    ADD COLUMN IF NOT EXISTS pessoa_id BIGINT REFERENCES pessoas.pessoas(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_customers_pessoa ON clientes.customers(pessoa_id);

-- ============================================================
-- Backfill
-- ============================================================
DO $$
DECLARE
    r RECORD;
    v_pessoa_id BIGINT;
BEGIN
    -- 1) signatarios: nome é NOT NULL, sempre criar pessoa.
    FOR r IN
        SELECT id, nome FROM assinatura_digital.signatarios WHERE pessoa_id IS NULL
    LOOP
        INSERT INTO pessoas.pessoas (nome_completo) VALUES (r.nome) RETURNING id INTO v_pessoa_id;
        UPDATE assinatura_digital.signatarios SET pessoa_id = v_pessoa_id WHERE id = r.id;
    END LOOP;

    -- 2) company_contacts: nome é opcional, só criar pessoa quando preenchido.
    FOR r IN
        SELECT id, nome FROM empresas.company_contacts
         WHERE pessoa_id IS NULL AND nome IS NOT NULL AND trim(nome) <> ''
    LOOP
        INSERT INTO pessoas.pessoas (nome_completo) VALUES (r.nome) RETURNING id INTO v_pessoa_id;
        UPDATE empresas.company_contacts SET pessoa_id = v_pessoa_id WHERE id = r.id;
    END LOOP;

    -- 3) customer_contacts: nome é NOT NULL, sempre criar pessoa.
    FOR r IN
        SELECT id, nome FROM clientes.customer_contacts WHERE pessoa_id IS NULL
    LOOP
        INSERT INTO pessoas.pessoas (nome_completo) VALUES (r.nome) RETURNING id INTO v_pessoa_id;
        UPDATE clientes.customer_contacts SET pessoa_id = v_pessoa_id WHERE id = r.id;
    END LOOP;

    -- 4) customers: só sem NUIT (heurística "sem indício de empresa"), mesma
    --    regra aplicada no código Go a partir de agora.
    FOR r IN
        SELECT id, nome FROM clientes.customers
         WHERE pessoa_id IS NULL AND (nuit IS NULL OR trim(nuit) = '')
    LOOP
        INSERT INTO pessoas.pessoas (nome_completo) VALUES (r.nome) RETURNING id INTO v_pessoa_id;
        UPDATE clientes.customers SET pessoa_id = v_pessoa_id WHERE id = r.id;
    END LOOP;
END $$;
