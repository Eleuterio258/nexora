'use strict';

const { Router } = require('express');
const controller = require('../controllers/fees.controller');

const router = Router();

router.get('/', controller.listar);
router.post('/', controller.criar);
router.post('/:id/pay', controller.pagar);

module.exports = router;
