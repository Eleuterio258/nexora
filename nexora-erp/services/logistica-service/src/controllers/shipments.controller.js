'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { status, source_service, source_type } = req.query;
    const params = [req.user.tenantId];
    const conditions = ['tenant_id = $1'];
    if (status) {
      params.push(status);
      conditions.push(`status = $${params.length}`);
    }
    if (source_service) {
      params.push(source_service);
      conditions.push(`source_service = $${params.length}`);
    }
    if (source_type) {
      params.push(source_type);
      conditions.push(`source_type = $${params.length}`);
    }

    const { rows } = await db.query(
      `SELECT * FROM logistics_shipments WHERE ${conditions.join(' AND ')} ORDER BY created_at DESC`,
      params
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function obter(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT * FROM logistics_shipments WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) {
      return res.status(404).json({ error: 'Expedicao nao encontrada' });
    }

    const { rows: tracking } = await db.query(
      `SELECT * FROM logistics_tracking_events WHERE shipment_id = $1 ORDER BY event_time ASC`,
      [req.params.id]
    );
    res.json({ ...rows[0], tracking });
  } catch (err) {
    next(err);
  }
}

async function criar(req, res, next) {
  try {
    const {
      numero, source_service, source_type, source_id, logistics_route_id,
      vehicle_id, driver_id, customer_id, delivery_address, scheduled_date, observacoes
    } = req.body;
    if (!numero || !source_service || !source_type || !source_id) {
      return res.status(400).json({ error: 'numero, source_service, source_type e source_id sao obrigatorios' });
    }

    const { rows } = await db.query(
      `INSERT INTO logistics_shipments
       (tenant_id, numero, source_service, source_type, source_id, logistics_route_id, vehicle_id, driver_id, customer_id, delivery_address, scheduled_date, observacoes, created_by)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)
       RETURNING *`,
      [
        req.user.tenantId, numero, source_service, source_type, source_id, logistics_route_id || null,
        vehicle_id || null, driver_id || null, customer_id || null, delivery_address || null, scheduled_date || null, observacoes || null, req.user.id
      ]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function despachar(req, res, next) {
  try {
    const { rows } = await db.query(
      `UPDATE logistics_shipments
          SET status = 'despachada',
              updated_at = NOW()
        WHERE id = $1 AND tenant_id = $2 AND status = 'planeada'
      RETURNING *`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) {
      return res.status(404).json({ error: 'Expedicao nao encontrada ou nao pode ser despachada' });
    }
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function entregar(req, res, next) {
  try {
    const { rows } = await db.query(
      `UPDATE logistics_shipments
          SET status = 'entregue',
              updated_at = NOW()
        WHERE id = $1 AND tenant_id = $2 AND status IN ('despachada','em_transito')
      RETURNING *`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) {
      return res.status(404).json({ error: 'Expedicao nao encontrada ou nao pode ser entregue' });
    }
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function cancelar(req, res, next) {
  try {
    const { rows } = await db.query(
      `UPDATE logistics_shipments
          SET status = 'cancelada',
              updated_at = NOW()
        WHERE id = $1 AND tenant_id = $2 AND status IN ('planeada','despachada','em_transito')
      RETURNING *`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) {
      return res.status(404).json({ error: 'Expedicao nao encontrada ou nao pode ser cancelada' });
    }
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, obter, criar, despachar, entregar, cancelar };
