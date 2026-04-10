'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT * FROM product_units WHERE tenant_id = $1 ORDER BY nome ASC`,
      [req.user.tenantId]
    );
    res.json(rows);
  } catch (err) { next(err); }
}

async function criar(req, res, next) {
  try {
    const { codigo, nome, simbolo, casas_decimais } = req.body;
    if (!codigo || !nome) return res.status(400).json({ error: 'codigo e nome são obrigatórios' });
    const { rows } = await db.query(
      `INSERT INTO product_units (tenant_id, codigo, nome, simbolo, casas_decimais)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [req.user.tenantId, codigo, nome, simbolo || null, casas_decimais ?? 2]
    );
    res.status(201).json(rows[0]);
  } catch (err) { next(err); }
}

async function obter(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT * FROM product_units WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Unidade não encontrada' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function actualizar(req, res, next) {
  try {
    const { codigo, nome, simbolo, casas_decimais } = req.body;
    const { rows } = await db.query(
      `UPDATE product_units SET
         codigo         = COALESCE($1, codigo),
         nome           = COALESCE($2, nome),
         simbolo        = COALESCE($3, simbolo),
         casas_decimais = COALESCE($4, casas_decimais)
       WHERE id = $5 AND tenant_id = $6 RETURNING *`,
      [codigo ?? null, nome ?? null, simbolo ?? null, casas_decimais ?? null, req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Unidade não encontrada' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function remover(req, res, next) {
  try {
    const { rowCount } = await db.query(
      `DELETE FROM product_units WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!rowCount) return res.status(404).json({ error: 'Unidade não encontrada' });
    res.status(204).send();
  } catch (err) { next(err); }
}

module.exports = { listar, criar, obter, actualizar, remover };
