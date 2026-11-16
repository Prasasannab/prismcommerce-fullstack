using MediatR;
using Microsoft.EntityFrameworkCore;
using PrismCommerce.Application.Common.Interfaces;
using PrismCommerce.Application.DTOs;
using PrismCommerce.Domain.Entities;
using PrismCommerce.Domain.Exceptions;

namespace PrismCommerce.Application.Features.Orders.GetOrderById;

public class GetOrderByIdQueryHandler : IRequestHandler<GetOrderByIdQuery, OrderResponseDto>
{
    private readonly IApplicationDbContext _context;

    public GetOrderByIdQueryHandler(IApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<OrderResponseDto> Handle(GetOrderByIdQuery request, CancellationToken cancellationToken)
    {
        var order = await _context.Orders
            .AsNoTracking()
            .Include(o => o.Items)
                .ThenInclude(i => i.ProductVariant)
            .FirstOrDefaultAsync(o => o.Id == request.OrderId, cancellationToken);

        if (order == null)
        {
            throw new EntityNotFoundException(nameof(Order), request.OrderId);
        }

        if (order.UserId != request.UserId && !request.IsAdmin)
        {
            throw new UnauthorizedAccessException("You are not authorized to view this order.");
        }

        var itemResponses = order.Items.Select(i => new OrderItemResponseDto(
            i.Id,
            i.ProductVariantId,
            i.ProductName,
            i.VariantTitle,
            i.ProductVariant?.Sku ?? string.Empty,
            i.UnitPrice,
            i.Quantity,
            i.TotalPrice
        )).ToList();

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
            ClientSecret: null);
    }
}
