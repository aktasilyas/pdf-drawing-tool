import 'package:drawing_ui/drawing_ui.dart' show ElyanotesIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/selection_mode_header.dart';
import '../../../../helpers/l10n.dart';

void main() {
  Future<ProviderContainer> pump(
    WidgetTester tester, {
    Set<String> selected = const {},
  }) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectionModeProvider.overrideWith((ref) => true),
          selectedDocumentsProvider.overrideWith((ref) => selected),
        ],
        child: localizedApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: SelectionModeHeader(
              allDocumentIds: ['a', 'b', 'c'],
              allFolderIds: ['f1'],
            ),
          ),
        ),
      ),
    );
    return ProviderScope.containerOf(
      tester.element(find.byType(SelectionModeHeader)),
    );
  }

  testWidgets('"Tümü" selects every document and folder id', (tester) async {
    final container = await pump(tester);

    await tester.tap(find.text('Tümü'));
    await tester.pump();

    expect(container.read(selectedDocumentsProvider), {'a', 'b', 'c'});
    expect(container.read(selectedFoldersProvider), {'f1'});
  });

  testWidgets('shows the selected count', (tester) async {
    await pump(tester, selected: {'a', 'b'});
    expect(find.text('2 seçildi'), findsOneWidget);
  });

  testWidgets('count label expands so actions end at the right edge',
      (tester) async {
    await pump(tester, selected: {'a'});
    final label = tester.getRect(find.text('1 seçildi'));
    final all = tester.getRect(find.text('Tümü'));
    expect(label.right, lessThan(all.left));
    final row = tester.getRect(find.byType(SelectionModeHeader));
    expect(
        row.right -
            tester.getRect(find.byIcon(ElyanotesIcons.libraryTrash)).right,
        lessThan(24));
  });

  testWidgets('delete icon is danger when something is selected',
      (tester) async {
    await pump(tester, selected: {'a'});
    final color = IconTheme.of(
      tester.element(find.byIcon(ElyanotesIcons.libraryTrash)),
    ).color;
    expect(color, AppPalette.light.danger);
  });

  testWidgets('delete icon is disabled without a selection', (tester) async {
    await pump(tester);
    final color = IconTheme.of(
      tester.element(find.byIcon(ElyanotesIcons.libraryTrash)),
    ).color;
    expect(color, AppPalette.light.textDisabled);
  });
}
