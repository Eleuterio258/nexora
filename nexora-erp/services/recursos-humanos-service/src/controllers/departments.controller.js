'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT * FROM hr_departments WHERE tenant_id = $1 ORDER BY nome ASC`,
      [req.user.tenantId]
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function criar(req, res, next) {
  try {
    const { codigo, nome, descricao } = req.body;
    if (!codigo || !nome) {
      return res.status(400).json({ error: 'codigo e nome sao obrigatorios' });
    }

    const { rows } = await db.query(
      `INSERT INTO hr_departments (tenant_id, codigo, nome, descricao)
       VALUES ($1,$2,$3,$4)
       RETURNING *`,
      [req.user.tenantId, codigo, nome, descricao || null]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function atualizar(req, res, next) {
  try {
    const { nome, descricao, ativo } = req.body;
    const { rows } = await db.query(
      `UPDATE hr_departments
          SET nome = COALESCE($1, nome),
              descricao = COALESCE($2, descricao),
              ativo = COALESCE($3, ativo),
              updated_at = NOW()
        WHERE id = $4 AND tenant_id = $5
      RETURNING *`,
      [nome ?? null, descricao ?? null, ativo ?? null, req.params.id, req.user.tenantId]
    );

    if (!rows.length) {
      return res.status(404).json({ error: 'Departamento nao encontrado' });
    }

    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, criar, atualizar };
