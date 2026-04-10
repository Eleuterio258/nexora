'use strict';

const { Router } = require('express');
const controller = require('../controllers/usage.controller');

const router = Router();

router.get('/', controller.listar);
router.post('/', controller.registar);

module.exports = router;
