using NexoraGis.Api.Authorization;
using NexoraGis.Api.Common;
using NexoraGis.Application.Features.Surveys;

namespace NexoraGis.Api.Endpoints;

public static class SurveyEndpoints
{
    public static void MapSurveyEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/v1/surveys")
            .WithTags("Surveys")
            .RequireAuthorization();

        group.MapGet("/", async (
                Guid? projetoId, string? status, LevantamentoService service, CancellationToken ct,
                int page = 0, int pageSize = 0) =>
                Results.Ok(await service.ListAsync(projetoId, status, page == 0 ? 1 : page, pageSize == 0 ? 50 : pageSize, ct)))
            .RequirePermission("surveys", "read");

        group.MapGet("/{id:guid}", async (Guid id, LevantamentoService service, CancellationToken ct) =>
                (await service.GetByIdAsync(id, ct)).ToHttpResult())
            .RequirePermission("surveys", "read");

        group.MapPost("/", async (CreateLevantamentoRequest request, LevantamentoService service, CancellationToken ct) =>
            {
                var result = await service.CreateAsync(request, ct);
                return result.IsSuccess
                    ? Results.Created($"/api/v1/surveys/{result.Value.Id}", result.Value)
                    : result.ToHttpResult();
            })
            .RequirePermission("surveys", "create");

        group.MapPost("/{id:guid}/status", async (Guid id, UpdateLevantamentoStatusRequest request, LevantamentoService service, CancellationToken ct) =>
                (await service.UpdateStatusAsync(id, request, ct)).ToHttpResult())
            .RequirePermission("surveys", "update");

        group.MapGet("/{id:guid}/points", async (Guid id, LevantamentoService service, CancellationToken ct) =>
                (await service.ListPointsAsync(id, ct)).ToHttpResult())
            .RequirePermission("surveys", "read");
    }
}
