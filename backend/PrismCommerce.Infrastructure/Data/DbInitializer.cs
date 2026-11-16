using Microsoft.EntityFrameworkCore;
using PrismCommerce.Application.Common.Interfaces;
using PrismCommerce.Domain.Entities;
using PrismCommerce.Domain.Enums;

namespace PrismCommerce.Infrastructure.Data;

public static class DbInitializer
{
    public static async Task SeedAsync(PrismCommerceDbContext context, IPasswordHasher passwordHasher)
    {
        ArgumentNullException.ThrowIfNull(context);
        ArgumentNullException.ThrowIfNull(passwordHasher);

        // 1. Seed Users
        if (!await context.Users.AnyAsync())
        {
            var adminUser = new User(
                email: "admin@prismcommerce.com",
                passwordHash: passwordHasher.HashPassword("Admin123!"),
                firstName: "Admin",
                lastName: "User",
                role: UserRole.Admin);

            var customerUser = new User(
                email: "customer@prismcommerce.com",
                passwordHash: passwordHasher.HashPassword("Customer123!"),
                firstName: "Demo",
                lastName: "Customer",
                role: UserRole.Customer);

            await context.Users.AddRangeAsync(adminUser, customerUser);
            await context.SaveChangesAsync();
        }

        // 2. Seed Categories
        var categoriesMap = new Dictionary<string, Category>();

        var categoryDefinitions = new List<(string Name, string Slug, string Desc, string Img)>
        {
            ("Audio", "audio", "High-fidelity headphones, earbuds, DACs, and studio audio gear.", "https://images.unsplash.com/photo-1546435770-a3e426bf472b"),
            ("Laptops", "laptops", "High-performance laptops, workstations, and ultraportable notebooks.", "https://images.unsplash.com/photo-1517336714731-489689fd1ca8"),
            ("Wearables", "wearables", "Smartwatches, fitness bands, smart rings, and connected health trackers.", "https://images.unsplash.com/photo-1523275335684-37898b6baf30"),
            ("Phones & Tablets", "phones-tablets", "Flagship 5G smartphones, creator tablets, and foldable mobile devices.", "https://images.unsplash.com/photo-1511707171634-5f897ff02aa9"),
            ("Gaming & VR", "gaming-vr", "Next-gen VR headsets, mechanical keyboards, gaming mice, and streaming controllers.", "https://images.unsplash.com/photo-1550745165-9bc0b252726f"),
            ("Accessories & Gear", "accessories", "GaN chargers, magnetic power banks, Thunderbolt docks, and EDC tech pouches.", "https://images.unsplash.com/photo-1588872657578-7efd1f1555ed")
        };

        foreach (var def in categoryDefinitions)
        {
            var existing = await context.Categories.FirstOrDefaultAsync(c => c.Slug == def.Slug);
            if (existing == null)
            {
                existing = new Category(def.Name, def.Slug, def.Desc, def.Img);
                await context.Categories.AddAsync(existing);
                await context.SaveChangesAsync();
            }
            categoriesMap[def.Slug] = existing;
        }

        // 3. Check if 100+ Products exist
        var existingCount = await context.Products.CountAsync();
        if (existingCount >= 100)
        {
            return;
        }

        // If less than 100, add the comprehensive catalog
        var productsToSeed = CatalogSeedData.GetProducts(categoriesMap);
        foreach (var prod in productsToSeed)
        {
            if (!await context.Products.AnyAsync(p => p.Slug == prod.Slug))
            {
                await context.Products.AddAsync(prod);
            }
        }

        await context.SaveChangesAsync();
    }
}
