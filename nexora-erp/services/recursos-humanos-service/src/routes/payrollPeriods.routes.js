'use strict';

const { Router } = require('express');
const controller = require('../controllers/payrollPeriods.controller');

const router = Router();

router.get('/', controller.listar);
router.post('/', controller.criar);
router.post('/:id/close', controller.fechar);

module.exports = router;
