import 'package:logger/logger.dart';

/// Global logger instance for the application.
/// 
/// Usage:
/// ```dart
/// logger.d('Debug message');
/// logger.i('Info message');
/// logger.w('Warning message');
/// logger.e('Error message', error: e, stackTrace: stackTrace);
/// ```
final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0, // Don't show method count
    errorMethodCount: 8, // Show more stack trace for errors
    lineLength: 120,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.none,
  ),
);
