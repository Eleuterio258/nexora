-- 108_audit_convention.up.sql
-- Documenta a convenção de uso dos dois sistemas de auditoria.
--
-- CONVENÇÃO:
--   auditoria.audit_logs   → log operacional de rotina (CRUD, quem fez o quê, quando)
--                            Usado pelo middleware AuditModule do Go backend.
--   auditoria.audit_events → registo de eventos com valor legal/compliance (cadeia de hash)
--                            Usar para: fecho de período, emissão de facturas, aprovações RH,
--                            alterações de permissões, alterações de planos de assinatura.
--
-- Não se elimina nenhum dos sistemas; ambos coexistem com propósitos distintos.

COMMENT ON TABLE auditoria.audit_logs IS
    'Log operacional de rotina: quem fez o quê e quando. '
    'Preenchido automaticamente pelo middleware AuditModule (Go). '
    'Não tem garantia de imutabilidade — para eventos legais usar audit_events.';

COMMENT ON TABLE auditoria.audit_events IS
    'Registo de eventos com valor legal/compliance, com cadeia de hash (event_hash + previous_hash). '
    'Usar para eventos irreversíveis: fecho de período contabilístico, emissão de facturas, '
    'aprovações RH, alterações de permissões, renovação de assinaturas. '
    'Não substituir audit_logs para operações rotineiras — manter separação de propósitos.';

-- View de conveniência para consultar os dois sistemas em conjunto
CREATE OR REPLACE VIEW auditoria.v_audit_unified AS
SELECT
    'log'              AS sistema,
    id,
    tenant_id,
    user_id,
    NULL::bigint       AS actor_user_id,
    modulo,
    acao               AS action,
    entidade           AS entity_type,
    entidade_id::text  AS entity_id,
    NULL::text         AS event_hash,
    created_at
  FROM auditoria.audit_logs
UNION ALL
SELECT
    'event'            AS sistema,
    id,
    tenant_id,
    NULL::bigint       AS user_id,
    actor_user_id,
    module_name        AS modulo,
    action,
    entity_type,
    entity_id::text,
    event_hash,
    created_at
  FROM auditoria.audit_events;

COMMENT ON VIEW auditoria.v_audit_unified IS
    'Vista unificada dos dois sistemas de auditoria. sistema=''log'' para audit_logs, ''event'' para audit_events.';
