# PHASE 5 — STEP 3: Drift Local Storage + Chat Geçmişi + Sync

## ÖZET
AI chat geçmişini Drift (SQLite) ile lokal olarak saklayıp, Supabase ile sync et. Conversation listesi ekle. Bu step sonunda kullanıcı önceki sohbetlerine erişebilecek, offline'da chat geçmişi görüntüleyebilecek.

## BRANCH
```bash
git checkout -b feature/ai-local-storage
```

---

## MİMARİ KARARLAR

1. **Mevcut `app_database.dart`'a AI tabloları ekle** — ayrı DB dosyası değil, çünkü projede zaten tek Drift DB pattern'ı var, schemaVersion artırılarak migration yapılacak
2. **Offline-first** — mesajlar önce lokal DB'ye yazılır, sonra Supabase'e sync edilir
3. **Conversation list** — AI chat modal'a geçmiş sohbet listesi sidebar/drawer eklenir
4. **Sync stratejisi** — Basit: kaydet → cloud'a gönder (fire-and-forget). Chat mesajları append-only olduğu için conflict yok
5. **Auto-title** — İlk mesajdan sonra AI'dan sohbet başlığı iste (opsiyonel, Step 7'de)

---

## @flutter-developer — İMPLEMENTASYON

### BÖLÜM A: Drift Tablolar — Mevcut DB'ye AI Tabloları Ekle

**Önce oku:**
- `example_app/lib/core/database/app_database.dart` — mevcut DB yapısı ve schemaVersion

**1) GÜNCELLE: `example_app/lib/core/database/app_database.dart`**

Mevcut dosyaya iki yeni tablo class'ı ekle ve `@DriftDatabase` annotation'ına dahil et. schemaVersion'ı 1 artır ve migration yaz.

Eklenecek tablolar:

```dart
/// Local AI conversation storage.
class AiConversationsLocal extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get title => text().withDefault(const Constant('Yeni Sohbet'))();
  TextColumn get documentId => text().nullable()();
  TextColumn get taskType => text().withDefault(const Constant('chat'))();
  IntColumn get totalInputTokens => integer().withDefault(const Constant(0))();
  IntColumn get totalOutputTokens => integer().withDefault(const Constant(0))();
  IntColumn get messageCount => integer().withDefault(const Constant(0))();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local AI message storage.
class AiMessagesLocal extends Table {
  TextColumn get id => text()();
  TextColumn get conversationId => text().references(AiConversationsLocal, #id)();
  TextColumn get role => text()(); // 'user', 'assistant', 'system'
  TextColumn get content => text()();
  TextColumn get model => text().nullable()();
  TextColumn get provider => text().nullable()();
  IntColumn get inputTokens => integer().withDefault(const Constant(0))();
  IntColumn get outputTokens => integer().withDefault(const Constant(0))();
  BoolColumn get hasImage => boolean().withDefault(const Constant(false))();
  TextColumn get imagePath => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

`@DriftDatabase` annotation'ına bu iki tabloyu ekle:
```dart
@DriftDatabase(tables: [Documents, Folders, SyncQueue, SyncMetadata, AiConversationsLocal, AiMessagesLocal])
```

Migration ekle (schemaVersion N → N+1):
```dart
@override
int get schemaVersion => MEVCUT_VERSIYON + 1; // örn: 2 → 3

@override
MigrationStrategy get migration => MigrationStrategy(
  onUpgrade: (migrator, from, to) async {
    // Mevcut migration'lar...
    
    if (from < YENİ_VERSIYON) {
      await migrator.createTable(aiConversationsLocal);
      await migrator.createTable(aiMessagesLocal);
    }
  },
  onCreate: (migrator) async {
    await migrator.createAll();
  },
);
```

**2) Build runner çalıştır:**
```bash
cd example_app
dart run build_runner build --delete-conflicting-outputs
```

---

### BÖLÜM B: AI Local Data Source

**3) OLUŞTUR: `example_app/lib/features/ai/data/datasources/ai_local_datasource.dart`**

```dart
import 'package:drift/drift.dart';

import 'package:example_app/core/database/app_database.dart';
import 'package:example_app/features/ai/domain/entities/ai_entities.dart';

