'use strict';

const { Router } = require('express');
const controller = require('../controllers/budgets.controller');

const router = Router();

router.get('/', controller.listar);
router.post('/', controller.upsert);

module.exports = router;
