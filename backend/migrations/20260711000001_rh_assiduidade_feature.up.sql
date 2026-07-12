-- Migration: feature rh.assiduidade no catálogo (Fase 2 da integração FaceClock)
--
-- Permite a cada tenant configurar quais métodos de assiduidade (facial,
-- fingerprint, qr_code, nfc, geolocation, etc.) estão activos, via o mecanismo
-- já existente de feature flags (saas.feature_catalog + tenant_feature_flags).
-- Ver assiduidade_system_backend/CONTRATO-INTEGRACAO-ERP.md.

INSERT INTO saas.feature_catalog (key, modulo, nome, descricao, ativo_por_defeito, configuravel)
VALUES (
  'rh.assiduidade',
  'recursos-humanos',
  'Assiduidade / Controlo de Ponto',
  'Registo de presença via dispositivos/serviços externos (ex.: FaceClock) com métodos configuráveis por tenant.',
  true,
  true
)
ON CONFLICT (key) DO NOTHING;
