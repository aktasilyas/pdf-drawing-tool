import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:example_app/core/bootstrap/app_bootstrap.dart';
import 'package:example_app/core/bootstrap/startup_gate.dart';
import 'package:example_app/core/crash_reporting/noop_crash_reporter.dart';

const _title = 'Uygulama başlatılamadı';
const _retry = 'Tekrar dene';
const _library = 'Kitaplık (stub)';

Widget _stubApp(AppBootstrapResult _) => const MaterialApp(
      home: Scaffold(body: Text(_library)),
    );

Future<AppBootstrapResult> _okResult() async {
  SharedPreferences.setMockInitialValues({});
  return AppBootstrapResult(
    prefs: await SharedPreferences.getInstance(),
    crashReporter: const NoopCrashReporter(),
  );
}

StartupFailure _failure() =>
    StartupFailure(StateError('database is locked'), StackTrace.empty);

void main() {
  // The error screen follows the device locale; pin Turkish for the copy.
  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.localesTestValue = const [Locale('tr')];
    addTearDown(binding.platformDispatcher.clearAllTestValues);
  });

  group('attemptStartup', () {
    test('returns the result on success', () async {
      final result = await _okResult();
      final outcome = await attemptStartup(() async => result);
      expect(outcome, isA<StartupSuccess>());
      expect((outcome as StartupSuccess).result, same(result));
    });

    test('never throws; returns the failure', () async {
      final error = StateError('migration failed');
      final outcome = await attemptStartup(() async => throw error);
      expect(outcome, isA<StartupFailure>());
      expect((outcome as StartupFailure).error, same(error));
    });
  });

  group('StartupGate', () {
    testWidgets('success shows the app', (tester) async {
      final result = await _okResult();
      await tester.pumpWidget(
        StartupGate(
          initial: StartupSuccess(result),
          bootstrap: () async => result,
          appBuilder: _stubApp,
        ),
      );
      expect(find.text(_library), findsOneWidget);
      expect(find.text(_title), findsNothing);
    });

    testWidgets('failure shows the error screen with Retry', (tester) async {
      await tester.pumpWidget(
        StartupGate(
          initial: _failure(),
          bootstrap: () async => throw StateError('unused'),
          appBuilder: _stubApp,
        ),
      );
      expect(find.text(_title), findsOneWidget);
      expect(find.text(_retry), findsOneWidget);
      expect(find.text(_library), findsNothing);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });

    testWidgets('Retry with a succeeding bootstrap shows the app',
        (tester) async {
      final result = await _okResult();
      var calls = 0;
      await tester.pumpWidget(
        StartupGate(
          initial: _failure(),
          bootstrap: () async {
            calls++;
            return result;
          },
          appBuilder: _stubApp,
        ),
      );

      await tester.tap(find.text(_retry));
      await tester.pump();
      await tester.pump();

      expect(calls, 1);
      expect(find.text(_library), findsOneWidget);
      expect(find.text(_title), findsNothing);
    });

    testWidgets('Retry that fails again stays on the error screen',
        (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        StartupGate(
          initial: _failure(),
          bootstrap: () async {
            calls++;
            throw StateError('still locked');
          },
          appBuilder: _stubApp,
        ),
      );

      await tester.tap(find.text(_retry));
      await tester.pump();
      await tester.pump();

      expect(calls, 1);
      expect(find.text(_title), findsOneWidget);
      expect(find.text(_retry), findsOneWidget);
    });

    testWidgets('Retry cannot start two bootstraps at once', (tester) async {
      final pending = Completer<AppBootstrapResult>();
      var calls = 0;
      await tester.pumpWidget(
        StartupGate(
          initial: _failure(),
          bootstrap: () {
            calls++;
            return pending.future;
          },
          appBuilder: _stubApp,
        ),
      );

      final button = find.byType(ElevatedButton);
      await tester.tap(button);
      await tester.pump();
      await tester.tap(button, warnIfMissed: false);
      await tester.pump();

      expect(calls, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      pending.complete(await _okResult());
      await tester.pump();
      await tester.pump();
      expect(find.text(_library), findsOneWidget);
    });
  });
}
