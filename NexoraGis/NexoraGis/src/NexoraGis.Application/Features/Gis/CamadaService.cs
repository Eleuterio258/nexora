using Microsoft.EntityFrameworkCore;
using NexoraGis.Application.Common;
using NexoraGis.Domain.Common;
using NexoraGis.Domain.Entities.Gis;
using NexoraGis.Domain.Entities.Territorial;
using NexoraGis.Domain.Enums;
using NexoraGis.Domain.Repositories;

namespace NexoraGis.Application.Features.Gis;

public class CamadaService(
    IRepository<Camada> camadas, IRepository<Projeto> projetos, IGeoServerPublisher geoServer, IUnitOfWork unitOfWork)
{
    private static readonly TipoCamada[] DroneProductTypes = [TipoCamada.Ortofoto, TipoCamada.ModeloTerreno, TipoCamada.Pontos];

    public async Task<Result<CamadaDto>> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        var camada = await camadas.GetByIdAsync(id, ct);
        return camada is null ? Result.Failure<CamadaDto>(NotFound(id)) : ToDto(camada);
    }

    public async Task<PagedResult<CamadaDto>> ListAsync(Guid? projetoId, TipoCamada? tipo, int page, int pageSize, CancellationToken ct = default)
    {
        page = page < 1 ? 1 : page;
        pageSize = pageSize is < 1 or > 200 ? 50 : pageSize;

        var query = camadas.Query();
        if (projetoId is not null) query = query.Where(c => c.ProjetoId == projetoId);
        if (tipo is not null) query = query.Where(c => c.Tipo == tipo);

        var totalCount = await query.CountAsync(ct);
        var items = await query.OrderByDescending(c => c.CreatedAt).Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(ct);

        return new PagedResult<CamadaDto>(items.Select(ToDto).ToList(), page, pageSize, totalCount);
    }

    public async Task<Result<CamadaDto>> CreateAsync(UpsertCamadaRequest request, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(request.Nome))
            return Result.Failure<CamadaDto>(Error.Validation("Camada.Invalid", "Nome é obrigatório."));

        if (request.ProjetoId is not null && !await projetos.ExistsAsync(request.ProjetoId.Value, ct))
            return Result.Failure<CamadaDto>(Error.Validation("Camada.ProjetoNotFound", "Projeto indicado não existe."));

        var camada = new Camada();
        Apply(camada, request);

        await camadas.AddAsync(camada, ct);
        await unitOfWork.SaveChangesAsync(ct);

        return ToDto(camada);
    }

    /// <summary>Atalho de registo de produtos de drone (§11 / 4.3.3) sobre o catálogo de camadas.</summary>
    public async Task<Result<CamadaDto>> RegisterDroneProductAsync(RegisterDroneProductRequest request, CancellationToken ct = default)
    {
        if (!DroneProductTypes.Contains(request.Tipo))
            return Result.Failure<CamadaDto>(Error.Validation(
                "Camada.InvalidDroneProductType", $"Tipo tem de ser um de: {string.Join(", ", DroneProductTypes)}."));

        return await CreateAsync(new UpsertCamadaRequest(
            request.ProjetoId, request.Nome, request.Tipo, TabelaFonte: null, Estilo: null, Metadados: null,
            ResponsavelId: null, request.Fonte, request.DataAtualizacao, request.SistemaCoordenadas,
            Versao: "1.0", Visivel: true, Publica: false), ct);
    }

    public async Task<Result<CamadaDto>> UpdateAsync(Guid id, UpsertCamadaRequest request, CancellationToken ct = default)
    {
        var camada = await camadas.GetByIdAsync(id, ct);
        if (camada is null)
            return Result.Failure<CamadaDto>(NotFound(id));

        if (string.IsNullOrWhiteSpace(request.Nome))
            return Result.Failure<CamadaDto>(Error.Validation("Camada.Invalid", "Nome é obrigatório."));

        Apply(camada, request);
        camada.UpdatedAt = DateTimeOffset.UtcNow;

        await camadas.UpdateAsync(camada, ct);
        await unitOfWork.SaveChangesAsync(ct);

        return ToDto(camada);
    }

    /// <summary>Publica a camada no GeoServer (backlog 7.1.2) — fica automaticamente disponível via WMS/WFS/WMTS.</summary>
    public async Task<Result<CamadaDto>> PublishAsync(Guid id, string? corHex, CancellationToken ct = default)
    {
        var camada = await camadas.GetByIdAsync(id, ct);
        if (camada is null)
            return Result.Failure<CamadaDto>(NotFound(id));

        if (string.IsNullOrWhiteSpace(camada.TabelaFonte))
            return Result.Failure<CamadaDto>(Error.Validation(
                "Camada.NoTabelaFonte", "A camada não tem tabela de origem definida — não é possível publicar no GeoServer."));

        string sld;
        try
        {
            sld = SldGenerator.SimplePolygonStyle(camada.Nome, string.IsNullOrWhiteSpace(corHex) ? "#3388ff" : corHex);
        }
        catch (ArgumentException ex)
        {
            return Result.Failure<CamadaDto>(Error.Validation("Camada.InvalidCorHex", ex.Message));
        }

        var publishResult = await geoServer.PublishLayerAsync(camada.Nome, camada.TabelaFonte, sld, ct);
        if (publishResult.IsFailure)
            return Result.Failure<CamadaDto>(publishResult.Error);

        camada.Publica = true;
        camada.UpdatedAt = DateTimeOffset.UtcNow;
        await camadas.UpdateAsync(camada, ct);
        await unitOfWork.SaveChangesAsync(ct);

        return ToDto(camada);
    }

    public async Task<Result> DeleteAsync(Guid id, CancellationToken ct = default)
    {
        var camada = await camadas.GetByIdAsync(id, ct);
        if (camada is null)
            return Result.Failure(NotFound(id));

        await camadas.DeleteAsync(camada, ct);
        await unitOfWork.SaveChangesAsync(ct);
        return Result.Success();
    }

    private static void Apply(Camada camada, UpsertCamadaRequest request)
    {
        camada.ProjetoId = request.ProjetoId;
        camada.Nome = request.Nome;
        camada.Tipo = request.Tipo;
        camada.TabelaFonte = request.TabelaFonte;
        camada.Estilo = request.Estilo;
        camada.Metadados = request.Metadados;
        camada.ResponsavelId = request.ResponsavelId;
        camada.Fonte = request.Fonte;
        camada.DataAtualizacao = request.DataAtualizacao;
        if (!string.IsNullOrWhiteSpace(request.SistemaCoordenadas)) camada.SistemaCoordenadas = request.SistemaCoordenadas;
        if (!string.IsNullOrWhiteSpace(request.Versao)) camada.Versao = request.Versao;
        camada.Visivel = request.Visivel;
        camada.Publica = request.Publica;
    }

    private static Error NotFound(Guid id) => Error.NotFound("Camada.NotFound", $"Camada '{id}' não encontrada.");

    private static CamadaDto ToDto(Camada c) => new(
        c.Id, c.ProjetoId, c.Nome, c.Tipo, c.TabelaFonte, c.ColunaGeometria, c.Estilo, c.Metadados, c.ResponsavelId,
        c.Fonte, c.DataAtualizacao, c.SistemaCoordenadas, c.Versao, c.Visivel, c.Publica, c.CreatedAt, c.UpdatedAt);
}
