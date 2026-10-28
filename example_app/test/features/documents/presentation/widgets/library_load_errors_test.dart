import 'package:drawing_ui/drawing_ui.dart' show pdfPathResolverProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/providers/folders_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_content_view.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_error_views.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_sidebar.dart';
import 'package:example_app/features/documents/presentation/widgets/new_document_importers.dart';
import 'package:example_app/l10n/l10n.dart';

import '../../../../helpers/l10n.dart';

const _secret = 'secret-boom-detail';

/// Library, trash and image-import failures show localized copy, never the
/// exception text (#405).
void main() {
  final l10n = lookupAppLocalizations(testLocale);

  Widget contentView(SidebarSection section, List<Override> overrides) {
    return ProviderScope(
      overrides: overrides,
      child: localizedApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: DocumentsContentView(
            section: section,
            folderId: null,
            onFolderTap: (_) {},
            onDocumentTap: (_) {},
            onFolderMore: (_) {},
            onDocumentMore: (_) {},
          ),
        ),
      ),
    );
  }

  void expectPlainError(String message) {
    expect(find.text(message), findsOneWidget);
    expect(find.textContaining(_secret), findsNothing);
    expect(find.textContaining('Exception'), findsNothing);
    expect(find.byKey(DocumentsErrorView.retryKey), findsOneWidget);
  }

  testWidgets('documents load failure shows the localized message',
      (tester) async {
    await tester.pumpWidget(
      contentView(SidebarSection.documents, [
        foldersProvider.overrideWith((ref) async => <Folder>[]),
        documentsProvider.overrideWith(
          (ref, folderId) async => throw Exception(_secret),
        ),
      ]),
    );
    await tester.pump();
    await tester.pump();

    expectPlainError(l10n.libraryLoadFailed);
  });

  testWidgets('folders load failure shows the folders message', (tester) async {
    await tester.pumpWidget(
      contentView(SidebarSection.documents, [
        foldersProvider.overrideWith(
          (ref) async => throw Exception(_secret),
        ),
        documentsProvider.overrideWith(
          (ref, folderId) async => <DocumentInfo>[],
        ),
      ]),
    );
    await tester.pump();
    await tester.pump();

    expectPlainError(l10n.libraryFoldersLoadFailed);
  });

  testWidgets('favorite documents failure shows the localized message',
      (tester) async {
    await tester.pumpWidget(
      contentView(SidebarSection.favorites, [
        favoriteFoldersProvider.overrideWith((ref) async => <Folder>[]),
        favoriteDocumentsProvider.overrideWith(
          (ref) async => throw Exception(_secret),
        ),
      ]),
    );
    await tester.pump();
    await tester.pump();

    expectPlainError(l10n.libraryLoadFailed);
  });

  testWidgets('trash load failure shows the trash message', (tester) async {
    await tester.pumpWidget(
      contentView(SidebarSection.trash, [
        trashItemsProvider.overrideWith(
          (ref) async => throw Exception(_secret),
        ),
      ]),
    );
    await tester.pump();
    await tester.pump();

    expectPlainError(l10n.libraryTrashLoadFailed);
  });

  testWidgets('image import failure shows a localized snackbar',
      (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pdfPathResolverProvider.overrideWith(
            (ref) => throw StateError(_secret),
          ),
        ],
        child: localizedApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (ctx) {
                context = ctx;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );

    final pending = importImageFile(context, path: '/x/photo.png', name: 'a');
    await tester.pump();
    await pending;
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text(l10n.libraryErrorImportDocument), findsOneWidget);
    expect(find.textContaining(_secret), findsNothing);
    expect(find.textContaining('StateError'), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
