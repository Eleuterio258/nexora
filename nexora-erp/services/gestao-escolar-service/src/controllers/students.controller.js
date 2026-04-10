'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { estado } = req.query;
    const params = [req.user.tenantId];
    let sql = `SELECT * FROM school_students WHERE tenant_id = $1`;
    if (estado) {
      params.push(estado);
      sql += ` AND estado = $2`;
    }
    sql += ` ORDER BY nome ASC`;

    const { rows } = await db.query(sql, params);
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function obter(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT * FROM school_students WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) {
      return res.status(404).json({ error: 'Aluno nao encontrado' });
    }
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function criar(req, res, next) {
  try {
    const {
      codigo, nome, data_nascimento, genero, encarregado_nome, encarregado_telefone, encarregado_email
    } = req.body;
    if (!codigo || !nome) {
      return res.status(400).json({ error: 'codigo e nome sao obrigatorios' });
    }

    const { rows } = await db.query(
      `INSERT INTO school_students
       (tenant_id, codigo, nome, data_nascimento, genero, encarregado_nome, encarregado_telefone, encarregado_email)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
       RETURNING *`,
      [req.user.tenantId, codigo, nome, data_nascimento || null, genero || null, encarregado_nome || null, encarregado_telefone || null, encarregado_email || null]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function atualizar(req, res, next) {
  try {
    const { estado, encarregado_nome, encarregado_telefone, encarregado_email } = req.body;
    const { rows } = await db.query(
      `UPDATE school_students
          SET estado = COALESCE($1, estado),
              encarregado_nome = COALESCE($2, encarregado_nome),
              encarregado_telefone = COALESCE($3, encarregado_telefone),
              encarregado_email = COALESCE($4, encarregado_email),
              updated_at = NOW()
        WHERE id = $5 AND tenant_id = $6
      RETURNING *`,
      [estado ?? null, encarregado_nome ?? null, encarregado_telefone ?? null, encarregado_email ?? null, req.params.id, req.user.tenantId]
    );
    if (!rows.length) {
      return res.status(404).json({ error: 'Aluno nao encontrado' });
    }
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, obter, criar, atualizar };
