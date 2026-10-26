import 'package:example_app/core/core.dart';

/// Runs the action directly, for repository tests that mock the datasources.
class PassThroughRunner implements LocalTransactionRunner {
  @override
  Future<T> run<T>(Future<T> Function() action) => action();
}
