namespace NexoraGis.Application.Features.Plans;

public record PlanoDto(
    Guid Id,
    Guid ProjetoId,
    string Codigo,
    string Designacao,
    string Versao,
    DateOnly? DataAprovacao,
    DateOnly? DataPublicacao,
    bool Ativo,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt);

public record CreatePlanoRequest(Guid ProjetoId, string Codigo, string Designacao, string? Versao);

/// <summary>
/// DataAprovacao/DataPublicacao não entram aqui de propósito — só o workflow
/// de aprovação (AprovacaoService) os escreve, para não haver dois caminhos
/// independentes a decidir se um plano está aprovado/publicado.
/// </summary>
public record UpdatePlanoRequest(string Designacao, bool Ativo);

/// <summary>Cria uma nova versão do plano (mesmo Código/Projeto) e marca a origem como inativa — backlog 5.1.2.</summary>
public record CreatePlanoVersionRequest(string NovaVersao);
