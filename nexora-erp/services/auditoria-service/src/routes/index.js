'use strict';

const { Router } = require('express');
const { requireAuth } = require('../middleware/auth');

const events = require('./events.routes');
const reports = require('./reports.routes');
const integrity = require('./integrity.routes');

const router = Router();
router.use(requireAuth);

router.use('/events', events);
router.use('/reports', reports);
router.use('/integrity', integrity);

module.exports = router;
