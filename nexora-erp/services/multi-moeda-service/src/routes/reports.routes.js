'use strict';

const { Router } = require('express');
const controller = require('../controllers/reports.controller');

const router = Router();

router.get('/latest-rates', controller.ultimasTaxas);

module.exports = router;
