<?php
declare(strict_types=1);

namespace E258Tech\Routing;

use InvalidArgumentException;

final class AdminApiRoutes
{
    // Cada entrada: module → módulo, action → funcionalidade real do módulo.
    // A action deve existir nas 'acoes' do módulo em modules.php.
    // action='' → qualquer utilizador autenticado pode chamar (sem verificação de funcionalidade).
    private const ENDPOINTS = [

        // ── Self-service ──────────────────────────────────────────────────────
        'pedido_ferias_criar'        => ['module' => 'pedido-ferias', 'action' => ''],
        'pedido_ferias_cancelar'     => ['module' => 'pedido-ferias', 'action' => ''],
        'self_service_chat_conversas' => ['module' => 'chat', 'action' => '',   'method' => 'GET'],
        'self_service_chat_criar'     => ['module' => 'chat', 'action' => ''],
        'self_service_chat_mensagens' => ['module' => 'chat', 'action' => '',   'method' => 'GET'],
        'self_service_chat_enviar'    => ['module' => 'chat', 'action' => ''],
        'self_service_justificacao'   => ['module' => 'assiduidade', 'action' => ''],
        'self_service_perfil_update'  => ['module' => 'perfil', 'action' => ''],
        'self_service_senha'          => ['module' => 'perfil', 'action' => ''],
        'self_service_utilizadores'   => ['module' => 'chat', 'action' => '',   'method' => 'GET'],

        // ── Autorização (IT admin) ────────────────────────────────────────────
        'utilizador_tipo'           => ['module' => 'autorizacao', 'action' => 'gerir_utilizadores'],
        'utilizador_reset_password' => ['module' => 'autorizacao', 'action' => 'gerir_utilizadores'],
        'cargo_estado'              => ['module' => 'autorizacao', 'action' => 'gerir_perfis'],
        'cargo_permissoes'          => ['module' => 'autorizacao', 'action' => 'gerir_permissoes'],
        'cargo_permissoes_get'      => ['module' => 'autorizacao', 'action' => 'gerir_permissoes', 'method' => 'GET'],
        'cargo_save'                => ['module' => 'autorizacao', 'action' => 'gerir_perfis'],
        'utilizador_cargo'          => ['module' => 'autorizacao', 'action' => 'gerir_utilizadores'],
        'utilizador_estado'         => ['module' => 'autorizacao', 'action' => 'gerir_utilizadores'],
        'utilizador_permissoes'     => ['module' => 'autorizacao', 'action' => 'gerir_permissoes'],
        'utilizador_save'           => ['module' => 'autorizacao', 'action' => 'gerir_utilizadores'],

        // ── Sessões (Auth) ────────────────────────────────────────────────────
        'sessao_revogar' => ['module' => 'auth', 'action' => 'ver_sessoes'],

        // ── Empresa ───────────────────────────────────────────────────────────
        'empresa_save'        => ['module' => 'empresa', 'action' => 'editar_empresa'],
        'empresa_fiscal_save' => ['module' => 'empresa', 'action' => 'editar_empresa'],
        'empresa_branch_save' => ['module' => 'empresa', 'action' => 'gerir_filiais'],
        'empresa_licenca_save' => ['module' => 'empresa', 'action' => 'gerir_licencas'],

        // ── Clientes ──────────────────────────────────────────────────────────
        'cliente_save'             => ['module' => 'clientes', 'action' => 'gerir_clientes'],
        'cliente_estado'           => ['module' => 'clientes', 'action' => 'gerir_clientes'],
        'cliente_contacto_save'    => ['module' => 'clientes', 'action' => 'gerir_clientes'],
        'cliente_contacto_delete'  => ['module' => 'clientes', 'action' => 'gerir_clientes'],
        'cliente_endereco_save'    => ['module' => 'clientes', 'action' => 'gerir_clientes'],
        'cliente_endereco_delete'  => ['module' => 'clientes', 'action' => 'gerir_clientes'],
        'cliente_pagamento_save'   => ['module' => 'clientes', 'action' => 'gerir_clientes'],
        'cliente_grupo_save'       => ['module' => 'clientes', 'action' => 'gerir_grupos'],
        'cliente_credito_save'     => ['module' => 'clientes', 'action' => 'gerir_credito'],

        // ── Faturação ─────────────────────────────────────────────────────────
        'serie_save'           => ['module' => 'faturacao', 'action' => 'configurar_series'],
        'serie_estado'         => ['module' => 'faturacao', 'action' => 'configurar_series'],
        'orcamento_save'       => ['module' => 'faturacao', 'action' => 'emitir_orcamentos'],
        'orcamento_item_save'  => ['module' => 'faturacao', 'action' => 'emitir_orcamentos'],
        'orcamento_item_delete' => ['module' => 'faturacao', 'action' => 'emitir_orcamentos'],
        'orcamento_estado'     => ['module' => 'faturacao', 'action' => 'emitir_orcamentos'],
        'encomenda_save'       => ['module' => 'faturacao', 'action' => 'emitir_encomendas'],
        'encomenda_estado'     => ['module' => 'faturacao', 'action' => 'emitir_encomendas'],
        'fatura_save'          => ['module' => 'faturacao', 'action' => 'emitir_faturas'],
        'fatura_item_save'     => ['module' => 'faturacao', 'action' => 'emitir_faturas'],
        'fatura_estado'        => ['module' => 'faturacao', 'action' => 'emitir_faturas'],
        'recibo_save'          => ['module' => 'faturacao', 'action' => 'emitir_faturas'],
        'nota_credito_save'    => ['module' => 'faturacao', 'action' => 'emitir_notas_credito'],

        // ── POS ───────────────────────────────────────────────────────────────
        'pos_sessao_abrir'   => ['module' => 'pos', 'action' => 'operar_pos'],
        'pos_sessao_fechar'  => ['module' => 'pos', 'action' => 'operar_pos'],
        'pos_venda_save'     => ['module' => 'pos', 'action' => 'operar_pos'],
        'pos_venda_cancelar' => ['module' => 'pos', 'action' => 'ver_vendas'],
        'pos_produtos_buscar' => ['module' => 'pos', 'action' => 'operar_pos', 'method' => 'GET'],
        'pos_terminal_save'  => ['module' => 'pos', 'action' => 'gerir_terminais'],
        'pos_catalogo_save'  => ['module' => 'pos', 'action' => 'gerir_catalogo'],
        'pos_catalogo_remove' => ['module' => 'pos', 'action' => 'gerir_catalogo'],

        // ── Stock & Produtos ──────────────────────────────────────────────────
        'produto_save'            => ['module' => 'stock', 'action' => 'gerir_produtos'],
        'produto_preco_save'      => ['module' => 'stock', 'action' => 'gerir_produtos'],
        'produto_variante_save'   => ['module' => 'stock', 'action' => 'gerir_produtos'],
        'produto_unidade_save'    => ['module' => 'stock', 'action' => 'gerir_produtos'],
        'produto_categoria_save'  => ['module' => 'stock', 'action' => 'gerir_categorias'],
        'produto_categoria_remover' => ['module' => 'stock', 'action' => 'gerir_categorias'],
        'produto_marca_save'      => ['module' => 'stock', 'action' => 'gerir_categorias'],
        'stock_operacao'          => ['module' => 'stock', 'action' => 'gerir_movimentos'],

        // ── Compras ───────────────────────────────────────────────────────────
        'compra_documento_save' => ['module' => 'compras', 'action' => 'criar_pedidos'],
        'compra_item_save'      => ['module' => 'compras', 'action' => 'criar_pedidos'],

        // ── Logística ─────────────────────────────────────────────────────────
        'logistica_operacao' => ['module' => 'logistica', 'action' => 'gerir_entregas'],

        // ── Financeiro ────────────────────────────────────────────────────────
        'financeiro_operacao' => ['module' => 'financeiro', 'action' => 'gerir_contas_receber'],

        // ── Tesouraria ────────────────────────────────────────────────────────
        'tesouraria_operacao' => ['module' => 'tesouraria', 'action' => 'gerir_movimentos'],

        // ── Contabilidade ─────────────────────────────────────────────────────
        'contab_conta_save'              => ['module' => 'contabilidade', 'action' => 'gerir_plano_contas'],
        'contab_conta_remover'           => ['module' => 'contabilidade', 'action' => 'gerir_plano_contas'],
        'contab_tipo_conta_save'         => ['module' => 'contabilidade', 'action' => 'gerir_plano_contas'],
        'contab_tipo_conta_remover'      => ['module' => 'contabilidade', 'action' => 'gerir_plano_contas'],
        'contab_ano_fiscal_save'         => ['module' => 'contabilidade', 'action' => 'gerir_periodos'],
        'contab_periodo_abrir'           => ['module' => 'contabilidade', 'action' => 'gerir_periodos'],
        'contab_diario_save'             => ['module' => 'contabilidade', 'action' => 'gerir_lancamentos'],
        'contab_lancamento_save'         => ['module' => 'contabilidade', 'action' => 'gerir_lancamentos'],
        'contab_lancamento_linha_save'   => ['module' => 'contabilidade', 'action' => 'gerir_lancamentos'],
        'contab_lancamento_estornar'     => ['module' => 'contabilidade', 'action' => 'gerir_lancamentos'],
        'contab_taxa_save'               => ['module' => 'contabilidade', 'action' => 'gerir_lancamentos'],
        'contab_regra_taxa_save'         => ['module' => 'contabilidade', 'action' => 'gerir_lancamentos'],
        'contab_grupo_imposto_save'      => ['module' => 'contabilidade', 'action' => 'gerir_lancamentos'],
        'contab_transacao_imposto_save'  => ['module' => 'contabilidade', 'action' => 'gerir_lancamentos'],
        'contab_ativo_fixo_save'         => ['module' => 'contabilidade', 'action' => 'gerir_ativos_fixos'],
        'contab_ativo_fixo_alienar'      => ['module' => 'contabilidade', 'action' => 'gerir_ativos_fixos'],
        'contab_amortizacao_processar'   => ['module' => 'contabilidade', 'action' => 'gerir_ativos_fixos'],
        'contab_amortizacao_cancelar'    => ['module' => 'contabilidade', 'action' => 'gerir_ativos_fixos'],
        'contab_orcamento_save'          => ['module' => 'contabilidade', 'action' => 'gerir_orcamentos'],
        'contab_orcamento_remover'       => ['module' => 'contabilidade', 'action' => 'gerir_orcamentos'],
        'contab_ano_fiscal_fechar'       => ['module' => 'contabilidade', 'action' => 'fechar_periodo'],
        'contab_periodo_fechar'          => ['module' => 'contabilidade', 'action' => 'fechar_periodo'],
        'contab_encerramento_iniciar'    => ['module' => 'contabilidade', 'action' => 'fechar_periodo'],
        'contab_encerramento_verificar'  => ['module' => 'contabilidade', 'action' => 'fechar_periodo'],
        'contab_encerramento_confirmar'  => ['module' => 'contabilidade', 'action' => 'fechar_periodo'],
        'contab_encerramento_reabrir'    => ['module' => 'contabilidade', 'action' => 'fechar_periodo'],
        'contab_relatorio_gerar'         => ['module' => 'contabilidade', 'action' => 'ver_relatorios'],

        // ── Impostos ──────────────────────────────────────────────────────────
        'imposto_operacao' => ['module' => 'impostos', 'action' => 'gerir_impostos'],

        // ── Multi-Moeda ───────────────────────────────────────────────────────
        'multi_moeda_operacao' => ['module' => 'multi-moeda', 'action' => 'gerir_moedas'],

        // ── Centros de Custo ──────────────────────────────────────────────────
        'centros_custo_centro_save'      => ['module' => 'centros-custo', 'action' => 'gerir_centros'],
        'centros_custo_centro_remover'   => ['module' => 'centros-custo', 'action' => 'eliminar_centros'],
        'centros_custo_orcamento_save'   => ['module' => 'centros-custo', 'action' => 'gerir_orcamentos'],
        'centros_custo_orcamento_remover' => ['module' => 'centros-custo', 'action' => 'gerir_orcamentos'],
        'centros_custo_alocacao_save'    => ['module' => 'centros-custo', 'action' => 'gerir_alocacoes'],

        // ── Recursos Humanos ──────────────────────────────────────────────────
        // Gestão de funcionários
        'rh_funcionario_save'                      => ['module' => 'recursos-humanos', 'action' => 'gerir_funcionarios'],
        'rh_funcionario_desligar'                  => ['module' => 'recursos-humanos', 'action' => 'gerir_funcionarios'],
        'rh_ausencia_save'                         => ['module' => 'recursos-humanos', 'action' => 'gerir_funcionarios'],
        'rh_funcionario_presenca_save'             => ['module' => 'recursos-humanos', 'action' => 'gerir_funcionarios'],
        'rh_funcionario_presenca_remover'          => ['module' => 'recursos-humanos', 'action' => 'gerir_funcionarios'],
        'rh_documento_save'                        => ['module' => 'recursos-humanos', 'action' => 'gerir_funcionarios'],
        'rh_documento_remover'                     => ['module' => 'recursos-humanos', 'action' => 'gerir_funcionarios'],
        'rh_documento_ficheiro'                    => ['module' => 'recursos-humanos', 'action' => 'ver_funcionarios', 'method' => 'GET'],
        'rh_contacto_emergencia_save'              => ['module' => 'recursos-humanos', 'action' => 'gerir_funcionarios'],
        'rh_contacto_emergencia_remover'           => ['module' => 'recursos-humanos', 'action' => 'gerir_funcionarios'],
        'rh_cargo_save'                            => ['module' => 'recursos-humanos', 'action' => 'gerir_funcionarios'],
        'rh_cargo_remover'                         => ['module' => 'recursos-humanos', 'action' => 'gerir_funcionarios'],
        'rh_unidade_save'                          => ['module' => 'recursos-humanos', 'action' => 'gerir_funcionarios'],
        'rh_unidade_mover'                         => ['module' => 'recursos-humanos', 'action' => 'gerir_funcionarios'],
        'rh_unidade_remover'                       => ['module' => 'recursos-humanos', 'action' => 'gerir_funcionarios'],
        'rh_tipo_ausencia_save'                    => ['module' => 'recursos-humanos', 'action' => 'gerir_funcionarios'],
        'rh_tipo_ausencia_remover'                 => ['module' => 'recursos-humanos', 'action' => 'gerir_funcionarios'],
        'rh_funcionario_processo_disciplinar_save'    => ['module' => 'recursos-humanos', 'action' => 'gerir_funcionarios'],
        'rh_funcionario_processo_disciplinar_editar'  => ['module' => 'recursos-humanos', 'action' => 'gerir_funcionarios'],
        'rh_funcionario_processo_disciplinar_remover' => ['module' => 'recursos-humanos', 'action' => 'gerir_funcionarios'],
        'rh_funcionario_saldo_ausencia_save'       => ['module' => 'recursos-humanos', 'action' => 'aprovar_ausencias'],
        // Contratos
        'rh_contrato_save'        => ['module' => 'recursos-humanos', 'action' => 'gerir_contratos'],
        'rh_contrato_renovar'     => ['module' => 'recursos-humanos', 'action' => 'gerir_contratos'],
        'rh_contrato_rescindir'   => ['module' => 'recursos-humanos', 'action' => 'gerir_contratos'],
        'rh_contrato_ficheiro'    => ['module' => 'recursos-humanos', 'action' => 'gerir_contratos', 'method' => 'GET'],
        // Horários
        'rh_horario_save'         => ['module' => 'recursos-humanos', 'action' => 'gerir_horarios'],
        'rh_horario_remover'      => ['module' => 'recursos-humanos', 'action' => 'gerir_horarios'],
        // Aprovação de ausências
        'rh_ausencia_aprovar'     => ['module' => 'recursos-humanos', 'action' => 'aprovar_ausencias'],
        'rh_ausencia_rejeitar'    => ['module' => 'recursos-humanos', 'action' => 'aprovar_ausencias'],
        'rh_ausencia_gozar'       => ['module' => 'recursos-humanos', 'action' => 'aprovar_ausencias'],
        'rh_ausencia_cancelar'    => ['module' => 'recursos-humanos', 'action' => 'aprovar_ausencias'],
        // Processamento salarial
        'rh_folha_pagamento_save'      => ['module' => 'recursos-humanos', 'action' => 'processar_salarios'],
        'rh_folha_pagamento_processar' => ['module' => 'recursos-humanos', 'action' => 'processar_salarios'],
        'rh_folha_pagamento_pagar'     => ['module' => 'recursos-humanos', 'action' => 'processar_salarios'],
        'rh_folha_pagamento_cancelar'  => ['module' => 'recursos-humanos', 'action' => 'processar_salarios'],
        'rh_historico_salarial_save'   => ['module' => 'recursos-humanos', 'action' => 'processar_salarios'],
        'rh_componente_salarial_save'  => ['module' => 'recursos-humanos', 'action' => 'processar_salarios'],
        'rh_componente_salarial_remover' => ['module' => 'recursos-humanos', 'action' => 'processar_salarios'],
        'rh_funcionario_componente_save'   => ['module' => 'recursos-humanos', 'action' => 'processar_salarios'],
        'rh_funcionario_componente_remover' => ['module' => 'recursos-humanos', 'action' => 'processar_salarios'],
        'rh_periodo_save'       => ['module' => 'recursos-humanos', 'action' => 'processar_salarios'],
        'rh_periodo_encerrar'   => ['module' => 'recursos-humanos', 'action' => 'processar_salarios'],
        // Avaliações
        'rh_avaliacao_save'      => ['module' => 'recursos-humanos', 'action' => 'gerir_avaliacoes'],
        'rh_avaliacao_submeter'  => ['module' => 'recursos-humanos', 'action' => 'gerir_avaliacoes'],
        'rh_avaliacao_aprovar'   => ['module' => 'recursos-humanos', 'action' => 'gerir_avaliacoes'],
        'rh_criterio_avaliacao_save'    => ['module' => 'recursos-humanos', 'action' => 'gerir_avaliacoes'],
        'rh_criterio_avaliacao_remover' => ['module' => 'recursos-humanos', 'action' => 'gerir_avaliacoes'],
        // Formações
        'rh_formacao_save'               => ['module' => 'recursos-humanos', 'action' => 'gerir_formacoes'],
        'rh_formacao_remover'            => ['module' => 'recursos-humanos', 'action' => 'gerir_formacoes'],
        'rh_funcionario_formacao_save'   => ['module' => 'recursos-humanos', 'action' => 'gerir_formacoes'],
        'rh_funcionario_formacao_editar' => ['module' => 'recursos-humanos', 'action' => 'gerir_formacoes'],
        'rh_funcionario_formacao_remover' => ['module' => 'recursos-humanos', 'action' => 'gerir_formacoes'],
        // Benefícios
        'rh_beneficio_save'              => ['module' => 'recursos-humanos', 'action' => 'gerir_beneficios'],
        'rh_beneficio_remover'           => ['module' => 'recursos-humanos', 'action' => 'gerir_beneficios'],
        'rh_funcionario_beneficio_save'  => ['module' => 'recursos-humanos', 'action' => 'gerir_beneficios'],
        'rh_funcionario_beneficio_remover' => ['module' => 'recursos-humanos', 'action' => 'gerir_beneficios'],

        // ── CRM ───────────────────────────────────────────────────────────────
        'lead_save'           => ['module' => 'crm', 'action' => 'gerir_leads'],
        'lead_mover'          => ['module' => 'crm', 'action' => 'mover_leads'],
        'lead_delete'         => ['module' => 'crm', 'action' => 'eliminar_leads'],
        'lead_converter'      => ['module' => 'crm', 'action' => 'converter_leads'],
        'oportunidade_save'   => ['module' => 'crm', 'action' => 'gerir_oportunidades'],
        'oportunidade_mover'  => ['module' => 'crm', 'action' => 'gerir_oportunidades'],
        'oportunidade_perder' => ['module' => 'crm', 'action' => 'gerir_oportunidades'],
        'oportunidade_delete' => ['module' => 'crm', 'action' => 'gerir_oportunidades'],
        'atividade_save'      => ['module' => 'crm', 'action' => 'gerir_atividades'],
        'atividade_concluir'  => ['module' => 'crm', 'action' => 'gerir_atividades'],

        // ── Assinaturas ───────────────────────────────────────────────────────
        'assinaturas_operacao' => ['module' => 'assinaturas', 'action' => 'gerir_assinaturas'],

        // ── Gestão Escolar ────────────────────────────────────────────────────
        'escolar_operacao' => ['module' => 'gestao-escolar', 'action' => 'gerir_academico'],

        // ── Notificações ──────────────────────────────────────────────────────
        'notificacoes_operacao' => ['module' => 'notificacoes', 'action' => 'gerir_notificacoes'],

        // ── Segurança ─────────────────────────────────────────────────────────
        'seguranca_operacao' => ['module' => 'seguranca', 'action' => 'gerir_politicas'],

        // ── Sistema ───────────────────────────────────────────────────────────
        'sistema_setting_save'       => ['module' => 'sistema-configuracao', 'action' => 'editar_configuracoes'],
        'sistema_cidade_save'        => ['module' => 'sistema-configuracao', 'action' => 'editar_configuracoes'],
        'sistema_idioma_save'        => ['module' => 'sistema-configuracao', 'action' => 'editar_configuracoes'],
        'sistema_pais_save'          => ['module' => 'sistema-configuracao', 'action' => 'editar_configuracoes'],
        'sistema_moeda_save'         => ['module' => 'sistema-configuracao', 'action' => 'editar_configuracoes'],
        'sistema_taxa_cambio_save'   => ['module' => 'sistema-configuracao', 'action' => 'editar_configuracoes'],
        'sistema_email_template_save' => ['module' => 'sistema-configuracao', 'action' => 'gerir_templates'],
        'sistema_sms_template_save'  => ['module' => 'sistema-configuracao', 'action' => 'gerir_templates'],
        'sistema_integracao_save'    => ['module' => 'sistema-configuracao', 'action' => 'gerir_templates'],

        // ── Recrutamento ──────────────────────────────────────────────────────
        'vaga_save'           => ['module' => 'recrutamento', 'action' => 'gerir_vagas'],
        'vaga_toggle'         => ['module' => 'recrutamento', 'action' => 'gerir_vagas'],
        'vaga_delete'         => ['module' => 'recrutamento', 'action' => 'gerir_vagas'],
        'candidatura_mover'   => ['module' => 'recrutamento', 'action' => 'gerir_pipeline'],
        'candidatura_avaliar' => ['module' => 'recrutamento', 'action' => 'avaliar_candidatos'],
        'entrevista_save'     => ['module' => 'recrutamento', 'action' => 'avaliar_candidatos'],
        'nota_save'           => ['module' => 'recrutamento', 'action' => 'avaliar_candidatos'],
    ];

    public function definition(string $name): array
    {
        return self::ENDPOINTS[$name]
            ?? throw new InvalidArgumentException("Endpoint de API administrativo desconhecido: $name");
    }

    public function names(): array
    {
        return array_keys(self::ENDPOINTS);
    }

    public function path(string $name): string
    {
        $this->definition($name);
        return "/nexora/api/$name";
    }
}
