using NexoraGis.Api.Authorization;
using NexoraGis.Api.Common;
using NexoraGis.Application.Features.Parcels;
using NexoraGis.Domain.Enums;

namespace NexoraGis.Api.Endpoints;

public static class ParcelEndpoints
{
    public static void MapParcelEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/v1/parcels")
            .WithTags("Parcels")
            .RequireAuthorization();

        group.MapGet("/", async (
                Guid? projetoId, Guid? divisaoAdministrativaId, SituacaoParcela? situacao, UsoSolo? usoAtual,
                ApprovalStatus? estado, string? codigo,
                ParcelaService service, CancellationToken ct,
                int page = 0, int pageSize = 0) =>
                Results.Ok(await service.ListAsync(projetoId, divisaoAdministrativaId, situacao, usoAtual, estado, codigo,
                    page == 0 ? 1 : page, pageSize == 0 ? 50 : pageSize, ct)))
            .RequirePermission("parcels", "read");

        group.MapPost("/search", async (ParcelaSearchRequest request, ParcelaService service, CancellationToken ct) =>
                Results.Ok(await service.SearchAsync(request, ct)))
            .RequirePermission("parcels", "read");

        group.MapGet("/{id:guid}", async (Guid id, ParcelaService service, CancellationToken ct) =>
                (await service.GetByIdAsync(id, ct)).ToHttpResult())
            .RequirePermission("parcels", "read");

        group.MapPost("/", async (CreateParcelaRequest request, ParcelaService service, CancellationToken ct) =>
            {
                var result = await service.CreateAsync(request, ct);
                return result.IsSuccess
                    ? Results.Created($"/api/v1/parcels/{result.Value.Id}", result.Value)
                    : result.ToHttpResult();
            })
            .RequirePermission("parcels", "create");

        group.MapPut("/{id:guid}", async (Guid id, UpdateParcelaRequest request, ParcelaService service, CancellationToken ct) =>
                (await service.UpdateAsync(id, request, ct)).ToHttpResult())
            .RequirePermission("parcels", "update");

        // Lotes
        group.MapGet("/{parcelaId:guid}/lots", async (Guid parcelaId, LoteService service, CancellationToken ct) =>
                (await service.ListAsync(parcelaId, ct)).ToHttpResult())
            .RequirePermission("parcels", "read");

        group.MapPost("/{parcelaId:guid}/lots", async (Guid parcelaId, CreateLoteRequest request, LoteService service, CancellationToken ct) =>
                (await service.CreateAsync(parcelaId, request, ct)).ToHttpResult())
            .RequirePermission("parcels", "update");

        group.MapDelete("/{parcelaId:guid}/lots/{loteId:guid}", async (Guid parcelaId, Guid loteId, LoteService service, CancellationToken ct) =>
                (await service.DeleteAsync(parcelaId, loteId, ct)).ToHttpResult())
            .RequirePermission("parcels", "update");

        // Edificações
        group.MapGet("/{parcelaId:guid}/buildings", async (Guid parcelaId, EdificacaoService service, CancellationToken ct) =>
                (await service.ListAsync(parcelaId, ct)).ToHttpResult())
            .RequirePermission("parcels", "read");

        group.MapPost("/{parcelaId:guid}/buildings", async (Guid parcelaId, UpsertEdificacaoRequest request, EdificacaoService service, CancellationToken ct) =>
                (await service.CreateAsync(parcelaId, request, ct)).ToHttpResult())
            .RequirePermission("parcels", "update");

        group.MapPut("/{parcelaId:guid}/buildings/{edificacaoId:guid}", async (Guid parcelaId, Guid edificacaoId, UpsertEdificacaoRequest request, EdificacaoService service, CancellationToken ct) =>
                (await service.UpdateAsync(parcelaId, edificacaoId, request, ct)).ToHttpResult())
            .RequirePermission("parcels", "update");

        group.MapDelete("/{parcelaId:guid}/buildings/{edificacaoId:guid}", async (Guid parcelaId, Guid edificacaoId, EdificacaoService service, CancellationToken ct) =>
                (await service.DeleteAsync(parcelaId, edificacaoId, ct)).ToHttpResult())
            .RequirePermission("parcels", "update");

        // Entidades relacionadas
        group.MapGet("/{parcelaId:guid}/entities", async (Guid parcelaId, Application.Features.Entities.EntidadeService service, CancellationToken ct) =>
                (await service.ListForParcelaAsync(parcelaId, ct)).ToHttpResult())
            .RequirePermission("parcels", "read");

        group.MapPost("/{parcelaId:guid}/entities", async (Guid parcelaId, Application.Features.Entities.LinkParcelaEntidadeRequest request, Application.Features.Entities.EntidadeService service, CancellationToken ct) =>
                (await service.LinkAsync(parcelaId, request, ct)).ToHttpResult())
            .RequirePermission("parcels", "update");

        group.MapDelete("/{parcelaId:guid}/entities/{parcelaEntidadeId:guid}", async (Guid parcelaId, Guid parcelaEntidadeId, Application.Features.Entities.EntidadeService service, CancellationToken ct) =>
                (await service.UnlinkAsync(parcelaId, parcelaEntidadeId, ct)).ToHttpResult())
            .RequirePermission("parcels", "update");
    }
}
