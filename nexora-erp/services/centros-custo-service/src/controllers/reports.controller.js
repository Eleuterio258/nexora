'use strict';

const db = require('../config/db');

async function resumo(req, res, next) {
  try {
    const { ano } = req.query;
    const params = [req.user.tenantId];
    let extra = '';
    if (ano) {
      params.push(ano);
      extra = ' AND b.ano = $2';
    }

    const { rows } = await db.query(
      `SELECT
          c.id,
          c.codigo,
          c.nome,
          COALESCE(SUM(a.valor), 0) AS total_alocado,
          COALESCE(SUM(b.valor_orcamentado), 0) AS total_orcamentado
         FROM cost_centers c
         LEFT JOIN cost_center_allocations a ON a.cost_center_id = c.id AND a.tenant_id = $1
         LEFT JOIN cost_center_budgets b ON b.cost_center_id = c.id AND b.tenant_id = $1${extra}
        WHERE c.tenant_id = $1
        GROUP BY c.id, c.codigo, c.nome
        ORDER BY c.codigo ASC`,
      params
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

module.exports = { resumo };
