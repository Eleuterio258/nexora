'use strict';

const bcrypt = require('bcryptjs');
const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { estado, search, page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;
    const params = [req.user.tenantId];
    const conditions = ['tenant_id = $1'];

    if (estado) {
      params.push(estado);
      conditions.push(`estado = $${params.length}`);
    }
    if (search) {
      params.push(`%${search}%`);
      conditions.push(`(nome ILIKE $${params.length} OR email ILIKE $${params.length})`);
    }

    const where = conditions.join(' AND ');
    params.push(Number(limit), offset);

    const [dataRes, countRes] = await Promise.all([
      db.query(
        `SELECT id, nome, email, telefone, estado, email_verificado, ultimo_login_em, created_at
           FROM users WHERE ${where}
          ORDER BY nome ASC
          LIMIT $${params.length - 1} OFFSET $${params.length}`,
        params
      ),
      db.query(`SELECT COUNT(*) FROM users WHERE ${where}`, params.slice(0, -2)),
    ]);

    res.json({
      data: dataRes.rows,
      meta: { total: parseInt(countRes.rows[0].count), page: Number(page), limit: Number(limit) },
    });
  } catch (err) {
    next(err);
  }
}

async function criar(req, res, next) {
  try {
    const { nome, email, password, telefone } = req.body;
    if (!nome || !email || !password) {
      return res.status(400).json({ error: 'nome, email e password são obrigatórios' });
    }
    if (password.length < 8) {
      return res.status(400).json({ error: 'Password deve ter pelo menos 8 caracteres' });
    }

    const hash = await bcrypt.hash(password, 12);
    const { rows } = await db.query(
      `INSERT INTO users (tenant_id, nome, email, password_hash, telefone, estado)
       VALUES ($1, $2, $3, $4, $5, 'pendente')
       RETURNING id, nome, email, telefone, estado, created_at`,
      [req.user.tenantId, nome, email.toLowerCase(), hash, telefone || null]
    );

    res.status(201).json(rows[0]);
  } catch (err) {
    if (err.code === '23505') return res.status(409).json({ error: 'Email já existe neste tenant' });
    next(err);
  }
}

async function obter(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT id, nome, email, telefone, estado, email_verificado, ultimo_login_em, created_at, updated_at
         FROM users WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Utilizador não encontrado' });
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function actualizar(req, res, next) {
  try {
    const { nome, telefone } = req.body;
    const { rows } = await db.query(
      `UPDATE users SET
         nome = COALESCE($1, nome),
         telefone = COALESCE($2, telefone),
         updated_at = CURRENT_TIMESTAMP
       WHERE id = $3 AND tenant_id = $4
       RETURNING id, nome, email, telefone, estado, updated_at`,
      [nome || null, telefone || null, req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Utilizador não encontrado' });
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function mudarEstado(estado) {
  return async function (req, res, next) {
    try {
      const extra = req.body.motivo ? `, motivo_bloqueio = $3` : '';
      const params = [estado, req.params.id, req.user.tenantId];

      const { rows } = await db.query(
        `UPDATE users SET estado = $1, updated_at = NOW()
           WHERE id = $2 AND tenant_id = $3
           RETURNING id, nome, estado`,
        params
      );
      if (!rows.length) return res.status(404).json({ error: 'Utilizador não encontrado' });

      if (estado === 'bloqueado') {
        await db.query(
          `UPDATE sessions SET ativa = FALSE, encerrado_em = NOW() WHERE user_id = $1`,
          [req.params.id]
        );
      }

      res.json(rows[0]);
    } catch (err) {
      next(err);
    }
  };
}

module.exports = {
  listar,
  criar,
  obter,
  actualizar,
  activar: mudarEstado('ativo'),
  bloquear: mudarEstado('bloqueado'),
  desactivar: mudarEstado('inativo'),
};
