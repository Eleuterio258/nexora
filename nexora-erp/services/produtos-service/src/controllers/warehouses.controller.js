'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { ativo } = req.query;
    const params = [req.user.tenantId];
    const cond = ['tenant_id = $1'];
    if (ativo !== undefined) { params.push(ativo === 'true'); cond.push(`ativo = $${params.length}`); }
    const { rows } = await db.query(
      `SELECT * FROM warehouses WHERE ${cond.join(' AND ')} ORDER BY nome ASC`,
      params
    );
    res.json(rows);
  } catch (err) { next(err); }
}

async function criar(req, res, next) {
  try {
    const { codigo, nome, localizacao } = req.body;
    if (!codigo || !nome) return res.status(400).json({ error: 'codigo e nome são obrigatórios' });
    const { rows } = await db.query(
      `INSERT INTO warehouses (tenant_id, codigo, nome, localizacao)
       VALUES ($1, $2, $3, $4) RETURNING *`,
      [req.user.tenantId, codigo, nome, localizacao || null]
    );
    res.status(201).json(rows[0]);
  } catch (err) { next(err); }
}

async function obter(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT * FROM warehouses WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Armazém não encontrado' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function actualizar(req, res, next) {
  try {
    const { codigo, nome, localizacao, ativo } = req.body;
    const { rows } = await db.query(
      `UPDATE warehouses SET
         codigo      = COALESCE($1, codigo),
         nome        = COALESCE($2, nome),
         localizacao = COALESCE($3, localizacao),
         ativo       = COALESCE($4, ativo)
       WHERE id = $5 AND tenant_id = $6 RETURNING *`,
      [codigo ?? null, nome ?? null, localizacao ?? null, ativo ?? null, req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Armazém não encontrado' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function remover(req, res, next) {
  try {
    const { rowCount } = await db.query(
      `DELETE FROM warehouses WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!rowCount) return res.status(404).json({ error: 'Armazém não encontrado' });
    res.status(204).send();
  } catch (err) { next(err); }
}

module.exports = { listar, criar, obter, actualizar, remover };
