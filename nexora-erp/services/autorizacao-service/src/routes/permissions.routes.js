'use strict';

const { Router } = require('express');
const c = require('../controllers/permissions.controller');

const r = Router();

r.get('/',      c.listar);
r.post('/',     c.criar);
r.get('/:id',   c.obter);
r.put('/:id',   c.actualizar);
r.delete('/:id', c.eliminar);

module.exports = r;
