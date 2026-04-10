'use strict';

const { Router } = require('express');
const controller = require('../controllers/pipelines.controller');

const router = Router();

router.get('/', controller.listar);
router.post('/', controller.criar);
router.get('/:id/stages', controller.listarStages);
router.post('/:id/stages', controller.criarStage);

module.exports = router;
