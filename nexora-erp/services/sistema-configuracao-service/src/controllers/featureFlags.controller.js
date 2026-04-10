'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT * FROM tenant_feature_flags WHERE tenant_id = $1 ORDER BY codigo ASC`,
      [req.user.tenantId]
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function upsert(req, res, next) {
  try {
    const { codigo, activo, configuracao } = req.body;
    if (!codigo) {
      return res.status(400).json({ error: 'codigo e obrigatorio' });
    }

    const { rows } = await db.query(
      `INSERT INTO tenant_feature_flags (tenant_id, codigo, activo, configuracao, updated_by)
       VALUES ($1,$2,$3,$4,$5)
       ON CONFLICT (tenant_id, codigo)
       DO UPDATE SET
         activo = EXCLUDED.activo,
         configuracao = EXCLUDED.configuracao,
         updated_by = EXCLUDED.updated_by,
         updated_at = NOW()
       RETURNING *`,
      [req.user.tenantId, codigo, !!activo, configuracao || null, req.user.id]
    );

    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, upsert };
