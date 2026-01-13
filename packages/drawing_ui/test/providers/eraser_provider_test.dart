import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/providers/eraser_provider.dart';

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
        container.read(eraserModeProvider.notifier).state = EraserMode.pixel;
        expect(container.read(eraserModeProvider), equals(EraserMode.pixel));
      });

      test('can change back to stroke mode', () {
        container.read(eraserModeProvider.notifier).state = EraserMode.pixel;
        container.read(eraserModeProvider.notifier).state = EraserMode.stroke;
        expect(container.read(eraserModeProvider), equals(EraserMode.stroke));
      });
    });

    group('eraserSizeProvider', () {
      test('default size is 20.0', () {
        final size = container.read(eraserSizeProvider);
        expect(size, equals(20.0));
      });

      test('can change size', () {
        container.read(eraserSizeProvider.notifier).state = 40.0;
        expect(container.read(eraserSizeProvider), equals(40.0));
      });

      test('can set small size', () {
        container.read(eraserSizeProvider.notifier).state = 5.0;
        expect(container.read(eraserSizeProvider), equals(5.0));
      });

      test('can set large size', () {
        container.read(eraserSizeProvider.notifier).state = 100.0;
        expect(container.read(eraserSizeProvider), equals(100.0));
      });
    });

    group('eraserToolProvider', () {
      test('creates EraserTool with default settings', () {
        final tool = container.read(eraserToolProvider);

        expect(tool.mode, equals(EraserMode.stroke));
        expect(tool.eraserSize, equals(20.0));
      });

      test('updates when mode changes', () {
        container.read(eraserModeProvider.notifier).state = EraserMode.pixel;

        final tool = container.read(eraserToolProvider);
        expect(tool.mode, equals(EraserMode.pixel));
      });

      test('updates when size changes', () {
        container.read(eraserSizeProvider.notifier).state = 50.0;

        final tool = container.read(eraserToolProvider);
        expect(tool.eraserSize, equals(50.0));
      });

      test('updates when both mode and size change', () {
        container.read(eraserModeProvider.notifier).state = EraserMode.pixel;
        container.read(eraserSizeProvider.notifier).state = 35.0;

        final tool = container.read(eraserToolProvider);
        expect(tool.mode, equals(EraserMode.pixel));
        expect(tool.eraserSize, equals(35.0));
      });

      test('tolerance is half of eraser size', () {
        container.read(eraserSizeProvider.notifier).state = 30.0;

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
