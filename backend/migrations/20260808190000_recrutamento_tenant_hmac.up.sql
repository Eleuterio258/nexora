-- Segredo HMAC por tenant para identificação assinada nos endpoints públicos
-- de recrutamento (GET /vagas, /vagas/{id}, /candidaturas espontâneas,
-- /contacto), usados por sites fora da infra do Nexora que não podem confiar
-- no Host/X-Forwarded-Host mediado pelo Traefik (esse cabeçalho é forjável
-- por qualquer chamador directo da API pública).
ALTER TABLE saas.tenants
    ADD COLUMN IF NOT EXISTS recrutamento_api_secret text;
