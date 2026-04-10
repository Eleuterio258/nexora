'use strict';

const db = require('../config/db');
const { roundMoney } = require('../lib/calculos');

async function listar(req, res, next) {
  try {
    const { supplier_id } = req.query;
    const params = [req.user.tenantId];
    const conditions = ['pr.tenant_id = $1'];

    if (supplier_id) {
      params.push(supplier_id);
      conditions.push(`pr.supplier_id = $${params.length}`);
    }

    const { rows } = await db.query(
      `SELECT pr.id, pr.numero, pr.return_date, pr.status, pr.total, pr.goods_receipt_id, s.nome AS supplier_nome
         FROM purchase_returns pr
         JOIN suppliers s ON s.id = pr.supplier_id
        WHERE ${conditions.join(' AND ')}
        ORDER BY pr.created_at DESC`,
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

    const { goods_receipt_id, numero, return_date, motivo, observacoes, items } = req.body;
    if (!goods_receipt_id || !numero || !motivo || !Array.isArray(items) || !items.length) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'goods_receipt_id, numero, motivo e items sao obrigatorios' });
    }

    const { rows: receipts } = await client.query(
      `SELECT * FROM goods_receipts WHERE id = $1 AND tenant_id = $2 FOR UPDATE`,
      [goods_receipt_id, req.user.tenantId]
    );

    if (!receipts.length) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Rececao nao encontrada' });
    }

    const receipt = receipts[0];
    const { rows: receiptItems } = await client.query(
      `SELECT * FROM goods_receipt_items WHERE goods_receipt_id = $1 ORDER BY id ASC`,
      [goods_receipt_id]
    );
    const receiptItemsById = new Map(receiptItems.map((item) => [String(item.id), item]));

    let total = 0;
    const normalizedItems = [];
    for (const item of items) {
      const receiptItem = receiptItemsById.get(String(item.goods_receipt_item_id));
      const qty = Number(item.quantity);
      if (!receiptItem || Number.isNaN(qty) || qty <= 0) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'Cada linha de devolucao deve referenciar um item valido da rececao' });
      }

      const disponivel = Number(receiptItem.quantity_received) - Number(receiptItem.returned_quantity);
      if (qty > disponivel) {
        await client.query('ROLLBACK');
        return res.status(422).json({ error: `Quantidade devolvida excede o saldo do item de rececao ${receiptItem.id}` });
      }

      const lineTotal = roundMoney(qty * Number(receiptItem.unit_cost));
      total = roundMoney(total + lineTotal);
      normalizedItems.push({
        goods_receipt_item_id: receiptItem.id,
        product_id: receiptItem.product_id,
        quantity: qty,
        unit_cost: Number(receiptItem.unit_cost),
        total: lineTotal
      });
    }

    const { rows: returns } = await client.query(
      `INSERT INTO purchase_returns
       (tenant_id, supplier_id, goods_receipt_id, numero, return_date, motivo, total, observacoes, criado_por)
       VALUES ($1,$2,$3,$4,COALESCE($5, CURRENT_DATE),$6,$7,$8,$9)
       RETURNING *`,
      [req.user.tenantId, receipt.supplier_id, receipt.id, numero, return_date || null, motivo, total, observacoes || null, req.user.id]
    );

    for (const item of normalizedItems) {
      await client.query(
        `INSERT INTO purchase_return_items
         (purchase_return_id, goods_receipt_item_id, product_id, quantity, unit_cost, total)
         VALUES ($1,$2,$3,$4,$5,$6)`,
        [returns[0].id, item.goods_receipt_item_id, item.product_id, item.quantity, item.unit_cost, item.total]
      );

      await client.query(
        `UPDATE goods_receipt_items
            SET returned_quantity = returned_quantity + $1
          WHERE id = $2`,
        [item.quantity, item.goods_receipt_item_id]
      );
    }

    await client.query('COMMIT');
    res.status(201).json(returns[0]);
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally {
    client.release();
  }
}

module.exports = { listar, criar };
