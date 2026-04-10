'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { class_id, student_id, attendance_date } = req.query;
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
    if (attendance_date) {
      params.push(attendance_date);
      conditions.push(`attendance_date = $${params.length}`);
    }

    const { rows } = await db.query(
      `SELECT * FROM school_attendance WHERE ${conditions.join(' AND ')} ORDER BY attendance_date DESC`,
      params
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function registar(req, res, next) {
  try {
    const { class_id, student_id, attendance_date, estado, observacoes } = req.body;
    if (!class_id || !student_id || !attendance_date || !estado) {
      return res.status(400).json({ error: 'class_id, student_id, attendance_date e estado sao obrigatorios' });
    }

    const { rows } = await db.query(
      `INSERT INTO school_attendance
       (tenant_id, class_id, student_id, attendance_date, estado, observacoes, created_by)
       VALUES ($1,$2,$3,$4,$5,$6,$7)
       ON CONFLICT (class_id, student_id, attendance_date)
       DO UPDATE SET estado = EXCLUDED.estado, observacoes = EXCLUDED.observacoes
       RETURNING *`,
      [req.user.tenantId, class_id, student_id, attendance_date, estado, observacoes || null, req.user.id]
    );
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, registar };
