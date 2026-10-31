import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/documents/documents.dart';
import 'package:example_app/features/documents/presentation/widgets/trash_content_view.dart';

import '../../../../helpers/l10n.dart';

/// An empty Recently deleted says the trash is empty (#619).
void main() {
  testWidgets('empty trash shows the trash empty state, not "No notes yet"',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          trashItemsProvider.overrideWith((ref) async => <TrashItem>[]),
        ],
        child: localizedApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          home: Scaffold(
            body: TrashContentView(
              onDocumentTap: (_) {},
              onDocumentMore: (_) {},
              onTrashedPageTap: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TrashEmptyState), findsOneWidget);
    expect(find.text('Trash is empty'), findsOneWidget);
    expect(find.text('Deleted notes will appear here'), findsOneWidget);
    expect(find.text('No notes yet'), findsNothing);
    expect(find.byType(DocumentsEmptyState), findsNothing);
    // No create call-to-action in the trash.
    expect(find.byType(AppButton), findsNothing);
  });
}
