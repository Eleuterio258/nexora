'use strict';

const { Router } = require('express');
const ctrl = require('../controllers/groups.controller');

const router = Router();

router.get('/',     ctrl.listar);
router.post('/',    ctrl.criar);
router.get('/:id',  ctrl.obter);
router.put('/:id',  ctrl.actualizar);
router.delete('/:id', ctrl.eliminar);

module.exports = router;
