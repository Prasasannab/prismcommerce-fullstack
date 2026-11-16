using System.Security.Claims;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PrismCommerce.Application.DTOs;
using PrismCommerce.Application.Features.Orders.GetMyOrders;
using PrismCommerce.Application.Features.Orders.GetOrderById;
using PrismCommerce.Application.Features.Orders.PlaceOrder;

namespace PrismCommerce.Api.Controllers;

[Authorize]
public class OrdersController : BaseApiController
{
    public OrdersController(ISender mediator) : base(mediator)
    {
    }

    [HttpPost]
    [ProducesResponseType(typeof(OrderResponseDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<OrderResponseDto>> PlaceOrder(
        [FromBody] PlaceOrderRequestDto request,
        CancellationToken cancellationToken)
    {
        var userId = GetCurrentUserId();
        var command = new PlaceOrderCommand(userId, request.ShippingAddress, request.Items);
        var order = await Mediator.Send(command, cancellationToken);

        return CreatedAtAction(nameof(GetOrderById), new { id = order.Id }, order);
    }

    [HttpGet("my-orders")]
    [ProducesResponseType(typeof(List<OrderResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<List<OrderResponseDto>>> GetMyOrders(CancellationToken cancellationToken)
    {
        var userId = GetCurrentUserId();
        var query = new GetMyOrdersQuery(userId);
        var orders = await Mediator.Send(query, cancellationToken);

        return Ok(orders);
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(OrderResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<OrderResponseDto>> GetOrderById(
        Guid id,
        CancellationToken cancellationToken)
    {
        var userId = GetCurrentUserId();
        var isAdmin = IsCurrentUserAdmin();
        var query = new GetOrderByIdQuery(id, userId, isAdmin);
        var order = await Mediator.Send(query, cancellationToken);

        return Ok(order);
    }

    private Guid GetCurrentUserId()
    {
        var idClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? User.FindFirst("sub")?.Value
            ?? User.FindFirst("id")?.Value;

        if (Guid.TryParse(idClaim, out var userId))
        {
            return userId;
        }

        throw new UnauthorizedAccessException("Invalid or missing user ID claim in token.");
    }

    private bool IsCurrentUserAdmin()
    {
        if (User.IsInRole("Admin"))
            return true;

        var roleClaim = User.FindFirst(ClaimTypes.Role)?.Value
            ?? User.FindFirst("role")?.Value;

        return string.Equals(roleClaim, "Admin", StringComparison.OrdinalIgnoreCase);
    }
}
