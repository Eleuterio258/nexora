'use strict';

const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const db = require('../config/db');

async function requireAuth(req, res, next) {
  try {
    const header = req.headers.authorization;
    if (!header || !header.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Token em falta' });
    }

    const token = header.slice(7);
    let payload;
    try {
      payload = jwt.verify(token, process.env.JWT_SECRET);
    } catch {
      return res.status(401).json({ error: 'Token inválido ou expirado' });
    }

    // Verify session is still active in DB
    const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
    const { rows } = await db.query(
      `SELECT s.id, s.ativa, u.estado, u.tenant_id
         FROM sessions s
         JOIN users u ON u.id = s.user_id
        WHERE s.token_hash = $1 AND s.user_id = $2`,
      [tokenHash, payload.sub]
    );

    if (!rows.length || !rows[0].ativa) {
      return res.status(401).json({ error: 'Sessão revogada' });
    }

    if (rows[0].estado !== 'ativo') {
      return res.status(403).json({ error: 'Utilizador inactivo ou bloqueado' });
    }

    req.user = {
      id: payload.sub,
      tenantId: rows[0].tenant_id,
      sessionId: rows[0].id,
    };

    next();
  } catch (err) {
    next(err);
  }
}

module.exports = { requireAuth };
