-- Reverte a granularização das permissões POS.
-- Nota: a reversão remove as ações finas e os cargos-padrão criados. Permissões
-- já atribuídas manualmente pelos administradores não são recuperadas.

SET search_path TO auth, public;

-- Remove os cargos-padrão POS criados pela migração up.
DELETE FROM auth.cargos
 WHERE nome IN ('Operador de Caixa', 'Caixa Sénior', 'Supervisor POS', 'Administrador POS');

-- Remove as novas ações finas de todos os cargos.
DELETE FROM auth.permissoes_cargo
 WHERE modulo = 'pos'
   AND acao IN (
       'operar_pos', 'abrir_sessao', 'fechar_sessao', 'registar_venda',
       'cancelar_venda', 'processar_devolucao', 'movimentar_caixa',
       'aplicar_desconto', 'supervisionar', 'fechar_outra_sessao',
       'gerir_terminais', 'gerir_catalogo', 'gerir_descontos', 'configurar'
   );

-- Nota: não recriamos as permissões antigas (ver/criar/editar/apagar) porque
-- o router Go já não as utiliza. Após o rollback, os cargos com acesso ao POS
-- perdem essas permissões até nova migração ou configuração manual.
