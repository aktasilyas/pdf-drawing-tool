import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _EnTools extends ToolStringsTr {
  const _EnTools();

  @override
  String get fountainPen => 'Fountain pen';
}

class _EnStrings implements DrawingStrings {
  const _EnStrings();

  @override
  ToolStrings get tools => const _EnTools();

  @override
  ToolbarStrings get toolbar => const ToolbarStringsTr();
}

Future<DrawingStrings> _pump(
  WidgetTester tester, {
  DrawingStrings? scope,
}) async {
  late DrawingStrings seen;
  final probe = Builder(
    builder: (context) {
      seen = context.drawingStrings;
      return const SizedBox();
    },
  );
  await tester.pumpWidget(
    scope == null ? probe : DrawingStringsScope(strings: scope, child: probe),
  );
  return seen;
}

void main() {
  group('DrawingStringsScope', () {
    testWidgets('falls back to Turkish without a scope', (tester) async {
      final strings = await _pump(tester);
      expect(strings, isA<DrawingStringsTr>());
      expect(strings.toolbar.home, 'Ana Sayfa');
    });

    testWidgets('a scope overrides the fallback', (tester) async {
      final strings = await _pump(tester, scope: const _EnStrings());
      expect(strings, isA<_EnStrings>());
      expect(strings.tools.fountainPen, 'Fountain pen');
    });
  });

  group('DrawingStringsTr', () {
    const strings = DrawingStringsTr();

    test('every ToolType label is non-empty and distinct', () {
      final labels = [for (final t in ToolType.values) t.label(strings)];
      expect(labels, everyElement(isNotEmpty));
      expect(labels.toSet().length, labels.length);
    });

    test('tool strings map has no empty value', () {
      final map = strings.tools.toMap();
      expect(map, isNotEmpty);
      expect(map.values, everyElement(isNotEmpty));
    });

    test('toolbar strings map has no empty value', () {
      final map = strings.toolbar.toMap();
      expect(map, isNotEmpty);
      expect(map.values, everyElement(isNotEmpty));
    });

    test('parameterized strings include their argument', () {
      expect(strings.toolbar.color('#FF0000'), contains('#FF0000'));
      expect(strings.toolbar.selectedColor('#FF0000'), contains('#FF0000'));
      expect(strings.toolbar.thickness('2.0'), contains('2.0'));
    });
  });
}
