'use strict';

const { Router } = require('express');
const ctrl = require('../controllers/alerts.controller');

const router = Router();

router.get('/', ctrl.listar);

router.post('/:id/resolver', ctrl.resolver);
router.post('/:id/ignorar',  ctrl.ignorar);

module.exports = router;
