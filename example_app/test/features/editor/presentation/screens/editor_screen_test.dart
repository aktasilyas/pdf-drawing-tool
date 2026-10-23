import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/editor/editor.dart';

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
      child: MaterialApp(
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

    testWidgets('should show error message when loading fails', (tester) async {
      // Arrange
      when(() => mockLoadUseCase(testDocId))
          .thenAnswer((_) async => throw Exception('Failed to load'));

      // Act
      await tester.pumpWidget(createTestWidget(testDocId));
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('Belge yüklenemedi'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Geri Dön'), findsOneWidget);
    });

    // Note: Full widget tests require DrawingScreen to be properly initialized
    // These tests verify the basic error handling and loading states
  });
}
