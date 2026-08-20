namespace NexoraGis.Api.Endpoints;

public static class HealthEndpoints
{
    public static void MapHealthEndpoints(this IEndpointRouteBuilder app)
    {
        app.MapGet("/health", () => Results.Ok(new { status = "ok", service = "NexoraGis.Api" }))
            .WithTags("Health");
    }
}
