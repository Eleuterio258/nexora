'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { tenantId } = req.user;
    const { ativo } = req.query;

    let query = 'SELECT * FROM payment_methods WHERE tenant_id = $1';
    const params = [tenantId];

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
    const { codigo, nome, tipo, requer_referencia, ativo } = req.body;

    if (!codigo || !nome) {
      const err = new Error('codigo e nome são obrigatórios');
      err.status = 400;
      return next(err);
    }

    const { rows } = await db.query(
      `INSERT INTO payment_methods (tenant_id, codigo, nome, tipo, requer_referencia, ativo)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [
        tenantId,
        codigo,
        nome,
        tipo || 'outro',
        requer_referencia ?? false,
        ativo ?? true,
      ]
    );

    res.status(201).json(rows[0]);
  } catch (err) {
    if (err.code === '23505') {
      err.status = 409;
      err.message = 'Método de pagamento com esse código já existe';
    }
    next(err);
  }
}

async function obter(req, res, next) {
  try {
    const { tenantId } = req.user;
    const { id } = req.params;

    const { rows } = await db.query(
      'SELECT * FROM payment_methods WHERE id = $1 AND tenant_id = $2',
      [id, tenantId]
    );

    if (!rows.length) {
      const err = new Error('Método de pagamento não encontrado');
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
    const { codigo, nome, tipo, requer_referencia, ativo } = req.body;

    const { rows } = await db.query(
      `UPDATE payment_methods
       SET codigo = COALESCE($1, codigo),
           nome = COALESCE($2, nome),
           tipo = COALESCE($3, tipo),
           requer_referencia = COALESCE($4, requer_referencia),
           ativo = COALESCE($5, ativo)
       WHERE id = $6 AND tenant_id = $7
       RETURNING *`,
      [codigo, nome, tipo, requer_referencia, ativo, id, tenantId]
    );

    if (!rows.length) {
      const err = new Error('Método de pagamento não encontrado');
      err.status = 404;
      return next(err);
    }

    res.json(rows[0]);
  } catch (err) {
    if (err.code === '23505') {
      err.status = 409;
      err.message = 'Método de pagamento com esse código já existe';
    }
    next(err);
  }
}

async function remover(req, res, next) {
  try {
    const { tenantId } = req.user;
    const { id } = req.params;

    const { rowCount } = await db.query(
      'DELETE FROM payment_methods WHERE id = $1 AND tenant_id = $2',
      [id, tenantId]
    );

    if (!rowCount) {
      const err = new Error('Método de pagamento não encontrado');
      err.status = 404;
      return next(err);
    }

    res.status(204).end();
  } catch (err) {
    if (err.code === '23503') {
      err.status = 409;
      err.message = 'Método de pagamento em uso e não pode ser eliminado';
    }
    next(err);
  }
}

module.exports = { listar, criar, obter, atualizar, remover };
