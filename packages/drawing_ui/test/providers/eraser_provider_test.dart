import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/src/providers/eraser_provider.dart';
import 'package:drawing_ui/src/providers/drawing_providers.dart';

void main() {
  group('Eraser Providers', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('eraserModeProvider', () {
      test('default mode is stroke', () {
        final mode = container.read(eraserModeProvider);
        expect(mode, equals(EraserMode.stroke));
      });

      test('can change to pixel mode', () {
        container.read(eraserSettingsProvider.notifier).setMode(EraserMode.pixel);
        expect(container.read(eraserModeProvider), equals(EraserMode.pixel));
      });

      test('can change back to stroke mode', () {
        container.read(eraserSettingsProvider.notifier).setMode(EraserMode.pixel);
        container.read(eraserSettingsProvider.notifier).setMode(EraserMode.stroke);
        expect(container.read(eraserModeProvider), equals(EraserMode.stroke));
      });
    });

    group('eraserSizeProvider', () {
      test('default size is 20.0', () {
        final size = container.read(eraserSizeProvider);
        expect(size, equals(20.0));
      });

      test('can change size', () {
        container.read(eraserSettingsProvider.notifier).setSize(40.0);
        expect(container.read(eraserSizeProvider), equals(40.0));
      });

      test('can set small size', () {
        container.read(eraserSettingsProvider.notifier).setSize(5.0);
        expect(container.read(eraserSizeProvider), equals(5.0));
      });

      test('can set large size', () {
        container.read(eraserSettingsProvider.notifier).setSize(100.0);
        expect(container.read(eraserSizeProvider), equals(100.0));
      });
    });

    group('eraserToolProvider', () {
      test('creates EraserTool with default settings', () {
        final tool = container.read(eraserToolProvider);

        expect(tool.mode, equals(core.EraserMode.stroke));
        expect(tool.eraserSize, equals(20.0));
      });

      test('updates when mode changes', () {
        container.read(eraserSettingsProvider.notifier).setMode(EraserMode.pixel);

        final tool = container.read(eraserToolProvider);
        expect(tool.mode, equals(core.EraserMode.pixel));
      });

      test('updates when size changes', () {
        container.read(eraserSettingsProvider.notifier).setSize(50.0);

        final tool = container.read(eraserToolProvider);
        expect(tool.eraserSize, equals(50.0));
      });

      test('updates when both mode and size change', () {
        container.read(eraserSettingsProvider.notifier).setMode(EraserMode.pixel);
        container.read(eraserSettingsProvider.notifier).setSize(35.0);

        final tool = container.read(eraserToolProvider);
        expect(tool.mode, equals(core.EraserMode.pixel));
        expect(tool.eraserSize, equals(35.0));
      });

      test('tolerance is half of eraser size', () {
        container.read(eraserSettingsProvider.notifier).setSize(30.0);

        final tool = container.read(eraserToolProvider);
        expect(tool.tolerance, equals(15.0));
      });
    });

    group('isEraserActiveProvider', () {
      test('default is false', () {
        final isActive = container.read(isEraserActiveProvider);
        expect(isActive, isFalse);
      });
    });
  });
}
