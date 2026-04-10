'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { activo, tipo } = req.query;
    const params = [req.user.tenantId];
    const conditions = ['tenant_id = $1'];
    if (activo !== undefined) {
      params.push(activo === 'true');
      conditions.push(`activo = $${params.length}`);
    }
    if (tipo) {
      params.push(tipo);
      conditions.push(`tipo = $${params.length}`);
    }

    const { rows } = await db.query(
      `SELECT * FROM cost_centers WHERE ${conditions.join(' AND ')} ORDER BY codigo ASC`,
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
      `SELECT * FROM cost_centers WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) {
      return res.status(404).json({ error: 'Centro de custo nao encontrado' });
    }
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function criar(req, res, next) {
  try {
    const { parent_id, codigo, nome, tipo, gestor_user_id } = req.body;
    if (!codigo || !nome) {
      return res.status(400).json({ error: 'codigo e nome sao obrigatorios' });
    }

    const { rows } = await db.query(
      `INSERT INTO cost_centers (tenant_id, parent_id, codigo, nome, tipo, gestor_user_id)
       VALUES ($1,$2,$3,$4,$5,$6)
       RETURNING *`,
      [req.user.tenantId, parent_id || null, codigo, nome, tipo || 'centro', gestor_user_id || null]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function atualizar(req, res, next) {
  try {
    const { parent_id, nome, tipo, gestor_user_id, activo } = req.body;
    const { rows } = await db.query(
      `UPDATE cost_centers
          SET parent_id = COALESCE($1, parent_id),
              nome = COALESCE($2, nome),
              tipo = COALESCE($3, tipo),
              gestor_user_id = COALESCE($4, gestor_user_id),
              activo = COALESCE($5, activo),
              updated_at = NOW()
        WHERE id = $6 AND tenant_id = $7
      RETURNING *`,
      [parent_id ?? null, nome ?? null, tipo ?? null, gestor_user_id ?? null, activo ?? null, req.params.id, req.user.tenantId]
    );
    if (!rows.length) {
      return res.status(404).json({ error: 'Centro de custo nao encontrado' });
    }
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, obter, criar, atualizar };
