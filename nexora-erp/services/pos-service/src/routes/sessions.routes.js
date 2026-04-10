'use strict';

const { Router } = require('express');
const controller = require('../controllers/sessions.controller');

const router = Router();

router.get('/', controller.listar);
router.post('/', controller.abrir);
router.post('/:id/close', controller.fechar);

module.exports = router;
