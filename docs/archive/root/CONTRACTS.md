# CONTRACTS.md - Interface Contracts

> ⚠️ Bu dosyayı sadece ARCHITECT değiştirebilir!
> Feature'lar arası iletişim bu interface'ler üzerinden olur.

---

## Core Contracts

### Failure Classes

```dart
// core/errors/failures.dart

abstract class Failure {
  final String message;
  final String? code;
  
  const Failure(this.message, {this.code});
}

class ServerFailure extends Failure {
  const ServerFailure([String message = 'Server error']) : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure([String message = 'Cache error']) : super(message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'No internet connection']) : super(message);
}

class AuthFailure extends Failure {
  const AuthFailure(String message, {String? code}) : super(message, code: code);
}

class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message);
}
```

---

## Auth Feature Contracts

### User Entity

```dart
// features/auth/domain/entities/user.dart

class User {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  
  const User({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
    this.lastLoginAt,
  });
  
  bool get hasDisplayName => displayName != null && displayName!.isNotEmpty;
}
```

### Auth Repository Interface

```dart
// features/auth/domain/repositories/auth_repository.dart

abstract class AuthRepository {
  /// Login with email and password
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  });
  
  /// Login with Google
  Future<Either<Failure, User>> loginWithGoogle();
  
  /// Register new account
  Future<Either<Failure, User>> register({
    required String email,
    required String password,
    required String displayName,
  });
  
  /// Logout current user
  Future<Either<Failure, void>> logout();
  
  /// Get current logged in user (null if not logged in)
  Future<Either<Failure, User?>> getCurrentUser();
  
  /// Watch auth state changes
  Stream<User?> watchAuthState();
  
  /// Send password reset email
  Future<Either<Failure, void>> sendPasswordReset(String email);
  
  /// Check if email is already registered
  Future<Either<Failure, bool>> isEmailRegistered(String email);
}
```

### Auth Use Cases

```dart
// features/auth/domain/usecases/login_usecase.dart
class LoginUseCase {
  Future<Either<Failure, User>> call({
    required String email,
    required String password,
  });
}

// features/auth/domain/usecases/register_usecase.dart
class RegisterUseCase {
  Future<Either<Failure, User>> call({
    required String email,
    required String password,
    required String displayName,
  });
}

// features/auth/domain/usecases/logout_usecase.dart
class LogoutUseCase {
  Future<Either<Failure, void>> call();
}

// features/auth/domain/usecases/get_current_user_usecase.dart
class GetCurrentUserUseCase {
  Future<Either<Failure, User?>> call();
}
```

---

## Documents Feature Contracts

### Document Entity

```dart
// features/documents/domain/entities/document_info.dart

class DocumentInfo {
  final String id;
  final String title;
  final String? folderId;
  final String templateId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? thumbnailPath;
  final int pageCount;
  final bool isFavorite;
  final SyncState syncState;
  
  const DocumentInfo({
    required this.id,
    required this.title,
    this.folderId,
    required this.templateId,
    required this.createdAt,
    required this.updatedAt,
    this.thumbnailPath,
    this.pageCount = 1,
    this.isFavorite = false,
    this.syncState = SyncState.local,
  });
}

enum SyncState { local, syncing, synced, error }
```

### Folder Entity

```dart
// features/documents/domain/entities/folder.dart

class Folder {
  final String id;
  final String name;
  final String? parentId;
  final int colorValue;
  final DateTime createdAt;
  final int documentCount;
  
  const Folder({
    required this.id,
    required this.name,
    this.parentId,
    this.colorValue = 0xFF2196F3,
    required this.createdAt,
    this.documentCount = 0,
  });
  
  bool get isRoot => parentId == null;
}
```

### Template Entity

