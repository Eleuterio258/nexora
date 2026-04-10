'use strict';
const { Router } = require('express');
const c = require('../controllers/creditnotes.controller');
const r = Router();

r.get('/',              c.listar);
r.post('/',             c.criar);
r.get('/:id',           c.obter);
r.put('/:id',           c.actualizar);
r.post('/:id/emitir',   c.emitir);
r.post('/:id/aplicar',  c.aplicar);
r.post('/:id/cancelar', c.cancelar);
r.post('/:id/items',    c.adicionarItem);

module.exports = r;
