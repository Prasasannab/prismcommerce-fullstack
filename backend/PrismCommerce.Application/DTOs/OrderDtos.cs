namespace PrismCommerce.Application.DTOs;

public record OrderItemRequestDto(Guid ProductVariantId, int Quantity);

public record PlaceOrderRequestDto(string ShippingAddress, List<OrderItemRequestDto> Items);

public record OrderItemResponseDto(
    Guid Id,
    Guid ProductVariantId,
    string ProductName,
    string VariantTitle,
    string Sku,
    decimal UnitPrice,
    int Quantity,
    decimal TotalPrice);

public record OrderResponseDto(
    Guid Id,
    string OrderNumber,
    Guid UserId,
    string Status,
    string PaymentStatus,
    decimal TotalAmount,
    string ShippingAddress,
    string? StripePaymentIntentId,
    DateTimeOffset CreatedAt,
    List<OrderItemResponseDto> Items,
    string? ClientSecret = null);
