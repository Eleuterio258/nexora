'use strict';

const { Router } = require('express');
const ctrl = require('../controllers/withholding.controller');

const router = Router();

router.get('/',    ctrl.listar);
router.post('/',   ctrl.criar);
router.get('/:id', ctrl.obter);
router.put('/:id', ctrl.actualizar);

router.post('/:id/transaccao', ctrl.registarTransaccao);

module.exports = router;
