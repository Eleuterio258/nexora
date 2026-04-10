'use strict';

const { Router } = require('express');
const controller = require('../controllers/events.controller');

const router = Router();

router.get('/', controller.listar);
router.get('/:id', controller.obter);
router.post('/', controller.criar);

module.exports = router;
