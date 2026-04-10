'use strict';
const { Router } = require('express');
const c = require('../controllers/series.controller');
const r = Router();

r.get('/',                c.listar);
r.post('/',               c.criar);
r.get('/:id',             c.obter);
r.put('/:id',             c.actualizar);
r.post('/:id/activar',    c.activar);
r.post('/:id/desactivar', c.desactivar);

module.exports = r;
