'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { user_id } = req.query;
    const params = [req.user.tenantId];
    const cond = ['r.tenant_id = $1'];

    if (user_id) {
      params.push(user_id);
      cond.push(`ur.user_id = $${params.length}`);
    }

    const { rows } = await db.query(
      `SELECT ur.id, ur.user_id, ur.role_id, r.codigo AS role_codigo, r.nome AS role_nome, ur.created_at
         FROM user_roles ur
         JOIN roles r ON r.id = ur.role_id
        WHERE ${cond.join(' AND ')}
        ORDER BY ur.created_at DESC`,
      params
    );
    res.json(rows);
  } catch (err) { next(err); }
}

async function atribuir(req, res, next) {
  try {
    const { user_id, role_id } = req.body;
    if (!user_id || !role_id) {
      return res.status(400).json({ error: 'user_id e role_id são obrigatórios' });
    }

    const { rows: role } = await db.query(
      `SELECT id FROM roles WHERE id = $1 AND tenant_id = $2`,
      [role_id, req.user.tenantId]
    );
    if (!role.length) return res.status(404).json({ error: 'Role não encontrada' });

    const { rows } = await db.query(
      `INSERT INTO user_roles (user_id, role_id)
       VALUES ($1, $2)
       ON CONFLICT ON CONSTRAINT uq_user_roles DO NOTHING
       RETURNING *`,
      [user_id, role_id]
    );
    if (!rows.length) {
      return res.status(409).json({ error: 'Utilizador já possui esta role' });
    }
    res.status(201).json(rows[0]);
  } catch (err) { next(err); }
}

async function remover(req, res, next) {
  try {
    const { rowCount } = await db.query(
      `DELETE FROM user_roles ur
        USING roles r
        WHERE ur.id = $1 AND ur.role_id = r.id AND r.tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!rowCount) return res.status(404).json({ error: 'Atribuição não encontrada' });
    res.status(204).send();
  } catch (err) { next(err); }
}

async function verificar(req, res, next) {
  try {
    const { user_id, permission_codigo } = req.query;
    if (!user_id || !permission_codigo) {
      return res.status(400).json({ error: 'user_id e permission_codigo são obrigatórios' });
    }

    const { rows } = await db.query(
      `SELECT 1
         FROM user_roles ur
         JOIN roles r ON r.id = ur.role_id
         JOIN role_permissions rp ON rp.role_id = ur.role_id
         JOIN permissions p ON p.id = rp.permission_id
        WHERE ur.user_id = $1
          AND r.tenant_id = $2
          AND r.ativo = TRUE
          AND p.codigo = $3
        LIMIT 1`,
      [user_id, req.user.tenantId, permission_codigo]
    );
    res.json({ tem: rows.length > 0 });
  } catch (err) { next(err); }
}

module.exports = { listar, atribuir, remover, verificar };
