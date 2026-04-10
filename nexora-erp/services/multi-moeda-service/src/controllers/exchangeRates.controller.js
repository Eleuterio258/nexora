'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { base_currency_id, quote_currency_id, effective_date } = req.query;
    const params = [req.user.tenantId];
    const conditions = ['er.tenant_id = $1'];

    if (base_currency_id) {
      params.push(base_currency_id);
      conditions.push(`er.base_currency_id = $${params.length}`);
    }
    if (quote_currency_id) {
      params.push(quote_currency_id);
      conditions.push(`er.quote_currency_id = $${params.length}`);
    }
    if (effective_date) {
      params.push(effective_date);
      conditions.push(`er.effective_date = $${params.length}`);
    }

    const { rows } = await db.query(
      `SELECT er.*, cb.code AS base_code, cq.code AS quote_code
         FROM exchange_rates er
         JOIN currencies cb ON cb.id = er.base_currency_id
         JOIN currencies cq ON cq.id = er.quote_currency_id
        WHERE ${conditions.join(' AND ')}
        ORDER BY er.effective_date DESC, er.created_at DESC`,
      params
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function criar(req, res, next) {
  try {
    const { base_currency_id, quote_currency_id, rate, source, effective_date, is_official } = req.body;
    if (!base_currency_id || !quote_currency_id || !rate) {
      return res.status(400).json({ error: 'base_currency_id, quote_currency_id e rate sao obrigatorios' });
    }

    const { rows } = await db.query(
      `INSERT INTO exchange_rates
       (tenant_id, base_currency_id, quote_currency_id, rate, source, effective_date, is_official, created_by)
       VALUES ($1,$2,$3,$4,$5,COALESCE($6, CURRENT_DATE),$7,$8)
       RETURNING *`,
      [req.user.tenantId, base_currency_id, quote_currency_id, rate, source || 'manual', effective_date || null, !!is_official, req.user.id]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, criar };
