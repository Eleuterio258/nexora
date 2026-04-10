'use strict';

const db = require('../config/db');
const { calcularFolha, roundMoney } = require('../lib/payroll');

async function listar(req, res, next) {
  try {
    const { payroll_period_id, status } = req.query;
    const params = [req.user.tenantId];
    const conditions = ['pr.tenant_id = $1'];

    if (payroll_period_id) {
      params.push(payroll_period_id);
      conditions.push(`pr.payroll_period_id = $${params.length}`);
    }
    if (status) {
      params.push(status);
      conditions.push(`pr.status = $${params.length}`);
    }

    const { rows } = await db.query(
      `SELECT pr.*, pp.ano, pp.mes
         FROM payroll_runs pr
         JOIN payroll_periods pp ON pp.id = pr.payroll_period_id
        WHERE ${conditions.join(' AND ')}
        ORDER BY pr.processamento_em DESC, pr.created_at DESC`,
      params
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function obter(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT * FROM payroll_runs WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) {
      return res.status(404).json({ error: 'Processamento de folha nao encontrado' });
    }

    const { rows: lines } = await db.query(
      `SELECT prl.*, e.codigo AS employee_codigo, e.nome AS employee_nome
         FROM payroll_run_lines prl
         JOIN employees e ON e.id = prl.employee_id
        WHERE prl.payroll_run_id = $1
        ORDER BY e.nome ASC`,
      [req.params.id]
    );

    res.json({ ...rows[0], lines });
  } catch (err) {
    next(err);
  }
}

async function processar(req, res, next) {
  const client = await db.connect();
  try {
    await client.query('BEGIN');

    const { payroll_period_id, numero, processamento_em, linhas } = req.body;
    if (!payroll_period_id || !numero) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'payroll_period_id e numero sao obrigatorios' });
    }

    const { rows: periods } = await client.query(
      `SELECT * FROM payroll_periods WHERE id = $1 AND tenant_id = $2 FOR UPDATE`,
      [payroll_period_id, req.user.tenantId]
    );
    if (!periods.length) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Periodo de folha nao encontrado' });
    }
    if (periods[0].status !== 'aberto') {
      await client.query('ROLLBACK');
      return res.status(409).json({ error: 'Periodo de folha fechado' });
    }

    let employees = [];
    if (Array.isArray(linhas) && linhas.length) {
      const ids = linhas.map((line) => Number(line.employee_id)).filter(Boolean);
      const { rows } = await client.query(
        `SELECT * FROM employees WHERE tenant_id = $1 AND id = ANY($2::bigint[]) AND estado = 'ativo'`,
        [req.user.tenantId, ids]
      );
      employees = rows.map((employee) => {
        const extra = linhas.find((line) => Number(line.employee_id) === Number(employee.id)) || {};
        return {
          ...employee,
          adicionais_input: Number(extra.adicionais || 0),
          descontos_input: Number(extra.descontos || 0),
          observacoes: extra.observacoes || null
        };
      });
    } else {
      const { rows } = await client.query(
        `SELECT * FROM employees WHERE tenant_id = $1 AND estado = 'ativo' ORDER BY nome ASC`,
        [req.user.tenantId]
      );
      employees = rows.map((employee) => ({
        ...employee,
        adicionais_input: 0,
        descontos_input: 0,
        observacoes: null
      }));
    }

    if (!employees.length) {
      await client.query('ROLLBACK');
      return res.status(422).json({ error: 'Nao ha funcionarios ativos para processar' });
    }

    const { rows: runs } = await client.query(
      `INSERT INTO payroll_runs
       (tenant_id, payroll_period_id, numero, processamento_em, criado_por)
       VALUES ($1,$2,$3,COALESCE($4, CURRENT_DATE),$5)
       RETURNING *`,
      [req.user.tenantId, payroll_period_id, numero, processamento_em || null, req.user.id]
    );

    let totalBruto = 0;
    let totalDescontos = 0;
    let totalLiquido = 0;

    for (const employee of employees) {
      const folha = calcularFolha(employee.salario_base, employee.adicionais_input, employee.descontos_input);
      totalBruto = roundMoney(totalBruto + folha.bruto);
      totalDescontos = roundMoney(totalDescontos + folha.descontos);
      totalLiquido = roundMoney(totalLiquido + folha.liquido);

      await client.query(
        `INSERT INTO payroll_run_lines
         (payroll_run_id, employee_id, salario_base, adicionais, descontos, bruto, liquido, observacoes)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8)`,
        [runs[0].id, employee.id, folha.salario_base, folha.adicionais, folha.descontos, folha.bruto, folha.liquido, employee.observacoes]
      );
    }

    const { rows: updated } = await client.query(
      `UPDATE payroll_runs
          SET total_bruto = $1,
              total_descontos = $2,
              total_liquido = $3
        WHERE id = $4
      RETURNING *`,
      [totalBruto, totalDescontos, totalLiquido, runs[0].id]
    );

    await client.query('COMMIT');
    res.status(201).json(updated[0]);
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally {
    client.release();
  }
}

async function aprovar(req, res, next) {
  try {
    const { rows } = await db.query(
      `UPDATE payroll_runs
          SET status = 'aprovado',
              aprovado_por = $1,
              aprovado_em = NOW()
        WHERE id = $2 AND tenant_id = $3 AND status = 'processado'
      RETURNING *`,
      [req.user.id, req.params.id, req.user.tenantId]
    );

    if (!rows.length) {
      return res.status(409).json({ error: 'Apenas folhas processadas podem ser aprovadas' });
    }

    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, obter, processar, aprovar };
