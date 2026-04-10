'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT * FROM accounting_journals WHERE tenant_id = $1 ORDER BY codigo ASC`,
      [req.user.tenantId]
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function criar(req, res, next) {
  try {
    const { codigo, nome, tipo } = req.body;
    if (!codigo || !nome || !tipo) {
      return res.status(400).json({ error: 'codigo, nome e tipo sao obrigatorios' });
    }

    const { rows } = await db.query(
      `INSERT INTO accounting_journals (tenant_id, codigo, nome, tipo)
       VALUES ($1,$2,$3,$4)
       RETURNING *`,
      [req.user.tenantId, codigo, nome, tipo]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, criar };
