'use strict';

const { Router } = require('express');
const c = require('../controllers/roles.controller');

const r = Router();

r.get('/',                              c.listar);
r.post('/',                             c.criar);
r.get('/:id',                           c.obter);
r.put('/:id',                           c.actualizar);
r.delete('/:id',                        c.eliminar);
r.get('/:id/permissions',               c.listarPermissions);
r.post('/:id/permissions',              c.atribuirPermission);
r.delete('/:id/permissions/:permissionId', c.removerPermission);

module.exports = r;
