'use strict';

const { Router } = require('express');
const ctrl = require('../controllers/items.controller');

const router = Router();

router.get('/',    ctrl.listar);
router.post('/',   ctrl.criar);
router.get('/:id', ctrl.obter);
router.put('/:id', ctrl.actualizar);

router.post('/:id/entrada',  ctrl.entrada);
router.post('/:id/saida',    ctrl.saida);
router.get('/:id/movements', ctrl.listarMovimentos);

module.exports = router;
