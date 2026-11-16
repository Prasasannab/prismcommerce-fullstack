using MediatR;
using Microsoft.EntityFrameworkCore;
using PrismCommerce.Application.Common.Interfaces;
using PrismCommerce.Application.DTOs;
using PrismCommerce.Domain.Entities;

namespace PrismCommerce.Application.Features.Orders.GetMyOrders;

public class GetMyOrdersQueryHandler : IRequestHandler<GetMyOrdersQuery, List<OrderResponseDto>>
{
    private readonly IApplicationDbContext _context;

    public GetMyOrdersQueryHandler(IApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<List<OrderResponseDto>> Handle(GetMyOrdersQuery request, CancellationToken cancellationToken)
    {
        var orders = await _context.Orders
            .AsNoTracking()
            .Include(o => o.Items)
                .ThenInclude(i => i.ProductVariant)
            .Where(o => o.UserId == request.UserId)
            .OrderByDescending(o => o.CreatedAt)
            .ToListAsync(cancellationToken);

        return orders.Select(order => new OrderResponseDto(
            order.Id,
            order.OrderNumber,
            order.UserId,
            order.Status.ToString(),
            order.PaymentStatus.ToString(),
            order.TotalAmount,
            order.ShippingAddress,
            order.StripePaymentIntentId,
            order.CreatedAt,
            order.Items.Select(i => new OrderItemResponseDto(
                i.Id,
                i.ProductVariantId,
                i.ProductName,
                i.VariantTitle,
                i.ProductVariant?.Sku ?? string.Empty,
                i.UnitPrice,
                i.Quantity,
                i.TotalPrice
            )).ToList(),
            ClientSecret: null
        )).ToList();
    }
}
