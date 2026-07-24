-- Reverter permissao auth.pin_admin
DELETE FROM auth.permissoes_tipo WHERE tipo = 'superadmin' AND modulo = 'auth' AND acao = 'pin_admin';
DELETE FROM auth.permissoes_cargo WHERE modulo = 'auth' AND acao = 'pin_admin';
