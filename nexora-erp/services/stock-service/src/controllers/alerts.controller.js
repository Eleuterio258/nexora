'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { status, alert_type } = req.query;
    const params = [req.user.tenantId];
    const cond = ['tenant_id = $1'];
    if (status)     { params.push(status);     cond.push(`status = $${params.length}`); }
    if (alert_type) { params.push(alert_type); cond.push(`alert_type = $${params.length}`); }
    const { rows } = await db.query(
      `SELECT * FROM stock_alerts WHERE ${cond.join(' AND ')} ORDER BY created_at DESC`,
      params
    );
    res.json(rows);
  } catch (err) { next(err); }
}

async function resolver(req, res, next) {
  try {
    const { rows } = await db.query(
      `UPDATE stock_alerts SET status = 'resolvido'
       WHERE id = $1 AND tenant_id = $2 AND status = 'aberto' RETURNING *`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Alerta não encontrado ou não está aberto' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function ignorar(req, res, next) {
  try {
    const { rows } = await db.query(
      `UPDATE stock_alerts SET status = 'ignorado'
       WHERE id = $1 AND tenant_id = $2 AND status = 'aberto' RETURNING *`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Alerta não encontrado ou não está aberto' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

module.exports = { listar, resolver, ignorar };
