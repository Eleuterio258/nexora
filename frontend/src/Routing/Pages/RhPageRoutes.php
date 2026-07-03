<?php
declare(strict_types=1);

namespace E258Tech\Routing\Pages;

final class RhPageRoutes
{
    public static function pages(): array
    {
        return [
            // RH
            'rh_funcionarios'           => ['path' => '/nexora/rh/funcionarios',           'view' => 'rh_funcionarios.php',           'permission' => 'recursos-humanos'],
            'rh_funcionario'            => ['path' => '/nexora/rh/funcionarios/ver',       'view' => 'rh_funcionario.php',            'permission' => 'recursos-humanos'],
            'rh_ausencias'              => ['path' => '/nexora/rh/ausencias',              'view' => 'rh_ausencias.php',              'permission' => 'recursos-humanos'],
            'rh_organograma'            => ['path' => '/nexora/rh/organograma',            'view' => 'rh_organograma.php',            'permission' => 'recursos-humanos'],
            'rh_folha_pagamento'        => ['path' => '/nexora/rh/folha-pagamento',        'view' => 'rh_folha_pagamento.php',        'permission' => 'recursos-humanos'],
            'rh_recibo_vencimento'      => ['path' => '/nexora/rh/recibo-vencimento',      'view' => 'rh_recibo_vencimento.php',      'permission' => 'recursos-humanos'],
            'meus_recibos'              => ['path' => '/nexora/meus-recibos',              'view' => 'meus_recibos.php',              'permission' => ''],
            'meu_recibo'                => ['path' => '/nexora/meu-recibo',                'view' => 'meu_recibo.php',                'permission' => ''],
            'rh_relatorios'             => ['path' => '/nexora/rh/relatorios',             'view' => 'rh_relatorios.php',             'permission' => 'recursos-humanos'],
            'rh_unidades'               => ['path' => '/nexora/rh/unidades',               'view' => 'rh_unidades.php',               'permission' => 'recursos-humanos'],
            'rh_periodos'               => ['path' => '/nexora/rh/periodos-avaliacao',     'view' => 'rh_periodos.php',               'permission' => 'recursos-humanos'],
            'rh_cargos'                 => ['path' => '/nexora/rh/cargos',                 'view' => 'rh_cargos.php',                 'permission' => 'recursos-humanos'],
            'rh_horarios'               => ['path' => '/nexora/rh/horarios',               'view' => 'rh_horarios.php',               'permission' => 'recursos-humanos'],
            'rh_componentes_salariais'  => ['path' => '/nexora/rh/componentes-salariais',  'view' => 'rh_componentes_salariais.php',  'permission' => 'recursos-humanos'],
            'rh_beneficios'             => ['path' => '/nexora/rh/beneficios',             'view' => 'rh_beneficios.php',             'permission' => 'recursos-humanos'],
            'rh_tipos_ausencia'         => ['path' => '/nexora/rh/tipos-ausencia',         'view' => 'rh_tipos_ausencia.php',         'permission' => 'recursos-humanos'],
            'rh_criterios_avaliacao'    => ['path' => '/nexora/rh/criterios-avaliacao',    'view' => 'rh_criterios_avaliacao.php',    'permission' => 'recursos-humanos'],
            'rh_formacoes'              => ['path' => '/nexora/rh/formacoes',              'view' => 'rh_formacoes.php',              'permission' => 'recursos-humanos'],
            'rh_processamento_salarial' => ['path' => '/nexora/rh/processamento-salarial', 'view' => 'rh_processamento_salarial.php', 'permission' => 'recursos-humanos'],
            'rh_configuracoes'          => ['path' => '/nexora/rh/configuracoes',          'view' => 'rh_configuracoes.php',          'permission' => 'recursos-humanos'],

            // Assinatura Digital
            'assinatura_digital'        => ['path' => '/nexora/assinatura-digital',        'view' => 'assinatura_digital.php',        'permission' => 'assinatura-digital'],
        ];
    }
}
