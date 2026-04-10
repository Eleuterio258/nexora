'use strict';
const { Router } = require('express');
const c = require('../controllers/quotes.controller');
const r = Router();

r.get('/',                          c.listar);
r.post('/',                         c.criar);
r.get('/:id',                       c.obter);
r.put('/:id',                       c.actualizar);
r.delete('/:id',                    c.eliminar);
r.post('/:id/enviar',               c.enviar);
r.post('/:id/aprovar',              c.aprovar);
r.post('/:id/rejeitar',             c.rejeitar);
r.post('/:id/converter',            c.converter);
r.post('/:id/items',                c.adicionarItem);
r.put('/:id/items/:item_id',        c.actualizarItem);
r.delete('/:id/items/:item_id',     c.removerItem);

module.exports = r;
