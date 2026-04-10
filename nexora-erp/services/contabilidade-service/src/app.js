'use strict';

const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const errorHandler = require('./middleware/errorHandler');
const routes = require('./routes');

const app = express();

app.use(helmet());
app.set('trust proxy', 1);
app.use(cors({ origin: process.env.CORS_ORIGIN || '*' }));
app.use(rateLimit({ windowMs: 60 * 1000, max: 200 }));
app.use(express.json({ limit: '1mb' }));

app.use('/api/contabilidade', routes);

app.get('/health', (req, res) => res.json({ status: 'ok', service: 'contabilidade-service' }));
app.use((req, res) => res.status(404).json({ error: 'Rota nao encontrada' }));
app.use(errorHandler);

module.exports = app;
