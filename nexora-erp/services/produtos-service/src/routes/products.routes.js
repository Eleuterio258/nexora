'use strict';

const { Router } = require('express');
const ctrl = require('../controllers/products.controller');

const router = Router();

router.get('/',    ctrl.listar);
router.post('/',   ctrl.criar);
router.get('/:id', ctrl.obter);
router.put('/:id', ctrl.actualizar);

router.post('/:id/activar',    ctrl.activar);
router.post('/:id/desactivar', ctrl.desactivar);

router.get('/:id/variants',        ctrl.listarVariantes);
router.post('/:id/variants',       ctrl.criarVariante);
router.put('/:id/variants/:vid',   ctrl.actualizarVariante);
router.delete('/:id/variants/:vid', ctrl.removerVariante);

router.get('/:id/prices',          ctrl.listarPrecos);
router.post('/:id/prices',         ctrl.criarPreco);
router.put('/:id/prices/:pid',     ctrl.actualizarPreco);
router.delete('/:id/prices/:pid',  ctrl.removerPreco);

router.get('/:id/barcodes',         ctrl.listarBarcodes);
router.post('/:id/barcodes',        ctrl.criarBarcode);
router.delete('/:id/barcodes/:bid', ctrl.removerBarcode);

module.exports = router;
