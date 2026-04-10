'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT * FROM logistics_vehicles WHERE tenant_id = $1 ORDER BY codigo ASC`,
      [req.user.tenantId]
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function criar(req, res, next) {
  try {
    const { codigo, matricula, descricao, capacidade_kg } = req.body;
    if (!codigo || !matricula) {
      return res.status(400).json({ error: 'codigo e matricula sao obrigatorios' });
    }

    const { rows } = await db.query(
      `INSERT INTO logistics_vehicles (tenant_id, codigo, matricula, descricao, capacidade_kg)
       VALUES ($1,$2,$3,$4,$5)
       RETURNING *`,
      [req.user.tenantId, codigo, matricula, descricao || null, capacidade_kg || null]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function atualizar(req, res, next) {
  try {
    const { descricao, capacidade_kg, activo } = req.body;
    const { rows } = await db.query(
      `UPDATE logistics_vehicles
          SET descricao = COALESCE($1, descricao),
              capacidade_kg = COALESCE($2, capacidade_kg),
              activo = COALESCE($3, activo),
              updated_at = NOW()
        WHERE id = $4 AND tenant_id = $5
      RETURNING *`,
      [descricao ?? null, capacidade_kg ?? null, activo ?? null, req.params.id, req.user.tenantId]
    );
    if (!rows.length) {
      return res.status(404).json({ error: 'Veiculo nao encontrado' });
    }
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, criar, atualizar };
