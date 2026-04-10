'use strict';

const { Router } = require('express');
const controller = require('../controllers/suppliers.controller');

const router = Router();

router.get('/', controller.listar);
router.get('/:id', controller.detalhar);
router.post('/', controller.criar);
router.patch('/:id', controller.atualizar);

module.exports = router;
