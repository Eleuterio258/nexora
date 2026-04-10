'use strict';

const db = require('../config/db');

// ── Tax Regimes ───────────────────────────────────────────────────────────────

async function listarRegimes(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT * FROM tax_regimes WHERE tenant_id = $1 ORDER BY nome ASC`,
      [req.user.tenantId]
    );
    res.json(rows);
  } catch (err) { next(err); }
}

async function criarRegime(req, res, next) {
  try {
    const { codigo, nome, descricao } = req.body;
    if (!codigo || !nome) return res.status(400).json({ error: 'codigo e nome são obrigatórios' });

    const { rows } = await db.query(
      `INSERT INTO tax_regimes (tenant_id, codigo, nome, descricao)
       VALUES ($1, $2, $3, $4) RETURNING *`,
      [req.user.tenantId, codigo, nome, descricao || null]
    );
    res.status(201).json(rows[0]);
  } catch (err) { next(err); }
}

async function actualizarRegime(req, res, next) {
  try {
    const { codigo, nome, descricao, ativo } = req.body;
    const { rows } = await db.query(
      `UPDATE tax_regimes
          SET codigo   = COALESCE($1, codigo),
              nome     = COALESCE($2, nome),
              descricao = COALESCE($3, descricao),
              ativo    = COALESCE($4, ativo)
        WHERE id = $5 AND tenant_id = $6
        RETURNING *`,
      [codigo || null, nome || null, descricao || null, ativo ?? null, req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Regime não encontrado' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function eliminarRegime(req, res, next) {
  try {
    const { rowCount } = await db.query(
      `DELETE FROM tax_regimes WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!rowCount) return res.status(404).json({ error: 'Regime não encontrado' });
    res.status(204).send();
  } catch (err) { next(err); }
}

// ── Taxes ─────────────────────────────────────────────────────────────────────

async function listar(req, res, next) {
  try {
    const { tipo, ativo } = req.query;
    const params = [req.user.tenantId];
    const cond = ['tenant_id = $1'];

    if (tipo)  { params.push(tipo);          cond.push(`tipo = $${params.length}`); }
    if (ativo !== undefined) { params.push(ativo === 'true'); cond.push(`ativo = $${params.length}`); }

    const { rows } = await db.query(
      `SELECT * FROM taxes WHERE ${cond.join(' AND ')} ORDER BY nome ASC`,
      params
    );
    res.json(rows);
  } catch (err) { next(err); }
}

async function criar(req, res, next) {
  try {
    const { codigo, nome, taxa, tipo } = req.body;
    if (!codigo || !nome || taxa === undefined) {
      return res.status(400).json({ error: 'codigo, nome e taxa são obrigatórios' });
    }

    const { rows } = await db.query(
      `INSERT INTO taxes (tenant_id, codigo, nome, taxa, tipo)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [req.user.tenantId, codigo, nome, taxa, tipo || 'iva']
    );
    res.status(201).json(rows[0]);
  } catch (err) { next(err); }
}

async function obter(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT * FROM taxes WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Imposto não encontrado' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function actualizar(req, res, next) {
  try {
    const { codigo, nome, taxa, tipo, ativo } = req.body;
    const { rows } = await db.query(
      `UPDATE taxes
          SET codigo = COALESCE($1, codigo),
              nome   = COALESCE($2, nome),
              taxa   = COALESCE($3, taxa),
              tipo   = COALESCE($4, tipo),
              ativo  = COALESCE($5, ativo)
        WHERE id = $6 AND tenant_id = $7
        RETURNING *`,
      [codigo || null, nome || null, taxa ?? null, tipo || null, ativo ?? null,
       req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Imposto não encontrado' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function eliminar(req, res, next) {
  try {
    const { rowCount } = await db.query(
      `DELETE FROM taxes WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!rowCount) return res.status(404).json({ error: 'Imposto não encontrado' });
    res.status(204).send();
  } catch (err) { next(err); }
}

// ── Exemptions ────────────────────────────────────────────────────────────────

async function listarExemptions(req, res, next) {
  try {
    const { rows: tax } = await db.query(
      `SELECT id FROM taxes WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!tax.length) return res.status(404).json({ error: 'Imposto não encontrado' });

    const { rows } = await db.query(
      `SELECT * FROM tax_exemptions WHERE tax_id = $1 ORDER BY created_at DESC`,
      [req.params.id]
    );
    res.json(rows);
  } catch (err) { next(err); }
}

async function criarExemption(req, res, next) {
  try {
    const { rows: tax } = await db.query(
      `SELECT id FROM taxes WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!tax.length) return res.status(404).json({ error: 'Imposto não encontrado' });

    const { entity_type, entity_id, motivo, numero_isencao, validade } = req.body;
    if (!entity_type || !entity_id) {
      return res.status(400).json({ error: 'entity_type e entity_id são obrigatórios' });
    }

    const { rows } = await db.query(
      `INSERT INTO tax_exemptions (tenant_id, tax_id, entity_type, entity_id, motivo, numero_isencao, validade)
       VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
      [req.user.tenantId, req.params.id, entity_type, entity_id,
       motivo || null, numero_isencao || null, validade || null]
    );
    res.status(201).json(rows[0]);
  } catch (err) { next(err); }
}

async function eliminarExemption(req, res, next) {
  try {
    const { rowCount } = await db.query(
      `DELETE FROM tax_exemptions WHERE id = $1 AND tax_id = $2 AND tenant_id = $3`,
      [req.params.eid, req.params.id, req.user.tenantId]
    );
    if (!rowCount) return res.status(404).json({ error: 'Isenção não encontrada' });
    res.status(204).send();
  } catch (err) { next(err); }
}

module.exports = {
  listarRegimes, criarRegime, actualizarRegime, eliminarRegime,
  listar, criar, obter, actualizar, eliminar,
  listarExemptions, criarExemption, eliminarExemption,
};
