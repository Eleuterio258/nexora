'use strict';

const db = require('../config/db');

// ── Categorias ────────────────────────────────────────────────────────────────

async function listar(req, res, next) {
  try {
    const { ativo } = req.query;
    const params = [req.user.tenantId];
    const cond = ['tenant_id = $1'];
    if (ativo !== undefined) { params.push(ativo === 'true'); cond.push(`ativo = $${params.length}`); }
    const { rows } = await db.query(
      `SELECT * FROM product_categories WHERE ${cond.join(' AND ')} ORDER BY nome ASC`,
      params
    );
    res.json(rows);
  } catch (err) { next(err); }
}

async function criar(req, res, next) {
  try {
    const { codigo, nome, descricao } = req.body;
    if (!nome) return res.status(400).json({ error: 'nome é obrigatório' });
    const { rows } = await db.query(
      `INSERT INTO product_categories (tenant_id, codigo, nome, descricao)
       VALUES ($1, $2, $3, $4) RETURNING *`,
      [req.user.tenantId, codigo || null, nome, descricao || null]
    );
    res.status(201).json(rows[0]);
  } catch (err) { next(err); }
}

async function obter(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT * FROM product_categories WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Categoria não encontrada' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function actualizar(req, res, next) {
  try {
    const { codigo, nome, descricao, ativo } = req.body;
    const { rows } = await db.query(
      `UPDATE product_categories SET
         codigo    = COALESCE($1, codigo),
         nome      = COALESCE($2, nome),
         descricao = COALESCE($3, descricao),
         ativo     = COALESCE($4, ativo)
       WHERE id = $5 AND tenant_id = $6 RETURNING *`,
      [codigo ?? null, nome ?? null, descricao ?? null, ativo ?? null, req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Categoria não encontrada' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function remover(req, res, next) {
  try {
    const { rowCount } = await db.query(
      `DELETE FROM product_categories WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!rowCount) return res.status(404).json({ error: 'Categoria não encontrada' });
    res.status(204).send();
  } catch (err) { next(err); }
}

// ── Subcategorias ─────────────────────────────────────────────────────────────

async function listarSubcategorias(req, res, next) {
  try {
    const { rows: cat } = await db.query(
      `SELECT id FROM product_categories WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!cat.length) return res.status(404).json({ error: 'Categoria não encontrada' });
    const { rows } = await db.query(
      `SELECT * FROM product_subcategories WHERE product_category_id = $1 ORDER BY nome ASC`,
      [req.params.id]
    );
    res.json(rows);
  } catch (err) { next(err); }
}

async function criarSubcategoria(req, res, next) {
  try {
    const { rows: cat } = await db.query(
      `SELECT id FROM product_categories WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!cat.length) return res.status(404).json({ error: 'Categoria não encontrada' });
    const { codigo, nome, descricao } = req.body;
    if (!nome) return res.status(400).json({ error: 'nome é obrigatório' });
    const { rows } = await db.query(
      `INSERT INTO product_subcategories (tenant_id, product_category_id, codigo, nome, descricao)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [req.user.tenantId, req.params.id, codigo || null, nome, descricao || null]
    );
    res.status(201).json(rows[0]);
  } catch (err) { next(err); }
}

module.exports = { listar, criar, obter, actualizar, remover, listarSubcategorias, criarSubcategoria };
