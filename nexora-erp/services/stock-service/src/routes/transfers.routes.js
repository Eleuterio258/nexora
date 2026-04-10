'use strict';

const { Router } = require('express');
const ctrl = require('../controllers/transfers.controller');

const router = Router();

router.get('/',    ctrl.listar);
router.post('/',   ctrl.criar);
router.get('/:id', ctrl.obter);

router.post('/:id/iniciar',  ctrl.iniciar);
router.post('/:id/concluir', ctrl.concluir);
router.post('/:id/cancelar', ctrl.cancelar);

module.exports = router;
