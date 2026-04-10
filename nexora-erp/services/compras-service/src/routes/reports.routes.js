'use strict';

const { Router } = require('express');
const controller = require('../controllers/reports.controller');

const router = Router();

router.get('/summary', controller.resumo);

module.exports = router;
