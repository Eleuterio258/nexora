'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { purchase_order_id } = req.query;
    const params = [req.user.tenantId];
    const conditions = ['gr.tenant_id = $1'];

    if (purchase_order_id) {
      params.push(purchase_order_id);
      conditions.push(`gr.purchase_order_id = $${params.length}`);
    }

    const { rows } = await db.query(
      `SELECT gr.id, gr.numero, gr.receipt_date, gr.status, gr.purchase_order_id, gr.supplier_id, gr.created_at,
              po.numero AS ordem_numero, s.nome AS supplier_nome
         FROM goods_receipts gr
         JOIN purchase_orders po ON po.id = gr.purchase_order_id
         JOIN suppliers s ON s.id = gr.supplier_id
        WHERE ${conditions.join(' AND ')}
        ORDER BY gr.created_at DESC`,
      params
    );

    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function criar(req, res, next) {
  const client = await db.connect();
  try {
    await client.query('BEGIN');

    const { purchase_order_id, numero, receipt_date, warehouse_id, observacoes, items } = req.body;
    if (!purchase_order_id || !numero || !Array.isArray(items) || !items.length) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'purchase_order_id, numero e items sao obrigatorios' });
    }

    const { rows: orders } = await client.query(
      `SELECT * FROM purchase_orders WHERE id = $1 AND tenant_id = $2 FOR UPDATE`,
      [purchase_order_id, req.user.tenantId]
    );

    if (!orders.length) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Ordem de compra nao encontrada' });
    }

    const order = orders[0];
    if (!['aprovada', 'parcial'].includes(order.status)) {
      await client.query('ROLLBACK');
      return res.status(409).json({ error: 'A ordem deve estar aprovada ou parcial para receber mercadoria' });
    }

    const { rows: orderItems } = await client.query(
      `SELECT * FROM purchase_order_items WHERE purchase_order_id = $1 ORDER BY id ASC`,
      [purchase_order_id]
    );
    const orderItemsById = new Map(orderItems.map((item) => [String(item.id), item]));

    const { rows: receiptRows } = await client.query(
      `INSERT INTO goods_receipts
       (tenant_id, purchase_order_id, supplier_id, numero, receipt_date, warehouse_id, observacoes, criado_por)
       VALUES ($1,$2,$3,$4,COALESCE($5, CURRENT_DATE),$6,$7,$8)
       RETURNING *`,
      [req.user.tenantId, order.id, order.supplier_id, numero, receipt_date || null, warehouse_id || null, observacoes || null, req.user.id]
    );

    for (const item of items) {
      const orderItem = orderItemsById.get(String(item.purchase_order_item_id));
      const qty = Number(item.quantity_received);
      const unitCost = Number(item.unit_cost ?? orderItem?.unit_price);

      if (!orderItem || Number.isNaN(qty) || qty <= 0 || Number.isNaN(unitCost) || unitCost < 0) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'Cada linha de rececao deve referenciar um item valido da ordem' });
      }

      const disponivel = Number(orderItem.quantity) - Number(orderItem.received_quantity);
      if (qty > disponivel) {
        await client.query('ROLLBACK');
        return res.status(422).json({ error: `Quantidade recebida excede o saldo do item ${orderItem.id}` });
      }

      await client.query(
        `INSERT INTO goods_receipt_items
         (goods_receipt_id, purchase_order_item_id, product_id, quantity_received, unit_cost, lote, validade)
         VALUES ($1,$2,$3,$4,$5,$6,$7)`,
        [receiptRows[0].id, orderItem.id, orderItem.product_id, qty, unitCost, item.lote || null, item.validade || null]
      );

      await client.query(
        `UPDATE purchase_order_items
            SET received_quantity = received_quantity + $1
          WHERE id = $2`,
        [qty, orderItem.id]
      );
    }

    const { rows: totals } = await client.query(
      `SELECT COUNT(*) FILTER (WHERE received_quantity >= quantity) AS completos,
              COUNT(*) AS total
         FROM purchase_order_items
        WHERE purchase_order_id = $1`,
      [purchase_order_id]
    );

    const nextStatus = Number(totals[0].completos) === Number(totals[0].total) ? 'recebida' : 'parcial';
    await client.query(
      `UPDATE purchase_orders SET status = $1, updated_at = NOW() WHERE id = $2`,
      [nextStatus, purchase_order_id]
    );

    await client.query('COMMIT');
    res.status(201).json(receiptRows[0]);
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally {
    client.release();
  }
}

module.exports = { listar, criar };
