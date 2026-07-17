-- Reverte a extensão do modelo Pessoa central a contactos externos.

ALTER TABLE clientes.customers DROP COLUMN IF EXISTS pessoa_id;
ALTER TABLE clientes.customer_contacts DROP COLUMN IF EXISTS pessoa_id;
ALTER TABLE empresas.company_contacts DROP COLUMN IF EXISTS pessoa_id;
ALTER TABLE assinatura_digital.signatarios DROP COLUMN IF EXISTS pessoa_id;
