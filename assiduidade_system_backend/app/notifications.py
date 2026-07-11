"""
Servico de notificacoes para alertas de falha, excecao e aprovacao.
Suporta email e SMS via providers configuraveis.
"""
import asyncio
import logging
import os
from datetime import datetime, timezone
from enum import Enum
from typing import Any


logger = logging.getLogger("faceclock.notifications")


class NotificationChannel(str, Enum):
    EMAIL = "email"
    SMS = "sms"
    WEBHOOK = "webhook"


class NotificationType(str, Enum):
    ADJUSTMENT_CREATED = "adjustment_created"
    ADJUSTMENT_APPROVED = "adjustment_approved"
    ADJUSTMENT_REJECTED = "adjustment_rejected"
    CONSENT_REVOKED = "consent_revoked"
    BIOMETRIC_ENROLL_FAILED = "biometric_enroll_failed"
    SYNC_FAILED = "sync_failed"
    SYSTEM_ALERT = "system_alert"


def _get_provider_config() -> dict[str, str]:
    return {
        "email_provider": os.getenv("EMAIL_PROVIDER", "").strip().lower(),
        "smtp_host": os.getenv("SMTP_HOST", ""),
        "smtp_port": int(os.getenv("SMTP_PORT", "587")),
        "smtp_user": os.getenv("SMTP_USER", ""),
        "smtp_password": os.getenv("SMTP_PASSWORD", ""),
        "smtp_from": os.getenv("SMTP_FROM", "faceclock@local"),
        "aws_region": os.getenv("AWS_SES_REGION", os.getenv("AWS_REGION", "")),
        "aws_access_key_id": os.getenv("AWS_ACCESS_KEY_ID", ""),
        "aws_secret_access_key": os.getenv("AWS_SECRET_ACCESS_KEY", ""),
        "aws_session_token": os.getenv("AWS_SESSION_TOKEN", ""),
        "aws_ses_from": os.getenv("AWS_SES_FROM", os.getenv("SMTP_FROM", "faceclock@local")),
        "aws_ses_reply_to": os.getenv("AWS_SES_REPLY_TO", ""),
        "aws_ses_configuration_set": os.getenv("AWS_SES_CONFIGURATION_SET", ""),
        "sms_api_key": os.getenv("SMS_API_KEY", ""),
        "sms_api_url": os.getenv("SMS_API_URL", ""),
        "webhook_url": os.getenv("NOTIFICATION_WEBHOOK_URL", ""),
    }


async def send_notification(
    channel: NotificationChannel,
    recipient: str,
    subject: str,
    body: str,
    notification_type: NotificationType = NotificationType.SYSTEM_ALERT,
    metadata: dict[str, Any] | None = None,
) -> bool:
    """
    Envia uma notificacao via o canal especificado.
    Retorna True se enviada com sucesso, False se falhou ou nao configurado.
    """
    config = _get_provider_config()

    try:
        if channel == NotificationChannel.EMAIL:
            return await _send_email(config, recipient, subject, body)
        elif channel == NotificationChannel.SMS:
            return await _send_sms(config, recipient, body)
        elif channel == NotificationChannel.WEBHOOK:
            return await _send_webhook(config, subject, body, notification_type, metadata)
        return False
    except Exception as exc:
        logger.error("Failed to send notification via %s: %s", channel.value, exc)
        return False


async def _send_email(config: dict, to: str, subject: str, body: str) -> bool:
    email_provider = config["email_provider"]
    if email_provider == "aws_ses":
        return await _send_email_via_ses(config, to, subject, body)

    if not config["smtp_host"]:
        logger.info("Email not configured, logging notification: to=%s, subject=%s", to, subject)
        return True

    import smtplib
    from email.mime.text import MIMEText

    msg = MIMEText(body, "html", "utf-8")
    msg["Subject"] = subject
    msg["From"] = config["smtp_from"]
    msg["To"] = to

    try:
        loop = asyncio.get_event_loop()
        await loop.run_in_executor(
            None,
            lambda: _do_send_email(config, msg),
        )
        logger.info("Email sent: to=%s, subject=%s", to, subject)
        return True
    except Exception as exc:
        logger.error("Email send failed: %s", exc)
        return False


