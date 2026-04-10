'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { tipo, ativo } = req.query;
    const params = [req.user.tenantId];
    const conditions = ['tenant_id = $1'];

    if (tipo) {
      params.push(tipo);
      conditions.push(`tipo = $${params.length}`);
    }
    if (ativo !== undefined) {
      params.push(ativo === 'true');
      conditions.push(`ativo = $${params.length}`);
    }

    const { rows } = await db.query(
      `SELECT * FROM chart_of_accounts
        WHERE ${conditions.join(' AND ')}
        ORDER BY codigo ASC`,
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
      `SELECT * FROM chart_of_accounts WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) {
      return res.status(404).json({ error: 'Conta nao encontrada' });
    }
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function criar(req, res, next) {
  try {
    const { parent_id, codigo, nome, tipo, natureza, aceita_movimento } = req.body;
    if (!codigo || !nome || !tipo || !natureza) {
      return res.status(400).json({ error: 'codigo, nome, tipo e natureza sao obrigatorios' });
    }

    const { rows } = await db.query(
      `INSERT INTO chart_of_accounts
       (tenant_id, parent_id, codigo, nome, tipo, natureza, aceita_movimento)
       VALUES ($1,$2,$3,$4,$5,$6,$7)
       RETURNING *`,
      [req.user.tenantId, parent_id || null, codigo, nome, tipo, natureza, aceita_movimento ?? true]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function atualizar(req, res, next) {
  try {
    const { parent_id, nome, tipo, natureza, aceita_movimento, ativo } = req.body;
    const { rows } = await db.query(
      `UPDATE chart_of_accounts
          SET parent_id = COALESCE($1, parent_id),
              nome = COALESCE($2, nome),
              tipo = COALESCE($3, tipo),
              natureza = COALESCE($4, natureza),
              aceita_movimento = COALESCE($5, aceita_movimento),
              ativo = COALESCE($6, ativo),
              updated_at = NOW()
        WHERE id = $7 AND tenant_id = $8
      RETURNING *`,
      [parent_id ?? null, nome ?? null, tipo ?? null, natureza ?? null, aceita_movimento ?? null, ativo ?? null, req.params.id, req.user.tenantId]
    );

    if (!rows.length) {
      return res.status(404).json({ error: 'Conta nao encontrada' });
    }

    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, obter, criar, atualizar };
