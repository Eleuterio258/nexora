'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { tenantId } = req.user;
    const { status, supplier_id, vencidas, page = 1, limit = 20 } = req.query;

    const params = [tenantId];
    const conditions = ['tenant_id = $1'];

    if (status) {
      params.push(status);
      conditions.push(`status = $${params.length}`);
    }
    if (supplier_id) {
      params.push(Number(supplier_id));
      conditions.push(`supplier_id = $${params.length}`);
    }
    if (vencidas === 'true') {
      conditions.push(`data_vencimento < CURRENT_DATE`);
      conditions.push(`status NOT IN ('liquidada','cancelada')`);
    }

    const offset = (Number(page) - 1) * Number(limit);
    const where = conditions.join(' AND ');

    const { rows: countRows } = await db.query(
      `SELECT COUNT(*) AS total FROM accounts_payable WHERE ${where}`,
      params
    );

    params.push(Number(limit), offset);
    const { rows } = await db.query(
      `SELECT * FROM accounts_payable WHERE ${where}
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
    const {
      supplier_id,
      financial_category_id,
      origem_tipo,
      origem_id,
      descricao,
      valor_total,
      data_emissao,
      data_vencimento,
    } = req.body;

    if (!valor_total || !data_emissao || !data_vencimento) {
      const err = new Error('valor_total, data_emissao e data_vencimento são obrigatórios');
      err.status = 400;
      return next(err);
    }

    await client.query('BEGIN');

    const ano = new Date(data_emissao).getFullYear();

    const { rows: seqRows } = await client.query(
      `SELECT COUNT(*)+1 AS seq FROM accounts_payable WHERE tenant_id=$1 AND EXTRACT(YEAR FROM created_at)=$2`,
      [tenantId, ano]
    );
    const numero = `AP${ano}/${String(seqRows[0].seq).padStart(6, '0')}`;

    const { rows } = await client.query(
      `INSERT INTO accounts_payable
         (tenant_id, numero, supplier_id, financial_category_id, origem_tipo, origem_id,
          descricao, valor_total, data_emissao, data_vencimento)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
       RETURNING *`,
      [
        tenantId,
        numero,
        supplier_id || null,
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
      `SELECT ap.*,
              json_agg(
                json_build_object(
                  'id', app2.id,
                  'payment_id', app2.payment_id,
                  'valor_imputado', app2.valor_imputado,
                  'data_imputacao', app2.data_imputacao,
                  'numero', p.numero,
                  'data_pagamento', p.data_pagamento
                )
              ) FILTER (WHERE app2.id IS NOT NULL) AS payments
       FROM accounts_payable ap
       LEFT JOIN accounts_payable_payments app2 ON app2.accounts_payable_id = ap.id
       LEFT JOIN payments p ON p.id = app2.payment_id
       WHERE ap.id = $1 AND ap.tenant_id = $2
       GROUP BY ap.id`,
      [id, tenantId]
    );

    if (!rows.length) {
      const err = new Error('Conta a pagar não encontrada');
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

    const { rows: apRows } = await client.query(
      'SELECT * FROM accounts_payable WHERE id = $1 AND tenant_id = $2 FOR UPDATE',
      [id, tenantId]
    );

    if (!apRows.length) {
      await client.query('ROLLBACK');
      const err = new Error('Conta a pagar não encontrada');
      err.status = 404;
      return next(err);
    }

    const ap = apRows[0];

    if (['liquidada', 'cancelada'].includes(ap.status)) {
      await client.query('ROLLBACK');
      const err = new Error('Conta a pagar já liquidada ou cancelada');
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
      `INSERT INTO accounts_payable_payments (accounts_payable_id, payment_id, valor_imputado)
       VALUES ($1, $2, $3)`,
      [id, payment_id, valor_imputado]
    );

    const novoValorPago = Number(ap.valor_pago) + Number(valor_imputado);
    const novoStatus = novoValorPago >= Number(ap.valor_total) ? 'liquidada' : 'parcial';

    const { rows: updated } = await client.query(
      `UPDATE accounts_payable
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
      err.message = 'Este pagamento já foi imputado a esta conta a pagar';
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
      'SELECT * FROM accounts_payable WHERE id = $1 AND tenant_id = $2 FOR UPDATE',
      [id, tenantId]
    );

    if (!rows.length) {
      await client.query('ROLLBACK');
      const err = new Error('Conta a pagar não encontrada');
      err.status = 404;
      return next(err);
    }

    if (rows[0].status === 'cancelada') {
      await client.query('ROLLBACK');
      const err = new Error('Conta a pagar já cancelada');
      err.status = 409;
      return next(err);
    }

    const { rows: updated } = await client.query(
      `UPDATE accounts_payable SET status = 'cancelada' WHERE id = $1 AND tenant_id = $2 RETURNING *`,
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
      `SELECT COUNT(*) AS total FROM accounts_payable
       WHERE tenant_id = $1 AND data_vencimento < CURRENT_DATE
         AND status NOT IN ('liquidada','cancelada')`,
      [tenantId]
    );

    const { rows } = await db.query(
      `SELECT * FROM accounts_payable
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
