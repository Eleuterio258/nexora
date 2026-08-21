using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Serilog;
using NexoraGis.Api.Authorization;
using NexoraGis.Api.Endpoints;
using NexoraGis.Api.Services;
using NexoraGis.Api.Workers;
using NexoraGis.Application;
using NexoraGis.Application.Common;
using NexoraGis.Infrastructure;
using NexoraGis.Infrastructure.Persistence;
using NexoraGis.Infrastructure.Persistence.Seed;
using NexoraGis.Infrastructure.Services;

var builder = WebApplication.CreateBuilder(args);

builder.Host.UseSerilog((context, services, configuration) => configuration
    .ReadFrom.Configuration(context.Configuration)
    .Enrich.FromLogContext()
    .WriteTo.Console());

builder.Services.AddOpenApi();
builder.Services.AddHttpContextAccessor();

// Em container a API corre em HTTP puro atrás do Traefik. Sem isto o pedido
// chega como http/IP-da-bridge: o UseHttpsRedirection abaixo entraria em ciclo
// de redirect e os logs registariam sempre o IP do proxy. As redes conhecidas
// são limpas porque o Traefik está numa bridge Docker (não é loopback), e a
// lista por omissão só confia em 127.0.0.1.
builder.Services.Configure<ForwardedHeadersOptions>(options =>
{
    options.ForwardedHeaders = ForwardedHeaders.XForwardedFor
                             | ForwardedHeaders.XForwardedProto
                             | ForwardedHeaders.XForwardedHost;

    // Só as redes indicadas podem forjar estes cabeçalhos. A rede `backend` do
    // Docker é partilhada com dezenas de containers, e qualquer um deles fala
    // com a porta 8080 desta API — aceitar X-Forwarded-* de todos deixaria
    // qualquer vizinho falsificar IP de cliente, esquema e host.
    options.KnownIPNetworks.Clear();
    options.KnownProxies.Clear();
    foreach (var network in builder.Configuration.GetValue("ForwardedHeaders:KnownNetworks", "172.16.0.0/12")!
                                   .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
    {
        var parts = network.Split('/');
        options.KnownIPNetworks.Add(new System.Net.IPNetwork(System.Net.IPAddress.Parse(parts[0]), int.Parse(parts[1])));
    }
});

// Sem isto qualquer excepção não tratada sobe até ao Kestrel e o cliente recebe
// uma resposta vazia; com ProblemDetails recebe um corpo RFC 9457 coerente com
// o resto da API.
builder.Services.AddProblemDetails();

builder.Services.ConfigureHttpJsonOptions(options =>
{
    options.SerializerOptions.Converters.Add(new NetTopologySuite.IO.Converters.GeoJsonConverterFactory());
    options.SerializerOptions.Converters.Add(new System.Text.Json.Serialization.JsonStringEnumConverter());
});

builder.Services.AddApplication();
builder.Services.AddInfrastructure(builder.Configuration);

builder.Services.AddScoped<ICurrentUserService, CurrentUserService>();

var jwtSection = builder.Configuration.GetSection(JwtOptions.SectionName);
var jwtOptions = jwtSection.Get<JwtOptions>() ?? new JwtOptions();

builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        // Sem isto, o handler remapeia "sub" para ClaimTypes.NameIdentifier ao
        // validar o token, e ICurrentUserService.UtilizadorId (que procura o
        // claim "sub") fica sempre null.
        options.MapInboundClaims = false;
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = jwtOptions.Issuer,
            ValidateAudience = true,
            ValidAudience = jwtOptions.Audience,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(JwtSigningKeyFactory.GetKeyBytes(jwtOptions.SigningKey)),
            ValidateLifetime = true,
            ClockSkew = TimeSpan.FromSeconds(30)
        };
    });

builder.Services.AddSingleton<IAuthorizationPolicyProvider, PermissionPolicyProvider>();
builder.Services.AddScoped<IAuthorizationHandler, PermissionAuthorizationHandler>();
builder.Services.AddAuthorization();

builder.Services.AddHostedService<SyncQueueWorker>();

var app = builder.Build();

// Fora de Development o schema é aplicado por opção explícita (Database__MigrateOnStartup),
// para o container não mexer numa base gerida à mão sem se pedir.
if (app.Configuration.GetValue("Database:MigrateOnStartup", false))
{
    using var scope = app.Services.CreateScope();
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    await db.Database.MigrateAsync();
}

if (app.Environment.IsDevelopment() || app.Configuration.GetValue("OpenApi:Expose", false))
{
    app.MapOpenApi();
}

if (app.Environment.IsDevelopment())
{
    using var scope = app.Services.CreateScope();
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    var passwordHasher = scope.ServiceProvider.GetRequiredService<IPasswordHasher>();
    await DevDataSeeder.SeedAsync(db, passwordHasher);
}
else
{
    // Só corre se Bootstrap__AdminPassword estiver definida; ver BootstrapSeeder.
    using var scope = app.Services.CreateScope();
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    var passwordHasher = scope.ServiceProvider.GetRequiredService<IPasswordHasher>();
    await BootstrapSeeder.SeedAsync(db, passwordHasher, app.Configuration, app.Logger);
}

app.UseExceptionHandler();
app.UseForwardedHeaders();

// Atrás do Traefik é ele que faz o 80 -> 443; o container só ouve em HTTP e o
// UseHttpsRedirection limitava-se a avisar "Failed to determine the https port"
// a cada health check.
if (!app.Configuration.GetValue("BehindReverseProxy", false))
{
    app.UseHttpsRedirection();
}
app.UseAuthentication();
app.UseAuthorization();

app.MapHealthEndpoints();
app.MapAuthEndpoints();
app.MapAdministrativeDivisionEndpoints();
app.MapProjectEndpoints();
app.MapParcelEndpoints();
app.MapEntityEndpoints();
app.MapInfrastructureEndpoints();
app.MapSurveyEndpoints();
app.MapSyncEndpoints();
app.MapGisEndpoints();
app.MapPlanEndpoints();
app.MapZoneEndpoints();
app.MapConflictEndpoints();
app.MapSpatialEndpoints();
app.MapApprovalEndpoints();
app.MapVersioningEndpoints();
app.MapAuditEndpoints();
app.MapInspectionEndpoints();
app.MapExportEndpoints();
app.MapReportEndpoints();

app.Run();

public partial class Program;
