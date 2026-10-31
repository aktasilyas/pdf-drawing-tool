import 'package:dartz/dartz.dart';
import 'package:drawing_core/drawing_core.dart'
    show
        BackgroundType,
        Cover,
        CoverRegistry,
        DrawingDocument,
        Page,
        PageBackground;
import 'package:drawing_ui/drawing_ui.dart' show CoverPreviewWidget;
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/documents.dart';
import 'package:example_app/features/editor/editor.dart';
import 'package:example_app/features/premium/premium.dart';
import 'package:example_app/l10n/l10n.dart';

import '../providers/documents_controller_harness.dart';
import '../../../../helpers/l10n.dart';

void main() {
  final coverA = CoverRegistry.pickable[0];
  final coverB = CoverRegistry.pickable[1];
  late MockDocumentRepository repo;
  late MockPageTrashRepository pageTrash;
  late Cover stored;

  DocumentInfo info() => testDocument.copyWith(coverId: stored.id);

  setUpAll(registerDocumentsFallbacks);

  setUp(() {
    stored = coverA;
    repo = MockDocumentRepository();
    pageTrash = MockPageTrashRepository();
    when(() => repo.getDocuments(folderId: any(named: 'folderId')))
        .thenAnswer((_) async => Right([info()]));
    when(() => repo.getFavorites()).thenAnswer((_) async => const Right([]));
    when(() => repo.getRecent(limit: any(named: 'limit')))
        .thenAnswer((_) async => const Right([]));
    when(() => repo.getDocument(testDocument.id))
        .thenAnswer((_) async => Right(info()));
    when(() => repo.getDrawingDocument(testDocument.id)).thenAnswer(
      (_) async => Right(
        DrawingDocument.multiPage(
          id: testDocument.id,
          title: testDocument.title,
          pages: [
            Page.createCover(
              index: 0,
              background: PageBackground(
                type: BackgroundType.cover,
                coverId: stored.id,
                color: stored.primaryColor,
              ),
            ),
          ],
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ),
    );
    when(
      () => repo.saveDocumentContent(
        id: any(named: 'id'),
        content: any(named: 'content'),
        pageCount: any(named: 'pageCount'),
        updatedAt: any(named: 'updatedAt'),
        coverId: any(named: 'coverId'),
        updateCover: any(named: 'updateCover'),
        title: any(named: 'title'),
      ),
    ).thenAnswer((invocation) async {
      final id = invocation.namedArguments[#coverId] as String;
      stored = CoverRegistry.byId(id)!;
      return const Right(null);
    });
  });

  testWidgets('picking a cover switches the library card to it',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          documentRepositoryProvider.overrideWithValue(repo),
          pageTrashRepositoryProvider.overrideWithValue(pageTrash),
          totalDocumentCountProvider.overrideWith((ref) async => 0),
          foldersProvider.overrideWith((ref) async => []),
        ],
        child: localizedApp(
          theme: AppTheme.light,
          builder: (context, child) => AppDrawingStringsScope(child: child!),
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                final docs = ref.watch(documentsProvider(null)).valueOrNull;
                if (docs == null) return const SizedBox.shrink();
                final doc = docs.first;
                return Column(
                  children: [
                    SizedBox(
                      width: 200,
                      height: 300,
                      child: DocumentCard(document: doc, onTap: () {}),
                    ),
                    TextButton(
                      onPressed: () => showDocumentMenu(
                        context,
                        ref,
                        doc,
                        isTrash: false,
                      ),
                      child: const Text('open'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    Finder cardCover(Cover cover) => find.descendant(
          of: find.byType(DocumentCard),
          matching: find.byWidgetPredicate(
            (w) => w is CoverPreviewWidget && w.cover.id == cover.id,
          ),
        );
    expect(cardCover(coverA), findsOneWidget);
    expect(cardCover(coverB), findsNothing);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kapağı değiştir'));
    await tester.pumpAndSettle();
    final strings = AppDrawingStrings(lookupAppLocalizations(testLocale));
    await tester.tap(find.text(strings.templates.coverName(coverB)));
    await tester.pumpAndSettle();

    verify(
      () => repo.saveDocumentContent(
        id: testDocument.id,
        content: any(named: 'content'),
        pageCount: any(named: 'pageCount'),
        updatedAt: any(named: 'updatedAt'),
        coverId: coverB.id,
        updateCover: true,
        title: any(named: 'title'),
      ),
    ).called(1);
    expect(cardCover(coverB), findsOneWidget);
    expect(cardCover(coverA), findsNothing);
  });
}
