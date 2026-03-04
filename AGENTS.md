# AGENTS.md - Elyanotes Coding Guidelines

> Bu dosya tüm AI coding assistant'lar tarafından okunmalıdır.
> Cursor, Claude, GPT, Gemini - hepsi bu kurallara uymalıdır.

---

## Project Overview

**Project:** Elyanotes - Flutter drawing/note-taking application  
**Owner:** İlyas Aktaş  
**Architect:** Claude Opus

Elyanotes iki bileşenden oluşur:
1. **pub.dev kütüphanesi** (packages/) - Çizim motoru
2. **Uygulama** (example_app/) - Tam özellikli not uygulaması

---

## Tech Stack

```yaml
Framework: Flutter 3.x with Dart
State Management: Riverpod (flutter_riverpod + riverpod_annotation)
Database: Drift (SQLite)
Backend: Supabase
Routing: GoRouter
DI: GetIt + Injectable
Premium: RevenueCat (purchases_flutter)
Functional: dartz (Either<Failure, T>)
```

---

## Architecture Rules

### Clean Architecture Layers

```
presentation/  → Widgets, Screens, Providers (UI logic only)
domain/        → Entities, Repository interfaces, Use cases
data/          → Repository implementations, Data sources, Models
```

### Feature-First Structure

Her feature kendi klasöründe, kendi katmanlarıyla:

```
features/
└── feature_name/
    ├── feature_name.dart    # Barrel export
    ├── data/
    │   ├── datasources/
    │   ├── models/
    │   └── repositories/
    ├── domain/
    │   ├── entities/
    │   ├── repositories/    # Abstract interfaces
    │   └── usecases/
    └── presentation/
        ├── providers/
        ├── screens/
        └── widgets/
```

### Dependency Rules

```
✅ ALLOWED:
- presentation → domain
- data → domain
- Any layer → core/

❌ FORBIDDEN:
- domain → presentation
- domain → data
- feature_a/data → feature_b/data
- feature_a/presentation → feature_b/presentation

✅ Cross-feature allowed ONLY via domain:
- feature_a → feature_b/domain/entities
- feature_a → feature_b/domain/repositories (interface)
```

---

## Code Style

### General

```dart
// ✅ Use const constructors
const MyWidget({super.key});

// ✅ Prefer final
final String name;

// ✅ Named parameters for 3+ params
void createDocument({
  required String title,
  required String templateId,
  String? folderId,
});

// ✅ Use Either for error handling
Future<Either<Failure, User>> login(String email, String password);

// ❌ Don't use print()
print('debug'); // WRONG
logger.d('debug'); // RIGHT
```

### File Organization

```dart
// ✅ Max 300 lines per file
// ✅ One class per file (exceptions: small related classes)
// ✅ Barrel exports for each module

// feature_name.dart
export 'data/datasources/feature_datasource.dart';
export 'data/repositories/feature_repository_impl.dart';
export 'domain/entities/feature_entity.dart';
export 'domain/repositories/feature_repository.dart';
export 'domain/usecases/feature_usecase.dart';
export 'presentation/providers/feature_provider.dart';
export 'presentation/screens/feature_screen.dart';
```

### Import Rules

```dart
// ✅ CORRECT - Package imports
import 'package:example_app/core/core.dart';
import 'package:example_app/features/auth/auth.dart';

// ❌ WRONG - Relative imports
import '../../../core/database/app_database.dart';

// ❌ WRONG - Direct src imports from other features
import 'package:example_app/features/auth/data/models/user_model.dart';

// ✅ CORRECT - Import via barrel
import 'package:example_app/features/auth/auth.dart';
```

### Naming Conventions

```dart
// Files: snake_case
user_model.dart
auth_repository.dart

// Classes: PascalCase
class UserModel {}
class AuthRepository {}

// Variables/methods: camelCase
final userName = 'test';
void getUserById() {}

// Constants: camelCase or SCREAMING_SNAKE_CASE
const apiBaseUrl = 'https://...';
const int MAX_RETRY_COUNT = 3;

// Private: prefix with underscore
class _PrivateClass {}
final _privateVar = 'secret';
```

---

## Repository Pattern

### Interface (Domain Layer)

```dart
// domain/repositories/document_repository.dart
abstract class DocumentRepository {
  Future<Either<Failure, List<DocumentInfo>>> getDocuments({String? folderId});
  Future<Either<Failure, DocumentInfo>> createDocument(CreateDocumentParams params);
  Future<Either<Failure, void>> deleteDocument(String id);
  Stream<List<DocumentInfo>> watchDocuments({String? folderId});
}
```

### Implementation (Data Layer)

