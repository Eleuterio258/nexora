'use strict';

const { Router } = require('express');
const c = require('../controllers/userRoles.controller');

const r = Router();

r.get('/check',  c.verificar);
r.get('/',       c.listar);
r.post('/',      c.atribuir);
r.delete('/:id', c.remover);

module.exports = r;
