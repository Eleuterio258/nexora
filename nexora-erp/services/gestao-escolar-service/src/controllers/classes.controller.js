'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { ano_lectivo, activo } = req.query;
    const params = [req.user.tenantId];
    const conditions = ['tenant_id = $1'];
    if (ano_lectivo) {
      params.push(ano_lectivo);
      conditions.push(`ano_lectivo = $${params.length}`);
    }
    if (activo !== undefined) {
      params.push(activo === 'true');
      conditions.push(`activo = $${params.length}`);
    }

    const { rows } = await db.query(
      `SELECT * FROM school_classes WHERE ${conditions.join(' AND ')} ORDER BY nome ASC`,
      params
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function criar(req, res, next) {
  try {
    const { codigo, nome, nivel, ano_lectivo, turma, capacidade } = req.body;
    if (!codigo || !nome || !ano_lectivo) {
      return res.status(400).json({ error: 'codigo, nome e ano_lectivo sao obrigatorios' });
    }

    const { rows } = await db.query(
      `INSERT INTO school_classes (tenant_id, codigo, nome, nivel, ano_lectivo, turma, capacidade)
       VALUES ($1,$2,$3,$4,$5,$6,$7)
       RETURNING *`,
      [req.user.tenantId, codigo, nome, nivel || null, ano_lectivo, turma || null, capacidade || null]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function atualizar(req, res, next) {
  try {
    const { nome, nivel, turma, capacidade, activo } = req.body;
    const { rows } = await db.query(
      `UPDATE school_classes
          SET nome = COALESCE($1, nome),
              nivel = COALESCE($2, nivel),
              turma = COALESCE($3, turma),
              capacidade = COALESCE($4, capacidade),
              activo = COALESCE($5, activo),
              updated_at = NOW()
        WHERE id = $6 AND tenant_id = $7
      RETURNING *`,
      [nome ?? null, nivel ?? null, turma ?? null, capacidade ?? null, activo ?? null, req.params.id, req.user.tenantId]
    );
    if (!rows.length) {
      return res.status(404).json({ error: 'Turma nao encontrada' });
    }
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, criar, atualizar };
