import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/providers/selection_provider.dart';

void main() {
  group('SelectionProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('selectionProvider', () {
      test('initial state is null', () {
        expect(container.read(selectionProvider), isNull);
      });

      test('setSelection updates state', () {
        final selection = Selection.create(
          type: SelectionType.rectangle,
          selectedStrokeIds: ['stroke1'],
          bounds: const BoundingBox(left: 0, top: 0, right: 100, bottom: 100),
        );

        container.read(selectionProvider.notifier).setSelection(selection);

        expect(container.read(selectionProvider), isNotNull);
        expect(
            container.read(selectionProvider)!.selectedStrokeIds, ['stroke1']);
      });

      test('clearSelection sets state to null', () {
        final selection = Selection.create(
          type: SelectionType.rectangle,
          selectedStrokeIds: ['stroke1'],
          bounds: const BoundingBox(left: 0, top: 0, right: 100, bottom: 100),
        );

        container.read(selectionProvider.notifier).setSelection(selection);
        container.read(selectionProvider.notifier).clearSelection();

        expect(container.read(selectionProvider), isNull);
      });

      test('updateBounds updates selection bounds', () {
        final selection = Selection.create(
          type: SelectionType.rectangle,
          selectedStrokeIds: ['stroke1'],
          bounds: const BoundingBox(left: 0, top: 0, right: 100, bottom: 100),
        );

        container.read(selectionProvider.notifier).setSelection(selection);

        const newBounds =
            BoundingBox(left: 50, top: 50, right: 150, bottom: 150);
        container.read(selectionProvider.notifier).updateBounds(newBounds);

        expect(container.read(selectionProvider)?.bounds, equals(newBounds));
      });

      test('updateBounds does nothing when no selection', () {
        const newBounds =
            BoundingBox(left: 50, top: 50, right: 150, bottom: 150);
        container.read(selectionProvider.notifier).updateBounds(newBounds);

        expect(container.read(selectionProvider), isNull);
      });

      test('updateStrokeIds updates selection stroke ids', () {
        final selection = Selection.create(
          type: SelectionType.rectangle,
          selectedStrokeIds: ['stroke1'],
          bounds: const BoundingBox(left: 0, top: 0, right: 100, bottom: 100),
        );

        container.read(selectionProvider.notifier).setSelection(selection);
        container
            .read(selectionProvider.notifier)
            .updateStrokeIds(['stroke1', 'stroke2', 'stroke3']);

        expect(container.read(selectionProvider)?.selectedStrokeIds,
            equals(['stroke1', 'stroke2', 'stroke3']));
      });
    });

    group('selection tool providers', () {
      test('default selection tool type is lasso (matches LassoMode.freeform)',
          () {
        // Default should be lasso to match LassoSettings.defaultSettings().mode = freeform
        expect(container.read(activeSelectionToolTypeProvider),
            equals(SelectionType.lasso));
      });

      test('can change selection tool type to rectangle', () {
        container.read(activeSelectionToolTypeProvider.notifier).state =
            SelectionType.rectangle;

        expect(container.read(activeSelectionToolTypeProvider),
            equals(SelectionType.rectangle));
      });

      test('activeSelectionToolProvider returns rectangle tool when selected',
          () {
        container.read(activeSelectionToolTypeProvider.notifier).state =
            SelectionType.rectangle;
        final tool = container.read(activeSelectionToolProvider);
        expect(tool.selectionType, equals(SelectionType.rectangle));
      });

      test('activeSelectionToolProvider returns lasso tool by default', () {
        // Default should be lasso to match LassoSettings.defaultSettings().mode = freeform
        final tool = container.read(activeSelectionToolProvider);
        expect(tool.selectionType, equals(SelectionType.lasso));
      });

      test('activeSelectionToolProvider returns rectangle tool when selected',
          () {
        container.read(activeSelectionToolTypeProvider.notifier).state =
            SelectionType.rectangle;

        final tool = container.read(activeSelectionToolProvider);
        expect(tool.selectionType, equals(SelectionType.rectangle));
      });

      test('activeSelectionToolProvider switches back to lasso', () {
        container.read(activeSelectionToolTypeProvider.notifier).state =
            SelectionType.rectangle;
        container.read(activeSelectionToolTypeProvider.notifier).state =
            SelectionType.lasso;

        final tool = container.read(activeSelectionToolProvider);
        expect(tool.selectionType, equals(SelectionType.lasso));
      });
    });
  });
}
