'use strict';

const { Router } = require('express');
const c = require('../controllers/returns.controller');

const r = Router();

r.get('/',                c.listar);
r.post('/',               c.criar);
r.get('/:id',             c.obter);
r.post('/:id/receber',    c.receber);
r.post('/:id/processar',  c.processar);

module.exports = r;
