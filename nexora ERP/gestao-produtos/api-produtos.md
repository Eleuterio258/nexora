# API — Modulo Gestao de Produtos

## Categorias

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/produtos/categorias | Listar categorias (suporta hierarquia via parent_id) |
| POST | /api/produtos/categorias | Criar categoria |
| GET | /api/produtos/categorias/{id} | Obter categoria |
| PUT | /api/produtos/categorias/{id} | Actualizar categoria |
| DELETE | /api/produtos/categorias/{id} | Remover categoria (sem produtos associados) |

---

## Marcas

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/produtos/marcas | Listar marcas |
| POST | /api/produtos/marcas | Criar marca |
| GET | /api/produtos/marcas/{id} | Obter marca |
| PUT | /api/produtos/marcas/{id} | Actualizar marca |

---

## Unidades de Medida

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/produtos/unidades | Listar unidades de medida |
| POST | /api/produtos/unidades | Criar unidade |
| PUT | /api/produtos/unidades/{id} | Actualizar unidade |

---

## Atributos

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/produtos/atributos | Listar atributos (ex: Cor, Tamanho) |
| POST | /api/produtos/atributos | Criar atributo |
| PUT | /api/produtos/atributos/{id} | Actualizar atributo |

---

## Tags

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/produtos/tags | Listar tags |
| POST | /api/produtos/tags | Criar tag |

---

## Produtos

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/produtos | Listar produtos (filtros: categoria_id, marca_id, tipo, status, search) |
| POST | /api/produtos | Criar produto |
| GET | /api/produtos/{id} | Obter produto com variantes, precos e stock |
| PUT | /api/produtos/{id} | Actualizar produto |
| POST | /api/produtos/{id}/activar | Activar produto |
| POST | /api/produtos/{id}/desactivar | Desactivar produto |

---

## Variantes

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/produtos/{id}/variantes | Listar variantes do produto |
| POST | /api/produtos/{id}/variantes | Criar variante (combinacao de atributos) |
| PUT | /api/produtos/{id}/variantes/{var_id} | Actualizar variante |
| DELETE | /api/produtos/{id}/variantes/{var_id} | Remover variante |

---

## Imagens

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/produtos/{id}/imagens | Listar imagens |
| POST | /api/produtos/{id}/imagens | Adicionar imagem |
| PUT | /api/produtos/{id}/imagens/{img_id} | Definir como principal |
| DELETE | /api/produtos/{id}/imagens/{img_id} | Remover imagem |

---

## Precos

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/produtos/{id}/precos | Listar precos por lista de preco |
| POST | /api/produtos/{id}/precos | Definir preco numa lista |
| PUT | /api/produtos/{id}/precos/{preco_id} | Actualizar preco |

---

## Descontos

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/produtos/{id}/descontos | Listar descontos do produto |
| POST | /api/produtos/{id}/descontos | Criar desconto (percentual ou valor fixo) |
| PUT | /api/produtos/{id}/descontos/{desc_id} | Actualizar desconto |
| DELETE | /api/produtos/{id}/descontos/{desc_id} | Remover desconto |

---

## Codigos de Barras

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/produtos/{id}/codigos-barras | Listar codigos de barras |
| POST | /api/produtos/{id}/codigos-barras | Adicionar codigo de barras |
| DELETE | /api/produtos/{id}/codigos-barras/{cb_id} | Remover codigo de barras |

---

## Composicao (Kits / Servicos Compostos)

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/produtos/{id}/componentes | Listar componentes do produto composto |
| POST | /api/produtos/{id}/componentes | Adicionar componente |
| PUT | /api/produtos/{id}/componentes/{comp_id} | Actualizar quantidade do componente |
| DELETE | /api/produtos/{id}/componentes/{comp_id} | Remover componente |

---

## Tags do Produto

| Metodo | Rota | Descricao |
| --- | --- | --- |
| POST | /api/produtos/{id}/tags | Associar tag ao produto |
| DELETE | /api/produtos/{id}/tags/{tag_id} | Remover tag do produto |

---

## Stock (Consulta)

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/produtos/{id}/stock | Posicao de stock por armazem |
| GET | /api/produtos/{id}/stock/alertas | Alertas de stock minimo por armazem |

---

## Relatorios

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/produtos/reports/mais-vendidos | Produtos com maior volume de vendas |
| GET | /api/produtos/reports/sem-movimentos | Produtos sem movimentos nos ultimos N dias |
| GET | /api/produtos/reports/stock-critico | Produtos abaixo do stock minimo |
| GET | /api/produtos/reports/margem | Margem por produto (preco venda vs custo medio) |
