using NexoraGis.Domain.Entities.Territorial;
using NexoraGis.Domain.Enums;

namespace NexoraGis.Domain.Entities.Workflow;

/// <summary>
/// Instância do workflow de aprovação para uma entidade (parcela, edificação,
/// plano, ...): Rascunho → Submetido → Em análise → Aprovado/Rejeitado → Publicado.
/// </summary>
public class Aprovacao
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public string EntidadeTipo { get; set; } = string.Empty;
    public Guid EntidadeId { get; set; }

    public Guid ProjetoId { get; set; }
    public Projeto Projeto { get; set; } = null!;

    public ApprovalStatus Status { get; set; } = ApprovalStatus.Rascunho;

    public Guid? RequisitadoPor { get; set; }
    public Utilizador? RequisitadoPorUtilizador { get; set; }

    public Guid? VerificadoPor { get; set; }
    public Utilizador? VerificadoPorUtilizador { get; set; }

    public Guid? AprovadoPor { get; set; }
    public Utilizador? AprovadoPorUtilizador { get; set; }

    public DateTimeOffset? DataSubmissao { get; set; }
    public DateTimeOffset? DataAnalise { get; set; }
    public DateTimeOffset? DataAprovacao { get; set; }
    public DateTimeOffset? DataPublicacao { get; set; }
    public string? MotivoRejeicao { get; set; }
    public string? Observacoes { get; set; }
    public int Versao { get; set; } = 1;

    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.UtcNow;
}
