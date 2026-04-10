'use strict';

const { Router } = require('express');
const c = require('../controllers/reconciliacoes.controller');

const r = Router();

r.get('/',            c.listar);
r.post('/',           c.criar);
r.get('/:id',         c.obter);
r.post('/:id/fechar', c.fechar);

module.exports = r;
