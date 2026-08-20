using NexoraGis.Domain.Entities.Territorial;

namespace NexoraGis.Application.Common;

public interface IJwtTokenGenerator
{
    /// <summary>Gera o access token JWT (curta duração) para o utilizador autenticado.</summary>
    (string Token, DateTimeOffset ExpiresAt) GenerateAccessToken(Utilizador utilizador);

    /// <summary>Gera um refresh token opaco (longa duração), em claro — o chamador é responsável por o hashar antes de persistir.</summary>
    (string Token, DateTimeOffset ExpiresAt) GenerateRefreshToken();
}
