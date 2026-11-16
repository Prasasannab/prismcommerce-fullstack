using MediatR;
using PrismCommerce.Application.DTOs;

namespace PrismCommerce.Application.Features.Auth.RefreshToken;

public record RefreshTokenCommand(
    string AccessToken,
    string RefreshToken) : IRequest<AuthResponseDto>;
