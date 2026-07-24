-- Assinatura digital — Fase 0 de estabilização:
--   * separa "aceite eletronicamente" (confirmação externa via webhook, sem
--     evidência PAdES gerada/verificada localmente) de "assinado"
--     (criptograficamente, com versão em versoes_assinadas produzida por
--     este sistema);
--   * reserva os estados "assinatura_em_processamento" e "assinatura_falhou"
--     para os fluxos assíncronos de provider corrigidos na Fase 3.
-- Nenhum destes novos valores é ainda produzido para "assinatura_falhou" /
-- "assinatura_em_processamento" pelo código actual — a constraint é alargada
-- de forma aditiva e retrocompatível para não bloquear a Fase 3.

ALTER TABLE assinatura_digital.documentos
    DROP CONSTRAINT IF EXISTS documentos_status_check;
ALTER TABLE assinatura_digital.documentos
    ADD CONSTRAINT documentos_status_check
    CHECK (status IN (
        'rascunho',
        'pendente',
        'parcialmente_assinado',
        'aceite_eletronicamente',
        'assinatura_em_processamento',
        'assinado',
        'assinatura_falhou',
        'cancelado',
        'expirado'
    ));

ALTER TABLE assinatura_digital.signatarios
    DROP CONSTRAINT IF EXISTS signatarios_status_check;
ALTER TABLE assinatura_digital.signatarios
    ADD CONSTRAINT signatarios_status_check
    CHECK (status IN (
        'pendente',
        'convidado',
        'aceite_eletronicamente',
        'assinatura_em_processamento',
        'assinado',
        'assinatura_falhou',
        'recusado'
    ));
