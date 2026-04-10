'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT id, tenant_id, codigo, nome, tipo, activo, updated_by, created_at, updated_at
         FROM notification_channels
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
    const { codigo, nome, tipo, configuracao, activo } = req.body;
    if (!codigo || !nome || !tipo) {
      return res.status(400).json({ error: 'codigo, nome e tipo sao obrigatorios' });
    }

    const { rows } = await db.query(
      `INSERT INTO notification_channels (tenant_id, codigo, nome, tipo, configuracao, activo, updated_by)
       VALUES ($1,$2,$3,$4,$5,$6,$7)
       ON CONFLICT (tenant_id, codigo)
       DO UPDATE SET
         nome = EXCLUDED.nome,
         tipo = EXCLUDED.tipo,
         configuracao = EXCLUDED.configuracao,
         activo = EXCLUDED.activo,
         updated_by = EXCLUDED.updated_by,
         updated_at = NOW()
       RETURNING id, tenant_id, codigo, nome, tipo, activo, updated_by, created_at, updated_at`,
      [req.user.tenantId, codigo, nome, tipo, configuracao || null, activo ?? true, req.user.id]
    );
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, upsert };
