using PrismCommerce.Domain.Common;
using PrismCommerce.Domain.Enums;
using PrismCommerce.Domain.Exceptions;

namespace PrismCommerce.Domain.Entities;

public class User : BaseEntity, IAggregateRoot
{
    public string Email { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public UserRole Role { get; set; } = UserRole.Customer;
    public string? RefreshToken { get; set; }
    public DateTimeOffset? RefreshTokenExpiryUtc { get; set; }

    public string FullName => $"{FirstName} {LastName}".Trim();

    public User()
    {
    }

    public User(
        string email,
        string passwordHash,
        string firstName,
        string lastName,
        UserRole role = UserRole.Customer)
    {
        if (string.IsNullOrWhiteSpace(email))
            throw new DomainException("Email cannot be empty.");
        if (string.IsNullOrWhiteSpace(passwordHash))
            throw new DomainException("Password hash cannot be empty.");

        Email = email.Trim().ToLowerInvariant();
        PasswordHash = passwordHash;
        FirstName = firstName.Trim();
        LastName = lastName.Trim();
        Role = role;
    }

    public void UpdateRefreshToken(string token, DateTimeOffset expiry)
    {
        if (string.IsNullOrWhiteSpace(token))
            throw new DomainException("Refresh token cannot be empty.");

        RefreshToken = token;
        RefreshTokenExpiryUtc = expiry;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void RevokeRefreshToken()
    {
        RefreshToken = null;
        RefreshTokenExpiryUtc = null;
        UpdatedAt = DateTimeOffset.UtcNow;
    }
}
