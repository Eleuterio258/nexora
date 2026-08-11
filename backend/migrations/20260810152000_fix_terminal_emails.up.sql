-- Corrige emails sintéticos de terminais antigos para evitar colisão entre tenants.
-- Apenas actualiza registos ainda no formato antigo; emails já no formato novo
-- não são alterados.

UPDATE auth.users u
SET email = 'terminal.' || pt.tenant_id || '.' || LOWER(pt.codigo) || '@nexora.local'
FROM pos.pos_terminals pt
WHERE pt.user_id = u.id
  AND u.email LIKE '%@terminal.internal';
