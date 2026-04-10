'use strict';

const { Router } = require('express');
const ctrl = require('../controllers/auth.controller');
const { requireAuth } = require('../middleware/auth');

const router = Router();

router.post('/login',           ctrl.login);
router.post('/refresh',         ctrl.refresh);
router.post('/forgot-password', ctrl.forgotPassword);
router.post('/reset-password',  ctrl.resetPassword);
router.post('/verify-email',    ctrl.verifyEmail);

// Protected
router.get('/gateway/validate', requireAuth, ctrl.gatewayValidate);
router.post('/logout',          requireAuth, ctrl.logout);
router.get('/me',               requireAuth, ctrl.me);
router.post('/change-password', requireAuth, ctrl.changePassword);

module.exports = router;
