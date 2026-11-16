using MediatR;
using PrismCommerce.Application.DTOs;

namespace PrismCommerce.Application.Features.Orders.PlaceOrder;

public record PlaceOrderCommand(
    Guid UserId,
    string ShippingAddress,
    List<OrderItemRequestDto> Items) : IRequest<OrderResponseDto>;
