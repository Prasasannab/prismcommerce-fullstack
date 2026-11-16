using PrismCommerce.Domain.Common;
using PrismCommerce.Domain.Exceptions;

namespace PrismCommerce.Domain.Entities;

public class ProductVariant : BaseEntity
{
    public Guid ProductId { get; set; }
    public Product? Product { get; set; }

    public string Sku { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string? Color { get; set; }
    public string? Size { get; set; }
    public decimal PriceAdjustment { get; set; }

    public InventoryRecord? Inventory { get; set; }

    public ProductVariant()
    {
    }

    public ProductVariant(
        Guid productId,
        string sku,
        string title,
        string? color = null,
        string? size = null,
        decimal priceAdjustment = 0m)
    {
        if (productId == Guid.Empty)
            throw new DomainException("Product ID cannot be empty.");
        if (string.IsNullOrWhiteSpace(sku))
            throw new DomainException("SKU cannot be empty.");
        if (string.IsNullOrWhiteSpace(title))
            throw new DomainException("Variant title cannot be empty.");

        ProductId = productId;
        Sku = sku.Trim().ToUpperInvariant();
        Title = title.Trim();
        Color = color?.Trim();
        Size = size?.Trim();
        PriceAdjustment = priceAdjustment;
    }
}
