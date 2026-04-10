'use strict';

const { Router } = require('express');
const { requireAuth } = require('../middleware/auth');

const suppliers = require('./suppliers.routes');
const purchaseOrders = require('./purchaseOrders.routes');
const goodsReceipts = require('./goodsReceipts.routes');
const purchaseReturns = require('./purchaseReturns.routes');
const reports = require('./reports.routes');

const router = Router();
router.use(requireAuth);

router.use('/suppliers', suppliers);
router.use('/purchase-orders', purchaseOrders);
router.use('/goods-receipts', goodsReceipts);
router.use('/purchase-returns', purchaseReturns);
router.use('/reports', reports);

module.exports = router;
