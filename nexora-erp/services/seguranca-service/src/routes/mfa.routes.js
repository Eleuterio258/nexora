'use strict';

const { Router } = require('express');
const controller = require('../controllers/mfa.controller');

const router = Router();

router.get('/', controller.listar);
router.post('/enroll', controller.enroll);
router.post('/verify', controller.verify);
router.post('/:id/revoke', controller.revogar);

module.exports = router;
