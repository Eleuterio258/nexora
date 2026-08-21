using Microsoft.EntityFrameworkCore;
using NexoraGis.Infrastructure.Persistence;

namespace NexoraGis.Api.Endpoints;

public static class HealthEndpoints
{
    public static void MapHealthEndpoints(this IEndpointRouteBuilder app)
    {
        // Liveness: o processo responde. Não toca em dependências.
        app.MapGet("/health", () => Results.Ok(new { status = "ok", service = "NexoraGis.Api" }))
            .WithTags("Health");

        // Readiness: é esta que o HEALTHCHECK do container usa. Sem a ida à base
        // o container ficava "healthy" com a base em baixo e o Traefik continuava
        // a encaminhar tráfego para uma API que só sabia devolver erros.
        app.MapGet("/health/ready", async (AppDbContext db, CancellationToken ct) =>
            {
                var dbOk = await db.Database.CanConnectAsync(ct);
                return dbOk
                    ? Results.Ok(new { status = "ready", service = "NexoraGis.Api", database = "ok" })
                    : Results.Json(new { status = "degraded", service = "NexoraGis.Api", database = "unreachable" }, statusCode: 503);
            })
            .WithTags("Health");
    }
}
