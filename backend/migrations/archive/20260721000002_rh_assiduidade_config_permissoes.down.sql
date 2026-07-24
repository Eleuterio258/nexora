DELETE FROM auth.permissoes_diretas WHERE modulo = 'assiduidade' AND acao IN ('ver_configuracao', 'gerir_configuracao');
DELETE FROM auth.permissoes_cargo WHERE modulo = 'assiduidade' AND acao IN ('ver_configuracao', 'gerir_configuracao');
