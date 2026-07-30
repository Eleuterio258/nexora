require("dotenv").config();

const express = require("express");
const nodemailer = require("nodemailer");
const { rateLimit, ipKeyGenerator } = require("express-rate-limit");
const { Pool } = require("pg");
const { Queue, Worker, Job } = require("bullmq");
const IORedis = require("ioredis");

const transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: Number(process.env.SMTP_PORT),
    secure: true, // Porta 465 = SSL

    auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS
    },

    pool: true,
    maxConnections: 5,
    maxMessages: 100
});

const db = new Pool({ connectionString: process.env.DATABASE_URL });

const connection = new IORedis(process.env.REDIS_URL, { maxRetriesPerRequest: null });
const emailQueue = new Queue("emails", { connection });

const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const MAX_BULK_ITEMS = 500;

async function registarEnvio({ clienteId, to, subject, estado, erro, messageId }) {
    try {
        await db.query(
            `INSERT INTO envios (cliente_id, destinatario, assunto, estado, erro, message_id)
             VALUES ($1, $2, $3, $4, $5, $6)`,
            [clienteId, to, subject, estado, erro || null, messageId || null]
        );
    } catch (err) {
        console.error("Falha ao registar envio:", err);
    }
}

new Worker(
    "emails",
    async (job) => {
        const { clienteId, to, subject, text, html } = job.data;

        try {
            const info = await transporter.sendMail({
                from: process.env.EMAIL_FROM,
                to,
                subject,
                text,
                html
            });

            await registarEnvio({ clienteId, to, subject, estado: "enviado", messageId: info.messageId });
            return { messageId: info.messageId };
        } catch (err) {
            await registarEnvio({ clienteId, to, subject, estado: "falhou", erro: err.message });
            throw err;
        }
    },
    { connection }
);

const app = express();
app.use(express.json());

app.get("/health", (req, res) => {
    res.json({ status: "ok" });
});

async function requireApiKey(req, res, next) {
    const key = req.header("x-api-key");

    if (!key) {
        return res.status(401).json({ error: "API key em falta" });
    }

    try {
        const result = await db.query(
            "SELECT id, nome FROM clientes WHERE api_key = $1 AND activo = true",
            [key]
        );

        if (result.rows.length === 0) {
            return res.status(401).json({ error: "API key inválida" });
        }

        req.cliente = result.rows[0];
        next();
    } catch (err) {
        console.error("Falha ao validar API key:", err);
        res.status(500).json({ error: "Erro interno" });
    }
}

const sendLimiter = rateLimit({
    windowMs: 60 * 1000,
    limit: 30,
    standardHeaders: true,
    legacyHeaders: false,
    keyGenerator: (req) => req.header("x-api-key") || ipKeyGenerator(req.ip)
});

const bulkLimiter = rateLimit({
    windowMs: 60 * 1000,
    limit: 5,
    standardHeaders: true,
    legacyHeaders: false,
    keyGenerator: (req) => req.header("x-api-key") || ipKeyGenerator(req.ip)
});

app.post("/send-email", requireApiKey, sendLimiter, async (req, res) => {
    const { to, subject, text, html } = req.body;

    if (!to || !subject || (!text && !html)) {
        return res.status(400).json({
            error: "Campos obrigatórios: to, subject e (text ou html)"
        });
    }

    if (!emailRegex.test(to)) {
        return res.status(400).json({ error: "Endereço 'to' inválido" });
    }

    const job = await emailQueue.add("send", {
        clienteId: req.cliente.id,
        to,
        subject,
        text,
        html
    });

    res.status(202).json({ jobId: job.id, status: "queued" });
});

app.post("/send-email/bulk", requireApiKey, bulkLimiter, async (req, res) => {
    const { emails } = req.body;

    if (!Array.isArray(emails) || emails.length === 0) {
        return res.status(400).json({ error: "Campo 'emails' deve ser um array não vazio" });
    }

    if (emails.length > MAX_BULK_ITEMS) {
        return res.status(400).json({ error: `Máximo de ${MAX_BULK_ITEMS} emails por pedido` });
    }

    for (let i = 0; i < emails.length; i++) {
        const { to, subject, text, html } = emails[i];

        if (!to || !subject || (!text && !html)) {
            return res.status(400).json({
                error: `Item ${i}: campos obrigatórios 'to', 'subject' e ('text' ou 'html')`
            });
        }

        if (!emailRegex.test(to)) {
            return res.status(400).json({ error: `Item ${i}: endereço 'to' inválido` });
        }
    }

    const jobs = await emailQueue.addBulk(
        emails.map(({ to, subject, text, html }) => ({
            name: "send",
            data: { clienteId: req.cliente.id, to, subject, text, html }
        }))
    );

    res.status(202).json({
        status: "queued",
        total: jobs.length,
        jobs: jobs.map((j) => ({ jobId: j.id, to: j.data.to }))
    });
});

app.get("/send-email/:jobId", requireApiKey, async (req, res) => {
    const job = await Job.fromId(emailQueue, req.params.jobId);

    if (!job) {
        return res.status(404).json({ error: "Job não encontrado" });
    }

    const state = await job.getState();
    res.json({ jobId: job.id, state, result: job.returnvalue, failedReason: job.failedReason });
});

const port = process.env.PORT || 3000;
app.listen(port, () => {
    console.log(`API a correr na porta ${port}`);
});