/// Local data source for AI conversations and messages using Drift.
class AILocalDataSource {
  final AppDatabase _db;

  AILocalDataSource(this._db);

  // ─── Conversations ──────────────────────────────────

  /// Get all conversations for a user, sorted by most recent.
  Future<List<AIConversation>> getConversations(String userId) async {
    final rows = await (_db.select(_db.aiConversationsLocal)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();

    return rows.map(_rowToConversation).toList();
  }

  /// Get a single conversation by ID.
  Future<AIConversation?> getConversation(String id) async {
    final row = await (_db.select(_db.aiConversationsLocal)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    return row != null ? _rowToConversation(row) : null;
  }

  /// Insert or update a conversation.
  Future<void> upsertConversation(AIConversation conversation) async {
    await _db.into(_db.aiConversationsLocal).insertOnConflictUpdate(
          AiConversationsLocalCompanion.insert(
            id: conversation.id,
            userId: conversation.userId,
            title: Value(conversation.title),
            documentId: Value(conversation.documentId),
            taskType: Value(conversation.taskType),
            totalInputTokens: Value(conversation.totalInputTokens),
            totalOutputTokens: Value(conversation.totalOutputTokens),
            messageCount: Value(conversation.messageCount),
            isPinned: Value(conversation.isPinned),
            isSynced: const Value(false),
            createdAt: conversation.createdAt,
            updatedAt: conversation.updatedAt,
          ),
        );
  }

  /// Delete a conversation and its messages.
  Future<void> deleteConversation(String conversationId) async {
    // Messages are cascade-deleted via foreign key
    // But Drift doesn't enforce FK cascades by default, so delete manually
    await (_db.delete(_db.aiMessagesLocal)
          ..where((t) => t.conversationId.equals(conversationId)))
        .go();
    await (_db.delete(_db.aiConversationsLocal)
          ..where((t) => t.id.equals(conversationId)))
        .go();
  }

  /// Update conversation title.
  Future<void> updateTitle(String conversationId, String title) async {
    await (_db.update(_db.aiConversationsLocal)
          ..where((t) => t.id.equals(conversationId)))
        .write(AiConversationsLocalCompanion(
          title: Value(title),
          updatedAt: Value(DateTime.now()),
          isSynced: const Value(false),
        ));
  }

  // ─── Messages ────────────────────────────────────────

  /// Get all messages for a conversation.
  Future<List<AIMessage>> getMessages(String conversationId) async {
    final rows = await (_db.select(_db.aiMessagesLocal)
          ..where((t) => t.conversationId.equals(conversationId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();

    return rows.map(_rowToMessage).toList();
  }

  /// Watch messages for a conversation (reactive stream).
  Stream<List<AIMessage>> watchMessages(String conversationId) {
    return (_db.select(_db.aiMessagesLocal)
          ..where((t) => t.conversationId.equals(conversationId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map(_rowToMessage).toList());
  }

  /// Insert a message.
  Future<void> insertMessage(AIMessage message) async {
    await _db.into(_db.aiMessagesLocal).insertOnConflictUpdate(
          AiMessagesLocalCompanion.insert(
            id: message.id,
            conversationId: message.conversationId,
            role: message.role.name,
            content: message.content,
            model: Value(message.model),
            provider: Value(message.provider),
            inputTokens: Value(message.inputTokens),
            outputTokens: Value(message.outputTokens),
            hasImage: Value(message.hasImage),
            imagePath: Value(message.imagePath),
            isSynced: const Value(false),
            createdAt: message.createdAt,
          ),
        );

    // Update conversation's updatedAt and messageCount
    await _incrementMessageCount(message.conversationId);
  }

  /// Get unsynced messages for cloud sync.
  Future<List<AIMessage>> getUnsyncedMessages() async {
    final rows = await (_db.select(_db.aiMessagesLocal)
          ..where((t) => t.isSynced.equals(false)))
        .get();

    return rows.map(_rowToMessage).toList();
  }

  /// Mark messages as synced.
  Future<void> markMessagesSynced(List<String> messageIds) async {
    await (_db.update(_db.aiMessagesLocal)
          ..where((t) => t.id.isIn(messageIds)))
        .write(const AiMessagesLocalCompanion(isSynced: Value(true)));
  }

  /// Mark conversations as synced.
  Future<void> markConversationSynced(String conversationId) async {
    await (_db.update(_db.aiConversationsLocal)
          ..where((t) => t.id.equals(conversationId)))
        .write(const AiConversationsLocalCompanion(isSynced: Value(true)));
  }

  // ─── Private Helpers ─────────────────────────────────

  Future<void> _incrementMessageCount(String conversationId) async {
    final conv = await getConversation(conversationId);
    if (conv == null) return;

    await (_db.update(_db.aiConversationsLocal)
          ..where((t) => t.id.equals(conversationId)))
        .write(AiConversationsLocalCompanion(
          messageCount: Value(conv.messageCount + 1),
          updatedAt: Value(DateTime.now()),
        ));
  }

  AIConversation _rowToConversation(AiConversationsLocalData row) {
    return AIConversation(
      id: row.id,
      userId: row.userId,
      title: row.title,
      documentId: row.documentId,
      taskType: row.taskType,
      totalInputTokens: row.totalInputTokens,
      totalOutputTokens: row.totalOutputTokens,
      messageCount: row.messageCount,
      isPinned: row.isPinned,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  AIMessage _rowToMessage(AiMessagesLocalData row) {
    return AIMessage(
      id: row.id,
      conversationId: row.conversationId,
      role: MessageRole.values.firstWhere(
        (r) => r.name == row.role,
        orElse: () => MessageRole.user,
      ),
      content: row.content,
      model: row.model,
      provider: row.provider,
      inputTokens: row.inputTokens,
      outputTokens: row.outputTokens,
      hasImage: row.hasImage,
      imagePath: row.imagePath,
      createdAt: row.createdAt,
    );
  }
}
```

---

### BÖLÜM C: Repository'yi Local Storage ile Güncelle

**4) GÜNCELLE: `example_app/lib/features/ai/data/repositories/ai_repository_impl.dart`**

Mevcut repository'ye local datasource entegre et. Offline-first pattern: önce lokal yaz, sonra remote'a gönder.

Değişiklikler:
- Constructor'a `AILocalDataSource` parametresi ekle
- `sendMessage()`: user mesajı ve AI yanıtı lokal DB'ye kaydet
- `getConversations()`: önce lokal DB'den oku
- `getMessages()`: önce lokal DB'den oku
- `createConversation()`: hem lokal hem remote'a yaz
- `deleteConversation()`: hem lokal hem remote'dan sil

```dart
class AIRepositoryImpl implements AIRepository {
  final AIRemoteDataSource _remoteDataSource;
  final AILocalDataSource _localDataSource;
  final SubscriptionTier _userTier;

  AIRepositoryImpl({
    required AIRemoteDataSource remoteDataSource,
    required AILocalDataSource localDataSource,
    required SubscriptionTier userTier,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _userTier = userTier;

  @override
  Stream<String> sendMessage({
    required String conversationId,
    required String message,
    required AITaskType taskType,
    String? imageBase64,
  }) async* {
    // 1. Save user message locally
    final userMsg = AIMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_user',
      conversationId: conversationId,
      role: MessageRole.user,
      content: message,
      hasImage: imageBase64 != null,
      createdAt: DateTime.now(),
    );
    await _localDataSource.insertMessage(userMsg);

    // 2. Stream from remote
    final buffer = StringBuffer();
    await for (final chunk in _remoteDataSource.chat(
      messages: [
        {'role': 'user', 'content': message},
      ],
      taskType: _mapTaskType(taskType),
      conversationId: conversationId,
      imageBase64: imageBase64,
    )) {
      buffer.write(chunk);
      yield chunk;
    }

    // 3. Save assistant message locally
    final assistantMsg = AIMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_assistant',
      conversationId: conversationId,
      role: MessageRole.assistant,
      content: buffer.toString(),
      createdAt: DateTime.now(),
    );
    await _localDataSource.insertMessage(assistantMsg);

    // 4. Fire-and-forget: save to Supabase
    _syncMessageToCloud(userMsg);
    _syncMessageToCloud(assistantMsg);
  }

  @override
  Future<List<AIConversation>> getConversations() async {
    final userId = _getCurrentUserId();
    if (userId == null) return [];

    // Lokal DB'den oku (offline-first)
    final local = await _localDataSource.getConversations(userId);
    if (local.isNotEmpty) return local;

    // Lokal boşsa remote'dan çek ve lokale kaydet
    try {
      final remote = await _remoteDataSource.getConversations();
      for (final json in remote) {
        final conv = AIConversation.fromJson(_mapKeys(json));
        await _localDataSource.upsertConversation(conv);
      }
      return _localDataSource.getConversations(userId);
    } catch (_) {
      return local; // Offline — boş liste
    }
  }

  @override
  Future<List<AIMessage>> getMessages(String conversationId) async {
    // Lokal DB'den oku
    final local = await _localDataSource.getMessages(conversationId);
    if (local.isNotEmpty) return local;

    // Lokal boşsa remote'dan çek
    try {
      final remote = await _remoteDataSource.getMessages(conversationId);
      for (final json in remote) {
        final msg = AIMessage.fromJson(_mapKeys(json));
        await _localDataSource.insertMessage(msg);
      }
      return _localDataSource.getMessages(conversationId);
    } catch (_) {
      return local;
    }
  }

  @override
  Future<AIConversation> createConversation({
    String? documentId,
    String taskType = 'chat',
  }) async {
    // Remote'da oluştur (ID almak için)
    final data = await _remoteDataSource.createConversation(
      documentId: documentId,
      taskType: taskType,
    );
    final conversation = AIConversation.fromJson(_mapKeys(data));

    // Lokal DB'ye kaydet
    await _localDataSource.upsertConversation(conversation);

    return conversation;
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    // Önce lokal sil
    await _localDataSource.deleteConversation(conversationId);
    // Sonra remote sil (fire-and-forget)
    try {
      await _remoteDataSource.deleteConversation(conversationId);
    } catch (_) {
      // Offline — silme remote'a sync edilecek
    }
  }

  @override
  Future<void> updateConversationTitle(
    String conversationId,
    String title,
  ) async {
    await _localDataSource.updateTitle(conversationId, title);
    try {
      // Remote'u da güncelle
      // ... mevcut Supabase update kodu ...
    } catch (_) {}
  }

  // ... mevcut getUsage(), _getTierLimits(), _mapTaskType(), _mapKeys() metodları korunur ...

  Future<void> _syncMessageToCloud(AIMessage message) async {
    try {
      await _remoteDataSource.saveMessage(
        conversationId: message.conversationId,
        role: message.role.name,
        content: message.content,
        model: message.model,
        provider: message.provider,
        inputTokens: message.inputTokens,
        outputTokens: message.outputTokens,
        hasImage: message.hasImage,
        imagePath: message.imagePath,
      );
      await _localDataSource.markMessagesSynced([message.id]);
    } catch (_) {
      // Offline — sync sonra yapılacak
    }
  }

  String? _getCurrentUserId() {
    // Supabase.instance.client.auth.currentUser?.id kullanımı —
    // Bu import mevcut dosyada zaten var olmalı
    return null; // TODO: implement — Supabase auth'dan userId al
  }
}
```

**ÖNEMLİ:** Mevcut `AIRepositoryImpl` dosyasını tamamen yeniden yazma — sadece `AILocalDataSource` parametresini ekle ve metodları yukarıdaki pattern'a göre güncelle. `_mapKeys()`, `_getTierLimits()`, `_mapTaskType()`, `getUsage()` gibi mevcut metodları koru.

`_getCurrentUserId()` implementasyonu:
```dart
String? _getCurrentUserId() {
  return Supabase.instance.client.auth.currentUser?.id;
}
```

---

### BÖLÜM D: Provider'ları Güncelle

**5) GÜNCELLE: `example_app/lib/features/ai/presentation/providers/ai_providers.dart`**

Local datasource provider ekle ve repository provider'ı güncelle:

```dart
import 'package:example_app/features/ai/data/datasources/ai_local_datasource.dart';
// ... mevcut importlar ...

final aiLocalDataSourceProvider = Provider<AILocalDataSource>((ref) {
  // Mevcut AppDatabase instance'ını kullan
  // Projedeki AppDatabase singleton erişim yöntemini kullan (getIt veya Provider)
  final db = getIt<AppDatabase>(); // veya ref.watch(appDatabaseProvider)
  return AILocalDataSource(db);
});

final aiRepositoryProvider = Provider<AIRepository>((ref) {
  final remote = ref.watch(aiRemoteDataSourceProvider);
  final local = ref.watch(aiLocalDataSourceProvider);
  const tier = SubscriptionTier.free;
  return AIRepositoryImpl(
    remoteDataSource: remote,
    localDataSource: local,
    userTier: tier,
  );
});
```

NOT: `AppDatabase` erişim yöntemini mevcut projede nasıl yapıldığını kontrol et. Eğer `getIt<AppDatabase>()` kullanılıyorsa onu kullan. Eğer başka bir provider varsa onu kullan.

**6) YENİ: `example_app/lib/features/ai/presentation/providers/ai_conversations_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/features/ai/domain/entities/ai_entities.dart';
import 'package:example_app/features/ai/domain/repositories/ai_repository.dart';
import 'package:example_app/features/ai/presentation/providers/ai_providers.dart';

/// Provider for the list of AI conversations.
final aiConversationsProvider =
    FutureProvider.autoDispose<List<AIConversation>>((ref) async {
  final repository = ref.watch(aiRepositoryProvider);
  return repository.getConversations();
});

/// Refresh conversations list.
void refreshConversations(WidgetRef ref) {
  ref.invalidate(aiConversationsProvider);
}
```

---

### BÖLÜM E: Conversation History UI

**7) OLUŞTUR: `example_app/lib/features/ai/presentation/widgets/ai_conversation_list.dart`**

Conversation history drawer/panel — AI chat modal'ın içinden açılır.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:example_app/features/ai/domain/entities/ai_entities.dart';
import 'package:example_app/features/ai/presentation/providers/ai_providers.dart';
import 'package:example_app/features/ai/presentation/providers/ai_conversations_provider.dart';

/// Displays the list of past AI conversations.
class AIConversationList extends ConsumerWidget {
  const AIConversationList({
    super.key,
    required this.onConversationSelected,
    this.currentConversationId,
  });

  final ValueChanged<String> onConversationSelected;
  final String? currentConversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(aiConversationsProvider);
    final theme = Theme.of(context);

    return Container(
      width: 280,
      color: theme.colorScheme.surfaceContainerLow,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.history, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Sohbet Geçmişi',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          ),
          const Divider(height: 1),
          // List
          Expanded(
            child: conversationsAsync.when(
              data: (conversations) {
                if (conversations.isEmpty) {
                  return Center(
                    child: Text(
                      'Henüz sohbet yok',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final conv = conversations[index];
                    final isActive = conv.id == currentConversationId;
                    return _ConversationTile(
                      conversation: conv,
                      isActive: isActive,
                      onTap: () => onConversationSelected(conv.id),
                      onDelete: () async {
                        final repo = ref.read(aiRepositoryProvider);
                        await repo.deleteConversation(conv.id);
                        refreshConversations(ref);
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Hata: $e', style: theme.textTheme.bodySmall),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
  });

  final AIConversation conversation;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      dense: true,
      selected: isActive,
      selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.1),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      title: Text(
        conversation.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        timeago.format(conversation.updatedAt, locale: 'tr'),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, size: 18),
        onPressed: onDelete,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        tooltip: 'Sil',
      ),
      onTap: onTap,
    );
  }
}
```

---

### BÖLÜM F: AIChatModal'a Conversation History Ekle

**8) GÜNCELLE: `example_app/lib/features/ai/presentation/screens/ai_chat_modal.dart`**

Header'a history butonu ekle. Tıklanınca drawer/side panel olarak AIConversationList gösterilir.

Değişiklikler:

1. State'e `_showHistory` bool ekle
2. Header'daki yeni sohbet butonunun yanına history butonu ekle:
```dart
IconButton(
  onPressed: () => setState(() => _showHistory = !_showHistory),
  icon: const Icon(Icons.history),
  tooltip: 'Sohbet geçmişi',
),
```

3. Body'yi Row ile wrap et — history açıksa solda list, sağda chat:
```dart
Expanded(
  child: Row(
    children: [
      // History sidebar (conditional)
      if (_showHistory)
        AIConversationList(
          currentConversationId: chatState.conversationId,
          onConversationSelected: (id) {
            ref.read(aiChatProvider.notifier).initialize(
              existingConversationId: id,
            );
            // Telefonda history'yi kapat
            if (MediaQuery.of(context).size.width < 600) {
              setState(() => _showHistory = false);
            }
          },
        ),
      // Chat area
      Expanded(child: _buildChatArea(chatState, theme)),
    ],
  ),
),
```

4. `_buildChatArea` metodunu extract et — mevcut messages list + empty state kodunu buraya taşı.

5. ai_widgets.dart barrel export'una ekle:
```dart
export 'ai_conversation_list.dart';
```

6. ai_providers.dart barrel export'una ekle:
```dart
export 'ai_conversations_provider.dart';
```

---

### BÖLÜM G: Doğrulama

**9) Build & Analyze:**
```bash
cd example_app
dart run build_runner build --delete-conflicting-outputs
flutter analyze
```

**10) Dosya yapısını doğrula:**
```
example_app/lib/features/ai/
├── data/
│   ├── datasources/
│   │   ├── ai_remote_datasource.dart    (Step 1)
│   │   ├── ai_exceptions.dart           (Step 1)
│   │   └── ai_local_datasource.dart     ← YENİ
│   ├── repositories/
│   │   └── ai_repository_impl.dart      ← GÜNCELLEME (local datasource eklendi)
│   └── services/
│       └── canvas_capture_service.dart   (Step 2)
├── domain/
│   └── ...                              (Step 1, değişiklik yok)
└── presentation/
    ├── providers/
    │   ├── ai_providers.dart            ← GÜNCELLEME (local provider eklendi)
    │   ├── ai_chat_provider.dart        (Step 2)
    │   ├── ai_usage_provider.dart       (Step 2)
    │   └── ai_conversations_provider.dart ← YENİ
    ├── screens/
    │   └── ai_chat_modal.dart           ← GÜNCELLEME (history sidebar)
    └── widgets/
        ├── ai_chat_bubble.dart          (Step 2)
        ├── ai_input_bar.dart            (Step 2)
        ├── ai_streaming_bubble.dart     (Step 2)
        ├── ai_conversation_list.dart    ← YENİ
        └── ai_widgets.dart              ← GÜNCELLEME (yeni export)

Değişen core dosyalar:
  example_app/lib/core/database/app_database.dart  ← GÜNCELLEME (2 tablo + migration)
```

---

## KURALLAR
- Her dosya max 300 satır
- Mevcut `app_database.dart`'taki tabloları ve migration'ları BOZMA — sadece ekle
- `build_runner` sonrası `.g.dart` dosyaları commit'e dahil
- `AiConversationsLocal` ve `AiMessagesLocal` isim pattern'ı Drift convention'a uygun (Local suffix çakışmayı önler)
- Drift companion class isimleri otomatik generate edilir — `AiConversationsLocalCompanion`, `AiMessagesLocalCompanion`
- timeago paketi zaten pubspec.yaml'da — ekstra dependency gerekmez

## TEST KRİTERLERİ
- [ ] `build_runner` başarılı — yeni tablolar `.g.dart`'a eklendi
- [ ] `flutter analyze` temiz
- [ ] Uygulama açılıyor — migration hatasız
- [ ] Mesaj gönderince lokal DB'ye kaydediliyor
- [ ] AI modal kapatıp açınca önceki mesajlar görünüyor
- [ ] History sidebar açılıyor ve sohbet listesi görünüyor
- [ ] Geçmiş sohbete tıklayınca o sohbetin mesajları yükleniyor
- [ ] Sohbet silinebiliyor
- [ ] Yeni sohbet butonu çalışıyor
- [ ] Offline'dayken önceki mesajlar hala görünüyor
- [ ] Dark mode uyumlu

## COMMIT
```
feat(ai): add local storage + conversation history

- Add AI tables to Drift DB (AiConversationsLocal, AiMessagesLocal)
- Add AILocalDataSource with offline-first CRUD
- Update AIRepositoryImpl with local-first pattern
- Add AIConversationList widget for chat history
- Add history sidebar to AIChatModal
- Sync messages to Supabase (fire-and-forget)
- Migration schemaVersion bump
```

## SONRAKİ ADIM
Step 4: Freemium gating + usage tracking UI + premium upgrade prompts
