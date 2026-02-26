/// Exception for rate limit errors.
class AIRateLimitException implements Exception {
  final String message;
  final int remaining;
  final DateTime? resetAt;

  AIRateLimitException({
    required this.message,
    this.remaining = 0,
    this.resetAt,
  });

  @override
  String toString() => 'AIRateLimitException: $message';
}

/// Exception for AI provider errors.
class AIProviderException implements Exception {
  final String message;
  AIProviderException(this.message);

  @override
  String toString() => 'AIProviderException: $message';
}
