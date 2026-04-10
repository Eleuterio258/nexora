'use strict';

const { Router } = require('express');
const { requireAuth } = require('../middleware/auth');
const ctrl = require('../controllers/payment-methods.controller');

const router = Router();

router.get('/', requireAuth, ctrl.listar);
router.post('/', requireAuth, ctrl.criar);
router.get('/:id', requireAuth, ctrl.obter);
router.put('/:id', requireAuth, ctrl.atualizar);
router.delete('/:id', requireAuth, ctrl.remover);

module.exports = router;
