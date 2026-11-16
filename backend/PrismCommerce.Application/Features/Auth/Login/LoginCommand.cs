using MediatR;
using PrismCommerce.Application.DTOs;

namespace PrismCommerce.Application.Features.Auth.Login;

public record LoginCommand(
    string Email,
    string Password) : IRequest<AuthResponseDto>;