```dart
// features/documents/domain/entities/template.dart

enum TemplateType {
  blank,
  thinLined,
  thickLined,
  smallGrid,
  largeGrid,
  dotted,
  cornell,
}

class Template {
  final String id;
  final String name;
  final TemplateType type;
  final String? thumbnailAsset;
  final bool isPremium;
  final PageBackground background;
  
  const Template({
    required this.id,
    required this.name,
    required this.type,
    this.thumbnailAsset,
    this.isPremium = false,
    required this.background,
  });
}

// Predefined templates
class Templates {
  static const blank = Template(
    id: 'blank',
    name: 'Boş',
    type: TemplateType.blank,
    thumbnailAsset: 'assets/templates/blank.png',
    background: PageBackground(type: BackgroundType.blank),
  );
  
  static const thinLined = Template(
    id: 'thin_lined',
    name: 'İnce Çizgili',
    type: TemplateType.thinLined,
    thumbnailAsset: 'assets/templates/thin_lined.png',
    background: PageBackground(
      type: BackgroundType.lined,
      lineSpacing: 20,
    ),
  );
  
  // ... diğer templates
  
  static List<Template> get all => [blank, thinLined, /* ... */];
  static List<Template> get free => all.where((t) => !t.isPremium).toList();
}
```

### Document Repository Interface

```dart
// features/documents/domain/repositories/document_repository.dart

abstract class DocumentRepository {
  /// Get all documents, optionally filtered by folder
  Future<Either<Failure, List<DocumentInfo>>> getDocuments({String? folderId});
  
  /// Get single document by ID
  Future<Either<Failure, DocumentInfo>> getDocument(String id);
  
  /// Create new document
  Future<Either<Failure, DocumentInfo>> createDocument({
    required String title,
    required String templateId,
    String? folderId,
  });
  
  /// Update document metadata
  Future<Either<Failure, DocumentInfo>> updateDocument({
    required String id,
    String? title,
    String? folderId,
    String? thumbnailPath,
    int? pageCount,
  });
  
  /// Delete document
  Future<Either<Failure, void>> deleteDocument(String id);
  
  /// Move document to folder
  Future<Either<Failure, void>> moveDocument(String id, String? folderId);
  
  /// Toggle favorite status
  Future<Either<Failure, void>> toggleFavorite(String id);
  
  /// Get favorite documents
  Future<Either<Failure, List<DocumentInfo>>> getFavorites();
  
  /// Get recently opened documents
  Future<Either<Failure, List<DocumentInfo>>> getRecent({int limit = 10});
  
  /// Search documents by title
  Future<Either<Failure, List<DocumentInfo>>> search(String query);
  
  /// Watch documents list (reactive)
  Stream<List<DocumentInfo>> watchDocuments({String? folderId});
  
  /// Get documents in trash
  Future<Either<Failure, List<DocumentInfo>>> getTrash();
  
  /// Move document to trash
  Future<Either<Failure, void>> moveToTrash(String id);
  
  /// Restore document from trash
  Future<Either<Failure, void>> restoreFromTrash(String id);
  
  /// Permanently delete document
  Future<Either<Failure, void>> permanentlyDelete(String id);
}
```

### Folder Repository Interface

```dart
// features/documents/domain/repositories/folder_repository.dart

abstract class FolderRepository {
  /// Get all folders, optionally filtered by parent
  Future<Either<Failure, List<Folder>>> getFolders({String? parentId});
  
  /// Get folder by ID
  Future<Either<Failure, Folder>> getFolder(String id);
  
  /// Create new folder
  Future<Either<Failure, Folder>> createFolder({
    required String name,
    String? parentId,
    int? colorValue,
  });
  
  /// Update folder
  Future<Either<Failure, Folder>> updateFolder({
    required String id,
    String? name,
    int? colorValue,
  });
  
  /// Delete folder (and optionally contents)
  Future<Either<Failure, void>> deleteFolder(String id, {bool deleteContents = false});
  
  /// Move folder to new parent
  Future<Either<Failure, void>> moveFolder(String id, String? newParentId);
  
  /// Watch folders list (reactive)
  Stream<List<Folder>> watchFolders({String? parentId});
  
  /// Get folder path (breadcrumb)
  Future<Either<Failure, List<Folder>>> getFolderPath(String folderId);
}
```

---

## Sync Feature Contracts

### Sync Status Entity

