'use strict';

const db = require('../config/db');

async function resumo(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT
          COUNT(*) AS total,
          COUNT(*) FILTER (WHERE status = 'planeada') AS planeadas,
          COUNT(*) FILTER (WHERE status = 'despachada') AS despachadas,
          COUNT(*) FILTER (WHERE status = 'em_transito') AS em_transito,
          COUNT(*) FILTER (WHERE status = 'entregue') AS entregues,
          COUNT(*) FILTER (WHERE status = 'cancelada') AS canceladas
         FROM logistics_shipments
        WHERE tenant_id = $1`,
      [req.user.tenantId]
    );
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { resumo };
