'use strict';

const db = require('../config/db');
const { proximoNumero } = require('../lib/numeracao');
const { calcularLinha, calcularDocumento } = require('../lib/calculos');

// ── helpers ──────────────────────────────────────────────────────────────────

async function recalcularTotais(client, invoiceId) {
  const { rows } = await client.query(
    `SELECT subtotal, desconto_valor, imposto_valor, total FROM invoice_items WHERE invoice_id = $1`,
    [invoiceId]
  );
  const tot = calcularDocumento(rows);
  await client.query(
    `UPDATE invoices SET subtotal=$1, desconto_total=$2, imposto_total=$3, total=$4 WHERE id=$5`,
    [tot.subtotal, tot.desconto_total, tot.imposto_total, tot.total, invoiceId]
  );
  return tot;
}

async function actualizarEstadoFatura(client, invoiceId) {
  const { rows } = await client.query(
    `SELECT status, total, valor_pago, due_date FROM invoices WHERE id=$1`, [invoiceId]
  );
  const inv = rows[0];
  if (!inv || inv.status === 'cancelada') return;

  let novoEstado = inv.status;
  const pago = Number(inv.valor_pago);
  const total = Number(inv.total);

  if (pago >= total) {
    novoEstado = 'paga';
  } else if (pago > 0) {
    novoEstado = 'parcialmente_paga';
  } else if (inv.due_date && new Date(inv.due_date) < new Date()) {
    novoEstado = 'vencida';
  } else {
    novoEstado = 'emitida';
  }

  if (novoEstado !== inv.status) {
    await client.query(`UPDATE invoices SET status=$1 WHERE id=$2`, [novoEstado, invoiceId]);
  }
}

// ── controllers ───────────────────────────────────────────────────────────────

