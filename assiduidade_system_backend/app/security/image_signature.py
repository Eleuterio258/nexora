"""
Assinatura de payload de imagem para prova de integridade e proveniencia.

O dispositivo assina a string `image_base64` (ou `image_url`) com a sua chave
privada Ed25519. O FaceClock valida a assinatura usando a chave publica
fornecida no request ou resolvida a partir do device_id no futuro.

Quando `REQUIRE_IMAGE_SIGNATURE=true`, os endpoints verify/identify rejeitam
capturas nao assinadas.
"""

from __future__ import annotations

import base64
import logging

log = logging.getLogger(__name__)


def verify_image_signature(
    public_key_b64: str | None,
    message: str | None,
    signature_b64: str | None,
) -> bool:
    """Verifica uma assinatura Ed25519 sobre a imagem.

    Args:
        public_key_b64: chave publica Ed25519 em base64.
        message: conteudo assinado (image_base64 ou image_url).
        signature_b64: assinatura em base64.

    Returns:
        True se a assinatura for valida; False caso contrario ou se algum
        parametro estiver em falta.
    """
    if not public_key_b64 or not message or not signature_b64:
        return False

    try:
        from cryptography.exceptions import InvalidSignature
        from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PublicKey
    except ImportError as exc:
        raise RuntimeError(
            "cryptography nao suporta Ed25519 ou nao esta instalado."
        ) from exc

    try:
        public_key_bytes = base64.b64decode(public_key_b64)
        signature = base64.b64decode(signature_b64)
        public_key = Ed25519PublicKey.from_public_bytes(public_key_bytes)
        public_key.verify(signature, message.encode("utf-8"))
        return True
    except (InvalidSignature, ValueError, Exception):
        return False
