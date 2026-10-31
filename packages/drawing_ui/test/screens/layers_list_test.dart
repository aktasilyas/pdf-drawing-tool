import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/l10n/canvas_strings.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/screens/layers_list.dart';
import 'package:flutter/gestures.dart' show kDoubleTapTimeout;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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

  group('semantics', () {
    testWidgets('panel meets the tap-target guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpList(tester);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('row is a button named after the layer; active is selected',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pumpList(tester);
      final inactive = layers()[0];
      final active = layers()[1];

      expect(
        tester.getSemantics(byKey('layer-semantics-${active.id}')),
        isSemantics(
          label: active.name,
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(byKey('layer-semantics-${inactive.id}')),
        isSemantics(
          label: inactive.name,
          isButton: true,
          hasSelectedState: true,
          isSelected: false,
          hasTapAction: true,
        ),
      );

      final owner = tester.binding.renderViews.first.owner!.semanticsOwner!;
      owner.performAction(
        tester.getSemantics(byKey('layer-semantics-${inactive.id}')).id,
        SemanticsAction.tap,
      );
      await tester.pump();
      expect(container.read(activeLayerIndexProvider), 0);
      handle.dispose();
    });

    testWidgets('row node keeps the list reorder actions', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpList(tester);
      const l10n = DefaultWidgetsLocalizations();
      final moves = {
        CustomSemanticsAction(label: l10n.reorderItemToStart),
        CustomSemanticsAction(label: l10n.reorderItemToEnd),
      }.map(CustomSemanticsAction.getIdentifier).toSet();

      for (final layer in layers()) {
        final data = tester
            .getSemantics(byKey('layer-semantics-${layer.id}'))
            .getSemanticsData();
        expect(data.label, layer.name);
        expect(
          data.customSemanticsActionIds!.toSet().intersection(moves),
          isNotEmpty,
          reason: layer.name,
        );
      }
      handle.dispose();
    });

    testWidgets('long press action (hint: rename) opens the name field',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pumpList(tester);
      final id = layers()[0].id;
      final node = tester.getSemantics(byKey('layer-semantics-$id'));

      // The hint is a custom action; the row node also holds the list's
      // move actions, so check membership rather than the exact list.
      expect(node, isSemantics(hasLongPressAction: true));
      final hint = CustomSemanticsAction.overridingAction(
        hint: const CanvasStringsTr().renameLayer,
        action: SemanticsAction.longPress,
      );
      expect(
        node.getSemanticsData().customSemanticsActionIds,
        contains(CustomSemanticsAction.getIdentifier(hint)),
      );
      final owner = tester.binding.renderViews.first.owner!.semanticsOwner!;
      owner.performAction(node.id, SemanticsAction.longPress);
      await tester.pumpAndSettle();

      expect(byKey('layer-rename-$id'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('visibility and lock toggles announce their state',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pumpList(tester);
      final id = layers()[0].id;
      const strings = CanvasStringsTr();

      expect(
        tester.getSemantics(byKey('layer-visibility-$id')),
        isSemantics(
          label: strings.hideLayer,
          isButton: true,
          hasToggledState: true,
          isToggled: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(byKey('layer-lock-$id')),
        isSemantics(
          label: strings.lockLayer,
          isButton: true,
          hasToggledState: true,
          isToggled: false,
          hasTapAction: true,
        ),
      );

      await tester.tap(byKey('layer-visibility-$id'));
      await tester.pump();

      expect(
        tester.getSemantics(byKey('layer-visibility-$id')),
        isSemantics(
          label: strings.showLayer,
          isButton: true,
          hasToggledState: true,
          isToggled: false,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });
  });
}
