"""Exceções do SDK Nexora."""


class NexoraError(Exception):
    """Base para todas as exceções do SDK Nexora."""


class NexoraConfigError(NexoraError):
    """Credenciais ou configuração em falta/inválidas."""


class NexoraAuthError(NexoraError):
    """Erro de autenticação HMAC ou resposta 401/403/409 do backend."""


class NexoraRequestError(NexoraError):
    """Erro de comunicação HTTP com o backend."""

    def __init__(self, message: str, status_code: int | None = None, response_body: str | None = None):
        super().__init__(message)
        self.status_code = status_code
        self.response_body = response_body
