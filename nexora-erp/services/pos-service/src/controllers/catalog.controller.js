'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { activo } = req.query;
    const params = [req.user.tenantId];
    let sql = `SELECT * FROM pos_catalog_items WHERE tenant_id = $1`;
    if (activo !== undefined) {
      params.push(activo === 'true');
      sql += ` AND activo = $2`;
    }
    sql += ` ORDER BY created_at DESC`;

    const { rows } = await db.query(sql, params);
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function upsert(req, res, next) {
  try {
    const { product_id, product_variant_id, codigo_barra, preco_venda, moeda, activo } = req.body;
    if (!product_id || preco_venda === undefined) {
      return res.status(400).json({ error: 'product_id e preco_venda sao obrigatorios' });
    }

    const { rows } = await db.query(
      `INSERT INTO pos_catalog_items (tenant_id, product_id, product_variant_id, codigo_barra, preco_venda, moeda, activo)
       VALUES ($1,$2,$3,$4,$5,$6,$7)
       ON CONFLICT (tenant_id, product_id, product_variant_id)
       DO UPDATE SET
         codigo_barra = EXCLUDED.codigo_barra,
         preco_venda = EXCLUDED.preco_venda,
         moeda = EXCLUDED.moeda,
         activo = EXCLUDED.activo,
         updated_at = NOW()
       RETURNING *`,
      [req.user.tenantId, product_id, product_variant_id || null, codigo_barra || null, preco_venda, moeda || 'MZN', activo ?? true]
    );
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, upsert };
