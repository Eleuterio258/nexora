'use strict';

const { Router } = require('express');
const { requireAuth } = require('../middleware/auth');
const db = require('../config/db');

const router = Router();
router.use(requireAuth);

router.get('/', async (req, res, next) => {
  try {
    const { user_id, sucesso, page = 1, limit = 50 } = req.query;
    const offset = (page - 1) * limit;
    const params = [req.user.tenantId];
    const conditions = ['tenant_id = $1'];

    if (user_id) { params.push(user_id); conditions.push(`user_id = $${params.length}`); }
    if (sucesso !== undefined) { params.push(sucesso === 'true'); conditions.push(`sucesso = $${params.length}`); }

    const where = conditions.join(' AND ');
    params.push(Number(limit), offset);

    const { rows } = await db.query(
      `SELECT id, user_id, email_tentado, sucesso, ip_address, motivo_falha, criado_em
         FROM login_history WHERE ${where}
        ORDER BY criado_em DESC
        LIMIT $${params.length - 1} OFFSET $${params.length}`,
      params
    );

    res.json(rows);
  } catch (err) {
    next(err);
  }
});

module.exports = router;
