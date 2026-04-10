'use strict';

const { Router } = require('express');
const { requireAuth } = require('../middleware/auth');

const terminals = require('./terminals.routes');
const sessions = require('./sessions.routes');
const sales = require('./sales.routes');
const catalog = require('./catalog.routes');
const reports = require('./reports.routes');

const router = Router();
router.use(requireAuth);

router.use('/terminals', terminals);
router.use('/sessions', sessions);
router.use('/sales', sales);
router.use('/catalog', catalog);
router.use('/reports', reports);

module.exports = router;
