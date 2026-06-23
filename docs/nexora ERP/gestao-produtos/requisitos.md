# Requisitos — Modulo Gestao de Produtos

## Requisitos Funcionais

### RF01 — Catalogo de Produtos
O sistema deve permitir criar produtos com codigo unico, nome, descricao, tipo (simples, variavel, kit, servico) e taxa de IVA.

### RF02 — Categorias e Subcategorias
O sistema deve suportar uma hierarquia de duas niveis (categoria e subcategoria) para classificacao de produtos.

### RF03 — Marcas
O sistema deve permitir gerir marcas e associa-las a produtos.

### RF04 — Unidades de Medida
O sistema deve gerir unidades de medida com codigo, nome, simbolo e numero de casas decimais.

### RF05 — Variantes de Produto
O sistema deve suportar variantes por produto (ex: tamanho, cor), cada uma com SKU e codigo proprio.

### RF06 — Precos
O sistema deve suportar multiplos tipos de preco por produto/variante (custo, venda, atacado, promocional), com moeda e vigencia temporal.

### RF07 — Descontos de Produto
O sistema deve suportar descontos por produto ou variante (percentual ou valor fixo) com vigencia temporal.

### RF08 — Codigos de Barras
O sistema deve permitir registar multiplos codigos de barras (EAN, UPC) por produto ou variante.

### RF09 — Imagens
O sistema deve suportar multiplas imagens por produto, com indicacao da imagem principal e ordem de exibicao.

### RF10 — Tags de Produto
O sistema deve suportar a criacao de tags e a sua atribuicao a produtos para classificacao e pesquisa.

### RF11 — Atributos Personalizados
O sistema deve permitir criar atributos customizados (texto, numero, lista, cor) e associar valores a produtos e variantes.

### RF12 — Kits e Compostos
O sistema deve suportar a definicao de kits, compostos por varios produtos/variantes com quantidades definidas.

### RF13 — Armazens
O sistema deve gerir armazens com codigo, nome, localizacao e stock minimo padrao.

### RF14 — Stock Minimo por Produto
O sistema deve permitir definir um stock minimo por produto, usado para alertas de reposicao.

---

## Requisitos Nao Funcionais

### RNF01 — Unicidade de Codigo
O codigo do produto deve ser unico por tenant. O codigo de barras deve ser unico globalmente na tabela.

### RNF02 — Desempenho de Pesquisa
A pesquisa de produtos por codigo, nome ou codigo de barras deve responder em menos de 300ms.

### RNF03 — Integridade Referencial
Nao deve ser possivel eliminar uma unidade de medida, categoria ou marca que esteja em uso por algum produto.

### RNF04 — Preco Activo
O sistema deve garantir que apenas um preco do mesmo tipo esteja activo por produto/variante em cada momento.

### RNF05 — Auditoria
Alteracoes a precos, taxas de IVA e estado de produtos devem gerar registos de auditoria.
