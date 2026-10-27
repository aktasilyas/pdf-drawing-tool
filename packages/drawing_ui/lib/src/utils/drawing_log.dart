import 'dart:developer' as developer;

/// Severity of a [DrawingLog] message.
enum DrawingLogLevel { debug, info, warning, error }

/// Receives every message logged through [DrawingLog].
typedef DrawingLogSink = void Function(
  DrawingLogLevel level,
  String message,
  Object? error,
  StackTrace? stackTrace,
);

/// Tiny logging facade for drawing_ui.
///
/// Defaults to `dart:developer` `log()`; the host app can route messages to
/// its own logger by replacing [sink] at startup.
class DrawingLog {
  DrawingLog._();

  /// Destination for all messages. Reset with `DrawingLog.sink = null`.
  static DrawingLogSink get sink => _sink ?? _defaultSink;
  static set sink(DrawingLogSink? value) => _sink = value;
  static DrawingLogSink? _sink;

  static void d(String message, [Object? error, StackTrace? stackTrace]) =>
      sink(DrawingLogLevel.debug, message, error, stackTrace);

  static void i(String message, [Object? error, StackTrace? stackTrace]) =>
      sink(DrawingLogLevel.info, message, error, stackTrace);

  static void w(String message, [Object? error, StackTrace? stackTrace]) =>
      sink(DrawingLogLevel.warning, message, error, stackTrace);

  static void e(String message, [Object? error, StackTrace? stackTrace]) =>
      sink(DrawingLogLevel.error, message, error, stackTrace);

  static void _defaultSink(
    DrawingLogLevel level,
    String message,
    Object? error,
    StackTrace? stackTrace,
  ) {
    developer.log(
      message,
      name: 'drawing_ui',
      level: switch (level) {
        DrawingLogLevel.debug => 500,
        DrawingLogLevel.info => 800,
        DrawingLogLevel.warning => 900,
        DrawingLogLevel.error => 1000,
      },
      error: error,
      stackTrace: stackTrace,
    );
  }
}
