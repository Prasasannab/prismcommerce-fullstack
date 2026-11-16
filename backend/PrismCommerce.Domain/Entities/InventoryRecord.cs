using PrismCommerce.Domain.Common;
using PrismCommerce.Domain.Exceptions;

namespace PrismCommerce.Domain.Entities;

public class InventoryRecord : BaseEntity
{
    public Guid ProductVariantId { get; set; }
    public ProductVariant? ProductVariant { get; set; }

    public int StockQuantity { get; set; }
    public int ReservedQuantity { get; set; }

    /// <summary>
    /// Concurrency token for PostgreSQL xmin / optimistic locking.
    /// </summary>
    public uint RowVersion { get; set; }

    public int AvailableStock => StockQuantity - ReservedQuantity;

    public InventoryRecord()
    {
    }

    public InventoryRecord(Guid productVariantId, int initialStock)
    {
        if (productVariantId == Guid.Empty)
            throw new DomainException("Product variant ID cannot be empty.");
        if (initialStock < 0)
            throw new DomainException("Initial stock quantity cannot be negative.");

        ProductVariantId = productVariantId;
        StockQuantity = initialStock;
        ReservedQuantity = 0;
    }

    public void ReserveStock(int quantity)
    {
        if (quantity <= 0)
            throw new DomainException("Quantity to reserve must be greater than zero.");
        if (quantity > AvailableStock)
            throw new DomainException($"Cannot reserve {quantity} units. Only {AvailableStock} units available.");

        ReservedQuantity += quantity;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void ReleaseReservation(int quantity)
    {
        if (quantity <= 0)
            throw new DomainException("Quantity to release must be greater than zero.");
        if (quantity > ReservedQuantity)
            throw new DomainException($"Cannot release {quantity} reserved units. Only {ReservedQuantity} units are currently reserved.");

        ReservedQuantity -= quantity;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void DeductStock(int quantity)
    {
        if (quantity <= 0)
            throw new DomainException("Quantity to deduct must be greater than zero.");

        if (ReservedQuantity >= quantity)
        {
            ReservedQuantity -= quantity;
            StockQuantity -= quantity;
        }
        else
        {
            if (AvailableStock < quantity && StockQuantity < quantity)
                throw new DomainException($"Insufficient stock to deduct {quantity} units. Current stock is {StockQuantity}, available is {AvailableStock}.");

            ReservedQuantity = Math.Max(0, ReservedQuantity - quantity);
            StockQuantity -= quantity;
        }

        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void Restock(int quantity)
    {
        if (quantity <= 0)
            throw new DomainException("Quantity to restock must be greater than zero.");

        StockQuantity += quantity;
        UpdatedAt = DateTimeOffset.UtcNow;
    }
}
