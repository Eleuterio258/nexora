'use strict';

const { Router } = require('express');
const controller = require('../controllers/payrollRuns.controller');

const router = Router();

router.get('/', controller.listar);
router.get('/:id', controller.obter);
router.post('/', controller.processar);
router.post('/:id/approve', controller.aprovar);

module.exports = router;
