'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT * FROM pos_terminals WHERE tenant_id = $1 ORDER BY nome ASC`,
      [req.user.tenantId]
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function criar(req, res, next) {
  try {
    const { codigo, nome, warehouse_id, caixa_id } = req.body;
    if (!codigo || !nome) {
      return res.status(400).json({ error: 'codigo e nome sao obrigatorios' });
    }

    const { rows } = await db.query(
      `INSERT INTO pos_terminals (tenant_id, codigo, nome, warehouse_id, caixa_id)
       VALUES ($1,$2,$3,$4,$5)
       RETURNING *`,
      [req.user.tenantId, codigo, nome, warehouse_id || null, caixa_id || null]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function atualizar(req, res, next) {
  try {
    const { nome, warehouse_id, caixa_id, activo } = req.body;
    const { rows } = await db.query(
      `UPDATE pos_terminals
          SET nome = COALESCE($1, nome),
              warehouse_id = COALESCE($2, warehouse_id),
              caixa_id = COALESCE($3, caixa_id),
              activo = COALESCE($4, activo),
              updated_at = NOW()
        WHERE id = $5 AND tenant_id = $6
      RETURNING *`,
      [nome ?? null, warehouse_id ?? null, caixa_id ?? null, activo ?? null, req.params.id, req.user.tenantId]
    );
    if (!rows.length) {
      return res.status(404).json({ error: 'Terminal nao encontrado' });
    }
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, criar, atualizar };
