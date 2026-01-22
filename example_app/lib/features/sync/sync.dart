/// Sync feature barrel export file.
///
/// Import this file to access all sync-related classes and interfaces.
library;

// Domain - Entities
export 'domain/entities/sync_status.dart';
export 'domain/entities/sync_queue_item.dart';
export 'domain/entities/sync_conflict.dart';

// Domain - Repositories
export 'domain/repositories/sync_repository.dart';

// Domain - Use Cases
export 'domain/usecases/sync_all_usecase.dart';
export 'domain/usecases/sync_document_usecase.dart';
export 'domain/usecases/get_sync_status_usecase.dart';
export 'domain/usecases/resolve_conflict_usecase.dart';
export 'domain/usecases/toggle_auto_sync_usecase.dart';
export 'domain/usecases/get_pending_items_usecase.dart';

// Data - Models
export 'data/models/sync_queue_model.dart';

// Data - Datasources
export 'data/datasources/sync_local_datasource.dart';
export 'data/datasources/sync_remote_datasource.dart';

// Data - Repositories
export 'data/repositories/sync_repository_impl.dart';

// Presentation - Providers
export 'presentation/providers/sync_provider.dart';

// Presentation - Widgets
export 'presentation/widgets/sync_status_indicator.dart';
export 'presentation/widgets/sync_settings_tile.dart';
export 'presentation/widgets/conflict_resolution_dialog.dart';
