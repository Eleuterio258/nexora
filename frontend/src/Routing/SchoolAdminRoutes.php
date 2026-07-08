<?php
declare(strict_types=1);

namespace E258Tech\Routing;

use InvalidArgumentException;

/**
 * Rotas do Painel Escolar independente (/escola/*).
 *
 * As rotas ERP (/nexora/gestao-escolar/*) foram removidas; o módulo escolar
 * agora só é acedido via Painel Escola.
 */
final class SchoolAdminRoutes
{
    /**
     * Definições das páginas: view e permissão necessária.
     * O path é sempre o do painel escolar (ESCOLAR_PANEL_PATHS).
     */
    private const VIEWS = [
        'gestao_escolar'                => ['view' => 'gestao_escolar.php',                'permission' => 'gestao-escolar'],
        'escolar_dashboard'             => ['view' => 'escolar_dashboard.php',             'permission' => 'gestao-escolar'],
        'escolar_anos_lectivos'         => ['view' => 'escolar_anos_lectivos.php',          'permission' => 'gestao-escolar'],
        'escolar_periodos'              => ['view' => 'escolar_periodos.php',               'permission' => 'gestao-escolar'],
        'escolar_turmas'                => ['view' => 'escolar_turmas.php',                'permission' => 'gestao-escolar'],
        'escolar_disciplinas'           => ['view' => 'escolar_disciplinas.php',            'permission' => 'gestao-escolar'],
        'escolar_atribuicoes'           => ['view' => 'escolar_atribuicoes.php',            'permission' => 'gestao-escolar'],
        'escolar_alunos'                => ['view' => 'escolar_alunos.php',                'permission' => 'gestao-escolar'],
        'escolar_matriculas'            => ['view' => 'escolar_matriculas.php',             'permission' => 'gestao-escolar'],
        'escolar_cargos_alunos'         => ['view' => 'escolar_cargos_alunos.php',          'permission' => 'gestao-escolar'],
        'escolar_cargos_professores'    => ['view' => 'escolar_cargos_professores.php',     'permission' => 'gestao-escolar'],
        'escolar_frequencia'            => ['view' => 'escolar_frequencia.php',             'permission' => 'gestao-escolar'],
        'escolar_avaliacoes'            => ['view' => 'escolar_avaliacoes.php',             'permission' => 'gestao-escolar'],
        'escolar_notas'                 => ['view' => 'escolar_notas.php',                 'permission' => 'gestao-escolar'],
        'escolar_boletins'              => ['view' => 'escolar_boletins.php',               'permission' => 'gestao-escolar'],
        'escolar_planos_cobranca'       => ['view' => 'escolar_planos_cobranca.php',        'permission' => 'gestao-escolar'],
        'escolar_cobrancas'             => ['view' => 'escolar_cobrancas.php',              'permission' => 'gestao-escolar'],
        'escolar_pagamentos'            => ['view' => 'escolar_pagamentos.php',             'permission' => 'gestao-escolar'],
        'escolar_biblioteca'            => ['view' => 'escolar_biblioteca.php',             'permission' => 'gestao-escolar'],
        'escolar_emprestimos'           => ['view' => 'escolar_emprestimos.php',            'permission' => 'gestao-escolar'],
        'escolar_comunicacao'           => ['view' => 'escolar_comunicacao.php',            'permission' => 'gestao-escolar'],
        'escolar_resumo_academico'      => ['view' => 'escolar_resumo_academico.php',       'permission' => 'gestao-escolar'],
        'escolar_resumo_financeiro'     => ['view' => 'escolar_resumo_financeiro.php',      'permission' => 'gestao-escolar'],
        'escolar_inadimplencia'         => ['view' => 'escolar_inadimplencia.php',          'permission' => 'gestao-escolar'],
        'escolar_professores'           => ['view' => 'escolar_professores.php',            'permission' => 'gestao-escolar'],
        'escolar_niveis'                => ['view' => 'escolar_niveis.php',                 'permission' => 'gestao-escolar'],
        'escolar_series'                => ['view' => 'escolar_series.php',                 'permission' => 'gestao-escolar'],
        'escolar_cursos'                => ['view' => 'escolar_cursos.php',                 'permission' => 'gestao-escolar'],
        'escolar_horarios'              => ['view' => 'escolar_horarios.php',               'permission' => 'gestao-escolar'],
        'escolar_ocorrencias'           => ['view' => 'escolar_ocorrencias.php',            'permission' => 'gestao-escolar'],
        'escolar_calendario'            => ['view' => 'escolar_calendario.php',             'permission' => 'gestao-escolar'],
        'escolar_config_financeira'     => ['view' => 'escolar_config_financeira.php',      'permission' => 'gestao-escolar'],
        'escolar_dashboard_diraccao'    => ['view' => 'escolar_dashboard.php',              'permission' => 'gestao-escolar'],
    ];

