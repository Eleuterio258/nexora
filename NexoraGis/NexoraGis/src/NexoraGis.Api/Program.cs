using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
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

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();

    using var scope = app.Services.CreateScope();
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    var passwordHasher = scope.ServiceProvider.GetRequiredService<IPasswordHasher>();
    await DevDataSeeder.SeedAsync(db, passwordHasher);
}

app.UseHttpsRedirection();
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
