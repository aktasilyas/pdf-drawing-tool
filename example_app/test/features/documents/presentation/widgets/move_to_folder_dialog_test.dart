import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/documents.dart';

import '../screens/library_fixtures.dart';

class MockFolderRepository extends Mock implements FolderRepository {}

void main() {
  late MockFolderRepository repository;

  final created = Folder(
    id: 'f-new',
    name: 'Alt',
    parentId: 'f-ders',
    colorValue: 0xFF000000,
    createdAt: DateTime(2026, 9, 1),
  );

  setUp(() {
    repository = MockFolderRepository();
    when(
      () => repository.createFolder(
        name: any(named: 'name'),
        parentId: any(named: 'parentId'),
        colorValue: any(named: 'colorValue'),
      ),
    ).thenAnswer((_) async => Right<Failure, Folder>(created));
  });

  Future<void> pumpDialog(WidgetTester tester, {String? parentFolderId}) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          folderRepositoryProvider.overrideWithValue(repository),
          foldersProvider.overrideWith((ref) => libraryFolders),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: MoveToFolderDialog(parentFolderId: parentFolderId),
          ),
        ),
      ),
    );
    await tester.pump();
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
}
