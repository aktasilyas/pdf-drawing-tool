import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:example_app/core/bootstrap/app_bootstrap.dart';
import 'package:example_app/core/bootstrap/startup_error_app.dart';
import 'package:example_app/core/utils/logger.dart';

/// One startup attempt, e.g. `AppBootstrap.run`.
typedef Bootstrapper = Future<AppBootstrapResult> Function();

/// Result of [attemptStartup].
sealed class StartupOutcome {
  const StartupOutcome();
}

final class StartupSuccess extends StartupOutcome {
  const StartupSuccess(this.result);
  final AppBootstrapResult result;
}

final class StartupFailure extends StartupOutcome {
  const StartupFailure(this.error, this.stackTrace);
  final Object error;
  final StackTrace stackTrace;
}

/// Runs [bootstrap] and never throws: a failure is logged once and returned.
Future<StartupOutcome> attemptStartup(Bootstrapper bootstrap) async {
  try {
    return StartupSuccess(await bootstrap());
  } catch (error, stack) {
    logger.e('App startup failed', error: error, stackTrace: stack);
    return StartupFailure(error, stack);
  }
}

/// Root widget: the app after a successful startup, otherwise a recoverable
/// error screen whose Retry runs [bootstrap] again.
class StartupGate extends StatefulWidget {
  const StartupGate({
    required this.initial,
    required this.bootstrap,
    required this.appBuilder,
    super.key,
  });

  /// Outcome of the first attempt, made before `runApp` so the happy path
  /// keeps the native splash until the app's first frame.
  final StartupOutcome initial;

  /// Called again on every Retry.
  final Bootstrapper bootstrap;

  /// Builds the real app (including its `ProviderScope`).
  final Widget Function(AppBootstrapResult result) appBuilder;

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  late StartupOutcome _outcome = widget.initial;
  bool _retrying = false;

  Future<void> _retry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    final outcome = await attemptStartup(widget.bootstrap);
    if (!mounted) return;
    setState(() {
      _outcome = outcome;
      _retrying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return switch (_outcome) {
      StartupSuccess(:final result) => KeyedSubtree(
          key: const ValueKey('startup-app'),
          child: widget.appBuilder(result),
        ),
      StartupFailure(:final error) => StartupErrorApp(
          key: const ValueKey('startup-error'),
          onRetry: _retrying ? null : _retry,
          retrying: _retrying,
          details: kDebugMode ? '$error' : null,
        ),
    };
  }
}
