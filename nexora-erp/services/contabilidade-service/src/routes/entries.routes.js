'use strict';

const { Router } = require('express');
const controller = require('../controllers/entries.controller');

const router = Router();

router.get('/', controller.listar);
router.get('/:id', controller.obter);
router.post('/', controller.criar);
router.post('/:id/post', controller.publicar);

module.exports = router;
