using System.Security.Claims;
using PrismCommerce.Domain.Entities;

namespace PrismCommerce.Application.Common.Interfaces;

public interface IJwtTokenService
{
    string GenerateAccessToken(User user);
    string GenerateRefreshToken();
    ClaimsPrincipal? GetPrincipalFromExpiredToken(string token);
}
