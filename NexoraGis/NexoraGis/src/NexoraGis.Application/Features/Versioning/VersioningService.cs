using Microsoft.EntityFrameworkCore;
using NexoraGis.Domain.Common;
using NexoraGis.Domain.Entities.Territorial;
using NexoraGis.Domain.Repositories;

namespace NexoraGis.Application.Features.Versioning;

/// <summary>
/// Leitura do histórico de versionamento de geometrias (backlog 6.2.1/6.2.2).
/// A escrita acontece nos services das entidades versionadas (ex:
/// ParcelaService.UpdateAsync) sempre que a geometria muda de facto.
/// </summary>
public class VersioningService(IRepository<GeometriaHistorico> historico)
{
    /// <summary>Todo o histórico de uma entidade, do mais antigo ao mais recente — backlog 6.2.1.</summary>
    public async Task<IReadOnlyList<GeometriaHistoricoDto>> GetHistoryAsync(string entidadeTipo, Guid entidadeId, CancellationToken ct = default)
    {
        var items = await historico.Query()
            .Where(h => h.EntidadeTipo == entidadeTipo && h.EntidadeId == entidadeId)
            .OrderBy(h => h.DataAlteracao).ThenBy(h => h.VersaoNova)
            .ToListAsync(ct);

        return items.Select(ToDto).ToList();
    }

    /// <summary>
    /// Reconstrói a geometria vigente numa data (backlog 6.2.2): a última
    /// alteração registada até essa data, ou a geometria anterior à primeira
    /// alteração se a data pedida for anterior a todo o histórico.
    /// </summary>
    public async Task<GeometryAtDateDto> GetAtDateAsync(string entidadeTipo, Guid entidadeId, DateTimeOffset data, CancellationToken ct = default)
    {
        // Desempate por VersaoNova quando duas alterações têm exactamente o
        // mesmo DataAlteracao — sem isto, a ordem entre elas não é garantida.
        var registos = await historico.Query()
            .Where(h => h.EntidadeTipo == entidadeTipo && h.EntidadeId == entidadeId)
            .OrderBy(h => h.DataAlteracao).ThenBy(h => h.VersaoNova)
            .ToListAsync(ct);

        if (registos.Count == 0)
            return new GeometryAtDateDto(false, data, null, null);

        var ultimaAntesOuNaData = registos.LastOrDefault(h => h.DataAlteracao <= data);
        if (ultimaAntesOuNaData is not null)
            return new GeometryAtDateDto(true, data, ultimaAntesOuNaData.GeometriaNova, ultimaAntesOuNaData.DataAlteracao);

        var primeira = registos[0];
        return new GeometryAtDateDto(true, data, primeira.GeometriaAnterior, null);
    }

    private static GeometriaHistoricoDto ToDto(GeometriaHistorico h) => new(
        h.Id, h.EntidadeTipo, h.EntidadeId, h.ProjetoId, h.GeometriaAnterior, h.GeometriaNova,
        h.UtilizadorId, h.DataAlteracao, h.Motivo, h.VersaoAnterior, h.VersaoNova);
}
