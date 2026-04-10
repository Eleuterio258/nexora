'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT id, ip_address, user_agent, iniciado_em, expira_em,
              (id = $2) AS atual
         FROM sessions
        WHERE user_id = $1 AND ativa = TRUE AND expira_em > NOW()
        ORDER BY iniciado_em DESC`,
      [req.user.id, req.user.sessionId]
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function revogar(req, res, next) {
  try {
    const { rowCount } = await db.query(
      `UPDATE sessions SET ativa = FALSE, encerrado_em = NOW()
        WHERE id = $1 AND user_id = $2`,
      [req.params.id, req.user.id]
    );
    if (!rowCount) return res.status(404).json({ error: 'Sessão não encontrada' });
    res.status(204).send();
  } catch (err) {
    next(err);
  }
}

async function revogarTodas(req, res, next) {
  try {
    await db.query(
      `UPDATE sessions SET ativa = FALSE, encerrado_em = NOW()
        WHERE user_id = $1 AND id != $2`,
      [req.user.id, req.user.sessionId]
    );
    res.status(204).send();
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, revogar, revogarTodas };
