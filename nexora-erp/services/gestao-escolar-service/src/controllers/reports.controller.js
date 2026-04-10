'use strict';

const db = require('../config/db');

async function resumo(req, res, next) {
  try {
    const [classesRes, studentsRes, feesRes] = await Promise.all([
      db.query(`SELECT COUNT(*) AS total FROM school_classes WHERE tenant_id = $1`, [req.user.tenantId]),
      db.query(`SELECT COUNT(*) AS total FROM school_students WHERE tenant_id = $1`, [req.user.tenantId]),
      db.query(`SELECT COUNT(*) AS total_propinas, COALESCE(SUM(valor_total), 0) AS valor_total, COALESCE(SUM(valor_pago), 0) AS valor_pago FROM school_fees WHERE tenant_id = $1`, [req.user.tenantId]),
    ]);

    res.json({
      classes: classesRes.rows[0],
      students: studentsRes.rows[0],
      fees: feesRes.rows[0]
    });
  } catch (err) {
    next(err);
  }
}

module.exports = { resumo };
