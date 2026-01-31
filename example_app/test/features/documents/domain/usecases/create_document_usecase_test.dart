import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/documents.dart';
import 'package:example_app/features/premium/premium.dart';

class MockDocumentRepository extends Mock implements DocumentRepository {}
class MockSubscriptionRepository extends Mock implements SubscriptionRepository {}

void main() {
  late CreateDocumentUseCase useCase;
  late MockDocumentRepository mockDocumentRepository;
  late MockSubscriptionRepository mockSubscriptionRepository;

  setUp(() {
    mockDocumentRepository = MockDocumentRepository();
    mockSubscriptionRepository = MockSubscriptionRepository();
    useCase = CreateDocumentUseCase(
      mockDocumentRepository,
      mockSubscriptionRepository,
    );
  });

  group('CreateDocumentUseCase', () {
    const testTitle = 'Test Document';
    const testTemplateId = 'blank';
    const testFolderId = 'folder-1';

    final testDocument = DocumentInfo(
      id: 'doc-1',
      title: testTitle,
      templateId: testTemplateId,
      folderId: testFolderId,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

    const premiumSubscription = Subscription(
      tier: SubscriptionTier.premium,
      isActive: true,
    );

    const freeSubscription = Subscription(
      tier: SubscriptionTier.free,
      isActive: true,
    );

    test('should create document when user has premium subscription', () async {
      // Arrange
      when(() => mockSubscriptionRepository.getSubscription())
          .thenAnswer((_) async => const Right(premiumSubscription));
      when(() => mockDocumentRepository.createDocument(
            title: testTitle,
            templateId: testTemplateId,
            folderId: testFolderId,
          )).thenAnswer((_) async => Right(testDocument));

      // Act
      final result = await useCase(
        title: testTitle,
        templateId: testTemplateId,
        folderId: testFolderId,
      );

      // Assert
      expect(result, Right(testDocument));
      verify(() => mockSubscriptionRepository.getSubscription()).called(1);
      verify(() => mockDocumentRepository.createDocument(
            title: testTitle,
            templateId: testTemplateId,
            folderId: testFolderId,
          )).called(1);
    });

    test('should create document when free user is under limit', () async {
      // Arrange
      final existingDocs = List.generate(
        3,
        (i) => DocumentInfo(
          id: 'doc-$i',
          title: 'Doc $i',
          templateId: 'blank',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      when(() => mockSubscriptionRepository.getSubscription())
          .thenAnswer((_) async => const Right(freeSubscription));
      when(() => mockDocumentRepository.getDocuments())
          .thenAnswer((_) async => Right(existingDocs));
      when(() => mockDocumentRepository.createDocument(
            title: testTitle,
            templateId: testTemplateId,
            folderId: testFolderId,
          )).thenAnswer((_) async => Right(testDocument));

      // Act
      final result = await useCase(
        title: testTitle,
        templateId: testTemplateId,
        folderId: testFolderId,
      );

      // Assert
      expect(result, Right(testDocument));
      verify(() => mockSubscriptionRepository.getSubscription()).called(1);
      verify(() => mockDocumentRepository.getDocuments()).called(1);
      verify(() => mockDocumentRepository.createDocument(
            title: testTitle,
            templateId: testTemplateId,
            folderId: testFolderId,
          )).called(1);
    });

    test('should return failure when free user exceeds document limit', () async {
      // Arrange
      final existingDocs = List.generate(
        FreeTierLimits.maxDocuments,
        (i) => DocumentInfo(
          id: 'doc-$i',
          title: 'Doc $i',
          templateId: 'blank',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      when(() => mockSubscriptionRepository.getSubscription())
          .thenAnswer((_) async => const Right(freeSubscription));
      when(() => mockDocumentRepository.getDocuments())
          .thenAnswer((_) async => Right(existingDocs));

      // Act
      final result = await useCase(
        title: testTitle,
        templateId: testTemplateId,
        folderId: testFolderId,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, contains('Ücretsiz sınıra ulaştınız'));
        },
        (_) => fail('Should return failure'),
      );
      verify(() => mockSubscriptionRepository.getSubscription()).called(1);
      verify(() => mockDocumentRepository.getDocuments()).called(1);
      verifyNever(() => mockDocumentRepository.createDocument(
            title: any(named: 'title'),
            templateId: any(named: 'templateId'),
            folderId: any(named: 'folderId'),
          ));
    });

    test('should not count trash documents towards limit', () async {
      // Arrange
      final existingDocs = [
        ...List.generate(
          3,
          (i) => DocumentInfo(
            id: 'doc-$i',
            title: 'Doc $i',
            templateId: 'blank',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
        ...List.generate(
          3,
          (i) => DocumentInfo(
            id: 'trash-$i',
            title: 'Trash $i',
            templateId: 'blank',
            isInTrash: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
      ];

      when(() => mockSubscriptionRepository.getSubscription())
          .thenAnswer((_) async => const Right(freeSubscription));
      when(() => mockDocumentRepository.getDocuments())
          .thenAnswer((_) async => Right(existingDocs));
      when(() => mockDocumentRepository.createDocument(
            title: testTitle,
            templateId: testTemplateId,
            folderId: testFolderId,
          )).thenAnswer((_) async => Right(testDocument));

      // Act
      final result = await useCase(
        title: testTitle,
        templateId: testTemplateId,
        folderId: testFolderId,
      );

      // Assert
      expect(result, Right(testDocument));
    });

    test('should return failure when subscription check fails', () async {
      // Arrange
      const failure = ServerFailure('Connection error');
      when(() => mockSubscriptionRepository.getSubscription())
          .thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase(
        title: testTitle,
        templateId: testTemplateId,
        folderId: testFolderId,
      );

      // Assert
      expect(result, const Left(failure));
      verify(() => mockSubscriptionRepository.getSubscription()).called(1);
      verifyNever(() => mockDocumentRepository.getDocuments());
      verifyNever(() => mockDocumentRepository.createDocument(
            title: any(named: 'title'),
            templateId: any(named: 'templateId'),
            folderId: any(named: 'folderId'),
          ));
    });
  });
}
