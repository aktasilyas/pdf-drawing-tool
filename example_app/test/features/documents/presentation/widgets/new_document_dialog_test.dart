import 'package:dartz/dartz.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:example_app/core/routing/route_names.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/documents.dart';
import 'package:example_app/features/premium/premium.dart';
import 'package:example_app/l10n/l10n.dart';

import '../providers/documents_controller_harness.dart';
import '../../../../helpers/l10n.dart';

void main() {
  setUpAll(registerDocumentsFallbacks);

  final l10n = lookupAppLocalizations(testLocale);
  final buttonKey = GlobalKey();
  late MockDocumentRepository repo;

  Future<void> pumpMenu(WidgetTester tester) async {
    repo = MockDocumentRepository();
    when(() => repo.createDocument(
          title: any(named: 'title'),
          templateId: any(named: 'templateId'),
          folderId: any(named: 'folderId'),
          paperColor: any(named: 'paperColor'),
          isPortrait: any(named: 'isPortrait'),
          documentType: any(named: 'documentType'),
        )).thenAnswer((_) async => Right(testDocument));
    when(() => repo.getDocuments(folderId: any(named: 'folderId')))
        .thenAnswer((_) async => const Right([]));
    when(() => repo.getFavorites()).thenAnswer((_) async => const Right([]));
    when(() => repo.getRecent(limit: any(named: 'limit')))
        .thenAnswer((_) async => const Right([]));
    when(() => repo.getTrash()).thenAnswer((_) async => const Right([]));

    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: Center(
            child: TextButton(
              key: buttonKey,
              onPressed: () => showNewDocumentDropdown(context, buttonKey),
              child: const Text('new'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.editor,
        builder: (_, state) =>
            Text('editor ${state.pathParameters['documentId']}'),
      ),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        documentRepositoryProvider.overrideWithValue(repo),
        totalDocumentCountProvider.overrideWith((ref) async => 0),
        notebookCountProvider.overrideWith((ref) async => 0),
        foldersProvider.overrideWith((ref) async => []),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.light,
        locale: testLocale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.tap(find.byKey(buttonKey));
    await tester.pumpAndSettle();
  }

  testWidgets('Quick note creates a quick note and opens the editor',
      (tester) async {
    await pumpMenu(tester);
    await tester.tap(find.text(l10n.libraryNewQuickNote));
    await tester.pumpAndSettle();

    verify(() => repo.createDocument(
          title: any(named: 'title'),
          templateId: 'thin_lined',
          folderId: null,
          paperColor: any(named: 'paperColor'),
          isPortrait: true,
          documentType: DocumentType.quickNote,
        )).called(1);
    expect(find.text('editor ${testDocument.id}'), findsOneWidget);
  });

  testWidgets('Whiteboard creates a whiteboard and opens the editor',
      (tester) async {
    await pumpMenu(tester);
    await tester.tap(find.text(l10n.libraryNewWhiteboard));
    await tester.pumpAndSettle();

    verify(() => repo.createDocument(
          title: any(named: 'title'),
          templateId: 'blank',
          folderId: null,
          paperColor: any(named: 'paperColor'),
          isPortrait: true,
          documentType: DocumentType.whiteboard,
        )).called(1);
    expect(find.text('editor ${testDocument.id}'), findsOneWidget);
  });
}
