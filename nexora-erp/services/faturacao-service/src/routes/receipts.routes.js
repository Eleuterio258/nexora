'use strict';
const { Router } = require('express');
const c = require('../controllers/receipts.controller');
const r = Router();

r.get('/',               c.listar);
r.post('/',              c.criar);
r.get('/:id',            c.obter);
r.post('/:id/cancelar',  c.cancelar);

module.exports = r;
