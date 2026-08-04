from slowapi import Limiter
from slowapi.util import get_remote_address


def _get_limit_key(request):
    """Combina IP remoto com access key Nexora quando disponível.

    Assim o rate limiting protege tanto contra abuso de um IP como contra
    abuso de uma credencial específica (ex.: terminal comprometido).
    """
    ip = get_remote_address(request)
    access_key = request.headers.get("X-Nexora-Access-Key", "anonymous")
    return f"{ip}:{access_key}"


limiter = Limiter(key_func=_get_limit_key)
