'use strict';

const db = require('../config/db');

async function resumoFolha(req, res, next) {
  try {
    const { payroll_period_id } = req.query;
    if (!payroll_period_id) {
      return res.status(400).json({ error: 'payroll_period_id e obrigatorio' });
    }

    const { rows } = await db.query(
      `SELECT
          pr.id,
          pr.numero,
          pr.status,
          pr.total_bruto,
          pr.total_descontos,
          pr.total_liquido,
          COUNT(prl.id) AS total_funcionarios
         FROM payroll_runs pr
         LEFT JOIN payroll_run_lines prl ON prl.payroll_run_id = pr.id
        WHERE pr.tenant_id = $1
          AND pr.payroll_period_id = $2
        GROUP BY pr.id
        ORDER BY pr.created_at DESC`,
      [req.user.tenantId, payroll_period_id]
    );

    res.json(rows);
  } catch (err) {
    next(err);
  }
}

module.exports = { resumoFolha };
