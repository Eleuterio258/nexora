'use strict';

const { Router } = require('express');
const { requireAuth } = require('../middleware/auth');
const ctrl = require('../controllers/payables.controller');

const router = Router();

router.get('/vencidas', requireAuth, ctrl.vencidas);
router.get('/', requireAuth, ctrl.listar);
router.post('/', requireAuth, ctrl.criar);
router.get('/:id', requireAuth, ctrl.obter);
router.post('/:id/liquidar', requireAuth, ctrl.liquidar);
router.patch('/:id/cancelar', requireAuth, ctrl.cancelar);

module.exports = router;
