'use strict';

const { Router } = require('express');
const { requireAuth } = require('../middleware/auth');

const rolesRoutes       = require('./roles.routes');
const permissionsRoutes = require('./permissions.routes');
const userRolesRoutes   = require('./userRoles.routes');

const router = Router();
router.use(requireAuth);

router.use('/roles',      rolesRoutes);
router.use('/permissions', permissionsRoutes);
router.use('/user-roles', userRolesRoutes);

module.exports = router;
