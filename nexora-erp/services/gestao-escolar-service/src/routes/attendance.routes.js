'use strict';

const { Router } = require('express');
const controller = require('../controllers/attendance.controller');

const router = Router();

router.get('/', controller.listar);
router.post('/', controller.registar);

module.exports = router;
