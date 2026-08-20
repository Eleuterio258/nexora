using Microsoft.EntityFrameworkCore;
using NexoraGis.Application.Common;
using NexoraGis.Domain.Common;
using NexoraGis.Domain.Entities.Cadastro;
using NexoraGis.Domain.Entities.Territorial;
using NexoraGis.Domain.Repositories;

namespace NexoraGis.Application.Features.Reports;

/// <summary>
/// Relatórios PDF (backlog 8.2): ficha cadastral de uma parcela (8.2.1) e
/// mapa temático de uso do solo por projecto (8.2.3). Plantas de
/// localização/enquadramento (8.2.2) e relatórios de levantamento/conflitos/
/// evolução (8.2.4) ficam fora — cada um pediria a sua própria composição de
/// dados; preferi dois relatórios bem feitos a quatro superficiais.
/// </summary>
public class ReportService(
    IRepository<Parcela> parcelas,
    IRepository<Projeto> projetos,
    IRepository<DivisaoAdministrativa> divisoes,
    IRepository<ParcelaEntidade> parcelaEntidades,
    IRepository<Edificacao> edificacoes,
    IReportGenerator reportGenerator)
{
    public async Task<Result<byte[]>> GenerateParcelaFichaAsync(Guid parcelaId, CancellationToken ct = default)
    {
        var parcela = await parcelas.GetByIdAsync(parcelaId, ct);
        if (parcela is null)
            return Result.Failure<byte[]>(Error.NotFound("Parcela.NotFound", $"Parcela '{parcelaId}' não encontrada."));

        var projeto = await projetos.GetByIdAsync(parcela.ProjetoId, ct);
        var divisao = parcela.DivisaoAdministrativaId is not null
            ? await divisoes.GetByIdAsync(parcela.DivisaoAdministrativaId.Value, ct)
            : null;

        var entidades = await parcelaEntidades.Query()
            .Where(pe => pe.ParcelaId == parcelaId && pe.Ativo)
            .Include(pe => pe.Entidade)
            .Select(pe => new ParcelaFichaEntidadeDto(pe.Entidade.Nome, pe.TipoRelacao.ToString()))
            .ToListAsync(ct);

        var edificacoesDaParcela = await edificacoes.Query()
            .Where(e => e.ParcelaId == parcelaId)
            .Select(e => new ParcelaFichaEdificacaoDto(e.Codigo, e.AreaConstruida, e.Finalidade == null ? null : e.Finalidade.ToString()))
            .ToListAsync(ct);

        var ficha = new ParcelaFichaDto(
            parcela.CodigoCadastral, parcela.NumeroParcela, parcela.NumeroTalhao,
            projeto?.Designacao ?? "—", divisao?.Nome,
            parcela.Situacao.ToString(), parcela.UsoAtual?.ToString(), parcela.UsoPrevisto?.ToString(),
            parcela.Estado.ToString(), parcela.Versao, parcela.AreaCalculada, parcela.Perimetro, parcela.Geometria,
            entidades, edificacoesDaParcela, DateTimeOffset.UtcNow);

        return reportGenerator.GenerateParcelaFicha(ficha);
    }

    public async Task<Result<byte[]>> GenerateMapaUsoSoloAsync(Guid projetoId, CancellationToken ct = default)
    {
        var projeto = await projetos.GetByIdAsync(projetoId, ct);
        if (projeto is null)
            return Result.Failure<byte[]>(Error.NotFound("Projeto.NotFound", $"Projeto '{projetoId}' não encontrado."));

        var itens = await parcelas.Query()
            .Where(p => p.ProjetoId == projetoId)
            .Select(p => new MapaTematicoParcelaDto(p.CodigoCadastral, p.UsoAtual == null ? "Sem uso definido" : p.UsoAtual.ToString()!, p.Geometria))
            .ToListAsync(ct);

        if (itens.Count == 0)
            return Result.Failure<byte[]>(Error.Validation("MapaTematico.NoParcelas", "O projeto não tem parcelas para desenhar."));

        var mapa = new MapaTematicoDto(projeto.Designacao, "Uso Atual do Solo", itens, DateTimeOffset.UtcNow);

        return reportGenerator.GenerateMapaTematico(mapa);
    }
}
