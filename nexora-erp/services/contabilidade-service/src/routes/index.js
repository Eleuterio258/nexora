'use strict';

const { Router } = require('express');
const { requireAuth } = require('../middleware/auth');

const periods = require('./periods.routes');
const accounts = require('./accounts.routes');
const journals = require('./journals.routes');
const entries = require('./entries.routes');
const reports = require('./reports.routes');

const router = Router();
router.use(requireAuth);

router.use('/periods', periods);
router.use('/accounts', accounts);
router.use('/journals', journals);
router.use('/entries', entries);
router.use('/reports', reports);

module.exports = router;
