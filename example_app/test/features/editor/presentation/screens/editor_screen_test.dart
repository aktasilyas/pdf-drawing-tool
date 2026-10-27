import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:drawing_ui/drawing_ui.dart' show documentProvider;
import 'package:example_app/core/core.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/editor/editor.dart';
import 'package:example_app/features/editor/presentation/widgets/editor_body.dart';

import 'package:example_app/l10n/l10n.dart';

import '../../../../helpers/l10n.dart';

class MockLoadDocumentUseCase extends Mock implements LoadDocumentUseCase {}

class MockSaveDocumentUseCase extends Mock implements SaveDocumentUseCase {}

void main() {
  late MockLoadDocumentUseCase mockLoadUseCase;
  late MockSaveDocumentUseCase mockSaveUseCase;

  setUp(() {
    mockLoadUseCase = MockLoadDocumentUseCase();
    mockSaveUseCase = MockSaveDocumentUseCase();
  });

  Widget createTestWidget(String documentId) {
    return ProviderScope(
      overrides: [
        loadDocumentUseCaseProvider.overrideWithValue(mockLoadUseCase),
        saveDocumentUseCaseProvider.overrideWithValue(mockSaveUseCase),
      ],
      child: localizedApp(
        theme: AppTheme.light,
        home: EditorScreen(documentId: documentId),
      ),
    );
  }

  group('EditorScreen', () {
    const testDocId = 'test-doc-id';

    setUp(() {
      // Test document setup is done per test
    });

    testWidgets('should show loading indicator while loading', (tester) async {
      // Arrange
      final completer = Completer<Either<Failure, DrawingDocument>>();
      when(() => mockLoadUseCase(testDocId))
          .thenAnswer((_) => completer.future);

      // Act
      await tester.pumpWidget(createTestWidget(testDocId));
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Finish loading so no timers or futures outlive the test.
      completer.complete(const Left(CacheFailure('Loading')));
      await tester.pumpAndSettle();
    });

    testWidgets('should show localized error without raw exception text',
        (tester) async {
      // Arrange
      when(() => mockLoadUseCase(testDocId))
          .thenAnswer((_) async => throw Exception('Failed to load'));

      // Act
      await tester.pumpWidget(createTestWidget(testDocId));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Belge açılamadı'), findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);
      expect(find.textContaining('Failed to load'), findsNothing);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Tekrar dene'), findsOneWidget);
      expect(find.text('Geri dön'), findsOneWidget);
      expect(
        tester.getSize(find.widgetWithText(AppButton, 'Tekrar dene')).height,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester.getSize(find.widgetWithText(AppButton, 'Geri dön')).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('Tekrar dene re-runs the load', (tester) async {
      // Arrange
      when(() => mockLoadUseCase(testDocId))
          .thenAnswer((_) async => const Left(CacheFailure('boom')));

      await tester.pumpWidget(createTestWidget(testDocId));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Tekrar dene'));
      await tester.pumpAndSettle();

      // Assert
      verify(() => mockLoadUseCase(testDocId)).called(2);
      expect(find.text('Belge açılamadı'), findsOneWidget);
    });

    testWidgets('Geri dön falls back to /documents without a back stack',
        (tester) async {
      // Arrange
      when(() => mockLoadUseCase(testDocId))
          .thenAnswer((_) async => const Left(CacheFailure('boom')));
      final router = GoRouter(
        initialLocation: '/editor/$testDocId',
        routes: [
          GoRoute(
            path: '/documents',
            builder: (context, state) => const Text('Library'),
          ),
          GoRoute(
            path: '/editor/:id',
            builder: (context, state) =>
                EditorScreen(documentId: state.pathParameters['id']!),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            loadDocumentUseCaseProvider.overrideWithValue(mockLoadUseCase),
            saveDocumentUseCaseProvider.overrideWithValue(mockSaveUseCase),
          ],
          child: MaterialApp.router(
            locale: testLocale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Belge açılamadı'), findsOneWidget);

      // Act
      await tester.tap(find.text('Geri dön'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Library'), findsOneWidget);
    });

    testWidgets('does not build EditorBody before the document is applied',
        (tester) async {
      // Arrange
      final doc = DrawingDocument.emptyMultiPage('T');
      when(() => mockLoadUseCase(testDocId))
          .thenAnswer((_) async => Right(doc));

      // Act: one frame after the load resolves. The session starts in the
      // post-frame callback, so the canvas must not exist yet. Do not pump
      // further: EditorBody is not test-safe.
      await tester.pumpWidget(createTestWidget(testDocId));
      await tester.pump();

      // Assert
      expect(find.byType(EditorBody), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final container =
          ProviderScope.containerOf(tester.element(find.byType(EditorScreen)));
      expect(container.read(documentProvider).id, doc.id);
    });

    // Note: Full widget tests require DrawingScreen to be properly initialized
    // These tests verify the basic error handling and loading states
  });
}
