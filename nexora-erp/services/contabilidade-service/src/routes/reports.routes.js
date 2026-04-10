'use strict';

const { Router } = require('express');
const controller = require('../controllers/reports.controller');

const router = Router();

router.get('/trial-balance', controller.balancete);
router.get('/general-ledger', controller.razao);

module.exports = router;
