'use strict';

const { Router } = require('express');
const ctrl = require('../controllers/utilizadores.controller');
const { requireAuth } = require('../middleware/auth');

const router = Router();
router.use(requireAuth);

router.get('/',                    ctrl.listar);
router.post('/',                   ctrl.criar);
router.get('/:id',                 ctrl.obter);
router.put('/:id',                 ctrl.actualizar);
router.post('/:id/activar',        ctrl.activar);
router.post('/:id/bloquear',       ctrl.bloquear);
router.post('/:id/desactivar',     ctrl.desactivar);

module.exports = router;
