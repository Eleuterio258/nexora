'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { tenantId } = req.user;
    const { tipo, status, data_inicio, data_fim, page = 1, limit = 20 } = req.query;

    const params = [tenantId];
    const conditions = ['tenant_id = $1'];

    if (tipo) {
      params.push(tipo);
      conditions.push(`tipo = $${params.length}`);
    }
    if (status) {
      params.push(status);
      conditions.push(`status = $${params.length}`);
    }
    if (data_inicio) {
      params.push(data_inicio);
      conditions.push(`data_pagamento >= $${params.length}`);
    }
    if (data_fim) {
      params.push(data_fim);
      conditions.push(`data_pagamento <= $${params.length}`);
    }

    const offset = (Number(page) - 1) * Number(limit);
    const where = conditions.join(' AND ');

    const { rows: countRows } = await db.query(
      `SELECT COUNT(*) AS total FROM payments WHERE ${where}`,
      params
    );

    params.push(Number(limit), offset);
    const { rows } = await db.query(
      `SELECT * FROM payments WHERE ${where}
       ORDER BY data_pagamento DESC, created_at DESC
       LIMIT $${params.length - 1} OFFSET $${params.length}`,
      params
    );

    res.json({ total: Number(countRows[0].total), page: Number(page), limit: Number(limit), data: rows });
  } catch (err) {
    next(err);
  }
}

async function criar(req, res, next) {
  const client = await db.connect();
  try {
    const { tenantId, id: userId } = req.user;
    const {
      tipo,
      data_pagamento,
      valor,
      payment_method_id,
      financial_category_id,
      referencia_tipo,
      referencia_id,
      descricao,
    } = req.body;

    if (!tipo || !data_pagamento || !valor) {
      const err = new Error('tipo, data_pagamento e valor são obrigatórios');
      err.status = 400;
      return next(err);
    }

    await client.query('BEGIN');

    const ano = new Date(data_pagamento).getFullYear();

    const { rows: seqRows } = await client.query(
      `SELECT COUNT(*)+1 AS seq FROM payments WHERE tenant_id=$1 AND EXTRACT(YEAR FROM created_at)=$2`,
      [tenantId, ano]
    );
    const numero = `PAG${ano}/${String(seqRows[0].seq).padStart(6, '0')}`;

    const { rows } = await client.query(
      `INSERT INTO payments
         (tenant_id, numero, payment_method_id, financial_category_id, tipo,
          data_pagamento, valor, referencia_tipo, referencia_id, descricao, criado_por)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
       RETURNING *`,
      [
        tenantId,
        numero,
        payment_method_id || null,
        financial_category_id || null,
        tipo,
        data_pagamento,
        valor,
        referencia_tipo || null,
        referencia_id || null,
        descricao || null,
        userId,
      ]
    );

    await client.query('COMMIT');
    res.status(201).json(rows[0]);
  } catch (err) {
    await client.query('ROLLBACK');
    if (err.code === '23514') {
      err.status = 400;
      err.message = 'Tipo ou status de pagamento inválido';
    }
    next(err);
  } finally {
    client.release();
  }
}

async function obter(req, res, next) {
  try {
    const { tenantId } = req.user;
    const { id } = req.params;

    const { rows } = await db.query(
      `SELECT p.*, pm.nome AS payment_method_nome, fc.nome AS category_nome
       FROM payments p
       LEFT JOIN payment_methods pm ON pm.id = p.payment_method_id
       LEFT JOIN financial_categories fc ON fc.id = p.financial_category_id
       WHERE p.id = $1 AND p.tenant_id = $2`,
      [id, tenantId]
    );

    if (!rows.length) {
      const err = new Error('Pagamento não encontrado');
      err.status = 404;
      return next(err);
    }

    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function cancelar(req, res, next) {
  const client = await db.connect();
  try {
    const { tenantId } = req.user;
    const { id } = req.params;

    await client.query('BEGIN');

    const { rows } = await client.query(
      'SELECT * FROM payments WHERE id = $1 AND tenant_id = $2 FOR UPDATE',
      [id, tenantId]
    );

    if (!rows.length) {
      await client.query('ROLLBACK');
      const err = new Error('Pagamento não encontrado');
      err.status = 404;
      return next(err);
    }

    const payment = rows[0];

    if (!['pendente', 'confirmado'].includes(payment.status)) {
      await client.query('ROLLBACK');
      const err = new Error('Apenas pagamentos pendentes ou confirmados podem ser cancelados');
      err.status = 409;
      return next(err);
    }

    const { rows: updated } = await client.query(
      `UPDATE payments SET status = 'cancelado' WHERE id = $1 AND tenant_id = $2 RETURNING *`,
      [id, tenantId]
    );

    await client.query('COMMIT');
    res.json(updated[0]);
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally {
    client.release();
  }
}

module.exports = { listar, criar, obter, cancelar };
