-- Remove o código 'pin' do catálogo de métodos de marcação.
--
-- Só apaga as linhas que nenhum evento referencia: rh.eventos_assiduidade
-- .metodo_id tem FK para rh.metodos_marcacao(id), portanto apagar um método já
-- usado rebentaria a migração. Se houver eventos por PIN registados, a linha
-- fica — desfazer a migração não deve destruir histórico de assiduidade.

DELETE FROM rh.metodos_marcacao m
 WHERE m.codigo = 'pin'
   AND NOT EXISTS (
       SELECT 1 FROM rh.eventos_assiduidade e WHERE e.metodo_id = m.id
   );
