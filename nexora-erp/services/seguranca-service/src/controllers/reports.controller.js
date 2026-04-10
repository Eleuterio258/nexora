'use strict';

const db = require('../config/db');

async function resumo(req, res, next) {
  try {
    const [policyRes, allowRes, mfaRes] = await Promise.all([
      db.query(`SELECT COUNT(*) AS total, COUNT(*) FILTER (WHERE activo = TRUE) AS activos FROM security_policies WHERE tenant_id = $1`, [req.user.tenantId]),
      db.query(`SELECT COUNT(*) AS total, COUNT(*) FILTER (WHERE activo = TRUE) AS activos FROM security_ip_allowlist WHERE tenant_id = $1`, [req.user.tenantId]),
      db.query(`SELECT COUNT(*) AS total, COUNT(*) FILTER (WHERE verified = TRUE AND revoked_at IS NULL) AS verificados FROM security_mfa_enrollments WHERE tenant_id = $1`, [req.user.tenantId]),
    ]);

    res.json({
      policies: policyRes.rows[0],
      allowlist: allowRes.rows[0],
      mfa: mfaRes.rows[0]
    });
  } catch (err) {
    next(err);
  }
}

module.exports = { resumo };
