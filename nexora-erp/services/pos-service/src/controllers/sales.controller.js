'use strict';

const db = require('../config/db');
const { roundMoney } = require('../lib/calculos');

async function listar(req, res, next) {
  try {
    const { status, pos_session_id } = req.query;
    const params = [req.user.tenantId];
    const conditions = ['tenant_id = $1'];
    if (status) {
      params.push(status);
      conditions.push(`status = $${params.length}`);
    }
    if (pos_session_id) {
      params.push(pos_session_id);
      conditions.push(`pos_session_id = $${params.length}`);
    }

    const { rows } = await db.query(
      `SELECT * FROM pos_sales WHERE ${conditions.join(' AND ')} ORDER BY created_at DESC`,
      params
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function obter(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT * FROM pos_sales WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) {
      return res.status(404).json({ error: 'Venda POS nao encontrada' });
    }

    const { rows: items } = await db.query(`SELECT * FROM pos_sale_items WHERE pos_sale_id = $1 ORDER BY id ASC`, [req.params.id]);
    const { rows: payments } = await db.query(`SELECT * FROM pos_sale_payments WHERE pos_sale_id = $1 ORDER BY id ASC`, [req.params.id]);

    res.json({ ...rows[0], items, payments });
  } catch (err) {
    next(err);
  }
}

async function criar(req, res, next) {
  const client = await db.connect();
  try {
    await client.query('BEGIN');

    const { pos_session_id, terminal_id, numero, customer_id, moeda, items, payments } = req.body;
    if (!pos_session_id || !terminal_id || !numero || !Array.isArray(items) || !items.length) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'pos_session_id, terminal_id, numero e items sao obrigatorios' });
    }

    const { rows: sessions } = await client.query(
      `SELECT * FROM pos_sessions WHERE id = $1 AND tenant_id = $2 AND status = 'aberta'`,
      [pos_session_id, req.user.tenantId]
    );
    if (!sessions.length) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Sessao POS nao encontrada ou fechada' });
    }

    let subtotal = 0;
    let descontoTotal = 0;
    let impostoTotal = 0;
    let total = 0;

    const { rows: saleRows } = await client.query(
      `INSERT INTO pos_sales
       (tenant_id, pos_session_id, terminal_id, numero, customer_id, moeda, created_by)
       VALUES ($1,$2,$3,$4,$5,$6,$7)
       RETURNING *`,
      [req.user.tenantId, pos_session_id, terminal_id, numero, customer_id || null, moeda || 'MZN', req.user.id]
    );

    for (const item of items) {
      const quantidade = Number(item.quantidade);
      const preco = Number(item.preco_unitario);
      const desconto = Number(item.desconto_valor || 0);
      const imposto = Number(item.imposto_valor || 0);
      if (!item.product_id || Number.isNaN(quantidade) || quantidade <= 0 || Number.isNaN(preco) || preco < 0) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'Cada item requer product_id, quantidade e preco_unitario validos' });
      }

      const lineSubtotal = roundMoney(quantidade * preco);
      const lineTotal = roundMoney(lineSubtotal - desconto + imposto);
      subtotal = roundMoney(subtotal + lineSubtotal);
      descontoTotal = roundMoney(descontoTotal + desconto);
      impostoTotal = roundMoney(impostoTotal + imposto);
      total = roundMoney(total + lineTotal);

      await client.query(
        `INSERT INTO pos_sale_items
         (pos_sale_id, product_id, product_variant_id, descricao, quantidade, preco_unitario, desconto_valor, imposto_valor, subtotal, total)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)`,
        [saleRows[0].id, item.product_id, item.product_variant_id || null, item.descricao || null, quantidade, preco, desconto, imposto, lineSubtotal, lineTotal]
      );
    }

    let valorRecebido = 0;
    for (const payment of (payments || [])) {
      const valor = Number(payment.valor);
      if (!payment.tipo || Number.isNaN(valor) || valor <= 0) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'Cada pagamento requer tipo e valor validos' });
      }
      valorRecebido = roundMoney(valorRecebido + valor);
      await client.query(
        `INSERT INTO pos_sale_payments (pos_sale_id, payment_method_id, tipo, valor, referencia)
         VALUES ($1,$2,$3,$4,$5)`,
        [saleRows[0].id, payment.payment_method_id || null, payment.tipo, valor, payment.referencia || null]
      );
    }

    const troco = roundMoney(Math.max(0, valorRecebido - total));
    const { rows: updated } = await client.query(
      `UPDATE pos_sales
          SET subtotal = $1,
              desconto_total = $2,
              imposto_total = $3,
              total = $4,
              valor_recebido = $5,
              troco = $6
        WHERE id = $7
      RETURNING *`,
      [subtotal, descontoTotal, impostoTotal, total, valorRecebido, troco, saleRows[0].id]
    );

    await client.query('COMMIT');
    res.status(201).json(updated[0]);
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally {
    client.release();
  }
}

async function finalizar(req, res, next) {
  try {
    const { rows } = await db.query(
      `UPDATE pos_sales
          SET status = 'concluida',
              sold_at = NOW()
        WHERE id = $1 AND tenant_id = $2 AND status = 'rascunho'
      RETURNING *`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) {
      return res.status(404).json({ error: 'Venda POS nao encontrada ou ja concluida' });
    }
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, obter, criar, finalizar };
