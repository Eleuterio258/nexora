'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT id, tenant_id, codigo, activo, endpoint_url, configuracao, updated_by, created_at, updated_at
         FROM tenant_integrations
        WHERE tenant_id = $1
        ORDER BY codigo ASC`,
      [req.user.tenantId]
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function upsert(req, res, next) {
  try {
    const { codigo, activo, endpoint_url, credenciais, configuracao } = req.body;
    if (!codigo) {
      return res.status(400).json({ error: 'codigo e obrigatorio' });
    }

    const { rows } = await db.query(
      `INSERT INTO tenant_integrations
       (tenant_id, codigo, activo, endpoint_url, credenciais, configuracao, updated_by)
       VALUES ($1,$2,$3,$4,$5,$6,$7)
       ON CONFLICT (tenant_id, codigo)
       DO UPDATE SET
         activo = EXCLUDED.activo,
         endpoint_url = EXCLUDED.endpoint_url,
         credenciais = EXCLUDED.credenciais,
         configuracao = EXCLUDED.configuracao,
         updated_by = EXCLUDED.updated_by,
         updated_at = NOW()
       RETURNING id, tenant_id, codigo, activo, endpoint_url, configuracao, updated_by, created_at, updated_at`,
      [req.user.tenantId, codigo, !!activo, endpoint_url || null, credenciais || null, configuracao || null, req.user.id]
    );

    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, upsert };
