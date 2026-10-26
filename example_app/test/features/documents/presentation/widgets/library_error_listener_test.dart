import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/documents.dart';
import '../../../../helpers/pass_through_runner.dart';
import '../../../../helpers/rejecting_database.dart';

void main() {
  late AppDatabase db;
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

  /// Holds one document and one sub folder but rejects every write.
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    final documents = DocumentLocalDatasourceImpl(db);
    final folders = FolderLocalDatasourceImpl(db);
    await documents.createDocument(document);
    await folders.createFolder(root);
    await folders.createFolder(sub);
    await rejectLibraryWrites(db);

    final documentRepo =
        DocumentRepositoryImpl(documents, folders, PassThroughRunner());
    final folderRepo =
        FolderRepositoryImpl(folders, documents, PassThroughRunner());
    container = ProviderContainer(
      overrides: [
        documentRepositoryProvider.overrideWithValue(documentRepo),
        folderRepositoryProvider.overrideWithValue(folderRepo),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

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
