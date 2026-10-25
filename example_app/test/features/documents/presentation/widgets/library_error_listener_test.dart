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

  setUp(() {
    prefs = _RejectingPrefs();
    when(() => prefs.getString(any())).thenReturn(null);
    when(() => prefs.getString('documents'))
        .thenReturn(json.encode([document.toJson()]));
    when(() => prefs.getString('folders')).thenReturn(json.encode([
      FolderModel(id: 'root', name: 'Okul', createdAt: now).toJson(),
      FolderModel(id: 'sub', name: 'Ders', parentId: 'root', createdAt: now)
          .toJson(),
    ]));
    when(() => prefs.setString(any(), any())).thenAnswer((_) async => false);

    final documents = DocumentLocalDatasourceImpl(prefs);
    final folders = FolderLocalDatasourceImpl(prefs);
    container = ProviderContainer(overrides: [
      documentRepositoryProvider
          .overrideWithValue(DocumentRepositoryImpl(documents, folders)),
      folderRepositoryProvider
          .overrideWithValue(FolderRepositoryImpl(folders, documents)),
    ]);
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
    expect(await documents().moveToTrash('doc-1'), isFalse);
    await tester.pump();
    expect(find.text('Belge çöpe taşınamadı'), findsOneWidget);
  });

  testWidgets('rename failure from the rename dialog shows a snackbar',
      (tester) async {
    await pumpApp(
      tester,
      home: Consumer(
        builder: (context, ref, _) => Scaffold(
          body: TextButton(
            onPressed: () =>
                showRenameDocumentDialog(context, ref, document.toEntity()),
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
    expect(await folders().createFolder(name: 'Yeni'), isNull);
    await tester.pump();
    expect(find.text('Klasör oluşturulamadı'), findsOneWidget);
  });

  testWidgets('validation messages are shown verbatim', (tester) async {
    await pumpApp(tester);
    expect(await folders().createFolder(name: 'Derin', parentId: 'sub'),
        isNull);
    await tester.pump();
    expect(find.text('Alt klasörlerin altına klasör oluşturulamaz'),
        findsOneWidget);
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
