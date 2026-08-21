# Build multi-stage da NexoraGis.Api (.NET 10).
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Restore em camada própria: só os .csproj, para o cache do NuGet sobreviver a
# alterações de código.
COPY src/NexoraGis.Api/NexoraGis.Api.csproj                 src/NexoraGis.Api/
COPY src/NexoraGis.Application/NexoraGis.Application.csproj src/NexoraGis.Application/
COPY src/NexoraGis.Domain/NexoraGis.Domain.csproj           src/NexoraGis.Domain/
COPY src/NexoraGis.Infrastructure/NexoraGis.Infrastructure.csproj src/NexoraGis.Infrastructure/
RUN dotnet restore src/NexoraGis.Api/NexoraGis.Api.csproj

COPY src/ src/
RUN dotnet publish src/NexoraGis.Api/NexoraGis.Api.csproj \
        -c Release -o /app --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
# O QuestPDF (relatórios PDF) assenta em SkiaSharp, que precisa do fontconfig +
# de pelo menos uma fonte instalada; a imagem aspnet não traz nenhum dos dois.
RUN apt-get update \
 && apt-get install -y --no-install-recommends libfontconfig1 fonts-dejavu-core curl \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /app ./

# Ponto de montagem das chaves do Data Protection: criado com o dono certo para
# que o volume nomeado herde essa permissão (o utilizador `app` não é root).
RUN mkdir -p /home/app/.aspnet/DataProtection-Keys \
 && chown -R app:app /home/app

ENV ASPNETCORE_URLS=http://+:8080 \
    DOTNET_gcServer=1
EXPOSE 8080
USER app

HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=5 \
  CMD curl -fsS http://127.0.0.1:8080/health || exit 1

ENTRYPOINT ["dotnet", "NexoraGis.Api.dll"]
