'use strict';

const { Router } = require('express');
const controller = require('../controllers/reports.controller');

const router = Router();

router.get('/pipeline-summary', controller.resumoPipeline);

module.exports = router;
