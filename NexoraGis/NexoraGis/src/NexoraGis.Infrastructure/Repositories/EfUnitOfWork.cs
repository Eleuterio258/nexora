using NexoraGis.Domain.Repositories;
using NexoraGis.Infrastructure.Persistence;

namespace NexoraGis.Infrastructure.Repositories;

public class EfUnitOfWork(AppDbContext dbContext) : IUnitOfWork
{
    public Task<int> SaveChangesAsync(CancellationToken cancellationToken = default) =>
        dbContext.SaveChangesAsync(cancellationToken);
}
