'use strict';

const { Router } = require('express');
const { requireAuth } = require('../middleware/auth');

const categories = require('./categories.routes');
const brands     = require('./brands.routes');
const units      = require('./units.routes');
const warehouses = require('./warehouses.routes');
const products   = require('./products.routes');

const router = Router();
router.use(requireAuth);

router.use('/categories', categories);
router.use('/brands',     brands);
router.use('/units',      units);
router.use('/warehouses', warehouses);
router.use('/',           products);

module.exports = router;
