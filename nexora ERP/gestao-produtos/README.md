# Modulo de Gestao de Produtos

## Objetivo

Este modulo concentra o cadastro completo de produtos e a sua classificacao comercial, fiscal e estrutural.

## Funcionalidades

- categorias e subcategorias
- marcas
- unidades de medida
- cadastro de produtos
- variantes de produto
- imagens de produto
- precos por produto
- descontos por produto
- codigos de barras
- etiquetas de produto
- atributos e valores de atributos
- kits de produtos
- integracao com stock e faturacao

## Arquivos

- `database-produtos.sql`: estrutura PostgreSQL do modulo
- `views-produtos.sql`: views de consulta de negocio
- `api-produtos.md`: endpoints do modulo

## Entidades principais

- product_categories
- product_subcategories
- product_brands
- product_units
- products
- product_variants
- product_images
- product_prices
- product_discounts
- product_barcodes
- product_tags
- product_attributes
- product_attribute_values
- product_kits
- product_kit_items
- product_stock
- warehouses
