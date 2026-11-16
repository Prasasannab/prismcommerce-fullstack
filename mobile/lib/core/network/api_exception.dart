import 'package:dio/dio.dart';

/// Structured application exception mapped from network and HTTP status codes.
/// Seamlessly decodes ASP.NET Core ProblemDetails error responses.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? title;
  final String? detail;
  final Map<String, List<String>>? validationErrors;
  final dynamic originalData;

  const ApiException({
    required this.message,
    this.statusCode,
    this.title,
    this.detail,
    this.validationErrors,
    this.originalData,
  });

  /// Factory converting any [DioException] into a domain-friendly [ApiException].
  factory ApiException.fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          message: 'Connection timed out. Please check your internet connection.',
          statusCode: 408,
        );

      case DioExceptionType.connectionError:
        return const ApiException(
          message: 'Unable to connect to server. Ensure PrismCommerce backend is running.',
          statusCode: 503,
        );

      case DioExceptionType.badCertificate:
        return const ApiException(
          message: 'Untrusted SSL certificate detected.',
          statusCode: 495,
        );

      case DioExceptionType.cancel:
        return const ApiException(
          message: 'Request was cancelled.',
        );

      case DioExceptionType.badResponse:
        return _handleBadResponse(error.response);

      case DioExceptionType.unknown:
      default:
        return ApiException(
          message: error.message ?? 'An unexpected network error occurred.',
          originalData: error.error,
        );
    }
  }

  /// Handles 4xx and 5xx responses including ASP.NET Core ProblemDetails format.
  static ApiException _handleBadResponse(Response<dynamic>? response) {
    final statusCode = response?.statusCode;
    final data = response?.data;

    String fallbackMessage = 'An unexpected server error occurred.';
    String? title;
    String? detail;
    Map<String, List<String>>? validationErrors;

    if (data is Map) {
      // Decode standard RFC 7807 ProblemDetails from ASP.NET Core
      if (data.containsKey('title') && data['title'] is String) {
        title = data['title'] as String;
      }
      if (data.containsKey('detail') && data['detail'] is String) {
        detail = data['detail'] as String;
      }
      if (data.containsKey('message') && data['message'] is String) {
        fallbackMessage = data['message'] as String;
      }

      // Check for FluentValidation / ASP.NET validation error dictionary
      if (data.containsKey('errors') && data['errors'] is Map) {
        final rawErrors = data['errors'] as Map;
        validationErrors = {};
        rawErrors.forEach((key, value) {
          if (value is List) {
            validationErrors![key.toString()] =
                value.map((e) => e.toString()).toList();
          } else if (value is String) {
            validationErrors![key.toString()] = [value];
          }
        });
      }
    } else if (data is String && data.isNotEmpty) {
      fallbackMessage = data;
    }

    // Determine the most accurate human-readable message
    String finalMessage;
    if (validationErrors != null && validationErrors.isNotEmpty) {
      // Pick first error from validation dictionary for clean toast/snack display
      final firstKey = validationErrors.keys.first;
      final firstErrList = validationErrors[firstKey];
      finalMessage = (firstErrList != null && firstErrList.isNotEmpty)
          ? firstErrList.first
          : (title ?? fallbackMessage);
    } else if (detail != null && detail.isNotEmpty) {
      finalMessage = detail;
    } else if (title != null && title.isNotEmpty) {
      finalMessage = title;
    } else {
      switch (statusCode) {
        case 400:
          finalMessage = 'Invalid request parameters.';
          break;
        case 401:
          finalMessage = 'Session expired or unauthorized. Please sign in again.';
          break;
        case 403:
          finalMessage = 'Access denied. You do not have permission.';
          break;
        case 404:
          finalMessage = 'The requested resource was not found.';
          break;
        case 409:
          finalMessage = 'Conflict detected: An item state has changed.';
          break;
        case 422:
          finalMessage = 'Validation failed for the submitted data.';
          break;
        case 429:
          finalMessage = 'Too many requests. Please slow down and try again.';
          break;
        case 500:
          finalMessage = 'Internal server error. Please try again shortly.';
          break;
        default:
          finalMessage = fallbackMessage;
          break;
      }
    }

    return ApiException(
      message: finalMessage,
      statusCode: statusCode,
      title: title,
      detail: detail,
      validationErrors: validationErrors,
      originalData: data,
    );
  }

  @override
  String toString() => 'ApiException(statusCode: $statusCode, message: $message)';
}
