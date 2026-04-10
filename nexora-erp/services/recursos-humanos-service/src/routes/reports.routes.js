'use strict';

const { Router } = require('express');
const controller = require('../controllers/reports.controller');

const router = Router();

router.get('/payroll-summary', controller.resumoFolha);

module.exports = router;
