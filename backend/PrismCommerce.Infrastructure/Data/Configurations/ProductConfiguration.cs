using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using PrismCommerce.Domain.Entities;

namespace PrismCommerce.Infrastructure.Data.Configurations;

public class ProductConfiguration : IEntityTypeConfiguration<Product>
{
    public void Configure(EntityTypeBuilder<Product> builder)
    {
        builder.ToTable("Products");

        builder.HasKey(p => p.Id);

        builder.HasIndex(p => p.Slug)
            .IsUnique();

        builder.Property(p => p.Name)
            .HasMaxLength(250)
            .IsRequired();

        builder.Property(p => p.Slug)
            .HasMaxLength(250)
            .IsRequired();

        builder.Property(p => p.Description)
            .HasMaxLength(4000);

        builder.Property(p => p.BasePrice)
            .HasPrecision(18, 2);

        builder.Property(p => p.IsActive)
            .IsRequired();

        builder.HasOne(p => p.Category)
            .WithMany(c => c.Products)
            .HasForeignKey(p => p.CategoryId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
