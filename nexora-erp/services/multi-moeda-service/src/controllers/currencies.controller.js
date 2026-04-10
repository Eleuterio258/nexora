'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT * FROM currencies ORDER BY code ASC`
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function criar(req, res, next) {
  try {
    const { code, name, symbol, decimals } = req.body;
    if (!code || !name) {
      return res.status(400).json({ error: 'code e name sao obrigatorios' });
    }

    const { rows } = await db.query(
      `INSERT INTO currencies (code, name, symbol, decimals)
       VALUES (UPPER($1), $2, $3, $4)
       RETURNING *`,
      [code, name, symbol || null, decimals ?? 2]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function atualizar(req, res, next) {
  try {
    const { name, symbol, decimals, active } = req.body;
    const { rows } = await db.query(
      `UPDATE currencies
          SET name = COALESCE($1, name),
              symbol = COALESCE($2, symbol),
              decimals = COALESCE($3, decimals),
              active = COALESCE($4, active)
        WHERE id = $5
      RETURNING *`,
      [name ?? null, symbol ?? null, decimals ?? null, active ?? null, req.params.id]
    );

    if (!rows.length) {
      return res.status(404).json({ error: 'Moeda nao encontrada' });
    }

    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, criar, atualizar };
