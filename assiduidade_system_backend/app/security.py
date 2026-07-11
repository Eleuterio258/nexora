import bcrypt


def verify_password(plain_password: str, password_hash: str) -> bool:
    return bcrypt.checkpw(
        plain_password.encode('utf-8'),
        password_hash.encode('utf-8')
    )


def get_password_hash(password: str) -> str:
    return bcrypt.hashpw(
        password.encode('utf-8'),
        bcrypt.gensalt()
    ).decode('utf-8')


def validate_password_strength(password: str) -> str | None:
    """Valida forca da senha. Retorna mensagem de erro ou None se valida."""
    if len(password) < 8:
        return "A senha deve ter pelo menos 8 caracteres."
    if not any(c.isupper() for c in password):
        return "A senha deve conter pelo menos uma letra maiuscula."
    if not any(c.islower() for c in password):
        return "A senha deve conter pelo menos uma letra minuscula."
    if not any(c.isdigit() for c in password):
        return "A senha deve conter pelo menos um numero."
    return None

