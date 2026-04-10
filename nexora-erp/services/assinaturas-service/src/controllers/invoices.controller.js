'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { status, subscription_id } = req.query;
    const params = [req.user.tenantId];
    const conditions = ['tenant_id = $1'];
    if (status) {
      params.push(status);
      conditions.push(`status = $${params.length}`);
    }
    if (subscription_id) {
      params.push(subscription_id);
      conditions.push(`subscription_id = $${params.length}`);
    }

    const { rows } = await db.query(
      `SELECT * FROM subscription_invoices WHERE ${conditions.join(' AND ')} ORDER BY created_at DESC`,
      params
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function criar(req, res, next) {
  try {
    const { subscription_id, numero, billing_period_start, billing_period_end, due_date, valor_total, moeda } = req.body;
    if (!subscription_id || !numero || !billing_period_start || !billing_period_end || !due_date) {
      return res.status(400).json({ error: 'subscription_id, numero, billing_period_start, billing_period_end e due_date sao obrigatorios' });
    }

    const { rows } = await db.query(
      `INSERT INTO subscription_invoices
       (tenant_id, subscription_id, numero, billing_period_start, billing_period_end, due_date, valor_total, moeda)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
       RETURNING *`,
      [req.user.tenantId, subscription_id, numero, billing_period_start, billing_period_end, due_date, valor_total || 0, moeda || 'MZN']
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function pagar(req, res, next) {
  try {
    const { valor_pago } = req.body;
    if (valor_pago === undefined) {
      return res.status(400).json({ error: 'valor_pago e obrigatorio' });
    }

    const { rows } = await db.query(
      `UPDATE subscription_invoices
          SET valor_pago = valor_pago + $1,
              status = CASE WHEN (valor_pago + $1) >= valor_total THEN 'paga' ELSE status END
        WHERE id = $2 AND tenant_id = $3 AND status IN ('emitida','vencida')
      RETURNING *`,
      [valor_pago, req.params.id, req.user.tenantId]
    );
    if (!rows.length) {
      return res.status(404).json({ error: 'Factura de assinatura nao encontrada ou nao pode ser paga' });
    }
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, criar, pagar };
