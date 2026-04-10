'use strict';

const { Router } = require('express');
const { requireAuth } = require('../middleware/auth');

const groups    = require('./groups.routes');
const customers = require('./customers.routes');

const router = Router();
router.use(requireAuth);

router.use('/groups',    groups);
router.use('/customers', customers);

module.exports = router;
