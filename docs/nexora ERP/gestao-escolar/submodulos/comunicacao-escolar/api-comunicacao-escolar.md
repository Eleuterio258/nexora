# API — Submodulo Comunicacao Escolar

## Mensagens e Comunicados

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/escolar/messages | Listar mensagens (filtros: publico_alvo, status, class_id) |
| POST | /api/escolar/messages | Criar comunicado (rascunho) |
| GET | /api/escolar/messages/{id} | Obter comunicado |
| PUT | /api/escolar/messages/{id} | Editar comunicado em rascunho |
| POST | /api/escolar/messages/{id}/publicar | Publicar comunicado (envia notificacoes) |
| POST | /api/escolar/messages/{id}/arquivar | Arquivar comunicado publicado |
| DELETE | /api/escolar/messages/{id} | Eliminar rascunho |
