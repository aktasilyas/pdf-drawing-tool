import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/documents.dart';

/// Prefs that hold one document and one sub folder but reject every write,
/// as SharedPreferences does when the platform write fails.
class _RejectingPrefs extends Mock implements SharedPreferences {}

void main() {
  late _RejectingPrefs prefs;
  late ProviderContainer container;

  final now = DateTime(2026, 1, 1);
  final document = DocumentModel(
    id: 'doc-1',
    title: 'Notes',
    templateId: 'blank',
    createdAt: now,
    updatedAt: now,
  );
  final root = FolderModel(id: 'root', name: 'Okul', createdAt: now);
  final sub = FolderModel(
    id: 'sub',
    name: 'Ders',
    parentId: 'root',
    createdAt: now,
  );

  setUp(() {
    prefs = _RejectingPrefs();
    final documentsJson = json.encode([document.toJson()]);
    final foldersJson = json.encode([root.toJson(), sub.toJson()]);
    when(() => prefs.getString(any())).thenReturn(null);
    when(() => prefs.getString('documents')).thenReturn(documentsJson);
    when(() => prefs.getString('folders')).thenReturn(foldersJson);
    when(() => prefs.setString(any(), any())).thenAnswer((_) async => false);

    final documents = DocumentLocalDatasourceImpl(prefs);
    final folders = FolderLocalDatasourceImpl(prefs);
    final documentRepo = DocumentRepositoryImpl(documents, folders);
    final folderRepo = FolderRepositoryImpl(folders, documents);
    container = ProviderContainer(
      overrides: [
        documentRepositoryProvider.overrideWithValue(documentRepo),
        folderRepositoryProvider.overrideWithValue(folderRepo),
      ],
    );
  });

  tearDown(() => container.dispose());

  Future<void> pumpApp(WidgetTester tester, {Widget? home}) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => LibraryErrorListener(child: child!),
          home: home ?? const Scaffold(body: SizedBox.expand()),
        ),
      ),
    );
  }

  DocumentsController documents() =>
      container.read(documentsControllerProvider.notifier);
  FoldersController folders() =>
      container.read(foldersControllerProvider.notifier);

  testWidgets('move to trash failure shows a snackbar', (tester) async {
    await pumpApp(tester);
    final moved = await documents().moveToTrash('doc-1');
    expect(moved, isFalse);
    await tester.pump();
    expect(find.text('Belge çöpe taşınamadı'), findsOneWidget);
  });

  testWidgets('rename dialog failure shows a snackbar', (tester) async {
    final info = document.toEntity();
    await pumpApp(
      tester,
      home: Consumer(
        builder: (context, ref, _) => Scaffold(
          body: TextButton(
            onPressed: () => showRenameDocumentDialog(context, ref, info),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Yeni ad');
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(find.text('Belge adı değiştirilemedi'), findsOneWidget);
  });

  testWidgets('folder create failure shows a snackbar', (tester) async {
    await pumpApp(tester);
    final id = await folders().createFolder(name: 'Yeni');
    expect(id, isNull);
    await tester.pump();
    expect(find.text('Klasör oluşturulamadı'), findsOneWidget);
  });

  testWidgets('validation messages are shown verbatim', (tester) async {
    await pumpApp(tester);
    final id = await folders().createFolder(name: 'Derin', parentId: 'sub');
    expect(id, isNull);
    await tester.pump();
    const message = 'Alt klasörlerin altına klasör oluşturulamaz';
    expect(find.text(message), findsOneWidget);
  });

  testWidgets('every failure is shown, even when identical', (tester) async {
    await pumpApp(tester);
    final seen = <LibraryError?>[];
    container.listen(libraryErrorProvider, (_, next) => seen.add(next));
    await documents().toggleFavorite('doc-1');
    await documents().toggleFavorite('doc-1');
    expect(seen, hasLength(2));
  });
}
