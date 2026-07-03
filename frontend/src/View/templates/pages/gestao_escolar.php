<?php
declare(strict_types=1);

$pageTitle = 'Gestão Escolar';
$activePage = 'gestao_escolar';
$breadcrumb = [['Admin', '/nexora/'], ['Gestão Escolar', '']];

// Paginação por recurso: ?cp=2 (classes), ?sp=2 (students), ?ip=2 (invoices), ?ap=2 (attendance)
$_cp = max(1, (int)($_GET['cp'] ?? 1));
$_sp = max(1, (int)($_GET['sp'] ?? 1));
$_ip = max(1, (int)($_GET['ip'] ?? 1));
$_ap = max(1, (int)($_GET['ap'] ?? 1));
$_turno = in_array($_GET['turno'] ?? '', ['manha','tarde','noite'], true) ? $_GET['turno'] : '';

$workspace = [
    'title' => 'Gestão Escolar',
    'subtitle' => 'Administração académica, alunos, finanças, biblioteca e comunicação.',
    'endpoint' => '/nexora/api/escolar_operacao',
    'resources' => [
        'dashboard' => [
            'label' => 'Dashboard', 'path' => '/api/escolar/dashboard/direction',
            'columns' => [['nome|indicador', 'Indicador'], ['valor|total', 'Valor']],
            'description' => 'Indicadores da direção escolar.',
        ],
        'years' => [
            'label' => 'Anos lectivos', 'path' => '/api/escolar/years',
            'columns' => [['nome|codigo', 'Ano'], ['data_inicio|inicio', 'Início'], ['data_fim|fim', 'Fim'], ['status|ativo', 'Estado']],
            'create' => ['operation' => 'year.create', 'label' => 'Novo ano lectivo', 'fields' => [
                ['name' => 'nome', 'label' => 'Nome', 'required' => true],
                ['name' => 'data_inicio', 'label' => 'Início', 'type' => 'date', 'required' => true],
                ['name' => 'data_fim', 'label' => 'Fim', 'type' => 'date', 'required' => true],
            ]],
            'actions' => [
                ['operation' => 'year.view', 'label' => 'Detalhes', 'result' => true],
                ['operation' => 'year.update', 'label' => 'Actualizar', 'fields' => [
                    ['name' => 'nome', 'label' => 'Nome', 'required' => true],
                    ['name' => 'data_inicio', 'label' => 'Início', 'type' => 'date', 'required' => true],
                    ['name' => 'data_fim', 'label' => 'Fim', 'type' => 'date', 'required' => true],
                ]],
                ['operation' => 'term.create', 'label' => 'Novo período', 'fields' => [
                    ['name' => 'nome', 'label' => 'Nome do período', 'required' => true],
                    ['name' => 'data_inicio', 'label' => 'Início', 'type' => 'date', 'required' => true],
                    ['name' => 'data_fim', 'label' => 'Fim', 'type' => 'date', 'required' => true],
                ]],
                ['operation' => 'year.activate', 'label' => 'Activar'],
                ['operation' => 'year.close', 'label' => 'Encerrar', 'confirm' => 'Encerrar este ano lectivo?'],
            ],
        ],
        'classes' => [
            'label' => 'Turmas',
            'path' => '/api/escolar/classes?' . http_build_query(array_filter(['pagina' => $_cp, 'por_pagina' => 25, 'turno' => $_turno])),
            'pagina_param' => 'cp',
            'filters' => [
                ['name' => 'turno', 'label' => 'Turno', 'options' => ['' => 'Todos', 'manha' => 'Manhã', 'tarde' => 'Tarde', 'noite' => 'Noite'], 'current' => $_turno],
            ],
            'columns' => [['codigo|id', 'Código'], ['nome', 'Turma'], ['nivel|classe', 'Nível'], ['turno', 'Turno'], ['teacher_name|professor_id', 'Director'], ['status', 'Estado']],
            'create' => ['operation' => 'class.create', 'label' => 'Nova turma', 'fields' => [
                ['name' => 'school_year_id', 'label' => 'ID do ano lectivo', 'type' => 'number', 'required' => true],
                ['name' => 'nome', 'label' => 'Nome', 'required' => true],
                ['name' => 'nivel', 'label' => 'Nível/classe', 'required' => true],
                ['name' => 'turno', 'label' => 'Turno', 'type' => 'select', 'options' => ['manha', 'tarde', 'noite'], 'required' => true],
                ['name' => 'capacidade', 'label' => 'Capacidade', 'type' => 'number'],
            ]],
            'actions' => [
                ['operation' => 'class.view', 'label' => 'Detalhes', 'result' => true],
                ['operation' => 'class.update', 'label' => 'Actualizar', 'fields' => [
                    ['name' => 'school_year_id', 'label' => 'ID do ano lectivo', 'type' => 'number', 'required' => true],
                    ['name' => 'nome', 'label' => 'Nome', 'required' => true],
                    ['name' => 'nivel', 'label' => 'Nível/classe', 'required' => true],
                    ['name' => 'turno', 'label' => 'Turno', 'type' => 'select', 'options' => ['manha', 'tarde', 'noite'], 'required' => true],
                    ['name' => 'capacidade', 'label' => 'Capacidade', 'type' => 'number'],
                ]],
                ['operation' => 'class.teacher', 'label' => 'Associar director', 'fields' => [
                    ['name' => 'teacher_id', 'label' => 'ID do professor', 'type' => 'number', 'required' => true],
                ]],
            ],
        ],
        'subjects' => [
            'label' => 'Disciplinas', 'path' => '/api/escolar/subjects',
            'columns' => [['codigo|id', 'Código'], ['nome', 'Disciplina'], ['carga_horaria', 'Carga horária'], ['status|ativo', 'Estado']],
            'create' => ['operation' => 'subject.create', 'label' => 'Nova disciplina', 'fields' => [
                ['name' => 'codigo', 'label' => 'Código', 'required' => true],
                ['name' => 'nome', 'label' => 'Nome', 'required' => true],
                ['name' => 'carga_horaria', 'label' => 'Carga horária', 'type' => 'number'],
            ]],
        ],
        'teacher_assignments' => [
            'label' => 'Atribuições', 'path' => null,
            'description' => 'Associe professores a turmas e disciplinas.',
            'create' => ['operation' => 'teacher.assignment.create', 'label' => 'Atribuir professor', 'fields' => [
                ['name' => 'teacher_id', 'label' => 'ID do professor', 'type' => 'number', 'required' => true],
                ['name' => 'class_id', 'label' => 'ID da turma', 'type' => 'number', 'required' => true],
                ['name' => 'subject_id', 'label' => 'ID da disciplina', 'type' => 'number', 'required' => true],
            ]],
        ],
        'students' => [
            'label' => 'Alunos',
            'path' => '/api/escolar/students?pagina=' . $_sp . '&por_pagina=25',
            'pagina_param' => 'sp',
            'columns' => [['numero|codigo|id', 'Número'], ['nome', 'Nome'], ['data_nascimento', 'Nascimento'], ['sexo', 'Sexo'], ['status', 'Estado']],
            'create' => ['operation' => 'student.create', 'label' => 'Novo aluno', 'fields' => [
                ['name' => 'nome', 'label' => 'Nome completo', 'required' => true],
                ['name' => 'data_nascimento', 'label' => 'Data de nascimento', 'type' => 'date', 'required' => true],
                ['name' => 'sexo', 'label' => 'Sexo', 'type' => 'select', 'options' => ['M', 'F'], 'required' => true],
                ['name' => 'documento', 'label' => 'Documento'],
                ['name' => 'contacto', 'label' => 'Contacto'],
            ]],
            'actions' => [
                ['operation' => 'student.view', 'label' => 'Detalhes', 'result' => true],
                ['operation' => 'student.update', 'label' => 'Actualizar', 'fields' => [
                    ['name' => 'nome', 'label' => 'Nome completo', 'required' => true],
                    ['name' => 'data_nascimento', 'label' => 'Data de nascimento', 'type' => 'date', 'required' => true],
                    ['name' => 'sexo', 'label' => 'Sexo', 'type' => 'select', 'options' => ['M', 'F'], 'required' => true],
                    ['name' => 'documento', 'label' => 'Documento'],
                    ['name' => 'contacto', 'label' => 'Contacto'],
                ]],
                ['operation' => 'guardian.create', 'label' => 'Adicionar encarregado', 'fields' => [
                    ['name' => 'nome', 'label' => 'Nome', 'required' => true],
                    ['name' => 'parentesco', 'label' => 'Parentesco', 'required' => true],
                    ['name' => 'contacto', 'label' => 'Contacto', 'required' => true],
                    ['name' => 'email', 'label' => 'Email', 'type' => 'email'],
                ]],
            ],
        ],
        'enrollments' => [
            'label' => 'Matrículas', 'path' => null,
            'description' => 'Matrícula, rematrícula, consulta, transferência e cancelamento.',
            'create' => ['operation' => 'enrollment.create', 'label' => 'Nova matrícula', 'fields' => [
                ['name' => 'student_id', 'label' => 'ID do aluno', 'type' => 'number', 'required' => true],
                ['name' => 'class_id', 'label' => 'ID da turma', 'type' => 'number', 'required' => true],
                ['name' => 'school_year_id', 'label' => 'ID do ano lectivo', 'type' => 'number', 'required' => true],
                ['name' => 'data_matricula', 'label' => 'Data da matrícula', 'type' => 'date', 'required' => true],
            ]],
            'tools' => [
                ['operation' => 'enrollment.view', 'label' => 'Consultar matrícula', 'result' => true, 'fields' => [
                    ['name' => '_id', 'label' => 'ID da matrícula', 'type' => 'number', 'required' => true],
                ]],
                ['operation' => 'enrollment.transfer', 'label' => 'Transferir aluno', 'fields' => [
                    ['name' => '_id', 'label' => 'ID da matrícula', 'type' => 'number', 'required' => true],
                    ['name' => 'class_id', 'label' => 'ID da nova turma', 'type' => 'number', 'required' => true],
                    ['name' => 'motivo', 'label' => 'Motivo', 'type' => 'textarea'],
                ]],
                ['operation' => 'enrollment.cancel', 'label' => 'Cancelar matrícula', 'fields' => [
                    ['name' => '_id', 'label' => 'ID da matrícula', 'type' => 'number', 'required' => true],
                    ['name' => 'motivo', 'label' => 'Motivo', 'type' => 'textarea', 'required' => true],
                ]],
            ],
        ],
        'student_roles' => [
            'label' => 'Cargos de alunos', 'path' => '/api/escolar/student-roles',
            'columns' => [['student_name|student_id', 'Aluno'], ['role|cargo', 'Cargo'], ['inicio|data_inicio', 'Início'], ['fim|data_fim', 'Fim'], ['status', 'Estado']],
            'create' => ['operation' => 'student.role.create', 'label' => 'Atribuir cargo', 'fields' => [
                ['name' => 'student_id', 'label' => 'ID do aluno', 'type' => 'number', 'required' => true],
                ['name' => 'cargo', 'label' => 'Cargo', 'required' => true],
                ['name' => 'data_inicio', 'label' => 'Início', 'type' => 'date', 'required' => true],
                ['name' => 'data_fim', 'label' => 'Fim', 'type' => 'date'],
            ]],
            'actions' => [
                ['operation' => 'student.role.update', 'label' => 'Actualizar vigência', 'fields' => [
                    ['name' => 'data_inicio', 'label' => 'Início', 'type' => 'date', 'required' => true],
                    ['name' => 'data_fim', 'label' => 'Fim', 'type' => 'date'],
                ]],
                ['operation' => 'student.role.revoke', 'label' => 'Revogar', 'confirm' => 'Revogar este cargo?'],
            ],
        ],
        'teacher_roles' => [
            'label' => 'Cargos de professores', 'path' => '/api/escolar/teacher-roles',
            'columns' => [['teacher_name|teacher_id', 'Professor'], ['role|cargo', 'Cargo'], ['inicio|data_inicio', 'Início'], ['fim|data_fim', 'Fim'], ['status', 'Estado']],
            'create' => ['operation' => 'teacher.role.create', 'label' => 'Atribuir cargo', 'fields' => [
                ['name' => 'teacher_id', 'label' => 'ID do professor', 'type' => 'number', 'required' => true],
                ['name' => 'cargo', 'label' => 'Cargo', 'required' => true],
                ['name' => 'data_inicio', 'label' => 'Início', 'type' => 'date', 'required' => true],
                ['name' => 'data_fim', 'label' => 'Fim', 'type' => 'date'],
            ]],
            'actions' => [
                ['operation' => 'teacher.role.update', 'label' => 'Actualizar cargo', 'fields' => [
                    ['name' => 'cargo', 'label' => 'Cargo', 'required' => true],
                    ['name' => 'data_inicio', 'label' => 'Início', 'type' => 'date', 'required' => true],
                    ['name' => 'data_fim', 'label' => 'Fim', 'type' => 'date'],
                ]],
                ['operation' => 'teacher.role.revoke', 'label' => 'Revogar', 'confirm' => 'Revogar este cargo?'],
            ],
        ],
        'attendance' => [
            'label' => 'Frequência',
            'path' => '/api/escolar/attendance?pagina=' . $_ap . '&por_pagina=25',
            'pagina_param' => 'ap',
            'columns' => [['data', 'Data'], ['student_name|student_id', 'Aluno'], ['class_name|class_id', 'Turma'], ['subject_name|subject_id', 'Disciplina'], ['status|presenca', 'Presença']],
            'create' => ['operation' => 'attendance.create', 'label' => 'Lançar frequência', 'fields' => [
                ['name' => 'student_id', 'label' => 'ID do aluno', 'type' => 'number', 'required' => true],
                ['name' => 'class_id', 'label' => 'ID da turma', 'type' => 'number', 'required' => true],
                ['name' => 'subject_id', 'label' => 'ID da disciplina', 'type' => 'number'],
                ['name' => 'data', 'label' => 'Data', 'type' => 'date', 'required' => true],
                ['name' => 'status', 'label' => 'Estado', 'type' => 'select', 'options' => ['presente', 'ausente', 'atrasado', 'justificado'], 'required' => true],
            ]],
            'actions' => [[
                'operation' => 'attendance.update', 'label' => 'Corrigir', 'fields' => [
                    ['name' => 'status', 'label' => 'Estado', 'type' => 'select', 'options' => ['presente', 'ausente', 'atrasado', 'justificado'], 'required' => true],
                    ['name' => 'observacao', 'label' => 'Observação', 'type' => 'textarea'],
                ],
            ]],
        ],
        'grade_items' => [
            'label' => 'Avaliações', 'path' => '/api/escolar/grade-items',
            'columns' => [['nome|id', 'Avaliação'], ['class_name|class_id', 'Turma'], ['subject_name|subject_id', 'Disciplina'], ['data', 'Data'], ['peso', 'Peso']],
            'create' => ['operation' => 'grade.item.create', 'label' => 'Nova avaliação', 'fields' => [
                ['name' => 'class_id', 'label' => 'ID da turma', 'type' => 'number', 'required' => true],
                ['name' => 'subject_id', 'label' => 'ID da disciplina', 'type' => 'number', 'required' => true],
                ['name' => 'term_id', 'label' => 'ID do período', 'type' => 'number', 'required' => true],
                ['name' => 'nome', 'label' => 'Nome', 'required' => true],
                ['name' => 'data', 'label' => 'Data', 'type' => 'date', 'required' => true],
                ['name' => 'peso', 'label' => 'Peso', 'type' => 'number'],
            ]],
        ],
        'grades' => [
            'label' => 'Notas', 'path' => null,
            'create' => ['operation' => 'grade.create', 'label' => 'Lançar nota', 'fields' => [
                ['name' => 'grade_item_id', 'label' => 'ID da avaliação', 'type' => 'number', 'required' => true],
                ['name' => 'student_id', 'label' => 'ID do aluno', 'type' => 'number', 'required' => true],
                ['name' => 'nota', 'label' => 'Nota', 'type' => 'number', 'required' => true],
                ['name' => 'observacao', 'label' => 'Observação', 'type' => 'textarea'],
            ]],
            'tools' => [[
                'operation' => 'grade.update', 'label' => 'Corrigir nota', 'fields' => [
                    ['name' => '_id', 'label' => 'ID da nota', 'type' => 'number', 'required' => true],
                    ['name' => 'nota', 'label' => 'Nota', 'type' => 'number', 'required' => true],
                    ['name' => 'observacao', 'label' => 'Observação', 'type' => 'textarea'],
                ],
            ]],
        ],
        'report_cards' => [
            'label' => 'Boletins', 'path' => null,
            'description' => 'Consulte o boletim de um aluno por período.',
            'tools' => [[
                'operation' => 'report.card.view', 'label' => 'Consultar boletim', 'result' => true, 'fields' => [
                    ['name' => 'student_id', 'label' => 'ID do aluno', 'type' => 'number', 'required' => true],
                    ['name' => 'term_id', 'label' => 'ID do período', 'type' => 'number'],
                ],
            ]],
        ],
        'fee_plans' => [
            'label' => 'Planos de cobrança', 'path' => '/api/escolar/fee-plans',
            'columns' => [['nome|id', 'Plano'], ['valor', 'Valor'], ['periodicidade', 'Periodicidade'], ['nivel|classe', 'Nível'], ['status|ativo', 'Estado']],
            'create' => ['operation' => 'fee.plan.create', 'label' => 'Novo plano', 'fields' => [
                ['name' => 'nome', 'label' => 'Nome', 'required' => true],
                ['name' => 'valor', 'label' => 'Valor', 'type' => 'number', 'required' => true],
                ['name' => 'periodicidade', 'label' => 'Periodicidade', 'type' => 'select', 'options' => ['unica', 'mensal', 'trimestral', 'anual'], 'required' => true],
                ['name' => 'nivel', 'label' => 'Nível/classe'],
            ]],
        ],
        'student_invoices' => [
            'label' => 'Cobranças',
            'path' => '/api/escolar/student-invoices?pagina=' . $_ip . '&por_pagina=25',
            'pagina_param' => 'ip',
            'columns' => [['numero|id', 'Número'], ['student_name|student_id', 'Aluno'], ['descricao', 'Descrição'], ['valor|total', 'Valor'], ['vencimento|due_date', 'Vencimento'], ['status', 'Estado']],
            'create' => ['operation' => 'student.invoice.create', 'label' => 'Gerar cobrança', 'fields' => [
                ['name' => 'student_id', 'label' => 'ID do aluno', 'type' => 'number', 'required' => true],
                ['name' => 'fee_plan_id', 'label' => 'ID do plano', 'type' => 'number', 'required' => true],
                ['name' => 'vencimento', 'label' => 'Vencimento', 'type' => 'date', 'required' => true],
                ['name' => 'descricao', 'label' => 'Descrição'],
            ]],
            'actions' => [
                ['operation' => 'student.invoice.view', 'label' => 'Detalhes', 'result' => true],
                ['operation' => 'student.invoice.emit', 'label' => 'Emitir'],
                ['operation' => 'student.invoice.discount', 'label' => 'Desconto/bolsa', 'fields' => [
                    ['name' => 'tipo', 'label' => 'Tipo', 'type' => 'select', 'options' => ['percentual', 'valor'], 'required' => true],
                    ['name' => 'valor', 'label' => 'Valor', 'type' => 'number', 'required' => true],
                    ['name' => 'motivo', 'label' => 'Motivo', 'type' => 'textarea'],
                ]],
            ],
        ],
        'payments' => [
            'label' => 'Pagamentos', 'path' => null,
            'create' => ['operation' => 'payment.create', 'label' => 'Registar pagamento', 'fields' => [
                ['name' => 'student_invoice_id', 'label' => 'ID da cobrança', 'type' => 'number', 'required' => true],
                ['name' => 'valor', 'label' => 'Valor', 'type' => 'number', 'required' => true],
                ['name' => 'metodo', 'label' => 'Método', 'type' => 'select', 'options' => ['dinheiro', 'transferencia', 'mpesa', 'emola', 'cartao'], 'required' => true],
                ['name' => 'referencia', 'label' => 'Referência'],
                ['name' => 'data', 'label' => 'Data', 'type' => 'date', 'required' => true],
            ]],
            'tools' => [
                ['operation' => 'payment.view', 'label' => 'Consultar pagamento', 'result' => true, 'fields' => [
                    ['name' => '_id', 'label' => 'ID do pagamento', 'type' => 'number', 'required' => true],
                ]],
                ['operation' => 'payment.receipt', 'label' => 'Gerar recibo', 'result' => true, 'fields' => [
                    ['name' => '_id', 'label' => 'ID do pagamento', 'type' => 'number', 'required' => true],
                ]],
            ],
        ],
        'books' => [
            'label' => 'Biblioteca', 'path' => '/api/escolar/library/books',
            'columns' => [['isbn|codigo|id', 'Código'], ['titulo', 'Título'], ['autor', 'Autor'], ['quantidade', 'Exemplares'], ['disponiveis', 'Disponíveis']],
            'create' => ['operation' => 'book.create', 'label' => 'Cadastrar livro', 'fields' => [
                ['name' => 'isbn', 'label' => 'ISBN'],
                ['name' => 'titulo', 'label' => 'Título', 'required' => true],
                ['name' => 'autor', 'label' => 'Autor', 'required' => true],
                ['name' => 'quantidade', 'label' => 'Quantidade', 'type' => 'number', 'required' => true],
            ]],
        ],
        'loans' => [
            'label' => 'Empréstimos', 'path' => '/api/escolar/library/loans',
            'columns' => [['id', 'ID'], ['book_title|book_id', 'Livro'], ['student_name|student_id', 'Aluno'], ['data_emprestimo', 'Empréstimo'], ['data_prevista', 'Devolução prevista'], ['status', 'Estado']],
            'create' => ['operation' => 'loan.create', 'label' => 'Novo empréstimo', 'fields' => [
                ['name' => 'book_id', 'label' => 'ID do livro', 'type' => 'number', 'required' => true],
                ['name' => 'student_id', 'label' => 'ID do aluno', 'type' => 'number', 'required' => true],
                ['name' => 'data_prevista', 'label' => 'Devolução prevista', 'type' => 'date', 'required' => true],
            ]],
            'actions' => [['operation' => 'loan.return', 'label' => 'Devolver']],
        ],
        'messages' => [
            'label' => 'Comunicação', 'path' => '/api/escolar/messages',
            'columns' => [['titulo|id', 'Título'], ['destinatario_tipo|audiencia', 'Audiência'], ['created_at|data', 'Data'], ['status', 'Estado']],
            'create' => ['operation' => 'message.create', 'label' => 'Novo comunicado', 'fields' => [
                ['name' => 'titulo', 'label' => 'Título', 'required' => true],
                ['name' => 'mensagem', 'label' => 'Mensagem', 'type' => 'textarea', 'required' => true],
                ['name' => 'audiencia', 'label' => 'Audiência', 'type' => 'select', 'options' => ['todos', 'alunos', 'encarregados', 'professores', 'turma'], 'required' => true],
                ['name' => 'class_id', 'label' => 'ID da turma', 'type' => 'number'],
            ]],
            'actions' => [['operation' => 'message.publish', 'label' => 'Publicar']],
        ],
        'academic_report' => [
            'label' => 'Resumo académico', 'path' => '/api/escolar/reports/academic-summary',
            'columns' => [['indicador|nome', 'Indicador'], ['valor|total', 'Valor'], ['periodo', 'Período']],
        ],
        'financial_report' => [
            'label' => 'Resumo financeiro', 'path' => '/api/escolar/reports/financial-summary',
            'columns' => [['indicador|nome', 'Indicador'], ['valor|total', 'Valor'], ['periodo', 'Período']],
        ],
        'delinquency' => [
            'label' => 'Inadimplência', 'path' => '/api/escolar/reports/delinquency',
            'columns' => [['student_name|student_id', 'Aluno'], ['total_due|valor_divida', 'Dívida'], ['oldest_due_date|vencimento', 'Vencimento'], ['days_overdue|dias_atraso', 'Dias']],
        ],
    ],
];

include dirname(__DIR__) . '/partials/operational_workspace.php';
