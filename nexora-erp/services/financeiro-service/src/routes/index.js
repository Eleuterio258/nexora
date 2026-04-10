'use strict';

const { Router } = require('express');

const router = Router();

router.use('/payment-methods', require('./payment-methods.routes'));
router.use('/categories', require('./categories.routes'));
router.use('/payments', require('./payments.routes'));
router.use('/receivables', require('./receivables.routes'));
router.use('/payables', require('./payables.routes'));
router.use('/budgets', require('./budgets.routes'));
router.use('/cashflow', require('./cashflow.routes'));

module.exports = router;
