'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { ativo } = req.query;
    const params = [req.user.tenantId];
    const cond = ['tenant_id = $1'];

    if (ativo !== undefined) {
      params.push(ativo === 'true');
      cond.push(`ativo = $${params.length}`);
    }

    const { rows } = await db.query(
      `SELECT id, tenant_id, codigo, nome, descricao, ativo, created_at
         FROM roles WHERE ${cond.join(' AND ')}
        ORDER BY nome ASC`,
      params
    );
    res.json(rows);
  } catch (err) { next(err); }
}

async function criar(req, res, next) {
  try {
    const { codigo, nome, descricao } = req.body;
    if (!codigo || !nome) {
      return res.status(400).json({ error: 'codigo e nome são obrigatórios' });
    }
    const { rows } = await db.query(
      `INSERT INTO roles (tenant_id, codigo, nome, descricao)
       VALUES ($1, $2, $3, $4) RETURNING *`,
      [req.user.tenantId, codigo, nome, descricao || null]
    );
    res.status(201).json(rows[0]);
  } catch (err) { next(err); }
}

async function obter(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT * FROM roles WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Role não encontrada' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function actualizar(req, res, next) {
  try {
    const { nome, descricao, ativo } = req.body;
    const { rows } = await db.query(
      `UPDATE roles SET
         nome      = COALESCE($1, nome),
         descricao = COALESCE($2, descricao),
         ativo     = COALESCE($3, ativo)
       WHERE id = $4 AND tenant_id = $5 RETURNING *`,
      [nome || null, descricao !== undefined ? descricao : null, ativo !== undefined ? ativo : null,
       req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Role não encontrada' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function eliminar(req, res, next) {
  try {
    const { rows: ur } = await db.query(
      `SELECT id FROM user_roles WHERE role_id = $1 LIMIT 1`,
      [req.params.id]
    );
    if (ur.length) {
      return res.status(409).json({ error: 'Não é possível eliminar role com utilizadores associados' });
    }
    const { rowCount } = await db.query(
      `DELETE FROM roles WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!rowCount) return res.status(404).json({ error: 'Role não encontrada' });
    res.status(204).send();
  } catch (err) { next(err); }
}

async function listarPermissions(req, res, next) {
  try {
    const { rows: role } = await db.query(
      `SELECT id FROM roles WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!role.length) return res.status(404).json({ error: 'Role não encontrada' });

    const { rows } = await db.query(
      `SELECT p.id, p.codigo, p.nome, p.descricao, p.recurso, p.acao, rp.created_at AS atribuida_em
         FROM role_permissions rp
         JOIN permissions p ON p.id = rp.permission_id
        WHERE rp.role_id = $1
        ORDER BY p.recurso, p.acao`,
      [req.params.id]
    );
    res.json(rows);
  } catch (err) { next(err); }
}

async function atribuirPermission(req, res, next) {
  try {
    const { permission_id } = req.body;
    if (!permission_id) return res.status(400).json({ error: 'permission_id é obrigatório' });

    const { rows: role } = await db.query(
      `SELECT id FROM roles WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!role.length) return res.status(404).json({ error: 'Role não encontrada' });

    const { rows: perm } = await db.query(
      `SELECT id FROM permissions WHERE id = $1`,
      [permission_id]
    );
    if (!perm.length) return res.status(404).json({ error: 'Permission não encontrada' });

    const { rows } = await db.query(
      `INSERT INTO role_permissions (role_id, permission_id)
       VALUES ($1, $2)
       ON CONFLICT ON CONSTRAINT uq_role_permissions DO NOTHING
       RETURNING *`,
      [req.params.id, permission_id]
    );
    if (!rows.length) {
      return res.status(409).json({ error: 'Permission já atribuída a esta role' });
    }
    res.status(201).json(rows[0]);
  } catch (err) { next(err); }
}

async function removerPermission(req, res, next) {
  try {
    const { rows: role } = await db.query(
      `SELECT id FROM roles WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!role.length) return res.status(404).json({ error: 'Role não encontrada' });

    const { rowCount } = await db.query(
      `DELETE FROM role_permissions WHERE role_id = $1 AND permission_id = $2`,
      [req.params.id, req.params.permissionId]
    );
    if (!rowCount) return res.status(404).json({ error: 'Associação não encontrada' });
    res.status(204).send();
  } catch (err) { next(err); }
}

module.exports = {
  listar, criar, obter, actualizar, eliminar,
  listarPermissions, atribuirPermission, removerPermission,
};