```dart
// features/sync/domain/entities/sync_status.dart

enum SyncStateType { idle, syncing, error, offline }

class SyncStatus {
  final SyncStateType state;
  final DateTime? lastSyncedAt;
  final int pendingChanges;
  final String? errorMessage;
  final double? progress; // 0.0 - 1.0
  
  const SyncStatus({
    required this.state,
    this.lastSyncedAt,
    this.pendingChanges = 0,
    this.errorMessage,
    this.progress,
  });
  
  bool get isSyncing => state == SyncStateType.syncing;
  bool get hasError => state == SyncStateType.error;
  bool get isOffline => state == SyncStateType.offline;
  bool get hasPendingChanges => pendingChanges > 0;
}

enum ConflictResolution { keepLocal, keepRemote, keepBoth }

class SyncConflict {
  final String documentId;
  final DateTime localModified;
  final DateTime remoteModified;
  
  const SyncConflict({
    required this.documentId,
    required this.localModified,
    required this.remoteModified,
  });
}
```

### Sync Repository Interface

```dart
// features/sync/domain/repositories/sync_repository.dart

abstract class SyncRepository {
  /// Sync all pending changes
  Future<Either<Failure, void>> syncAll();
  
  /// Sync specific document
  Future<Either<Failure, void>> syncDocument(String documentId);
  
  /// Get current sync status
  Future<Either<Failure, SyncStatus>> getSyncStatus();
  
  /// Watch sync status changes
  Stream<SyncStatus> watchSyncStatus();
  
  /// Get list of conflicts
  Future<Either<Failure, List<SyncConflict>>> getConflicts();
  
  /// Resolve a sync conflict
  Future<Either<Failure, void>> resolveConflict({
    required String documentId,
    required ConflictResolution resolution,
  });
  
  /// Check network connectivity
  Future<bool> isOnline();
  
  /// Watch connectivity changes
  Stream<bool> watchConnectivity();
  
  /// Enable/disable auto sync
  Future<Either<Failure, void>> setAutoSync(bool enabled);
  
  /// Get auto sync setting
  Future<bool> isAutoSyncEnabled();
}
```

---

## Premium Feature Contracts

### Subscription Entity

```dart
// features/premium/domain/entities/subscription.dart

enum SubscriptionTier { free, premium, premiumPlus }

class Subscription {
  final SubscriptionTier tier;
  final DateTime? expiresAt;
  final bool isActive;
  final String? productId;
  final bool willRenew;
  
  const Subscription({
    required this.tier,
    this.expiresAt,
    required this.isActive,
    this.productId,
    this.willRenew = false,
  });
  
  bool get isFree => tier == SubscriptionTier.free;
  bool get isPremium => tier != SubscriptionTier.free && isActive;
  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());
}
```

### Entitlements

```dart
// features/premium/domain/entities/entitlement.dart

/// Entitlement identifiers - must match RevenueCat dashboard
class Entitlements {
  static const String cloudSync = 'cloud_sync';
  static const String unlimitedDocuments = 'unlimited_documents';
  static const String premiumTemplates = 'premium_templates';
  static const String aiFeatures = 'ai_features';
  static const String advancedExport = 'advanced_export';
  static const String noAds = 'no_ads';
  
  static const List<String> all = [
    cloudSync,
    unlimitedDocuments,
    premiumTemplates,
    aiFeatures,
    advancedExport,
    noAds,
  ];
}

class Entitlement {
  final String id;
  final bool isActive;
  final DateTime? expiresAt;
  
  const Entitlement({
    required this.id,
    required this.isActive,
    this.expiresAt,
  });
}
```

### Product

```dart
// features/premium/domain/entities/product.dart

enum ProductType { subscription, lifetime }

class Product {
  final String id;
  final String title;
  final String description;
  final String price;
  final String currencyCode;
  final ProductType type;
  final String? subscriptionPeriod; // 'monthly', 'yearly'
  
  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.currencyCode,
    required this.type,
    this.subscriptionPeriod,
  });
}
```

### Subscription Repository Interface

