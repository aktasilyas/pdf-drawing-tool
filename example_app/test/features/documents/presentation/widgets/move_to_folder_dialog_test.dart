import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:example_app/core/core.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/documents/documents.dart';

import '../providers/documents_controller_harness.dart'
    show MockDocumentRepository;
import '../screens/library_fixtures.dart';
import '../../../../helpers/l10n.dart';

class MockFolderRepository extends Mock implements FolderRepository {}

void main() {
  late MockFolderRepository repository;
  late MockDocumentRepository documents;
  bool? popped;

  final created = Folder(
    id: 'f-new',
    name: 'Alt',
    parentId: 'f-ders',
    colorValue: 0xFF000000,
    createdAt: DateTime(2026, 9, 1),
  );

  setUp(() {
    repository = MockFolderRepository();
    documents = MockDocumentRepository();
    popped = null;
    when(() => documents.moveDocument(any(), any()))
        .thenAnswer((_) async => const Right<Failure, void>(null));
    when(() => documents.getDocuments(folderId: any(named: 'folderId')))
        .thenAnswer((_) async => const Right([]));
    when(() => documents.getFavorites())
        .thenAnswer((_) async => const Right([]));
    when(() => documents.getRecent(limit: any(named: 'limit')))
        .thenAnswer((_) async => const Right([]));
    when(() => documents.getTrash()).thenAnswer((_) async => const Right([]));
    when(
      () => repository.createFolder(
        name: any(named: 'name'),
        parentId: any(named: 'parentId'),
        colorValue: any(named: 'colorValue'),
      ),
    ).thenAnswer((_) async => Right<Failure, Folder>(created));
  });

  Future<void> pumpDialog(
    WidgetTester tester, {
    String? parentFolderId,
    List<String> documentIds = const [],
    List<String> folderIds = const [],
    Future<Object?>? Function()? onPopped,
  }) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          folderRepositoryProvider.overrideWithValue(repository),
          documentRepositoryProvider.overrideWithValue(documents),
          foldersProvider.overrideWith((ref) => libraryFolders),
        ],
        child: localizedApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(children: [
                TextButton(
                  onPressed: () async => popped = await showDialog<bool>(
                    context: context,
                    builder: (_) => MoveToFolderDialog(
                      documentIds: documentIds,
                      folderIds: folderIds,
                      parentFolderId: parentFolderId,
                    ),
                  ),
                  child: const Text('open'),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> createFolderNamed(WidgetTester tester, String name) async {
    await tester.tap(find.text('Yeni Klasör'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), name);
    await tester.tap(find.text('Oluştur'));
    await tester.pump();
  }

  testWidgets('creates the folder under parentFolderId', (tester) async {
    await pumpDialog(tester, parentFolderId: 'f-ders');
    await createFolderNamed(tester, 'Alt');

    verify(
      () => repository.createFolder(
        name: 'Alt',
        parentId: 'f-ders',
        colorValue: any(named: 'colorValue'),
      ),
    ).called(1);
  });

  testWidgets('creates a root folder when parentFolderId is null',
      (tester) async {
    await pumpDialog(tester);
    await createFolderNamed(tester, 'Kök');

    verify(
      () => repository.createFolder(
        name: 'Kök',
        parentId: null,
        colorValue: any(named: 'colorValue'),
      ),
    ).called(1);
  });

  testWidgets('selecting a target and confirming pops true', (tester) async {
    await pumpDialog(tester, documentIds: const ['doc-1']);
    await tester.tap(find.text('Ders Notları'));
    await tester.pump();
    await tester.tap(find.text('Taşı'));
    await tester.pumpAndSettle();

    verify(() => documents.moveDocument('doc-1', 'f-ders')).called(1);
    expect(popped, isTrue);
  });

  testWidgets('cancel pops without moving', (tester) async {
    await pumpDialog(tester, documentIds: const ['doc-1']);
    await tester.tap(find.text('İptal'));
    await tester.pumpAndSettle();

    verifyNever(() => documents.moveDocument(any(), any()));
    expect(popped, isNull);
    expect(find.byType(MoveToFolderDialog), findsNothing);
  });

  testWidgets('a failed move keeps the dialog open', (tester) async {
    when(() => documents.moveDocument(any(), any()))
        .thenAnswer((_) async => const Left(CacheFailure('boom')));
    await pumpDialog(tester, documentIds: const ['doc-1']);
    await tester.tap(find.text('Projeler'));
    await tester.pump();
    await tester.tap(find.text('Taşı'));
    await tester.pumpAndSettle();

    expect(find.byType(MoveToFolderDialog), findsOneWidget);
    expect(popped, isNull);
  });

  testWidgets('a blank folder name is rejected', (tester) async {
    await pumpDialog(tester);
    await createFolderNamed(tester, '  ');

    verifyNever(() => repository.createFolder(
        name: any(named: 'name'),
        parentId: any(named: 'parentId'),
        colorValue: any(named: 'colorValue')));
    expect(find.text('Oluştur'), findsOneWidget);
  });

  testWidgets('inline create selects the new folder', (tester) async {
    await pumpDialog(tester, documentIds: const ['doc-1']);
    await createFolderNamed(tester, 'Alt');
    await tester.pumpAndSettle();

    // Form closed, move button enabled (a target is selected).
    expect(find.text('Oluştur'), findsNothing);
    final move =
        tester.widget<AppButton>(find.widgetWithText(AppButton, 'Taşı'));
    expect(move.onPressed, isNotNull);
  });

  testWidgets('a moved folder is not offered as its own target',
      (tester) async {
    await pumpDialog(tester, folderIds: const ['f-ders']);
    expect(find.text('Ders Notları'), findsNothing);
    expect(find.text('Biyoloji'), findsNothing);
    expect(find.text('Projeler'), findsOneWidget);
  });

  testWidgets('every row is at least 48dp', (tester) async {
    await pumpDialog(tester, documentIds: const ['doc-1']);
    for (final e in find.byType(ListTile).evaluate()) {
      expect(
          (e.renderObject! as RenderBox).size.height, greaterThanOrEqualTo(48));
    }
    expect(find.byType(ListTile), findsWidgets);
  });
}
