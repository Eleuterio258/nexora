'use strict';

const { Router } = require('express');
const { requireAuth } = require('../middleware/auth');

const currencies = require('./currencies.routes');
const tenantCurrencies = require('./tenantCurrencies.routes');
const exchangeRates = require('./exchangeRates.routes');
const conversions = require('./conversions.routes');
const reports = require('./reports.routes');

const router = Router();
router.use(requireAuth);

router.use('/currencies', currencies);
router.use('/tenant-currencies', tenantCurrencies);
router.use('/exchange-rates', exchangeRates);
router.use('/conversions', conversions);
router.use('/reports', reports);

module.exports = router;
