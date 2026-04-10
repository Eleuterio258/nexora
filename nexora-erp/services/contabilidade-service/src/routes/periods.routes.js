'use strict';

const { Router } = require('express');
const controller = require('../controllers/periods.controller');

const router = Router();

router.get('/', controller.listar);
router.post('/', controller.criar);
router.post('/:id/close', controller.fechar);

module.exports = router;
