import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:example_app/features/editor/editor.dart';
import 'package:drawing_core/drawing_core.dart';

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
    late DrawingDocument testDocument;

    setUp(() {
      testDocument = DrawingDocument.multiPage(
        id: testDocId,
        title: 'Test Document',
        pages: [Page.create(index: 0)],
      );
    });

    testWidgets('should show loading indicator while loading', (tester) async {
      // Arrange
      when(() => mockLoadUseCase(testDocId))
          .thenAnswer((_) async => Future.delayed(
                const Duration(seconds: 1),
                () => throw Exception('Loading'),
              ));

      // Act
      await tester.pumpWidget(createTestWidget(testDocId));
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show error message when loading fails', (tester) async {
      // Arrange
      when(() => mockLoadUseCase(testDocId))
          .thenAnswer((_) async => throw Exception('Failed to load'));

      // Act
      await tester.pumpWidget(createTestWidget(testDocId));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Hata'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Geri Dön'), findsOneWidget);
    });

    // Note: Full widget tests require DrawingScreen to be properly initialized
    // These tests verify the basic error handling and loading states
  });
}
