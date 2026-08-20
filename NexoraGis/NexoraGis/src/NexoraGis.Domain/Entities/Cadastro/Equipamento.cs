using NetTopologySuite.Geometries;
using NexoraGis.Domain.Entities.Territorial;

namespace NexoraGis.Domain.Entities.Cadastro;

public class Equipamento
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid ProjetoId { get; set; }
    public Projeto Projeto { get; set; } = null!;

    /// <summary>Tipo livre: escola, hospital, mercado, esquadra, etc.</summary>
    public string Tipo { get; set; } = string.Empty;
    public string? Codigo { get; set; }
    public string Nome { get; set; } = string.Empty;
    public Point? Geometria { get; set; }
    public string? Morada { get; set; }
    public string? Contacto { get; set; }
    public string? HorarioFuncionamento { get; set; }
    public int? Capacidade { get; set; }
    public string? Atributos { get; set; }
    public bool Ativo { get; set; } = true;

    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.UtcNow;
}
