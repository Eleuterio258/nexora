'use strict';

const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { v4: uuidv4 } = require('uuid');
const db = require('../config/db');

// ── helpers ──────────────────────────────────────────────────────────────────

function hashToken(token) {
  return crypto.createHash('sha256').update(token).digest('hex');
}

function signAccess(userId, tenantId) {
  return jwt.sign(
    { sub: userId, tid: tenantId },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '15m' }
  );
}

function signRefresh(userId) {
  return jwt.sign(
    { sub: userId },
    process.env.JWT_REFRESH_SECRET,
    { expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d' }
  );
}

function parseDuration(str) {
  const m = str.match(/^(\d+)([mhd])$/);
  if (!m) return 15 * 60 * 1000;
  const n = parseInt(m[1]);
  return m[2] === 'm' ? n * 60000 : m[2] === 'h' ? n * 3600000 : n * 86400000;
}

// ── controllers ───────────────────────────────────────────────────────────────

async function login(req, res, next) {
  try {
    const { email, password, tenant_id } = req.body;
    if (!email || !password || !tenant_id) {
      return res.status(400).json({ error: 'email, password e tenant_id são obrigatórios' });
    }

    const { rows } = await db.query(
      `SELECT id, nome, password_hash, estado, tenant_id
         FROM users WHERE email = $1 AND tenant_id = $2`,
      [email.toLowerCase(), tenant_id]
    );

    const user = rows[0];
    const valid = user && await bcrypt.compare(password, user.password_hash);

    // Audit log (fire-and-forget)
    db.query(
      `INSERT INTO login_history (user_id, tenant_id, email_tentado, sucesso, ip_address, user_agent, motivo_falha)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [
        valid ? user.id : null,
        tenant_id,
        email.toLowerCase(),
        !!valid,
        req.ip,
        req.headers['user-agent'] || null,
        !valid ? (user ? 'password incorrecta' : 'utilizador não encontrado') : null,
      ]
    ).catch(() => {});

    if (!valid) {
      return res.status(401).json({ error: 'Credenciais inválidas' });
    }

    if (user.estado !== 'ativo') {
      return res.status(403).json({ error: `Conta ${user.estado}` });
    }

    const accessToken = signAccess(user.id, user.tenant_id);
    const refreshToken = signRefresh(user.id);
    const refreshExpires = parseDuration(process.env.JWT_REFRESH_EXPIRES_IN || '7d');

    await db.query(
      `INSERT INTO sessions (user_id, token_hash, ip_address, user_agent, expira_em)
       VALUES ($1, $2, $3, $4, $5)`,
      [
        user.id,
        hashToken(accessToken),
        req.ip,
        req.headers['user-agent'] || null,
        new Date(Date.now() + parseDuration(process.env.JWT_EXPIRES_IN || '15m')),
      ]
    );

    await db.query(
      `UPDATE users SET ultimo_login_em = CURRENT_TIMESTAMP WHERE id = $1`,
      [user.id]
    );

    res.json({
      access_token: accessToken,
      refresh_token: refreshToken,
      token_type: 'Bearer',
      expires_in: parseDuration(process.env.JWT_EXPIRES_IN || '15m') / 1000,
      user: { id: user.id, nome: user.nome, email },
    });
  } catch (err) {
    next(err);
  }
}

async function logout(req, res, next) {
  try {
    await db.query(
      `UPDATE sessions SET ativa = FALSE, encerrado_em = CURRENT_TIMESTAMP
        WHERE id = $1`,
      [req.user.sessionId]
    );
    res.status(204).send();
  } catch (err) {
    next(err);
  }
}

async function refresh(req, res, next) {
  try {
    const { refresh_token } = req.body;
    if (!refresh_token) {
      return res.status(400).json({ error: 'refresh_token é obrigatório' });
    }

    let payload;
    try {
      payload = jwt.verify(refresh_token, process.env.JWT_REFRESH_SECRET);
    } catch {
      return res.status(401).json({ error: 'refresh_token inválido ou expirado' });
    }

    const { rows } = await db.query(
      `SELECT id, tenant_id, estado FROM users WHERE id = $1`,
      [payload.sub]
    );

    const user = rows[0];
    if (!user || user.estado !== 'ativo') {
      return res.status(401).json({ error: 'Utilizador inactivo' });
    }

    const accessToken = signAccess(user.id, user.tenant_id);

    await db.query(
      `INSERT INTO sessions (user_id, token_hash, ip_address, user_agent, expira_em)
       VALUES ($1, $2, $3, $4, $5)`,
      [
        user.id,
        hashToken(accessToken),
        req.ip,
        req.headers['user-agent'] || null,
        new Date(Date.now() + parseDuration(process.env.JWT_EXPIRES_IN || '15m')),
      ]
    );

    res.json({
      access_token: accessToken,
      token_type: 'Bearer',
      expires_in: parseDuration(process.env.JWT_EXPIRES_IN || '15m') / 1000,
    });
  } catch (err) {
    next(err);
  }
}

async function me(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT id, tenant_id, nome, email, telefone, estado, email_verificado,
              ultimo_login_em, created_at
         FROM users WHERE id = $1`,
      [req.user.id]
    );
    if (!rows.length) return res.status(404).json({ error: 'Utilizador não encontrado' });
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function changePassword(req, res, next) {
  try {
    const { password_actual, nova_password } = req.body;
    if (!password_actual || !nova_password) {
      return res.status(400).json({ error: 'password_actual e nova_password são obrigatórios' });
    }
    if (nova_password.length < 8) {
      return res.status(400).json({ error: 'A nova password deve ter pelo menos 8 caracteres' });
    }

    const { rows } = await db.query(`SELECT password_hash FROM users WHERE id = $1`, [req.user.id]);
    const valid = rows.length && await bcrypt.compare(password_actual, rows[0].password_hash);
    if (!valid) return res.status(401).json({ error: 'Password actual incorrecta' });

    const hash = await bcrypt.hash(nova_password, 12);
    await db.query(
      `UPDATE users SET password_hash = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2`,
      [hash, req.user.id]
    );

    // Revoke all other sessions
    await db.query(
      `UPDATE sessions SET ativa = FALSE, encerrado_em = CURRENT_TIMESTAMP
        WHERE user_id = $1 AND id != $2`,
      [req.user.id, req.user.sessionId]
    );

    res.status(204).send();
  } catch (err) {
    next(err);
  }
}

async function forgotPassword(req, res, next) {
  try {
    const { email, tenant_id } = req.body;
    if (!email || !tenant_id) {
      return res.status(400).json({ error: 'email e tenant_id são obrigatórios' });
    }

    const { rows } = await db.query(
      `SELECT id FROM users WHERE email = $1 AND tenant_id = $2 AND estado = 'ativo'`,
      [email.toLowerCase(), tenant_id]
    );

    // Always respond 204 to avoid user enumeration
    if (rows.length) {
      const token = uuidv4();
      const tokenHash = hashToken(token);
      await db.query(
        `INSERT INTO password_resets (user_id, token_hash, expira_em)
         VALUES ($1, $2, NOW() + INTERVAL '1 hour')`,
        [rows[0].id, tokenHash]
      );
      // TODO: enqueue email via RabbitMQ with token
      console.log(`[auth] Password reset token for user ${rows[0].id}: ${token}`);
    }

    res.status(204).send();
  } catch (err) {
    next(err);
  }
}

async function resetPassword(req, res, next) {
  try {
    const { token, nova_password } = req.body;
    if (!token || !nova_password) {
      return res.status(400).json({ error: 'token e nova_password são obrigatórios' });
    }
    if (nova_password.length < 8) {
      return res.status(400).json({ error: 'A nova password deve ter pelo menos 8 caracteres' });
    }

    const tokenHash = hashToken(token);
    const { rows } = await db.query(
      `SELECT id, user_id FROM password_resets
        WHERE token_hash = $1 AND usado_em IS NULL AND expira_em > NOW()`,
      [tokenHash]
    );

    if (!rows.length) {
      return res.status(400).json({ error: 'Token inválido ou expirado' });
    }

    const hash = await bcrypt.hash(nova_password, 12);
    await Promise.all([
      db.query(`UPDATE users SET password_hash = $1, updated_at = NOW() WHERE id = $2`, [hash, rows[0].user_id]),
      db.query(`UPDATE password_resets SET usado_em = NOW() WHERE id = $1`, [rows[0].id]),
      db.query(`UPDATE sessions SET ativa = FALSE, encerrado_em = NOW() WHERE user_id = $1`, [rows[0].user_id]),
    ]);

    res.status(204).send();
  } catch (err) {
    next(err);
  }
}

async function verifyEmail(req, res, next) {
  try {
    const { token } = req.body;
    if (!token) return res.status(400).json({ error: 'token é obrigatório' });

    const tokenHash = hashToken(token);
    const { rows } = await db.query(
      `SELECT id, user_id FROM email_verifications
        WHERE token_hash = $1 AND usado_em IS NULL AND expira_em > NOW()`,
      [tokenHash]
    );

    if (!rows.length) return res.status(400).json({ error: 'Token inválido ou expirado' });

    await Promise.all([
      db.query(`UPDATE users SET email_verificado = TRUE, updated_at = NOW() WHERE id = $1`, [rows[0].user_id]),
      db.query(`UPDATE email_verifications SET usado_em = NOW() WHERE id = $1`, [rows[0].id]),
    ]);

    res.status(204).send();
  } catch (err) {
    next(err);
  }
}

async function gatewayValidate(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT id, tenant_id, nome, email
         FROM users
        WHERE id = $1`,
      [req.user.id]
    );

    if (!rows.length) {
      return res.status(404).json({ error: 'Utilizador nao encontrado' });
    }

    const user = rows[0];
    res
      .set('X-Auth-User-Id', String(user.id))
      .set('X-Auth-Tenant-Id', String(user.tenant_id))
      .set('X-Auth-Session-Id', String(req.user.sessionId))
      .set('X-Auth-User-Email', user.email)
      .set('X-Auth-User-Name', user.nome)
      .status(204)
      .send();
  } catch (err) {
    next(err);
  }
}

module.exports = { login, logout, refresh, me, changePassword, forgotPassword, resetPassword, verifyEmail, gatewayValidate };
