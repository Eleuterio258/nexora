'use strict';

const { Router } = require('express');
const ctrl = require('../controllers/empresas.controller');
const { requireAuth } = require('../middleware/auth');

const router = Router();
router.use(requireAuth);

router.get('/',    ctrl.listar);
router.post('/',   ctrl.criar);
router.get('/:id', ctrl.obter);
router.put('/:id', ctrl.actualizar);

// Settings
router.get('/:id/settings',           ctrl.getSettings);
router.post('/:id/settings',          ctrl.upsertSetting);

// Tax info
router.get('/:id/tax-info',           ctrl.getTaxInfo);
router.post('/:id/tax-info',          ctrl.upsertTaxInfo);
router.put('/:id/tax-info',           ctrl.upsertTaxInfo);

// Branches
router.get('/:id/branches',           ctrl.listBranches);
router.post('/:id/branches',          ctrl.createBranch);

// Banks
router.get('/:id/banks',              ctrl.listBanks);
router.post('/:id/banks',             ctrl.createBank);

// Users
router.get('/:id/users',              ctrl.listUsers);
router.post('/:id/users',             ctrl.addUser);
router.delete('/:id/users/:userId',   ctrl.removeUser);

module.exports = router;
