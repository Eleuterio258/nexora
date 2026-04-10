'use strict';

const { Router } = require('express');
const { requireAuth } = require('../middleware/auth');

const taxes      = require('./taxes.routes');
const regimes    = require('./regimes.routes');
const withholding = require('./withholding.routes');
const returns    = require('./returns.routes');

const router = Router();
router.use(requireAuth);

router.use('/taxes',        taxes);
router.use('/regimes',      regimes);
router.use('/withholding',  withholding);
router.use('/declaracoes',  returns);

module.exports = router;
