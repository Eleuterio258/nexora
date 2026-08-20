namespace NexoraGis.Application.Features.Auth;

public record LoginRequest(string UsernameOrEmail, string Password);

public record RefreshRequest(string RefreshToken);

public record AuthResponse(
    string AccessToken,
    DateTimeOffset AccessTokenExpiresAt,
    string RefreshToken,
    DateTimeOffset RefreshTokenExpiresAt,
    Guid UtilizadorId,
    string NomeCompleto,
    string Perfil,
    Guid OrganizacaoId);
