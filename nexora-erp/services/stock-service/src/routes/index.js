'use strict';

const { Router } = require('express');
const { requireAuth } = require('../middleware/auth');

const items       = require('./items.routes');
const transfers   = require('./transfers.routes');
const adjustments = require('./adjustments.routes');
const alerts      = require('./alerts.routes');

const router = Router();
router.use(requireAuth);

router.use('/items',       items);
router.use('/transfers',   transfers);
router.use('/adjustments', adjustments);
router.use('/alerts',      alerts);

module.exports = router;
