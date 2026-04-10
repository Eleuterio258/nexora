'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { estado, department_id } = req.query;
    const params = [req.user.tenantId];
    const conditions = ['e.tenant_id = $1'];

    if (estado) {
      params.push(estado);
      conditions.push(`e.estado = $${params.length}`);
    }
    if (department_id) {
      params.push(department_id);
      conditions.push(`e.department_id = $${params.length}`);
    }

    const { rows } = await db.query(
      `SELECT e.*, d.nome AS department_nome
         FROM employees e
         LEFT JOIN hr_departments d ON d.id = e.department_id
        WHERE ${conditions.join(' AND ')}
        ORDER BY e.nome ASC`,
      params
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function obter(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT e.*, d.nome AS department_nome
         FROM employees e
         LEFT JOIN hr_departments d ON d.id = e.department_id
        WHERE e.id = $1 AND e.tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) {
      return res.status(404).json({ error: 'Funcionario nao encontrado' });
    }
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function criar(req, res, next) {
  try {
    const {
      department_id, user_id, codigo, nome, email, telefone, nuit, data_nascimento, data_admissao,
      cargo, tipo_contrato, salario_base, moeda
    } = req.body;

    if (!codigo || !nome || !data_admissao || !cargo) {
      return res.status(400).json({ error: 'codigo, nome, data_admissao e cargo sao obrigatorios' });
    }

    const { rows } = await db.query(
      `INSERT INTO employees
       (tenant_id, department_id, user_id, codigo, nome, email, telefone, nuit, data_nascimento, data_admissao, cargo, tipo_contrato, salario_base, moeda)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14)
       RETURNING *`,
      [
        req.user.tenantId,
        department_id || null,
        user_id || null,
        codigo,
        nome,
        email || null,
        telefone || null,
        nuit || null,
        data_nascimento || null,
        data_admissao,
        cargo,
        tipo_contrato || 'efectivo',
        salario_base || 0,
        moeda || 'MZN'
      ]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function atualizar(req, res, next) {
  try {
    const {
      department_id, email, telefone, estado, cargo, tipo_contrato, salario_base, moeda
    } = req.body;

    const { rows } = await db.query(
      `UPDATE employees
          SET department_id = COALESCE($1, department_id),
              email = COALESCE($2, email),
              telefone = COALESCE($3, telefone),
              estado = COALESCE($4, estado),
              cargo = COALESCE($5, cargo),
              tipo_contrato = COALESCE($6, tipo_contrato),
              salario_base = COALESCE($7, salario_base),
              moeda = COALESCE($8, moeda),
              updated_at = NOW()
        WHERE id = $9 AND tenant_id = $10
      RETURNING *`,
      [department_id ?? null, email ?? null, telefone ?? null, estado ?? null, cargo ?? null, tipo_contrato ?? null, salario_base ?? null, moeda ?? null, req.params.id, req.user.tenantId]
    );

    if (!rows.length) {
      return res.status(404).json({ error: 'Funcionario nao encontrado' });
    }

    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, obter, criar, atualizar };
