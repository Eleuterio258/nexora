'use strict';
const { Router } = require('express');
const c = require('../controllers/reports.controller');
const r = Router();

r.get('/sales-summary',      c.salesSummary);
r.get('/revenue-by-customer', c.revenueByCustomer);
r.get('/revenue-by-product',  c.revenueByProduct);
r.get('/aging-receivables',   c.agingReceivables);
r.get('/tax-summary',         c.taxSummary);
r.get('/top-customers',       c.topCustomers);

module.exports = r;
