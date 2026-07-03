<?php
declare(strict_types=1);

namespace E258Tech\Routing\Pages;

final class FinanceiroPageRoutes
{
    public static function pages(): array
    {
        return [
            // Financeiro
            'tesouraria'         => ['path' => '/nexora/tesouraria',        'view' => 'tesouraria.php',         'permission' => 'tesouraria'],
            'logistica'          => ['path' => '/nexora/logistica',         'view' => 'logistica.php',          'permission' => 'logistica'],
            'financeiro'         => ['path' => '/nexora/financeiro',        'view' => 'financeiro.php',         'permission' => 'financeiro'],
            'multi_moeda'        => ['path' => '/nexora/multi-moeda',       'view' => 'multi_moeda.php',        'permission' => 'multi-moeda'],
            'centros_custo'      => ['path' => '/nexora/centros-custo',     'view' => 'centros_custo.php',      'permission' => 'centros-custo'],
            'impostos_avancados' => ['path' => '/nexora/impostos/avancados', 'view' => 'impostos_avancados.php', 'permission' => 'impostos'],
            // Contabilidade
            'contab_plano_contas' => ['path' => '/nexora/contabilidade/plano-contas',  'view' => 'contab_plano_contas.php',  'permission' => 'contabilidade'],
            'contab_periodos'     => ['path' => '/nexora/contabilidade/periodos',      'view' => 'contab_periodos.php',      'permission' => 'contabilidade'],
            'contab_lancamentos'  => ['path' => '/nexora/contabilidade/lancamentos',   'view' => 'contab_lancamentos.php',   'permission' => 'contabilidade'],
            'contab_lancamento'   => ['path' => '/nexora/contabilidade/lancamento',    'view' => 'contab_lancamento.php',    'permission' => 'contabilidade'],
            'contab_impostos'     => ['path' => '/nexora/contabilidade/impostos',      'view' => 'contab_impostos.php',      'permission' => 'contabilidade'],
            'contab_ativos_fixos' => ['path' => '/nexora/contabilidade/ativos-fixos',  'view' => 'contab_ativos_fixos.php',  'permission' => 'contabilidade'],
            'contab_amortizacoes' => ['path' => '/nexora/contabilidade/amortizacoes',  'view' => 'contab_amortizacoes.php',  'permission' => 'contabilidade'],
            'contab_orcamentos'   => ['path' => '/nexora/contabilidade/orcamentos',    'view' => 'contab_orcamentos.php',    'permission' => 'contabilidade'],
            'contab_encerramento' => ['path' => '/nexora/contabilidade/encerramento',  'view' => 'contab_encerramento.php',  'permission' => 'contabilidade'],
            'contab_relatorios'   => ['path' => '/nexora/contabilidade/relatorios',    'view' => 'contab_relatorios.php',    'permission' => 'contabilidade'],
        ];
    }
}
