'use strict';

const { Router } = require('express');
const controller = require('../controllers/classes.controller');

const router = Router();

router.get('/', controller.listar);
router.post('/', controller.criar);
router.patch('/:id', controller.atualizar);

module.exports = router;
