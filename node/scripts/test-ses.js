require("dotenv").config();

const { SESClient, SendEmailCommand } = require("@aws-sdk/client-ses");

function sanitizeFrom(from) {
    if (!from) return null;
    return from.replace(/^["']+|["'>]+$/g, "").trim();
}

const from = sanitizeFrom(process.env.EMAIL_FROM) || "noreply@e258tech.co.mz";
const to = process.argv[2] || "eleuterio3d@gmail.com";

const ses = new SESClient({
    region: process.env.AWS_REGION || "us-east-1",
    credentials: {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID,
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
    }
});

const command = new SendEmailCommand({
    Source: from,
    Destination: { ToAddresses: [to] },
    Message: {
        Subject: { Data: "Teste AWS SES" },
        Body: {
            Text: { Data: "Este é um email de teste enviado via AWS SES." },
            Html: { Data: "<p>Este é um email de teste enviado via <strong>AWS SES</strong>.</p>" }
        }
    }
});

ses.send(command)
    .then((result) => {
        console.log("Email enviado com sucesso:");
        console.log("MessageId:", result.MessageId);
        console.log("De:", from);
        console.log("Para:", to);
    })
    .catch((err) => {
        console.error("Falha ao enviar email:");
        console.error(err.name, "-", err.message);
        process.exit(1);
    });
