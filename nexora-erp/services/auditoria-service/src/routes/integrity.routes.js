'use strict';

const { Router } = require('express');
const controller = require('../controllers/integrity.controller');

const router = Router();

router.get('/verify', controller.verificar);

module.exports = router;
