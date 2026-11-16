using MediatR;
using PrismCommerce.Application.DTOs;

namespace PrismCommerce.Application.Features.Orders.GetMyOrders;

public record GetMyOrdersQuery(Guid UserId) : IRequest<List<OrderResponseDto>>;
