'use strict';

const { Router } = require('express');
const c = require('../controllers/orders.controller');

const r = Router();

r.get('/',                          c.listar);
r.post('/',                         c.criar);
r.get('/:id',                       c.obter);
r.put('/:id',                       c.actualizar);
r.post('/:id/confirmar',            c.confirmar);
r.post('/:id/cancelar',             c.cancelar);
r.post('/:id/items',                c.adicionarItem);
r.put('/:id/items/:item_id',        c.actualizarItem);
r.delete('/:id/items/:item_id',     c.removerItem);

module.exports = r;
