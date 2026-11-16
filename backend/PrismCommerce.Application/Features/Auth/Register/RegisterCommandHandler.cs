using MediatR;
using Microsoft.EntityFrameworkCore;
using PrismCommerce.Application.Common.Interfaces;
using PrismCommerce.Application.DTOs;
using PrismCommerce.Domain.Entities;
using PrismCommerce.Domain.Enums;
using PrismCommerce.Domain.Exceptions;

namespace PrismCommerce.Application.Features.Auth.Register;

public class RegisterCommandHandler : IRequestHandler<RegisterCommand, AuthResponseDto>
{
    private readonly IApplicationDbContext _context;
    private readonly IPasswordHasher _passwordHasher;
    private readonly IJwtTokenService _jwtTokenService;
    private readonly IDateTimeProvider _dateTimeProvider;

    public RegisterCommandHandler(
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

    public async Task<AuthResponseDto> Handle(RegisterCommand request, CancellationToken cancellationToken)
    {
        var normalizedEmail = request.Email.Trim().ToLowerInvariant();

        var emailExists = await _context.Users
            .AnyAsync(u => u.Email == normalizedEmail, cancellationToken);

        if (emailExists)
        {
            throw new DomainException($"User with email '{request.Email}' already exists.");
        }

        var passwordHash = _passwordHasher.HashPassword(request.Password);
        var user = new User(
            normalizedEmail,
            passwordHash,
            request.FirstName,
            request.LastName,
            UserRole.Customer);

        var refreshToken = _jwtTokenService.GenerateRefreshToken();
        var refreshTokenExpiry = _dateTimeProvider.UtcNow.AddDays(7);
        user.UpdateRefreshToken(refreshToken, refreshTokenExpiry);

        _context.Users.Add(user);
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
