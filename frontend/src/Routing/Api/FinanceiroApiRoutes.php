<?php
declare (strict_types = 1);

namespace E258Tech\Routing\Api;

final class FinanceiroApiRoutes
{
    public static function endpoints(): array
    {
        return [
            // ── Logística ─────────────────────────────────────────────────────────
            'logistica_operacao'              => ['module' => 'logistica', 'action' => 'gerir_entregas'],

            // ── Financeiro ────────────────────────────────────────────────────────
            'financeiro_operacao'             => ['module' => 'financeiro', 'action' => 'gerir_contas_receber'],

            // ── Tesouraria ────────────────────────────────────────────────────────
            'tesouraria_operacao'             => ['module' => 'tesouraria', 'action' => 'gerir_movimentos'],

            // ── Contabilidade ─────────────────────────────────────────────────────
            'contab_conta_save'               => ['module' => 'contabilidade', 'action' => 'gerir_plano_contas'],
            'contab_conta_remover'            => ['module' => 'contabilidade', 'action' => 'gerir_plano_contas'],
            'contab_tipo_conta_save'          => ['module' => 'contabilidade', 'action' => 'gerir_plano_contas'],
            'contab_tipo_conta_remover'       => ['module' => 'contabilidade', 'action' => 'gerir_plano_contas'],
            'contab_ano_fiscal_save'          => ['module' => 'contabilidade', 'action' => 'gerir_periodos'],
            'contab_periodo_abrir'            => ['module' => 'contabilidade', 'action' => 'gerir_periodos'],
            'contab_diario_save'              => ['module' => 'contabilidade', 'action' => 'gerir_lancamentos'],
            'contab_lancamento_save'          => ['module' => 'contabilidade', 'action' => 'gerir_lancamentos'],
            'contab_lancamento_linha_save'    => ['module' => 'contabilidade', 'action' => 'gerir_lancamentos'],
            'contab_lancamento_estornar'      => ['module' => 'contabilidade', 'action' => 'gerir_lancamentos'],
            'contab_taxa_save'                => ['module' => 'contabilidade', 'action' => 'gerir_lancamentos'],
            'contab_regra_taxa_save'          => ['module' => 'contabilidade', 'action' => 'gerir_lancamentos'],
            'contab_grupo_imposto_save'       => ['module' => 'contabilidade', 'action' => 'gerir_lancamentos'],
            'contab_transacao_imposto_save'   => ['module' => 'contabilidade', 'action' => 'gerir_lancamentos'],
            'contab_ativo_fixo_save'          => ['module' => 'contabilidade', 'action' => 'gerir_ativos_fixos'],
            'contab_ativo_fixo_alienar'       => ['module' => 'contabilidade', 'action' => 'gerir_ativos_fixos'],
            'contab_amortizacao_processar'    => ['module' => 'contabilidade', 'action' => 'gerir_ativos_fixos'],
            'contab_amortizacao_cancelar'     => ['module' => 'contabilidade', 'action' => 'gerir_ativos_fixos'],
            'contab_orcamento_save'           => ['module' => 'contabilidade', 'action' => 'gerir_orcamentos'],
            'contab_orcamento_remover'        => ['module' => 'contabilidade', 'action' => 'gerir_orcamentos'],
            'contab_ano_fiscal_fechar'        => ['module' => 'contabilidade', 'action' => 'fechar_periodo'],
            'contab_periodo_fechar'           => ['module' => 'contabilidade', 'action' => 'fechar_periodo'],
            'contab_encerramento_iniciar'     => ['module' => 'contabilidade', 'action' => 'fechar_periodo'],
            'contab_encerramento_verificar'   => ['module' => 'contabilidade', 'action' => 'fechar_periodo'],
            'contab_encerramento_confirmar'   => ['module' => 'contabilidade', 'action' => 'fechar_periodo'],
            'contab_encerramento_reabrir'     => ['module' => 'contabilidade', 'action' => 'fechar_periodo'],
            'contab_relatorio_gerar'          => ['module' => 'contabilidade', 'action' => 'ver_relatorios'],

            // ── Impostos ──────────────────────────────────────────────────────────
            'imposto_operacao'                => ['module' => 'impostos', 'action' => 'gerir_impostos'],

            // ── Multi-Moeda ───────────────────────────────────────────────────────
            'multi_moeda_operacao'            => ['module' => 'multi-moeda', 'action' => 'gerir_moedas'],

            // ── Centros de Custo ──────────────────────────────────────────────────
            'centros_custo_centro_save'       => ['module' => 'centros-custo', 'action' => 'gerir_centros'],
            'centros_custo_centro_remover'    => ['module' => 'centros-custo', 'action' => 'eliminar_centros'],
            'centros_custo_orcamento_save'    => ['module' => 'centros-custo', 'action' => 'gerir_orcamentos'],
            'centros_custo_orcamento_remover' => ['module' => 'centros-custo', 'action' => 'gerir_orcamentos'],
            'centros_custo_alocacao_save'     => ['module' => 'centros-custo', 'action' => 'gerir_alocacoes'],
        ];
    }
}
