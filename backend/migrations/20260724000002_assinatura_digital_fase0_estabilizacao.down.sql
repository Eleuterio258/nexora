-- Reverte a Fase 0 de estabilização. Antes de restringir a constraint,
-- converte defensivamente qualquer linha que já use os estados novos para o
-- equivalente mais próximo suportado pela constraint anterior — caso
-- contrário o ALTER TABLE falharia com dados incompatíveis.
UPDATE assinatura_digital.documentos
    SET status = 'assinado'
    WHERE status IN ('aceite_eletronicamente', 'assinatura_em_processamento', 'assinatura_falhou');

UPDATE assinatura_digital.signatarios
    SET status = 'assinado'
    WHERE status IN ('aceite_eletronicamente', 'assinatura_em_processamento', 'assinatura_falhou');

ALTER TABLE assinatura_digital.signatarios
    DROP CONSTRAINT IF EXISTS signatarios_status_check;
ALTER TABLE assinatura_digital.signatarios
    ADD CONSTRAINT signatarios_status_check
    CHECK (status IN ('pendente', 'convidado', 'assinado', 'recusado'));

ALTER TABLE assinatura_digital.documentos
    DROP CONSTRAINT IF EXISTS documentos_status_check;
ALTER TABLE assinatura_digital.documentos
    ADD CONSTRAINT documentos_status_check
    CHECK (status IN (
        'rascunho',
        'pendente',
        'parcialmente_assinado',
        'assinado',
        'cancelado',
        'expirado'
    ));
