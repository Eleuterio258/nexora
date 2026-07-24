DELETE FROM auth.permissoes_diretas WHERE modulo = 'assiduidade' AND acao = 'aprovar_correcao';
DELETE FROM auth.permissoes_cargo WHERE modulo = 'assiduidade' AND acao = 'aprovar_correcao';
DELETE FROM auth.permissoes_tipo WHERE tipo = 'funcionario' AND modulo = 'assiduidade' AND acao = 'corrigir_ponto';
