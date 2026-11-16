using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using PrismCommerce.Domain.Entities;

namespace PrismCommerce.Infrastructure.Data.Configurations;

public class InventoryRecordConfiguration : IEntityTypeConfiguration<InventoryRecord>
{
    public void Configure(EntityTypeBuilder<InventoryRecord> builder)
    {
        builder.ToTable("InventoryRecords");

        builder.HasKey(i => i.Id);

        builder.HasIndex(i => i.ProductVariantId)
            .IsUnique();

        builder.Property(i => i.StockQuantity)
            .IsRequired();

        builder.Property(i => i.ReservedQuantity)
            .IsRequired();

        builder.Ignore(i => i.AvailableStock);

#pragma warning disable CS0618
        builder.UseXminAsConcurrencyToken();
#pragma warning restore CS0618
    }
}
