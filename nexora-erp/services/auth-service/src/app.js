'use strict';

const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const errorHandler = require('./middleware/errorHandler');

const authRoutes        = require('./routes/auth.routes');
const utilizadoresRoutes = require('./routes/utilizadores.routes');
const sessoesRoutes     = require('./routes/sessoes.routes');
const apikeysRoutes     = require('./routes/apikeys.routes');
const historicoRoutes   = require('./routes/historico.routes');

const app = express();

// Security
app.use(helmet());
app.set('trust proxy', 1);
app.use(cors({ origin: process.env.CORS_ORIGIN || '*' }));

// Rate limiting — stricter on auth endpoints
app.use('/api/auth/login',          rateLimit({ windowMs: 15 * 60 * 1000, max: 20, message: { error: 'Demasiadas tentativas. Tente de novo em 15 minutos.' } }));
app.use('/api/auth/forgot-password', rateLimit({ windowMs: 60 * 60 * 1000, max: 5,  message: { error: 'Limite de pedidos atingido.' } }));
app.use('/api/auth',                rateLimit({ windowMs: 60 * 1000, max: 120 }));

app.use(express.json({ limit: '1mb' }));

// Routes
app.use('/api/auth',                authRoutes);
app.use('/api/auth/utilizadores',   utilizadoresRoutes);
app.use('/api/auth/sessoes',        sessoesRoutes);
app.use('/api/auth/api-keys',       apikeysRoutes);
app.use('/api/auth/historico-login', historicoRoutes);

// Health check
app.get('/health', (req, res) => res.json({ status: 'ok', service: 'auth-service' }));

// 404
app.use((req, res) => res.status(404).json({ error: 'Rota não encontrada' }));

app.use(errorHandler);

module.exports = app;
