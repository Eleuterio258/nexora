-- Sem reversão: o backfill preencheu campos vazios com dados que já existiam
-- noutra tabela do mesmo tenant. Apagá-los não repõe estado nenhum — só volta
-- a partir a deduplicação por documento. Se for mesmo preciso reverter, é caso
-- a caso e à mão.
SELECT 1;
