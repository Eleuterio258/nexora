'use strict';

const crypto = require('crypto');
const db = require('../config/db');

function generateKey() {
  const raw = crypto.randomBytes(32).toString('hex');
  const prefix = 'nxk_' + raw.slice(0, 8);
  const full = `${prefix}_${raw.slice(8)}`;
  const hash = crypto.createHash('sha256').update(full).digest('hex');
  return { full, prefix, hash };
}

async function listar(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT id, nome, key_prefix, ativa, ultimo_uso_em, expira_em, created_at
         FROM api_keys WHERE tenant_id = $1 ORDER BY created_at DESC`,
      [req.user.tenantId]
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function criar(req, res, next) {
  try {
    const { nome, expira_em } = req.body;
    if (!nome) return res.status(400).json({ error: 'nome é obrigatório' });

    const { full, prefix, hash } = generateKey();

    const { rows } = await db.query(
      `INSERT INTO api_keys (tenant_id, user_id, nome, key_prefix, key_hash, expira_em)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING id, nome, key_prefix, ativa, expira_em, created_at`,
      [req.user.tenantId, req.user.id, nome, prefix, hash, expira_em || null]
    );

    res.status(201).json({ ...rows[0], key: full, aviso: 'Guarde esta chave — não será mostrada novamente.' });
  } catch (err) {
    next(err);
  }
}

async function obter(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT id, nome, key_prefix, ativa, ultimo_uso_em, expira_em, created_at
         FROM api_keys WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Chave não encontrada' });
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function actualizar(req, res, next) {
  try {
    const { nome, expira_em } = req.body;
    const { rows } = await db.query(
      `UPDATE api_keys SET
         nome = COALESCE($1, nome),
         expira_em = COALESCE($2, expira_em)
       WHERE id = $3 AND tenant_id = $4
       RETURNING id, nome, key_prefix, ativa, expira_em`,
      [nome || null, expira_em || null, req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Chave não encontrada' });
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function revogar(req, res, next) {
  try {
    const { rowCount } = await db.query(
      `UPDATE api_keys SET ativa = FALSE WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!rowCount) return res.status(404).json({ error: 'Chave não encontrada' });
    res.status(204).send();
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, criar, obter, actualizar, revogar };
