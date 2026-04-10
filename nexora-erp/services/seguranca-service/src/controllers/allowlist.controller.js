'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT * FROM security_ip_allowlist WHERE tenant_id = $1 ORDER BY created_at DESC`,
      [req.user.tenantId]
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function criar(req, res, next) {
  try {
    const { descricao, ip_or_cidr } = req.body;
    if (!ip_or_cidr) {
      return res.status(400).json({ error: 'ip_or_cidr e obrigatorio' });
    }

    const { rows } = await db.query(
      `INSERT INTO security_ip_allowlist (tenant_id, descricao, ip_or_cidr, created_by)
       VALUES ($1,$2,$3,$4)
       RETURNING *`,
      [req.user.tenantId, descricao || null, ip_or_cidr, req.user.id]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function atualizar(req, res, next) {
  try {
    const { descricao, activo } = req.body;
    const { rows } = await db.query(
      `UPDATE security_ip_allowlist
          SET descricao = COALESCE($1, descricao),
              activo = COALESCE($2, activo),
              updated_at = NOW()
        WHERE id = $3 AND tenant_id = $4
      RETURNING *`,
      [descricao ?? null, activo ?? null, req.params.id, req.user.tenantId]
    );
    if (!rows.length) {
      return res.status(404).json({ error: 'Regra de allowlist nao encontrada' });
    }
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, criar, atualizar };
