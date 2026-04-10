'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT * FROM logistics_routes WHERE tenant_id = $1 ORDER BY codigo ASC`,
      [req.user.tenantId]
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function criar(req, res, next) {
  try {
    const { codigo, nome, origem, destino, distancia_km } = req.body;
    if (!codigo || !nome || !origem || !destino) {
      return res.status(400).json({ error: 'codigo, nome, origem e destino sao obrigatorios' });
    }

    const { rows } = await db.query(
      `INSERT INTO logistics_routes (tenant_id, codigo, nome, origem, destino, distancia_km)
       VALUES ($1,$2,$3,$4,$5,$6)
       RETURNING *`,
      [req.user.tenantId, codigo, nome, origem, destino, distancia_km || null]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, criar };
