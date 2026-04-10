'use strict';

const { Router } = require('express');
const { requireAuth } = require('../middleware/auth');

const branding = require('./branding.routes');
const defaults = require('./defaults.routes');
const documentSettings = require('./documentSettings.routes');
const featureFlags = require('./featureFlags.routes');
const integrations = require('./integrations.routes');

const router = Router();
router.use(requireAuth);

router.use('/branding', branding);
router.use('/defaults', defaults);
router.use('/documents', documentSettings);
router.use('/features', featureFlags);
router.use('/integrations', integrations);

module.exports = router;
