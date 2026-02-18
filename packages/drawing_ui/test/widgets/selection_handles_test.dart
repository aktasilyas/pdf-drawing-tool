import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/widgets/selection_handles.dart';

void main() {
  group('SelectionHandles', () {
    late Selection testSelection;

    setUp(() {
      testSelection = Selection.create(
        type: SelectionType.rectangle,
        selectedStrokeIds: ['stroke1'],
        bounds: const BoundingBox(left: 50, top: 50, right: 150, bottom: 150),
      );
    });

    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SelectionHandles(
                selection: testSelection,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(SelectionHandles), findsOneWidget);
    });

    testWidgets('has GestureDetector for interaction', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SelectionHandles(
                selection: testSelection,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(GestureDetector), findsOneWidget);
    });

    testWidgets('expands to fill available space', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: SelectionHandles(
                  selection: testSelection,
                ),
              ),
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(SelectionHandles),
          matching: find.byType(SizedBox),
        ),
      );

      // SizedBox.expand() sets width/height to double.infinity
      expect(sizedBox.width, equals(double.infinity));
      expect(sizedBox.height, equals(double.infinity));
    });

    testWidgets('accepts selection parameter', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SelectionHandles(
                selection: testSelection,
              ),
            ),
          ),
        ),
      );

      final widget = tester.widget<SelectionHandles>(
        find.byType(SelectionHandles),
      );

      expect(widget.selection, equals(testSelection));
    });

    testWidgets('accepts optional callbacks', (tester) async {
      bool changedCalled = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SelectionHandles(
                selection: testSelection,
                onSelectionChanged: () => changedCalled = true,
              ),
            ),
          ),
        ),
      );

      final widget = tester.widget<SelectionHandles>(
        find.byType(SelectionHandles),
      );

      expect(widget.onSelectionChanged, isNotNull);
      // Callback not called yet (just testing presence)
      expect(changedCalled, isFalse);
    });
  });

  group('SelectionActions', () {
    testWidgets('renders without error', (tester) async {
      final selection = Selection.create(
        type: SelectionType.rectangle,
        selectedStrokeIds: ['stroke1'],
        bounds: const BoundingBox(left: 0, top: 0, right: 100, bottom: 100),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SelectionActions(selection: selection),
            ),
          ),
        ),
      );

      expect(find.byType(SelectionActions), findsOneWidget);
    });

    testWidgets('returns SizedBox.shrink', (tester) async {
      final selection = Selection.create(
        type: SelectionType.rectangle,
        selectedStrokeIds: ['stroke1'],
        bounds: const BoundingBox(left: 0, top: 0, right: 100, bottom: 100),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SelectionActions(selection: selection),
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(SelectionActions),
          matching: find.byType(SizedBox),
        ),
      );

      expect(sizedBox.width, equals(0.0));
      expect(sizedBox.height, equals(0.0));
    });

    testWidgets('accepts onDeleted callback', (tester) async {
      final selection = Selection.create(
        type: SelectionType.rectangle,
        selectedStrokeIds: ['stroke1'],
        bounds: const BoundingBox(left: 0, top: 0, right: 100, bottom: 100),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SelectionActions(
                selection: selection,
                onDeleted: () {},
              ),
            ),
          ),
        ),
      );

      final widget = tester.widget<SelectionActions>(
        find.byType(SelectionActions),
      );

      expect(widget.onDeleted, isNotNull);
    });
  });
}
