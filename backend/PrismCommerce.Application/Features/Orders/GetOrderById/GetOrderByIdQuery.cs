using MediatR;
using PrismCommerce.Application.DTOs;

namespace PrismCommerce.Application.Features.Orders.GetOrderById;

public record GetOrderByIdQuery(
    Guid OrderId,
    Guid UserId,
    bool IsAdmin) : IRequest<OrderResponseDto>;
