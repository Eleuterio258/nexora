namespace NexoraGis.Domain.Entities.Territorial;

/// <summary>
/// Regra RBAC: (Perfil, Recurso, Acao). Perfil/Recurso/Acao aceitam '*' como
/// wildcard (ex: administrador tem '*'/'*'), por isso ficam como string em vez
/// de enum.
/// </summary>
public class Permissao
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Perfil { get; set; } = string.Empty;
    public string Recurso { get; set; } = string.Empty;
    public string Acao { get; set; } = string.Empty;
    public bool Ativo { get; set; } = true;
}
