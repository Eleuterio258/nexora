'use strict';

const db = require('../config/db');

async function resumo(req, res, next) {
  try {
    const params = [req.user.tenantId];
    const { rows } = await db.query(
      `SELECT
          COUNT(*) FILTER (WHERE status = 'rascunho') AS ordens_rascunho,
          COUNT(*) FILTER (WHERE status = 'aprovada') AS ordens_aprovadas,
          COUNT(*) FILTER (WHERE status = 'parcial') AS ordens_parciais,
          COUNT(*) FILTER (WHERE status = 'recebida') AS ordens_recebidas,
          COALESCE(SUM(total) FILTER (WHERE status <> 'cancelada'), 0) AS total_encomendado
         FROM purchase_orders
        WHERE tenant_id = $1`,
      params
    );

    const { rows: receiptRows } = await db.query(
      `SELECT COUNT(*) AS total_rececoes
         FROM goods_receipts
        WHERE tenant_id = $1`,
      params
    );

    const { rows: returnRows } = await db.query(
      `SELECT COUNT(*) AS total_devolucoes, COALESCE(SUM(total), 0) AS valor_devolvido
         FROM purchase_returns
        WHERE tenant_id = $1`,
      params
    );

    res.json({
      ...rows[0],
      ...receiptRows[0],
      ...returnRows[0]
    });
  } catch (err) {
    next(err);
  }
}

module.exports = { resumo };
