'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT * FROM security_policies WHERE tenant_id = $1 ORDER BY codigo ASC`,
      [req.user.tenantId]
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function upsert(req, res, next) {
  try {
    const { codigo, nome, configuracao, activo } = req.body;
    if (!codigo || !nome || !configuracao) {
      return res.status(400).json({ error: 'codigo, nome e configuracao sao obrigatorios' });
    }

    const { rows } = await db.query(
      `INSERT INTO security_policies (tenant_id, codigo, nome, configuracao, activo, updated_by)
       VALUES ($1,$2,$3,$4,$5,$6)
       ON CONFLICT (tenant_id, codigo)
       DO UPDATE SET
         nome = EXCLUDED.nome,
         configuracao = EXCLUDED.configuracao,
         activo = EXCLUDED.activo,
         updated_by = EXCLUDED.updated_by,
         updated_at = NOW()
       RETURNING *`,
      [req.user.tenantId, codigo, nome, configuracao, activo ?? true, req.user.id]
    );
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, upsert };
