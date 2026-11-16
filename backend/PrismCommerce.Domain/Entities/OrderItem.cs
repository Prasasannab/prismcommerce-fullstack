using PrismCommerce.Domain.Common;
using PrismCommerce.Domain.Exceptions;

namespace PrismCommerce.Domain.Entities;

public class OrderItem : BaseEntity
{
    public Guid OrderId { get; set; }
    public Order? Order { get; set; }

    public Guid ProductVariantId { get; set; }
    public ProductVariant? ProductVariant { get; set; }

    public string ProductName { get; set; } = string.Empty;
    public string VariantTitle { get; set; } = string.Empty;
    public decimal UnitPrice { get; set; }
    public int Quantity { get; set; }
    public decimal TotalPrice { get; set; }

    public OrderItem()
    {
    }

    public OrderItem(
        Guid orderId,
        Guid productVariantId,
        string productName,
        string variantTitle,
        decimal unitPrice,
        int quantity)
    {
        if (orderId == Guid.Empty)
            throw new DomainException("Order ID cannot be empty.");
        if (productVariantId == Guid.Empty)
            throw new DomainException("Product variant ID cannot be empty.");
        if (string.IsNullOrWhiteSpace(productName))
            throw new DomainException("Product name cannot be empty.");
        if (unitPrice < 0)
            throw new DomainException("Unit price cannot be negative.");
        if (quantity <= 0)
            throw new DomainException("Quantity must be greater than zero.");

        OrderId = orderId;
        ProductVariantId = productVariantId;
        ProductName = productName.Trim();
        VariantTitle = variantTitle.Trim();
        UnitPrice = unitPrice;
        Quantity = quantity;
        TotalPrice = unitPrice * quantity;
    }
}
