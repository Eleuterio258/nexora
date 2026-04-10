'use strict';

const { Router } = require('express');
const controller = require('../controllers/sales.controller');

const router = Router();

router.get('/', controller.listar);
router.get('/:id', controller.obter);
router.post('/', controller.criar);
router.post('/:id/complete', controller.finalizar);

module.exports = router;
