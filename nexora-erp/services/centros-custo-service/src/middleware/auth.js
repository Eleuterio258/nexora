'use strict';

const jwt = require('jsonwebtoken');

function requireAuth(req, res, next) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Token em falta' });
  }

  try {
    const payload = jwt.verify(header.slice(7), process.env.JWT_SECRET);
    req.user = { id: Number(payload.sub), tenantId: Number(payload.tid) };
    next();
  } catch {
    res.status(401).json({ error: 'Token invalido ou expirado' });
  }
}

module.exports = { requireAuth };
