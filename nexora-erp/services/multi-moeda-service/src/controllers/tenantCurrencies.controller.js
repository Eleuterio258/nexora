'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT tc.*, c.code, c.name, c.symbol, c.decimals
         FROM tenant_currencies tc
         JOIN currencies c ON c.id = tc.currency_id
        WHERE tc.tenant_id = $1
        ORDER BY tc.is_base DESC, c.code ASC`,
      [req.user.tenantId]
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function ativar(req, res, next) {
  try {
    const { currency_id, is_base } = req.body;
    if (!currency_id) {
      return res.status(400).json({ error: 'currency_id e obrigatorio' });
    }

    if (is_base) {
      await db.query(
        `UPDATE tenant_currencies SET is_base = FALSE WHERE tenant_id = $1`,
        [req.user.tenantId]
      );
    }

    const { rows } = await db.query(
      `INSERT INTO tenant_currencies (tenant_id, currency_id, is_base)
       VALUES ($1,$2,$3)
       ON CONFLICT (tenant_id, currency_id)
       DO UPDATE SET active = TRUE, is_base = EXCLUDED.is_base
       RETURNING *`,
      [req.user.tenantId, currency_id, !!is_base]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function definirBase(req, res, next) {
  const client = await db.connect();
  try {
    await client.query('BEGIN');

    const { rows: current } = await client.query(
      `SELECT * FROM tenant_currencies WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!current.length) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Moeda do tenant nao encontrada' });
    }

    await client.query(`UPDATE tenant_currencies SET is_base = FALSE WHERE tenant_id = $1`, [req.user.tenantId]);
    const { rows } = await client.query(
      `UPDATE tenant_currencies
          SET is_base = TRUE, active = TRUE
        WHERE id = $1 AND tenant_id = $2
      RETURNING *`,
      [req.params.id, req.user.tenantId]
    );

    await client.query('COMMIT');
    res.json(rows[0]);
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally {
    client.release();
  }
}

module.exports = { listar, ativar, definirBase };
