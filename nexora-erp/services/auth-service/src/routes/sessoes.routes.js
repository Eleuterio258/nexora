'use strict';

const { Router } = require('express');
const ctrl = require('../controllers/sessoes.controller');
const { requireAuth } = require('../middleware/auth');

const router = Router();
router.use(requireAuth);

router.get('/',                    ctrl.listar);
router.post('/:id/revogar',        ctrl.revogar);
router.post('/revogar-todas',      ctrl.revogarTodas);

module.exports = router;
