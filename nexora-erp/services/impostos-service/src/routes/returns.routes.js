'use strict';

const { Router } = require('express');
const ctrl = require('../controllers/returns.controller');

const router = Router();

router.get('/',    ctrl.listar);
router.post('/',   ctrl.criar);
router.get('/:id', ctrl.obter);
router.put('/:id', ctrl.actualizar);

router.post('/:id/submeter', ctrl.submeter);
router.post('/:id/pagar',    ctrl.pagar);

module.exports = router;
