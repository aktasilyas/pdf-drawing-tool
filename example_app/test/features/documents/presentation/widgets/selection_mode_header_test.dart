import 'package:dartz/dartz.dart';
import 'package:drawing_ui/drawing_ui.dart' show ElyanotesIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:example_app/core/core.dart' show CacheFailure;
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/documents/domain/repositories/document_repository.dart';
import 'package:example_app/features/documents/domain/repositories/folder_repository.dart';
import 'package:example_app/features/documents/presentation/providers/folders_provider.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/selection_mode_header.dart';
import '../../../../helpers/l10n.dart';

class _MockDocumentRepository extends Mock implements DocumentRepository {}

class _MockFolderRepository extends Mock implements FolderRepository {}

void main() {
  Future<ProviderContainer> pump(
    WidgetTester tester, {
    Set<String> selected = const {},
    Set<String> selectedFolders = const {},
    DocumentRepository? repository,
    FolderRepository? folderRepository,
    bool isTrashSection = false,
  }) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectionModeProvider.overrideWith((ref) => true),
          selectedDocumentsProvider.overrideWith((ref) => selected),
          selectedFoldersProvider.overrideWith((ref) => selectedFolders),
          if (folderRepository != null)
            folderRepositoryProvider.overrideWithValue(folderRepository),
          if (repository != null)
            documentRepositoryProvider.overrideWithValue(repository),
        ],
        child: localizedApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SelectionModeHeader(
              allDocumentIds: const ['a', 'b', 'c'],
              allFolderIds: const ['f1'],
              isTrashSection: isTrashSection,
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

  group('bulk delete forever', () {
    late _MockDocumentRepository repo;

    setUp(() {
      repo = _MockDocumentRepository();
      when(() => repo.permanentlyDelete(any()))
          .thenAnswer((_) async => const Right(null));
    });

    Future<ProviderContainer> deleteAll(WidgetTester tester) async {
      final container = await pump(
        tester,
        selected: {'a', 'b', 'c'},
        repository: repo,
        isTrashSection: true,
      );
      await tester.tap(find.byIcon(ElyanotesIcons.libraryTrash));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Sil'));
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('a partial failure keeps only the failed ids selected',
        (tester) async {
      when(() => repo.permanentlyDelete('b'))
          .thenAnswer((_) async => const Left(CacheFailure('disk')));

      final container = await deleteAll(tester);

      verify(() => repo.permanentlyDelete('a')).called(1);
      verify(() => repo.permanentlyDelete('c')).called(1);
      expect(container.read(selectionModeProvider), isTrue);
      expect(container.read(selectedDocumentsProvider), {'b'});
    });

    testWidgets('full success exits selection mode', (tester) async {
      final container = await deleteAll(tester);

      verify(() => repo.permanentlyDelete(any())).called(3);
      expect(container.read(selectionModeProvider), isFalse);
      expect(container.read(selectedDocumentsProvider), isEmpty);
    });
  });

  group('folder selection', () {
    late _MockFolderRepository folders;
    late _MockDocumentRepository docs;

    setUp(() {
      folders = _MockFolderRepository();
      docs = _MockDocumentRepository();
      when(() => folders.deleteFolder(any(),
              deleteContents: any(named: 'deleteContents')))
          .thenAnswer((_) async => const Right(null));
      when(() => docs.moveToTrash(any()))
          .thenAnswer((_) async => const Right(null));
    });

    testWidgets('folders-only Delete confirms and calls deleteFolder',
        (tester) async {
      final container = await pump(
        tester,
        selectedFolders: {'f1'},
        repository: docs,
        folderRepository: folders,
      );
      await tester.tap(find.byIcon(ElyanotesIcons.libraryTrash));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Sil'));
      await tester.pumpAndSettle();

      verify(() => folders.deleteFolder('f1',
          deleteContents: any(named: 'deleteContents'))).called(1);
      verifyNever(() => docs.moveToTrash(any()));
      expect(container.read(selectionModeProvider), isFalse);
    });

    testWidgets('cancelling the dialog deletes nothing', (tester) async {
      final container = await pump(
        tester,
        selectedFolders: {'f1'},
        folderRepository: folders,
      );
      await tester.tap(find.byIcon(ElyanotesIcons.libraryTrash));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'İptal'));
      await tester.pumpAndSettle();

      verifyNever(() => folders.deleteFolder(any(),
          deleteContents: any(named: 'deleteContents')));
      expect(container.read(selectedFoldersProvider), {'f1'});
    });

    testWidgets('mixed selection handles notebooks and folders',
        (tester) async {
      final container = await pump(
        tester,
        selected: {'a'},
        selectedFolders: {'f1'},
        repository: docs,
        folderRepository: folders,
      );
      await tester.tap(find.byIcon(ElyanotesIcons.libraryTrash));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Sil'));
      await tester.pumpAndSettle();

      verify(() => docs.moveToTrash('a')).called(1);
      verify(() => folders.deleteFolder('f1',
          deleteContents: any(named: 'deleteContents'))).called(1);
      expect(container.read(selectionModeProvider), isFalse);
    });

    testWidgets('a failed folder stays selected', (tester) async {
      when(() => folders.deleteFolder(any(),
              deleteContents: any(named: 'deleteContents')))
          .thenAnswer((_) async => const Left(CacheFailure('disk')));
      final container = await pump(
        tester,
        selectedFolders: {'f1'},
        folderRepository: folders,
      );
      await tester.tap(find.byIcon(ElyanotesIcons.libraryTrash));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Sil'));
      await tester.pumpAndSettle();

      expect(container.read(selectionModeProvider), isTrue);
      expect(container.read(selectedFoldersProvider), {'f1'});
    });

    testWidgets('Duplicate is disabled for folders-only', (tester) async {
      await pump(tester, selectedFolders: {'f1'});
      final button = tester.widget<AppIconButton>(find.ancestor(
        of: find.byIcon(ElyanotesIcons.libraryCopy),
        matching: find.byType(AppIconButton),
      ));
      expect(button.onPressed, isNull);
    });
  });
}