```dart
// features/premium/domain/repositories/subscription_repository.dart

abstract class SubscriptionRepository {
  /// Get current subscription status
  Future<Either<Failure, Subscription>> getSubscription();
  
  /// Check if user has specific entitlement
  Future<Either<Failure, bool>> hasEntitlement(String entitlementId);
  
  /// Get all active entitlements
  Future<Either<Failure, List<Entitlement>>> getEntitlements();
  
  /// Get available products for purchase
  Future<Either<Failure, List<Product>>> getProducts();
  
  /// Purchase a product
  Future<Either<Failure, Subscription>> purchase(String productId);
  
  /// Restore previous purchases
  Future<Either<Failure, Subscription>> restorePurchases();
  
  /// Watch subscription changes
  Stream<Subscription> watchSubscription();
  
  /// Get subscription management URL
  Future<Either<Failure, String?>> getManagementUrl();
}
```

---

## Limits and Constants

```dart
// features/premium/domain/entities/limits.dart

class FreeTierLimits {
  static const int maxDocuments = 5;
  static const int maxFolders = 3;
  static const int maxPagesPerDocument = 10;
  static const bool canUseCloudSync = false;
  static const bool canUsePremiumTemplates = false;
  static const bool canUseAiFeatures = false;
}

class PremiumLimits {
  static const int maxDocuments = -1; // Unlimited
  static const int maxFolders = -1;
  static const int maxPagesPerDocument = -1;
  static const bool canUseCloudSync = true;
  static const bool canUsePremiumTemplates = true;
  static const bool canUseAiFeatures = true;
}
```

---

## Feature Interdependencies

```
┌─────────────────────────────────────────────────────────────┐
│                       PREMIUM                                │
│         (SubscriptionRepository, Entitlements)               │
└─────────────────────────────────────────────────────────────┘
                              │
          provides: hasEntitlement(), getSubscription()
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│     AUTH     │     │  DOCUMENTS   │     │     SYNC     │
│              │     │              │     │              │
│ checks:      │     │ checks:      │     │ checks:      │
│ - none       │     │ - unlimited  │     │ - cloudSync  │
│              │     │ - templates  │     │              │
└──────────────┘     └──────┬───────┘     └──────┬───────┘
        │                   │                     │
        │                   │                     │
        └─────────┬─────────┴─────────────────────┘
                  │
                  ▼
          ┌──────────────┐
          │    EDITOR    │
          │              │
          │ uses:        │
          │ - DocumentInfo
          │ - User (author)
          │ - SyncStatus  │
          └──────────────┘
```

### Usage Examples

```dart
// Documents feature checking premium
class CreateDocumentUseCase {
  final DocumentRepository _documentRepository;
  final SubscriptionRepository _subscriptionRepository;

  Future<Either<Failure, DocumentInfo>> call(CreateDocumentParams params) async {
    // Check document limit for free users
    final subscription = await _subscriptionRepository.getSubscription();
    final currentDocs = await _documentRepository.getDocuments();
    
    return subscription.fold(
      (failure) => Left(failure),
      (sub) {
        if (sub.isFree) {
          final docsResult = currentDocs;
          return docsResult.fold(
            (failure) => Left(failure),
            (docs) {
              if (docs.length >= FreeTierLimits.maxDocuments) {
                return Left(LimitExceededFailure('Ücretsiz sınıra ulaştınız'));
              }
              return _documentRepository.createDocument(/* ... */);
            },
          );
        }
        return _documentRepository.createDocument(/* ... */);
      },
    );
  }
}

// Sync feature checking premium
class SyncDocumentsUseCase {
  final SyncRepository _syncRepository;
  final SubscriptionRepository _subscriptionRepository;

  Future<Either<Failure, void>> call() async {
    final hasSync = await _subscriptionRepository.hasEntitlement(Entitlements.cloudSync);
    
    return hasSync.fold(
      (failure) => Left(failure),
      (canSync) {
        if (!canSync) {
          return Left(PremiumRequiredFailure('Cloud sync requires premium'));
        }
        return _syncRepository.syncAll();
      },
    );
  }
}
```

---

## Change Log

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-01-22 | 1.0 | Initial contracts | Architect |

---

⚠️ **Bu interface'leri değiştirmek için Architect onayı gereklidir!**
