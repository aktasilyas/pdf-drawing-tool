import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/documents.dart';
import 'package:example_app/features/premium/premium.dart';

class MockFolderRepository extends Mock implements FolderRepository {}
class MockSubscriptionRepository extends Mock implements SubscriptionRepository {}

void main() {
  late CreateFolderUseCase useCase;
  late MockFolderRepository mockFolderRepository;
  late MockSubscriptionRepository mockSubscriptionRepository;

  setUp(() {
    mockFolderRepository = MockFolderRepository();
    mockSubscriptionRepository = MockSubscriptionRepository();
    useCase = CreateFolderUseCase(
      mockFolderRepository,
      mockSubscriptionRepository,
    );
  });

  group('CreateFolderUseCase', () {
    const testName = 'Test Folder';
    const testParentId = 'parent-1';
    const testColor = 0xFF2196F3;

    final testFolder = Folder(
      id: 'folder-1',
      name: testName,
      parentId: testParentId,
      colorValue: testColor,
      createdAt: DateTime(2024, 1, 1),
    );

    const premiumSubscription = Subscription(
      tier: SubscriptionTier.premium,
      isActive: true,
    );

    const freeSubscription = Subscription(
      tier: SubscriptionTier.free,
      isActive: true,
    );

    test('should create folder when user has premium subscription', () async {
      // Arrange
      when(() => mockSubscriptionRepository.getSubscription())
          .thenAnswer((_) async => const Right(premiumSubscription));
      when(() => mockFolderRepository.createFolder(
            name: testName,
            parentId: testParentId,
            colorValue: testColor,
          )).thenAnswer((_) async => Right(testFolder));

      // Act
      final result = await useCase(
        name: testName,
        parentId: testParentId,
        colorValue: testColor,
      );

      // Assert
      expect(result, Right(testFolder));
      verify(() => mockSubscriptionRepository.getSubscription()).called(1);
      verify(() => mockFolderRepository.createFolder(
            name: testName,
            parentId: testParentId,
            colorValue: testColor,
          )).called(1);
    });

    test('should create folder when free user is under limit', () async {
      // Arrange
      final existingFolders = List.generate(
        2,
        (i) => Folder(
          id: 'folder-$i',
          name: 'Folder $i',
          createdAt: DateTime.now(),
        ),
      );

      when(() => mockSubscriptionRepository.getSubscription())
          .thenAnswer((_) async => const Right(freeSubscription));
      when(() => mockFolderRepository.getFolders())
          .thenAnswer((_) async => Right(existingFolders));
      when(() => mockFolderRepository.createFolder(
            name: testName,
            parentId: testParentId,
            colorValue: testColor,
          )).thenAnswer((_) async => Right(testFolder));

      // Act
      final result = await useCase(
        name: testName,
        parentId: testParentId,
        colorValue: testColor,
      );

      // Assert
      expect(result, Right(testFolder));
    });

    test('should return failure when free user exceeds folder limit', () async {
      // Arrange
      final existingFolders = List.generate(
        FreeTierLimits.maxFolders,
        (i) => Folder(
          id: 'folder-$i',
          name: 'Folder $i',
          createdAt: DateTime.now(),
        ),
      );

      when(() => mockSubscriptionRepository.getSubscription())
          .thenAnswer((_) async => const Right(freeSubscription));
      when(() => mockFolderRepository.getFolders())
          .thenAnswer((_) async => Right(existingFolders));

      // Act
      final result = await useCase(
        name: testName,
        parentId: testParentId,
        colorValue: testColor,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, contains('Klasör sınırına ulaştınız'));
        },
        (_) => fail('Should return failure'),
      );
      verifyNever(() => mockFolderRepository.createFolder(
            name: any(named: 'name'),
            parentId: any(named: 'parentId'),
            colorValue: any(named: 'colorValue'),
          ));
    });
  });
}
