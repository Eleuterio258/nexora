'use strict';

const { Router } = require('express');
const { requireAuth } = require('../middleware/auth');
const ctrl = require('../controllers/payments.controller');

const router = Router();

router.get('/', requireAuth, ctrl.listar);
router.post('/', requireAuth, ctrl.criar);
router.get('/:id', requireAuth, ctrl.obter);
router.patch('/:id/cancelar', requireAuth, ctrl.cancelar);

module.exports = router;
