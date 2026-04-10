-- Views do modulo de Recursos Humanos

-- Ficha resumida do funcionario com unidade organizacional e cargo actuais
CREATE OR REPLACE VIEW vw_rh_employees AS
SELECT
    e.id AS employee_id,
    e.tenant_id,
    e.numero,
    e.nome,
    e.email_profissional,
    e.telefone,
    e.estado,
    e.data_admissao,
    e.data_demissao,
    u.nome AS unidade_org,
    p.nome AS cargo,
    p.grau_salarial
FROM employees e
LEFT JOIN org_units u ON u.id = e.org_unit_id
LEFT JOIN employee_positions p ON p.id = e.employee_position_id;

-- Salario actual de cada funcionario (registo mais recente)
CREATE OR REPLACE VIEW vw_rh_salario_actual AS
SELECT DISTINCT ON (s.employee_id)
    s.employee_id,
    s.salario_base,
    s.inicia_em,
    s.motivo_alteracao
FROM employee_salaries s
ORDER BY s.employee_id, s.inicia_em DESC;

-- Resumo de recibos por processamento
CREATE OR REPLACE VIEW vw_rh_payslips AS
SELECT
    pr.id AS payroll_run_id,
    pr.mes,
    pr.ano,
    pr.status AS run_status,
    e.numero,
    e.nome,
    ep.salario_base,
    ep.total_proventos,
    ep.total_descontos,
    ep.inss_colaborador,
    ep.inss_entidade,
    ep.irps,
    ep.total_liquido,
    ep.status AS payslip_status
FROM employee_payroll ep
JOIN payroll_runs pr ON pr.id = ep.payroll_run_id
JOIN employees e ON e.id = ep.employee_id;

-- Saldos de licenca actuais por funcionario e tipo
CREATE OR REPLACE VIEW vw_rh_leave_balances AS
SELECT
    lb.employee_id,
    e.nome,
    lt.nome AS tipo_licenca,
    lb.ano,
    lb.dias_direito,
    lb.dias_gozados,
    lb.dias_pendentes,
    (lb.dias_direito - lb.dias_gozados - lb.dias_pendentes) AS dias_disponiveis
FROM employee_leave_balances lb
JOIN employees e ON e.id = lb.employee_id
JOIN employee_leave_types lt ON lt.id = lb.employee_leave_type_id;

-- Pedidos de licenca com estado e responsavel
CREATE OR REPLACE VIEW vw_rh_leaves AS
SELECT
    l.id AS leave_id,
    e.nome AS funcionario,
    lt.nome AS tipo_licenca,
    l.data_inicio,
    l.data_fim,
    l.dias_solicitados,
    l.dias_aprovados,
    l.status,
    l.motivo,
    ap.nome AS aprovado_por_nome
FROM employee_leaves l
JOIN employees e ON e.id = l.employee_id
JOIN employee_leave_types lt ON lt.id = l.employee_leave_type_id
LEFT JOIN employees ap ON ap.id = l.aprovado_por;

-- Assiduidade mensal com totais
CREATE OR REPLACE VIEW vw_rh_attendance_mensal AS
SELECT
    a.employee_id,
    e.nome,
    DATE_TRUNC('month', a.data) AS mes,
    COUNT(*) AS dias_trabalhados,
    SUM(a.horas_trabalhadas) AS total_horas,
    SUM(a.horas_extra) AS total_horas_extra,
    COUNT(*) FILTER (WHERE a.estado = 'falta') AS total_faltas
FROM employee_attendance a
JOIN employees e ON e.id = a.employee_id
GROUP BY a.employee_id, e.nome, DATE_TRUNC('month', a.data);

-- Headcount por unidade organizacional (directo, sem subarvore)
CREATE OR REPLACE VIEW vw_rh_headcount AS
SELECT
    u.id AS org_unit_id,
    u.nome AS unidade_org,
    u.nivel,
    COUNT(e.id) AS total_funcionarios,
    COUNT(e.id) FILTER (WHERE e.estado = 'ativo')     AS ativos,
    COUNT(e.id) FILTER (WHERE e.estado = 'suspenso')  AS suspensos
FROM org_units u
LEFT JOIN employees e ON e.org_unit_id = u.id
GROUP BY u.id, u.nome, u.nivel;

-- Massa salarial por unidade organizacional (salario actual)
CREATE OR REPLACE VIEW vw_rh_massa_salarial AS
SELECT
    u.nome AS unidade_org,
    COUNT(s.employee_id) AS num_funcionarios,
    SUM(s.salario_base) AS massa_salarial_bruta,
    AVG(s.salario_base) AS salario_medio
FROM vw_rh_salario_actual s
JOIN employees e ON e.id = s.employee_id
JOIN org_units u ON u.id = e.org_unit_id
WHERE e.estado = 'ativo'
GROUP BY u.nome;
