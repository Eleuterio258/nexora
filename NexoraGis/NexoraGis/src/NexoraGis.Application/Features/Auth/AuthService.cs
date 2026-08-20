using System.Security.Cryptography;
using System.Text;
using NexoraGis.Application.Common;
using NexoraGis.Domain.Entities.Territorial;
using NexoraGis.Domain.Repositories;

namespace NexoraGis.Application.Features.Auth;

public class AuthService(
    IRepository<Utilizador> utilizadores,
    IRepository<RefreshToken> refreshTokens,
    IPasswordHasher passwordHasher,
    IJwtTokenGenerator jwtTokenGenerator,
    IUnitOfWork unitOfWork)
{
    public async Task<AuthResponse?> LoginAsync(LoginRequest request, CancellationToken ct = default)
    {
        var candidates = await utilizadores.FindAsync(
            u => u.Ativo && (u.Username == request.UsernameOrEmail || u.Email == request.UsernameOrEmail), ct);
        var utilizador = candidates.FirstOrDefault();

        if (utilizador is null || !passwordHasher.Verify(utilizador.PasswordHash, request.Password))
            return null;

        utilizador.UltimoAcesso = DateTimeOffset.UtcNow;
        await utilizadores.UpdateAsync(utilizador, ct);

        return await IssueTokensAsync(utilizador, ct);
    }

    public async Task<AuthResponse?> RefreshAsync(RefreshRequest request, CancellationToken ct = default)
    {
        var tokenHash = HashToken(request.RefreshToken);
        var stored = (await refreshTokens.FindAsync(t => t.TokenHash == tokenHash, ct)).FirstOrDefault();
        if (stored is null || !stored.IsActive)
            return null;

        var utilizador = (await utilizadores.FindAsync(u => u.Id == stored.UtilizadorId && u.Ativo, ct)).FirstOrDefault();
        if (utilizador is null)
            return null;

        var response = await IssueTokensAsync(utilizador, ct);

        stored.RevokedAt = DateTimeOffset.UtcNow;
        stored.ReplacedByTokenHash = HashToken(response.RefreshToken);
        await refreshTokens.UpdateAsync(stored, ct);
        await unitOfWork.SaveChangesAsync(ct);

        return response;
    }

    public async Task LogoutAsync(string refreshToken, CancellationToken ct = default)
    {
        var tokenHash = HashToken(refreshToken);
        var stored = (await refreshTokens.FindAsync(t => t.TokenHash == tokenHash, ct)).FirstOrDefault();
        if (stored is null || stored.RevokedAt is not null)
            return;

        stored.RevokedAt = DateTimeOffset.UtcNow;
        await refreshTokens.UpdateAsync(stored, ct);
        await unitOfWork.SaveChangesAsync(ct);
    }

    private async Task<AuthResponse> IssueTokensAsync(Utilizador utilizador, CancellationToken ct)
    {
        var (accessToken, accessExpires) = jwtTokenGenerator.GenerateAccessToken(utilizador);
        var (refreshToken, refreshExpires) = jwtTokenGenerator.GenerateRefreshToken();

        await refreshTokens.AddAsync(new RefreshToken
        {
            UtilizadorId = utilizador.Id,
            TokenHash = HashToken(refreshToken),
            ExpiresAt = refreshExpires
        }, ct);

        await unitOfWork.SaveChangesAsync(ct);

        return new AuthResponse(
            accessToken, accessExpires, refreshToken, refreshExpires,
            utilizador.Id, utilizador.NomeCompleto, utilizador.Perfil.ToString(), utilizador.OrganizacaoId);
    }

    private static string HashToken(string token)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(token));
        return Convert.ToHexString(bytes);
    }
}
