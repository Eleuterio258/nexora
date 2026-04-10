'use strict';

const { Router } = require('express');
const { requireAuth } = require('../middleware/auth');
const ctrl = require('../controllers/cashflow.controller');

const router = Router();

router.get('/resumo', requireAuth, ctrl.resumo);
router.get('/', requireAuth, ctrl.listar);
router.post('/', requireAuth, ctrl.criar);

module.exports = router;
