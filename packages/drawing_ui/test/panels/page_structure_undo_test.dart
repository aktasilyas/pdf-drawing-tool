import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/panels/page_structure_undo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

core.Page _page(String id, int index) => core.Page(
      id: id,
      index: index,
      size: core.PageSize.a4Portrait,
      layers: [core.Layer.empty('L')],
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  testWidgets('a failed undo shows the "can\'t undo" SnackBar', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(documentProvider.notifier).updateDocument(
          core.DrawingDocument.multiPage(
            id: 'd',
            title: 't',
            pages: [_page('p0', 0), _page('p1', 1)],
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
        );
    final actions = container.read(pageStructureActionsProvider);
    final change = actions.insertPage(1, _page('new', 1));
    // A conflicting change: another page vanishes after the insert.
    await actions.deletePage(2);

    late ScaffoldMessengerState messenger;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(builder: (context) {
          messenger = ScaffoldMessenger.of(context);
          return const SizedBox();
        }),
      ),
    ));

    showPageUndoSnackBar(
      messenger,
      actions,
      change,
      'Added',
      undoLabel: 'Undo',
      undoFailedMessage: "Can't undo",
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Undo'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text("Can't undo"), findsOneWidget);
  });
}