async def _send_email_via_ses(config: dict, to: str, subject: str, body: str) -> bool:
    if not config["aws_region"] or not config["aws_ses_from"]:
        logger.info("AWS SES not configured, logging notification: to=%s, subject=%s", to, subject)
        return True

    try:
        loop = asyncio.get_event_loop()
        await loop.run_in_executor(
            None,
            lambda: _do_send_email_via_ses(config, to, subject, body),
        )
        logger.info("Email sent via AWS SES: to=%s, subject=%s", to, subject)
        return True
    except Exception as exc:
        logger.error("AWS SES email send failed: %s", exc)
        return False


def _do_send_email(config: dict, msg):
    import smtplib

    with smtplib.SMTP(config["smtp_host"], config["smtp_port"]) as server:
        server.starttls()
        if config["smtp_user"] and config["smtp_password"]:
            server.login(config["smtp_user"], config["smtp_password"])
        server.send_message(msg)


def _do_send_email_via_ses(config: dict, to: str, subject: str, body: str):
    import boto3

    client_kwargs = {"region_name": config["aws_region"]}
    if config["aws_access_key_id"] and config["aws_secret_access_key"]:
        client_kwargs["aws_access_key_id"] = config["aws_access_key_id"]
        client_kwargs["aws_secret_access_key"] = config["aws_secret_access_key"]
    if config["aws_session_token"]:
        client_kwargs["aws_session_token"] = config["aws_session_token"]

    client = boto3.client("ses", **client_kwargs)
    request = {
        "Source": config["aws_ses_from"],
        "Destination": {"ToAddresses": [to]},
        "Message": {
            "Subject": {"Data": subject, "Charset": "UTF-8"},
            "Body": {"Html": {"Data": body, "Charset": "UTF-8"}},
        },
    }
    if config["aws_ses_reply_to"]:
        request["ReplyToAddresses"] = [config["aws_ses_reply_to"]]
    if config["aws_ses_configuration_set"]:
        request["ConfigurationSetName"] = config["aws_ses_configuration_set"]
    client.send_email(**request)


async def _send_sms(config: dict, to: str, body: str) -> bool:
    if not config["sms_api_url"] or not config["sms_api_key"]:
        logger.info("SMS not configured, logging notification: to=%s", to)
        return True

    import httpx

    try:
        async with httpx.AsyncClient(timeout=10) as client:
            response = await client.post(
                config["sms_api_url"],
                json={
                    "to": to,
                    "message": body[:160],
                },
                headers={"Authorization": f"Bearer {config['sms_api_key']}"},
            )
            if response.status_code in (200, 201, 202):
                logger.info("SMS sent: to=%s", to)
                return True
            logger.error("SMS send failed: status=%d", response.status_code)
            return False
    except Exception as exc:
        logger.error("SMS send failed: %s", exc)
        return False


async def _send_webhook(
    config: dict,
    subject: str,
    body: str,
    notification_type: NotificationType,
    metadata: dict | None,
) -> bool:
    if not config["webhook_url"]:
        logger.info("Webhook not configured, logging notification: subject=%s", subject)
        return True

    import httpx

    try:
        async with httpx.AsyncClient(timeout=10) as client:
            response = await client.post(
                config["webhook_url"],
                json={
                    "type": notification_type.value,
                    "subject": subject,
                    "body": body,
                    "metadata": metadata or {},
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                },
            )
            if response.status_code in (200, 201, 202):
                logger.info("Webhook sent: subject=%s", subject)
                return True
            logger.error("Webhook send failed: status=%d", response.status_code)
            return False
    except Exception as exc:
        logger.error("Webhook send failed: %s", exc)
        return False
