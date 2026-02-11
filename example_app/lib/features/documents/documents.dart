/// Documents feature module
library;

// Domain - Entities
export 'domain/entities/document_info.dart';
export 'domain/entities/folder.dart';
export 'domain/entities/view_mode.dart';

// Domain - Repositories
export 'domain/repositories/document_repository.dart';
export 'domain/repositories/folder_repository.dart';

// Domain - Use Cases
export 'domain/usecases/create_document_usecase.dart';
export 'domain/usecases/get_documents_usecase.dart';
export 'domain/usecases/delete_document_usecase.dart';
export 'domain/usecases/move_document_usecase.dart';
export 'domain/usecases/toggle_favorite_usecase.dart';
export 'domain/usecases/search_documents_usecase.dart';
export 'domain/usecases/create_folder_usecase.dart';
export 'domain/usecases/get_folders_usecase.dart';
export 'domain/usecases/delete_folder_usecase.dart';

// Data - Models
export 'data/models/document_model.dart';
export 'data/models/folder_model.dart';

// Data - Datasources
export 'data/datasources/document_local_datasource.dart';
export 'data/datasources/folder_local_datasource.dart';

// Data - Repositories
export 'data/repositories/document_repository_impl.dart';
export 'data/repositories/folder_repository_impl.dart';

// Presentation - Providers
export 'presentation/providers/documents_provider.dart';
export 'presentation/providers/folders_provider.dart';

// Presentation - Screens
export 'presentation/screens/documents_screen.dart';
export 'presentation/screens/documents_screen_helpers.dart';
export 'presentation/screens/manage_folders_screen.dart';
export 'presentation/screens/template_selection_screen.dart';

// Presentation - Widgets
export 'presentation/widgets/breadcrumb_navigation.dart';
export 'presentation/widgets/cover_grid.dart';
export 'presentation/widgets/document_card.dart';
export 'presentation/widgets/document_card_helpers.dart';
export 'presentation/widgets/document_context_menu.dart';
export 'presentation/widgets/document_grid.dart';
export 'presentation/widgets/document_list_tile.dart';
export 'presentation/widgets/document_preview.dart';
export 'presentation/widgets/document_thumbnail_painter.dart';
export 'presentation/widgets/documents_combined_grid.dart';
export 'presentation/widgets/documents_content_view.dart';
export 'presentation/widgets/documents_empty_states.dart';
export 'presentation/widgets/documents_error_views.dart';
export 'presentation/widgets/documents_header.dart';
export 'presentation/widgets/documents_list_view.dart';
export 'presentation/widgets/documents_menus.dart';
export 'presentation/widgets/documents_sidebar.dart';
export 'presentation/widgets/empty_state.dart';
export 'presentation/widgets/folder_card.dart';
export 'presentation/widgets/folder_color_picker.dart';
export 'presentation/widgets/folder_menus.dart';
export 'presentation/widgets/format_picker_sheet.dart';
export 'presentation/widgets/manage_folder_list_item.dart';
export 'presentation/widgets/move_to_folder_dialog.dart';
export 'presentation/widgets/new_document_dialog.dart';
export 'presentation/widgets/new_document_importers.dart';
export 'presentation/widgets/paper_color_palette.dart';
export 'presentation/widgets/selection_mode_header.dart';
export 'presentation/widgets/sidebar_item.dart';
export 'presentation/widgets/template_category_tabs.dart';
export 'presentation/widgets/template_grid.dart';
export 'presentation/widgets/template_preview_card.dart';
