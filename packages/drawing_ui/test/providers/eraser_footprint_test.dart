// Eraser cursor must match the erase footprint (#132).
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/widgets/eraser_cursor_widget.dart';
import 'package:drawing_ui/src/canvas/eraser_cursor_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EraserSettings defaults', () {
    test('new installs erase without pressure scaling', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final settings = container.read(eraserSettingsProvider);

      expect(settings.pressureSensitive, isFalse);
      for (final p in [0.0, 0.5, 1.0]) {
        expect(settings.effectiveSize(p), settings.size);
      }
    });

    test('a persisted choice keeps pressure sensitivity on', () {
      final settings = EraserSettings.fromJson(const {
        'pressureSensitive': true,
      });

      expect(settings.pressureSensitive, isTrue);
    });
  });

  group('EraserSettings.effectiveSize', () {
    const base = EraserSettings(
      mode: EraserMode.pixel,
      size: 20,
      pressureSensitive: true,
      eraseOnlyHighlighter: false,
      autoLift: false,
    );

    test('scales 30-100 % with pressure when on', () {
      expect(base.effectiveSize(0.0), closeTo(6, 1e-9));
      expect(base.effectiveSize(0.5), closeTo(13, 1e-9));
      expect(base.effectiveSize(1.0), closeTo(20, 1e-9));
    });

    test('clamps out-of-range pressure', () {
      expect(base.effectiveSize(-1), closeTo(6, 1e-9));
      expect(base.effectiveSize(2), closeTo(20, 1e-9));
    });

    test('ignores pressure when off', () {
      final off = base.copyWith(pressureSensitive: false);
      expect(off.effectiveSize(0.0), 20);
      expect(off.effectiveSize(0.5), 20);
    });
  });

  group('EraserCursorWidget', () {
    Future<double> cursorSize(
      WidgetTester tester, {
      required bool pressureSensitive,
      required double pressure,
    }) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(eraserSettingsProvider.notifier)
        ..setSize(20)
        ..setPressureSensitive(pressureSensitive);
      container.read(eraserCursorPressureProvider.notifier).state = pressure;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: EraserCursorWidget(
              cursorPosition: Offset(50, 50),
              isVisible: true,
            ),
          ),
        ),
      );
      final paint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(EraserCursorWidget),
          matching: find.byType(CustomPaint),
        ),
      );
      return (paint.painter! as EraserCursorPainter).size;
    }

    for (final p in [0.0, 0.5, 1.0]) {
      testWidgets('cursor equals erase size at pressure $p (on)',
          (tester) async {
        final size = await cursorSize(
          tester,
          pressureSensitive: true,
          pressure: p,
        );
        const settings = EraserSettings(
          mode: EraserMode.pixel,
          size: 20,
          pressureSensitive: true,
          eraseOnlyHighlighter: false,
          autoLift: false,
        );
        expect(size, closeTo(settings.effectiveSize(p), 1e-9));
      });
    }

    testWidgets('cursor stays full size when pressure scaling is off',
        (tester) async {
      final size = await cursorSize(
        tester,
        pressureSensitive: false,
        pressure: 0.2,
      );
      expect(size, 20);
    });
  });
}
