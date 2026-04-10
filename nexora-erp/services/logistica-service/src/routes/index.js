'use strict';

const { Router } = require('express');
const { requireAuth } = require('../middleware/auth');

const vehicles = require('./vehicles.routes');
const drivers = require('./drivers.routes');
const routesResource = require('./routes.routes');
const shipments = require('./shipments.routes');
const tracking = require('./tracking.routes');
const reports = require('./reports.routes');

const router = Router();
router.use(requireAuth);

router.use('/vehicles', vehicles);
router.use('/drivers', drivers);
router.use('/routes', routesResource);
router.use('/shipments', shipments);
router.use('/tracking', tracking);
router.use('/reports', reports);

module.exports = router;
