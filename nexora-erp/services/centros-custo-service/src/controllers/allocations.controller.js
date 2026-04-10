'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { cost_center_id, source_service, source_type, source_id } = req.query;
    const params = [req.user.tenantId];
    const conditions = ['tenant_id = $1'];
    if (cost_center_id) {
      params.push(cost_center_id);
      conditions.push(`cost_center_id = $${params.length}`);
    }
    if (source_service) {
      params.push(source_service);
      conditions.push(`source_service = $${params.length}`);
    }
    if (source_type) {
      params.push(source_type);
      conditions.push(`source_type = $${params.length}`);
    }
    if (source_id) {
      params.push(source_id);
      conditions.push(`source_id = $${params.length}`);
    }

    const { rows } = await db.query(
      `SELECT * FROM cost_center_allocations WHERE ${conditions.join(' AND ')} ORDER BY created_at DESC`,
      params
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function criar(req, res, next) {
  try {
    const {
      cost_center_id, source_service, source_type, source_id, source_line_id,
      descricao, valor, moeda, allocation_percent, referencia_tipo, referencia_id
    } = req.body;

    if (!cost_center_id || !source_service || !source_type || !source_id || valor === undefined) {
      return res.status(400).json({ error: 'cost_center_id, source_service, source_type, source_id e valor sao obrigatorios' });
    }

    const { rows } = await db.query(
      `INSERT INTO cost_center_allocations
       (tenant_id, cost_center_id, source_service, source_type, source_id, source_line_id, descricao, valor, moeda, allocation_percent, referencia_tipo, referencia_id, created_by)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)
       RETURNING *`,
      [
        req.user.tenantId, cost_center_id, source_service, source_type, source_id, source_line_id || null,
        descricao || null, valor, moeda || 'MZN', allocation_percent ?? 100, referencia_tipo || null, referencia_id || null, req.user.id
      ]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, criar };
