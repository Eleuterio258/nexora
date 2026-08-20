namespace NexoraGis.Domain.Entities.Territorial;

public class ProjetoEquipa
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid ProjetoId { get; set; }
    public Projeto Projeto { get; set; } = null!;

    public Guid UtilizadorId { get; set; }
    public Utilizador Utilizador { get; set; } = null!;

    public string? Funcao { get; set; }
    public bool Ativo { get; set; } = true;
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
}
