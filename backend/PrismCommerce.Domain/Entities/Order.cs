using PrismCommerce.Domain.Common;
using PrismCommerce.Domain.Enums;
using PrismCommerce.Domain.Exceptions;

namespace PrismCommerce.Domain.Entities;

public class Order : BaseEntity, IAggregateRoot
{
    public string OrderNumber { get; set; } = string.Empty;
    public Guid UserId { get; set; }
    public User? User { get; set; }

    public OrderStatus Status { get; set; } = OrderStatus.Pending;
    public PaymentStatus PaymentStatus { get; set; } = PaymentStatus.Pending;
    public decimal TotalAmount { get; set; }
    public string? StripePaymentIntentId { get; set; }
    public string ShippingAddress { get; set; } = string.Empty;

    public ICollection<OrderItem> Items { get; set; } = new List<OrderItem>();

    public Order()
    {
    }

    public Order(
        string orderNumber,
        Guid userId,
        string shippingAddress,
        decimal totalAmount = 0m)
    {
        if (string.IsNullOrWhiteSpace(orderNumber))
            throw new DomainException("Order number cannot be empty.");
        if (userId == Guid.Empty)
            throw new DomainException("Valid user ID is required.");
        if (string.IsNullOrWhiteSpace(shippingAddress))
            throw new DomainException("Shipping address cannot be empty.");
        if (totalAmount < 0)
            throw new DomainException("Total amount cannot be negative.");

        OrderNumber = orderNumber.Trim();
        UserId = userId;
        ShippingAddress = shippingAddress.Trim();
        TotalAmount = totalAmount;
        Status = OrderStatus.Pending;
        PaymentStatus = PaymentStatus.Pending;
    }

    public void MarkAsPaid(string paymentIntentId)
    {
        if (string.IsNullOrWhiteSpace(paymentIntentId))
            throw new DomainException("Stripe payment intent ID cannot be empty.");
        if (Status == OrderStatus.Cancelled)
            throw new DomainException("Cannot mark a cancelled order as paid.");
        if (PaymentStatus == PaymentStatus.Succeeded)
            throw new DomainException("Order payment has already succeeded.");

        StripePaymentIntentId = paymentIntentId.Trim();
        PaymentStatus = PaymentStatus.Succeeded;
        Status = OrderStatus.Paid;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void CancelOrder()
    {
        if (Status == OrderStatus.Delivered)
            throw new DomainException("Cannot cancel an order that has already been delivered.");
        if (Status == OrderStatus.Shipped)
            throw new DomainException("Cannot cancel an order that has already been shipped.");
        if (Status == OrderStatus.Cancelled)
            return;

        Status = OrderStatus.Cancelled;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void MarkAsShipped()
    {
        if (Status == OrderStatus.Cancelled)
            throw new DomainException("Cannot ship a cancelled order.");
        if (PaymentStatus != PaymentStatus.Succeeded)
            throw new DomainException("Cannot ship an order that has not been paid.");
        if (Status == OrderStatus.Delivered)
            throw new DomainException("Cannot ship an order that has already been delivered.");

        Status = OrderStatus.Shipped;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void MarkAsDelivered()
    {
        if (Status != OrderStatus.Shipped)
            throw new DomainException("Cannot deliver an order that is not currently shipped.");

        Status = OrderStatus.Delivered;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void AddItem(OrderItem item)
    {
        ArgumentNullException.ThrowIfNull(item);
        Items.Add(item);
        TotalAmount += item.TotalPrice;
        UpdatedAt = DateTimeOffset.UtcNow;
    }
}
