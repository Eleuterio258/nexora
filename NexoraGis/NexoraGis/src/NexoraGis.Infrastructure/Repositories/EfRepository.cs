using System.Linq.Expressions;
using Microsoft.EntityFrameworkCore;
using NexoraGis.Domain.Repositories;
using NexoraGis.Infrastructure.Persistence;

namespace NexoraGis.Infrastructure.Repositories;

public class EfRepository<T>(AppDbContext dbContext) : IRepository<T> where T : class
{
    private readonly DbSet<T> _set = dbContext.Set<T>();

    public IQueryable<T> Query() => _set.AsNoTracking();

    public async Task<T?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) =>
        await _set.FindAsync([id], cancellationToken);

    public async Task<IReadOnlyList<T>> GetAllAsync(CancellationToken cancellationToken = default) =>
        await _set.AsNoTracking().ToListAsync(cancellationToken);

    public async Task<IReadOnlyList<T>> FindAsync(Expression<Func<T, bool>> predicate, CancellationToken cancellationToken = default) =>
        await _set.Where(predicate).ToListAsync(cancellationToken);

    public async Task<T> AddAsync(T entity, CancellationToken cancellationToken = default)
    {
        var entry = await _set.AddAsync(entity, cancellationToken);
        return entry.Entity;
    }

    public Task UpdateAsync(T entity, CancellationToken cancellationToken = default)
    {
        if (dbContext.Entry(entity).State == EntityState.Detached)
            _set.Update(entity);

        return Task.CompletedTask;
    }

    public Task DeleteAsync(T entity, CancellationToken cancellationToken = default)
    {
        _set.Remove(entity);
        return Task.CompletedTask;
    }

    public async Task<bool> ExistsAsync(Guid id, CancellationToken cancellationToken = default) =>
        await _set.FindAsync([id], cancellationToken) is not null;
}
