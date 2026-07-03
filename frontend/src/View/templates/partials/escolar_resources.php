<?php
declare(strict_types=1);

return [
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
        'label' => 'Turmas', 'path' => '/api/escolar/classes',
        'columns' => [['codigo|id', 'Código'], ['nome', 'Turma'], ['nivel|classe', 'Nível'], ['turno', 'Turno'], ['teacher_name|professor_id', 'Director'], ['status', 'Estado']],
        'create' => ['operation' => 'class.create', 'label' => 'Nova turma', 'fields' => [
            ['name' => 'school_year_id', 'label' => 'Ano lectivo (ID)', 'type' => 'number', 'required' => true],
            ['name' => 'nome', 'label' => 'Nome', 'required' => true],
            ['name' => 'nivel', 'label' => 'Nível/classe', 'required' => true],
            ['name' => 'turno', 'label' => 'Turno', 'type' => 'select', 'options' => ['manha', 'tarde', 'noite'], 'required' => true],
            ['name' => 'capacidade', 'label' => 'Capacidade', 'type' => 'number'],
        ]],
        'actions' => [
            ['operation' => 'class.view', 'label' => 'Detalhes', 'result' => true],
            ['operation' => 'class.update', 'label' => 'Actualizar', 'fields' => [
                ['name' => 'school_year_id', 'label' => 'Ano lectivo (ID)', 'type' => 'number', 'required' => true],
                ['name' => 'nome', 'label' => 'Nome', 'required' => true],
                ['name' => 'nivel', 'label' => 'Nível/classe', 'required' => true],
                ['name' => 'turno', 'label' => 'Turno', 'type' => 'select', 'options' => ['manha', 'tarde', 'noite'], 'required' => true],
                ['name' => 'capacidade', 'label' => 'Capacidade', 'type' => 'number'],
            ]],
            ['operation' => 'class.teacher', 'label' => 'Associar director', 'fields' => [
                ['name' => 'teacher_id', 'label' => 'Professor (ID)', 'type' => 'number', 'required' => true],
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
    'teachers' => [
        'label' => 'Professores', 'path' => '/api/escolar/teachers',
        'columns' => [['codigo|id', 'Código'], ['nome_completo', 'Nome'], ['especialidade', 'Especialidade'], ['status', 'Estado']],
        'create' => ['operation' => 'teacher.create', 'label' => 'Novo professor', 'fields' => [
            ['name' => 'codigo', 'label' => 'Código', 'required' => true],
            ['name' => 'nome_completo', 'label' => 'Nome completo', 'required' => true],
            ['name' => 'especialidade', 'label' => 'Especialidade'],
            ['name' => 'email', 'label' => 'Email', 'type' => 'email'],
            ['name' => 'telefone', 'label' => 'Telefone'],
            ['name' => 'carga_horaria_maxima_semanal', 'label' => 'Carga horária máxima/semana', 'type' => 'number'],
        ]],
        'actions' => [
            ['operation' => 'teacher.view', 'label' => 'Detalhes', 'result' => true],
            ['operation' => 'teacher.update', 'label' => 'Actualizar', 'fields' => [
                ['name' => 'codigo', 'label' => 'Código'],
                ['name' => 'nome_completo', 'label' => 'Nome completo'],
                ['name' => 'especialidade', 'label' => 'Especialidade'],
                ['name' => 'email', 'label' => 'Email', 'type' => 'email'],
                ['name' => 'telefone', 'label' => 'Telefone'],
                ['name' => 'carga_horaria_maxima_semanal', 'label' => 'Carga horária máxima/semana', 'type' => 'number'],
                ['name' => 'status', 'label' => 'Estado', 'type' => 'select', 'options' => ['activo', 'inactivo', 'suspenso']],
            ]],
            ['operation' => 'teacher.delete', 'label' => 'Remover', 'confirm' => 'Remover este professor?'],
        ],
    ],
    'levels' => [
        'label' => 'Níveis de ensino', 'path' => '/api/escolar/levels',
        'columns' => [['codigo|id', 'Código'], ['nome', 'Nível'], ['sistema_avaliacao', 'Avaliação'], ['numero_periodos_padrao', 'Períodos'], ['activo', 'Activo']],
        'create' => ['operation' => 'level.create', 'label' => 'Novo nível', 'fields' => [
            ['name' => 'codigo', 'label' => 'Código', 'required' => true],
            ['name' => 'nome', 'label' => 'Nome', 'required' => true],
            ['name' => 'nota_minima_aprovacao', 'label' => 'Nota mínima', 'type' => 'number'],
            ['name' => 'escala_maxima', 'label' => 'Escala máxima', 'type' => 'number'],
            ['name' => 'sistema_avaliacao', 'label' => 'Sistema', 'type' => 'select', 'options' => ['0-20', '0-100', 'A-F', 'ECTS']],
            ['name' => 'numero_periodos_padrao', 'label' => 'N.º períodos', 'type' => 'number'],
            ['name' => 'nomenclatura_periodo', 'label' => 'Nome do período'],
            ['name' => 'nomenclatura_serie', 'label' => 'Nome da série'],
        ]],
        'actions' => [
            ['operation' => 'level.view', 'label' => 'Detalhes', 'result' => true],
            ['operation' => 'level.update', 'label' => 'Actualizar', 'fields' => [
                ['name' => 'codigo', 'label' => 'Código'],
                ['name' => 'nome', 'label' => 'Nome'],
                ['name' => 'nota_minima_aprovacao', 'label' => 'Nota mínima', 'type' => 'number'],
                ['name' => 'escala_maxima', 'label' => 'Escala máxima', 'type' => 'number'],
                ['name' => 'sistema_avaliacao', 'label' => 'Sistema', 'type' => 'select', 'options' => ['0-20', '0-100', 'A-F', 'ECTS']],
                ['name' => 'activo', 'label' => 'Activo', 'type' => 'select', 'options' => ['true', 'false']],
            ]],
            ['operation' => 'level.delete', 'label' => 'Remover', 'confirm' => 'Remover este nível?'],
        ],
    ],
    'series' => [
        'label' => 'Séries', 'path' => '/api/escolar/series',
        'columns' => [['codigo|id', 'Código'], ['nome', 'Série'], ['level_id', 'Nível (ID)'], ['ordem', 'Ordem'], ['activo', 'Activo']],
        'create' => ['operation' => 'series.create', 'label' => 'Nova série', 'fields' => [
            ['name' => 'level_id', 'label' => 'Nível (ID)', 'type' => 'number', 'required' => true],
            ['name' => 'codigo', 'label' => 'Código', 'required' => true],
            ['name' => 'nome', 'label' => 'Nome', 'required' => true],
            ['name' => 'ordem', 'label' => 'Ordem', 'type' => 'number'],
        ]],
        'actions' => [
            ['operation' => 'series.view', 'label' => 'Detalhes', 'result' => true],
            ['operation' => 'series.update', 'label' => 'Actualizar', 'fields' => [
                ['name' => 'level_id', 'label' => 'Nível (ID)', 'type' => 'number'],
                ['name' => 'codigo', 'label' => 'Código'],
                ['name' => 'nome', 'label' => 'Nome'],
                ['name' => 'ordem', 'label' => 'Ordem', 'type' => 'number'],
                ['name' => 'activo', 'label' => 'Activo', 'type' => 'select', 'options' => ['true', 'false']],
            ]],
            ['operation' => 'series.delete', 'label' => 'Remover', 'confirm' => 'Remover esta série?'],
        ],
    ],
    'courses' => [
        'label' => 'Cursos', 'path' => '/api/escolar/courses',
        'columns' => [['codigo|id', 'Código'], ['nome', 'Curso'], ['level_id', 'Nível (ID)'], ['duracao_anos', 'Duração'], ['modalidade', 'Modalidade'], ['activo', 'Activo']],
        'create' => ['operation' => 'course.create', 'label' => 'Novo curso', 'fields' => [
            ['name' => 'level_id', 'label' => 'Nível (ID)', 'type' => 'number', 'required' => true],
            ['name' => 'codigo', 'label' => 'Código', 'required' => true],
            ['name' => 'nome', 'label' => 'Nome', 'required' => true],
            ['name' => 'duracao_anos', 'label' => 'Duração (anos)', 'type' => 'number'],
            ['name' => 'modalidade', 'label' => 'Modalidade', 'type' => 'select', 'options' => ['presencial', 'distancia', 'pos_laboral', 'hibrido']],
        ]],
        'actions' => [
            ['operation' => 'course.view', 'label' => 'Detalhes', 'result' => true],
            ['operation' => 'course.update', 'label' => 'Actualizar', 'fields' => [
                ['name' => 'level_id', 'label' => 'Nível (ID)', 'type' => 'number'],
                ['name' => 'codigo', 'label' => 'Código'],
                ['name' => 'nome', 'label' => 'Nome'],
                ['name' => 'duracao_anos', 'label' => 'Duração (anos)', 'type' => 'number'],
                ['name' => 'modalidade', 'label' => 'Modalidade', 'type' => 'select', 'options' => ['presencial', 'distancia', 'pos_laboral', 'hibrido']],
                ['name' => 'activo', 'label' => 'Activo', 'type' => 'select', 'options' => ['true', 'false']],
            ]],
            ['operation' => 'course.delete', 'label' => 'Remover', 'confirm' => 'Remover este curso?'],
        ],
    ],
    'teacher_assignments' => [
        'label' => 'Atribuições', 'path' => null,
        'description' => 'Associe professores a turmas e disciplinas.',
        'create' => ['operation' => 'teacher.assignment.create', 'label' => 'Atribuir professor', 'fields' => [
            ['name' => 'teacher_id', 'label' => 'Professor (ID)', 'type' => 'number', 'required' => true],
            ['name' => 'class_id', 'label' => 'Turma (ID)', 'type' => 'number', 'required' => true],
            ['name' => 'subject_id', 'label' => 'Disciplina (ID)', 'type' => 'number', 'required' => true],
        ]],
    ],
    'students' => [
        'label' => 'Alunos', 'path' => '/api/escolar/students',
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
            ['operation' => 'portal.status',     'label' => 'Estado portal', 'result' => true],
            ['operation' => 'portal.activate',   'label' => 'Activar portal', 'fields' => [
                ['name' => 'email',    'label' => 'Email de acesso', 'type' => 'email',    'required' => true],
                ['name' => 'password', 'label' => 'Senha inicial',   'type' => 'password', 'required' => true],
            ]],
            ['operation' => 'portal.invite', 'label' => 'Enviar convite', 'result' => true, 'fields' => [
                ['name' => 'email', 'label' => 'Email do aluno', 'type' => 'email', 'required' => true],
            ]],
            ['operation' => 'portal.reset_senha', 'label' => 'Reset senha portal', 'fields' => [
                ['name' => 'password', 'label' => 'Nova senha', 'type' => 'password', 'required' => true],
            ]],
            ['operation' => 'portal.deactivate', 'label' => 'Desactivar portal', 'confirm' => 'Desactivar acesso ao portal deste aluno?'],
        ],
    ],
    'enrollments' => [
        'label' => 'Matrículas', 'path' => null,
        'description' => 'Matrícula, rematrícula, consulta, transferência e cancelamento.',
        'create' => ['operation' => 'enrollment.create', 'label' => 'Nova matrícula', 'fields' => [
            ['name' => 'student_id', 'label' => 'Aluno (ID)', 'type' => 'number', 'required' => true],
            ['name' => 'class_id', 'label' => 'Turma (ID)', 'type' => 'number', 'required' => true],
            ['name' => 'school_year_id', 'label' => 'Ano lectivo (ID)', 'type' => 'number', 'required' => true],
            ['name' => 'data_matricula', 'label' => 'Data da matrícula', 'type' => 'date', 'required' => true],
        ]],
        'tools' => [
            ['operation' => 'enrollment.view', 'label' => 'Consultar matrícula', 'result' => true, 'fields' => [
                ['name' => '_id', 'label' => 'Matrícula (ID)', 'type' => 'number', 'required' => true],
            ]],
            ['operation' => 'enrollment.transfer', 'label' => 'Transferir aluno', 'fields' => [
                ['name' => '_id', 'label' => 'Matrícula (ID)', 'type' => 'number', 'required' => true],
                ['name' => 'class_id', 'label' => 'Nova turma (ID)', 'type' => 'number', 'required' => true],
                ['name' => 'motivo', 'label' => 'Motivo', 'type' => 'textarea'],
            ]],
            ['operation' => 'enrollment.cancel', 'label' => 'Cancelar matrícula', 'fields' => [
                ['name' => '_id', 'label' => 'Matrícula (ID)', 'type' => 'number', 'required' => true],
                ['name' => 'motivo', 'label' => 'Motivo', 'type' => 'textarea', 'required' => true],
            ]],
        ],
    ],
    'student_roles' => [
        'label' => 'Cargos de alunos', 'path' => '/api/escolar/student-roles',
        'columns' => [['student_name|student_id', 'Aluno'], ['role|cargo', 'Cargo'], ['inicio|data_inicio', 'Início'], ['fim|data_fim', 'Fim'], ['status', 'Estado']],
        'create' => ['operation' => 'student.role.create', 'label' => 'Atribuir cargo', 'fields' => [
            ['name' => 'student_id', 'label' => 'Aluno (ID)', 'type' => 'number', 'required' => true],
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
            ['name' => 'teacher_id', 'label' => 'Professor (ID)', 'type' => 'number', 'required' => true],
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
    'timetable' => [
        'label' => 'Horários', 'path' => null,
        'description' => 'Gestão de horários escolares.',
        'create' => ['operation' => 'timetable.create', 'label' => 'Nova aula', 'fields' => [
            ['name' => 'school_year_id', 'label' => 'Ano lectivo (ID)', 'type' => 'number', 'required' => true],
            ['name' => 'class_id', 'label' => 'Turma (ID)', 'type' => 'number', 'required' => true],
            ['name' => 'subject_id', 'label' => 'Disciplina (ID)', 'type' => 'number', 'required' => true],
            ['name' => 'teacher_id', 'label' => 'Professor (ID)', 'type' => 'number', 'required' => true],
            ['name' => 'time_slot_id', 'label' => 'Slot (ID)', 'type' => 'number', 'required' => true],
            ['name' => 'dia_semana', 'label' => 'Dia da semana (1-7)', 'type' => 'number', 'required' => true],
            ['name' => 'sala', 'label' => 'Sala'],
        ]],
        'tools' => [
            ['operation' => 'timetable.class.view', 'label' => 'Horário por turma', 'result' => true, 'fields' => [
                ['name' => 'class_id', 'label' => 'Turma (ID)', 'type' => 'number', 'required' => true],
            ]],
            ['operation' => 'timetable.teacher.view', 'label' => 'Horário por professor', 'result' => true, 'fields' => [
                ['name' => 'teacher_id', 'label' => 'Professor (ID)', 'type' => 'number', 'required' => true],
            ]],
        ],
    ],
    'time_slots' => [
        'label' => 'Slots horários', 'path' => '/api/escolar/time-slots',
        'columns' => [['codigo|id', 'Código'], ['nome', 'Nome'], ['hora_inicio', 'Início'], ['hora_fim', 'Fim'], ['ordem', 'Ordem']],
        'create' => ['operation' => 'time.slot.create', 'label' => 'Novo slot', 'fields' => [
            ['name' => 'codigo', 'label' => 'Código', 'required' => true],
            ['name' => 'nome', 'label' => 'Nome'],
            ['name' => 'hora_inicio', 'label' => 'Início (HH:MM)', 'required' => true],
            ['name' => 'hora_fim', 'label' => 'Fim (HH:MM)', 'required' => true],
            ['name' => 'ordem', 'label' => 'Ordem', 'type' => 'number'],
        ]],
    ],
    'calendar' => [
        'label' => 'Calendário', 'path' => '/api/escolar/calendar-events',
        'columns' => [['titulo|id', 'Título'], ['data_inicio', 'Início'], ['publico_alvo', 'Público'], ['dia_todo', 'Dia todo']],
        'create' => ['operation' => 'calendar.event.create', 'label' => 'Novo evento', 'fields' => [
            ['name' => 'school_year_id', 'label' => 'Ano lectivo (ID)', 'type' => 'number', 'required' => true],
            ['name' => 'titulo', 'label' => 'Título', 'required' => true],
            ['name' => 'descricao', 'label' => 'Descrição', 'type' => 'textarea'],
            ['name' => 'data_inicio', 'label' => 'Data início', 'type' => 'date', 'required' => true],
            ['name' => 'data_fim', 'label' => 'Data fim', 'type' => 'date'],
            ['name' => 'publico_alvo', 'label' => 'Público', 'type' => 'select', 'options' => ['todos', 'alunos', 'professores', 'turma', 'curso']],
        ]],
        'actions' => [
            ['operation' => 'calendar.event.view', 'label' => 'Detalhes', 'result' => true],
            ['operation' => 'calendar.event.update', 'label' => 'Actualizar', 'fields' => [
                ['name' => 'titulo', 'label' => 'Título'],
                ['name' => 'descricao', 'label' => 'Descrição', 'type' => 'textarea'],
                ['name' => 'data_inicio', 'label' => 'Data início', 'type' => 'date'],
                ['name' => 'data_fim', 'label' => 'Data fim', 'type' => 'date'],
            ]],
            ['operation' => 'calendar.event.delete', 'label' => 'Remover', 'confirm' => 'Remover este evento?'],
        ],
    ],
    'incidents' => [
        'label' => 'Ocorrências', 'path' => '/api/escolar/incidents',
        'columns' => [['data_ocorrencia', 'Data'], ['student_id', 'Aluno (ID)'], ['descricao', 'Descrição'], ['status', 'Estado']],
        'create' => ['operation' => 'incident.create', 'label' => 'Registar ocorrência', 'fields' => [
            ['name' => 'school_year_id', 'label' => 'Ano lectivo (ID)', 'type' => 'number', 'required' => true],
            ['name' => 'student_id', 'label' => 'Aluno (ID)', 'type' => 'number', 'required' => true],
            ['name' => 'descricao', 'label' => 'Descrição', 'type' => 'textarea', 'required' => true],
            ['name' => 'data_ocorrencia', 'label' => 'Data', 'type' => 'date', 'required' => true],
        ]],
        'actions' => [
            ['operation' => 'incident.view', 'label' => 'Detalhes', 'result' => true],
            ['operation' => 'incident.update', 'label' => 'Actualizar', 'fields' => [
                ['name' => 'descricao', 'label' => 'Descrição', 'type' => 'textarea'],
                ['name' => 'status', 'label' => 'Estado', 'type' => 'select', 'options' => ['registada', 'em_analise', 'resolvida', 'arquivada']],
            ]],
        ],
    ],
    'attendance' => [
        'label' => 'Frequência', 'path' => '/api/escolar/attendance',
        'columns' => [['data', 'Data'], ['student_name|student_id', 'Aluno'], ['class_name|class_id', 'Turma'], ['subject_name|subject_id', 'Disciplina'], ['status|presenca', 'Presença']],
        'create' => ['operation' => 'attendance.create', 'label' => 'Lançar frequência', 'fields' => [
            ['name' => 'student_id', 'label' => 'Aluno (ID)', 'type' => 'number', 'required' => true],
            ['name' => 'class_id', 'label' => 'Turma (ID)', 'type' => 'number', 'required' => true],
            ['name' => 'subject_id', 'label' => 'Disciplina (ID)', 'type' => 'number'],
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
            ['name' => 'class_id', 'label' => 'Turma (ID)', 'type' => 'number', 'required' => true],
            ['name' => 'subject_id', 'label' => 'Disciplina (ID)', 'type' => 'number', 'required' => true],
            ['name' => 'term_id', 'label' => 'Período (ID)', 'type' => 'number', 'required' => true],
            ['name' => 'nome', 'label' => 'Nome', 'required' => true],
            ['name' => 'data', 'label' => 'Data', 'type' => 'date', 'required' => true],
            ['name' => 'peso', 'label' => 'Peso', 'type' => 'number'],
        ]],
    ],
    'grades' => [
        'label' => 'Notas', 'path' => null,
        'create' => ['operation' => 'grade.create', 'label' => 'Lançar nota', 'fields' => [
            ['name' => 'grade_item_id', 'label' => 'Avaliação (ID)', 'type' => 'number', 'required' => true],
            ['name' => 'student_id', 'label' => 'Aluno (ID)', 'type' => 'number', 'required' => true],
            ['name' => 'nota', 'label' => 'Nota', 'type' => 'number', 'required' => true],
            ['name' => 'observacao', 'label' => 'Observação', 'type' => 'textarea'],
        ]],
        'tools' => [[
            'operation' => 'grade.update', 'label' => 'Corrigir nota', 'fields' => [
                ['name' => '_id', 'label' => 'Nota (ID)', 'type' => 'number', 'required' => true],
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
                ['name' => 'student_id', 'label' => 'Aluno (ID)', 'type' => 'number', 'required' => true],
                ['name' => 'term_id', 'label' => 'Período (ID)', 'type' => 'number'],
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
        'label' => 'Cobranças', 'path' => '/api/escolar/student-invoices',
        'columns' => [['numero|id', 'Número'], ['student_name|student_id', 'Aluno'], ['descricao', 'Descrição'], ['valor|total', 'Valor'], ['vencimento|due_date', 'Vencimento'], ['status', 'Estado']],
        'create' => ['operation' => 'student.invoice.create', 'label' => 'Gerar cobrança', 'fields' => [
            ['name' => 'student_id', 'label' => 'Aluno (ID)', 'type' => 'number', 'required' => true],
            ['name' => 'fee_plan_id', 'label' => 'Plano (ID)', 'type' => 'number', 'required' => true],
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
            ['name' => 'student_invoice_id', 'label' => 'Cobrança (ID)', 'type' => 'number', 'required' => true],
            ['name' => 'valor', 'label' => 'Valor', 'type' => 'number', 'required' => true],
            ['name' => 'metodo', 'label' => 'Método', 'type' => 'select', 'options' => ['dinheiro', 'transferencia', 'mpesa', 'emola', 'cartao'], 'required' => true],
            ['name' => 'referencia', 'label' => 'Referência'],
            ['name' => 'data', 'label' => 'Data', 'type' => 'date', 'required' => true],
        ]],
        'tools' => [
            ['operation' => 'payment.view', 'label' => 'Consultar pagamento', 'result' => true, 'fields' => [
                ['name' => '_id', 'label' => 'Pagamento (ID)', 'type' => 'number', 'required' => true],
            ]],
            ['operation' => 'payment.receipt', 'label' => 'Gerar recibo', 'result' => true, 'fields' => [
                ['name' => '_id', 'label' => 'Pagamento (ID)', 'type' => 'number', 'required' => true],
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
            ['name' => 'book_id', 'label' => 'Livro (ID)', 'type' => 'number', 'required' => true],
            ['name' => 'student_id', 'label' => 'Aluno (ID)', 'type' => 'number', 'required' => true],
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
            ['name' => 'class_id', 'label' => 'Turma (ID)', 'type' => 'number'],
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
];
