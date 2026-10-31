import 'package:drawing_ui/drawing_ui.dart'
    show CoverTextureStore, sharedPreferencesProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/domain/entities/trashed_page.dart';
import 'package:example_app/features/documents/presentation/providers/document_menu_actions.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/screens/documents_screen.dart';
import 'package:example_app/features/documents/presentation/widgets/document_card.dart';
import 'package:example_app/features/editor/editor.dart'
    show LoadDocumentUseCase;
import 'package:example_app/features/editor/presentation/providers/editor_provider.dart';
import 'package:example_app/l10n/l10n.dart';

import '../../../../helpers/font_loader.dart';
import '../../../../helpers/l10n.dart';
import 'library_fixtures.dart';

class _MockLoadDocument extends Mock implements LoadDocumentUseCase {}

class _MockMenuActions extends Mock implements DocumentMenuActions {}

/// Tapping a notebook in Recently deleted offers Restore / Delete forever
/// instead of opening it in the editor (#621).
void main() {
  late _MockLoadDocument loadDocument;
  late _MockMenuActions actions;
  final trashed = libraryRootDocuments
      .take(2)
      .map((d) => d.copyWith(isInTrash: true, deletedAt: DateTime(2026, 10)))
      .toList();

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppTestFonts();
    await loadManifestFonts();
    await CoverTextureStore.ensureLoaded();
    registerFallbackValue(trashed.first);
  });

  setUp(() {
    loadDocument = _MockLoadDocument();
    actions = _MockMenuActions();
    when(() => actions.restore(any())).thenAnswer((_) async => true);
  });

  Future<AppLocalizations> pumpTrash(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...libraryOverrides(),
          trashDocumentsProvider.overrideWith((ref) => trashed),
          trashedPagesProvider.overrideWith((ref) => const <TrashedPage>[]),
          sharedPreferencesProvider.overrideWithValue(prefs),
          loadDocumentUseCaseProvider.overrideWithValue(loadDocument),
          documentMenuActionsProvider.overrideWithValue(actions),
        ],
        child: localizedApp(
          theme: AppTheme.light,
          home: const DocumentsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final l10n =
        AppLocalizations.of(tester.element(find.byType(Scaffold).first));
    await tester.tap(find.byTooltip(l10n.commonMenu));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.librarySectionTrash));
    await tester.pumpAndSettle();
    return l10n;
  }

  /// Taps the first trashed tile the way its cover does. Calls the tile's
  /// callback so the test covers the Trash wiring, not the hit test of the
  /// tile itself (`document_card_test.dart` covers that).
  Future<void> tapFirstTrashedCard(WidgetTester tester) async {
    final card = tester.widget<DocumentCard>(find.byType(DocumentCard).first);
    expect(card.isInTrash, isTrue);
    card.onTap();
    await tester.pumpAndSettle();
  }

  testWidgets('tapping a trashed notebook shows trash actions, not the editor',
      (tester) async {
    final l10n = await pumpTrash(tester);

    await tapFirstTrashedCard(tester);

    expect(find.text(l10n.commonRestore), findsOneWidget);
    expect(find.text(l10n.libraryDeleteForever), findsOneWidget);
    verifyNever(() => loadDocument(any()));
  });

  testWidgets('Restore from the tap menu restores that notebook',
      (tester) async {
    final l10n = await pumpTrash(tester);

    await tapFirstTrashedCard(tester);
    await tester.tap(find.text(l10n.commonRestore));
    await tester.pumpAndSettle();

    final restored = verify(() => actions.restore(captureAny())).captured;
    expect((restored.single as DocumentInfo).id, trashed.first.id);
    verifyNever(() => loadDocument(any()));
  });

  testWidgets('selection mode in the trash still toggles selection',
      (tester) async {
    final l10n = await pumpTrash(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(DocumentsScreen)),
    );
    container.read(selectionModeProvider.notifier).state = true;
    await tester.pumpAndSettle();

    await tapFirstTrashedCard(tester);

    expect(find.text(l10n.commonRestore), findsNothing);
    expect(container.read(selectedDocumentsProvider), {trashed.first.id});
    verifyNever(() => loadDocument(any()));
  });
}
