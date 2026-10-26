import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:example_app/core/crash_reporting/firebase_crash_reporter.dart';

class _MockCrashlytics extends Mock implements FirebaseCrashlytics {}

void main() {
  late _MockCrashlytics crashlytics;
  late FirebaseCrashReporter reporter;

  setUpAll(() {
    registerFallbackValue(Object());
  });

  setUp(() {
    crashlytics = _MockCrashlytics();
    reporter = FirebaseCrashReporter(crashlytics);
    when(
      () => crashlytics.recordError(
        any<dynamic>(),
        any(),
        printDetails: any(named: 'printDetails'),
        fatal: any(named: 'fatal'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => crashlytics.recordError(
        any<dynamic>(),
        any(),
        reason: any<dynamic>(named: 'reason'),
        printDetails: any(named: 'printDetails'),
      ),
    ).thenAnswer((_) async {});
    when(() => crashlytics.setCrashlyticsCollectionEnabled(any()))
        .thenAnswer((_) async {});
    when(() => crashlytics.deleteUnsentReports()).thenAnswer((_) async {});
  });

  test('isActive is true', () {
    expect(reporter.isActive, isTrue);
  });

  test('recordError sends a scrubbed error and stack, passes fatal', () async {
    const error = FormatException('bad /data/user/0/app/files/a.pdf');
    final stack = StackTrace.fromString(
      '#0 f (file:///data/user/0/app/a.dart:1:1)\n'
      '#1 g (package:example_app/g.dart:2:2)',
    );

    await reporter.recordError(error, stack, fatal: true);

    final captured = verify(
      () => crashlytics.recordError(
        captureAny<dynamic>(),
        captureAny(),
        printDetails: false,
        fatal: true,
      ),
    ).captured;
    final sent = captured[0] as ScrubbedError;
    expect(sent.type, 'FormatException');
    expect(sent.toString(), isNot(contains('/data/user')));
    expect(sent.toString(), contains('<path>'));
    final sentStack = captured[1] as StackTrace;
    expect(sentStack.toString(), isNot(contains('/data/user')));
    expect(sentStack.toString(), contains('package:example_app/g.dart'));
  });

  test('recordError defaults to non-fatal and accepts a null stack', () async {
    await reporter.recordError(StateError('x'), null);

    verify(
      () => crashlytics.recordError(
        any<dynamic>(),
        null,
        printDetails: false,
        fatal: false,
      ),
    ).called(1);
  });

  test('recordFlutterError sends scrubbed data without information', () async {
    final details = FlutterErrorDetails(
      exception: StateError("no note 'Secret' at /storage/emulated/0/x.pdf"),
      stack: StackTrace.fromString('#0 f (package:example_app/f.dart:1:1)'),
      context: ErrorDescription('while opening /storage/emulated/0/x.pdf'),
      informationCollector: () => [ErrorDescription('private widget info')],
    );

    await reporter.recordFlutterError(details);

    // The stub and verify only match calls without `information`.
    final captured = verify(
      () => crashlytics.recordError(
        captureAny<dynamic>(),
        any(),
        reason: captureAny<dynamic>(named: 'reason'),
        printDetails: false,
      ),
    ).captured;
    final sent = captured[0] as ScrubbedError;
    expect(sent.type, 'StateError');
    expect(sent.toString(), isNot(contains('Secret')));
    expect(sent.toString(), isNot(contains('/storage')));
    expect(captured[1].toString(), isNot(contains('/storage')));
    expect(captured[1].toString(), contains('<path>'));
  });

  test('opting out disables collection then deletes unsent reports', () async {
    await reporter.setCollectionEnabled(false);

    verifyInOrder([
      () => crashlytics.setCrashlyticsCollectionEnabled(false),
      () => crashlytics.deleteUnsentReports(),
    ]);
  });

  test('opting in only enables collection', () async {
    await reporter.setCollectionEnabled(true);

    verify(() => crashlytics.setCrashlyticsCollectionEnabled(true)).called(1);
    verifyNever(() => crashlytics.deleteUnsentReports());
  });

  test('drops errors recorded while opted out', () async {
    await reporter.setCollectionEnabled(false);
    await reporter.recordError(StateError('x'), StackTrace.current);
    await reporter.recordFlutterError(
      FlutterErrorDetails(exception: StateError('y')),
    );

    verifyNever(
      () => crashlytics.recordError(
        any<dynamic>(),
        any(),
        printDetails: any(named: 'printDetails'),
        fatal: any(named: 'fatal'),
      ),
    );
    verifyNever(
      () => crashlytics.recordError(
        any<dynamic>(),
        any(),
        reason: any<dynamic>(named: 'reason'),
        printDetails: any(named: 'printDetails'),
      ),
    );
  });

  test('never sets user identifier, log lines or custom keys', () async {
    await reporter.recordError(StateError('x'), StackTrace.current);
    await reporter.setCollectionEnabled(true);

    verifyNever(() => crashlytics.setUserIdentifier(any()));
    verifyNever(() => crashlytics.log(any()));
    verifyNever(() => crashlytics.setCustomKey(any(), any()));
  });
}
