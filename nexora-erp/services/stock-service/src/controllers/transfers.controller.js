'use strict';

const db = require('../config/db');

async function gerarNumero(client, tenantId) {
  const ano = new Date().getFullYear();
  const { rows } = await client.query(
    `SELECT COUNT(*) AS total FROM stock_transfers
     WHERE tenant_id = $1 AND EXTRACT(YEAR FROM created_at) = $2`,
    [tenantId, ano]
  );
  const seq = String(Number(rows[0].total) + 1).padStart(4, '0');
  return `TRF${ano}/${seq}`;
}

async function listar(req, res, next) {
  try {
    const { status } = req.query;
    const params = [req.user.tenantId];
    const cond = ['tenant_id = $1'];
    if (status) { params.push(status); cond.push(`status = $${params.length}`); }
    const { rows } = await db.query(
      `SELECT * FROM stock_transfers WHERE ${cond.join(' AND ')} ORDER BY created_at DESC`,
      params
    );
    res.json(rows);
  } catch (err) { next(err); }
}

async function criar(req, res, next) {
  const client = await db.connect();
  try {
    await client.query('BEGIN');
    const { from_warehouse_id, to_warehouse_id, items } = req.body;
    if (!from_warehouse_id || !to_warehouse_id) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'from_warehouse_id e to_warehouse_id são obrigatórios' });
    }
    if (!Array.isArray(items) || !items.length) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'items é obrigatório e deve ter pelo menos um elemento' });
    }
    const numero = await gerarNumero(client, req.user.tenantId);
    const { rows } = await client.query(
      `INSERT INTO stock_transfers (tenant_id, numero, from_warehouse_id, to_warehouse_id)
       VALUES ($1,$2,$3,$4) RETURNING *`,
      [req.user.tenantId, numero, from_warehouse_id, to_warehouse_id]
    );
    const transfer = rows[0];
    for (const item of items) {
      if (!item.stock_item_id || !item.quantity) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'Cada item deve ter stock_item_id e quantity' });
      }
      await client.query(
        `INSERT INTO stock_transfer_items (stock_transfer_id, stock_item_id, quantity)
         VALUES ($1,$2,$3)`,
        [transfer.id, item.stock_item_id, item.quantity]
      );
    }
    await client.query('COMMIT');
    res.status(201).json(transfer);
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally { client.release(); }
}

async function obter(req, res, next) {
  try {
    const [tRes, iRes] = await Promise.all([
      db.query(`SELECT * FROM stock_transfers WHERE id = $1 AND tenant_id = $2`, [req.params.id, req.user.tenantId]),
      db.query(`SELECT sti.*, si.product_id, si.warehouse_id FROM stock_transfer_items sti
                JOIN stock_items si ON si.id = sti.stock_item_id
                WHERE sti.stock_transfer_id = $1`, [req.params.id]),
    ]);
    if (!tRes.rows.length) return res.status(404).json({ error: 'Transferência não encontrada' });
    res.json({ ...tRes.rows[0], items: iRes.rows });
  } catch (err) { next(err); }
}

async function iniciar(req, res, next) {
  try {
    const { rows } = await db.query(
      `UPDATE stock_transfers SET status = 'em_transito'
       WHERE id = $1 AND tenant_id = $2 AND status = 'pendente' RETURNING *`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Transferência não encontrada ou não está pendente' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function concluir(req, res, next) {
  const client = await db.connect();
  try {
    await client.query('BEGIN');
    const { rows: tRows } = await client.query(
      `SELECT * FROM stock_transfers WHERE id = $1 AND tenant_id = $2 AND status = 'em_transito' FOR UPDATE`,
      [req.params.id, req.user.tenantId]
    );
    if (!tRows.length) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Transferência não encontrada ou não está em trânsito' });
    }
    const transfer = tRows[0];
    const { rows: tItems } = await client.query(
      `SELECT sti.*, si.available_quantity FROM stock_transfer_items sti
       JOIN stock_items si ON si.id = sti.stock_item_id
       WHERE sti.stock_transfer_id = $1`,
      [req.params.id]
    );

    for (const item of tItems) {
      if (Number(item.available_quantity) < Number(item.quantity)) {
        await client.query('ROLLBACK');
        return res.status(422).json({ error: `Stock insuficiente para o item ${item.stock_item_id}` });
      }
      // Desconta origem
      await client.query(
        `UPDATE stock_items SET quantity = quantity - $1, updated_at = NOW() WHERE id = $2`,
        [item.quantity, item.stock_item_id]
      );
      await client.query(
        `INSERT INTO stock_movements (tenant_id, stock_item_id, tipo, quantity, reference_type, reference_id)
         VALUES ($1,$2,'transferencia_saida',$3,'stock_transfer',$4)`,
        [req.user.tenantId, item.stock_item_id, item.quantity, transfer.id]
      );

      // Encontra ou cria item de destino
      const { rows: destItem } = await client.query(
        `SELECT id FROM stock_items
         WHERE tenant_id = $1 AND product_id = (SELECT product_id FROM stock_items WHERE id = $2)
           AND COALESCE(product_variant_id, -1) = COALESCE((SELECT product_variant_id FROM stock_items WHERE id = $2), -1)
           AND warehouse_id = $3`,
        [req.user.tenantId, item.stock_item_id, transfer.to_warehouse_id]
      );

      let destId;
      if (destItem.length) {
        destId = destItem[0].id;
        await client.query(
          `UPDATE stock_items SET quantity = quantity + $1, updated_at = NOW() WHERE id = $2`,
          [item.quantity, destId]
        );
      } else {
        const { rows: newItem } = await client.query(
          `INSERT INTO stock_items (tenant_id, product_id, product_variant_id, warehouse_id, quantity)
           SELECT tenant_id, product_id, product_variant_id, $1, $2 FROM stock_items WHERE id = $3
           RETURNING id`,
          [transfer.to_warehouse_id, item.quantity, item.stock_item_id]
        );
        destId = newItem[0].id;
      }
      await client.query(
        `INSERT INTO stock_movements (tenant_id, stock_item_id, tipo, quantity, reference_type, reference_id)
         VALUES ($1,$2,'transferencia_entrada',$3,'stock_transfer',$4)`,
        [req.user.tenantId, destId, item.quantity, transfer.id]
      );
    }

    const { rows } = await client.query(
      `UPDATE stock_transfers SET status = 'concluida' WHERE id = $1 RETURNING *`,
      [req.params.id]
    );
    await client.query('COMMIT');
    res.json(rows[0]);
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally { client.release(); }
}

async function cancelar(req, res, next) {
  try {
    const { rows } = await db.query(
      `UPDATE stock_transfers SET status = 'cancelada'
       WHERE id = $1 AND tenant_id = $2 AND status IN ('pendente','em_transito') RETURNING *`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Transferência não encontrada ou não pode ser cancelada' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

module.exports = { listar, criar, obter, iniciar, concluir, cancelar };
