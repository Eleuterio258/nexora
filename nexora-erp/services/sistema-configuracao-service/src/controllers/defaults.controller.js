'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT chave, valor, updated_at FROM tenant_defaults WHERE tenant_id = $1 ORDER BY chave ASC`,
      [req.user.tenantId]
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function upsert(req, res, next) {
  try {
    const { chave, valor } = req.body;
    if (!chave) {
      return res.status(400).json({ error: 'chave e obrigatoria' });
    }

    const { rows } = await db.query(
      `INSERT INTO tenant_defaults (tenant_id, chave, valor, updated_by)
       VALUES ($1,$2,$3,$4)
       ON CONFLICT (tenant_id, chave)
       DO UPDATE SET valor = EXCLUDED.valor, updated_by = EXCLUDED.updated_by, updated_at = NOW()
       RETURNING *`,
      [req.user.tenantId, chave, valor ?? null, req.user.id]
    );

    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, upsert };
