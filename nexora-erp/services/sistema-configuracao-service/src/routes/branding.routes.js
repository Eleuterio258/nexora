'use strict';

const { Router } = require('express');
const controller = require('../controllers/branding.controller');

const router = Router();

router.get('/', controller.obter);
router.post('/', controller.upsert);

module.exports = router;
