# Sync Feature

Offline-first senkronizasyon modülü.

## Özellikler

- ✅ **Offline-First**: Tüm değişiklikler önce local DB'ye yazılır
- ✅ **Sync Queue**: FIFO kuyruk sistemi ile sıralı senkronizasyon
- ✅ **Conflict Resolution**: Local/Remote/Both stratejileri
- ✅ **Retry Mechanism**: 3 deneme hakkı ile otomatik retry
- ✅ **Incremental Sync**: Timestamp-based incremental sync
- ✅ **Real-time Status**: Stream-based sync status monitoring
- ✅ **Connectivity Monitoring**: Otomatik online/offline detection
- ✅ **Auto Sync**: Kullanıcı ayarlanabilir otomatik senkronizasyon

## Mimari

```
┌─────────────────────────────────────────────────────────────┐
│                        APP LAYER                            │
├─────────────────────────────────────────────────────────────┤
│                     SYNC SERVICE                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │ SyncManager │  │ SyncQueue   │  │ ConflictResolver    │ │
│  └─────────────┘  └─────────────┘  └─────────────────────┘ │
├─────────────────────────────────────────────────────────────┤
│         LOCAL (Drift)          │      REMOTE (Supabase)    │
│  ┌─────────────────────────┐   │   ┌─────────────────────┐ │
│  │ documents_table         │   │   │ documents (table)   │ │
│  │ folders_table           │   │   │ folders (table)     │ │
│  │ sync_queue_table        │   │   │ sync_metadata       │ │
│  │ sync_metadata_table     │   │   │                     │ │
│  └─────────────────────────┘   │   └─────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Dosya Yapısı

```
sync/
├── domain/
│   ├── entities/
│   │   ├── sync_status.dart          # Sync durumu entity
│   │   ├── sync_queue_item.dart      # Kuyruk öğesi entity
│   │   └── sync_conflict.dart        # Çakışma entity
│   ├── repositories/
│   │   └── sync_repository.dart      # Repository interface
│   └── usecases/
│       ├── sync_all_usecase.dart
│       ├── sync_document_usecase.dart
│       ├── get_sync_status_usecase.dart
│       ├── resolve_conflict_usecase.dart
│       ├── toggle_auto_sync_usecase.dart
│       └── get_pending_items_usecase.dart
├── data/
│   ├── models/
│   │   └── sync_queue_model.dart     # Queue model
│   ├── datasources/
│   │   ├── sync_local_datasource.dart   # Drift datasource
│   │   └── sync_remote_datasource.dart  # Supabase datasource
│   └── repositories/
│       └── sync_repository_impl.dart    # Repository implementation
├── presentation/
│   ├── providers/
│   │   └── sync_provider.dart        # Riverpod providers
│   └── widgets/
│       ├── sync_status_indicator.dart
│       ├── sync_settings_tile.dart
│       └── conflict_resolution_dialog.dart
└── sync.dart                          # Barrel export
```

## Kullanım

### 1. Provider Setup

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MyApp(),
    ),
  );
}
```

### 2. Sync Status Gösterme

```dart
// UI'da sync status göstermek için
SyncStatusIndicator(
  showLabel: true,
  iconSize: 16,
)
```

### 3. Sync Settings

```dart
// Ayarlar sayfasında
SyncSettingsTile()
```

### 4. Manuel Sync Tetikleme

```dart
// Sync controller ile
final controller = ref.read(syncControllerProvider.notifier);
await controller.syncAll();
```

### 5. Document Sync'e Ekleme

```dart
// Bir document değiştiğinde sync queue'ya ekle
final repository = ref.read(syncRepositoryProvider);
await repository.addToQueue(
  SyncQueueItem(
    id: uuid.v4(),
    entityId: documentId,
    entityType: SyncEntityType.document,
    action: SyncAction.update,
    createdAt: DateTime.now(),
  ),
);
```

## Sync Flow

### Upload Flow (Local → Remote)

1. Kullanıcı bir document düzenler
2. Document local DB'ye kaydedilir
3. Sync queue'ya `SyncQueueItem` eklenir
4. Auto sync aktifse veya manuel sync tetiklenirse:
   - Queue'daki tüm itemlar sırayla işlenir
   - Her item için local data alınır
   - Remote'a upsert/delete yapılır
   - Başarılıysa queue'dan silinir
   - Hata varsa retry count artırılır

### Download Flow (Remote → Local)

1. Sync başlatılır
2. Last sync timestamp alınır
3. Remote'dan bu tarihten sonraki değişiklikler çekilir
4. Local DB'ye upsert edilir
5. Last sync timestamp güncellenir

### Conflict Resolution

Bir document hem local hem remote'ta değişmişse:

1. Çakışma detect edilir
2. Kullanıcıya dialog gösterilir
3. Kullanıcı seçer:
   - **Keep Local**: Local version remote'a yazılır
   - **Keep Remote**: Remote version local'e yazılır
   - **Keep Both**: Local kopyalanır, her ikisi de saklanır

## Database Schema

### Drift Tables

```dart
// Documents
- id: String (PK)
- title: String
- folder_id: String?
- template_id: String
- created_at: DateTime
- updated_at: DateTime
- thumbnail_path: String?
- page_count: int
- is_favorite: bool
- is_in_trash: bool
- sync_state: int (0=local, 1=syncing, 2=synced, 3=error)
- content: Uint8List?

// Folders
- id: String (PK)
- name: String
- parent_id: String?
- color_value: int
- created_at: DateTime

// SyncQueue
- id: String (PK)
- entity_id: String
- entity_type: int (0=document, 1=folder)
- action: int (0=create, 1=update, 2=delete)
- created_at: DateTime
- retry_count: int
- error_message: String?

// SyncMetadata
- key: String (PK)
- value: String
```

### Supabase Tables

SQL schema için `supabase_schema.sql` dosyasına bakın.

## Premium Integration

Cloud sync premium feature'dır. Kullanmadan önce kontrol edin:

```dart
final hasSync = await ref.read(
  hasEntitlementProvider(Entitlements.cloudSync).future
);

if (!hasSync) {
  // Show paywall
  return;
}

// Proceed with sync
await controller.syncAll();
```

## Testing

```bash
# Unit tests
flutter test test/features/sync/domain/
flutter test test/features/sync/data/

# Widget tests
flutter test test/features/sync/presentation/
```

## Build Commands

```bash
# Install dependencies
flutter pub get

# Generate Drift code
dart run build_runner build --delete-conflicting-outputs

# Watch mode for development
dart run build_runner watch

# Run analyzer
flutter analyze

# Run tests
flutter test
```

## Troubleshooting

### Drift build hatası

```bash
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

### Sync çalışmıyor

1. Network connectivity kontrol et: `isOnline()`
2. Premium entitlement kontrol et: `hasEntitlement(cloudSync)`
3. Pending items kontrol et: `getPendingItems()`
4. Sync status kontrol et: `getSyncStatus()`

### Conflict resolution çalışmıyor

Conflict detection logic henüz tam implement edilmedi. `getConflicts()` metodu
şu an boş liste döndürüyor. Conflict detection için:

1. Local ve remote timestamp'leri karşılaştır
2. Aynı document için farklı `updated_at` varsa conflict var
3. Conflict dialog göster
4. User seçimine göre resolve et

## TODO

- [ ] Conflict detection logic implement edilmeli
- [ ] Unit testler yazılmalı
- [ ] Integration testler yazılmalı
- [ ] Background sync (WorkManager)
- [ ] Batch sync optimization
- [ ] Sync progress tracking
- [ ] Selective sync (folders)
- [ ] Sync history log

## License

This module is part of StarNote project.
