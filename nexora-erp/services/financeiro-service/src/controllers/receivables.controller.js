'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { tenantId } = req.user;
    const { status, customer_id, vencidas, page = 1, limit = 20 } = req.query;

    const params = [tenantId];
    const conditions = ['tenant_id = $1'];

    if (status) {
      params.push(status);
      conditions.push(`status = $${params.length}`);
    }
    if (customer_id) {
      params.push(Number(customer_id));
      conditions.push(`customer_id = $${params.length}`);
    }
    if (vencidas === 'true') {
      conditions.push(`data_vencimento < CURRENT_DATE`);
      conditions.push(`status NOT IN ('liquidada','cancelada')`);
    }

    const offset = (Number(page) - 1) * Number(limit);
    const where = conditions.join(' AND ');

    const { rows: countRows } = await db.query(
      `SELECT COUNT(*) AS total FROM accounts_receivable WHERE ${where}`,
      params
    );

    params.push(Number(limit), offset);
    const { rows } = await db.query(
      `SELECT * FROM accounts_receivable WHERE ${where}
       ORDER BY data_vencimento ASC, created_at DESC
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
    const { tenantId } = req.user;
    const { customer_id, financial_category_id, origem_tipo, origem_id, descricao, valor_total, data_emissao, data_vencimento } = req.body;

    if (!customer_id || !valor_total || !data_emissao || !data_vencimento) {
      const err = new Error('customer_id, valor_total, data_emissao e data_vencimento são obrigatórios');
      err.status = 400;
      return next(err);
    }

    await client.query('BEGIN');

    const ano = new Date(data_emissao).getFullYear();

    const { rows: seqRows } = await client.query(
      `SELECT COUNT(*)+1 AS seq FROM accounts_receivable WHERE tenant_id=$1 AND EXTRACT(YEAR FROM created_at)=$2`,
      [tenantId, ano]
    );
    const numero = `AR${ano}/${String(seqRows[0].seq).padStart(6, '0')}`;

    const { rows } = await client.query(
      `INSERT INTO accounts_receivable
         (tenant_id, numero, customer_id, financial_category_id, origem_tipo, origem_id,
          descricao, valor_total, data_emissao, data_vencimento)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
       RETURNING *`,
      [
        tenantId,
        numero,
        customer_id,
        financial_category_id || null,
        origem_tipo || null,
        origem_id || null,
        descricao || null,
        valor_total,
        data_emissao,
        data_vencimento,
      ]
    );

    await client.query('COMMIT');
    res.status(201).json(rows[0]);
  } catch (err) {
    await client.query('ROLLBACK');
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
      `SELECT ar.*,
              json_agg(
                json_build_object(
                  'id', arp.id,
                  'payment_id', arp.payment_id,
                  'valor_imputado', arp.valor_imputado,
                  'data_imputacao', arp.data_imputacao,
                  'numero', p.numero,
                  'data_pagamento', p.data_pagamento
                )
              ) FILTER (WHERE arp.id IS NOT NULL) AS payments
       FROM accounts_receivable ar
       LEFT JOIN accounts_receivable_payments arp ON arp.accounts_receivable_id = ar.id
       LEFT JOIN payments p ON p.id = arp.payment_id
       WHERE ar.id = $1 AND ar.tenant_id = $2
       GROUP BY ar.id`,
      [id, tenantId]
    );

    if (!rows.length) {
      const err = new Error('Conta a receber não encontrada');
      err.status = 404;
      return next(err);
    }

    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function liquidar(req, res, next) {
  const client = await db.connect();
  try {
    const { tenantId } = req.user;
    const { id } = req.params;
    const { payment_id, valor_imputado } = req.body;

    if (!payment_id || !valor_imputado) {
      const err = new Error('payment_id e valor_imputado são obrigatórios');
      err.status = 400;
      return next(err);
    }

    await client.query('BEGIN');

    const { rows: arRows } = await client.query(
      'SELECT * FROM accounts_receivable WHERE id = $1 AND tenant_id = $2 FOR UPDATE',
      [id, tenantId]
    );

    if (!arRows.length) {
      await client.query('ROLLBACK');
      const err = new Error('Conta a receber não encontrada');
      err.status = 404;
      return next(err);
    }

    const ar = arRows[0];

    if (['liquidada', 'cancelada'].includes(ar.status)) {
      await client.query('ROLLBACK');
      const err = new Error('Conta a receber já liquidada ou cancelada');
      err.status = 409;
      return next(err);
    }

    const { rows: payRows } = await client.query(
      'SELECT * FROM payments WHERE id = $1 AND tenant_id = $2',
      [payment_id, tenantId]
    );

    if (!payRows.length) {
      await client.query('ROLLBACK');
      const err = new Error('Pagamento não encontrado');
      err.status = 404;
      return next(err);
    }

    await client.query(
      `INSERT INTO accounts_receivable_payments (accounts_receivable_id, payment_id, valor_imputado)
       VALUES ($1, $2, $3)`,
      [id, payment_id, valor_imputado]
    );

    const novoValorPago = Number(ar.valor_pago) + Number(valor_imputado);
    const novoStatus = novoValorPago >= Number(ar.valor_total) ? 'liquidada' : 'parcial';

    const { rows: updated } = await client.query(
      `UPDATE accounts_receivable
       SET valor_pago = $1, status = $2
       WHERE id = $3
       RETURNING *`,
      [novoValorPago, novoStatus, id]
    );

    await client.query('COMMIT');
    res.json(updated[0]);
  } catch (err) {
    await client.query('ROLLBACK');
    if (err.code === '23505') {
      err.status = 409;
      err.message = 'Este pagamento já foi imputado a esta conta a receber';
    }
    next(err);
  } finally {
    client.release();
  }
}

async function cancelar(req, res, next) {
  const client = await db.connect();
  try {
    const { tenantId } = req.user;
    const { id } = req.params;

    await client.query('BEGIN');

    const { rows } = await client.query(
      'SELECT * FROM accounts_receivable WHERE id = $1 AND tenant_id = $2 FOR UPDATE',
      [id, tenantId]
    );

    if (!rows.length) {
      await client.query('ROLLBACK');
      const err = new Error('Conta a receber não encontrada');
      err.status = 404;
      return next(err);
    }

    if (rows[0].status === 'cancelada') {
      await client.query('ROLLBACK');
      const err = new Error('Conta a receber já cancelada');
      err.status = 409;
      return next(err);
    }

    const { rows: updated } = await client.query(
      `UPDATE accounts_receivable SET status = 'cancelada' WHERE id = $1 AND tenant_id = $2 RETURNING *`,
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

async function vencidas(req, res, next) {
  try {
    const { tenantId } = req.user;
    const { page = 1, limit = 20 } = req.query;

    const offset = (Number(page) - 1) * Number(limit);

    const { rows: countRows } = await db.query(
      `SELECT COUNT(*) AS total FROM accounts_receivable
       WHERE tenant_id = $1 AND data_vencimento < CURRENT_DATE
         AND status NOT IN ('liquidada','cancelada')`,
      [tenantId]
    );

    const { rows } = await db.query(
      `SELECT * FROM accounts_receivable
       WHERE tenant_id = $1 AND data_vencimento < CURRENT_DATE
         AND status NOT IN ('liquidada','cancelada')
       ORDER BY data_vencimento ASC
       LIMIT $2 OFFSET $3`,
      [tenantId, Number(limit), offset]
    );

    res.json({ total: Number(countRows[0].total), page: Number(page), limit: Number(limit), data: rows });
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, criar, obter, liquidar, cancelar, vencidas };
