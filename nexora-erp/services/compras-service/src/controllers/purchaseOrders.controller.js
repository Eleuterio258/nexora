'use strict';

const db = require('../config/db');
const { normalizeItems, summarizeItems } = require('../lib/calculos');

async function listar(req, res, next) {
  try {
    const { status, supplier_id } = req.query;
    const params = [req.user.tenantId];
    const conditions = ['po.tenant_id = $1'];

    if (status) {
      params.push(status);
      conditions.push(`po.status = $${params.length}`);
    }

    if (supplier_id) {
      params.push(supplier_id);
      conditions.push(`po.supplier_id = $${params.length}`);
    }

    const { rows } = await db.query(
      `SELECT po.id, po.numero, po.order_date, po.expected_date, po.status, po.moeda, po.total,
              po.created_at, s.nome AS supplier_nome
         FROM purchase_orders po
         JOIN suppliers s ON s.id = po.supplier_id
        WHERE ${conditions.join(' AND ')}
        ORDER BY po.created_at DESC`,
      params
    );

    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function detalhar(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT po.*, s.nome AS supplier_nome, s.nuit AS supplier_nuit
         FROM purchase_orders po
         JOIN suppliers s ON s.id = po.supplier_id
        WHERE po.id = $1 AND po.tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );

    if (!rows.length) {
      return res.status(404).json({ error: 'Ordem de compra nao encontrada' });
    }

    const { rows: items } = await db.query(
      `SELECT * FROM purchase_order_items WHERE purchase_order_id = $1 ORDER BY id ASC`,
      [req.params.id]
    );

    res.json({ ...rows[0], items });
  } catch (err) {
    next(err);
  }
}

async function criar(req, res, next) {
  const client = await db.connect();
  try {
    await client.query('BEGIN');

    const { supplier_id, numero, order_date, expected_date, moeda, observacoes, items } = req.body;
    if (!supplier_id || !numero) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'supplier_id e numero sao obrigatorios' });
    }

    const normalizedItems = normalizeItems(items);
    const totals = summarizeItems(normalizedItems);

    const { rows: suppliers } = await client.query(
      `SELECT id FROM suppliers WHERE id = $1 AND tenant_id = $2 AND estado = 'ativo'`,
      [supplier_id, req.user.tenantId]
    );

    if (!suppliers.length) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Fornecedor nao encontrado ou inativo' });
    }

    const { rows } = await client.query(
      `INSERT INTO purchase_orders
       (tenant_id, supplier_id, numero, order_date, expected_date, moeda, subtotal, desconto_total, imposto_total, total, observacoes, criado_por)
       VALUES ($1,$2,$3,COALESCE($4, CURRENT_DATE),$5,$6,$7,$8,$9,$10,$11,$12)
       RETURNING *`,
      [
        req.user.tenantId,
        supplier_id,
        numero,
        order_date || null,
        expected_date || null,
        moeda || 'MZN',
        totals.subtotal,
        totals.desconto_total,
        totals.imposto_total,
        totals.total,
        observacoes || null,
        req.user.id
      ]
    );

    for (const item of normalizedItems) {
      await client.query(
        `INSERT INTO purchase_order_items
         (purchase_order_id, product_id, descricao, unidade, quantity, unit_price, desconto, tax_rate, tax_amount, total)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)`,
        [
          rows[0].id,
          item.product_id,
          item.descricao,
          item.unidade,
          item.quantity,
          item.unit_price,
          item.desconto,
          item.tax_rate,
          item.tax_amount,
          item.total
        ]
      );
    }

    await client.query('COMMIT');
    res.status(201).json(rows[0]);
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally {
    client.release();
  }
}

async function aprovar(req, res, next) {
  try {
    const { rows } = await db.query(
      `UPDATE purchase_orders
          SET status = 'aprovada',
              aprovado_por = $1,
              aprovado_em = NOW(),
              updated_at = NOW()
        WHERE id = $2 AND tenant_id = $3 AND status = 'rascunho'
      RETURNING *`,
      [req.user.id, req.params.id, req.user.tenantId]
    );

    if (!rows.length) {
      return res.status(409).json({ error: 'Apenas ordens em rascunho podem ser aprovadas' });
    }

    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, detalhar, criar, aprovar };
