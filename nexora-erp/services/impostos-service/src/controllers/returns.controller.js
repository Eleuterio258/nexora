'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { tipo, status } = req.query;
    const params = [req.user.tenantId];
    const cond = ['tenant_id = $1'];

    if (tipo)   { params.push(tipo);   cond.push(`tipo = $${params.length}`); }
    if (status) { params.push(status); cond.push(`status = $${params.length}`); }

    const { rows } = await db.query(
      `SELECT * FROM tax_returns WHERE ${cond.join(' AND ')} ORDER BY periodo DESC, created_at DESC`,
      params
    );
    res.json(rows);
  } catch (err) { next(err); }
}

async function criar(req, res, next) {
  try {
    const { periodo, tipo } = req.body;
    if (!periodo || !tipo) return res.status(400).json({ error: 'periodo e tipo são obrigatórios' });

    const { rows } = await db.query(
      `INSERT INTO tax_returns (tenant_id, periodo, tipo)
       VALUES ($1, $2, $3) RETURNING *`,
      [req.user.tenantId, periodo, tipo]
    );
    res.status(201).json(rows[0]);
  } catch (err) { next(err); }
}

async function obter(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT * FROM tax_returns WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Declaração não encontrada' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function actualizar(req, res, next) {
  try {
    const { total_base, total_imposto, total_credito, total_a_pagar } = req.body;
    const { rows } = await db.query(
      `UPDATE tax_returns
          SET total_base     = COALESCE($1, total_base),
              total_imposto  = COALESCE($2, total_imposto),
              total_credito  = COALESCE($3, total_credito),
              total_a_pagar  = COALESCE($4, total_a_pagar)
        WHERE id = $5 AND tenant_id = $6 AND status = 'rascunho'
        RETURNING *`,
      [total_base ?? null, total_imposto ?? null, total_credito ?? null, total_a_pagar ?? null,
       req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Declaração não encontrada ou não está em rascunho' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function submeter(req, res, next) {
  const client = await db.connect();
  try {
    await client.query('BEGIN');
    const { rows } = await client.query(
      `UPDATE tax_returns
          SET status = 'submetida', data_submissao = NOW()
        WHERE id = $1 AND tenant_id = $2 AND status = 'rascunho'
        RETURNING *`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Declaração não encontrada ou não está em rascunho' });
    }
    await client.query('COMMIT');
    res.json(rows[0]);
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally { client.release(); }
}

async function pagar(req, res, next) {
  const client = await db.connect();
  try {
    await client.query('BEGIN');
    const { rows } = await client.query(
      `UPDATE tax_returns
          SET status = 'paga'
        WHERE id = $1 AND tenant_id = $2 AND status = 'submetida'
        RETURNING *`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Declaração não encontrada ou não está submetida' });
    }
    await client.query('COMMIT');
    res.json(rows[0]);
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally { client.release(); }
}

module.exports = { listar, criar, obter, actualizar, submeter, pagar };
