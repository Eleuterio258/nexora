'use strict';

const { Router } = require('express');
const c = require('../controllers/caixas.controller');

const r = Router();

r.get('/',              c.listar);
r.post('/',             c.criar);
r.get('/:id',           c.obter);
r.put('/:id',           c.actualizar);
r.post('/:id/entrada',  c.entrada);
r.post('/:id/saida',    c.saida);

module.exports = r;
