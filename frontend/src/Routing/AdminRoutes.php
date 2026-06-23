<?php
declare(strict_types=1);

namespace E258Tech\Routing;

use InvalidArgumentException;

final class AdminRoutes
{
    private const PAGES = [
        // Dashboard
        'dashboard'            => ['path' => '/nexora/',                              'view' => 'dashboard.php',          'permission' => ''],
        // Recrutamento
        'pipeline'             => ['path' => '/nexora/recrutamento/pipeline',         'view' => 'pipeline.php',           'permission' => 'recrutamento'],
        'relatorios'           => ['path' => '/nexora/recrutamento/relatorios',       'view' => 'relatorios.php',         'permission' => 'recrutamento'],
        'vagas'                => ['path' => '/nexora/recrutamento/vagas',            'view' => 'vagas.php',              'permission' => 'recrutamento'],
        'vaga_form'            => ['path' => '/nexora/recrutamento/vagas/form',       'view' => 'vaga_form.php',          'permission' => 'recrutamento'],
        'candidaturas'         => ['path' => '/nexora/recrutamento/candidaturas',     'view' => 'candidaturas.php',       'permission' => 'recrutamento'],
        'candidatura_ver'      => ['path' => '/nexora/recrutamento/candidaturas/ver', 'view' => 'candidatura_ver.php',    'permission' => 'recrutamento'],
        // CRM
        'leads'                => ['path' => '/nexora/crm/leads',                    'view' => 'leads.php',              'permission' => 'crm'],
        'lead_form'            => ['path' => '/nexora/crm/leads/form',               'view' => 'lead_form.php',          'permission' => 'crm'],
        'crm_leads_pipeline'   => ['path' => '/nexora/crm/leads/pipeline',           'view' => 'crm_leads_pipeline.php', 'permission' => 'crm'],
        'oportunidades'        => ['path' => '/nexora/crm/oportunidades',            'view' => 'oportunidades.php',      'permission' => 'crm'],
        'oportunidade_form'    => ['path' => '/nexora/crm/oportunidades/form',       'view' => 'oportunidade_form.php',  'permission' => 'crm'],
        'crm_pipeline'         => ['path' => '/nexora/crm/pipeline',                 'view' => 'crm_pipeline.php',       'permission' => 'crm'],
        // Clientes
        'clientes'             => ['path' => '/nexora/clientes',                     'view' => 'clientes.php',           'permission' => 'clientes'],
        'cliente_form'         => ['path' => '/nexora/clientes/form',                'view' => 'cliente_form.php',       'permission' => 'clientes'],
        // Faturação
        'faturacao_series'     => ['path' => '/nexora/faturacao/series',             'view' => 'faturacao_series.php',   'permission' => 'faturacao'],
        'orcamentos'           => ['path' => '/nexora/faturacao/orcamentos',         'view' => 'orcamentos.php',         'permission' => 'faturacao'],
        'orcamento_form'       => ['path' => '/nexora/faturacao/orcamentos/form',    'view' => 'orcamento_form.php',     'permission' => 'faturacao'],
        'orcamento_proforma'   => ['path' => '/nexora/faturacao/orcamentos/proforma','view' => 'orcamento_proforma.php', 'permission' => 'faturacao'],
        'encomendas'           => ['path' => '/nexora/faturacao/encomendas',         'view' => 'encomendas.php',         'permission' => 'faturacao'],
        'faturas'              => ['path' => '/nexora/faturacao/faturas',            'view' => 'faturas.php',            'permission' => 'faturacao'],
        'fatura_form'          => ['path' => '/nexora/faturacao/faturas/form',       'view' => 'fatura_form.php',        'permission' => 'faturacao'],
        'fatura_proforma'      => ['path' => '/nexora/faturacao/faturas/proforma',   'view' => 'fatura_proforma.php',    'permission' => 'faturacao'],
        'recibos'              => ['path' => '/nexora/faturacao/recibos',            'view' => 'recibos.php',            'permission' => 'faturacao'],
        'notas_credito'        => ['path' => '/nexora/faturacao/notas-credito',      'view' => 'notas_credito.php',      'permission' => 'faturacao'],
        // POS
        'pos'                  => ['path' => '/nexora/pos',                          'view' => 'pos.php',                'permission' => 'pos'],
        'pos_dashboard'        => ['path' => '/nexora/pos/dashboard',                'view' => 'pos_dashboard.php',      'permission' => 'pos'],
        'pos_vendas'           => ['path' => '/nexora/pos/vendas',                   'view' => 'pos_vendas.php',         'permission' => 'pos'],
        'pos_venda_ver'        => ['path' => '/nexora/pos/vendas/ver',               'view' => 'pos_venda_ver.php',      'permission' => 'pos'],
        'pos_terminais'        => ['path' => '/nexora/pos/terminais',                'view' => 'pos_terminais.php',      'permission' => 'pos'],
        'pos_catalogo'         => ['path' => '/nexora/pos/catalogo',                 'view' => 'pos_catalogo.php',       'permission' => 'pos'],
        'pos_relatorios'       => ['path' => '/nexora/pos/relatorios',               'view' => 'pos_relatorios.php',     'permission' => 'pos'],
        'pos_devolucoes'       => ['path' => '/nexora/pos/devolucoes',               'view' => 'pos_devolucoes.php',     'permission' => 'pos'],
        // Produtos & Stock
        'produtos'             => ['path' => '/nexora/produtos',                     'view' => 'produtos.php',           'permission' => 'stock'],
        'produto_form'         => ['path' => '/nexora/produtos/form',                'view' => 'produto_form.php',       'permission' => 'stock'],
        'produto_categorias'   => ['path' => '/nexora/produtos/categorias',          'view' => 'produto_categorias.php', 'permission' => 'stock'],
        'stock'                => ['path' => '/nexora/stock',                        'view' => 'stock.php',              'permission' => 'stock'],
        // Compras
        'compras'              => ['path' => '/nexora/compras',                      'view' => 'compras.php',            'permission' => 'compras'],
        // Financeiro
        'tesouraria'           => ['path' => '/nexora/tesouraria',                   'view' => 'tesouraria.php',         'permission' => 'tesouraria'],
        'logistica'            => ['path' => '/nexora/logistica',                    'view' => 'logistica.php',          'permission' => 'logistica'],
        'financeiro'           => ['path' => '/nexora/financeiro',                   'view' => 'financeiro.php',         'permission' => 'financeiro'],
        'multi_moeda'          => ['path' => '/nexora/multi-moeda',                  'view' => 'multi_moeda.php',        'permission' => 'multi-moeda'],
        'centros_custo'        => ['path' => '/nexora/centros-custo',                'view' => 'centros_custo.php',      'permission' => 'centros-custo'],
        'impostos_avancados'   => ['path' => '/nexora/impostos/avancados',           'view' => 'impostos_avancados.php', 'permission' => 'impostos'],
        // Contabilidade
        'contab_plano_contas'  => ['path' => '/nexora/contabilidade/plano-contas',   'view' => 'contab_plano_contas.php',  'permission' => 'contabilidade'],
        'contab_periodos'      => ['path' => '/nexora/contabilidade/periodos',       'view' => 'contab_periodos.php',      'permission' => 'contabilidade'],
        'contab_lancamentos'   => ['path' => '/nexora/contabilidade/lancamentos',    'view' => 'contab_lancamentos.php',   'permission' => 'contabilidade'],
        'contab_lancamento'    => ['path' => '/nexora/contabilidade/lancamento',     'view' => 'contab_lancamento.php',    'permission' => 'contabilidade'],
        'contab_impostos'      => ['path' => '/nexora/contabilidade/impostos',       'view' => 'contab_impostos.php',      'permission' => 'contabilidade'],
        'contab_ativos_fixos'  => ['path' => '/nexora/contabilidade/ativos-fixos',   'view' => 'contab_ativos_fixos.php',  'permission' => 'contabilidade'],
        'contab_amortizacoes'  => ['path' => '/nexora/contabilidade/amortizacoes',   'view' => 'contab_amortizacoes.php',  'permission' => 'contabilidade'],
        'contab_orcamentos'    => ['path' => '/nexora/contabilidade/orcamentos',     'view' => 'contab_orcamentos.php',    'permission' => 'contabilidade'],
        'contab_encerramento'  => ['path' => '/nexora/contabilidade/encerramento',   'view' => 'contab_encerramento.php',  'permission' => 'contabilidade'],
        'contab_relatorios'    => ['path' => '/nexora/contabilidade/relatorios',     'view' => 'contab_relatorios.php',    'permission' => 'contabilidade'],
        // RH
        'rh_funcionarios'      => ['path' => '/nexora/rh/funcionarios',              'view' => 'rh_funcionarios.php',    'permission' => 'recursos-humanos'],
        'rh_funcionario'       => ['path' => '/nexora/rh/funcionarios/ver',          'view' => 'rh_funcionario.php',     'permission' => 'recursos-humanos'],
        'rh_ausencias'         => ['path' => '/nexora/rh/ausencias',                 'view' => 'rh_ausencias.php',       'permission' => 'recursos-humanos'],
        'rh_organograma'       => ['path' => '/nexora/rh/organograma',               'view' => 'rh_organograma.php',     'permission' => 'recursos-humanos'],
        'rh_folha_pagamento'   => ['path' => '/nexora/rh/folha-pagamento',           'view' => 'rh_folha_pagamento.php', 'permission' => 'recursos-humanos'],
        'rh_relatorios'        => ['path' => '/nexora/rh/relatorios',                'view' => 'rh_relatorios.php',      'permission' => 'recursos-humanos'],
        // Sistema
        'sistema_geral'        => ['path' => '/nexora/sistema/geral',                'view' => 'sistema_geral.php',      'permission' => 'sistema-configuracao'],
        'sistema_templates'    => ['path' => '/nexora/sistema/templates',            'view' => 'sistema_templates.php',  'permission' => 'sistema-configuracao'],
        'sistema_logs'         => ['path' => '/nexora/sistema/logs',                 'view' => 'sistema_logs.php',       'permission' => 'sistema-configuracao'],
        // Outros
        'assinaturas'          => ['path' => '/nexora/assinaturas',                  'view' => 'assinaturas.php',        'permission' => 'assinaturas'],
        'notificacoes'         => ['path' => '/nexora/notificacoes',                 'view' => 'notificacoes.php',       'permission' => 'notificacoes'],
        'seguranca'            => ['path' => '/nexora/seguranca',                    'view' => 'seguranca.php',          'permission' => 'seguranca'],
        'gestao_escolar'                => ['path' => '/nexora/gestao-escolar',                        'view' => 'gestao_escolar.php',                'permission' => 'gestao-escolar'],
        'escolar_dashboard'             => ['path' => '/nexora/gestao-escolar/dashboard',               'view' => 'escolar_dashboard.php',             'permission' => 'gestao-escolar'],
        'escolar_anos_lectivos'         => ['path' => '/nexora/gestao-escolar/anos-lectivos',           'view' => 'escolar_anos_lectivos.php',          'permission' => 'gestao-escolar'],
        'escolar_turmas'                => ['path' => '/nexora/gestao-escolar/turmas',                  'view' => 'escolar_turmas.php',                'permission' => 'gestao-escolar'],
        'escolar_disciplinas'           => ['path' => '/nexora/gestao-escolar/disciplinas',             'view' => 'escolar_disciplinas.php',            'permission' => 'gestao-escolar'],
        'escolar_atribuicoes'           => ['path' => '/nexora/gestao-escolar/atribuicoes',             'view' => 'escolar_atribuicoes.php',            'permission' => 'gestao-escolar'],
        'escolar_alunos'                => ['path' => '/nexora/gestao-escolar/alunos',                  'view' => 'escolar_alunos.php',                'permission' => 'gestao-escolar'],
        'escolar_matriculas'            => ['path' => '/nexora/gestao-escolar/matriculas',              'view' => 'escolar_matriculas.php',             'permission' => 'gestao-escolar'],
        'escolar_cargos_alunos'         => ['path' => '/nexora/gestao-escolar/cargos-alunos',           'view' => 'escolar_cargos_alunos.php',          'permission' => 'gestao-escolar'],
        'escolar_cargos_professores'    => ['path' => '/nexora/gestao-escolar/cargos-professores',      'view' => 'escolar_cargos_professores.php',     'permission' => 'gestao-escolar'],
        'escolar_frequencia'            => ['path' => '/nexora/gestao-escolar/frequencia',              'view' => 'escolar_frequencia.php',             'permission' => 'gestao-escolar'],
        'escolar_avaliacoes'            => ['path' => '/nexora/gestao-escolar/avaliacoes',              'view' => 'escolar_avaliacoes.php',             'permission' => 'gestao-escolar'],
        'escolar_notas'                 => ['path' => '/nexora/gestao-escolar/notas',                   'view' => 'escolar_notas.php',                 'permission' => 'gestao-escolar'],
        'escolar_boletins'              => ['path' => '/nexora/gestao-escolar/boletins',                'view' => 'escolar_boletins.php',               'permission' => 'gestao-escolar'],
        'escolar_planos_cobranca'       => ['path' => '/nexora/gestao-escolar/planos-cobranca',         'view' => 'escolar_planos_cobranca.php',        'permission' => 'gestao-escolar'],
        'escolar_cobrancas'             => ['path' => '/nexora/gestao-escolar/cobrancas',               'view' => 'escolar_cobrancas.php',              'permission' => 'gestao-escolar'],
        'escolar_pagamentos'            => ['path' => '/nexora/gestao-escolar/pagamentos',              'view' => 'escolar_pagamentos.php',             'permission' => 'gestao-escolar'],
        'escolar_biblioteca'            => ['path' => '/nexora/gestao-escolar/biblioteca',              'view' => 'escolar_biblioteca.php',             'permission' => 'gestao-escolar'],
        'escolar_emprestimos'           => ['path' => '/nexora/gestao-escolar/emprestimos',             'view' => 'escolar_emprestimos.php',            'permission' => 'gestao-escolar'],
        'escolar_comunicacao'           => ['path' => '/nexora/gestao-escolar/comunicacao',             'view' => 'escolar_comunicacao.php',            'permission' => 'gestao-escolar'],
        'escolar_resumo_academico'      => ['path' => '/nexora/gestao-escolar/resumo-academico',        'view' => 'escolar_resumo_academico.php',       'permission' => 'gestao-escolar'],
        'escolar_resumo_financeiro'     => ['path' => '/nexora/gestao-escolar/resumo-financeiro',       'view' => 'escolar_resumo_financeiro.php',      'permission' => 'gestao-escolar'],
        'escolar_inadimplencia'         => ['path' => '/nexora/gestao-escolar/inadimplencia',           'view' => 'escolar_inadimplencia.php',          'permission' => 'gestao-escolar'],
        // Self-service
        'pedido_ferias'        => ['path' => '/nexora/pedido-ferias',             'view' => 'pedido_ferias.php',        'permission' => ''],
        'chat'                 => ['path' => '/nexora/chat',                      'view' => 'chat.php',                 'permission' => ''],
        'minha_assiduidade'    => ['path' => '/nexora/assiduidade',               'view' => 'minha_assiduidade.php',    'permission' => ''],
        'meu_perfil'           => ['path' => '/nexora/perfil',                    'view' => 'meu_perfil.php',           'permission' => ''],
        // Administração
        'utilizadores'         => ['path' => '/nexora/admin/utilizadores',           'view' => 'utilizadores.php',       'permission' => 'autorizacao'],
        'utilizador_form'      => ['path' => '/nexora/admin/utilizadores/form',      'view' => 'utilizador_form.php',    'permission' => 'autorizacao'],
        'cargos'               => ['path' => '/nexora/admin/cargos',                 'view' => 'cargos.php',             'permission' => 'autorizacao'],
        'cargo_form'           => ['path' => '/nexora/admin/cargos/form',            'view' => 'cargo_form.php',         'permission' => 'autorizacao'],
        'empresa'              => ['path' => '/nexora/admin/empresa',                'view' => 'empresa.php',            'permission' => 'empresa'],
        'sessoes'              => ['path' => '/nexora/admin/sessoes',                'view' => 'sessoes.php',            'permission' => 'auth'],
        'auditoria'            => ['path' => '/nexora/admin/auditoria',              'view' => 'auditoria.php',          'permission' => 'auditoria'],
    ];

    public function resolveByPath(string $path): ?string
    {
        $clean = rtrim($path, '/');
        foreach (self::PAGES as $name => $def) {
            if (rtrim($def['path'], '/') === $clean) {
                return $name;
            }
        }
        return null;
    }

    public function definition(string $name): array
    {
        return self::PAGES[$name]
            ?? throw new InvalidArgumentException("Rota administrativa desconhecida: $name");
    }

    public function names(): array
    {
        return array_keys(self::PAGES);
    }

    public function path(string $name, array $query = []): string
    {
        $path = $this->definition($name)['path'];
        $query = array_filter(
            $query,
            static fn(mixed $value): bool => $value !== null && $value !== ''
        );

        return $path . ($query ? '?' . http_build_query($query) : '');
    }

    public function api(string $name): string
    {
        return (new AdminApiRoutes())->path($name);
    }

    public function apiNames(): array
    {
        return (new AdminApiRoutes())->names();
    }
}
