'use strict';

const { Router } = require('express');
const { requireAuth } = require('../middleware/auth');

const contasBancarias  = require('./contasBancarias.routes');
const caixas           = require('./caixas.routes');
const movimentos       = require('./movimentos.routes');
const reconciliacoes   = require('./reconciliacoes.routes');

const router = Router();
router.use(requireAuth);

router.use('/contas-bancarias', contasBancarias);
router.use('/caixas',           caixas);
router.use('/movimentos',       movimentos);
router.use('/reconciliacoes',   reconciliacoes);

module.exports = router;
