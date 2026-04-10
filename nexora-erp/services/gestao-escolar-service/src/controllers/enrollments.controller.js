'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { class_id, student_id, status } = req.query;
    const params = [req.user.tenantId];
    const conditions = ['tenant_id = $1'];
    if (class_id) {
      params.push(class_id);
      conditions.push(`class_id = $${params.length}`);
    }
    if (student_id) {
      params.push(student_id);
      conditions.push(`student_id = $${params.length}`);
    }
    if (status) {
      params.push(status);
      conditions.push(`status = $${params.length}`);
    }

    const { rows } = await db.query(
      `SELECT * FROM school_enrollments WHERE ${conditions.join(' AND ')} ORDER BY created_at DESC`,
      params
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function criar(req, res, next) {
  try {
    const { student_id, class_id, numero, data_matricula } = req.body;
    if (!student_id || !class_id || !numero) {
      return res.status(400).json({ error: 'student_id, class_id e numero sao obrigatorios' });
    }

    const { rows } = await db.query(
      `INSERT INTO school_enrollments (tenant_id, student_id, class_id, numero, data_matricula, created_by)
       VALUES ($1,$2,$3,$4,$5,$6)
       RETURNING *`,
      [req.user.tenantId, student_id, class_id, numero, data_matricula || null, req.user.id]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, criar };
