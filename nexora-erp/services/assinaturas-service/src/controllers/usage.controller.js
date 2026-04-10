'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { subscription_id, recurso } = req.query;
    const params = [req.user.tenantId];
    const conditions = ['tenant_id = $1'];
    if (subscription_id) {
      params.push(subscription_id);
      conditions.push(`subscription_id = $${params.length}`);
    }
    if (recurso) {
      params.push(recurso);
      conditions.push(`recurso = $${params.length}`);
    }

    const { rows } = await db.query(
      `SELECT * FROM subscription_usage WHERE ${conditions.join(' AND ')} ORDER BY created_at DESC`,
      params
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function registar(req, res, next) {
  try {
    const { subscription_id, recurso, quantidade, periodo, metadata } = req.body;
    if (!subscription_id || !recurso || quantidade === undefined) {
      return res.status(400).json({ error: 'subscription_id, recurso e quantidade sao obrigatorios' });
    }

    const { rows } = await db.query(
      `INSERT INTO subscription_usage (tenant_id, subscription_id, recurso, quantidade, periodo, metadata)
       VALUES ($1,$2,$3,$4,$5,$6)
       RETURNING *`,
      [req.user.tenantId, subscription_id, recurso, quantidade, periodo || null, metadata || null]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, registar };
