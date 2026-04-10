'use strict';

/**
 * Shared JWT middleware — used by all services EXCEPT auth-service.
 * auth-service validates sessions against the DB directly.
 *
 * Usage in any service:
 *   const { requireAuth } = require('../../shared/middleware/auth');
 *   router.use(requireAuth);
 */

const jwt = require('jsonwebtoken');

function requireAuth(req, res, next) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Token em falta' });
  }

  try {
    const payload = jwt.verify(header.slice(7), process.env.JWT_SECRET);
    req.user = {
      id: Number(payload.sub),
      tenantId: Number(payload.tid),
    };
    next();
  } catch {
    res.status(401).json({ error: 'Token inválido ou expirado' });
  }
}

/**
 * Optional: restrict to specific tenant.
 * router.use(requireTenant(process.env.SYSTEM_TENANT_ID));
 */
function requireTenant(tenantId) {
  return function (req, res, next) {
    if (!req.user || req.user.tenantId !== Number(tenantId)) {
      return res.status(403).json({ error: 'Acesso negado para este tenant' });
    }
    next();
  };
}

module.exports = { requireAuth, requireTenant };
