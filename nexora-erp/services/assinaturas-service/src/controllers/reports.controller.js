'use strict';

const db = require('../config/db');

async function resumo(req, res, next) {
  try {
    const [subsRes, invRes] = await Promise.all([
      db.query(`SELECT COUNT(*) AS total, COUNT(*) FILTER (WHERE status = 'activa') AS activas FROM subscriptions WHERE tenant_id = $1`, [req.user.tenantId]),
      db.query(`SELECT COUNT(*) AS total_facturas, COALESCE(SUM(valor_total), 0) AS valor_facturado, COALESCE(SUM(valor_pago), 0) AS valor_pago FROM subscription_invoices WHERE tenant_id = $1`, [req.user.tenantId]),
    ]);

    res.json({
      subscriptions: subsRes.rows[0],
      invoices: invRes.rows[0]
    });
  } catch (err) {
    next(err);
  }
}

module.exports = { resumo };
