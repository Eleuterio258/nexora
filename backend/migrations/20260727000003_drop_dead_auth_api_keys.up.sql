-- auth.api_keys nunca foi validada por nenhum middleware (confirmado por
-- grep exaustivo em internal/ — só apikeys.go, o próprio CRUD, referenciava
-- key_hash) e não tinha nenhuma UI a consumi-la (confirmado em frontend/).
-- Substituída conceptualmente por client_credentials no Authorization Server
-- OAuth2 (ver 20260727000001_oauth2_authorization_server), para o caso de
-- uso que originalmente pretendia servir (integrações servidor-a-servidor).
DROP TABLE IF EXISTS auth.api_keys;