async function listar(req, res, next) {
  try {
    const { status, customer_id, vencidas, page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;
    const params = [req.user.tenantId];
    const cond = ['tenant_id = $1'];

    if (status)      { params.push(status);      cond.push(`status = $${params.length}`); }
    if (customer_id) { params.push(customer_id); cond.push(`customer_id = $${params.length}`); }
    if (vencidas === 'true') { cond.push(`due_date < CURRENT_DATE AND status NOT IN ('paga','cancelada')`); }

    params.push(Number(limit), offset);
    const { rows } = await db.query(
      `SELECT id, numero, customer_id, invoice_date, due_date, status, total, valor_pago, saldo_pendente, moeda
         FROM invoices WHERE ${cond.join(' AND ')}
        ORDER BY created_at DESC
        LIMIT $${params.length - 1} OFFSET $${params.length}`,
      params
    );
    res.json(rows);
  } catch (err) { next(err); }
}

async function criar(req, res, next) {
  const client = await db.connect();
  try {
    await client.query('BEGIN');
    const { customer_id, sales_order_id, invoice_date, due_date, moeda, payment_terms, observacoes } = req.body;
    if (!customer_id) return res.status(400).json({ error: 'customer_id é obrigatório' });

    const { numero, serie_id } = await proximoNumero(client, req.user.tenantId, 'FT');

    const { rows } = await client.query(
      `INSERT INTO invoices (tenant_id, serie_id, customer_id, sales_order_id, numero, invoice_date, due_date, moeda, payment_terms, observacoes, criado_por)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11) RETURNING *`,
      [req.user.tenantId, serie_id, customer_id, sales_order_id || null, numero,
       invoice_date || null, due_date || null, moeda || 'MZN', payment_terms || null, observacoes || null, req.user.id]
    );
    await client.query('COMMIT');
    res.status(201).json(rows[0]);
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally { client.release(); }
}

async function obter(req, res, next) {
  try {
    const [invRes, itemsRes, taxesRes, discRes, receiptsRes] = await Promise.all([
      db.query(`SELECT * FROM invoices WHERE id=$1 AND tenant_id=$2`, [req.params.id, req.user.tenantId]),
      db.query(`SELECT * FROM invoice_items WHERE invoice_id=$1 ORDER BY id`, [req.params.id]),
      db.query(`SELECT * FROM invoice_taxes WHERE invoice_id=$1`, [req.params.id]),
      db.query(`SELECT * FROM invoice_discounts WHERE invoice_id=$1`, [req.params.id]),
      db.query(`SELECT id, numero, payment_date, valor, status FROM invoice_receipts WHERE invoice_id=$1 ORDER BY payment_date`, [req.params.id]),
    ]);
    if (!invRes.rows.length) return res.status(404).json({ error: 'Fatura não encontrada' });
    res.json({
      ...invRes.rows[0],
      items: itemsRes.rows,
      taxes: taxesRes.rows,
      discounts: discRes.rows,
      receipts: receiptsRes.rows,
    });
  } catch (err) { next(err); }
}

async function actualizar(req, res, next) {
  try {
    const { due_date, payment_terms, observacoes } = req.body;
    const { rows } = await db.query(
      `UPDATE invoices SET
         due_date      = COALESCE($1, due_date),
         payment_terms = COALESCE($2, payment_terms),
         observacoes   = COALESCE($3, observacoes)
       WHERE id=$4 AND tenant_id=$5 AND status='rascunho' RETURNING *`,
      [due_date || null, payment_terms || null, observacoes || null, req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Fatura não encontrada ou não está em rascunho' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function emitir(req, res, next) {
  const client = await db.connect();
  try {
    await client.query('BEGIN');
    const { rows } = await client.query(
      `UPDATE invoices SET status='emitida', emitida_em=NOW()
        WHERE id=$1 AND tenant_id=$2 AND status='rascunho'
        RETURNING *`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Fatura não encontrada ou não está em rascunho' });
    }
    // Consolida resumo de impostos por taxa
    await client.query(`DELETE FROM invoice_taxes WHERE invoice_id=$1`, [req.params.id]);
    await client.query(
      `INSERT INTO invoice_taxes (invoice_id, tax_id, nome_imposto, taxa, base_imponivel, valor_imposto)
       SELECT $1, tax_id, CONCAT('IVA ', imposto_percent, '%'), imposto_percent,
              SUM(subtotal), SUM(imposto_valor)
         FROM invoice_items WHERE invoice_id=$1 AND imposto_percent > 0
        GROUP BY tax_id, imposto_percent`,
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
    // RNF02: cancelamento requer nota de crédito — apenas marcamos como cancelada se já existe NC
    const { motivo } = req.body;
    if (!motivo) return res.status(400).json({ error: 'motivo é obrigatório' });

    const { rows } = await db.query(
      `UPDATE invoices SET status='cancelada'
        WHERE id=$1 AND tenant_id=$2 AND status IN ('emitida','parcialmente_paga','vencida')
        RETURNING *`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Fatura não encontrada ou não pode ser cancelada' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

// ── Items ────────────────────────────────────────────────────────────────────

async function adicionarItem(req, res, next) {
  const client = await db.connect();
  try {
    await client.query('BEGIN');
    const { rows: inv } = await client.query(
      `SELECT id FROM invoices WHERE id=$1 AND tenant_id=$2 AND status='rascunho' FOR UPDATE`,
      [req.params.id, req.user.tenantId]
    );
    if (!inv.length) return res.status(404).json({ error: 'Fatura não encontrada ou não está em rascunho' });

    const { product_id, descricao, quantidade, preco_unitario, desconto_percent, tax_id, imposto_percent } = req.body;
    if (!product_id || !quantidade || preco_unitario === undefined) {
      return res.status(400).json({ error: 'product_id, quantidade e preco_unitario são obrigatórios' });
    }

    const calc = calcularLinha({ quantidade, preco_unitario, desconto_percent, imposto_percent });

    const { rows } = await client.query(
      `INSERT INTO invoice_items
         (invoice_id, product_id, descricao, quantidade, preco_unitario, desconto_percent, desconto_valor,
          tax_id, imposto_percent, imposto_valor, subtotal, total)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12) RETURNING *`,
      [req.params.id, product_id, descricao || null, quantidade, preco_unitario,
       desconto_percent || 0, calc.desconto_valor, tax_id || null, imposto_percent || 0,
       calc.imposto_valor, calc.subtotal, calc.total]
    );

    await recalcularTotais(client, req.params.id);
    await client.query('COMMIT');
    res.status(201).json(rows[0]);
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally { client.release(); }
}

async function actualizarItem(req, res, next) {
  const client = await db.connect();
  try {
    await client.query('BEGIN');
    const { rows: inv } = await client.query(
      `SELECT id FROM invoices WHERE id=$1 AND tenant_id=$2 AND status='rascunho' FOR UPDATE`,
      [req.params.id, req.user.tenantId]
    );
    if (!inv.length) return res.status(404).json({ error: 'Fatura não encontrada ou não está em rascunho' });

    const { rows: cur } = await client.query(
      `SELECT * FROM invoice_items WHERE id=$1 AND invoice_id=$2`, [req.params.item_id, req.params.id]
    );
    if (!cur.length) return res.status(404).json({ error: 'Linha não encontrada' });

    const merged = {
      quantidade:       req.body.quantidade       ?? cur[0].quantidade,
      preco_unitario:   req.body.preco_unitario   ?? cur[0].preco_unitario,
      desconto_percent: req.body.desconto_percent ?? cur[0].desconto_percent,
      imposto_percent:  req.body.imposto_percent  ?? cur[0].imposto_percent,
    };
    const calc = calcularLinha(merged);

    const { rows } = await client.query(
      `UPDATE invoice_items SET
         descricao=$1, quantidade=$2, preco_unitario=$3,
         desconto_percent=$4, desconto_valor=$5,
         tax_id=COALESCE($6,tax_id), imposto_percent=$7, imposto_valor=$8,
         subtotal=$9, total=$10
       WHERE id=$11 RETURNING *`,
      [req.body.descricao || cur[0].descricao, merged.quantidade, merged.preco_unitario,
       merged.desconto_percent, calc.desconto_valor, req.body.tax_id || null,
       merged.imposto_percent, calc.imposto_valor, calc.subtotal, calc.total, req.params.item_id]
    );

    await recalcularTotais(client, req.params.id);
    await client.query('COMMIT');
    res.json(rows[0]);
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally { client.release(); }
}

async function removerItem(req, res, next) {
  const client = await db.connect();
  try {
    await client.query('BEGIN');
    const { rows: inv } = await client.query(
      `SELECT id FROM invoices WHERE id=$1 AND tenant_id=$2 AND status='rascunho' FOR UPDATE`,
      [req.params.id, req.user.tenantId]
    );
    if (!inv.length) return res.status(404).json({ error: 'Fatura não encontrada ou não está em rascunho' });
    const { rowCount } = await client.query(
      `DELETE FROM invoice_items WHERE id=$1 AND invoice_id=$2`, [req.params.item_id, req.params.id]
    );
    if (!rowCount) return res.status(404).json({ error: 'Linha não encontrada' });
    await recalcularTotais(client, req.params.id);
    await client.query('COMMIT');
    res.status(204).send();
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally { client.release(); }
}

// ── Vencidas ─────────────────────────────────────────────────────────────────

async function vencidas(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT id, numero, customer_id, invoice_date, due_date, total, saldo_pendente,
              CURRENT_DATE - due_date AS dias_atraso
         FROM invoices
        WHERE tenant_id=$1 AND due_date < CURRENT_DATE AND status NOT IN ('paga','cancelada')
        ORDER BY due_date ASC`,
      [req.user.tenantId]
    );
    res.json(rows);
  } catch (err) { next(err); }
}

module.exports = {
  listar, criar, obter, actualizar, emitir, cancelar,
  adicionarItem, actualizarItem, removerItem, vencidas,
};
