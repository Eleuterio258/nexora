'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT id, codigo, nome, descricao, ativo, created_at
         FROM customer_groups
        WHERE tenant_id = $1
        ORDER BY nome ASC`,
      [req.user.tenantId]
    );
    res.json(rows);
  } catch (err) { next(err); }
}

async function criar(req, res, next) {
  try {
    const { codigo, nome, descricao } = req.body;
    if (!codigo || !nome) return res.status(400).json({ error: 'codigo e nome são obrigatórios' });

    const { rows } = await db.query(
      `INSERT INTO customer_groups (tenant_id, codigo, nome, descricao)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [req.user.tenantId, codigo, nome, descricao || null]
    );
    res.status(201).json(rows[0]);
  } catch (err) { next(err); }
}

async function obter(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT * FROM customer_groups WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Grupo não encontrado' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function actualizar(req, res, next) {
  try {
    const { codigo, nome, descricao, ativo } = req.body;
    const { rows } = await db.query(
      `UPDATE customer_groups
          SET codigo   = COALESCE($1, codigo),
              nome     = COALESCE($2, nome),
              descricao = COALESCE($3, descricao),
              ativo    = COALESCE($4, ativo)
        WHERE id = $5 AND tenant_id = $6
        RETURNING *`,
      [codigo || null, nome || null, descricao || null, ativo ?? null, req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Grupo não encontrado' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function eliminar(req, res, next) {
  try {
    const { rows: check } = await db.query(
      `SELECT COUNT(*) AS total FROM customers WHERE customer_group_id = $1`,
      [req.params.id]
    );
    if (Number(check[0].total) > 0) {
      return res.status(409).json({ error: 'Grupo tem clientes associados e não pode ser eliminado' });
    }
    const { rowCount } = await db.query(
      `DELETE FROM customer_groups WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!rowCount) return res.status(404).json({ error: 'Grupo não encontrado' });
    res.status(204).send();
  } catch (err) { next(err); }
}

module.exports = { listar, criar, obter, actualizar, eliminar };
