'use strict';

const { Router } = require('express');
const controller = require('../controllers/conversions.controller');

const router = Router();

router.post('/', controller.converter);

module.exports = router;
