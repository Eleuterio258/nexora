'use strict';

const { Router } = require('express');
const { requireAuth } = require('../middleware/auth');

const templates = require('./templates.routes');
const messages = require('./messages.routes');
const channels = require('./channels.routes');
const reports = require('./reports.routes');

const router = Router();
router.use(requireAuth);

router.use('/templates', templates);
router.use('/messages', messages);
router.use('/channels', channels);
router.use('/reports', reports);

module.exports = router;
