'use strict';

const { Router } = require('express');
const { requireAuth } = require('../middleware/auth');

const classes = require('./classes.routes');
const students = require('./students.routes');
const enrollments = require('./enrollments.routes');
const fees = require('./fees.routes');
const attendance = require('./attendance.routes');
const reports = require('./reports.routes');

const router = Router();
router.use(requireAuth);

router.use('/classes', classes);
router.use('/students', students);
router.use('/enrollments', enrollments);
router.use('/fees', fees);
router.use('/attendance', attendance);
router.use('/reports', reports);

module.exports = router;
