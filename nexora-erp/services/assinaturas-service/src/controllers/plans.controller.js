'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT * FROM subscription_plans WHERE tenant_id = $1 ORDER BY nome ASC`,
      [req.user.tenantId]
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function criar(req, res, next) {
  try {
    const { codigo, nome, billing_period, preco, moeda, limites } = req.body;
    if (!codigo || !nome) {
      return res.status(400).json({ error: 'codigo e nome sao obrigatorios' });
    }

    const { rows } = await db.query(
      `INSERT INTO subscription_plans (tenant_id, codigo, nome, billing_period, preco, moeda, limites)
       VALUES ($1,$2,$3,$4,$5,$6,$7)
       RETURNING *`,
      [req.user.tenantId, codigo, nome, billing_period || 'mensal', preco || 0, moeda || 'MZN', limites || null]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function atualizar(req, res, next) {
  try {
    const { nome, billing_period, preco, moeda, limites, activo } = req.body;
    const { rows } = await db.query(
      `UPDATE subscription_plans
          SET nome = COALESCE($1, nome),
              billing_period = COALESCE($2, billing_period),
              preco = COALESCE($3, preco),
              moeda = COALESCE($4, moeda),
              limites = COALESCE($5, limites),
              activo = COALESCE($6, activo),
              updated_at = NOW()
        WHERE id = $7 AND tenant_id = $8
      RETURNING *`,
      [nome ?? null, billing_period ?? null, preco ?? null, moeda ?? null, limites ?? null, activo ?? null, req.params.id, req.user.tenantId]
    );
    if (!rows.length) {
      return res.status(404).json({ error: 'Plano nao encontrado' });
    }
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, criar, atualizar };
