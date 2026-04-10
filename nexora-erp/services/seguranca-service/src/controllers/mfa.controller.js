'use strict';

const crypto = require('crypto');
const db = require('../config/db');

function gerarSecret() {
  return crypto.randomBytes(20).toString('hex');
}

async function listar(req, res, next) {
  try {
    const { user_id } = req.query;
    const params = [req.user.tenantId];
    let sql = `SELECT id, tenant_id, user_id, metodo, verified, last_verified_at, revoked_at, created_at
                 FROM security_mfa_enrollments
                WHERE tenant_id = $1`;
    if (user_id) {
      params.push(user_id);
      sql += ` AND user_id = $2`;
    }
    sql += ` ORDER BY created_at DESC`;

    const { rows } = await db.query(sql, params);
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function enroll(req, res, next) {
  try {
    const { user_id, metodo } = req.body;
    if (!user_id) {
      return res.status(400).json({ error: 'user_id e obrigatorio' });
    }

    const secret = gerarSecret();
    const { rows } = await db.query(
      `INSERT INTO security_mfa_enrollments (tenant_id, user_id, metodo, secret, created_by)
       VALUES ($1,$2,$3,$4,$5)
       ON CONFLICT (tenant_id, user_id, metodo)
       DO UPDATE SET secret = EXCLUDED.secret, verified = FALSE, revoked_at = NULL
       RETURNING id, tenant_id, user_id, metodo, secret, verified, created_at`,
      [req.user.tenantId, user_id, metodo || 'totp', secret, req.user.id]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function verify(req, res, next) {
  try {
    const { enrollment_id, codigo } = req.body;
    if (!enrollment_id || !codigo) {
      return res.status(400).json({ error: 'enrollment_id e codigo sao obrigatorios' });
    }

    const { rows } = await db.query(
      `UPDATE security_mfa_enrollments
          SET verified = TRUE,
              last_verified_at = NOW()
        WHERE id = $1 AND tenant_id = $2 AND revoked_at IS NULL
      RETURNING id, tenant_id, user_id, metodo, verified, last_verified_at`,
      [enrollment_id, req.user.tenantId]
    );
    if (!rows.length) {
      return res.status(404).json({ error: 'Enrollment MFA nao encontrado' });
    }
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function revogar(req, res, next) {
  try {
    const { rows } = await db.query(
      `UPDATE security_mfa_enrollments
          SET revoked_at = NOW()
        WHERE id = $1 AND tenant_id = $2 AND revoked_at IS NULL
      RETURNING id, user_id, metodo, revoked_at`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) {
      return res.status(404).json({ error: 'Enrollment MFA nao encontrado' });
    }
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, enroll, verify, revogar };
