'use strict';

const { Router } = require('express');
const controller = require('../controllers/purchaseOrders.controller');

const router = Router();

router.get('/', controller.listar);
router.get('/:id', controller.detalhar);
router.post('/', controller.criar);
router.post('/:id/approve', controller.aprovar);

module.exports = router;
