'use strict';

const { Router } = require('express');
const { requireAuth } = require('../middleware/auth');

const departments = require('./departments.routes');
const employees = require('./employees.routes');
const payrollPeriods = require('./payrollPeriods.routes');
const payrollRuns = require('./payrollRuns.routes');
const reports = require('./reports.routes');

const router = Router();
router.use(requireAuth);

router.use('/departments', departments);
router.use('/employees', employees);
router.use('/payroll-periods', payrollPeriods);
router.use('/payroll-runs', payrollRuns);
router.use('/reports', reports);

module.exports = router;
