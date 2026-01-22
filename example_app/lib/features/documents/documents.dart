// Domain Layer - Entities
export 'domain/entities/document_info.dart';
export 'domain/entities/folder.dart';
export 'domain/entities/template.dart';

// Domain Layer - Repositories
export 'domain/repositories/document_repository.dart';
export 'domain/repositories/folder_repository.dart';

// Domain Layer - Use Cases
export 'domain/usecases/create_document_usecase.dart';
export 'domain/usecases/create_folder_usecase.dart';
export 'domain/usecases/delete_document_usecase.dart';
export 'domain/usecases/delete_folder_usecase.dart';
export 'domain/usecases/get_documents_usecase.dart';
export 'domain/usecases/get_favorites_usecase.dart';
export 'domain/usecases/get_folders_usecase.dart';
export 'domain/usecases/get_recent_usecase.dart';
export 'domain/usecases/get_trash_usecase.dart';
export 'domain/usecases/move_document_usecase.dart';
export 'domain/usecases/move_to_trash_usecase.dart';
export 'domain/usecases/restore_from_trash_usecase.dart';
export 'domain/usecases/search_documents_usecase.dart';
export 'domain/usecases/toggle_favorite_usecase.dart';

// Data Layer - Models
export 'data/models/document_model.dart';
export 'data/models/folder_model.dart';

// Data Layer - Datasources
export 'data/datasources/document_local_datasource.dart';
export 'data/datasources/folder_local_datasource.dart';

// Data Layer - Repositories
export 'data/repositories/document_repository_impl.dart';
export 'data/repositories/folder_repository_impl.dart';

// Presentation Layer - Providers
export 'presentation/providers/documents_provider.dart';
export 'presentation/providers/folders_provider.dart';

// Presentation Layer - Screens
export 'presentation/screens/documents_screen.dart';

// Presentation Layer - Widgets
export 'presentation/widgets/document_card.dart';
export 'presentation/widgets/document_context_menu.dart';
export 'presentation/widgets/document_grid.dart';
export 'presentation/widgets/empty_state.dart';
export 'presentation/widgets/new_document_dialog.dart';
export 'presentation/widgets/sidebar.dart';

// Presentation Layer - Constants
export 'presentation/constants/documents_strings.dart';
