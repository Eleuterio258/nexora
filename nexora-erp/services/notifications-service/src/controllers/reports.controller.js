'use strict';

const db = require('../config/db');

async function resumo(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT
          COUNT(*) AS total,
          COUNT(*) FILTER (WHERE status = 'pendente') AS pendentes,
          COUNT(*) FILTER (WHERE status = 'enviado') AS enviados,
          COUNT(*) FILTER (WHERE status = 'falha') AS falhas
         FROM notification_messages
        WHERE tenant_id = $1`,
      [req.user.tenantId]
    );

    const { rows: canais } = await db.query(
      `SELECT canal_tipo, COUNT(*) AS total
         FROM notification_messages
        WHERE tenant_id = $1
        GROUP BY canal_tipo
        ORDER BY canal_tipo ASC`,
      [req.user.tenantId]
    );

    res.json({
      ...rows[0],
      por_canal: canais
    });
  } catch (err) {
    next(err);
  }
}

module.exports = { resumo };
