'use strict';

const { Router } = require('express');
const { requireAuth } = require('../middleware/auth');

const series    = require('./series.routes');
const quotes    = require('./quotes.routes');
const orders    = require('./orders.routes');
const deliveries = require('./deliveries.routes');
const invoices  = require('./invoices.routes');
const receipts  = require('./receipts.routes');
const creditnotes = require('./creditnotes.routes');
const returns   = require('./returns.routes');
const reports   = require('./reports.routes');

const router = Router();
router.use(requireAuth);

router.use('/series',       series);
router.use('/quotes',       quotes);
router.use('/orders',       orders);
router.use('/deliveries',   deliveries);
router.use('/invoices',     invoices);
router.use('/receipts',     receipts);
router.use('/credit-notes', creditnotes);
router.use('/returns',      returns);
router.use('/reports',      reports);

module.exports = router;
