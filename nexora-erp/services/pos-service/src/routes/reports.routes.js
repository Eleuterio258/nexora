'use strict';

const { Router } = require('express');
const controller = require('../controllers/reports.controller');

const router = Router();

router.get('/sales-summary', controller.resumoVendas);

module.exports = router;
