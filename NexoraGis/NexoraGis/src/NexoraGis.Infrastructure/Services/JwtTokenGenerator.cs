using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using NexoraGis.Application.Common;
using NexoraGis.Domain.Entities.Territorial;
using NexoraGis.Domain.Enums;

namespace NexoraGis.Infrastructure.Services;

public class JwtTokenGenerator(IOptions<JwtOptions> options) : IJwtTokenGenerator
{
    private readonly JwtOptions _options = options.Value;

    public (string Token, DateTimeOffset ExpiresAt) GenerateAccessToken(Utilizador utilizador)
    {
        var expiresAt = DateTimeOffset.UtcNow.AddMinutes(_options.AccessTokenMinutes);

        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, utilizador.Id.ToString()),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            new Claim(ClaimTypes.Name, utilizador.Username),
            new Claim(ClaimTypes.Email, utilizador.Email),
            new Claim("perfil", utilizador.Perfil.ToWireString()),
            new Claim("organizacao_id", utilizador.OrganizacaoId.ToString())
        };

        var signingKey = new SymmetricSecurityKey(JwtSigningKeyFactory.GetKeyBytes(_options.SigningKey));
        var credentials = new SigningCredentials(signingKey, SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: _options.Issuer,
            audience: _options.Audience,
            claims: claims,
            expires: expiresAt.UtcDateTime,
            signingCredentials: credentials);

        return (new JwtSecurityTokenHandler().WriteToken(token), expiresAt);
    }

    public (string Token, DateTimeOffset ExpiresAt) GenerateRefreshToken()
    {
        var expiresAt = DateTimeOffset.UtcNow.AddDays(_options.RefreshTokenDays);
        var token = Convert.ToBase64String(RandomNumberGenerator.GetBytes(64));
        return (token, expiresAt);
    }
}
