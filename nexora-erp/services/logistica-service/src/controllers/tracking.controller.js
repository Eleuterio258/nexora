'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { shipment_id } = req.query;
    const params = [req.user.tenantId];
    let sql = `SELECT * FROM logistics_tracking_events WHERE tenant_id = $1`;
    if (shipment_id) {
      params.push(shipment_id);
      sql += ` AND shipment_id = $2`;
    }
    sql += ` ORDER BY event_time DESC`;

    const { rows } = await db.query(sql, params);
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function registar(req, res, next) {
  try {
    const { shipment_id, evento, localizacao, latitude, longitude, observacoes } = req.body;
    if (!shipment_id || !evento) {
      return res.status(400).json({ error: 'shipment_id e evento sao obrigatorios' });
    }

    const { rows } = await db.query(
      `INSERT INTO logistics_tracking_events
       (tenant_id, shipment_id, evento, localizacao, latitude, longitude, observacoes, created_by)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
       RETURNING *`,
      [req.user.tenantId, shipment_id, evento, localizacao || null, latitude || null, longitude || null, observacoes || null, req.user.id]
    );

    if (evento === 'em_transito') {
      await db.query(
        `UPDATE logistics_shipments SET status = 'em_transito', updated_at = NOW() WHERE id = $1 AND tenant_id = $2`,
        [shipment_id, req.user.tenantId]
      );
    }

    res.status(201).json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, registar };
