<?php
// Mapa de módulos: cor, nome, funcionalidades reais da API.
// Cada 'acoes' é um array  funcionalidade_chave => 'Label legível'
// Estes valores são usados na grelha de permissões e no kernel da API.
// 'sem_atribuicao' → não aparece na grelha (gerido internamente).
return [

    'auth' => [
        'nome'           => 'Autenticação',
        'cor'            => '#6366F1',
        'sem_atribuicao' => true,
        'acoes'          => ['ver_sessoes' => 'Ver Sessões'],
    ],

    'autorizacao' => [
        'nome'           => 'Autorização',
        'cor'            => '#F97316',
        'sem_atribuicao' => true,
        'acoes'          => [
            'gerir_perfis'      => 'Gerir Perfis de Acesso',
            'gerir_permissoes'  => 'Gerir Permissões',
            'gerir_utilizadores' => 'Gerir Utilizadores',
        ],
    ],

    'empresa' => [
        'nome'  => 'Empresa',
        'cor'   => '#2563EB',
        'acoes' => [
            'ver_empresa'     => 'Ver Informações da Empresa',
            'editar_empresa'  => 'Editar Empresa & Configurações Fiscais',
            'gerir_filiais'   => 'Gerir Filiais',
            'gerir_licencas'  => 'Gerir Licenças',
        ],
    ],

    'clientes' => [
        'nome'  => 'Clientes',
        'cor'   => '#8B5CF6',
        'acoes' => [
            'ver_clientes'    => 'Ver Clientes',
            'gerir_clientes'  => 'Criar & Editar Clientes',
            'gerir_grupos'    => 'Gerir Grupos de Clientes',
            'gerir_credito'   => 'Gerir Limites de Crédito',
            'eliminar_clientes' => 'Eliminar Clientes',
        ],
    ],

    'vendas' => [
        'nome'  => 'Vendas',
        'cor'   => '#3B82F6',
        'acoes' => [
            'ver_vendas'      => 'Ver Vendas',
            'criar_vendas'    => 'Registar Vendas',
            'cancelar_vendas' => 'Cancelar Vendas',
        ],
    ],

    'faturacao' => [
        'nome'  => 'Faturação',
        'cor'   => '#6366F1',
        'acoes' => [
            'ver_documentos'      => 'Ver Documentos',
            'emitir_orcamentos'   => 'Emitir Orçamentos',
            'emitir_encomendas'   => 'Emitir Encomendas',
            'emitir_faturas'      => 'Emitir Faturas',
            'emitir_notas_credito' => 'Emitir Notas de Crédito',
            'configurar_series'   => 'Configurar Séries de Faturação',
        ],
    ],

    'pos' => [
        'nome'  => 'POS',
        'cor'   => '#EF4444',
        'acoes' => [
            'operar_pos'      => 'Operar Terminal POS',
            'ver_vendas'      => 'Ver Vendas POS',
            'gerir_terminais' => 'Gerir Terminais',
            'gerir_catalogo'  => 'Gerir Catálogo POS',
        ],
    ],

    'stock' => [
        'nome'  => 'Stock',
        'cor'   => '#10B981',
        'acoes' => [
            'ver_stock'        => 'Ver Stock',
            'gerir_produtos'   => 'Criar & Editar Produtos',
            'gerir_categorias' => 'Gerir Categorias & Marcas',
            'gerir_movimentos' => 'Registar Movimentos de Stock',
            'eliminar_produtos' => 'Eliminar Produtos',
        ],
    ],

    'compras' => [
        'nome'  => 'Compras',
        'cor'   => '#F59E0B',
        'acoes' => [
            'ver_compras'      => 'Ver Compras',
            'criar_pedidos'    => 'Criar Pedidos de Compra',
            'aprovar_pedidos'  => 'Aprovar Pedidos de Compra',
            'gerir_itens'      => 'Gerir Itens de Compra',
        ],
    ],

    'logistica' => [
        'nome'  => 'Logística',
        'cor'   => '#84CC16',
        'acoes' => [
            'ver_logistica'   => 'Ver Logística',
            'gerir_entregas'  => 'Gerir Entregas & Expedições',
        ],
    ],

    'financeiro' => [
        'nome'  => 'Financeiro',
        'cor'   => '#14B8A6',
        'acoes' => [
            'ver_financeiro'         => 'Ver Financeiro',
            'gerir_contas_receber'   => 'Contas a Receber',
            'gerir_contas_pagar'     => 'Contas a Pagar',
            'gerir_categorias'       => 'Gerir Categorias Financeiras',
        ],
    ],

    'tesouraria' => [
        'nome'  => 'Tesouraria',
        'cor'   => '#059669',
        'acoes' => [
            'ver_tesouraria'      => 'Ver Tesouraria',
            'gerir_movimentos'    => 'Registar Movimentos',
            'gerir_reconciliacao' => 'Reconciliação Bancária',
        ],
    ],

    'contabilidade' => [
        'nome'  => 'Contabilidade',
        'cor'   => '#06B6D4',
        'acoes' => [
            'ver_contabilidade'   => 'Ver Contabilidade',
            'gerir_plano_contas'  => 'Plano de Contas',
            'gerir_lancamentos'   => 'Lançamentos Contabilísticos',
            'gerir_periodos'      => 'Anos & Períodos Fiscais',
            'gerir_ativos_fixos'  => 'Ativos Fixos & Amortizações',
            'gerir_orcamentos'    => 'Orçamentos Contabilísticos',
            'fechar_periodo'      => 'Encerramento de Período',
            'ver_relatorios'      => 'Relatórios Contabilísticos',
        ],
    ],

    'impostos' => [
        'nome'  => 'Impostos',
        'cor'   => '#EAB308',
        'acoes' => [
            'ver_impostos'   => 'Ver Impostos',
            'gerir_impostos' => 'Gerir Regras Fiscais',
        ],
    ],

    'multi-moeda' => [
        'nome'  => 'Multi-Moeda',
        'cor'   => '#D97706',
        'acoes' => [
            'ver_moedas'   => 'Ver Moedas',
            'gerir_moedas' => 'Gerir Moedas & Taxas de Câmbio',
        ],
    ],

    'centros-custo' => [
        'nome'  => 'Centros de Custo',
        'cor'   => '#78716C',
        'acoes' => [
            'ver_centros'        => 'Ver Centros de Custo',
            'gerir_centros'      => 'Criar & Editar Centros de Custo',
            'gerir_orcamentos'   => 'Orçamentos por Centro',
            'gerir_alocacoes'    => 'Alocações de Custo',
            'eliminar_centros'   => 'Eliminar Centros de Custo',
        ],
    ],

    'recursos-humanos' => [
        'nome'  => 'Recursos Humanos',
        'cor'   => '#EC4899',
        'acoes' => [
            'ver_funcionarios'   => 'Ver Funcionários',
            'gerir_funcionarios' => 'Criar & Editar Funcionários',
            'gerir_contratos'    => 'Gerir Contratos',
            'gerir_horarios'     => 'Gerir Horários de Trabalho',
            'aprovar_ausencias'  => 'Aprovar / Rejeitar Ausências',
            'processar_salarios' => 'Processamento Salarial',
            'gerir_avaliacoes'   => 'Avaliações de Desempenho',
            'gerir_formacoes'    => 'Formações',
            'gerir_beneficios'   => 'Benefícios',
            'ver_relatorios'     => 'Relatórios RH',
        ],
    ],

    'pedido-ferias' => [
        'nome'  => 'Pedido de Férias',
        'cor'   => '#F472B6',
        'acoes' => [
            'ver_pedidos'      => 'Ver os Meus Pedidos',
            'submeter_pedido'  => 'Submeter Pedido de Férias',
        ],
    ],

    'crm' => [
        'nome'  => 'CRM',
        'cor'   => '#A855F7',
        'acoes' => [
            'ver_leads'          => 'Ver Leads',
            'gerir_leads'        => 'Criar & Editar Leads',
            'mover_leads'        => 'Mover Leads no Pipeline',
            'converter_leads'    => 'Converter Leads',
            'eliminar_leads'     => 'Eliminar Leads',
            'ver_oportunidades'  => 'Ver Oportunidades',
            'gerir_oportunidades' => 'Criar & Gerir Oportunidades',
            'gerir_atividades'   => 'Registar Atividades CRM',
        ],
    ],

    'assinaturas' => [
        'nome'  => 'Assinaturas',
        'cor'   => '#9333EA',
        'acoes' => [
            'ver_assinaturas'   => 'Ver Assinaturas',
            'gerir_assinaturas' => 'Gerir Assinaturas & Planos',
        ],
    ],

    'gestao-escolar' => [
        'nome'  => 'Gestão Escolar',
        'cor'   => '#0D9488',
        'acoes' => [
            'ver_escolar'        => 'Ver Dados Escolares',
            'gerir_academico'    => 'Gestão Académica (Turmas, Disciplinas, Atribuições)',
            'gerir_alunos'       => 'Gerir Alunos & Matrículas',
            'gerir_avaliacoes'   => 'Notas & Avaliações',
            'gerir_frequencia'   => 'Frequência & Assiduidade',
            'gerir_biblioteca'   => 'Biblioteca & Empréstimos',
            'gerir_financeiro'   => 'Financeiro Escolar (Cobranças & Pagamentos)',
            'gerir_comunicacao'  => 'Comunicação',
            'ver_relatorios'     => 'Relatórios Escolares',
        ],
    ],

    'notificacoes' => [
        'nome'  => 'Notificações',
        'cor'   => '#0EA5E9',
        'acoes' => [
            'ver_notificacoes'   => 'Ver Notificações',
            'gerir_notificacoes' => 'Gerir Templates & Canais',
        ],
    ],

    'auditoria' => [
        'nome'  => 'Auditoria',
        'cor'   => '#64748B',
        'acoes' => [
            'ver_logs' => 'Ver Logs de Auditoria',
        ],
    ],

    'seguranca' => [
        'nome'  => 'Segurança',
        'cor'   => '#DC2626',
        'acoes' => [
            'ver_seguranca'    => 'Ver Configurações de Segurança',
            'gerir_politicas'  => 'Gerir Políticas de Segurança',
            'gerir_allowlist'  => 'Gerir IP Allowlist',
        ],
    ],

    'sistema-configuracao' => [
        'nome'  => 'Configuração do Sistema',
        'cor'   => '#475569',
        'acoes' => [
            'ver_configuracoes'   => 'Ver Configurações',
            'editar_configuracoes' => 'Editar Configurações Gerais',
            'gerir_templates'     => 'Gerir Templates & Integrações',
            'ver_logs_sistema'    => 'Ver Logs do Sistema',
        ],
    ],

    'recrutamento' => [
        'nome'  => 'Recrutamento',
        'cor'   => '#16A34A',
        'acoes' => [
            'ver_vagas'           => 'Ver Vagas',
            'gerir_vagas'         => 'Criar & Editar Vagas',
            'ver_candidaturas'    => 'Ver Candidaturas',
            'gerir_candidaturas'  => 'Gerir Candidaturas',
            'gerir_pipeline'      => 'Mover no Pipeline de Seleção',
            'avaliar_candidatos'  => 'Avaliar & Entrevistar Candidatos',
            'ver_relatorios'      => 'Relatórios de Recrutamento',
        ],
    ],

    // ── Self-Service Portal (funcionários) ────────────────────────────────────

    'home' => [
        'nome'  => 'Home / Dashboard',
        'cor'   => '#0EA5E9',
        'acoes' => [
            'ver_dashboard' => 'Ver Dashboard Inicial',
        ],
    ],

    'chat' => [
        'nome'  => 'Chat Interno',
        'cor'   => '#10B981',
        'acoes' => [
            'ver_conversas'   => 'Ver Conversas',
            'enviar_mensagem' => 'Enviar Mensagens',
        ],
    ],

    'assiduidade' => [
        'nome'  => 'Assiduidade',
        'cor'   => '#F59E0B',
        'acoes' => [
            'ver_assiduidade' => 'Consultar Registos de Assiduidade',
            'justificar'      => 'Submeter Justificações',
        ],
    ],

    'perfil' => [
        'nome'  => 'Perfil',
        'cor'   => '#8B5CF6',
        'acoes' => [
            'ver_perfil'   => 'Ver Perfil',
            'editar_perfil' => 'Editar Dados Pessoais & Senha',
        ],
    ],

];
