using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;
using PrismCommerce.Application.Common.Interfaces;
using PrismCommerce.Domain.Common;
using PrismCommerce.Domain.Entities;

namespace PrismCommerce.Infrastructure.Data;

public class PrismCommerceDbContext : DbContext, IApplicationDbContext
{
    public PrismCommerceDbContext(DbContextOptions<PrismCommerceDbContext> options)
        : base(options)
    {
    }

    public DbSet<User> Users => Set<User>();
    public DbSet<Category> Categories => Set<Category>();
    public DbSet<Product> Products => Set<Product>();
    public DbSet<ProductVariant> ProductVariants => Set<ProductVariant>();
    public DbSet<InventoryRecord> InventoryRecords => Set<InventoryRecord>();
    public DbSet<Order> Orders => Set<Order>();
    public DbSet<OrderItem> OrderItems => Set<OrderItem>();

    public async Task<IDbContextTransaction> BeginTransactionAsync(CancellationToken cancellationToken = default)
    {
        return await Database.BeginTransactionAsync(cancellationToken);
    }

    public async Task<List<InventoryRecord>> GetInventoryForUpdateAsync(IEnumerable<Guid> productVariantIds, CancellationToken cancellationToken = default)
    {
        var ids = productVariantIds.Distinct().ToArray();
        if (ids.Length == 0) return new List<InventoryRecord>();

        // PostgreSQL pessimistic row-level locking (including system column xmin for concurrency token):
        return await InventoryRecords
            .FromSqlRaw("SELECT *, xmin FROM \"InventoryRecords\" WHERE \"ProductVariantId\" = ANY({0}) FOR UPDATE", ids)
            .ToListAsync(cancellationToken);
    }

    public override async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        foreach (var entry in ChangeTracker.Entries<BaseEntity>())
        {
            if (entry.State == EntityState.Modified)
            {
                entry.Entity.UpdatedAt = DateTimeOffset.UtcNow;
            }
        }

        return await base.SaveChangesAsync(cancellationToken);
    }

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);
        builder.ApplyConfigurationsFromAssembly(typeof(PrismCommerceDbContext).Assembly);
    }
}
