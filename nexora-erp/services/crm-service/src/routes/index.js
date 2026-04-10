'use strict';

const { Router } = require('express');
const { requireAuth } = require('../middleware/auth');

const leadSources = require('./leadSources.routes');
const pipelines = require('./pipelines.routes');
const leads = require('./leads.routes');
const opportunities = require('./opportunities.routes');
const activities = require('./activities.routes');
const reports = require('./reports.routes');

const router = Router();
router.use(requireAuth);

router.use('/lead-sources', leadSources);
router.use('/pipelines', pipelines);
router.use('/leads', leads);
router.use('/opportunities', opportunities);
router.use('/activities', activities);
router.use('/reports', reports);

module.exports = router;
