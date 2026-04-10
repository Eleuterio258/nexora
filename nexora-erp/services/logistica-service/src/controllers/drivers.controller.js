'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT * FROM logistics_drivers WHERE tenant_id = $1 ORDER BY nome ASC`,
      [req.user.tenantId]
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function criar(req, res, next) {
  try {
    const { codigo, nome, telefone, carta_numero } = req.body;
    if (!codigo || !nome) {
      return res.status(400).json({ error: 'codigo e nome sao obrigatorios' });
    }

    const { rows } = await db.query(
      `INSERT INTO logistics_drivers (tenant_id, codigo, nome, telefone, carta_numero)
       VALUES ($1,$2,$3,$4,$5)
       RETURNING *`,
      [req.user.tenantId, codigo, nome, telefone || null, carta_numero || null]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function atualizar(req, res, next) {
  try {
    const { telefone, carta_numero, activo } = req.body;
    const { rows } = await db.query(
      `UPDATE logistics_drivers
          SET telefone = COALESCE($1, telefone),
              carta_numero = COALESCE($2, carta_numero),
              activo = COALESCE($3, activo),
              updated_at = NOW()
        WHERE id = $4 AND tenant_id = $5
      RETURNING *`,
      [telefone ?? null, carta_numero ?? null, activo ?? null, req.params.id, req.user.tenantId]
    );
    if (!rows.length) {
      return res.status(404).json({ error: 'Motorista nao encontrado' });
    }
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, criar, atualizar };
