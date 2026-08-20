namespace NexoraGis.Domain.Entities.Territorial;

/// <summary>Token de renovação de sessão, associado a um utilizador e revogável.</summary>
public class RefreshToken
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid UtilizadorId { get; set; }
    public Utilizador Utilizador { get; set; } = null!;

    /// <summary>Hash SHA-256 do token — o valor em claro nunca é persistido.</summary>
    public string TokenHash { get; set; } = string.Empty;

    public DateTimeOffset ExpiresAt { get; set; }
    public DateTimeOffset? RevokedAt { get; set; }
    public string? ReplacedByTokenHash { get; set; }

    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;

    public bool IsActive => RevokedAt is null && ExpiresAt > DateTimeOffset.UtcNow;
}
