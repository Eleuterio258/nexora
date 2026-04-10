'use strict';

const db = require('../config/db');

// ── Produtos ──────────────────────────────────────────────────────────────────

async function listar(req, res, next) {
  try {
    const { ativo, category_id, brand_id, search, page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;
    const params = [req.user.tenantId];
    const cond = ['tenant_id = $1'];

    if (ativo !== undefined)  { params.push(ativo === 'true');    cond.push(`ativo = $${params.length}`); }
    if (category_id)          { params.push(category_id);         cond.push(`product_category_id = $${params.length}`); }
    if (brand_id)             { params.push(brand_id);            cond.push(`product_brand_id = $${params.length}`); }
    if (search)               { params.push(`%${search}%`);       cond.push(`(nome ILIKE $${params.length} OR codigo ILIKE $${params.length})`); }

    params.push(Number(limit), offset);
    const { rows } = await db.query(
      `SELECT id, codigo, nome, tipo, iva_percentual, stock_minimo, ativo,
              product_category_id, product_brand_id, product_unit_id, created_at
         FROM products WHERE ${cond.join(' AND ')}
        ORDER BY nome ASC
        LIMIT $${params.length - 1} OFFSET $${params.length}`,
      params
    );
    res.json(rows);
  } catch (err) { next(err); }
}

async function criar(req, res, next) {
  try {
    const {
      codigo, nome, descricao, tipo, iva_percentual, stock_minimo,
      category_id, subcategory_id, brand_id, unit_id, warehouse_default_id,
    } = req.body;
    if (!codigo || !nome) return res.status(400).json({ error: 'codigo e nome são obrigatórios' });
    const { rows } = await db.query(
      `INSERT INTO products
         (tenant_id, product_category_id, product_subcategory_id, product_brand_id, product_unit_id,
          warehouse_default_id, codigo, nome, descricao, tipo, iva_percentual, stock_minimo)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12) RETURNING *`,
      [
        req.user.tenantId,
        category_id || null, subcategory_id || null, brand_id || null, unit_id || null,
        warehouse_default_id || null,
        codigo, nome, descricao || null,
        tipo || 'simples',
        iva_percentual ?? 17.00,
        stock_minimo ?? 0,
      ]
    );
    res.status(201).json(rows[0]);
  } catch (err) { next(err); }
}

async function obter(req, res, next) {
  try {
    const [prodRes, varRes, priceRes] = await Promise.all([
      db.query(`SELECT * FROM products WHERE id = $1 AND tenant_id = $2`, [req.params.id, req.user.tenantId]),
      db.query(`SELECT * FROM product_variants WHERE product_id = $1 AND ativo = TRUE ORDER BY nome ASC`, [req.params.id]),
      db.query(`SELECT * FROM product_prices WHERE product_id = $1 AND ativo = TRUE ORDER BY tipo_preco, moeda`, [req.params.id]),
    ]);
    if (!prodRes.rows.length) return res.status(404).json({ error: 'Produto não encontrado' });
    res.json({ ...prodRes.rows[0], variants: varRes.rows, prices: priceRes.rows });
  } catch (err) { next(err); }
}

async function actualizar(req, res, next) {
  try {
    const {
      codigo, nome, descricao, tipo, iva_percentual, stock_minimo,
      category_id, subcategory_id, brand_id, unit_id, warehouse_default_id,
    } = req.body;
    const { rows } = await db.query(
      `UPDATE products SET
         codigo                = COALESCE($1, codigo),
         nome                  = COALESCE($2, nome),
         descricao             = COALESCE($3, descricao),
         tipo                  = COALESCE($4, tipo),
         iva_percentual        = COALESCE($5, iva_percentual),
         stock_minimo          = COALESCE($6, stock_minimo),
         product_category_id   = COALESCE($7, product_category_id),
         product_subcategory_id= COALESCE($8, product_subcategory_id),
         product_brand_id      = COALESCE($9, product_brand_id),
         product_unit_id       = COALESCE($10, product_unit_id),
         warehouse_default_id  = COALESCE($11, warehouse_default_id),
         updated_at            = NOW()
       WHERE id = $12 AND tenant_id = $13 RETURNING *`,
      [
        codigo ?? null, nome ?? null, descricao ?? null, tipo ?? null,
        iva_percentual ?? null, stock_minimo ?? null,
        category_id ?? null, subcategory_id ?? null, brand_id ?? null,
        unit_id ?? null, warehouse_default_id ?? null,
        req.params.id, req.user.tenantId,
      ]
    );
    if (!rows.length) return res.status(404).json({ error: 'Produto não encontrado' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function activar(req, res, next) {
  try {
    const { rows } = await db.query(
      `UPDATE products SET ativo = TRUE, updated_at = NOW()
       WHERE id = $1 AND tenant_id = $2 RETURNING *`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Produto não encontrado' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function desactivar(req, res, next) {
  try {
    const { rows } = await db.query(
      `UPDATE products SET ativo = FALSE, updated_at = NOW()
       WHERE id = $1 AND tenant_id = $2 RETURNING *`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Produto não encontrado' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

// ── Variantes ─────────────────────────────────────────────────────────────────

async function listarVariantes(req, res, next) {
  try {
    const { rows: prod } = await db.query(
      `SELECT id FROM products WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!prod.length) return res.status(404).json({ error: 'Produto não encontrado' });
    const { rows } = await db.query(
      `SELECT * FROM product_variants WHERE product_id = $1 ORDER BY nome ASC`,
      [req.params.id]
    );
    res.json(rows);
  } catch (err) { next(err); }
}

async function criarVariante(req, res, next) {
  try {
    const { rows: prod } = await db.query(
      `SELECT id FROM products WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!prod.length) return res.status(404).json({ error: 'Produto não encontrado' });
    const { codigo, nome, sku } = req.body;
    if (!nome) return res.status(400).json({ error: 'nome é obrigatório' });
    const { rows } = await db.query(
      `INSERT INTO product_variants (product_id, codigo, nome, sku)
       VALUES ($1, $2, $3, $4) RETURNING *`,
      [req.params.id, codigo || null, nome, sku || null]
    );
    res.status(201).json(rows[0]);
  } catch (err) { next(err); }
}

async function actualizarVariante(req, res, next) {
  try {
    const { rows: prod } = await db.query(
      `SELECT id FROM products WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!prod.length) return res.status(404).json({ error: 'Produto não encontrado' });
    const { codigo, nome, sku, ativo } = req.body;
    const { rows } = await db.query(
      `UPDATE product_variants SET
         codigo = COALESCE($1, codigo),
         nome   = COALESCE($2, nome),
         sku    = COALESCE($3, sku),
         ativo  = COALESCE($4, ativo)
       WHERE id = $5 AND product_id = $6 RETURNING *`,
      [codigo ?? null, nome ?? null, sku ?? null, ativo ?? null, req.params.vid, req.params.id]
    );
    if (!rows.length) return res.status(404).json({ error: 'Variante não encontrada' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function removerVariante(req, res, next) {
  try {
    const { rows: prod } = await db.query(
      `SELECT id FROM products WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!prod.length) return res.status(404).json({ error: 'Produto não encontrado' });
    const { rowCount } = await db.query(
      `DELETE FROM product_variants WHERE id = $1 AND product_id = $2`,
      [req.params.vid, req.params.id]
    );
    if (!rowCount) return res.status(404).json({ error: 'Variante não encontrada' });
    res.status(204).send();
  } catch (err) { next(err); }
}

// ── Preços ────────────────────────────────────────────────────────────────────

async function listarPrecos(req, res, next) {
  try {
    const { rows: prod } = await db.query(
      `SELECT id FROM products WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!prod.length) return res.status(404).json({ error: 'Produto não encontrado' });
    const { rows } = await db.query(
      `SELECT * FROM product_prices WHERE product_id = $1 ORDER BY tipo_preco, moeda`,
      [req.params.id]
    );
    res.json(rows);
  } catch (err) { next(err); }
}

async function criarPreco(req, res, next) {
  try {
    const { rows: prod } = await db.query(
      `SELECT id FROM products WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!prod.length) return res.status(404).json({ error: 'Produto não encontrado' });
    const { product_variant_id, tipo_preco, moeda, valor, inicia_em, fim_em } = req.body;
    if (valor === undefined) return res.status(400).json({ error: 'valor é obrigatório' });
    const { rows } = await db.query(
      `INSERT INTO product_prices (product_id, product_variant_id, tipo_preco, moeda, valor, inicia_em, fim_em)
       VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *`,
      [
        req.params.id, product_variant_id || null,
        tipo_preco || 'venda', moeda || 'MZN',
        valor, inicia_em || null, fim_em || null,
      ]
    );
    res.status(201).json(rows[0]);
  } catch (err) { next(err); }
}

async function actualizarPreco(req, res, next) {
  try {
    const { rows: prod } = await db.query(
      `SELECT id FROM products WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!prod.length) return res.status(404).json({ error: 'Produto não encontrado' });
    const { tipo_preco, moeda, valor, inicia_em, fim_em, ativo } = req.body;
    const { rows } = await db.query(
      `UPDATE product_prices SET
         tipo_preco = COALESCE($1, tipo_preco),
         moeda      = COALESCE($2, moeda),
         valor      = COALESCE($3, valor),
         inicia_em  = COALESCE($4, inicia_em),
         fim_em     = COALESCE($5, fim_em),
         ativo      = COALESCE($6, ativo)
       WHERE id = $7 AND product_id = $8 RETURNING *`,
      [tipo_preco ?? null, moeda ?? null, valor ?? null, inicia_em ?? null, fim_em ?? null, ativo ?? null,
       req.params.pid, req.params.id]
    );
    if (!rows.length) return res.status(404).json({ error: 'Preço não encontrado' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function removerPreco(req, res, next) {
  try {
    const { rows: prod } = await db.query(
      `SELECT id FROM products WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!prod.length) return res.status(404).json({ error: 'Produto não encontrado' });
    const { rowCount } = await db.query(
      `DELETE FROM product_prices WHERE id = $1 AND product_id = $2`,
      [req.params.pid, req.params.id]
    );
    if (!rowCount) return res.status(404).json({ error: 'Preço não encontrado' });
    res.status(204).send();
  } catch (err) { next(err); }
}

// ── Barcodes ──────────────────────────────────────────────────────────────────

async function listarBarcodes(req, res, next) {
  try {
    const { rows: prod } = await db.query(
      `SELECT id FROM products WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!prod.length) return res.status(404).json({ error: 'Produto não encontrado' });
    const { rows } = await db.query(
      `SELECT * FROM product_barcodes WHERE product_id = $1 ORDER BY principal DESC, id ASC`,
      [req.params.id]
    );
    res.json(rows);
  } catch (err) { next(err); }
}

async function criarBarcode(req, res, next) {
  const client = await db.connect();
  try {
    await client.query('BEGIN');
    const { rows: prod } = await client.query(
      `SELECT id FROM products WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!prod.length) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Produto não encontrado' });
    }
    const { product_variant_id, barcode, tipo, principal } = req.body;
    if (!barcode) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'barcode é obrigatório' });
    }
    if (principal) {
      await client.query(
        `UPDATE product_barcodes SET principal = FALSE WHERE product_id = $1`,
        [req.params.id]
      );
    }
    const { rows } = await client.query(
      `INSERT INTO product_barcodes (product_id, product_variant_id, barcode, tipo, principal)
       VALUES ($1,$2,$3,$4,$5) RETURNING *`,
      [req.params.id, product_variant_id || null, barcode, tipo || null, principal || false]
    );
    await client.query('COMMIT');
    res.status(201).json(rows[0]);
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally { client.release(); }
}

async function removerBarcode(req, res, next) {
  try {
    const { rows: prod } = await db.query(
      `SELECT id FROM products WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!prod.length) return res.status(404).json({ error: 'Produto não encontrado' });
    const { rowCount } = await db.query(
      `DELETE FROM product_barcodes WHERE id = $1 AND product_id = $2`,
      [req.params.bid, req.params.id]
    );
    if (!rowCount) return res.status(404).json({ error: 'Barcode não encontrado' });
    res.status(204).send();
  } catch (err) { next(err); }
}

module.exports = {
  listar, criar, obter, actualizar, activar, desactivar,
  listarVariantes, criarVariante, actualizarVariante, removerVariante,
  listarPrecos, criarPreco, actualizarPreco, removerPreco,
  listarBarcodes, criarBarcode, removerBarcode,
};
