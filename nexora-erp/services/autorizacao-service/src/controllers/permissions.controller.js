'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { recurso } = req.query;
    const params = [];
    const cond = [];

    if (recurso) {
      params.push(recurso);
      cond.push(`recurso = $${params.length}`);
    }

    const where = cond.length ? `WHERE ${cond.join(' AND ')}` : '';
    const { rows } = await db.query(
      `SELECT id, codigo, nome, descricao, recurso, acao, created_at
         FROM permissions ${where}
        ORDER BY recurso, acao`,
      params
    );
    res.json(rows);
  } catch (err) { next(err); }
}

async function criar(req, res, next) {
  try {
    const { codigo, nome, descricao, recurso, acao } = req.body;
    if (!codigo || !nome) {
      return res.status(400).json({ error: 'codigo e nome são obrigatórios' });
    }
    const { rows } = await db.query(
      `INSERT INTO permissions (codigo, nome, descricao, recurso, acao)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [codigo, nome, descricao || null, recurso || null, acao || null]
    );
    res.status(201).json(rows[0]);
  } catch (err) { next(err); }
}

async function obter(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT * FROM permissions WHERE id = $1`,
      [req.params.id]
    );
    if (!rows.length) return res.status(404).json({ error: 'Permission não encontrada' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function actualizar(req, res, next) {
  try {
    const { codigo, nome, descricao, recurso, acao } = req.body;
    const { rows } = await db.query(
      `UPDATE permissions SET
         codigo    = COALESCE($1, codigo),
         nome      = COALESCE($2, nome),
         descricao = COALESCE($3, descricao),
         recurso   = COALESCE($4, recurso),
         acao      = COALESCE($5, acao)
       WHERE id = $6 RETURNING *`,
      [codigo || null, nome || null, descricao !== undefined ? descricao : null,
       recurso !== undefined ? recurso : null, acao !== undefined ? acao : null, req.params.id]
    );
    if (!rows.length) return res.status(404).json({ error: 'Permission não encontrada' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function eliminar(req, res, next) {
  try {
    const { rowCount } = await db.query(
      `DELETE FROM permissions WHERE id = $1`,
      [req.params.id]
    );
    if (!rowCount) return res.status(404).json({ error: 'Permission não encontrada' });
    res.status(204).send();
  } catch (err) { next(err); }
}

module.exports = { listar, criar, obter, actualizar, eliminar };
