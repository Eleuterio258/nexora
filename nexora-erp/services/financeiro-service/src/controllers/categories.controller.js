'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { tenantId } = req.user;
    const { tipo, ativo } = req.query;

    let query = 'SELECT * FROM financial_categories WHERE tenant_id = $1';
    const params = [tenantId];

    if (tipo) {
      params.push(tipo);
      query += ` AND tipo = $${params.length}`;
    }

    if (ativo !== undefined) {
      params.push(ativo === 'true');
      query += ` AND ativo = $${params.length}`;
    }

    query += ' ORDER BY nome ASC';

    const { rows } = await db.query(query, params);
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function criar(req, res, next) {
  try {
    const { tenantId } = req.user;
    const { parent_id, codigo, nome, tipo, ativo } = req.body;

    if (!nome || !tipo) {
      const err = new Error('nome e tipo são obrigatórios');
      err.status = 400;
      return next(err);
    }

    const { rows } = await db.query(
      `INSERT INTO financial_categories (tenant_id, parent_id, codigo, nome, tipo, ativo)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [tenantId, parent_id || null, codigo || null, nome, tipo, ativo ?? true]
    );

    res.status(201).json(rows[0]);
  } catch (err) {
    if (err.code === '23514') {
      err.status = 400;
      err.message = 'Tipo de categoria inválido';
    }
    next(err);
  }
}

async function obter(req, res, next) {
  try {
    const { tenantId } = req.user;
    const { id } = req.params;

    const { rows } = await db.query(
      'SELECT * FROM financial_categories WHERE id = $1 AND tenant_id = $2',
      [id, tenantId]
    );

    if (!rows.length) {
      const err = new Error('Categoria financeira não encontrada');
      err.status = 404;
      return next(err);
    }

    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function atualizar(req, res, next) {
  try {
    const { tenantId } = req.user;
    const { id } = req.params;
    const { parent_id, codigo, nome, tipo, ativo } = req.body;

    const { rows } = await db.query(
      `UPDATE financial_categories
       SET parent_id = COALESCE($1, parent_id),
           codigo = COALESCE($2, codigo),
           nome = COALESCE($3, nome),
           tipo = COALESCE($4, tipo),
           ativo = COALESCE($5, ativo)
       WHERE id = $6 AND tenant_id = $7
       RETURNING *`,
      [parent_id, codigo, nome, tipo, ativo, id, tenantId]
    );

    if (!rows.length) {
      const err = new Error('Categoria financeira não encontrada');
      err.status = 404;
      return next(err);
    }

    res.json(rows[0]);
  } catch (err) {
    if (err.code === '23514') {
      err.status = 400;
      err.message = 'Tipo de categoria inválido';
    }
    next(err);
  }
}

async function remover(req, res, next) {
  try {
    const { tenantId } = req.user;
    const { id } = req.params;

    const { rowCount } = await db.query(
      'DELETE FROM financial_categories WHERE id = $1 AND tenant_id = $2',
      [id, tenantId]
    );

    if (!rowCount) {
      const err = new Error('Categoria financeira não encontrada');
      err.status = 404;
      return next(err);
    }

    res.status(204).end();
  } catch (err) {
    if (err.code === '23503') {
      err.status = 409;
      err.message = 'Categoria em uso e não pode ser eliminada';
    }
    next(err);
  }
}

module.exports = { listar, criar, obter, atualizar, remover };
