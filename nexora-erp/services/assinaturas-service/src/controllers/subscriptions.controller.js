'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { status, plan_id } = req.query;
    const params = [req.user.tenantId];
    const conditions = ['s.tenant_id = $1'];
    if (status) {
      params.push(status);
      conditions.push(`s.status = $${params.length}`);
    }
    if (plan_id) {
      params.push(plan_id);
      conditions.push(`s.plan_id = $${params.length}`);
    }

    const { rows } = await db.query(
      `SELECT s.*, p.nome AS plan_nome
         FROM subscriptions s
         JOIN subscription_plans p ON p.id = s.plan_id
        WHERE ${conditions.join(' AND ')}
        ORDER BY s.created_at DESC`,
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
      `SELECT * FROM subscriptions WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) {
      return res.status(404).json({ error: 'Assinatura nao encontrada' });
    }
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function criar(req, res, next) {
  try {
    const { company_id, plan_id, numero, starts_at, ends_at, next_billing_date, unit_price, moeda, auto_renew } = req.body;
    if (!plan_id || !numero || !starts_at) {
      return res.status(400).json({ error: 'plan_id, numero e starts_at sao obrigatorios' });
    }

    const { rows } = await db.query(
      `INSERT INTO subscriptions
       (tenant_id, company_id, plan_id, numero, starts_at, ends_at, next_billing_date, unit_price, moeda, auto_renew, created_by)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
       RETURNING *`,
      [req.user.tenantId, company_id || null, plan_id, numero, starts_at, ends_at || null, next_billing_date || null, unit_price || 0, moeda || 'MZN', auto_renew ?? true, req.user.id]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function atualizar(req, res, next) {
  try {
    const { ends_at, next_billing_date, unit_price, moeda, auto_renew, status } = req.body;
    const { rows } = await db.query(
      `UPDATE subscriptions
          SET ends_at = COALESCE($1, ends_at),
              next_billing_date = COALESCE($2, next_billing_date),
              unit_price = COALESCE($3, unit_price),
              moeda = COALESCE($4, moeda),
              auto_renew = COALESCE($5, auto_renew),
              status = COALESCE($6, status),
              updated_at = NOW()
        WHERE id = $7 AND tenant_id = $8
      RETURNING *`,
      [ends_at ?? null, next_billing_date ?? null, unit_price ?? null, moeda ?? null, auto_renew ?? null, status ?? null, req.params.id, req.user.tenantId]
    );
    if (!rows.length) {
      return res.status(404).json({ error: 'Assinatura nao encontrada' });
    }
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function activar(req, res, next) {
  try {
    const { rows } = await db.query(
      `UPDATE subscriptions
          SET status = 'activa',
              updated_at = NOW()
        WHERE id = $1 AND tenant_id = $2 AND status IN ('pendente','suspensa')
      RETURNING *`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) {
      return res.status(404).json({ error: 'Assinatura nao encontrada ou nao pode ser activada' });
    }
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function cancelar(req, res, next) {
  try {
    const { rows } = await db.query(
      `UPDATE subscriptions
          SET status = 'cancelada',
              updated_at = NOW()
        WHERE id = $1 AND tenant_id = $2 AND status IN ('activa','suspensa','pendente')
      RETURNING *`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) {
      return res.status(404).json({ error: 'Assinatura nao encontrada ou nao pode ser cancelada' });
    }
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, obter, criar, atualizar, activar, cancelar };
