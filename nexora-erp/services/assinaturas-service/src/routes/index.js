'use strict';

const { Router } = require('express');
const { requireAuth } = require('../middleware/auth');

const plans = require('./plans.routes');
const subscriptions = require('./subscriptions.routes');
const invoices = require('./invoices.routes');
const usage = require('./usage.routes');
const reports = require('./reports.routes');

const router = Router();
router.use(requireAuth);

router.use('/plans', plans);
router.use('/subscriptions', subscriptions);
router.use('/invoices', invoices);
router.use('/usage', usage);
router.use('/reports', reports);

module.exports = router;
