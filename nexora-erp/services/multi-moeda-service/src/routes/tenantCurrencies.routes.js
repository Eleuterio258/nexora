'use strict';

const { Router } = require('express');
const controller = require('../controllers/tenantCurrencies.controller');

const router = Router();

router.get('/', controller.listar);
router.post('/', controller.ativar);
router.post('/:id/set-base', controller.definirBase);

module.exports = router;
