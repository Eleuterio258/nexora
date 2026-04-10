'use strict';

const db = require('../config/db');

async function resumo(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT
          COUNT(*) AS total_eventos,
          COUNT(*) FILTER (WHERE status = 'sucesso') AS sucessos,
          COUNT(*) FILTER (WHERE status = 'falha') AS falhas,
          COUNT(*) FILTER (WHERE status = 'alerta') AS alertas
         FROM audit_events
        WHERE tenant_id = $1`,
      [req.user.tenantId]
    );

    const { rows: byService } = await db.query(
      `SELECT service_name, COUNT(*) AS total
         FROM audit_events
        WHERE tenant_id = $1
        GROUP BY service_name
        ORDER BY total DESC, service_name ASC`,
      [req.user.tenantId]
    );

    res.json({
      ...rows[0],
      por_servico: byService
    });
  } catch (err) {
    next(err);
  }
}

module.exports = { resumo };
