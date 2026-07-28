DELETE FROM auth.permissoes_tipo
 WHERE tipo = 'funcionario' AND modulo = 'assiduidade' AND acao = 'marcar_ponto';
