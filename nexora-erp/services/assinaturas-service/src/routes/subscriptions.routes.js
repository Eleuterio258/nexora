'use strict';

const { Router } = require('express');
const controller = require('../controllers/subscriptions.controller');

const router = Router();

router.get('/', controller.listar);
router.get('/:id', controller.obter);
router.post('/', controller.criar);
router.patch('/:id', controller.atualizar);
router.post('/:id/activate', controller.activar);
router.post('/:id/cancel', controller.cancelar);

module.exports = router;