    /**
     * Mapa das rotas do Painel Escolar independente (/escola/*).
     */
    private const ESCOLAR_PANEL_PATHS = [
        'escolar_dashboard'             => '/escola/dashboard',
        'escolar_anos_lectivos'         => '/escola/anos-lectivos',
        'escolar_periodos'              => '/escola/periodos',
        'escolar_niveis'                => '/escola/niveis',
        'escolar_series'                => '/escola/series',
        'escolar_cursos'                => '/escola/cursos',
        'escolar_turmas'                => '/escola/turmas',
        'escolar_disciplinas'           => '/escola/disciplinas',
        'escolar_professores'           => '/escola/professores',
        'escolar_atribuicoes'           => '/escola/atribuicoes',
        'escolar_horarios'              => '/escola/horarios',
        'escolar_calendario'            => '/escola/calendario',
        'escolar_alunos'                => '/escola/alunos',
        'escolar_matriculas'            => '/escola/matriculas',
        'escolar_cargos_alunos'         => '/escola/cargos-alunos',
        'escolar_cargos_professores'    => '/escola/cargos-professores',
        'escolar_ocorrencias'           => '/escola/ocorrencias',
        'escolar_frequencia'            => '/escola/frequencia',
        'escolar_avaliacoes'            => '/escola/avaliacoes',
        'escolar_notas'                 => '/escola/notas',
        'escolar_boletins'              => '/escola/boletins',
        'escolar_planos_cobranca'       => '/escola/planos-propinas',
        'escolar_cobrancas'             => '/escola/cobrancas',
        'escolar_pagamentos'            => '/escola/pagamentos',
        'escolar_inadimplencia'         => '/escola/aging',
        'escolar_biblioteca'            => '/escola/biblioteca',
        'escolar_emprestimos'           => '/escola/emprestimos',
        'escolar_comunicacao'           => '/escola/comunicacao',
        'escolar_resumo_academico'      => '/escola/resumo-academico',
        'escolar_resumo_financeiro'     => '/escola/resumo-financeiro',
        'escolar_config_financeira'     => '/escola/config-financeira',
    ];

    public function resolveByPath(string $path): ?string
    {
        $clean = rtrim($path, '/');
        foreach (self::ESCOLAR_PANEL_PATHS as $name => $panelPath) {
            if (rtrim($panelPath, '/') === $clean) {
                return $name;
            }
        }
        return null;
    }

    public function definition(string $name): array
    {
        $view = self::VIEWS[$name] ?? null;
        if ($view === null) {
            throw new InvalidArgumentException("Rota escolar desconhecida: $name");
        }

        $path = self::ESCOLAR_PANEL_PATHS[$name]
            ?? throw new InvalidArgumentException("Rota escolar sem path: $name");

        return array_merge($view, ['path' => $path]);
    }

    public function names(): array
    {
        return array_keys(self::VIEWS);
    }

    public function path(string $name, array $query = []): string
    {
        $path = self::ESCOLAR_PANEL_PATHS[$name]
            ?? throw new InvalidArgumentException("Rota escolar desconhecida: $name");

        $query = array_filter(
            $query,
            static fn(mixed $value): bool => $value !== null && $value !== ''
        );

        return $path . ($query ? '?' . http_build_query($query) : '');
    }

    /**
     * Gera o breadcrumb base para views do módulo escolar.
     * Como só existe o Painel Escolar (/escola/*), o layout escola_top.php já
     * imprime "Escola" como raiz; retorna apenas o tail fornecido.
     */
    public function escolarBreadcrumb(array $tail): array
    {
        return $tail;
    }
}
