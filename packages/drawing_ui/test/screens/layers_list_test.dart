import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/screens/layers_list.dart';
import 'package:flutter/gestures.dart' show kDoubleTapTimeout;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../golden/helpers/chrome_theme.dart';

void main() {
  late ProviderContainer container;

  /// Pumps the panel with two layers: index 0 (default) and index 1 (active).
  Future<void> pumpList(WidgetTester tester) async {
    container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(layerActionsProvider).add('Second');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: chromeTheme(Brightness.light),
          home: const Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: 260, height: 400, child: LayersList()),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  List<Layer> layers() => container.read(documentProvider).layers;

  Finder byKey(String key) => find.byKey(ValueKey(key));

  testWidgets('tapping a row makes that layer active', (tester) async {
    await pumpList(tester);
    expect(container.read(activeLayerIndexProvider), 1);

    await tester.tap(byKey('layer-row-${layers()[0].id}'));
    // The name area also listens for double taps, so the row's single tap
    // is only accepted once the double-tap window has passed.
    await tester.pump(kDoubleTapTimeout + const Duration(milliseconds: 50));

    expect(container.read(activeLayerIndexProvider), 0);
  });

  testWidgets('delete then undo restores the layer with its content',
      (tester) async {
    await pumpList(tester);
    final removed = layers()[1];
    final stroke = Stroke.create(style: StrokeStyle.pen())
        .addPoint(DrawingPoint(x: 10, y: 10));
    container.read(documentProvider.notifier).addStroke(stroke);
    await tester.pump();

    await tester.tap(byKey('layer-delete'));
    await tester.pump();
    expect(layers().length, 1);

    container.read(historyManagerProvider.notifier).undo();
    await tester.pump();

    expect(layers().length, 2);
    expect(layers()[1].id, removed.id);
    expect(layers()[1].strokes.length, 1);
    expect(byKey('layer-row-${removed.id}'), findsOneWidget);
  });

  testWidgets('visibility toggle flips isVisible', (tester) async {
    await pumpList(tester);
    final id = layers()[0].id;
    expect(layers()[0].isVisible, isTrue);

    await tester.tap(byKey('layer-visibility-$id'));
    await tester.pump();

    expect(layers()[0].isVisible, isFalse);
  });

  testWidgets('double tap on the name renames the layer', (tester) async {
    await pumpList(tester);
    final id = layers()[0].id;

    final name = byKey('layer-name-$id');
    await tester.tap(name);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(name);
    await tester.pumpAndSettle();

    final field = byKey('layer-rename-$id');
    expect(field, findsOneWidget);
    await tester.enterText(field, 'Ink');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(layers()[0].name, 'Ink');
    expect(field, findsNothing);
  });

  testWidgets('every tappable control is at least 48dp', (tester) async {
    await pumpList(tester);
    final id = layers()[0].id;
    final finders = [
      byKey('layer-row-$id'),
      byKey('layer-name-$id'),
      byKey('layer-visibility-$id'),
      byKey('layer-lock-$id'),
      byKey('layer-add'),
      byKey('layer-delete'),
      byKey('layer-duplicate'),
    ];
    for (final finder in finders) {
      expect(finder, findsOneWidget, reason: '$finder');
      final size = tester.getSize(finder);
      expect(size.width, greaterThanOrEqualTo(48), reason: '$finder');
      expect(size.height, greaterThanOrEqualTo(48), reason: '$finder');
    }
  });
}
