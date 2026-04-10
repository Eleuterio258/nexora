'use strict';

const { Router } = require('express');
const c = require('../controllers/contasBancarias.controller');

const r = Router();

r.get('/',                  c.listar);
r.post('/',                 c.criar);
r.get('/:id',               c.obter);
r.put('/:id',               c.actualizar);
r.post('/:id/deposito',     c.deposito);
r.post('/:id/levantamento', c.levantamento);

module.exports = r;
