using NexoraGis.Api.Authorization;
using NexoraGis.Api.Common;
using NexoraGis.Application.Features.Projects;
using NexoraGis.Domain.Enums;

namespace NexoraGis.Api.Endpoints;

public static class ProjectEndpoints
{
    public static void MapProjectEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/v1/projects")
            .WithTags("Projects")
            .RequireAuthorization();

        group.MapGet("/", async (
                ProjectStatus? status, Guid? divisaoAdministrativaId, string? tipo,
                ProjetoService service, CancellationToken ct,
                int page = 0, int pageSize = 0) =>
            {
                var result = await service.ListAsync(status, divisaoAdministrativaId, tipo,
                    page == 0 ? 1 : page, pageSize == 0 ? 50 : pageSize, ct);
                return Results.Ok(result);
            })
            .RequirePermission("projects", "read");

        group.MapGet("/{id:guid}", async (Guid id, ProjetoService service, CancellationToken ct) =>
                (await service.GetByIdAsync(id, ct)).ToHttpResult())
            .RequirePermission("projects", "read");

        group.MapPost("/", async (CreateProjetoRequest request, ProjetoService service, CancellationToken ct) =>
            {
                var result = await service.CreateAsync(request, ct);
                return result.IsSuccess
                    ? Results.Created($"/api/v1/projects/{result.Value.Id}", result.Value)
                    : result.ToHttpResult();
            })
            .RequirePermission("projects", "create");

        group.MapPut("/{id:guid}", async (Guid id, UpdateProjetoRequest request, ProjetoService service, CancellationToken ct) =>
                (await service.UpdateAsync(id, request, ct)).ToHttpResult())
            .RequirePermission("projects", "update");

        group.MapPost("/{id:guid}/status", async (Guid id, ChangeProjetoStatusRequest request, ProjetoService service, CancellationToken ct) =>
                (await service.ChangeStatusAsync(id, request, ct)).ToHttpResult())
            .RequirePermission("projects", "update");

        group.MapGet("/{id:guid}/team", async (Guid id, ProjetoService service, CancellationToken ct) =>
                (await service.ListTeamAsync(id, ct)).ToHttpResult())
            .RequirePermission("projects", "read");

        group.MapPost("/{id:guid}/team", async (Guid id, AddTeamMemberRequest request, ProjetoService service, CancellationToken ct) =>
                (await service.AddTeamMemberAsync(id, request, ct)).ToHttpResult())
            .RequirePermission("projects", "update");

        group.MapDelete("/{id:guid}/team/{utilizadorId:guid}", async (Guid id, Guid utilizadorId, ProjetoService service, CancellationToken ct) =>
                (await service.RemoveTeamMemberAsync(id, utilizadorId, ct)).ToHttpResult())
            .RequirePermission("projects", "update");
    }
}
