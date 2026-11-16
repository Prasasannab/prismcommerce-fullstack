using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using PrismCommerce.Domain.Entities;

namespace PrismCommerce.Infrastructure.Data.Configurations;

public class ProductVariantConfiguration : IEntityTypeConfiguration<ProductVariant>
{
    public void Configure(EntityTypeBuilder<ProductVariant> builder)
    {
        builder.ToTable("ProductVariants");

        builder.HasKey(v => v.Id);

        builder.HasIndex(v => v.Sku)
            .IsUnique();

        builder.Property(v => v.Sku)
            .HasMaxLength(100)
            .IsRequired();

        builder.Property(v => v.Title)
            .HasMaxLength(200)
            .IsRequired();

        builder.Property(v => v.Color)
            .HasMaxLength(50);

        builder.Property(v => v.Size)
            .HasMaxLength(50);

        builder.Property(v => v.PriceAdjustment)
            .HasPrecision(18, 2);

        builder.HasOne(v => v.Product)
            .WithMany(p => p.Variants)
            .HasForeignKey(v => v.ProductId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(v => v.Inventory)
            .WithOne(i => i.ProductVariant)
            .HasForeignKey<InventoryRecord>(i => i.ProductVariantId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
