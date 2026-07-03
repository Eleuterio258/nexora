<?php
declare(strict_types=1);

namespace E258Tech\Routing\Api;

final class ComercialApiRoutes
{
    public static function endpoints(): array
    {
        return [
            // ── Faturação ─────────────────────────────────────────────────────────
            'serie_save'            => ['module' => 'faturacao', 'action' => 'configurar_series'],
            'serie_estado'          => ['module' => 'faturacao', 'action' => 'configurar_series'],
            'orcamento_save'        => ['module' => 'faturacao', 'action' => 'emitir_orcamentos'],
            'orcamento_item_save'   => ['module' => 'faturacao', 'action' => 'emitir_orcamentos'],
            'orcamento_item_delete' => ['module' => 'faturacao', 'action' => 'emitir_orcamentos'],
            'orcamento_estado'      => ['module' => 'faturacao', 'action' => 'emitir_orcamentos'],
            'encomenda_save'        => ['module' => 'faturacao', 'action' => 'emitir_encomendas'],
            'encomenda_estado'      => ['module' => 'faturacao', 'action' => 'emitir_encomendas'],
            'fatura_save'           => ['module' => 'faturacao', 'action' => 'emitir_faturas'],
            'fatura_item_save'      => ['module' => 'faturacao', 'action' => 'emitir_faturas'],
            'fatura_estado'         => ['module' => 'faturacao', 'action' => 'emitir_faturas'],
            'recibo_save'           => ['module' => 'faturacao', 'action' => 'emitir_faturas'],
            'nota_credito_save'     => ['module' => 'faturacao', 'action' => 'emitir_notas_credito'],

            // ── POS ───────────────────────────────────────────────────────────────
            'pos_sessao_abrir'    => ['module' => 'pos', 'action' => 'operar_pos'],
            'pos_sessao_fechar'   => ['module' => 'pos', 'action' => 'operar_pos'],
            'pos_venda_save'      => ['module' => 'pos', 'action' => 'operar_pos'],
            'pos_venda_cancelar'  => ['module' => 'pos', 'action' => 'operar_pos'],
            'pos_produtos_buscar' => ['module' => 'pos', 'action' => 'operar_pos',    'method' => 'GET'],
            'pos_terminal_save'   => ['module' => 'pos', 'action' => 'gerir_terminais'],
            'pos_catalogo_save'   => ['module' => 'pos', 'action' => 'gerir_catalogo'],
            'pos_catalogo_remove' => ['module' => 'pos', 'action' => 'gerir_catalogo'],

            // ── Stock & Produtos ──────────────────────────────────────────────────
            'produto_save'              => ['module' => 'stock', 'action' => 'gerir_produtos'],
            'produto_preco_save'        => ['module' => 'stock', 'action' => 'gerir_produtos'],
            'produto_variante_save'     => ['module' => 'stock', 'action' => 'gerir_produtos'],
            'produto_unidade_save'      => ['module' => 'stock', 'action' => 'gerir_produtos'],
            'produto_categoria_save'    => ['module' => 'stock', 'action' => 'gerir_categorias'],
            'produto_categoria_remover' => ['module' => 'stock', 'action' => 'gerir_categorias'],
            'produto_marca_save'        => ['module' => 'stock', 'action' => 'gerir_categorias'],
            'stock_operacao'            => ['module' => 'stock', 'action' => 'gerir_movimentos'],

            // ── Compras ───────────────────────────────────────────────────────────
            'compra_documento_save' => ['module' => 'compras', 'action' => 'criar_pedidos'],
            'compra_item_save'      => ['module' => 'compras', 'action' => 'criar_pedidos'],
        ];
    }
}
