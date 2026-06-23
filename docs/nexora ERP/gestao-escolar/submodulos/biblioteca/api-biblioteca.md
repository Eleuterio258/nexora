# API — Submodulo Biblioteca

## Catalogo de Livros

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/escolar/library/books | Listar livros (filtros: categoria, estado, disponivel) |
| POST | /api/escolar/library/books | Cadastrar livro no catalogo |
| GET | /api/escolar/library/books/{id} | Obter livro com quantidade disponivel |
| PUT | /api/escolar/library/books/{id} | Actualizar dados do livro |
| POST | /api/escolar/library/books/{id}/desactivar | Desactivar livro do catalogo |

---

## Emprestimos

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/escolar/library/loans | Listar emprestimos (filtros: status, student_id, teacher_id) |
| POST | /api/escolar/library/loans | Registar emprestimo (aluno ou professor) |
| GET | /api/escolar/library/loans/{id} | Obter emprestimo com datas e estado |
| POST | /api/escolar/library/loans/{id}/devolver | Confirmar devolucao do livro |
| POST | /api/escolar/library/loans/{id}/perda | Registar perda ou extravio do livro |
| GET | /api/escolar/library/loans/atrasados | Listar emprestimos com devolucao em atraso |
