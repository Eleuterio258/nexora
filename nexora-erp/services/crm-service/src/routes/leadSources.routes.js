'use strict';

const { Router } = require('express');
const controller = require('../controllers/leadSources.controller');

const router = Router();

router.get('/', controller.listar);
router.post('/', controller.criar);

module.exports = router;
