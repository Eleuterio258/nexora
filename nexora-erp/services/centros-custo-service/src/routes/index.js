'use strict';

const { Router } = require('express');
const { requireAuth } = require('../middleware/auth');

const centers = require('./centers.routes');
const allocations = require('./allocations.routes');
const budgets = require('./budgets.routes');
const reports = require('./reports.routes');

const router = Router();
router.use(requireAuth);

router.use('/centers', centers);
router.use('/allocations', allocations);
router.use('/budgets', budgets);
router.use('/reports', reports);

module.exports = router;
