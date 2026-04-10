'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { tipo, ano } = req.query;
    const params = [req.user.tenantId];
    const cond = ['tenant_id = $1'];
    if (tipo) { params.push(tipo); cond.push(`tipo = $${params.length}`); }
    if (ano)  { params.push(ano);  cond.push(`ano = $${params.length}`); }

    const { rows } = await db.query(
      `SELECT * FROM invoice_series WHERE ${cond.join(' AND ')} ORDER BY tipo, ano DESC`,
      params
    );
    res.json(rows);
  } catch (err) { next(err); }
}

async function criar(req, res, next) {
  try {
    const { tipo, prefixo, ano } = req.body;
    if (!tipo || !prefixo || !ano) {
      return res.status(400).json({ error: 'tipo, prefixo e ano são obrigatórios' });
    }
    const { rows } = await db.query(
      `INSERT INTO invoice_series (tenant_id, tipo, prefixo, ano)
       VALUES ($1, $2, $3, $4) RETURNING *`,
      [req.user.tenantId, tipo, prefixo, ano]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    if (err.code === '23505') return res.status(409).json({ error: 'Série já existe para este tipo/ano' });
    next(err);
  }
}

async function obter(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT * FROM invoice_series WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Série não encontrada' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function actualizar(req, res, next) {
  try {
    const { prefixo } = req.body;
    const { rows } = await db.query(
      `UPDATE invoice_series SET prefixo = COALESCE($1, prefixo)
        WHERE id = $2 AND tenant_id = $3 AND sequencia = 0
        RETURNING *`,
      [prefixo || null, req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Série não encontrada ou já tem documentos emitidos' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function activar(req, res, next) {
  try {
    const { rows } = await db.query(
      `UPDATE invoice_series SET ativo = TRUE WHERE id = $1 AND tenant_id = $2 RETURNING *`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Série não encontrada' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function desactivar(req, res, next) {
  try {
    const { rows } = await db.query(
      `UPDATE invoice_series SET ativo = FALSE WHERE id = $1 AND tenant_id = $2 RETURNING *`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Série não encontrada' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

module.exports = { listar, criar, obter, actualizar, activar, desactivar };
