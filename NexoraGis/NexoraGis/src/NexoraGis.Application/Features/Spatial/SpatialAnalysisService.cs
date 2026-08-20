using Microsoft.EntityFrameworkCore;
using NexoraGis.Application.Common;
using NexoraGis.Domain.Common;
using NexoraGis.Domain.Entities.Cadastro;
using NexoraGis.Domain.Entities.Gis;
using NexoraGis.Domain.Entities.Territorial;
using NexoraGis.Domain.Entities.Workflow;
using NexoraGis.Domain.Enums;
using NexoraGis.Domain.Repositories;

namespace NexoraGis.Application.Features.Spatial;

/// <summary>
/// Análise espacial de apoio ao ordenamento (backlog 5.3). Ferramentas de
/// medição (5.3.1) e buffers em metros (metade de 5.3.2) ficam fora daqui —
/// pedem cálculo geodésico (ST_Buffer sobre ::geography) que este projeto não
/// expõe ainda via LINQ, e são tipicamente uma ferramenta de WebGIS
/// client-side (§18 do documento funcional). O resto — interseções e
/// estatísticas agregadas — só usa ST_Intersects e colunas de área já
/// calculadas pelo Postgres, por isso fica seguro implementar aqui.
/// </summary>
public class SpatialAnalysisService(
    IRepository<Parcela> parcelas,
    IRepository<Edificacao> edificacoes,
    IRepository<Infraestrutura> infraestruturas,
    IRepository<Zona> zonas,
    IRepository<Conflito> conflitos,
    IRepository<Fiscalizacao> fiscalizacoes,
    IRepository<Aprovacao> aprovacoes,
    IRepository<Projeto> projetos)
{
    /// <summary>Parcelas cuja geometria interseta a geometria indicada — backlog 5.3.3.</summary>
    public async Task<Result<IReadOnlyList<AffectedParcelDto>>> FindAffectedParcelsAsync(AffectedParcelsRequest request, CancellationToken ct = default)
    {
        if (request.ProjetoId is not null && !await projetos.ExistsAsync(request.ProjetoId.Value, ct))
            return Result.Failure<IReadOnlyList<AffectedParcelDto>>(Error.Validation("Spatial.ProjetoNotFound", "Projeto indicado não existe."));

        var query = parcelas.Query().Where(p => p.Geometria.Intersects(request.Geometria));
        if (request.ProjetoId is not null) query = query.Where(p => p.ProjetoId == request.ProjetoId);

        var items = await query
            .Take(500)
            .Select(p => new AffectedParcelDto(p.Id, p.CodigoCadastral))
            .ToListAsync(ct);

        return Result.Success<IReadOnlyList<AffectedParcelDto>>(items);
    }

    /// <summary>Estatísticas territoriais agregadas de um projeto — backlog 5.3.4.</summary>
    public async Task<Result<ProjectStatisticsDto>> GetProjectStatisticsAsync(Guid projetoId, CancellationToken ct = default)
    {
        if (!await projetos.ExistsAsync(projetoId, ct))
            return Result.Failure<ProjectStatisticsDto>(Error.Validation("Spatial.ProjetoNotFound", "Projeto indicado não existe."));

        var parcelasQuery = parcelas.Query().Where(p => p.ProjetoId == projetoId);

        var totalParcelas = await parcelasQuery.CountAsync(ct);
        var areaTotalParcelas = await parcelasQuery.SumAsync(p => p.AreaCalculada, ct) ?? 0m;

        var porSituacao = await parcelasQuery
            .GroupBy(p => p.Situacao)
            .Select(g => new { Chave = g.Key, Total = g.Count() })
            .ToListAsync(ct);

        var porUso = await parcelasQuery
            .Where(p => p.UsoAtual != null)
            .GroupBy(p => p.UsoAtual)
            .Select(g => new { Chave = g.Key, Total = g.Count() })
            .ToListAsync(ct);

        var totalEdificacoes = await edificacoes.Query().CountAsync(e => e.Parcela.ProjetoId == projetoId, ct);
        var areaTotalEdificacoes = await edificacoes.Query()
            .Where(e => e.Parcela.ProjetoId == projetoId)
            .SumAsync(e => e.AreaConstruida, ct) ?? 0m;

        var totalInfraestruturas = await infraestruturas.Query().CountAsync(i => i.ProjetoId == projetoId, ct);

        var totalZonas = await zonas.Query().CountAsync(z => z.Plano.ProjetoId == projetoId, ct);
        var areaTotalZonas = await zonas.Query()
            .Where(z => z.Plano.ProjetoId == projetoId)
            .SumAsync(z => z.AreaCalculada, ct) ?? 0m;

        var conflitosAtivos = await conflitos.Query().CountAsync(c => c.ProjetoId == projetoId && !c.Resolvido, ct);
        var fiscalizacoesAbertas = await fiscalizacoes.Query().CountAsync(f => f.ProjetoId == projetoId && f.Estado != "resolvido", ct);

        var pendentes = new[] { ApprovalStatus.Submetido, ApprovalStatus.EmAnalise, ApprovalStatus.CorrecaoSolicitada };
        var aprovacoesPendentes = await aprovacoes.Query().CountAsync(a => a.ProjetoId == projetoId && pendentes.Contains(a.Status), ct);

        return new ProjectStatisticsDto(
            projetoId, totalParcelas, areaTotalParcelas, totalEdificacoes, areaTotalEdificacoes,
            totalInfraestruturas, totalZonas, areaTotalZonas, conflitosAtivos, fiscalizacoesAbertas, aprovacoesPendentes,
            porSituacao.ToDictionary(x => x.Chave.ToString(), x => x.Total),
            porUso.ToDictionary(x => x.Chave!.ToString()!, x => x.Total));
    }
}
