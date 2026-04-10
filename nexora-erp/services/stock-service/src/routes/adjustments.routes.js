'use strict';

const { Router } = require('express');
const ctrl = require('../controllers/adjustments.controller');

const router = Router();

router.get('/',  ctrl.listar);
router.post('/', ctrl.criar);

module.exports = router;
