using System.Net;
using NexoraGis.Domain.Entities.Territorial;
using NexoraGis.Domain.Enums;

namespace NexoraGis.Domain.Entities.Audit;

public class AuditLog
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid? UtilizadorId { get; set; }
    public Utilizador? Utilizador { get; set; }
    public string? UtilizadorNome { get; set; }

    public TipoOperacaoAuditoria Operacao { get; set; }
    public string EntidadeTipo { get; set; } = string.Empty;
    public Guid? EntidadeId { get; set; }

    public Guid? ProjetoId { get; set; }
    public Projeto? Projeto { get; set; }

    public string? DadosAnteriores { get; set; }
    public string? DadosNovos { get; set; }
    public IPAddress? IpAddress { get; set; }

    public DateTimeOffset DataHora { get; set; } = DateTimeOffset.UtcNow;
}
