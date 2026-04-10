'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT * FROM withholding_taxes WHERE tenant_id = $1 ORDER BY nome ASC`,
      [req.user.tenantId]
    );
    res.json(rows);
  } catch (err) { next(err); }
}

async function criar(req, res, next) {
  try {
    const { codigo, nome, taxa, aplica_em, tipo_entidade } = req.body;
    if (!codigo || !nome || taxa === undefined || !aplica_em) {
      return res.status(400).json({ error: 'codigo, nome, taxa e aplica_em são obrigatórios' });
    }

    const { rows } = await db.query(
      `INSERT INTO withholding_taxes (tenant_id, codigo, nome, taxa, aplica_em, tipo_entidade)
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
      [req.user.tenantId, codigo, nome, taxa, aplica_em, tipo_entidade || null]
    );
    res.status(201).json(rows[0]);
  } catch (err) { next(err); }
}

async function obter(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT * FROM withholding_taxes WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Retenção não encontrada' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function actualizar(req, res, next) {
  try {
    const { codigo, nome, taxa, aplica_em, tipo_entidade, ativo } = req.body;
    const { rows } = await db.query(
      `UPDATE withholding_taxes
          SET codigo        = COALESCE($1, codigo),
              nome          = COALESCE($2, nome),
              taxa          = COALESCE($3, taxa),
              aplica_em     = COALESCE($4, aplica_em),
              tipo_entidade = COALESCE($5, tipo_entidade),
              ativo         = COALESCE($6, ativo)
        WHERE id = $7 AND tenant_id = $8
        RETURNING *`,
      [codigo || null, nome || null, taxa ?? null, aplica_em || null,
       tipo_entidade || null, ativo ?? null, req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Retenção não encontrada' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function registarTransaccao(req, res, next) {
  const client = await db.connect();
  try {
    await client.query('BEGIN');

    const { rows: wt } = await client.query(
      `SELECT * FROM withholding_taxes WHERE id = $1 AND tenant_id = $2 AND ativo = TRUE`,
      [req.params.id, req.user.tenantId]
    );
    if (!wt.length) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Retenção não encontrada ou inactiva' });
    }

    const { base_imponivel, referencia_tipo, referencia_id } = req.body;
    if (base_imponivel === undefined) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'base_imponivel é obrigatório' });
    }

    const taxa_aplicada = Number(wt[0].taxa);
    const valor_retido = Number((Number(base_imponivel) * taxa_aplicada / 100).toFixed(2));

    const { rows } = await client.query(
      `INSERT INTO withholding_tax_transactions
         (tenant_id, withholding_tax_id, referencia_tipo, referencia_id, base_imponivel, taxa_aplicada, valor_retido)
       VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
      [req.user.tenantId, req.params.id, referencia_tipo || null, referencia_id || null,
       base_imponivel, taxa_aplicada, valor_retido]
    );

    await client.query('COMMIT');
    res.status(201).json(rows[0]);
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally { client.release(); }
}

module.exports = { listar, criar, obter, actualizar, registarTransaccao };
