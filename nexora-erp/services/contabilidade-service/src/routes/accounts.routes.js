'use strict';

const { Router } = require('express');
const controller = require('../controllers/accounts.controller');

const router = Router();

router.get('/', controller.listar);
router.get('/:id', controller.obter);
router.post('/', controller.criar);
router.patch('/:id', controller.atualizar);

module.exports = router;
