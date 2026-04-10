'use strict';

const { Router } = require('express');
const ctrl = require('../controllers/warehouses.controller');

const router = Router();

router.get('/',    ctrl.listar);
router.post('/',   ctrl.criar);
router.get('/:id', ctrl.obter);
router.put('/:id', ctrl.actualizar);
router.delete('/:id', ctrl.remover);

module.exports = router;