```dart
// data/repositories/document_repository_impl.dart
@Injectable(as: DocumentRepository)
class DocumentRepositoryImpl implements DocumentRepository {
  final DocumentLocalDatasource _localDatasource;
  final NetworkInfo _networkInfo;

  DocumentRepositoryImpl(this._localDatasource, this._networkInfo);

  @override
  Future<Either<Failure, List<DocumentInfo>>> getDocuments({String? folderId}) async {
    try {
      final documents = await _localDatasource.getDocuments(folderId: folderId);
      return Right(documents.map((m) => m.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
}
```

---

## Use Cases

```dart
// domain/usecases/get_documents_usecase.dart
@injectable
class GetDocumentsUseCase {
  final DocumentRepository _repository;

  GetDocumentsUseCase(this._repository);

  Future<Either<Failure, List<DocumentInfo>>> call({String? folderId}) {
    return _repository.getDocuments(folderId: folderId);
  }
}
```

---

## Providers (Riverpod)

```dart
// presentation/providers/documents_provider.dart
@riverpod
class DocumentsNotifier extends _$DocumentsNotifier {
  @override
  Future<List<DocumentInfo>> build({String? folderId}) async {
    final useCase = ref.watch(getDocumentsUseCaseProvider);
    final result = await useCase(folderId: folderId);
    return result.fold(
      (failure) => throw failure,
      (documents) => documents,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build(folderId: null));
  }
}
```

---

## Testing Requirements

### Minimum Coverage: 80%

```dart
// Unit tests for use cases
test('should return documents when repository succeeds', () async {
  when(() => mockRepository.getDocuments())
      .thenAnswer((_) async => Right(tDocuments));

  final result = await useCase();

  expect(result, Right(tDocuments));
  verify(() => mockRepository.getDocuments()).called(1);
});

// Widget tests for screens
testWidgets('should display documents list', (tester) async {
  await tester.pumpWidget(createTestWidget());
  await tester.pumpAndSettle();

  expect(find.byType(DocumentCard), findsNWidgets(3));
});
```

### Test File Structure

```
test/
├── features/
│   └── auth/
│       ├── data/
│       │   └── repositories/
│       │       └── auth_repository_impl_test.dart
│       ├── domain/
│       │   └── usecases/
│       │       └── login_usecase_test.dart
│       └── presentation/
│           ├── providers/
│           │   └── auth_provider_test.dart
│           └── screens/
│               └── login_screen_test.dart
```

---

## Git Workflow

### Branch Naming

```
feature/<feature-name>    # New features
fix/<issue-description>   # Bug fixes
refactor/<scope>          # Refactoring
```

### Commit Format

```
type(scope): message

Types:
- feat: New feature
- fix: Bug fix
- refactor: Code refactoring
- test: Adding tests
- docs: Documentation
- chore: Maintenance

Examples:
feat(auth): add Google sign-in
fix(documents): fix folder deletion crash
refactor(sync): extract sync queue logic
test(premium): add subscription tests
```

### Before Commit Checklist

```bash
# 1. Run analyzer
flutter analyze

# 2. Run tests
flutter test

# 3. Format code
dart format .

# 4. Check for warnings
flutter pub get
```

---

## Forbidden Practices

```dart
// ❌ No print statements
print('debug');

// ❌ No hardcoded strings in UI
Text('Login');  // Use l10n or constants

// ❌ No business logic in widgets
onPressed: () {
  // ❌ WRONG - logic in widget
  final result = await api.login(email, password);
  if (result.isSuccess) navigate();
}

// ✅ RIGHT - delegate to provider
onPressed: () => ref.read(authProvider.notifier).login(email, password),

// ❌ No direct HTTP/database calls in presentation
final response = await http.get(...);  // WRONG in widget/screen

// ❌ No mutable state in entities
class User {
  String name;  // ❌ WRONG - mutable
  final String name;  // ✅ RIGHT - immutable
}
```

---

## File Ownership

```
📁 packages/*              → CURSOR (Phase 5)
📁 example_app/lib/core/*  → ARCHITECT ONLY
📁 example_app/lib/shared/* → ARCHITECT ONLY
📁 features/auth/*         → AGENT-A
📁 features/documents/*    → AGENT-B
📁 features/editor/*       → CURSOR
📁 features/sync/*         → AGENT-C
📁 features/premium/*      → AGENT-D
```

**Başka agent'ın dosyasına DOKUNMA!**

---

## Questions?

Emin olmadığın durumlarda:
1. Bu dosyayı tekrar oku
2. CONTRACTS.md'yi kontrol et
3. İlyas'a sor
