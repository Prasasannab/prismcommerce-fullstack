using MediatR;
using Microsoft.EntityFrameworkCore;
using PrismCommerce.Application.Common.Interfaces;
using PrismCommerce.Application.DTOs;
using PrismCommerce.Domain.Entities;
using PrismCommerce.Domain.Exceptions;

namespace PrismCommerce.Application.Features.Orders.PlaceOrder;

public class PlaceOrderCommandHandler : IRequestHandler<PlaceOrderCommand, OrderResponseDto>
{
    private readonly IApplicationDbContext _context;
    private readonly ICacheService _cacheService;
    private readonly IPaymentService _paymentService;

    public PlaceOrderCommandHandler(
        IApplicationDbContext context,
        ICacheService cacheService,
        IPaymentService paymentService)
    {
        _context = context;
        _cacheService = cacheService;
        _paymentService = paymentService;
    }

    public async Task<OrderResponseDto> Handle(PlaceOrderCommand request, CancellationToken cancellationToken)
    {
        using var transaction = await _context.BeginTransactionAsync(cancellationToken);

        var variantIds = request.Items
            .Select(i => i.ProductVariantId)
            .Distinct()
            .ToList();

        // 1. Acquire pessimistic row-level lock on inventory records
        var inventoryRecords = await _context.GetInventoryForUpdateAsync(variantIds, cancellationToken);
        var inventoryMap = inventoryRecords.ToDictionary(i => i.ProductVariantId);

        // 2. Load product variants with their parent product
        var variants = await _context.ProductVariants
            .Include(v => v.Product)
            .Where(v => variantIds.Contains(v.Id))
            .ToListAsync(cancellationToken);
        var variantMap = variants.ToDictionary(v => v.Id);

        // 3. Validate existence of all requested variants
        foreach (var item in request.Items)
        {
            if (!variantMap.TryGetValue(item.ProductVariantId, out var variant) || variant.Product == null)
            {
                throw new EntityNotFoundException(nameof(ProductVariant), item.ProductVariantId);
            }

            if (!variant.Product.IsActive)
            {
                throw new DomainException($"Product '{variant.Product.Name}' is currently inactive.");
            }
        }

        // 4. Validate stock availability and reserve inventory
        foreach (var item in request.Items)
        {
            var variant = variantMap[item.ProductVariantId];
            inventoryMap.TryGetValue(item.ProductVariantId, out var inventory);

            if (inventory == null || inventory.AvailableStock < item.Quantity)
            {
                throw new DomainException($"Insufficient stock for variant '{variant.Title}' (SKU: {variant.Sku}). Available: {inventory?.AvailableStock ?? 0}, Requested: {item.Quantity}");
            }

            inventory.ReserveStock(item.Quantity);
        }

        // 5. Instantiate new Order aggregate
        var orderNumber = $"ORD-{DateTime.UtcNow:yyyyMMdd}-{Guid.NewGuid().ToString("N")[..8].ToUpperInvariant()}";
        var order = new Order(orderNumber, request.UserId, request.ShippingAddress);

        // 6. Add order items
        foreach (var item in request.Items)
        {
            var variant = variantMap[item.ProductVariantId];
            var unitPrice = variant.Product!.BasePrice + variant.PriceAdjustment;

            var orderItem = new OrderItem(
                order.Id,
                variant.Id,
                variant.Product.Name,
                variant.Title,
                unitPrice,
                item.Quantity);

            order.AddItem(orderItem);
        }

        order.TotalAmount = order.Items.Sum(i => i.TotalPrice);

        // 7. Create Stripe PaymentIntent
        var paymentResult = await _paymentService.CreatePaymentIntentAsync(
            order.TotalAmount,
            "usd",
            order.OrderNumber,
            new Dictionary<string, string>
            {
                ["OrderId"] = order.Id.ToString(),
                ["UserId"] = order.UserId.ToString()
            },
            cancellationToken);

        order.StripePaymentIntentId = paymentResult.PaymentIntentId;

        _context.Orders.Add(order);
        await _context.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);

        // 8. Invalidate catalog cache since available stock has changed
        await _cacheService.RemoveByPrefixAsync("catalog:products", cancellationToken);

        // 9. Map to OrderResponseDto
        var itemResponses = order.Items.Select(i =>
        {
            variantMap.TryGetValue(i.ProductVariantId, out var v);
            return new OrderItemResponseDto(
                i.Id,
                i.ProductVariantId,
                i.ProductName,
                i.VariantTitle,
                v?.Sku ?? string.Empty,
                i.UnitPrice,
                i.Quantity,
                i.TotalPrice);
        }).ToList();

        return new OrderResponseDto(
            order.Id,
            order.OrderNumber,
            order.UserId,
            order.Status.ToString(),
            order.PaymentStatus.ToString(),
            order.TotalAmount,
            order.ShippingAddress,
            order.StripePaymentIntentId,
            order.CreatedAt,
            itemResponses,
            ClientSecret: paymentResult.ClientSecret);
    }
}
