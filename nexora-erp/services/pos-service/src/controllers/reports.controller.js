'use strict';

const db = require('../config/db');

async function resumoVendas(req, res, next) {
  try {
    const { pos_session_id } = req.query;
    const params = [req.user.tenantId];
    let extra = '';
    if (pos_session_id) {
      params.push(pos_session_id);
      extra = ` AND pos_session_id = $2`;
    }

    const { rows } = await db.query(
      `SELECT
          COUNT(*) AS total_vendas,
          COALESCE(SUM(total), 0) AS valor_total,
          COALESCE(SUM(valor_recebido), 0) AS valor_recebido
         FROM pos_sales
        WHERE tenant_id = $1
          AND status = 'concluida'${extra}`,
      params
    );
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { resumoVendas };
