<?php
declare (strict_types = 1);

namespace E258Tech\Routing\Api;

final class RhApiRoutes
{
    public static function endpoints(): array
    {
        return [
            // ── Configurações ─────────────────────────────────────────────────────
            'rh_config_save'                              => ['module' => 'recursos-humanos', 'action' => 'gerir_funcionarios'],
            'rh_proximo_numero_funcionario'               => ['module' => 'recursos-humanos', 'action' => 'ver_funcionarios', 'method' => 'GET'],
            'rh_irps_escaloes'                            => ['module' => 'recursos-humanos', 'action' => 'ver_funcionarios', 'method' => 'GET'],
            'rh_irps_escalao_save'                        => ['module' => 'recursos-humanos', 'action' => 'gerir_funcionarios'],
            'rh_irps_escalao_update'                      => ['module' => 'recursos-humanos', 'action' => 'gerir_funcionarios'],
            'rh_irps_escalao_delete'                      => ['module' => 'recursos-humanos', 'action' => 'gerir_funcionarios'],
            'rh_irps_seed_mozambique'                     => ['module' => 'recursos-humanos', 'action' => 'gerir_funcionarios'],

            // ── Gestão de funcionários ────────────────────────────────────────────
            'rh_funcionario_save'                         => ['module' => 'recursos-humanos', 'action' => 'gerir_funcionarios'],
            'rh_funcionario_desligar'                     => ['module' => 'recursos-humanos', 'action' => 'gerir_funcionarios'],
            'rh_ausencia_save'                            => ['module' => 'recursos-humanos', 'action' => 'gerir_funcionarios'],
            'rh_funcionario_presenca_save'                => ['module' => 'recursos-humanos', 'action' => 'gerir_funcionarios'],
            'rh_funcionario_presenca_remover'             => ['module' => 'recursos-humanos', 'action' => 'gerir_funcionarios'],
            'rh_documento_save'                           => ['module' => 'recursos-humanos', 'action' => 'gerir_funcionarios'],
            'rh_documento_remover'                        => ['module' => 'recursos-humanos', 'action' => 'gerir_funcionarios'],
            'rh_documento_ficheiro'                       => ['module' => 'recursos-humanos', 'action' => 'ver_funcionarios', 'method' => 'GET'],
            'rh_contacto_emergencia_save'                 => ['module' => 'recursos-humanos', 'action' => 'gerir_funcionarios'],
            'rh_contacto_emergencia_remover'              => ['module' => 'recursos-humanos', 'action' => 'gerir_funcionarios'],
            'rh_cargo_save'                               => ['module' => 'recursos-humanos', 'action' => 'gerir_funcionarios'],
            'rh_cargo_remover'                            => ['module' => 'recursos-humanos', 'action' => 'gerir_funcionarios'],
            'rh_unidade_save'                             => ['module' => 'recursos-humanos', 'action' => 'gerir_funcionarios'],
            'rh_unidade_mover'                            => ['module' => 'recursos-humanos', 'action' => 'gerir_funcionarios'],
            'rh_unidade_remover'                          => ['module' => 'recursos-humanos', 'action' => 'gerir_funcionarios'],
            'rh_tipo_ausencia_save'                       => ['module' => 'recursos-humanos', 'action' => 'gerir_funcionarios'],
            'rh_tipo_ausencia_remover'                    => ['module' => 'recursos-humanos', 'action' => 'gerir_funcionarios'],
            'rh_funcionario_processo_disciplinar_save'    => ['module' => 'recursos-humanos', 'action' => 'gerir_funcionarios'],
            'rh_funcionario_processo_disciplinar_editar'  => ['module' => 'recursos-humanos', 'action' => 'gerir_funcionarios'],
            'rh_funcionario_processo_disciplinar_remover' => ['module' => 'recursos-humanos', 'action' => 'gerir_funcionarios'],
            'rh_funcionario_saldo_ausencia_save'          => ['module' => 'recursos-humanos', 'action' => 'aprovar_ausencias'],

            // ── Contratos ─────────────────────────────────────────────────────────
            'rh_contrato_save'                            => ['module' => 'recursos-humanos', 'action' => 'gerir_contratos'],
            'rh_contrato_renovar'                         => ['module' => 'recursos-humanos', 'action' => 'gerir_contratos'],
            'rh_contrato_rescindir'                       => ['module' => 'recursos-humanos', 'action' => 'gerir_contratos'],
            'rh_contrato_ficheiro'                        => ['module' => 'recursos-humanos', 'action' => 'gerir_contratos', 'method' => 'GET'],
            'rh_contrato_pdf'                             => ['module' => 'recursos-humanos', 'action' => 'gerir_contratos', 'method' => 'GET'],
            'rh_contrato_enviar_assinatura'               => ['module' => 'recursos-humanos', 'action' => 'gerir_contratos'],

            // ── Horários ──────────────────────────────────────────────────────────
            'rh_horario_save'                             => ['module' => 'recursos-humanos', 'action' => 'gerir_horarios'],
            'rh_horario_remover'                          => ['module' => 'recursos-humanos', 'action' => 'gerir_horarios'],

            // ── Aprovação de ausências ────────────────────────────────────────────
            'rh_ausencia_aprovar'                         => ['module' => 'recursos-humanos', 'action' => 'aprovar_ausencias'],
            'rh_ausencia_rejeitar'                        => ['module' => 'recursos-humanos', 'action' => 'aprovar_ausencias'],
            'rh_ausencia_gozar'                           => ['module' => 'recursos-humanos', 'action' => 'aprovar_ausencias'],
            'rh_ausencia_cancelar'                        => ['module' => 'recursos-humanos', 'action' => 'aprovar_ausencias'],

            // ── Processamento salarial ────────────────────────────────────────────
            'rh_folha_pagamento_save'                     => ['module' => 'recursos-humanos', 'action' => 'processar_salarios'],
            'rh_folha_pagamento_processar'                => ['module' => 'recursos-humanos', 'action' => 'processar_salarios'],
            'rh_folha_pagamento_pagar'                    => ['module' => 'recursos-humanos', 'action' => 'processar_salarios'],
            'rh_folha_pagamento_cancelar'                 => ['module' => 'recursos-humanos', 'action' => 'processar_salarios'],
            'rh_historico_salarial_save'                  => ['module' => 'recursos-humanos', 'action' => 'processar_salarios'],
            'rh_componente_salarial_save'                 => ['module' => 'recursos-humanos', 'action' => 'processar_salarios'],
            'rh_componente_salarial_remover'              => ['module' => 'recursos-humanos', 'action' => 'processar_salarios'],
            'rh_adiantamento_save'                        => ['module' => 'recursos-humanos', 'action' => 'processar_salarios'],
            'rh_adiantamento_cancelar'                    => ['module' => 'recursos-humanos', 'action' => 'processar_salarios'],
            'rh_emprestimo_save'                          => ['module' => 'recursos-humanos', 'action' => 'processar_salarios'],
            'rh_emprestimo_cancelar'                      => ['module' => 'recursos-humanos', 'action' => 'processar_salarios'],
            'rh_funcionario_componente_save'              => ['module' => 'recursos-humanos', 'action' => 'processar_salarios'],
            'rh_funcionario_componente_remover'           => ['module' => 'recursos-humanos', 'action' => 'processar_salarios'],
            'rh_periodo_save'                             => ['module' => 'recursos-humanos', 'action' => 'processar_salarios'],
            'rh_periodo_encerrar'                         => ['module' => 'recursos-humanos', 'action' => 'processar_salarios'],

            // ── Avaliações ────────────────────────────────────────────────────────
            'rh_avaliacao_save'                           => ['module' => 'recursos-humanos', 'action' => 'gerir_avaliacoes'],
            'rh_avaliacao_submeter'                       => ['module' => 'recursos-humanos', 'action' => 'gerir_avaliacoes'],
            'rh_avaliacao_aprovar'                        => ['module' => 'recursos-humanos', 'action' => 'gerir_avaliacoes'],
            'rh_criterio_avaliacao_save'                  => ['module' => 'recursos-humanos', 'action' => 'gerir_avaliacoes'],
            'rh_criterio_avaliacao_remover'               => ['module' => 'recursos-humanos', 'action' => 'gerir_avaliacoes'],

            // ── Formações ─────────────────────────────────────────────────────────
            'rh_formacao_save'                            => ['module' => 'recursos-humanos', 'action' => 'gerir_formacoes'],
            'rh_formacao_remover'                         => ['module' => 'recursos-humanos', 'action' => 'gerir_formacoes'],
            'rh_funcionario_formacao_save'                => ['module' => 'recursos-humanos', 'action' => 'gerir_formacoes'],
            'rh_funcionario_formacao_editar'              => ['module' => 'recursos-humanos', 'action' => 'gerir_formacoes'],
            'rh_funcionario_formacao_remover'             => ['module' => 'recursos-humanos', 'action' => 'gerir_formacoes'],

            // ── Benefícios ────────────────────────────────────────────────────────
            'rh_beneficio_save'                           => ['module' => 'recursos-humanos', 'action' => 'gerir_beneficios'],
            'rh_beneficio_remover'                        => ['module' => 'recursos-humanos', 'action' => 'gerir_beneficios'],
            'rh_funcionario_beneficio_save'               => ['module' => 'recursos-humanos', 'action' => 'gerir_beneficios'],
            'rh_funcionario_beneficio_remover'            => ['module' => 'recursos-humanos', 'action' => 'gerir_beneficios'],

            // ── Gateway de operações RH ───────────────────────────────────────────
            'rh_operacao'                                 => ['module' => 'recursos-humanos', 'action' => 'gerir_funcionarios'],
        ];
    }
}
