'use strict';

const { Router } = require('express');
const ctrl = require('../controllers/customers.controller');

const router = Router();

// Customers
router.get('/',    ctrl.listar);
router.post('/',   ctrl.criar);
router.get('/:id', ctrl.obter);
router.put('/:id', ctrl.actualizar);

// Estado
router.post('/:id/activar',    ctrl.activar);
router.post('/:id/bloquear',   ctrl.bloquear);
router.post('/:id/desactivar', ctrl.desactivar);

// Contacts
router.get('/:id/contacts',          ctrl.listarContacts);
router.post('/:id/contacts',         ctrl.criarContact);
router.put('/:id/contacts/:cid',     ctrl.actualizarContact);
router.delete('/:id/contacts/:cid',  ctrl.eliminarContact);

// Addresses
router.get('/:id/addresses',         ctrl.listarAddresses);
router.post('/:id/addresses',        ctrl.criarAddress);
router.put('/:id/addresses/:aid',    ctrl.actualizarAddress);
router.delete('/:id/addresses/:aid', ctrl.eliminarAddress);

// Documents
router.get('/:id/documents',  ctrl.listarDocuments);
router.post('/:id/documents', ctrl.criarDocument);

// Credit Limit
router.get('/:id/credit-limit',  ctrl.obterCreditLimit);
router.post('/:id/credit-limit', ctrl.upsertCreditLimit);

// Notes
router.get('/:id/notes',  ctrl.listarNotes);
router.post('/:id/notes', ctrl.criarNote);

// Discounts
router.get('/:id/discounts',  ctrl.listarDiscounts);
router.post('/:id/discounts', ctrl.criarDiscount);

module.exports = router;
