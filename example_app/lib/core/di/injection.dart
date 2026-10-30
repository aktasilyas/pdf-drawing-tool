/// Dependency Injection setup using GetIt + Injectable.
///
/// Usage:
/// ```dart
/// // In main.dart
/// await configureDependencies();
///
/// // Get instance
/// final repo = getIt<AuthRepository>();
/// ```
library;

import 'dart:async';

import 'package:drawing_core/drawing_core.dart' show PdfPathResolver;
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:example_app/core/clipboard/clipboard_file_refs.dart';
import 'package:example_app/core/database/app_database.dart';
import 'package:example_app/core/database/local_transaction_runner.dart';
import 'package:example_app/core/utils/logger.dart';
import 'package:example_app/features/documents/documents.dart';
import 'package:example_app/features/editor/editor.dart';

/// Global service locator instance
final getIt = GetIt.instance;

/// Configure all dependencies
///
/// Call this in main() before runApp()
Future<void> configureDependencies() async {
  // Core services
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  // Single local database for the whole app (providers read it from here).
  final database = AppDatabase();
  getIt.registerSingleton<AppDatabase>(database);
  getIt.registerLazySingleton<LocalTransactionRunner>(
    () => DriftTransactionRunner(database),
  );

  // Import the legacy prefs library before any datasource reads from Drift.
  await PrefsToDriftMigration(database, prefs).run();

  // Imported PDFs are stored relative to the app documents directory.
  final docsDir = await getApplicationDocumentsDirectory();
  getIt.registerSingleton<PdfPathResolver>(PdfPathResolver(docsDir.path));

  // Paths the editor clipboards still need; bound at the app root.
  getIt.registerLazySingleton<ClipboardFileRefs>(ClipboardFileRefs.new);

  // Manual registrations
  _registerRepositories();
  _registerUseCases();

  unawaited(purgeExpiredTrashOnStartup(
    PurgeExpiredTrashUseCase(
      getIt<DocumentRepository>(),
      getIt<PageTrashRepository>(),
    ),
  ));
}

/// Deletes trash older than 30 days. Never blocks or fails app startup.
Future<void> purgeExpiredTrashOnStartup(
  PurgeExpiredTrashUseCase purge, {
  DateTime Function() clock = DateTime.now,
}) async {
  try {
    final result = await purge(clock());
    result.fold(
      (failure) => logger.w('Trash purge failed: ${failure.message}'),
      (count) {
        if (count > 0) logger.i('Purged $count expired trash items');
      },
    );
  } catch (e) {
    logger.w('Trash purge failed: $e');
  }
}

// ignore: unused_element
void _registerCoreServices() {
  // Supabase client
  // getIt.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  // SharedPreferences - already registered in provider
}

void _registerRepositories() {
  // Datasources
  getIt.registerLazySingleton<DocumentLocalDatasource>(
    () => DocumentLocalDatasourceImpl(
      getIt(),
      pdfPaths: getIt<PdfPathResolver>(),
      clipboard: getIt<ClipboardFileRefs>(),
    ),
  );

  getIt.registerLazySingleton<FolderLocalDatasource>(
    () => FolderLocalDatasourceImpl(getIt()),
  );

  getIt.registerLazySingleton<TrashedPageLocalDatasource>(
    () => TrashedPageLocalDatasourceImpl(getIt()),
  );

  // Documents
  getIt.registerLazySingleton<DocumentRepository>(
    () => DocumentRepositoryImpl(
      getIt<DocumentLocalDatasource>(),
      getIt<FolderLocalDatasource>(),
      getIt<LocalTransactionRunner>(),
      null,
      getIt<PdfPathResolver>(),
    ),
  );

  // Page trash
  getIt.registerLazySingleton<PageTrashRepository>(
    () => PageTrashRepositoryImpl(
      getIt<TrashedPageLocalDatasource>(),
      getIt<DocumentLocalDatasource>(),
      getIt<LocalTransactionRunner>(),
    ),
  );

  // Folders
  getIt.registerLazySingleton<FolderRepository>(
    () => FolderRepositoryImpl(
      getIt<FolderLocalDatasource>(),
      getIt<DocumentLocalDatasource>(),
      getIt<LocalTransactionRunner>(),
    ),
  );
}

void _registerUseCases() {
  // Maintenance
  getIt.registerLazySingleton(
    () => SweepOrphanedFilesUseCase(
      getIt<DocumentRepository>(),
      PrefsMaintenanceSchedule(getIt<SharedPreferences>()),
    ),
  );

  // Re-link a missing source PDF
  getIt.registerLazySingleton(
    () => RelinkPdfSourceUseCase(
      PdfxPageCounter(),
      LocalPdfSourceFiles(getIt<PdfPathResolver>()),
    ),
  );

  // Editor use cases
  getIt.registerFactory(() => LoadDocumentUseCase(getIt()));
  getIt.registerFactory(() => SaveDocumentUseCase(getIt()));
}

/// Drops all registrations so [configureDependencies] can run again (startup
/// Retry, tests). Closes an already registered database connection first so
/// its file is not left locked.
///
/// Must never delete, move or rewrite any file: the database stays on disk
/// exactly as it is.
Future<void> resetDependencies() async {
  if (getIt.isRegistered<AppDatabase>()) {
    try {
      await getIt<AppDatabase>().close();
    } catch (e) {
      logger.w('Closing the database during reset failed: $e');
    }
  }
  await getIt.reset();
}
