using NexoraGis.Application.Features.Surveys;

namespace NexoraGis.Api.Workers;

/// <summary>
/// Processa a fila de sincronização em segundo plano (backlog 4.2.4), para
/// que lotes grandes submetidos pelo dispositivo de campo não bloqueiem o
/// pedido HTTP. Corre num scope de DI próprio por iteração, já que
/// <see cref="SyncService"/> e o <c>AppDbContext</c> são scoped.
/// </summary>
public class SyncQueueWorker(IServiceScopeFactory scopeFactory, ILogger<SyncQueueWorker> logger) : BackgroundService
{
    private static readonly TimeSpan PollInterval = TimeSpan.FromSeconds(5);

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        using var timer = new PeriodicTimer(PollInterval);

        do
        {
            try
            {
                bool processedAny;
                do
                {
                    using var scope = scopeFactory.CreateScope();
                    var syncService = scope.ServiceProvider.GetRequiredService<SyncService>();
                    processedAny = await syncService.ProcessNextPendingJobAsync(stoppingToken);
                }
                while (processedAny && !stoppingToken.IsCancellationRequested);
            }
            catch (Exception ex) when (!stoppingToken.IsCancellationRequested)
            {
                logger.LogError(ex, "Erro ao processar a fila de sincronização.");
            }
        }
        while (await timer.WaitForNextTickAsync(stoppingToken));
    }
}
