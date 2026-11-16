using MediatR;
using Microsoft.EntityFrameworkCore;
using PrismCommerce.Application.Common.Interfaces;
using PrismCommerce.Application.DTOs;
using PrismCommerce.Domain.Exceptions;

namespace PrismCommerce.Application.Features.Auth.Login;

public class LoginCommandHandler : IRequestHandler<LoginCommand, AuthResponseDto>
{
    private readonly IApplicationDbContext _context;
    private readonly IPasswordHasher _passwordHasher;
    private readonly IJwtTokenService _jwtTokenService;
    private readonly IDateTimeProvider _dateTimeProvider;

    public LoginCommandHandler(
        IApplicationDbContext context,
        IPasswordHasher passwordHasher,
        IJwtTokenService jwtTokenService,
        IDateTimeProvider dateTimeProvider)
    {
        _context = context;
        _passwordHasher = passwordHasher;
        _jwtTokenService = jwtTokenService;
        _dateTimeProvider = dateTimeProvider;
    }

    public async Task<AuthResponseDto> Handle(LoginCommand request, CancellationToken cancellationToken)
    {
        var normalizedEmail = request.Email.Trim().ToLowerInvariant();

        var user = await _context.Users
            .FirstOrDefaultAsync(u => u.Email == normalizedEmail, cancellationToken);

        if (user == null || !_passwordHasher.VerifyPassword(request.Password, user.PasswordHash))
        {
            throw new DomainException("Invalid email or password.");
        }

        var refreshToken = _jwtTokenService.GenerateRefreshToken();
        var refreshTokenExpiry = _dateTimeProvider.UtcNow.AddDays(7);
        user.UpdateRefreshToken(refreshToken, refreshTokenExpiry);

        await _context.SaveChangesAsync(cancellationToken);

        var accessToken = _jwtTokenService.GenerateAccessToken(user);
        var accessExpiry = _dateTimeProvider.UtcNow.AddMinutes(60);

        var userDto = new UserDto(
            user.Id,
            user.Email,
            user.FirstName,
            user.LastName,
            user.Role.ToString());

        return new AuthResponseDto(accessToken, refreshToken, accessExpiry, userDto);
    }
}
