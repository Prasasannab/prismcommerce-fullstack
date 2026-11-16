using System.Text.Json;
using Microsoft.AspNetCore.Mvc;
using PrismCommerce.Application.Common.Exceptions;
using PrismCommerce.Domain.Exceptions;

namespace PrismCommerce.Api.Middlewares;

public class ExceptionHandlingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionHandlingMiddleware> _logger;

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        DictionaryKeyPolicy = JsonNamingPolicy.CamelCase
    };

    public ExceptionHandlingMiddleware(RequestDelegate next, ILogger<ExceptionHandlingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (ValidationException ex)
        {
            await HandleValidationExceptionAsync(context, ex);
        }
        catch (EntityNotFoundException ex)
        {
            await HandleEntityNotFoundExceptionAsync(context, ex);
        }
        catch (DomainException ex)
        {
            await HandleDomainExceptionAsync(context, ex);
        }
        catch (UnauthorizedAccessException ex)
        {
            await HandleUnauthorizedAccessExceptionAsync(context, ex);
        }
        catch (Stripe.StripeException ex)
        {
            await HandleStripeExceptionAsync(context, ex);
        }
        catch (Exception ex)
        {
            await HandleUnhandledExceptionAsync(context, ex);
        }
    }

    private static Task HandleStripeExceptionAsync(HttpContext context, Stripe.StripeException ex)
    {
        var problemDetails = new ProblemDetails
        {
            Status = StatusCodes.Status400BadRequest,
            Title = "Invalid Stripe Webhook Request",
            Type = "https://datatracker.ietf.org/doc/html/rfc7231#section-6.5.1",
            Detail = ex.Message,
            Instance = context.Request.Path
        };

        return WriteProblemDetailsAsync(context, problemDetails, StatusCodes.Status400BadRequest);
    }

    private static Task HandleValidationExceptionAsync(HttpContext context, ValidationException ex)
    {
        var problemDetails = new ProblemDetails
        {
            Status = StatusCodes.Status400BadRequest,
            Title = "Validation Failed",
            Type = "https://datatracker.ietf.org/doc/html/rfc7231#section-6.5.1",
            Detail = "One or more validation failures have occurred.",
            Instance = context.Request.Path
        };

        problemDetails.Extensions["errors"] = ex.Errors;

        return WriteProblemDetailsAsync(context, problemDetails, StatusCodes.Status400BadRequest);
    }

    private static Task HandleEntityNotFoundExceptionAsync(HttpContext context, EntityNotFoundException ex)
    {
        var problemDetails = new ProblemDetails
        {
            Status = StatusCodes.Status404NotFound,
            Title = "Resource Not Found",
            Type = "https://datatracker.ietf.org/doc/html/rfc7231#section-6.5.4",
            Detail = ex.Message,
            Instance = context.Request.Path
        };

        return WriteProblemDetailsAsync(context, problemDetails, StatusCodes.Status404NotFound);
    }

    private static Task HandleDomainExceptionAsync(HttpContext context, DomainException ex)
    {
        var problemDetails = new ProblemDetails
        {
            Status = StatusCodes.Status400BadRequest,
            Title = "Domain Rule Violation",
            Type = "https://datatracker.ietf.org/doc/html/rfc7231#section-6.5.1",
            Detail = ex.Message,
            Instance = context.Request.Path
        };

        return WriteProblemDetailsAsync(context, problemDetails, StatusCodes.Status400BadRequest);
    }

    private static Task HandleUnauthorizedAccessExceptionAsync(HttpContext context, UnauthorizedAccessException ex)
    {
        var problemDetails = new ProblemDetails
        {
            Status = StatusCodes.Status401Unauthorized,
            Title = "Unauthorized",
            Type = "https://datatracker.ietf.org/doc/html/rfc7235#section-3.1",
            Detail = ex.Message,
            Instance = context.Request.Path
        };

        return WriteProblemDetailsAsync(context, problemDetails, StatusCodes.Status401Unauthorized);
    }

    private Task HandleUnhandledExceptionAsync(HttpContext context, Exception ex)
    {
        _logger.LogError(ex, "An unhandled exception occurred while processing request {Path}", context.Request.Path);

        var problemDetails = new ProblemDetails
        {
            Status = StatusCodes.Status500InternalServerError,
            Title = "Internal Server Error",
            Type = "https://datatracker.ietf.org/doc/html/rfc7231#section-6.6.1",
            Detail = "An unexpected error occurred. Please try again later.",
            Instance = context.Request.Path
        };

        return WriteProblemDetailsAsync(context, problemDetails, StatusCodes.Status500InternalServerError);
    }

    private static async Task WriteProblemDetailsAsync(HttpContext context, ProblemDetails problemDetails, int statusCode)
    {
        context.Response.StatusCode = statusCode;
        context.Response.ContentType = "application/problem+json";

        await JsonSerializer.SerializeAsync(context.Response.Body, problemDetails, JsonOptions);
    }
}
