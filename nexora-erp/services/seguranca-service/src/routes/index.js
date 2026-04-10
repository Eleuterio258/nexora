'use strict';

const { Router } = require('express');
const { requireAuth } = require('../middleware/auth');

const policies = require('./policies.routes');
const allowlist = require('./allowlist.routes');
const mfa = require('./mfa.routes');
const reports = require('./reports.routes');

const router = Router();
router.use(requireAuth);

router.use('/policies', policies);
router.use('/allowlist', allowlist);
router.use('/mfa', mfa);
router.use('/reports', reports);

module.exports = router;
