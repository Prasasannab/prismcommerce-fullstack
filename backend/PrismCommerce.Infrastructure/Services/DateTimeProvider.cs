using PrismCommerce.Application.Common.Interfaces;

namespace PrismCommerce.Infrastructure.Services;

public class DateTimeProvider : IDateTimeProvider
{
    public DateTimeOffset UtcNow => DateTimeOffset.UtcNow;
}
