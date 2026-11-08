<?php
// Mapa de módulos: cor, nome, funcionalidades reais da API.
// Cada 'acoes' é um array  funcionalidade_chave => 'Label legível'
// Estes valores são usados na grelha de permissões e no kernel da API.
// 'sem_atribuicao' → não aparece na grelha (gerido internamente).
//
// Só estão aqui os módulos que o backend escolar ainda tem. As acções de
// 'gestao-escolar' são as que o backend verifica nas rotas /api/escolar
// (mw.RequirePermission em internal/router/router.go).
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

    'gestao-escolar' => [
        'nome'  => 'Gestão Escolar',
        'cor'   => '#0D9488',
        'acoes' => [
            'ver'               => 'Ver Dados Escolares',
            'relatorios'        => 'Relatórios Escolares',
            'gerir_turmas'      => 'Gestão Académica (Anos, Turmas, Disciplinas, Professores)',
            'gerir_alunos'      => 'Gerir Alunos & Encarregados',
            'gerir_matriculas'  => 'Gerir Matrículas',
            'gerir_presencas'   => 'Frequência & Presenças',
            'lancar_notas'      => 'Notas, Avaliações & Tarefas',
            'gerir_propinas'    => 'Propinas, Cobranças & Pagamentos',
            'gerir_biblioteca'  => 'Biblioteca & Empréstimos',
            'gerir_comunicacao' => 'Comunicação',
            'gerir_horarios'    => 'Horários',
            'gerir_calendario'  => 'Calendário Escolar',
            'gerir_ocorrencias' => 'Ocorrências, Sanções & Méritos',
            'portal_aluno'      => 'Portal do Aluno e do Encarregado',
        ],
    ],

];
