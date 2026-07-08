<?php
declare (strict_types = 1);

namespace E258Tech\Routing\Pages;

final class ComercialPageRoutes
{
    public static function pages(): array
    {
        return [
            // Dashboard
            'dashboard'                 => ['path' => '/nexora/', 'view' => 'dashboard.php', 'permission' => ''],
            // Recrutamento
            'recrutamento_dashboard'    => ['path' => '/nexora/recrutamento', 'view' => 'recrutamento_dashboard.php', 'permission' => 'recrutamento'],
            'pipeline'                  => ['path' => '/nexora/recrutamento/pipeline', 'view' => 'pipeline.php', 'permission' => 'recrutamento'],
            'relatorios'                => ['path' => '/nexora/recrutamento/relatorios', 'view' => 'relatorios.php', 'permission' => 'recrutamento'],
            'vagas'                     => ['path' => '/nexora/recrutamento/vagas', 'view' => 'vagas.php', 'permission' => 'recrutamento'],
            'vaga_form'                 => ['path' => '/nexora/recrutamento/vagas/form', 'view' => 'vaga_form.php', 'permission' => 'recrutamento'],
            'candidaturas'              => ['path' => '/nexora/recrutamento/candidaturas', 'view' => 'candidaturas.php', 'permission' => 'recrutamento'],
            'candidatura_ver'           => ['path' => '/nexora/recrutamento/candidaturas/ver', 'view' => 'candidatura_ver.php', 'permission' => 'recrutamento'],
            'recrutamento_configuracao' => ['path' => '/nexora/recrutamento/configuracao', 'view' => 'recrutamento_configuracao.php', 'permission' => 'recrutamento'],
            'recrutamento_contactos'    => ['path' => '/nexora/recrutamento/contactos', 'view' => 'recrutamento_contactos.php', 'permission' => 'recrutamento'],
            // CRM
            'leads'                     => ['path' => '/nexora/crm/leads', 'view' => 'leads.php', 'permission' => 'crm'],
            'lead_form'                 => ['path' => '/nexora/crm/leads/form', 'view' => 'lead_form.php', 'permission' => 'crm'],
            'crm_leads_pipeline'        => ['path' => '/nexora/crm/leads/pipeline', 'view' => 'crm_leads_pipeline.php', 'permission' => 'crm'],
            'oportunidades'             => ['path' => '/nexora/crm/oportunidades', 'view' => 'oportunidades.php', 'permission' => 'crm'],
            'oportunidade_form'         => ['path' => '/nexora/crm/oportunidades/form', 'view' => 'oportunidade_form.php', 'permission' => 'crm'],
            'crm_pipeline'              => ['path' => '/nexora/crm/pipeline', 'view' => 'crm_pipeline.php', 'permission' => 'crm'],
            // Clientes
            'clientes'                  => ['path' => '/nexora/clientes', 'view' => 'clientes.php', 'permission' => 'clientes'],
            'cliente_form'              => ['path' => '/nexora/clientes/form', 'view' => 'cliente_form.php', 'permission' => 'clientes'],
            // Faturação
            'faturacao_series'          => ['path' => '/nexora/faturacao/series', 'view' => 'faturacao_series.php', 'permission' => 'faturacao'],
            'orcamentos'                => ['path' => '/nexora/faturacao/orcamentos', 'view' => 'orcamentos.php', 'permission' => 'faturacao'],
            'orcamento_form'            => ['path' => '/nexora/faturacao/orcamentos/form', 'view' => 'orcamento_form.php', 'permission' => 'faturacao'],
            'orcamento_proforma'        => ['path' => '/nexora/faturacao/orcamentos/proforma', 'view' => 'orcamento_proforma.php', 'permission' => 'faturacao'],
            'encomendas'                => ['path' => '/nexora/faturacao/encomendas', 'view' => 'encomendas.php', 'permission' => 'faturacao'],
            'faturas'                   => ['path' => '/nexora/faturacao/faturas', 'view' => 'faturas.php', 'permission' => 'faturacao'],
            'fatura_form'               => ['path' => '/nexora/faturacao/faturas/form', 'view' => 'fatura_form.php', 'permission' => 'faturacao'],
            'fatura_proforma'           => ['path' => '/nexora/faturacao/faturas/proforma', 'view' => 'fatura_proforma.php', 'permission' => 'faturacao'],
            'recibos'                   => ['path' => '/nexora/faturacao/recibos', 'view' => 'recibos.php', 'permission' => 'faturacao'],
            'notas_credito'             => ['path' => '/nexora/faturacao/notas-credito', 'view' => 'notas_credito.php', 'permission' => 'faturacao'],
            // POS
            'pos'                       => ['path' => '/nexora/pos', 'view' => 'pos.php', 'permission' => 'pos'],
            'pos_dashboard'             => ['path' => '/nexora/pos/dashboard', 'view' => 'pos_dashboard.php', 'permission' => 'pos'],
            'pos_vendas'                => ['path' => '/nexora/pos/vendas', 'view' => 'pos_vendas.php', 'permission' => 'pos'],
            'pos_venda_ver'             => ['path' => '/nexora/pos/vendas/ver', 'view' => 'pos_venda_ver.php', 'permission' => 'pos'],
            'pos_terminais'             => ['path' => '/nexora/pos/terminais', 'view' => 'pos_terminais.php', 'permission' => 'pos'],
            'pos_catalogo'              => ['path' => '/nexora/pos/catalogo', 'view' => 'pos_catalogo.php', 'permission' => 'pos'],
            'pos_relatorios'            => ['path' => '/nexora/pos/relatorios', 'view' => 'pos_relatorios.php', 'permission' => 'pos'],
            'pos_devolucoes'            => ['path' => '/nexora/pos/devolucoes', 'view' => 'pos_devolucoes.php', 'permission' => 'pos'],
            // Produtos & Stock
            'produtos'                  => ['path' => '/nexora/produtos', 'view' => 'produtos.php', 'permission' => 'stock'],
            'produto_form'              => ['path' => '/nexora/produtos/form', 'view' => 'produto_form.php', 'permission' => 'stock'],
            'produto_categorias'        => ['path' => '/nexora/produtos/categorias', 'view' => 'produto_categorias.php', 'permission' => 'stock'],
            'stock'                     => ['path' => '/nexora/stock', 'view' => 'stock.php', 'permission' => 'stock'],
            // Compras
            'compras'                   => ['path' => '/nexora/compras', 'view' => 'compras.php', 'permission' => 'compras'],
        ];
    }
}
