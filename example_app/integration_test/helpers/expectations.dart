import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fails when a widget failed to build: Flutter swaps it for an
/// [ErrorWidget] (red box in debug) and the app keeps running.
void expectNoErrorWidgets(String where) {
  expect(
    find.byType(ErrorWidget),
    findsNothing,
    reason: 'a widget failed to build on: $where',
  );
}
