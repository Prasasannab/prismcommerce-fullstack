using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Configuration;

namespace PrismCommerce.Infrastructure.Data;

public class PrismCommerceDbContextFactory : IDesignTimeDbContextFactory<PrismCommerceDbContext>
{
    public PrismCommerceDbContext CreateDbContext(string[] args)
    {
        var basePath = Path.Combine(Directory.GetCurrentDirectory(), "../PrismCommerce.Api");
        if (!Directory.Exists(basePath))
        {
            basePath = Directory.GetCurrentDirectory();
        }

        var configuration = new ConfigurationBuilder()
            .SetBasePath(basePath)
            .AddJsonFile("appsettings.json", optional: true)
            .AddJsonFile("appsettings.Development.json", optional: true)
            .AddEnvironmentVariables()
            .Build();

        var connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? "Host=localhost;Port=5432;Database=prismcommerce_db;Username=prismuser;Password=prismpassword123!";

        var builder = new DbContextOptionsBuilder<PrismCommerceDbContext>();
        builder.UseNpgsql(connectionString, b => b.MigrationsAssembly(typeof(PrismCommerceDbContext).Assembly.FullName));

        return new PrismCommerceDbContext(builder.Options);
    }
}
