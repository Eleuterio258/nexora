'use strict';

const { Router } = require('express');
const { requireAuth } = require('../middleware/auth');
const ctrl = require('../controllers/budgets.controller');

const router = Router();

router.get('/comparativo', requireAuth, ctrl.comparativo);
router.get('/', requireAuth, ctrl.listar);
router.post('/', requireAuth, ctrl.upsert);

module.exports = router;
