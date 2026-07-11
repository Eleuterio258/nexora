DELETE FROM auth.permissoes_tipo
WHERE modulo = 'hardware'
  AND acao IN ('ver_dispositivos', 'gerir_dispositivos', 'ver_eventos');
