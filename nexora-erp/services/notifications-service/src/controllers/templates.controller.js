'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { canal_tipo } = req.query;
    const params = [req.user.tenantId];
    let sql = `SELECT * FROM notification_templates WHERE tenant_id = $1`;
    if (canal_tipo) {
      params.push(canal_tipo);
      sql += ` AND canal_tipo = $2`;
    }
    sql += ` ORDER BY codigo ASC`;

    const { rows } = await db.query(sql, params);
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function upsert(req, res, next) {
  try {
    const { codigo, canal_tipo, assunto, corpo, variaveis, activo } = req.body;
    if (!codigo || !canal_tipo || !corpo) {
      return res.status(400).json({ error: 'codigo, canal_tipo e corpo sao obrigatorios' });
    }

    const { rows } = await db.query(
      `INSERT INTO notification_templates (tenant_id, codigo, canal_tipo, assunto, corpo, variaveis, activo, updated_by)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
       ON CONFLICT (tenant_id, codigo, canal_tipo)
       DO UPDATE SET
         assunto = EXCLUDED.assunto,
         corpo = EXCLUDED.corpo,
         variaveis = EXCLUDED.variaveis,
         activo = EXCLUDED.activo,
         updated_by = EXCLUDED.updated_by,
         updated_at = NOW()
       RETURNING *`,
      [req.user.tenantId, codigo, canal_tipo, assunto || null, corpo, variaveis || null, activo ?? true, req.user.id]
    );
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, upsert };
