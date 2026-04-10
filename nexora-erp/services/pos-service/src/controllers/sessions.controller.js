'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { status, terminal_id } = req.query;
    const params = [req.user.tenantId];
    const conditions = ['tenant_id = $1'];
    if (status) {
      params.push(status);
      conditions.push(`status = $${params.length}`);
    }
    if (terminal_id) {
      params.push(terminal_id);
      conditions.push(`terminal_id = $${params.length}`);
    }

    const { rows } = await db.query(
      `SELECT * FROM pos_sessions WHERE ${conditions.join(' AND ')} ORDER BY opened_at DESC`,
      params
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function abrir(req, res, next) {
  try {
    const { terminal_id, opening_amount } = req.body;
    if (!terminal_id) {
      return res.status(400).json({ error: 'terminal_id e obrigatorio' });
    }

    const { rows } = await db.query(
      `INSERT INTO pos_sessions (tenant_id, terminal_id, user_id, opening_amount)
       VALUES ($1,$2,$3,$4)
       RETURNING *`,
      [req.user.tenantId, terminal_id, req.user.id, opening_amount || 0]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function fechar(req, res, next) {
  try {
    const { closing_amount } = req.body;
    const { rows } = await db.query(
      `UPDATE pos_sessions
          SET status = 'fechada',
              closing_amount = $1,
              closed_at = NOW()
        WHERE id = $2 AND tenant_id = $3 AND status = 'aberta'
      RETURNING *`,
      [closing_amount || 0, req.params.id, req.user.tenantId]
    );
    if (!rows.length) {
      return res.status(404).json({ error: 'Sessao nao encontrada ou ja fechada' });
    }
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, abrir, fechar };
