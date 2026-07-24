-- Liga um contrato de RH ao documento de assinatura digital criado a partir
-- dele (ver internal/modules/recursos-humanos/handlers, endpoint
-- enviar-para-assinatura).

ALTER TABLE rh.contratos
    ADD COLUMN IF NOT EXISTS assinatura_documento_id BIGINT
        REFERENCES assinatura_digital.documentos(id);
