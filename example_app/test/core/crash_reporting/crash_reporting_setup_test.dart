import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:example_app/core/config/app_env.dart';
import 'package:example_app/core/crash_reporting/crash_reporter.dart';
import 'package:example_app/core/crash_reporting/crash_reporting_setup.dart';
import 'package:example_app/core/crash_reporting/noop_crash_reporter.dart';

class _MockReporter extends Mock implements CrashReporter {}

const _fullEnv = AppEnv(
  firebaseApiKey: 'key',
  firebaseAppId: '1:2:android:3',
  firebaseProjectId: 'proj',
  firebaseMessagingSenderId: '2',
);

void main() {
  late _MockReporter reporter;
  late int initCalls;

  setUpAll(() {
    registerFallbackValue(FlutterErrorDetails(exception: Object()));
    registerFallbackValue(Object());
  });

  setUp(() {
    reporter = _MockReporter();
    initCalls = 0;
    when(() => reporter.isActive).thenReturn(true);
    when(() => reporter.setCollectionEnabled(any())).thenAnswer((_) async {});
    when(() => reporter.recordFlutterError(any())).thenAnswer((_) async {});
    when(() => reporter.recordError(any(), any(), fatal: any(named: 'fatal')))
        .thenAnswer((_) async {});
  });

  Future<CrashReporter> select({
    bool isRelease = true,
    AppEnv env = _fullEnv,
    bool userEnabled = true,
    CrashReporterInitializer? init,
  }) {
    Future<CrashReporter> defaultInit(AppEnv _) async {
      initCalls++;
      return reporter;
    }

    return selectCrashReporter(
      isRelease: isRelease,
      env: env,
      userEnabled: userEnabled,
      initFirebase: init ?? defaultInit,
    );
  }

  group('AppEnv.hasFirebaseConfig', () {
    test('false by default and when any value is missing', () {
      expect(const AppEnv().hasFirebaseConfig, isFalse);
      const partial = AppEnv(firebaseApiKey: 'k', firebaseAppId: 'a');
      expect(partial.hasFirebaseConfig, isFalse);
    });

    test('true when all four values are set', () {
      expect(_fullEnv.hasFirebaseConfig, isTrue);
    });
  });

  group('selectCrashReporter', () {
    test('debug build returns no-op and never initializes Firebase', () async {
      final result = await select(isRelease: false);
      expect(result, isA<NoopCrashReporter>());
      expect(initCalls, 0);
    });

    test('release without Firebase config returns no-op', () async {
      final result = await select(env: const AppEnv());
      expect(result, isA<NoopCrashReporter>());
      expect(initCalls, 0);
    });

    test('release with config applies the stored user choice', () async {
      final result = await select(userEnabled: false);
      expect(result, same(reporter));
      expect(initCalls, 1);
      verify(() => reporter.setCollectionEnabled(false)).called(1);
    });

    test('initialization failure falls back to no-op', () async {
      final result = await select(init: (_) async => throw Exception('boom'));
      expect(result, isA<NoopCrashReporter>());
    });

    test('failure while applying the choice falls back to no-op', () async {
      when(() => reporter.setCollectionEnabled(any()))
          .thenThrow(Exception('boom'));
      final result = await select();
      expect(result, isA<NoopCrashReporter>());
    });
  });

  group('installCrashHandlers', () {
    late FlutterExceptionHandler? originalOnError;
    late ErrorCallback? originalPlatformOnError;

    setUp(() {
      originalOnError = FlutterError.onError;
      originalPlatformOnError = PlatformDispatcher.instance.onError;
    });

    tearDown(() {
      FlutterError.onError = originalOnError;
      PlatformDispatcher.instance.onError = originalPlatformOnError;
    });

    test('no-op reporter leaves handlers unchanged', () {
      installCrashHandlers(const NoopCrashReporter());
      expect(FlutterError.onError, same(originalOnError));
      expect(
        PlatformDispatcher.instance.onError,
        same(originalPlatformOnError),
      );
    });

    test('active reporter receives framework and platform errors', () {
      installCrashHandlers(reporter);

      final details = FlutterErrorDetails(exception: StateError('x'));
      final previous = FlutterError.presentError;
      FlutterError.presentError = (_) {};
      addTearDown(() => FlutterError.presentError = previous);
      FlutterError.onError!(details);
      verify(() => reporter.recordFlutterError(details)).called(1);

      final stack = StackTrace.current;
      final handled = PlatformDispatcher.instance.onError!(
        StateError('y'),
        stack,
      );
      expect(handled, isTrue);
      verify(() => reporter.recordError(any(), stack, fatal: true)).called(1);
    });
  });
}
