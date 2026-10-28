/// Documents feature module
library;

// Domain - Entities
export 'domain/entities/document_info.dart';
export 'domain/entities/encoded_json.dart';
export 'domain/entities/folder.dart';
export 'domain/entities/incoming_pdf.dart';
export 'domain/entities/library_rule.dart';
export 'domain/entities/paper_color.dart';
export 'domain/entities/view_mode.dart';

// Domain - Repositories
export 'domain/repositories/document_repository.dart';
export 'domain/repositories/folder_repository.dart';
export 'domain/repositories/incoming_pdf_source.dart';
export 'domain/repositories/maintenance_schedule.dart';
export 'domain/repositories/page_trash_repository.dart';

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
export 'domain/usecases/purge_expired_trash_usecase.dart';
export 'domain/usecases/sweep_orphaned_files_usecase.dart';

// Data - Models
export 'data/models/document_model.dart';
export 'data/models/folder_model.dart';
export 'data/models/trashed_page_model.dart';

// Data - Migration
export 'data/migration/prefs_to_drift_migration.dart';

// Data - Datasources
export 'data/datasources/document_content_codec.dart';
export 'data/datasources/document_local_datasource.dart';
export 'data/datasources/folder_local_datasource.dart';
export 'data/datasources/method_channel_incoming_pdf_source.dart';
export 'data/datasources/prefs_maintenance_schedule.dart';
export 'data/datasources/trashed_page_local_datasource.dart';

// Data - Repositories
export 'data/repositories/document_repository_impl.dart';
export 'data/repositories/folder_repository_impl.dart';
export 'data/repositories/page_trash_repository_impl.dart';

// Presentation - Providers
export 'presentation/providers/document_menu_actions.dart';
export 'presentation/providers/document_preview_provider.dart';
export 'presentation/providers/documents_provider.dart';
export 'presentation/providers/folders_provider.dart';
export 'presentation/providers/incoming_pdf_provider.dart';
export 'presentation/providers/library_error.dart';
export 'presentation/providers/move_to_folder_actions.dart';

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
export 'presentation/widgets/rename_document_dialog.dart';
export 'presentation/widgets/trashed_page_menu.dart';
export 'presentation/widgets/documents_sidebar.dart';
export 'presentation/widgets/empty_state.dart';
export 'presentation/widgets/folder_card.dart';
export 'presentation/widgets/folder_color_picker.dart';
export 'presentation/widgets/folder_list_tile.dart';
export 'presentation/widgets/folder_menus.dart';
export 'presentation/widgets/document_quota.dart';
export 'presentation/widgets/folder_tile_art.dart';
export 'presentation/widgets/format_picker_sheet.dart';
export 'presentation/widgets/incoming_pdf_listener.dart';
export 'presentation/widgets/library_grid_metrics.dart';
export 'presentation/widgets/library_header_parts.dart';
export 'presentation/widgets/library_list_row.dart';
export 'presentation/widgets/library_page_thumbnail.dart';
export 'presentation/widgets/library_tile_frame.dart';
export 'presentation/widgets/library_tile_parts.dart';
export 'presentation/widgets/library_error_listener.dart';
export 'presentation/widgets/manage_folder_list_item.dart';
export 'presentation/widgets/move_to_folder_dialog.dart';
export 'presentation/widgets/new_document_dialog.dart';
export 'presentation/widgets/new_document_importers.dart';
export 'presentation/widgets/paper_color_palette.dart';
export 'presentation/widgets/pdf_file_importer.dart';
export 'presentation/widgets/pdf_import_commit.dart';
export 'presentation/widgets/pdf_import_feedback.dart';
export 'presentation/widgets/selection_mode_header.dart';
export 'presentation/widgets/sidebar_item.dart';
export 'presentation/widgets/template_category_tabs.dart';
export 'presentation/widgets/template_grid.dart';
export 'presentation/widgets/template_preview_card.dart';
