'use strict';

const { Router } = require('express');
const controller = require('../controllers/messages.controller');

const router = Router();

router.get('/', controller.listar);
router.post('/', controller.criar);
router.post('/:id/send', controller.enviar);

module.exports = router;
