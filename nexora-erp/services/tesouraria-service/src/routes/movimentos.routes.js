'use strict';

const { Router } = require('express');
const c = require('../controllers/movimentos.controller');

const r = Router();

r.get('/', c.listar);

module.exports = r;
