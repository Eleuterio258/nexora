'use strict';

const { Router } = require('express');
const ctrl = require('../controllers/taxes.controller');

const router = Router();

router.get('/',     ctrl.listarRegimes);
router.post('/',    ctrl.criarRegime);
router.put('/:id',  ctrl.actualizarRegime);
router.delete('/:id', ctrl.eliminarRegime);

module.exports = router;
