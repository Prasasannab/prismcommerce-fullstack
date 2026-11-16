using System.Security.Claims;
using MediatR;
using Microsoft.EntityFrameworkCore;
using PrismCommerce.Application.Common.Interfaces;
using PrismCommerce.Application.DTOs;
using PrismCommerce.Domain.Entities;
using PrismCommerce.Domain.Exceptions;

namespace PrismCommerce.Application.Features.Auth.RefreshToken;

public class RefreshTokenCommandHandler : IRequestHandler<RefreshTokenCommand, AuthResponseDto>
{
    private readonly IApplicationDbContext _context;
    private readonly IJwtTokenService _jwtTokenService;
    private readonly IDateTimeProvider _dateTimeProvider;

    public RefreshTokenCommandHandler(
        IApplicationDbContext context,
        IJwtTokenService jwtTokenService,
        IDateTimeProvider dateTimeProvider)
    {
        _context = context;
        _jwtTokenService = jwtTokenService;
        _dateTimeProvider = dateTimeProvider;
    }

    public async Task<AuthResponseDto> Handle(RefreshTokenCommand request, CancellationToken cancellationToken)
    {
        var principal = _jwtTokenService.GetPrincipalFromExpiredToken(request.AccessToken);
        if (principal == null)
        {
            throw new DomainException("Invalid access token.");
        }

        var userIdClaim = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? principal.FindFirst("sub")?.Value
            ?? principal.FindFirst("id")?.Value;

        User? user = null;
        if (Guid.TryParse(userIdClaim, out var userId))
        {
            user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId, cancellationToken);
        }
        else
        {
            var emailClaim = principal.FindFirst(ClaimTypes.Email)?.Value
                ?? principal.FindFirst("email")?.Value;

            if (!string.IsNullOrEmpty(emailClaim))
            {
                var normalizedEmail = emailClaim.Trim().ToLowerInvariant();
                user = await _context.Users.FirstOrDefaultAsync(u => u.Email == normalizedEmail, cancellationToken);
            }
        }

        if (user == null)
        {
            throw new DomainException("User associated with token was not found.");
        }

        if (user.RefreshToken != request.RefreshToken || user.RefreshTokenExpiryUtc <= _dateTimeProvider.UtcNow)
        {
            throw new DomainException("Invalid or expired refresh token.");
        }

        var newRefreshToken = _jwtTokenService.GenerateRefreshToken();
        var refreshTokenExpiry = _dateTimeProvider.UtcNow.AddDays(7);
        user.UpdateRefreshToken(newRefreshToken, refreshTokenExpiry);

        await _context.SaveChangesAsync(cancellationToken);

        var newAccessToken = _jwtTokenService.GenerateAccessToken(user);
        var accessExpiry = _dateTimeProvider.UtcNow.AddMinutes(60);

        var userDto = new UserDto(
            user.Id,
            user.Email,
            user.FirstName,
            user.LastName,
            user.Role.ToString());

        return new AuthResponseDto(newAccessToken, newRefreshToken, accessExpiry, userDto);
    }
}
