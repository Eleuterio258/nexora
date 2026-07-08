<?php
declare (strict_types = 1);

namespace E258Tech\Routing\Api;

final class CrmRecrutamentoApiRoutes
{
    public static function endpoints(): array
    {
        return [
            // ── CRM ───────────────────────────────────────────────────────────────
            'lead_save'                        => ['module' => 'crm', 'action' => 'gerir_leads'],
            'lead_mover'                       => ['module' => 'crm', 'action' => 'mover_leads'],
            'lead_delete'                      => ['module' => 'crm', 'action' => 'eliminar_leads'],
            'lead_converter'                   => ['module' => 'crm', 'action' => 'converter_leads'],
            'oportunidade_save'                => ['module' => 'crm', 'action' => 'gerir_oportunidades'],
            'oportunidade_mover'               => ['module' => 'crm', 'action' => 'gerir_oportunidades'],
            'oportunidade_perder'              => ['module' => 'crm', 'action' => 'gerir_oportunidades'],
            'oportunidade_delete'              => ['module' => 'crm', 'action' => 'gerir_oportunidades'],
            'atividade_save'                   => ['module' => 'crm', 'action' => 'gerir_atividades'],
            'atividade_concluir'               => ['module' => 'crm', 'action' => 'gerir_atividades'],

            // ── Recrutamento ──────────────────────────────────────────────────────
            'vaga_save'                        => ['module' => 'recrutamento', 'action' => 'gerir_vagas'],
            'vaga_toggle'                      => ['module' => 'recrutamento', 'action' => 'gerir_vagas'],
            'vaga_delete'                      => ['module' => 'recrutamento', 'action' => 'gerir_vagas'],
            'candidatura_mover'                => ['module' => 'recrutamento', 'action' => 'gerir_pipeline'],
            'candidatura_avaliar'              => ['module' => 'recrutamento', 'action' => 'avaliar_candidatos'],
            'entrevista_save'                  => ['module' => 'recrutamento', 'action' => 'avaliar_candidatos'],
            'nota_save'                        => ['module' => 'recrutamento', 'action' => 'avaliar_candidatos'],
            'recrutamento_campo_custom_save'   => ['module' => 'recrutamento', 'action' => 'configurar_recrutamento'],
            'recrutamento_campo_custom_delete' => ['module' => 'recrutamento', 'action' => 'configurar_recrutamento'],
            'recrutamento_notificacoes_save'   => ['module' => 'recrutamento', 'action' => 'configurar_recrutamento'],
            'recrutamento_contacto_lido'       => ['module' => 'recrutamento', 'action' => 'gerir_candidaturas'],
            'candidatura_contratar'            => ['module' => 'recrutamento', 'action' => 'gerir_candidaturas'],
        ];
    }
}
