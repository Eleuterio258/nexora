'use strict';

const { Router } = require('express');
const controller = require('../controllers/shipments.controller');

const router = Router();

router.get('/', controller.listar);
router.get('/:id', controller.obter);
router.post('/', controller.criar);
router.post('/:id/dispatch', controller.despachar);
router.post('/:id/deliver', controller.entregar);
router.post('/:id/cancel', controller.cancelar);

module.exports = router;
